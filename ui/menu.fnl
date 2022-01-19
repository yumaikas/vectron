(local f (require :f))
(local c (require :c))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

; Used to keep track that everything came from this module

(fn update-button [button dt] 
  (local (mx my) (love.mouse.getPosition))
  (local 
    {
     :pos [px py]
     :drawn-txt txt-drawn
     :on-click click } button)
    (local (w h) (txt-drawn:getDimensions))
    (local x px)
    (local y py)
    (when (and
            (c.pt-in-rect? [mx my] [x y w h])
            love.mouse.isJustPressed)
      (click)))

(fn draw-button [button]
  (local (mx my) (love.mouse.getPosition))
  (local 
    { :pos [px py]
     :drawn-txt txt-drawn } button)
  (local (w h) (txt-drawn:getDimensions))
  (local x px)
  (local y py)
  (when (c.pt-in-rect? [mx my] [x y w h])
    (gfx.setColor [ 1 0 1 ])
    (gfx.polygon :fill
                 [(- x 3) y
                  (+ x w) y
                  (+ x w) (+ y h)
                  (- x 3) (+ y h)]))
  (gfx.setColor [ 1 1 1 ])
  (gfx.draw txt-drawn px py))


(fn button [pos font text on-click] 
  (local txt (gfx.newText font text))
  (annex {
          :type :button
          :drawn-txt txt
          : pos
          :code {:update update-button 
                  :draw draw-button }
          : on-click }))

(fn text [pos font text]
  (annex {:type :text
          : font
          : pos
          : text }))

(fn image [rect image]
  (annex {:type :image
          : rect
          : image }))

(fn fps [pos] 
  (annex {:type :fps : pos}))

{
 : text
 : image
 : button
 : fps
 }
