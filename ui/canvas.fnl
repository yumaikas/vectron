(local f (require :f))
(local c (require :c))
(local v (require :v))
(local server (require :ui.server))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)
(import-macros {: each-in} :m)

(local exports {})

(fn ratio-place [xratio yratio rect] 
  (let [[x y w h] rect ]
    [(+ x (* w xratio)) (+ y (* h yratio))]))

(fn point->ratio [point rect] 
  (let [[px py] point
        [x y w h] rect]
    [(/ (- px x) w) (/ (- py y) h)]))

(fn make [rect status srv] 
  (local [x y w h] rect)
  (let [big (math.max w h)
        small (math.min w h)
        ratio (/ small big)
        scale (if (> w h)  
                [1.0 ratio] 
                [ratio 1.0]) ]
    (annex {
            :info 
            { : scale }
            :server srv 
            :debug status
            :type :canvas
            :code { :update exports.update 
                   :draw exports.draw }
            :drag-handle nil

            :do-place (fn [self xratio yratio] (ratio-place xratio yratio self.rect))

            :pos [x y]
            :rect [x y w h]
            :dims [w h]})
    ))

(fn hl-line [points mpos] 
  (var min-dist 4.5e15)
  (var ret nil)
  (for [i 1 (- (length points) 1)]
    (let [pt (. points i)
          next-pt (. points (+ 1 i))
          dist (c.dist-pt-line pt next-pt mpos) ]
      (when (< dist min-dist)
        (set min-dist dist)
        (set ret [pt next-pt]))))
  ret)

(fn highlighted-point [points mpos]
  (f.find points #(< (v.dist mpos $) 10)))

(fn draw [canvas]
  (let 
    [points (server.points canvas.server)
     curr-shape (server.current-shape canvas.server) 
     offset (server.slide-offset canvas.server)
     bg-shapes (f.filter.i (server.shapes canvas.server) #(not= $ curr-shape))
     {:mode mode} (server.mode canvas.server)
     pt-count (length points)
     {:pos [x y] :dims [w h]} canvas 
     (mx my) (love.mouse.getPosition)
     mpt [mx my] ]

    (each-in bgs bg-shapes 
      (let [pt-count (length bgs.points)]
        (gfx.setColor [0.5 0.5 0.5])
        (if 
          (> pt-count 1)
          (gfx.line (v.flatten bgs.points))
          (= pt-count 1)
          (gfx.circle 
            :line 
            (. bgs.points 1 1) 
            (. bgs.points 1 2) 
            4))))

    (if 
      (> pt-count 1)
      (do
        ; Lay out the line
        (gfx.setColor [0 1 0])
        (gfx.line (v.flatten points))
        (match mode
          :insert 
          (let [[[x1 y1] [x2 y2]] (hl-line points [mx my])]
            (gfx.setColor [0.2 0.2 1])
            (gfx.line x1 y1 mx my x2 y2))
          _ 
          (let [hpt (highlighted-point points [mx my])]
            ; Draw the hover point, w/e it is
            (when hpt
              (gfx.setColor [0.2 0.2 1])
              (gfx.circle :line (. hpt 1) (. hpt 2) 5)))))
      (= pt-count 1)
      (let [[x y] (. points 1)]
        (gfx.circle :line x y 4)))

    (gfx.setColor [1 1 1])
    (gfx.rectangle :line x y w h)))

(fn update [canvas dt]
  (local {:debug outlbl :server srv } canvas)
  (local {:mode  mode} (server.mode srv))
  (set outlbl.text (view canvas.info))
  (let [(mx my) (love.mouse.getPosition)
        points (server.points srv)
        in-canvas (c.pt-in-rect? [mx my] canvas.rect) 
        just-pressed? love.mouse.isJustPressed
        just-released? love.mouse.isJustReleased 
        mouse-moved? love.mouse.delta
        ]
    (when (and in-canvas just-pressed?)
      ; Do things based on current mode
      (match mode 
        :add
        (server.add-point srv [mx my])
        :insert
        (let [[_ after] (hl-line points [mx my])]
          (server.insert-point srv after [mx my]))
        :delete
        (let [hlpt (highlighted-point points [mx my])]
          (when hlpt
            (server.remove-point srv hlpt)))
        :move
        (let [hlpt (highlighted-point points [mx my])]
          (when hlpt
              (set canvas.drag-handle (server.begin-drag srv hlpt))))
        :slide 
        (do
          (set canvas.slide true)
          (server.begin-slide srv [mx my]))
      ))
    (when just-released? 
      (match mode
        :slide 
        (when canvas.slide 
          (set canvas.slide false)
          (server.end-slide srv [mx my]))
        :move
        (when canvas.drag-handle
          (server.end-drag srv canvas.drag-handle [mx my])
          (set canvas.drag-handle nil))))
    (when mouse-moved?
      (match mode
        :slide
        (when canvas.slide
          (server.update-slide srv [mx my]))
        :move
        (when canvas.drag-handle
          (server.update-drag srv canvas.drag-handle [mx my]))))))

(set exports.make make)
(set exports.draw draw)
(set exports.update update)

exports
