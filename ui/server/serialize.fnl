(local f (require :f))
(local v (require :v))
(local lpeg (require :lulpeg))
(local polyline (require :ui.shapes.polyline))
(local polygon (require :ui.shapes.polygon))
; (local pegdebug (require :pegdebug))
(local {: view} (require :fennel))
(import-macros {: check} :m)

(fn module->str [mod] 
  (if 
    (= mod polyline) "polyline"
    (= mod polygon) "polygon"
    ":missing"))

(fn luapts [points] 
  (.. "{ " (table.concat points ", ") " }"))

(fn fennelpts [points]
  (.. "[ " (table.concat points " ") " ]"))

(fn fennel-scene [scene] 
  (.. "[ \n"
      (table.concat 
        (icollect [_ {: module : points :color [r g b]} (ipairs scene)]
                  (..
                    " { "
                    ":module :" (module->str module) " "
                    ":color [" r " " g " " b "] " 
                    ":points " (fennelpts (v.flatten points))
                    " }\n")))
      " ]"))

(fn lua-scene [scene]
  (.. "{ "
      (table.concat 
        (icollect [_ {: module : points :color [r g b]} (ipairs scene)]
                  (..
                    " { "
                    " module = \"" (module->str module) "\""
                    "color = {" r ", " g ", " b "}, "
                    "points = " (luapts (v.flatten points)) 
                    " } ")) ", ")
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

(local fennel-module-patt
    (lpeg.P
      {1 :module
       :module-lit (+ (* "polyline" (lpeg.Cc polyline)) (* "polygon" (lpeg.Cc polygon)))
       :module (* ":" (lpeg.V :module-lit))
       }))

(local lua-pts-patt
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
       :pair (/ (* digit space* "," space* digit) topair)
       :table (lpeg.Ct (* space* "{" space* (^ (* pair space* (^ (lpeg.P ",") 0) space*) 1) "}"))
       })))

(local lua-scene-patt
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
    (lpeg.P { 1 :debug
       :digit  (^ (lpeg.R "09") 1)
       :number (/ (* digit (^ (* "." digit) 0)) tonumber)
       :color-triple (lpeg.Ct (* "{" space* number "," space+ number "," space+ number space*"}"))
       :color (lpeg.Cg (* "color" space* "=" space* color-triple) :color)
       :points (lpeg.Cg (* "points" space* "=" space* lua-pts-patt) :points)
       :shape (lpeg.Ct (* "{" (^ (* space* (+ points color) space* (^ (lpeg.P ",") 0) space* ) 2) "}"))
       :scene (lpeg.Ct (* space* "{"  (^ (* space* shape space* (^ (lpeg.P ",") 0) space*) 1) space* "}" space*))
       :debug scene 
       })
    ))
(local fennel-scene-patt
  (let [
      digit (lpeg.V :digit)
      number (lpeg.V :number)
      shape (lpeg.V :shape)
      color (lpeg.V :color)
      points (lpeg.V :points)
      module (lpeg.V :module)
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
       :module (lpeg.Cg (* ":module" space* fennel-module-patt) :module)
       :shape (lpeg.Ct (* "{" (^ (* space* (+ points color module) space* ) 3) "}"))
       :scene (lpeg.Ct (* space* "["  (^ (* space* shape space*) 1) space* "]" space*))
       :debug scene 
       })
    ))

(fn is-full-shape? [shape]
  (and (. shape :module) (. shape :color) (. shape :points)))

(fn load-fennel-scene [text]
  (let [scene (fennel-scene-patt:match text)]
    (if (and scene (> (length scene) 0) (f.all? scene is-full-shape?))
      (values :ok scene)
      (values :error "Scene failed to parse"))))

(fn load-lua-scene [text]
  (let [scene (lua-scene-patt:match text)]
    (if (and scene (> (length scene) 0) (f.all? scene is-full-shape?))
      (values :ok scene)
      (values :error "Scene failed to parse"))))


(fn loadfennelpts [text] 
  (let [points (fennel-pts-patt:match text)]
    (if (and points (> (length points) 0))
      (values :ok points)
      (values :error "Found no points"))))

(fn loadluapts [text] 
  (let [points (lua-pts-patt:match text)]
    (if (and points (> (length points) 0))
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
    :lua (load-lua-scene text)
    _ (mode-not-found! mode :text->scene)))

{: text->points : points->text : scene->text : text->scene  }

