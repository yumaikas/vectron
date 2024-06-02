; A very basic collisions library


(fn pt-in-rect? [pt rect]
  "Check if point pt in contained inside rect"
  (local [x y] pt)
  (local [x1 y1 w h] rect)
  (local (x2 y2) (values (+ x1 w) (+ y1 h)))
  (and
    (> x x1)
    (< x x2)
    (> y y1)
    (< y y2)))


(fn dist-pt-line [lpt1 lpt2 xpt3] 
  ; Based on https://stackoverflow.com/a/6853926/823592
  (let [[x1 y1] lpt1
        [x2 y2] lpt2
        [x y] xpt3 
        A (- x x1)
        B (- y y1)
        C (- x2 x1)
        D (- y2 y1)
        dot (+ (* A C) (* B D))
        len_sq (+ (* C C) (* D D))
        param (if (not= len_sq 0)
                (/ dot len_sq)
                -1)
        [xx yy] (if
                  (< param 0) [x1 y1]
                  (> param 1) [x2 y2]
                  [(+ x1 (* C param))
                   (+ y1 (* D param))])
        dx (- x xx)
        dy (- y yy)
        ]
    (math.sqrt (+ (* dx dx) (* dy dy)))))

{: pt-in-rect? : dist-pt-line }
