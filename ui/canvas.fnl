(local f (require :f))
(local c (require :c))
(local v (require :v))
(local server (require :ui.server))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)
(local polyline (require :ui.shapes.polyline))
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
  (let [points (f.filter.i points #(< (v.dist mpos $) 10))]
    (when (not (f.empty? points))
      (accumulate [closest (. points 1)
                   _ pt (ipairs points)]
                  (if (> (v.dist mpos closest) (v.dist mpos pt))
                    pt
                    closest)))))

(fn draw [canvas]
  (let 
    [points (server.points canvas.server)
     curr-shape (server.current-shape canvas.server) 
     bg-shapes (f.filter.i (server.shapes canvas.server) #(not= $ curr-shape))
     {:mode mode} (server.mode canvas.server)
     color-mode (server.color-mode canvas.server)
     slide-offset (server.slide-offset canvas.server)
     pt-count (length curr-shape.points)
     {:pos [x y] :dims [w h]} canvas 
     (mx my) (love.mouse.getPosition)
     [cmx cmy] (v.sub [mx my] canvas.pos)
     mpt [cmx cmy] ]
    (gfx.push)
    (gfx.translate x y)
    (each-in bgs bg-shapes 
      (bgs.module.draw-bg bgs color-mode))

    (curr-shape.module.draw-selected curr-shape mode slide-offset)

    (gfx.setColor [1 1 1])
    (gfx.rectangle :line 0 0 w h)
    (gfx.pop)
    ))

(fn update [canvas dt]
  (tset canvas.rect 1 (. canvas.pos 1))
  (tset canvas.rect 2 (. canvas.pos 2))
  (local {:debug outlbl :server srv } canvas)
  (local {:mode  mode} (server.mode srv))
  (set outlbl.text (view canvas.info))
  (let [(mx my) (love.mouse.getPosition)
        [cmx cmy] (v.sub [mx my] canvas.pos)
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
        (server.add-point srv [cmx cmy])
        :insert
        (when (> (length points) 1)
          (let [[_ after] (hl-line points [cmx cmy])]
            (server.insert-point srv after [cmx cmy])))
        :delete
        (let [hlpt (highlighted-point points [cmx cmy])]
          (when hlpt
            (server.remove-point srv hlpt)))
        :move
        (let [hlpt (highlighted-point points [cmx cmy])]
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
          (server.end-drag srv canvas.drag-handle [cmx cmy])
          (set canvas.drag-handle nil))))
    (when mouse-moved?
      (match mode
        :slide
        (when canvas.slide
          (server.update-slide srv [mx my]))
        :move
        (when canvas.drag-handle
          (server.update-drag srv canvas.drag-handle [cmx cmy]))))))

(set exports.make make)
(set exports.draw draw)
(set exports.update update)

exports
