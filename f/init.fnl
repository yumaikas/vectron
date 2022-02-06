(lambda assert! [val msg] (if val 
                            (io.write ".")
                            (error msg)))
(fn function? [f] (= (type f) :function))
(fn table? [t] (= (type t) :table))
(fn number? [t] (= (type t) :number))
(fn boolean? [t] (= (type t) :boolean))
(fn string? [t] (= (type t) :string))
(fn even? [n] (and (number? n) (= (% n 2) 0)))

(fn uuid []
  (string.gsub "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx" "[xy]" 
    (fn [c] 
      (string.format 
        "%x" 
        (if (= c "x")
          (math.random 0 0xf)
          (math.random 8 0xb))))))

(local pack (or table.pack (fn [...] [...])))

(fn all? [tbl pred] 
  (or (table? tbl) (error "all expects a table in slot 1"))
  (or (function? pred) (error "all expects a in slot 2"))
  (local tlen (length tbl))
  (var idx 1)
  (var valid true)
  (while (and valid (< idx tlen))
    (set valid (and valid (pred (. tbl idx))))
    (set idx (+ idx 1)))
  valid)

(fn find [tbl pred] 
  (or (table? tbl) (error "find expects a table in slot 1"))
  (or (function? pred) (error "find expects a in slot 2"))
  (local tlen (length tbl))
  (var idx 1)
  (var continue true)
  (while (and (. tbl idx) (not (pred (. tbl idx))))
    (set idx (+ idx 1)))
  (if (<= idx tlen)
    (. tbl idx)
    nil))

(fn index-of [tbl el] 
  (or (table? tbl) (error "find expects a table in slot 1"))
  (or el (error "el cannot be nil in index-of"))

  (local tlen (length tbl))
  (var idx 1)
  (while (and (. tbl idx) (not= el (. tbl idx)))
    (set idx (+ idx 1)))
  (if (<= idx tlen)
    idx
    nil))


(fn any? [tbl pred]
  (or (table? tbl) (error "all expects a table in slot 1"))
  (or (function? pred) (error "all expects a in slot 2"))
  (local tlen (length tbl))
  (var idx 1)
  (var continue true)
  (while (and continue (< idx tlen))
    (set continue (not (pred (. tbl idx))))
    (set idx (+ idx 1)))
  (not continue))

(fn tests! [] 
  (print "")
  (assert! (function? #(+ 1 2)) "#() is not detected as a function!")
  (assert! (table? {}) "{} is not detected as a table!")
  (assert! (table? []) "[] is not detected as a table!")
  (assert! (string? :str) ":str is not detected as a string!")
  (assert! (all? [1 2 3] number?) "all? isn't working?")
  (assert! (any? [1 2 3] number?) "any? isn't working?")
  (assert! (not (any? [true "foo"] number?)) "all? isn't working?")
  (assert! (any? [true "foo"] boolean?) "all? isn't working?")
  (assert! (= 2 (find [1 2 3] even?)) "Didn't find 2 via even? !")
  (even? {}))

(local {: view} (require :fennel))
(fn pp [x] (print (view x)))

(var in-debug? false)

(fn with-debug [f] 
  (set in-debug? true)
  (let [ret (pack (pcall f))]
    (set in-debug? false)
    (match ret
      [true & rest] (unpack rest)
      [false & rest] (error (unpack rest)))))

{
 : pp
 : find
 : index-of
 : all?
 : any?
 : function?
 : boolean?
 : string?
 : number?
 :values (fn [tbl] (icollect [_ v (pairs tbl)] v))
 :keys (fn [tbl] (icollect [k _ (pairs tbl)] k))
 : table?
 : with-debug
 : uuid
 :map 
 {
  :i (fn [tbl f] (icollect [_ el (ipairs tbl)] (f el)))
  :idx (fn [tbl f] (icollect [idx el (ipairs tbl)] (f idx el)))
  :kv (fn [tbl f] (collect [k val (pairs tbl)] (f k val)))
  }
 :in-debug? (fn [] in-debug?)
}
