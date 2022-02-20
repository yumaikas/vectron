(local f (require :f))
(local v (require :v))
(local lpeg (require :lulpeg))
(local {: view} (require :fennel))
(import-macros {: check} :m)

(fn luapts [points] 
  (.. "{ " (table.concat points ", ") " }"))

(fn fennelpts [points]
  (.. "[ " (table.concat points " ") " ]"))

(fn fennel-scene [scene] 
  (.. "[ "
      (table.concat 
        (icollect [_ {: points :color [r g b]} (ipairs scene)]
                  (..
                    " { "
                    ":color [" r " " g " " b "] " 
                    ":points " (fennelpts (v.flatten points))
                    " } ")))
      " ]"))

(fn lua-scene [scene]
  (.. "{ "
      (table.concat 
        (icollect [_ {: points :color [r g b]} (ipairs scene)]
                  (..
                    " { "
                    "color = {" r ", " g ", " b "}, "
                    "points = " (luapts (v.flatten points)) 
                    " }, ")))
      " }"))


(local fennel-pts-patt
  (let [
      digit (lpeg.V :digit)
      pair (lpeg.V :pair)
      space+ (^ (lpeg.S " \t\r\n") 1)
      space* (^ (lpeg.S " \t\r\n") 0)
      topair (fn [x y] [x y])
      ] 
    (lpeg.P 
      { 1 :table
       :digit (/ (^ (lpeg.R "09") 1) tonumber)
       :pair (/ (* digit space+ digit) topair)
       :table (lpeg.Ct (* space* "[" space* (^ (* pair space*) 1) "]"))
       })))

(local fennel-scene-patt
  (let [
      digit (lpeg.V :digit)
      number (lpeg.V :number)
      shape (lpeg.V :shape)
      color (lpeg.V :color)
      points (lpeg.V :points)
      color-triple (lpeg.V :color-triple)
      scene (lpeg.V :scene)
      space+ (^ (lpeg.S " \t\r\n") 1)
      space* (^ (lpeg.S " \t\r\n") 0)
        ]
    (lpeg.P 
      { 1 :debug
       :digit  (^ (lpeg.R "09") 1)
       :number (/ (* digit (^ (* "." digit) 0)) tonumber)
       :color-triple (lpeg.Ct (* "[" space* number space+ number space+ number space*"]"))
       :color (lpeg.Cg (* ":color" space* color-triple) :color)
       :points (lpeg.Cg (* ":points" space* fennel-pts-patt) :points)
       :shape (lpeg.Ct (* "{" (^ (* space* (+ points color) space* ) 2) "}"))
       :scene (lpeg.Ct (* space* "["  (^ (* space* shape space*) 1) space* "]" space*))
       :debug scene 
       })
    ))
       ; (lpeg.Ct (* space* (lpeg.P "[" )))

(fn is-full-shape? [shape]
  (and (. shape :color) (. shape :points)))

(fn load-fennel-scene [text]
  (let [scene (fennel-scene-patt:match text)]
    (f.pp text)
    (f.pp scene)
    (if (and scene (> (length scene) 0) (f.all? scene is-full-shape?))
      (values :ok scene)
      (values :error "Scene failed to parse"))))


(fn loadfennelpts [text] 
  (let [points (fennel-pts-patt:match text)]
    (f.pp points)
    (if (and points (> (length points) 0))
      (values :ok points)
      (values :error "Found no points"))))

(fn loadluapts [text]
  (let [points []]
    (each [x y (string.gfind text "(%d+)%s*,%s*(%d+)")]
      (table.insert points [x y]))
    (if (> (length points) 0)
      (values :ok points)
      (values :error "Found no points"))))

(fn mode-not-found! [mode fname]
  (error (.. "Unknown copy-mode " mode " in " fname " !")))

(fn text->points [mode text]
  (match mode
    :lua (loadluapts text)
    :fennel (loadfennelpts text)
    _ (mode-not-found! mode :text->points)))

(fn points->text [mode points] 
  (match mode
    :lua (luapts points)
    :fennel (fennelpts points)
    _ (mode-not-found! mode :points->text)))

(fn scene->text [mode scene]
  (match mode
    :lua (lua-scene scene)
    :fennel (fennel-scene scene)
    _ (mode-not-found! mode :scene->text)))

(fn text->scene [mode text]
  (match mode
    :fennel (load-fennel-scene text)
    _ (mode-not-found! mode :text->scene)))

{: text->points : points->text : scene->text : text->scene  }

