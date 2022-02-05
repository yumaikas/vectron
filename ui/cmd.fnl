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

(fn gerundize [mode] 
  (match mode
    :add :adding
    :delete :deleting
    :move :moving
    _ (error (.. "Unrecognized mode passed to gerundise: " mode))))

(fn export-switch-text [copy-mode]
  (match copy-mode
    :lua    [ [0 0 0] "F:" [1 1 1] " To Fennel"]
    :fennel [ [0 0 0]  "L:" [1 1 1] " To Lua   "]))

(fn start-export-text [copy-mode] 
  (match copy-mode
    :lua    " To Fennel" 
    :fennel " To Lua   "))

(var times 10)
(fn update [me dt] 
  (local {:element-map elements
          :server srv } me)
  (when (> times 0)
    (let [{:mode-lbl mode
           :pts-lbl points
           :app-lbl app
           } elements]
      (print "********")
      (set times (- times 1))
      (f.pp mode)
      (f.pp points)
      (f.pp app)))
  (let [{:mode mode-el :code-switch switch-btn} elements
        status-line (server.status-line srv)
        {: mode : copy-mode } (server.mode srv) ]
    (switch-btn:set-text (export-switch-text copy-mode))
    (if status-line
      (mode-el:set-text status-line)
      (mode-el:set-text 
        (.. 
          (: (gerundize mode) :gsub "^%l" string.upper) " points. "
          "Import/Export to " (copy-mode:gsub "^%l" string.upper)))))

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

  (fn xbbtn [key keybind txt on-click]
    (let [btn (menu.key-button [0 0] assets.font keybind txt on-click)]
      (tset element-map key btn)
      btn))

  (fn txt [txt] (menu.text [0 0] assets.font txt))
  (fn btxt [key txt] 
    (let [el (menu.text [0 0] assets.font txt)]
      (tset element-map key el)
      el))


  (local mode-txt (btxt :mode "<NOT_INIT>"))
  
  (local row0 
    (ui-stack :horizontal [0 0] (btxt :mode-lbl "  MODE:") mode-txt ))

  (local row1
    (ui-stack 
      :horizontal [0 0]
       (btxt :pts-lbl "POINTS:")
       (xbbtn :add "A:" " Add " #(server.set-mode srv :add)) 
       (xbbtn :move "M:" " Move" #(server.set-mode srv :move))
       (xbbtn :del "D:" " Delete   " #(server.set-mode srv :delete)) 
       (xbbtn :paste "I:" " Import" #(server.load-code srv))
       (xbbtn :copy "E:" " Export" #(server.copy-code srv))
       ))

  (fn switch-export [] 
    (let [{:copy-mode m} (server.mode srv)]
      (match m
        :fennel (server.set-copy-mode srv :lua)
        :lua (server.set-copy-mode srv :fennel))))

  (local row2
    (ui-stack 
      :horizontal [0 0]
      (btxt :app-lbl "   APP:") 
       (xbbtn :undo "U:" " Undo" #(server.undo srv))
       (xbbtn :redo "R:" " Redo" #(server.redo srv)) 
       (xbbtn :code-switch "L:" (start-export-text :fennel) switch-export)
       (xbbtn :quit "Q:" " Quit" #(love.event.quit 0))))

  ; RESUME
  (local row3
    (ui-stack
      :horizontal [0 0] ))


  (fn layout [me] 
    (me.rows.code.layout me.rows))
  (let 
    [
     my-stack (ui-stack :vertical pos row0 row1 row2)
     me 
     {
      :rows my-stack
      : element-map
      :pos pos
      :dims [0 0]
      :code {: draw : update : layout}
      :server srv
      }]
    (annex me)))

  {: make }
