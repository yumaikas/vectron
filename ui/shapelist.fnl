(local fennel (require :fennel))
(local f (require :f))
(local v (require :v))
(import-macros {: each-in : check} :m)
(local menu (require :ui.menu))
(local {:stack ui-stack } (require :ui.containers))
(local ui (require :ui))
(local server (require :ui.server))
(local gfx love.graphics)

(fn update [shapelist dt]
  (let [{:server srv
         :pos [x y]
         :dims [w h] } shapelist]
  (do)))

(fn draw [shapelist] 
  (let [{
         :server srv
         :pos [x y]
         : font
         :dims [w h]} shapelist]

    (var yval y)
    (gfx.setFont font)
    (let [h (font:getHeight)
          shapes (server.shapes srv)
          selected (server.current-shape srv) ]
      (each-in shape shapes
         (gfx.print (length shape.points)  x yval)
         (set yval (+ yval h)))
      )
    (gfx.rectangle :line x y w h)))


(fn make [server pos font] 
  (ui.annex 
    {
     : pos 
     : server
     : font
     :dims [200 300]
     :code  {: update : draw} }))


{ : make }
