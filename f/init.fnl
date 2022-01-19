(lambda assert! [val msg] (if val 
                            (io.write ".")
                            (error msg)))
(fn function? [f] (= (type f) :function))
(fn table? [t] (= (type t) :table))
(fn number? [t] (= (type t) :number))
(fn boolean? [t] (= (type t) :boolean))
(fn string? [t] (= (type t) :string))
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
  )



{
 : all?
 : any?
 : function?
 : boolean?
 : string?
 : number?
 : table?
}
