(local f (require :f))
(local c (require :c))
(local {:view view} (require :fennel))
(local gfx love.graphics)

; Used to keep track that everything came from this module

(local MODULE {})
(fn is-mine? [e] (= MODULE (. e MODULE)))
(fn annex [tbl] (tset tbl MODULE MODULE) tbl)
(fn pp [obj] (print (view obj)))
(var layers {})

(fn add-layer [layer]
  (or (f.all? layer is-mine?) (error "Element constructed outside of module found!"))
  (table.insert layers (annex layer))
  (pp layers))

(fn swap-layers [new-layers] 
  (or (f.all? new-layers is-mine?) (error "Layers constructed outside of UI module!"))
  (set layers new-layers))

(fn get-layers [] 
  layers)

(fn button [pos font text on-click] 
  (local txt (gfx.newText font text))

  (annex {
          :type :button
          :drawn-txt txt
          : pos
          : on-click }))

(fn text [pos font text]
  (annex {:type :text
          : font
          : pos
          : text }))

(fn image [rect image]
  (annex {:type :image
          : rect
          : image }))

(fn init []
  )

(fn update [dt] 
  (local (mx my) (love.mouse.getPosition))
  (each [_ layer (ipairs layers)]
    (each [_ el (ipairs layer)]
      (match el
        {:type :text
         :pos [x y]
         :font fnt
         :text txt
         MODULE MODULE } 
        (do 
          (gfx.setFont fnt)
          (gfx.print txt x y))
        {:type :button
         :pos [px py]
         :drawn-txt txt-drawn
         :on-click click
         MODULE MODULE } 
        (do
          (local (w h) (txt-drawn:getDimensions))
          (local x px)
          (local y py)
          (when (and
                  (c.pt-in-rect? [mx my] [x y w h])
                  love.mouse.isJustPressed)
            (click)
            ))


        _ (error (.. "Unmatched element " (view el)))

      ))
  ))

(fn draw [] 
  (local (mx my) (love.mouse.getPosition))
  (each [_ layer (ipairs layers)]
    (each [_ el (ipairs layer)]
      (match el
        {:type :text
         :pos [x y]
         :font fnt
         :text txt
         MODULE MODULE } 
        (do 
          (gfx.setColor [ 1 1 1 ])
          (gfx.setFont fnt)
          (gfx.print txt x y))
        {:type :button
         :pos [px py]
         :drawn-txt txt-drawn
         MODULE MODULE } 
        (do
          (local (w h) (txt-drawn:getDimensions))
          (local x px)
          (local y py)
          (when (c.pt-in-rect? [mx my] [x y w h])
            (gfx.setColor [ 1 0 1 ])
            (gfx.polygon :fill
                         [(- x 3) y
                          (+ x w) y
                          (+ x w) (+ y h)
                          (- x 3) (+ y h)]))
          (gfx.setColor [ 1 1 1 ])
          (gfx.draw txt-drawn px py))


        _ (error (.. "Unmatched element " (view el)))
        )
  )))


{
 : add-layer
 : get-layers
 : swap-layers
 : text
 : image
 : button
 : update
 : draw
 : init
 }
