(local gfx love.graphics)
(local f (require :f))
(local c (require :c))
(local v (require :v))

(fn hl-line [points mpos] 
  (var min-dist 4.5e15)
  (var ret nil)
  (for [i 1 (- (length points) 1)]
    (let [pt (. points i)
          next-pt (. points (+ 1 i))
          dist (c.dist-pt-line pt next-pt mpos) ]
      (when (< dist min-dist)
        (set min-dist dist)
        (set ret [pt next-pt]))))
  ret)

(fn highlighted-point [points mpos]
  (let [points (f.filter.i points #(< (v.dist mpos $) 10))]
    (when (not (f.empty? points))
      (accumulate [closest (. points 1)
                   _ pt (ipairs points)]
                  (if (> (v.dist mpos closest) (v.dist mpos pt))
                    pt
                    closest)))))

(let [polyline {}]
  (fn polyline.copy [shape]
    (let [[r g b] shape.color
          points shape.points ]
      { 
       :module polyline
       :color [r g b]
       :points (icollect [_ [x y] (ipairs points)] [x y])}))

  (fn polyline.new [x y c] 
    { :module polyline :color c :points [[x y]] })
  (fn polyline.empty [c]
    { :module polyline :color c :points [] })
  (fn polyline.draw-bg [shape color-mode] 
    (let [pt-count (length shape.points)]
      (match color-mode
        :alebedo (gfx.setColor shape.color)
        :highlight-selected (gfx.setColor [0.3 0.3 0.3]))
      (if 
        (> pt-count 1)
        (gfx.line (v.flatten shape.points))
        (= pt-count 1)
        (gfx.circle
          :line
          (. shape.points 1 1)
          (. shape.points 1 2)
          4))))

  (fn polyline.draw-selected [shape server-mode slide-offset]
    (let [pt-count (length shape.points)
          points shape.points
          [sx sy] (or slide-offset [0 0])
          (mx my) (love.mouse.getPosition)]
      (gfx.push)
      (gfx.translate sx sy)
      (if 
        (> pt-count 1)
        (do
          (gfx.setColor shape.color)
          (gfx.line (v.flatten points))
          (match server-mode
            :insert
            (let [[[x1 y1]  [x2 y2]] (hl-line points [mx my])]
              (gfx.setColor [0.2 0.2 1])
              (gfx.line x1 y1 mx my x2 y2))
            _
            (let [hpt (highlighted-point points [mx my])]
              ; Draw the hover point, w/e it is
              (when hpt
                (gfx.setColor [0.2 0.2 1])
                (gfx.circle :line (. hpt 1) (. hpt 2) 5)))))
        (= pt-count 1)
        (let [[x y] (. points 1)]
          (gfx.setColor [1 1 1])
          (gfx.circle :line x y 4))

      )
      (gfx.pop)))

  polyline)

