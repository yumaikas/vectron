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

;; This is an attempt at a preformance improvment
(fn flatten-into [pts dest]
  (var destidx 1)
  (for [i 1 (length pts)]
    (tset dest destidx (. pts i 1))
    (tset dest (+ 1 destidx) (. pts i 2))
    (set destidx (+ 2 destidx)))
  ; Clear out unused spaces
  (for [i destidx (length dest)]
    (tset dest i nil)))

(fn dist [v1 v2]
  (check v1 "v1 nil in dist!")
  (check v2 "v2 nil in dist!")
  (let [[x1 y1] v1
        [x2 y2] v2]
  (math.sqrt 
    (+
     (math.pow (- x2 x1) 2)
     (math.pow (- y2 y1) 2)))))

(fn distxyp [x1 y1 x2 y2]
  (math.sqrt 
    (+
     (math.pow (- x2 x1) 2)
     (math.pow (- y2 y1) 2))))

(fn mag [a]
  (let [[x y] a]
  (math.sqrt (+ (* x x) (* y y)))))

(fn unit [a]
  (let [[x y] a
        m (mag a)]
    [(/ x m) (/ y m)]))

(fn angle-of [a b]
  (let [[ax ay] a
        [bx by] b
        ; Based on https://stackoverflow.com/a/16544330/823592
        dot (+ (* ax bx) (* ay by))
        det (- (* ax by) (* ay bx))
        ]
     (math.atan det dot)))

(fn dot [a b]
  (let [[ax ay] a
        [bx by] b ]
        ; Based on https://stackoverflow.com/a/16544330/823592
        (+ (* ax bx) (* ay by))))

(fn project-point-onto-line [lpt1 lpt2 xpt3] 
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
                -1) ]
    (if
      (< param 0) [x1 y1]
      (> param 1) [x2 y2]
      [(+ x1 (* C param))
       (+ y1 (* D param))])))

(fn project-onto [a b]
  (let [m (mag a)
        angle-mult (math.cos (angle-of a b))
        [ux uy] (unit b)
        full-mult (* m angle-mult) ]
    [(* ux full-mult) (* uy full-mult)]))



{ : add : sub : flatten : flatten-into : dist : distxyp : dot : angle-of : unit : project-onto }

