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

{: pt-in-rect?}
