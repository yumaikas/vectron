(fn check [exp err]
  `(or ,exp (error ,err)))

(fn each-in [ident tbl body]
  `(let [tbl# ,tbl]
     (for [i# 1 (length tbl#)]
       (local ,ident (. tbl# i#))
       ,body)))

{: check : each-in }
