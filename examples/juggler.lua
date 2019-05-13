scrn = createscreen(0, 5)

anim = loadanimation("./examples/images/juggler32.gif")
frame = 0
nextFrame = 0

function _init()
  usepalette(anim[1])
end

function _step(t)
  if t - nextFrame > 100 then
    nextFrame = t
  end
  if t < nextFrame then
    return
  end
  frame = frame + 1
  if frame > #anim then
    frame = 1
  end
  bar(0, 0, 320, 180)
  drawimage(anim[frame], 0, 0, 0, 0, 320, 180)
  nextFrame = nextFrame + imageduration(anim[frame])
end
