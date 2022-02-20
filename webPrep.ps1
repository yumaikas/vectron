try {
$paths = ls | ? { -not(($_.FullName -ilike "*love-bins*") -or ($_.FullName -ilike "*.ps1") -or ($_.FullName -ilike "*publish*")) } | % { $_.FullName; }


ls -Recurse .\publish\vectron\ | Remove-Item -Recurse -Force 

#New-Item .\publish\vectron\ -ItemType Directory
Remove-Item -Recurse -Force .\publish\vectron.love
Compress-Archive $paths publish\vectron.love
Push-location publish\
"Vectron" | npx love.js vectron.love vectron -c
cd vectron
web-dir
}
finally {
    Pop-location
}
# Compress-Archive (ls -Recurse) ..\CasterFightWeba.zip -Force
