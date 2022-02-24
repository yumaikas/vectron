(local protocols {})

(fn protocol [name ...] 
  (fn slice [t idx len?]
    (let [len (or len? (length t))]
    (icollect [i v (ipairs t) :until (> i (+ idx len)) :into `()]
              (when (and (> i idx)) v))))

  (let [match-body [...]
        protocol {} ]
    (when (not= 0 (% (length match-body) 2))
      (print (view match-body))
      (error "protocol expects an even nummber of forms"))
    (fn proto-of [msg-type name ...]
       `(fn [coro# ,...] (,msg-type coro# ,name ,...)))
    (tset protocols name protocol)

    (icollect [i form (ipairs match-body) :into `(match (coroutine.yield))]
      (if 
        ; Special case to let error handling form pass through
        (= i (- (length match-body) 1)) form
        ; Handle the protocol defining forms
        (= (% i 2) 1)
        (do 
          (tset protocol (. form 2) (proto-of (unpack form)))
          (slice form 1))
        ; The code to run for a message can pass through unmodified
        form))))

(fn export-protocol [name]
  (collect 
    [name func (pairs (. protocols name)) :into `[]]
    name func))

{: export-protocol : protocol}

