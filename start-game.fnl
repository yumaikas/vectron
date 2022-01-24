(local fennel (require :fennel))
(local timer (require :game.timer))
(local f (require :f))
(import-macros {: each-in : check} :m)
(local menu (require :ui.menu))
(local canvas (require :ui.canvas))
(local {:stack ui-stack } (require :ui.containers))
(local ui (require :ui))
(local server (require :ui.server))
(local assets (require :assets))
(local gfx love.graphics)

(fn get-window-size [] [(love.graphics.getWidth) (love.graphics.getHeight)])

(fn get-center [] (icollect [_ attr (ipairs (get-window-size))] (/ attr 2)))

(var total-time 0)

(var location [0 0])

(fn love.mousepressed [x y button istouch presses]
  (set love.mouse.isJustPressed true))


(fn love.load [] 
  (print "XD")
  (each-in k [1 2 3]
        (print k))

  (var y-val 0)
  (var x-val 0)
  (fn y+= [by] (set y-val (+ y-val by)) y-val)
  (fn x+= [by] (set x-val (+ x-val by)) x-val)
  (local srv (server.make))
  (f.pp server)
  (print "QED")
  (local canvas-dbg (menu.text [300 300] assets.font ""))
  (local blot (canvas.make [30 30 550 550] canvas-dbg))
  (ui.add-layer 
    [
     (ui-stack :horizontal 
               [40 (y+= 610)] 
               [
                (menu.button [0 0] assets.font "Add Point" #(f.pp "Do stuff" ))
                (menu.text [0 0] assets.font "|")
                (menu.button [0 0] assets.font "Generate Lua" #(f.pp "Do stuff" ))
                (menu.text [0 0] assets.font "|")
                (menu.button [0 0] assets.font "QUIT!" #(love.event.quit 0))
                ])
     (canvas.make [30 30 550 550] canvas-dbg srv)
     canvas-dbg
     ])
  (ui.add-layer [ (menu.fps [10 10]) ])
  (server.start srv { :canvas blot })
  (do))

(fn love.draw []
  (gfx.setFont assets.font)
  (ui.draw))

(fn love.focus [f] 
  ; A hack to try to make it so that
  ; clicking in/out of the window works
  (set love.mouse.isJustPressed true))
(fn love.mousefocus [f] (do))

(fn love.update [dt]
  (ui.update dt)
  (timer.update dt)
  (set love.mouse.isJustPressed false))
