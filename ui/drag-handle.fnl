(local f (require :f))
(local c (require :c))
(local v (require :v))
(import-macros {: each-in } :m)
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

(fn draw [me] 
  (local [px py] me.pos)
  (gfx.push)
  (gfx.translate px py)
  (gfx.rectangle :fill 0 0 10 10)
  (gfx.pop))

(fn update [me]
  (let [{ : field : pos : start : start-pos } me
        (mx my) (love.mouse.getPosition)]
    (local rect [(. me.pos 1) (. me.pos 2) 10 10])


    (when (and (c.pt-in-rect? [mx my] rect) love.mouse.isJustPressed)
      (set me.is-dragging true))
    (when (and me.is-dragging love.mouse.isJustReleased)
      (set me.is-dragging false))
    (when (and love.mouse.delta me.is-dragging)
      (set me.pos (v.add love.mouse.delta me.pos))
      (local total-delta (v.sub me.pos me.start-pos))
      (field.set (v.add start total-delta)))
    )
  )

(fn make [field pos] 

  (annex
  {
   :is-dragging false
   :code { : draw : update }
   :start (field.get)
   : pos
   :start-pos pos
   : field }))

{: make }
