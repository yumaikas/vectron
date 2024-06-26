(local f (require :f))
(local shape<> (require :ui.server.serialize))
(local polyline (require :ui.shapes.polyline))
(local polygon (require :ui.shapes.polygon))
(local v (require :v))
(local lpeg (require :lulpeg))
(local {: view} (require :fennel))
(import-macros {: check} :m)
(import-macros {: protocol : export-protocol} :ui.proto)

(local server-start-state
  (let [starting-shape (polygon.empty [0 1 0]) ]
  {
   :mode :add
   :copy-mode :fennel
   :color-mode :alebedo ; Can be alebedo or highlight-selected
   :current-shape 1
   :shapes [starting-shape]
   :slide {:start [0 0] :current [0 0]}
   :handles {}
   }))


; Aping Erlang GenServers here
(fn call [coro ...] 
  ; (print "CAST" (view ...))
  (let [(ok msg) (coroutine.resume coro ...)]
    ; Ack
    (if ok
      (do (coroutine.resume coro :ACK) msg)
      (error msg))))

(fn cast [coro ...] 
  ; (print "CALL" (view ...))
  (assert (coroutine.resume coro ...)))

(local s {})
(fn s.current-shape [server] (. server.shapes server.current-shape))

(fn s.update [server dt] (f.pp "UPDATE!"))

(fn s.set-mode [server new-mode] (set server.mode new-mode))

(local modes [:alebedo :highlight-selected])
(fn s.color-mode [server] server.color-mode)

(fn s.set-color-mode [server mode] 
  (if (f.index-of modes mode)
    (set server.color-mode mode)
    (error (.. "Invalid color mode: " mode))))

(fn s.toggle-color-mode [server] 
  (set server.color-mode 
       (match server.color-mode
         :alebedo  :highlight-selected
         :highlight-selected :alebedo)))

(fn s.add-point [server pt]
  (let [current-shape (s.current-shape server)]
  (table.insert current-shape.points pt)))

(fn s.insert-point [server after pt]
  (let [current-shape (s.current-shape server)
        idx (f.index-of current-shape.points after) ]
    (table.insert current-shape.points idx pt)))

(fn s.remove-point [server pt]
  (let [current-shape (s.current-shape server)
        idx (f.index-of current-shape.points pt)]
    ; Do not delete points that are currently being used by a running operation
    (when (and idx (not (f.any? (f.values server.handles) #(= pt $.point))))
      (table.remove current-shape.points idx))))

(fn s.begin-drag [server pt] 
  (let [current-shape (s.current-shape server)
        point-idx (f.index-of current-shape.points pt)
        handle (f.uuid)]
    (if point-idx
      (do
        (local data { :type :drag :point pt  })
        (tset server.handles handle data)
        handle)
      (error "Tried to start drag on point not in list!"))))

(fn s.update-drag [server handle coord] 
  (let [drag-operation (. server.handles handle)
        [x y] coord]
    (if drag-operation
      (do 
        ; Mutating the point here to avoid having to replace it in the points list for now
        (tset drag-operation.point 1 x)
        (tset drag-operation.point 2 y))
      (error (.. "Tried to update a non-existant handle: " handle)))))
  
(fn s.end-drag [server handle coord]
  (let [drag-operation (. server.handles handle)
        [x y] coord]
    (if drag-operation
      (do 
        ; Mutating the point here to avoid having to replace it in the points list for now
        (tset drag-operation.point 1 x)
        (tset drag-operation.point 2 y)
        (tset server.handles handle nil))
      (error (.. "Tried to end a non-existant handle: " handle)))))

(fn copy [text] (love.system.setClipboardText text))

(fn s.set-copy-mode [server mode]
  (check (f.index-of [:lua :fennel] mode) (.. "Cannot set copy-mode to " mode))
  (set server.copy-mode mode))

(fn s.copy-code [server] 
  (let [current-shape (s.current-shape server)
        copy-mode server.copy-mode]
    (copy (shape<>.points->text copy-mode (v.flatten current-shape.points)))))

(fn s.copy-scene [server]
  (let [shapes (s.shapes server)
        copy-mode server.copy-mode]
    (copy (shape<>.scene->text copy-mode shapes))))

(fn s.set-status [server status] (set server.status-line status))
(fn s.clear-status [server] (set server.status-line nil))

(fn s.begin-slide [server at]
  (set server.slide.start at)
  (set server.slide.current at))

(fn s.update-slide [server to] (set server.slide.current to))


(fn s.end-slide [server at]
  (let [current-shape (s.current-shape server)
        pt-adjust (v.sub server.slide.current
                         server.slide.start)]
    (set current-shape.points (f.map.i current-shape.points #(v.add $ pt-adjust)))
    (set server.slide.start [0 0])
    (set server.slide.current [0 0])))

(fn s.toggle-shape-mode [server] 
  (let [current-shape (s.current-shape server)]
    (set current-shape.module
      (if (= current-shape.module polyline) polygon polyline))))

(fn s.points [server] 
  (let [points (. (s.current-shape server) :points)]
    (if
      (= server.mode :slide) 
      (let [pt-adjust (v.sub server.slide.current server.slide.start)]
        (f.map.i points #(v.add $ pt-adjust)))
      points)))

(fn s.shapes [server] server.shapes)

(fn s.new-shape [server of] 
  (let [[x y] server.proto-point
        new-shape (of.new x y [0 1 0])]
    (table.insert server.shapes new-shape)
    new-shape))

(fn s.move-shape [server shape after]
  (let [w/o-shape (f.filter.i server.shapes #(not= shape $)) 
        insert-idx (+ 1 (or (f.index-of w/o-shape after) 0)) ]
    (table.insert w/o-shape insert-idx shape)
    (set server.shapes w/o-shape)))

(fn s.set-shape-color [server shape color]
  (if (f.index-of server.shapes shape)
    (set shape.color color)
    (error (.. "Tried to set color for shape not in server!"))))

(fn s.pick-shape [server shape] 
  (let [pick-idx (f.index-of server.shapes shape)]
    (if pick-idx
      (set server.current-shape pick-idx)
      (error "Tried to pick shape not in the server!"))))

(fn s.shapelist-move-up [server] 
  (let [picked (. server.shapes server.current-shape )
        swap-idx (- server.current-shape 1)
        swap-with (. server.shapes swap-idx)]
    (when (>= swap-idx 0)
        (tset server.shapes swap-idx picked)
        (tset server.shapes server.current-shape swap-with))))

(fn s.shapelist-move-down [server] 
  (let [picked (. server.shapes server.current-shape )
        swap-idx (+ server.current-shape 1)
        swap-with (. server.shapes swap-idx)]
    (when (<= swap-idx (length server.shapes))
        (tset server.shapes swap-idx picked)
        (tset server.shapes server.current-shape swap-with))))

(fn s.clear-scene [server] 
  (let [starting-shape (polygon.empty [0 1 0]) ]
   (set server.mode :add)
   (set server.copy-mode :fennel)
   (set server.current-shape 1)
   (set server.shapes [starting-shape])
   (set server.slide {:start [0 0] :current [0 0]})
   (set server.handles {})))

(fn s.slide-offset [server]
  (v.sub 
    server.slide.current
    server.slide.start))

(fn s.load-scene [server]
  (let [copy-mode server.copy-mode
        text (love.system.getClipboardText)
        (ok shapes) (shape<>.text->scene copy-mode text)]
    (if (and (= ok :ok) (> (length shapes) 0))
      (do 
        (set server.current-shape 1)
        (set server.shapes shapes))
      (do (print shapes)
        (s.set-status server "Unable to load scene from clipboard")))))
        

(fn s.load-paste [server]
  (let [current-shape (s.current-shape server)
        copy-mode server.copy-mode
        input (love.system.getClipboardText)
        (ok pts) (shape<>.text->points copy-mode input) ]
    (if (= ok :ok)
      (set current-shape.points pts)
      (do (print pts)
        (s.set-status server "Did not find any points on the clipboard")))))


(fn copy-each-shape [shapes] 
   (icollect [_ shape (ipairs shapes)] (shape.module.copy shape)))

(fn version-of [server]
  {
   :current-shape server.current-shape
   :shapes (copy-each-shape server.shapes)
   })

(fn apply-version [server version] 
  (set server.current-shape version.current-shape)
  (set server.shapes (copy-each-shape version.shapes)))

(fn s.base [server]
  (var history [])
  (var version-idx 1)
  (while true
    (var drop-status true)
    (fn keep-status [] (set drop-status false))
    (fn commit [] 
      (let [version (version-of server)]

        ; We are adding new things after a redo?
        ; If I ever wanted to create side-versions of things
        ; This would be the spot. But I do not at the moment.
        (when (< version-idx (length history))
          (for [i version-idx (length history)]
            (tset history i nil)))

        (tset history version-idx version)
        (set version-idx (+ 1 version-idx))
        )
      ;(f.pp history)
      )
    (fn undo [] 
      (when (> version-idx (length history))
        ; Commit the current state before backing away from it.
        (commit)
        (set version-idx (- version-idx 1)))
      (when (> version-idx 1)
        (set version-idx (- version-idx 1))
        (apply-version server (. history version-idx))))

    (fn redo []
      (when (< version-idx (length history))
        (set version-idx (+ version-idx 1))
        (apply-version server (. history version-idx))))

    (protocol :vectron-server
      (cast :add-point pt) (do (commit) (s.add-point server pt))
      (cast :remove-point pt) (do (commit) (s.remove-point server pt))
      (cast :insert-point after pt) (do (commit) (s.insert-point server after pt))

      ; TODO: Update this code to use operation handles akin to drags 
      (cast :begin-slide at) (s.begin-slide server at)
      (cast :update-slide to) (s.update-slide server to)
      (cast :end-slide at) (do (commit) (s.end-slide server at))
      (call :slide-offset) (coroutine.yield (s.slide-offset server))

      (call :shapes) (coroutine.yield (s.shapes server))
      (cast :new-shape of) (do (commit) (s.pick-shape server (s.new-shape server of)))
      (call :current-shape) (coroutine.yield (s.current-shape server))
      (cast :pick-shape shape) (do (commit) (s.pick-shape server shape))
      (cast :move-shape shape after) (do (commit) (s.move-shape server shape after))

      ; TODO: Keep a temp color copy on hand?
      (cast :set-shape-color shape color) (do (s.set-shape-color server shape color))
      (cast :commit-shape-color shape color) (do (commit) (s.set-shape-color server shape color))

      (call :begin-drag pt)  (coroutine.yield (s.begin-drag server pt))
      (cast :update-drag handle coord) (s.update-drag server handle coord)
      (cast :end-drag handle coord) (do (commit) (s.end-drag server handle coord))

      (cast :set-mode new-mode) (s.set-mode server new-mode)

      (cast :undo) (undo server)
      (cast :redo) (redo server)

      (cast :set-color-mode mode) (s.set-color-mode server mode)
      (cast :toggle-color-mode) (s.toggle-color-mode server)

      (cast :toggle-shape-mode) (s.toggle-shape-mode server)

      (cast :set-copy-mode mode) (s.set-copy-mode server mode)
      (cast :copy-code) (do (s.copy-code server))
      (cast :load-code) (do (commit) (keep-status) (s.load-paste server))

      (cast :copy-scene) (do (s.copy-scene server))
      (cast :load-scene) (do (commit) (keep-status) (s.load-scene server))
      (cast :clear-scene) (do (commit) (s.clear-scene server))

      (cast :update dt) (do (keep-status) 
                     (s.update server dt))

      (call :color-mode) (do (keep-status) (coroutine.yield (s.color-mode server)))
      (call :status-line) (do (keep-status)
                       (coroutine.yield server.status-line))

      (call :state) (do (keep-status) 
                 (coroutine.yield server))
      (call :points) (do (keep-status) 
                  (coroutine.yield (s.points server)))
      (call :mode) (do (keep-status) 
                (coroutine.yield {:mode server.mode :copy-mode server.copy-mode }))

      unmatched (error (.. "Unknown request " (view unmatched))))
    (when drop-status
      (s.clear-status server))
    ))

(fn s.init-canvas [server canvas]
  (table.insert (. (s.current-shape server) :points) (canvas:do-place 0.5 0.5))
  (set server.proto-point (canvas:do-place 0.5 0.5))
  (s.base server))

(fn pack [...] 
  (let [t [...]]
    (set t.n (length t))
    t))

(fn s.serve [server] 
  (let [vals (pack (coroutine.yield))]
    (match vals
      [:start {: canvas }]  (s.init-canvas server canvas)
      _ (error (.. "Given " (view vals) " instead of expected start inputs!")))))


(fn make [] 
  (let [srv (coroutine.create s.serve)]
    (coroutine.resume srv server-start-state)
    (match (coroutine.status srv)
      :dead (let [(_ msg) (coroutine.resume srv)]
              (error msg))
      _ srv)))

(let [proto (export-protocol :vectron-server)]
  (set proto.make make)
  (set proto.start 
       (fn [coro inputs] (coroutine.resume coro :start inputs)))
  proto)

