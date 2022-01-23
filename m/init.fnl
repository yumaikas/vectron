(fn check [exp err]
  `(or ,exp (error ,err)))

{: check}
