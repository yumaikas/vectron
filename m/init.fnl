(fn check [exp err]
  `(or ,exp (error ,err)))

(fn each-in [ident tbl ...]
  `(let [tbl# ,tbl]
     (for [i# 1 (length tbl#)]
       (local ,ident (. tbl# i#))
       ,...)))

{: check : each-in }
