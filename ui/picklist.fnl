(local f (require :f))
(local c (require :c))
(local v (require :v))
(local {:annex annex} (require :ui))
(local {:view view} (require :fennel))
(local gfx love.graphics)


(fn draw [self] 
  )
(fn update [self dt] 
  )

(fn picklist [pos items] 
  (annex {: pos : items :code {: draw : update }})

{ : picklist }
