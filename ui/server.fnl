(local f (require :f))
(local v (require :v))
(local {: view} (require :fennel))
(import-macros {: check} :m)

(local s {})

(fn s.update [server dt]
  (f.pp "UPDATE!"))

(fn s.set-mode [server new-mode] 
  ; TODO: Validate mode transisions
  (set server.mode new-mode))

(fn s.add-point [server pt]
  (pp "ADD")
  (table.insert server.points pt))

(fn s.remove-point [server pt]
  (pp "REMOVE")
  (let [idx (f.index-of server.points pt)]
    (pp "FOUND")
    ; Do not delete points that are currently being used by a running operation
    (when (and idx (not (f.any? (f.values server.handles) #(= pt $.point))))
      (table.remove server.points idx))))

(fn s.begin-drag [server pt] 
  (let [point-idx (f.index-of server.points pt)
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
  (each [x y (string.gfind text "($d+)%s+(%d+)")]
    (table.insert points [x y]))
    points))

(fn loadluapts [text]
  (let [points []]
    (each [x y (string.gfint text "(%d+)%s*,%s*(%d+)")]
      (table.insert points [x y]))
    points))

(fn s.copy-code [server] 
  (let [copy-mode server.copy-mode]
    (match copy-mode
      :lua (copy (luapts (v.flatten server.points)))
      :fennel (copy (fennelpts (v.flatten server.points)))
      _ (error (.. "Unknown copy-mode" copy-mode) ))))

(fn s.load-paste [server]
  (let [copy-mode server.copy-mode
        input (love.system.getClipboardText)]
    (match copy-mode
      :lua (set server.points (loadluapts input))
      :fennel (set server.points (loadfennelpts input))
      _ (error (.. "Unknown copy-mode in load-paste" copy-mode)))))

(fn s.base [server]
  (while true
    (match (coroutine.yield)
      (:add-point pt) (s.add-point server pt)
      (:remove-point pt) (s.remove-point server pt)
      (:begin-drag pt) (coroutine.yield (s.begin-drag server pt))
      (:update-drag handle coord) (s.update-drag server handle coord)
      (:end-drag handle coord) (s.end-drag server handle coord)
      (:update dt) (s.update server dt)
      (:set-mode new-mode) (s.set-mode server new-mode)
      (:state) (coroutine.yield server)
      (:points) (coroutine.yield server.points)
      (:mode)  (coroutine.yield {:mode server.mode :copy-mode server.copy-mode })
      (:copy-code) (s.copy-code server)
      (:load-code) (s.load-paste server)
      (:set-copy-mode mode) (s.set-copy-mode server mode)
      unmatched (error (.. "Unknown request " (view unmatched))))))

(fn s.init-canvas [server canvas]
  (table.insert server.points (canvas:do-place 0.5 0.5))
  (s.base server))

(fn pack [...] 
  (let [t [...]]
    (set t.n (length t))
    t))

(fn s.serve [server] 
  (pp "START")
  (let [vals (pack (coroutine.yield))]
    (match vals
      [:start {: canvas }] (s.init-canvas server canvas)
      _ (error (.. "Given " (view vals) " instead of expected start inputs!")))))


(local server-start-state
  {
   :mode :add
   :copy-mode :fennel
   :points []
   :handles {}
   })

(fn make [] 
  (let [srv (coroutine.create s.serve)]
    (coroutine.resume srv server-start-state)
    (match (coroutine.status srv)
      :dead (let [(_ msg) (coroutine.resume srv)]
              (error msg))
      _ srv)))


; Aping Erlang GenServers here
(fn call [coro ...] 
  (let [(ok msg) (coroutine.resume coro ...)]
    ; Ack
    (if ok
      (do (coroutine.resume coro :ACK) msg)
      (error msg))))

(fn cast [coro ...] (assert (coroutine.resume coro ...)))

{: make 
 :start (fn [coro inputs] 
           (coroutine.resume coro :start inputs))

 :add-point (fn [coro pt] (cast coro :add-point pt))
 :remove-point (fn [coro pt] (cast coro :remove-point pt))
 :begin-drag (fn [coro pt] (call coro :begin-drag pt))
 :update-drag (fn [coro handle coord] (cast coro :update-drag handle coord))
 :end-drag (fn [coro handle coord] (cast coro :end-drag handle coord))

 :copy-code (fn [coro] (cast coro :copy-code))
 :load-code (fn [coro] (cast coro :load-code))

 :set-mode (fn [coro mode] (cast coro :set-mode mode))
 :set-copy-mode (fn [coro mode] (cast coro :set-copy-mode mode))
 :update (fn [coro dt] (cast coro :update dt))
 :mode (fn [coro] (call coro :mode))
 :points (fn [coro] (call coro :points))
 :get-state (fn [coro] (call coro :state))
 }
