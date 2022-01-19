(local f (require :f))
(local c (require :c))
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
            :code exports
            :pos [x y]
            :dims [w h]})
    ))

(fn draw [canvas]
  (local {:pos [x y] :dims [w h]} canvas)
  (gfx.setColor [1 1 1])
  (gfx.rectangle :line x y w h))

(fn update [canvas dt]
  (local {:debug outlbl } canvas)
  (set outlbl.text (view canvas.info)))

(set exports.make make)
(set exports.draw draw)
(set exports.update update)

exports
