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



(fn picker-line [op t x1 y x2 mx my has-drag?] 
  (match op
    :update (let
      [cx (f.lerp x1 x2 t)
       justDown? love.mouse.isJustPressed
       justUp? love.mouse.isJustReleased
       moved? love.mouse.delta
       in-circle?  (< (v.distxyp cx y mx my) 6) ]
      (if
        (and in-circle? justDown?) (values true (f.unlerp x1 x2 mx))
        (and has-drag? justUp?) (values false (f.unlerp x1 x2 mx))
        (and has-drag? moved?) (values true (f.unlerp x1 x2 mx))
        true (values has-drag? t)))
    :draw
    (let 
      [cx (f.lerp x1 x2 t)]
      (gfx.setColor [0.8 0.8 0.8])
      (gfx.line x1 y x2 y)
      (when 
        (< (v.distxyp cx y mx my) 6)
        (gfx.setColor [1 1 1]))
      (gfx.circle (if has-drag? :fill :line) cx y 6))))

(fn update [picker dt] 
  ; TODO: Update based on mouse drag states, will need 
  ; to handle pressed/released and co.
  (let [srv picker.server
        [x y] picker.pos
        [w h] picker.dims
        curr-shape (server.current-shape srv)
        [r g b] curr-shape.color
        curr-color [r g b]
        drag-idx picker.drag-idx
        justDown? love.mouse.isJustPressed
        justUp? love.mouse.isJustReleased
        moved? love.mouse.delta
        top-y (+ y 10)
        bot-y (+ y (- h 10))
        r-x (+ x 10) 
        l-x (+ x (- w 10))
        (mx my) (love.mouse.getPosition) ]

    (var any-had-drag? false)
    (each-in idx [1 2 3]
       (let [yval (+ y (* h (/ (+ 1 idx) 5)))
             (has-drag? new-t) (picker-line :update (. curr-color idx) r-x yval l-x mx my (= drag-idx idx))]
         (tset curr-color idx new-t)
         (when has-drag?
           (set any-had-drag? true)
           (set picker.drag-idx idx))))
    ; Commit when a drag handle has been released
    (if (and love.mouse.isJustReleased picker.drag-idx)
      (server.commit-shape-color srv curr-shape curr-color)
      (server.set-shape-color srv curr-shape curr-color))
    
    (when (not any-had-drag?)
      (set picker.drag-idx nil))))

(fn draw [picker] 
  (let [[x y] picker.pos
        [w h] picker.dims ]
    (gfx.setColor assets.frame-color)
    (gfx.rectangle :line x y w h)
    ; TODO: Draw 3 lines at 1/10th of w worth of padding on each side, with sliders that lerp between the two extents of each one

    (let [srv picker.server
          top-y (+ y 10)
          bot-y (+ y (- h 10))
          r-x (+ x 10) 
          l-x (+ x (- w 10))
          drag-idx picker.drag-idx
          curr-shape (server.current-shape srv)
          [r g b] curr-shape.color
          [sr sg sb] (f.map.i curr-shape.color #(string.format "%.1f" $))
          (mx my) (love.mouse.getPosition) ]
      (gfx.print  [ [r 0.2 0.2] (.. "R:" sr " ") [0.2 g 0.2] (.. "G:" sg " ") [0.2 0.2 b] (.. "B:" sb " ") ]   
                 r-x (+ top-y (assets.font:getHeight)))
    (each-in idx [1 2 3]
      (picker-line :draw (. curr-shape.color idx) r-x (+ y (* h (/ (+ 1 idx) 5))) l-x mx my (= idx drag-idx))))))

(fn make [srv pos dims]  
  (ui.annex 
    {
     :type :color-picker
     :drag-state {}
     :color [0 0.5 0]
     :drag-idx nil
     :server srv
     :code {: update : draw}
     : pos
     : dims }))

{: make }

