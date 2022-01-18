(local fennel (require :fennel))
(local timer (require :game.timer))
(local f (require :f))
(local menu (require :ui.menu))
(local ui (require :ui))
(local assets (require :assets))
(local gfx love.graphics)
(fn pp [x] (print (fennel.view x)))

(fn get-window-size [] [(love.graphics.getWidth) (love.graphics.getHeight)])

(fn get-center [] (icollect [_ attr (ipairs (get-window-size))] (/ attr 2)))

(var total-time 0)

(var location [0 0])


(fn love.mousepressed [x y button istouch presses]
  (set love.mouse.isJustPressed true))

(fn love.load [] 
  (print "XD")

  (var y-val 0)
  (fn y+= [by] (set y-val (+ y-val by)) y-val)
  (ui.add-layer 
    [
     (menu.text [40 (y+= 40)] assets.font "FOO!")
     (menu.text [40 (y+= 30)] assets.font "BAR!")
     (menu.button [40 (y+= 30)] assets.font "QUIT!!" #(love.event.quit 0))
     ])
   (ui.add-layer [ (menu.fps [10 10]) ])
  (do))

(fn love.draw []
  (gfx.setFont assets.font)
  (ui.draw))

(fn love.update [dt]
  (ui.update dt)
  (timer.update dt)
  (set love.mouse.isJustPressed false))
