screendrag = require("./examples/screendrag")

scrn = view.newscreen(10, 5)
pointer = image.load("./examples/images/pointer.gif")

img = image.load("./examples/images/Pharao.gif")
width = image.imagewidth(img)
height = image.imageheight(img)
image.usepalette(img)

x = -100
y = -170
function _step()
  local mx, my, mbtn = input.mouse()
  image.draw(img, 160 - (width / 2), 90 - height / 2, 0, 0, width, height)
  gfx.bar(x, y, 100, 100)
  x = x + 1
  y = y + 1
  image.draw(pointer, mx, my, 0, 0, 16, 16)
  if y > 320 then
    x = -100
    y = -170
  end
  screendrag.step(scrn)
end
