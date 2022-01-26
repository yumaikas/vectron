(local f (require :f))
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

(fn s.base [server]
  (while true
    (match (coroutine.yield)
      (:add-point pt) (s.add-point server pt)
      (:update dt) (s.update server dt)
      (:set-mode new-mode) (s.set-mode server new-mode)
      (:state) (do (coroutine.yield server))
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

(fn make [] 
  (let [srv (coroutine.create s.serve)]
    (coroutine.resume srv {:mode :insert :points []})
    (match (coroutine.status srv)
      :dead (let [(_ msg) (coroutine.resume srv)]
              (error msg))
      _ srv)))


{: make 
 :start (fn [coro inputs] 
           (coroutine.resume coro :start inputs))

 :add-point (fn [coro pt] (coroutine.resume coro :add-point pt))
 :set-mode (fn [coro mode] (coroutine.resume coro :set-mode mode))
 :update (fn [coro dt] (coroutine.resume coro :update dt))
 :get-state (fn [coro] (let [(ok msg) (coroutine.resume coro :state)]
                          ; Ack
                          (if ok
                            (do (coroutine.resume coro :ACK) msg)
                            (error msg))))
 }
