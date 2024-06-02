# Vectron

Vectron is a line vector editor designed to make it easy to edit point lists for use in love2D `love.graphices.line` calls. 


## Tech

Vectron is built with some lua, and more fennel. 

- `c/` is the rather small collision library 
- `m/` is for the two macros that have been defined so far
- `f/` is a set of additions to lua/fennel's very small standard library.
- `ui/` is where most of the ui logic lives.

- `game/` is currently vestigial code from Wobbly Invaders that has mostly been moved into the above folders, but hasn't been cleared out yet.

## Up and running

Clone the repo, install [love2d](https://love2d.org/), and then run `love .` or `lovec .` in the top level folder. `watch.ps1` assumes the existence of [eye](https://github.com/yumaikas/eye) on your machine, it could be replaced with entr, or your file watcher of choice. 


## Status

Everything that has a button should work at a basic level, with the exceptions of:

- Undo/redo is being adjusted to handle multiple shpaes
- Import/Export only work on the current shape, rather than the whole list
- No keyboard shortcuts have been set up, the nano-style UI is still a bit aspirational.
