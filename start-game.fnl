(local fennel (require :fennel))
(local timer (require :game.timer))
(local f (require :f))
(local v (require :v))
(local command-map (require :ui.cmd))
(local shapelist (require :ui.shapelist))
(import-macros {: each-in : check} :m)
(local menu (require :ui.menu))
(local canvas (require :ui.canvas))
(local color-picker (require :ui.color-picker))
(local {:stack ui-stack } (require :ui.containers))
(local ui (require :ui))
(local drag-handle (require :ui.drag-handle))
(local server (require :ui.server))
(local assets (require :assets))
(local gfx love.graphics)


(set love.keys {})
(set love.keys.justPressed {})
(set love.keys.down {})

(fn get-window-size [] [(love.graphics.getWidth) (love.graphics.getHeight)])

(fn get-center [] (icollect [_ attr (ipairs (get-window-size))] (/ attr 2)))

(var total-time 0)

(fn love.mousepressed [x y button istouch presses]
  (set love.mouse.isJustPressed true))

(fn love.mousereleased [x y button istouch]
  (set love.mouse.isJustReleased true))

(fn love.mousemoved [x y dx dy] 
  (when (or (not= dx 0) (not= dy 0))
    (set love.mouse.delta [dx dy])))

(fn love.keypressed [_ scancode isrepeat] 
  (tset love.keys.down scancode true)
  (tset love.keys.justPressed scancode true))

(fn love.keyreleased [_ scancode] 
  (tset love.keys.down scancode nil))

(fn pos-dragger [obj pos] 
  (local field 
    {
     :get #(. obj :pos)
     :set #(set obj.pos $)
     })

  (drag-handle.make field pos))


(fn love.load [] 

  ; Make these configurable?
  (gfx.setLineStyle :rough)
  ; TODO: Switch to none
  (gfx.setLineJoin :none)
  (gfx.setLineWidth 1)

  (var y-val 0)
  (var x-val 0)
  (fn y+= [by] (set y-val (+ y-val by)) y-val)
  (fn x+= [by] (set x-val (+ x-val by)) x-val)
  (local srv (server.make))
  (local fore-color-field {})
  (fn fore-color-field.set [to] 
    (let [curr-shape (server.current-shape srv)]
    (server.set-shape-color srv curr-shape to)))
  (fn fore-color-field.get [] 
    (let [curr-shape (server.current-shape srv)]
      curr-shape.color))
  (fn fore-color-field.commit [to] 
    (let [curr-shape (server.current-shape srv)]
      (server.commit-shape-color srv curr-shape to)))

  (local canvas-dbg (menu.text [300 300] assets.font ""))
  (local blot (canvas.make [15 30 360 600] canvas-dbg srv))
  (local blot-dragger (pos-dragger blot [375 30]))

  (server.start srv { :canvas blot })
  (ui.add-layer 
    [
     blot
     blot-dragger
     canvas-dbg

     (command-map.make srv [40 850])
     (shapelist.make srv [630 30] [200 300] assets.font)
     (color-picker.make "Line Color" fore-color-field [630 340] [200 140])
     (color-picker.make "Fill Color" fore-color-field [630 (+ 150 340)] [200 140])
     ])
  (ui.add-layer [ (menu.fps [10 10]) ])

  ; (let [(maj min rev codename) (love.getVersion)]
  ;  (f.pp [maj min rev codename]))
  )

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
  (set love.mouse.isJustPressed false)
  (set love.mouse.isJustReleased false)
  (set love.mouse.delta nil)
  (each [k (pairs love.keys.justPressed)]
    (tset love.keys.justPressed k nil))
  )
