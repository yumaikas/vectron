(local f (require :f))
(local v (require :v))
(local {: view} (require :fennel))
(import-macros {: check} :m)

(local s {})
(fn s.current-shape [server] (. server.shapes server.current-shape))

(fn s.update [server dt]
  (f.pp "UPDATE!"))

(fn s.set-mode [server new-mode] 
  ; TODO: Validate mode transisions
  (set server.mode new-mode))

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


(fn copy [text]
  (love.system.setClipboardText text))

(fn s.set-copy-mode [server mode]
  (check (f.index-of [:lua :fennel] mode) (.. "Cannot set copy-mode to " mode))
  (set server.copy-mode mode))

(fn luapts [points] 
  (.. "{ " (table.concat points ", ") " }"))

(fn fennelpts [points]
  (.. "[ " (table.concat points " ") " ]"))

; TODO: Set up lpeg or something like that to do this better
(fn loadfennelpts [text] 
  (let [points []]
    (each [x y (string.gfind text "(%d+)%s+(%d+)")]
      (table.insert points [x y]))
    (if (> (length points) 0)
      (values :ok points)
      (values :error "Found no points"))))

(fn loadluapts [text]
  (let [points []]
    (each [x y (string.gfind text "(%d+)%s*,%s*(%d+)")]
      (table.insert points [x y]))
    (if (> (length points) 0)
      (values :ok points)
      (values :error "Found no points"))))

(fn s.copy-code [server] 
  (let [current-shape (s.current-shape server)
        copy-mode server.copy-mode]
    (match copy-mode
      :lua (copy (luapts (v.flatten current-shape.points)))
      :fennel (copy (fennelpts (v.flatten current-shape.points)))
      _ (error (.. "Unknown copy-mode" copy-mode) ))))

(fn pts-loader-for-mode [copy-mode]
  (match copy-mode 
    :lua loadluapts 
    :fennel loadfennelpts 
    _ (error (.. "Unknown copy-mode in pts-loader-for-mode " copy-mode))))

(fn s.set-status [server status] 
  (set server.status-line status))

(fn s.clear-status [server] 
  (set server.status-line nil))

(fn s.begin-slide [server at]
  (set server.slide.start at)
  (set server.slide.current at))

(fn s.update-slide [server to]
  (set server.slide.current to))

(fn s.end-slide [server at]
  (let [current-shape (s.current-shape server)
        pt-adjust (v.sub server.slide.current
                         server.slide.start)]
    (set current-shape.points (f.map.i current-shape.points #(v.add $ pt-adjust)))
    (set server.slide.start [0 0])
    (set server.slide.current [0 0])))

(fn s.points [server] 
  (let [points (. (s.current-shape server) :points)]
    (if
      (= server.mode :slide) 
      (let [pt-adjust (v.sub server.slide.current server.slide.start)]
        (f.map.i points #(v.add $ pt-adjust)))
      points)))

(fn s.shapes [server] server.shapes)

(fn s.new-shape [server] 
  (f.pp "NEW")
  (let [[x y] server.proto-point]
    (table.insert 
      server.shapes 
      { :points [[x y]]
       :color [0 1 0] }))
  (f.pp "SHAPE"))

(fn s.move-shape [server shape after]
  (let [w/o-shape (f.filter.i server.shapes #(not= shape $)) 
        insert-idx (+ 1 (or (f.index-of w/o-shape after) 0)) ]
    (table.insert w/o-shape insert-idx shape)
    (set server.shapes w/o-shape)))

(fn s.pick-shape [server shape] 
  (let [pick-idx (f.index-of server.shapes shape)]
    (if pick-idx
      (set server.current-shape pick-idx)
      (error "Tried to pick shape not in the server!"))))

(fn s.slide-offset [server]
  (v.sub 
    server.slide.current
    server.slide.start))

(fn s.load-paste [server]
  (let [current-shape (s.current-shape server)
        copy-mode server.copy-mode
        input (love.system.getClipboardText)
        loader (pts-loader-for-mode copy-mode)
        (ok pts) (loader input) ]
    (if (= ok :ok)
      (set current-shape.points pts)
      (do (print pts)
        (s.set-status server "Didn't find any points on the clipboard")))))


(fn copy-shape [shape] 
  (let [[r g b] shape.color
        points shape.points ]
  { :color [r g b]
   :points (icollect [_ [x y] (ipairs points)] [x y])}))

(fn copy-each-shape [shapes] 
   (icollect [_ shape (ipairs shapes)] (copy-shape shape)))

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
      (f.pp history))
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

    
    (match (coroutine.yield)
      (:add-point pt) (do (commit) (s.add-point server pt))
      (:remove-point pt) (do (commit) (s.remove-point server pt))
      (:insert-point after pt) (do (commit) (s.insert-point server after pt))

      ; TODO: Update this code to use operation handles akin to drags 
      (:begin-slide at) (s.begin-slide server at)
      (:update-slide to) (s.update-slide server to)
      (:end-slide at) (s.end-slide server at)
      (:slide-offset) (coroutine.yield (s.slide-offset server))

      (:shapes) (coroutine.yield (s.shapes server))
      (:new-shape) (do (commit) (s.new-shape server))
      (:current-shape) (coroutine.yield (s.current-shape server))
      (:pick-shape shape) (s.pick-shape server shape)
      (:move-shape shape after) (do (commit) (s.move-shape server shape after))

      (:begin-drag pt)  (coroutine.yield (s.begin-drag server pt))
      (:update-drag handle coord) (s.update-drag server handle coord)

      (:end-drag handle coord) (do (commit) (s.end-drag server handle coord))
      (:set-mode new-mode) (s.set-mode server new-mode)

      (:undo) (undo server)
      (:redo) (redo server)

      (:set-copy-mode mode) (s.set-copy-mode server mode)
      (:copy-code) (do (commit) (s.copy-code server))
      (:load-code) (do (commit) (keep-status) (s.load-paste server))

      (:update dt) (do (keep-status) 
                     (s.update server dt))

      (:status-line) (do (keep-status)
                       (coroutine.yield server.status-line))

      (:state) (do (keep-status) 
                 (coroutine.yield server))
      (:points) (do (keep-status) 
                  (coroutine.yield (s.points server)))
      (:mode) (do (keep-status) 
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


(local server-start-state
  (let [starting-shape {:points [] :color [0 1 0]} ]
  {
   :mode :add
   :copy-mode :fennel
   :current-shape 1
   :shapes [starting-shape]
   :slide {:start [0 0] :current [0 0]}
   :handles {}
   }))

(fn make [] 
  (let [srv (coroutine.create s.serve)]
    (coroutine.resume srv server-start-state)
    (match (coroutine.status srv)
      :dead (let [(_ msg) (coroutine.resume srv)]
              (error msg))
      _ srv)))


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

{: make 
 :start (fn [coro inputs] 
           (coroutine.resume coro :start inputs))

 :add-point (fn [coro pt] (cast coro :add-point pt))
 :insert-point (fn [coro after pt] (cast coro :insert-point after pt))
 :remove-point (fn [coro pt] (cast coro :remove-point pt))

 :begin-drag (fn [coro pt] (call coro :begin-drag pt))
 :update-drag (fn [coro handle coord] (cast coro :update-drag handle coord))
 :end-drag (fn [coro handle coord] (cast coro :end-drag handle coord))

 :slide-offset (fn [coro] (call coro :slide-offset))
 :begin-slide (fn [coro at] (cast coro :begin-slide at))
 :update-slide (fn [coro to] (cast coro :update-slide to))
 :end-slide (fn [coro at] (cast coro :end-slide at))

 :shapes (fn [coro] (call coro :shapes))
 :current-shape (fn [coro] (call coro :current-shape))
 :pick-shape (fn [coro shape] (cast coro :pick-shape shape))
 :move-shape (fn [coro shape after] (cast coro :move-shape shape after))
 :new-shape (fn [coro] (cast coro :new-shape))

 :undo (fn [coro] (cast coro :undo))
 :redo (fn [coro] (cast coro :redo))

 :copy-code (fn [coro] (cast coro :copy-code))
 :load-code (fn [coro] (cast coro :load-code))

 :set-mode (fn [coro mode] (cast coro :set-mode mode))
 :set-copy-mode (fn [coro mode] (cast coro :set-copy-mode mode))
 :update (fn [coro dt] (cast coro :update dt))
 :mode (fn [coro] (call coro :mode))
 :points (fn [coro] (call coro :points))
 :get-state (fn [coro] (call coro :state))
 :status-line (fn [coro] (call coro :status-line))
 }
