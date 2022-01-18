; Load in base assets here
(let [chars (..
              " abcdefghijklmnopqrstuvwxyz" 
              "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" 
              "123456789.,!?-+/():;%&`'*#=[]\"")]
  { :font (love.graphics.newFont "assets/iosevka.ttc" 20)
   :bitfont (love.graphics.newImageFont "assets/font.png" chars) })
