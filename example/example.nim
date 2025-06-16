import raylib, nayanim, raymath, math, strformat

initWindow(800, 600, "raylib example - animation com debug simples")
setTargetFPS(60)

var spriteJson = readFile("medieval.json")
var spriteAtlas = loadTexture("medieval.png")

let animData = loadAnimationData(spriteJson, spriteAtlas)
var animation = newAnimation(animData, "IDLE")

animation.speed = 0.5
animation.scale = 2.0

while not windowShouldClose():
  clearBackground(RAYWHITE)

  if isMouseButtonPressed(Left):
    animation.name="RUN"

  if isMouseButtonPressed(Right):
    animation.name="IDLE"

  updateAnimation(animation)

  var pos = Vector2(
    x: getMousePosition().x - animation.currentFrame.sourceSize.x / 2 * animation.scale,
    y: getMousePosition().y - animation.currentFrame.sourceSize.y / 2 * animation.scale
  )
  let sourceRect = getSourceRect(animation, pos)
  let trimmedRect = getTrimmedRect(animation, pos)

  drawing:
    drawAnimation(animation, pos)
    
    drawRectangleLines(sourceRect, 1, GREEN)
    drawRectangleLines(trimmedRect, 1, RED)
    
    drawText(&"Source: {sourceRect.width:.0f}x{sourceRect.height:.0f}", 10, 110, 16, GREEN)
    drawText(&"Trimmed: {trimmedRect.width:.0f}x{trimmedRect.height:.0f}", 10, 130, 16, RED)
    
closeWindow()