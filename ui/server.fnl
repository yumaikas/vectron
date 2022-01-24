(local {: view} (require :fennel))
(import-macros {: check} :m)

(var base% (fn []))

(fn update% [server dt]
  (base% server))

(fn set-mode% [server new-mode] 
  ; TODO: Validate mode transisions
  (set server.mode new-mode)
  (base% server))

(fn base% [server]
  (match (coroutine.yield)
    (:update dt) (update% server dt)
    (:set-mode new-mode) (set-mode% server new-mode)
    (:state) (coroutine.yield server)
    unmatched (error (.. "Unknown request " (view unmatched))))
  (base% server))

(fn init-canvas% [server canvas]
  (table.insert server.points (canvas:do-place 0.5 0.5))
  (base% server))

(fn pack [...] 
  (let [t [...]]
    (set t.n (length t))
    t))

(fn serve% [server] 
  (let [vals (pack (coroutine.yield))]
    (match vals
      [:start {: canvas }] (init-canvas% server canvas)
      _ (error (.. "Given " (view vals) " instead of expected start inputs!")))))

(fn make [] 
  (let [srv (coroutine.create serve% {:mode :drag :points []})]
    (match (coroutine.status srv)
      :dead (let [(_ msg) (coroutine.resume srv)]
              (error msg))
      _ srv)))

{: make 
 :start (fn [coro inputs] (coroutine.resume coro :start inputs))
 :set-mode (fn [coro mode] (coroutine.resume coro :set-mode mode))
 :update (fn [coro dt] (coroutine.resume coro :update dt))
 :get-state (fn [coro] (let [(ok msg) (coroutine.resume coro :state)]
                          ; Ack
                          (if ok
                            msg
                            (error msg))))
 }
