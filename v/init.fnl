(local f (require :f))

(fn add [a b] 
  (let [[x1 y1] a
        [x2 y2] b]
    [(+ x1 x2) (+ y1 y2)]))

{ : add }

