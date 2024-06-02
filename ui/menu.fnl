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
     : txt
     :on-click click } button)
    (local x px)
    (local y py)
    (local (w h) (txt:getDimensions))
    (when (and
            (c.pt-in-rect? [mx my] [x y w h])
            love.mouse.isJustPressed)
      (click)))

(fn draw-button [button]
  (local (mx my) (love.mouse.getPosition))
  (local 
    { :pos [px py]
     : txt } button)
  (local (w h) (txt:getDimensions))
  (local x px)
  (local y py)
  (when (c.pt-in-rect? [mx my] [x y w h])
    (gfx.setColor [ 1 0.5 1 ])
    (gfx.polygon :fill
                 [(- x 3) y
                  (+ x w) y
                  (+ x w) (+ y h)
                  (- x 3) (+ y h)]))
  (gfx.setColor [ 1 1 1 ])

  (gfx.draw txt px py))

(fn update-key-button [button dt] 
  (local (mx my) (love.mouse.getPosition))
  (local 
    {
     :pos [px py]
     : txt
     :on-click click } button)
    (local x px)
    (local y py)
    (local (w h) (txt:getDimensions))
    (when (> button.press-fade 0)
      (set button.press-fade (- button.press-fade dt)))
    (when (and
            (c.pt-in-rect? [mx my] [x y w h])
            love.mouse.isJustPressed)
      (click)))

(fn draw-key-button [button dt]
  (local (mx my) (love.mouse.getPosition))
  (local 
    { :pos [px py]
     :hl-dims [hlw hlh]
     : press-fade
     : txt } button)
  (local (w h) (txt:getDimensions))
  (local x px)
  (local y py)
  (when (> press-fade 0) 
    (gfx.setColor [ 0.5 0.5 0.5 ])
    (gfx.polygon :fill
                 [(- x 3) y
                  (+ x w) y
                  (+ x w) (+ y h)
                  (- x 3) (+ y h)]))
  (when (c.pt-in-rect? [mx my] [x y w h])
    (gfx.setColor [ 1 0.5 1 ])
    (gfx.polygon :fill
                 [(- x 3) y
                  (+ x w) y
                  (+ x w) (+ y h)
                  (- x 3) (+ y h)]))
  (gfx.setColor [ 1 1 1 ])
  (gfx.rectangle :fill (- px 2) py (+ hlw 2) hlh)
  (gfx.draw txt px py))


(fn set-text [el new-text]
  ; TODO: If this is used anywhere it would be 
  ; relevant, figure out how to invalidate layout.
  ; But it is not just yet

  (el.txt:set new-text)
  
  (set el.dims (let [(w h) (el.txt:getDimensions)]
                  (v.add [w h] [10 0]))))

(fn key-button [pos font key-hl text on-click]
  (local hl-dims [(font:getWidth key-hl) (font:getHeight)])
  (local txt (gfx.newText font 
    [
     [0 0 0] key-hl
     [1 1 1] text
     ]))
  (local (w h) (txt:getDimensions))
  (annex {
          :type :key-button
          : txt
          : pos
          : hl-dims
          : set-text
          :press-fade 0
          :press (fn [self] (set self.press-fade 0.1))
          :dims (v.add [w h] [10 0])
          :code { :update update-key-button
                 :draw draw-key-button }
          : on-click
          }))

(fn button [pos font text on-click] 
  (local txt (gfx.newText font text))
  (local (w h) (txt:getDimensions))
  (annex {
          :type :button
          : txt
          : pos
          : set-text
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
          : set-text
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
 : key-button
 : fps
 }
