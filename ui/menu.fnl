(local f (require :f))
(local c (require :c))
(local v (require :v))
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
    (local x px)
    (local y py)
    (local (w h) (txt-drawn:getDimensions))
    (when (and
            (c.pt-in-rect? [mx my] [x y w h])
            love.mouse.isJustPressed)
      (f.pp "CLICK")
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
    (f.pp love.mouse.isJustPressed)
    (gfx.setColor [ 1 0.5 1 ])
    (gfx.polygon :fill
                 [(- x 3) y
                  (+ x w) y
                  (+ x w) (+ y h)
                  (- x 3) (+ y h)]))
  (gfx.setColor [ 1 1 1 ])
  (gfx.draw txt-drawn px py))


(fn button [pos font text on-click] 
  (local txt (gfx.newText font text))
  (local (w h) (txt:getDimensions))
  (annex {
          :type :button
          :drawn-txt txt
          : pos
          :dims (v.add [w h] [10 0])
          :code {:update update-button 
                  :draw draw-button }
          : on-click }))

(fn text [pos font text]
  (local txt (gfx.newText font text))
  (local (w h) (txt:getDimensions))
  (annex {:type :text
          : font
          :code {
                 :update (fn [self dt]) 
                 :draw (fn [self dt] (gfx.draw self.txt (unpack self.pos)) ) } 
          :dims (v.add [w h] [10 0])
          : pos
          : txt }))

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
