(local f (require :f))
(local c (require :c))
(local v (require :v))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

(local exports {})

(fn make [rect status] 
  (local [x y w h] rect)
  (let [big (math.max w h)
        small (math.min w h)
        ratio (/ small big)
        scale (if (> w h)  
                [1.0 ratio] 
                [ratio 1.0]) ]
    (annex {
            :info 
            { 
             : scale }
            :debug status
            :points []
            :type :canvas
            :mode :add-points
            :code exports
            :pos [x y]
            :rect [x y w h]
            :dims [w h]})
    ))

(fn draw [canvas]
  (let 
    [pt-count (length canvas.points)
     {:pos [x y] :dims [w h]} canvas 
     (mx my) (love.mouse.getPosition)
     mpt [mx my] ]
    (if 

      (> pt-count 1)
      (do
        ; Lay out the line
        (gfx.setColor [0 1 0])
        (gfx.line (v.flatten canvas.points))
        ; Draw the hover point, w/e it is
        (each [_ pt (ipairs canvas.points)]
          (when (< (v.dist mpt pt) 10)
            (gfx.setColor [0.2 0.2 1])
            (gfx.circle :line (. pt 1) (. pt 2) 5))))

      (= pt-count 1)
      (let [[x y] (. canvas.points 1)]
        (gfx.circle :line x y 4)))

    (gfx.setColor [1 1 1])
    (gfx.rectangle :line x y w h)))

(fn update [canvas dt]
  (local {:debug outlbl } canvas)
  (set outlbl.text (view canvas.info))
  (let [(mx my) (love.mouse.getPosition)
        in-canvas (c.pt-in-rect? [mx my] canvas.rect) 
        just-clicked? love.mouse.isJustPressed]
    (when (and in-canvas just-clicked?)
      (pp "LORRE")
      (table.insert
        canvas.points [mx my])))
  )

(set exports.make make)
(set exports.draw draw)
(set exports.update update)

exports
