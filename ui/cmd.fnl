(import-macros {: check : each-in } :m)
(local {: annex} (require :ui))
(local {:stack ui-stack} (require :ui.containers))
(local ui (require :ui))
(local menu (require :ui.menu))
(local assets (require :assets))
(local f (require :f))
(local server (require :ui.server))

(fn draw [me]
  (me.rows.code.draw me.rows))

(fn update [me dt] 

  (local {:element-map elements
          :server srv } me)
  (let [{:mode mode} elements]
    (mode:set-text (: (server.mode srv) :gsub "^%l" string.upper)))

  ; Forward events and such
  (me.rows.code.update me.rows))

(fn make [srv pos] 

  (local element-map {})
  (fn btn [txt on-click] (menu.button [0 0] assets.font txt on-click))
  ; Bound buttons
  (fn bbtn [key txt on-click]
    (let [btn (menu.button [0 0] assets.font txt on-click)]
      (tset element-map key btn)
      btn))

  (fn txt [txt] (menu.text [0 0] assets.font txt))
  (fn btxt [key txt] 
    (let [el (menu.text [0 0] assets.font txt)]
      (tset element-map key el)
      el))

  (local mode-txt (btxt :mode "<NOT_INIT>"))
  
  (local row0 
    (ui-stack :horizontal [0 0] [ (txt "  MODE:") mode-txt ]))

  (local row1
    (let [addbtn (bbtn :add "A: Add" #(server.set-mode srv :add))
          delbtn (bbtn :del "D: Delete" #(server.set-mode srv :delete))
          movebtn (bbtn :move "M: Move" #(server.set-mode srv :move)) 
          spacer (txt "|") ] 
    (ui-stack 
      :horizontal [0 0]
      [ (txt "POINTS:") addbtn (txt "|") movebtn (txt "|") delbtn ])))
  (local row2
    (let [quitbtn (bbtn :quit "Q: Quit" (fn [] (love.event.quit 0))) ]
      (ui-stack 
        :horizontal [0 0]
        [(txt "   APP:") quitbtn])))

  (fn layout [me] 
    (me.rows.code.layout me.rows))
  (let 
    [
     my-stack (ui-stack :vertical pos [row0 row1 row2])
     me 
     {
      :rows my-stack
      : element-map
      ; : button-map ; TODO: Figure out how to handle the button callbacks
      :pos pos
      :dims [0 0]
      :code {: draw : update : layout}
      :server srv
      }]
    (annex me)))

  {: make }
