(local f (require :f))
(local c (require :c))
(local v (require :v))
(import-macros {: each-in } :m)
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

(fn layout [self] 
  (f.pp "LAYOUT")
  (var x-extent 0)
  (var y-extent 0)
  (var coord [(. self.pos 1) (. self.pos 2)])
  (each-in child self.children
    (when child.code.layout
      (child.code.layout child)))

  (local move-coord 
    (if 
      (= self.dir :vertical)

      (fn [el] 
        (let 
          [[cx cy] coord
           [w h] el.dims]
          (set el.pos [cx cy])
          (set x-extent (math.max x-extent w))
          (set coord (v.add coord [0 h]))))
      (= self.dir :horizontal)
      (fn [el] 
        (let 
          [[cx cy] coord
           [w h] el.dims]
          (set el.pos [cx cy])
          (set y-extent (math.max y-extent h))
          (set coord (v.add coord [w 0]))))))
  (each-in child self.children
    (move-coord child)
    (when child.code.layout
      (child.code.layout child)))
  (set self.dims 
       (let [[cx cy] coord
             [px py] self.pos
             xmax (math.max cx x-extent)
             ymax (math.max cy y-extent) ]
         [(- xmax px)
          (- ymax py)])))

(fn draw [self]
  (each-in child self.children
        (child.code.draw child)))

(fn update [self dt]
  (each-in child self.children
         (child.code.update child dt)))

(fn can-stack? [el] el.code)
(lambda stack [dir pos children] 
  (or (f.all? children can-stack?) 
      (error (.. "Child in stack doesn't know how to draw itself!"
                 (view (f.find children #(not (can-stack? $)))))))
  (let 
    [me (annex {
                : pos
                : dir
                :dims [0 0]
                : children
                :code {: draw : update : layout}
                })]
    me))

{ : stack }
