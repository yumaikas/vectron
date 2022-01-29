(import-macros {: each-in : check} :m)
(local {: view} (require :fennel))
(local f (require :f))

(fn add [a b] 
  (let [[x1 y1] a
        [x2 y2] b]
    [(+ x1 x2) (+ y1 y2)]))

(fn sub [a b] 
  (let [[x1 y1] a
        [x2 y2] b]
    [(- x1 x2) (- y1 y2)]))

(fn flatten [pts] 
  (accumulate [nums {}
               _ d (ipairs pts)]
              (do 
                (each-in n d
                  (table.insert nums n))
                nums)))
(fn dist [v1 v2]
  (check v1 "v1 nil in dist!")
  (check v2 "v2 nil in dist!")
  (let [[x1 y1] v1
        [x2 y2] v2]
  (math.sqrt 
    (+
     (math.pow (- x2 x1) 2)
     (math.pow (- y2 y1) 2)))))

{ : add : sub : flatten : dist }

