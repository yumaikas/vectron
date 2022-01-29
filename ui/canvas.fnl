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

            :do-place (fn [self xratio yratio] (ratio-place xratio yratio self.rect))

            :pos [x y]
            :rect [x y w h]
            :dims [w h]})
    ))

(fn highlighted-point [points mpos]
  (f.find points #(< (v.dist mpos $) 10)))

(fn draw [canvas]
  (let 
    [points (. (server.get-state canvas.server) :points)
     pt-count (length points)
     {:pos [x y] :dims [w h]} canvas 
     (mx my) (love.mouse.getPosition)
     mpt [mx my] ]
    (if 

      (> pt-count 1)
      (do
        ; Lay out the line
        (gfx.setColor [0 1 0])
        (gfx.line (v.flatten points))
        ; Draw the hover point, w/e it is
        (let [hpt (highlighted-point points [mx my])]
          (when hpt
            (gfx.setColor [0.2 0.2 1])
            (gfx.circle :line (. hpt 1) (. hpt 2) 5))))

      (= pt-count 1)
      (let [[x y] (. points 1)]
        (gfx.circle :line x y 4)))

    (gfx.setColor [1 1 1])
    (gfx.rectangle :line x y w h)))

(fn update [canvas dt]
  (local {:debug outlbl :server srv } canvas)
  (local {: mode} (server.get-state srv))
  (set outlbl.text (view canvas.info))
  (let [(mx my) (love.mouse.getPosition)
        points (server.points srv)
        in-canvas (c.pt-in-rect? [mx my] canvas.rect) 
        just-clicked? love.mouse.isJustPressed]
    (when (and in-canvas just-clicked?)
      ; Do things based on current mode
      (match mode 
        :add
        (server.add-point srv [mx my])
        :delete
        (let [hlpt (highlighted-point points [mx my])]
          (when hlpt
            (server.remove-point srv hlpt)))

      ))))

(set exports.make make)
(set exports.draw draw)
(set exports.update update)

exports
