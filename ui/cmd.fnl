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
  (me.rows.code.update me.rows))

(fn make [srv pos] 
  (fn btn [txt on-click] (menu.button [0 0] assets.font txt on-click))
  (fn txt [txt] (menu.text [0 0] assets.font txt))
  
  (local row1
    (let [addbtn (btn "A: Add" #(f.pp "add"))
          delbtn (btn "D: Delete" #(f.pp "delete"))
          movebtn (btn "M: Move" #(f.pp "move")) 
          spacer (txt "|") ] 
    (ui-stack 
      :horizontal [0 0]
      [ (txt "POINTS:") addbtn (txt "|") movebtn (txt "|") delbtn ])))
  (local row2
    (let [quitbtn (btn "Q: Quit" (fn [] (love.event.quit 0))) ]
      (ui-stack 
        :horizontal [0 0]
        [(txt "   APP:") quitbtn])))

  (fn layout [me] 
    (me.rows.code.layout me.rows))
  (let 
    [
     my-stack (ui-stack :vertical pos [row1 row2])
     me 
     {
      :rows my-stack
      ; : button-map ; TODO: Figure out how to handle the button callbacks
      :pos pos
      :dims [0 0]
      :code {: draw : update : layout}
      :server srv
      }]
    (annex me)))

  {: make }
