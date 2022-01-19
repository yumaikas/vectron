(local f (require :f))
(local c (require :c))
(local v (require :v))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

(fn layout [self] 
  (var coord [(. self.pos 1) (. self.pos 2)])
  (local move-coord 
    (if 
      (= self.dir :vertical)

      (fn [el] 
        (let 
          [[cx cy] coord
           [w h] el.dims]
          (set el.pos [cx cy])
          (set coord (v.add coord [0 h]))))
      (= self.dir :horizontal)
      (fn [el] 
        (let 
          [[cx cy] coord
           [w h] el.dims]
          (set el.pos [cx cy])
          (set coord (v.add coord [w 0]))))))
  (each [_ child (ipairs self.children)]
    (move-coord child)))

(fn draw [self]
  (each [_ child (ipairs self.children)]
    (child.code.draw child)))

(fn update [self])

(fn can-stack? [el] el.code)
(fn stack [dir pos children] 
  (or (f.all? children can-stack?) 
      (error (.. "Child in stack doesn't know how to draw itself!"
                 (view (f.find children #(not (can-stack? $)))))))
  (let 
    [me (annex {
                : pos
                : dir
                : children
                :code {: draw : update}
                })]
    (layout me) me))

{
 :stack stack
 }
