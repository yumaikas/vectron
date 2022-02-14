(local fennel (require :fennel))
(local f (require :f))
(local c (require :c))
(local v (require :v))
(import-macros {: each-in : check} :m)
(local menu (require :ui.menu))
(local {:stack ui-stack } (require :ui.containers))
(local ui (require :ui))
(local assets (require :assets))
(local server (require :ui.server))
(local gfx love.graphics)


(fn update [picker dt] 
  ; TODO: Update based on mouse drag states, will need 
  ; to handle pressed/released and co.
  (do))

(fn picker-line [op t x1 y x2 mx my] 
  (match op
    :update (do)
    :draw
    (let [cx (f.lerp x1 x2 t)]
      (gfx.setColor [0.8 0.8 0.8])
      (gfx.line x1 y x2 y)
      (when (< (v.distxyp cx y mx my) 6)
        (gfx.setColor [1 1 1]))
      (gfx.circle :line cx y 6))))

(fn draw [picker] 
  (let [[x y] picker.pos
        [w h] picker.dims
        [r g b] picker.color ]
    (gfx.setColor assets.frame-color)
    (gfx.rectangle :line x y w h)
    ; TODO: Draw 3 lines at 1/10th of w worth of padding on each side, with sliders that lerp between the two extents of each one

    (let [top-y (+ y 10)
          bot-y (+ y (- h 10))
          r-x (+ x 10) 
          l-x (+ x (- w 10))
          y1 (math.floor (+ y (* h (/ 1 4))))
          y2 (math.floor (+ y (* h (/ 2 4))))
          y3 (math.floor (+ y (* h (/ 3 4))))
          (mx my) (love.mouse.getPosition)
          ]
      (picker-line :draw r r-x y1 l-x mx my)
      (picker-line :draw g r-x y2 l-x mx my)
      (picker-line :draw b r-x y3 l-x mx my)

      )


    ))

(fn make [srv pos dims]  
  (ui.annex 
    {
     :type :color-picker
     :drag-state {}
     :color [0 0.5 0]
     :server srv
     :code {: update : draw}
     : pos
     : dims }))

{: make }

