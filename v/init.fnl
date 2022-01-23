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
                (for [i 1 (length d)]
                  (table.insert nums (. d i)))
                nums)))
(fn dist [v1 v2]
  (let [[x1 y1] v1
        [x2 y2] v2]
  (math.sqrt 
    (+
     (math.pow (- x2 x1) 2)
     (math.pow (- y2 y1) 2)))))

{ : add : sub : flatten : dist }

