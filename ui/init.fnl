(local f (require :f))
(local c (require :c))
(import-macros {: check} :m)
(local {:view view} (require :fennel))
(local gfx love.graphics)

(local MODULE {})
(fn is-mine? [e] (= MODULE (. e MODULE)))
(fn annex [tbl] (tset tbl MODULE MODULE) tbl)
(fn pp [obj] (print (view obj)))
(var layers {})


(fn add-layer [layer]
  (check (f.all? layer is-mine?) "Element constructed outside of module found!")
  (table.insert layers (annex layer))
  (pp layers))

(fn swap-layers [new-layers] 
  (check (f.all? new-layers is-mine?) "Layers constructed outside of UI module!")
  (set layers new-layers))

(fn get-layers [] 
  layers)

(fn init [])

(fn update [dt] 
  (local (mx my) (love.mouse.getPosition))
  (each [_ layer (ipairs layers)]
    (each [_ el (ipairs layer)]
      (match el
        { :code {:update el-update } MODULE MODULE}
        (el-update el dt)
        {:type :text
         :pos [x y]
         :font fnt
         :text txt
         MODULE MODULE } 
        (do 
          (gfx.setFont fnt)
          (gfx.print txt x y))
        {:type :fps} (do)


        _ (error (.. "Unmatched element in update " (view el)))

      ))
  ))

(fn draw [] 
  (local (mx my) (love.mouse.getPosition))
  (each [_ layer (ipairs layers)]
    (each [_ el (ipairs layer)]
      (match el
        { :code {:draw el-draw } MODULE MODULE}
        (el-draw el)
        { :pos [fx fy] :type "fps" MODULE MODULE } 
        (do
          (gfx.print (love.timer.getFPS) fx fy))
        {:type :text
         :pos [x y]
         :font fnt
         :text txt
         MODULE MODULE } 
        (do 
          (gfx.setColor [ 1 1 1 ])
          (gfx.setFont fnt)
          (gfx.print txt x y))
        _ (error (.. "Unmatched element in draw" (view el)))
        )
  )))


{
 : add-layer
 : get-layers
 : swap-layers
 : update
 : draw
 : init
 : annex
 }
