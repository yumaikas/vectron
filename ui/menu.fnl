(local f (require :f))
(local c (require :c))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)

; Used to keep track that everything came from this module

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

(fn fps [pos] 
  (annex {:type :fps : pos}))

{
 : text
 : image
 : button
 : fps
 }
