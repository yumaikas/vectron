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

(fn draw [picker] 
  (let [[x y] picker.pos
        [w h] picker.dims]
    (gfx.setColor assets.frame-color)
    (gfx.rectangle :line x y w h)
    ; TODO: Draw 3 lines at 1/10th of w worth of padding on each side, with sliders that lerp between the two extents of each one
    ))

(fn make [srv pos dims]  
  (ui.annex 
    {
     :type :color-picker
     :drag-state {}
     :color [0 0 0]
     :server srv
     :code {: update : draw}
     : pos
     : dims }))

{: make }

