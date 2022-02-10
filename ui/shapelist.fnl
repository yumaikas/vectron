(local fennel (require :fennel))
(local f (require :f))
(local c (require :c))
(local v (require :v))
(import-macros {: each-in : check} :m)
(local menu (require :ui.menu))
(local {:stack ui-stack } (require :ui.containers))
(local ui (require :ui))
(local server (require :ui.server))
(local gfx love.graphics)

(fn shape-summary [shape idx] 
  ; This might have to change later...
  (values 
    [ [0 0 0] (.. idx ":") [1 1 1] (.. "#pts " (length shape.points))]
    (.. idx ": #pts " (length shape.points))))

(fn update [shapelist dt]
  (let [{:server srv
         :pos [x y]
         : font
         : children 
         :dims [w h] } shapelist
        shapes (server.shapes srv)]
    (var yval y)
    (let [h (font:getHeight)
          (mx my) (love.mouse.getPosition)
          mpos [mx my]
          shapes (server.shapes srv)
          selected (server.current-shape srv) 
          ; Assumes a mono-space font
          hlw (- (font:getWidth "0:") 2)]

      (each [idx shape (ipairs shapes)]
        (let [(fmt raw-text) (shape-summary shape idx) 
              raw-width (font:getWidth raw-text)
              ]
          (if (and (c.pt-in-rect? mpos [x yval raw-width h])
                   love.mouse.isJustPressed)
            (server.pick-shape srv shape))
          (set yval (+ yval h)))))
  (do)))

(fn draw [shapelist] 
  (let [{:server srv
         :pos [x y]
         : font
         :dims [w h]} shapelist]

    (var yval y)
    (gfx.setFont font)
    (let [h (font:getHeight)
          (mx my) (love.mouse.getPosition)
          mpos [mx my]
          shapes (server.shapes srv)
          selected (server.current-shape srv) 
          hlw (- (font:getWidth "0:") 2)]
      (each [idx shape (ipairs shapes)]
        (let [(fmt raw-text) (shape-summary shape idx) 
              raw-width (font:getWidth raw-text)
              ]
          (if (c.pt-in-rect? mpos [x yval raw-width h])
            (do
              (gfx.setColor [0.3 0.3 0])
              (gfx.rectangle :fill x yval raw-width h)))
          (gfx.setColor [1 1 1])
          (gfx.rectangle :fill x yval (- (font:getWidth "0:") 2) h)
          (gfx.print fmt x yval)

          (set yval (+ yval h)))))

    (gfx.rectangle :line x y w h)))


(fn make [server pos font] 
  (ui.annex 
    {: pos 
     : server
     : font
     :children {}
     :dims [200 300]
     :code  {: update : draw} }))


{ : make }
