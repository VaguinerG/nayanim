import std/[json, tables, sequtils]
import raylib

type
  Frame* = object
    rect*: Rectangle
    duration*: int

  Animation* = object
    frames*: Table[string, seq[Frame]]
    texture*: Texture

proc parseSpritesheetJson(jsonStr: string): Table[string, seq[Frame]] =
  let json = parseJson(jsonStr)
  
  # Convert all frames to array - toSeq gets key-value pairs, mapIt transforms each pair
  let frames = json["frames"].pairs.toSeq.mapIt(
    Frame(
      rect: Rectangle(
        x: it[1]["frame"]["x"].getFloat(),
        y: it[1]["frame"]["y"].getFloat(), 
        width: it[1]["frame"]["w"].getFloat(),
        height: it[1]["frame"]["h"].getFloat()
      ),
      duration: it[1]["duration"].getInt()
    )
  )
  
  # Map each animation tag to its frame range - creates (name, frames) tuples then converts to Table
  json["meta"]["frameTags"].mapIt(
    (it["name"].getStr(), frames[it["from"].getInt() .. it["to"].getInt()])
  ).toTable

proc loadAnimation*(jsonStr: string, texture: sink Texture): Animation =
  Animation(
    frames: parseSpritesheetJson(jsonStr),
    texture: texture
  )

# Base frame drawing
proc drawAnimationFrame*(anim: Animation, animType: string, frame: int,
                         x: float32,
                         y: float32,
                         color: Color = WHITE,
                         rotation: float32 = 0.0,
                         scale: float32 = 1.0,
                         horizontalFlip: bool = false,
                         verticalFlip: bool = false,
                         origin: Vector2 | void = void) =

  let currentFrame = anim.frames[animType][frame]

  let frameWidth = currentFrame.rect.width * scale
  let frameHeight = currentFrame.rect.height * scale

  let finalOrigin: Vector2 =
    when origin is void:
      Vector2(x: frameWidth / 2, y: frameHeight / 2)
    else:
      origin

  let source = Rectangle(
    x: currentFrame.rect.x,
    y: currentFrame.rect.y,
    width: if horizontalFlip: -currentFrame.rect.width else: currentFrame.rect.width,
    height: if verticalFlip: -currentFrame.rect.height else: currentFrame.rect.height
  )

  let dest = Rectangle(
    x: x, y: y,
    width: frameWidth,
    height: frameHeight
  )

  drawTexture(anim.texture, source, dest, finalOrigin, rotation, color)

# Frame drawing with Vector2
proc drawAnimationFrame*(anim: Animation, animType: string, frame: int,
                           pos: Vector2,
                           color: Color = WHITE,
                           rotation: float32 = 0.0,
                           scale: float32 = 1.0,
                           horizontalFlip: bool = false,
                           verticalFlip: bool = false,
                           origin: Vector2 | void = void) =

  when origin is void:
    drawAnimationFrame(anim, animType, frame,
                       x = pos.x, y = pos.y,
                       color = color,
                       rotation = rotation,
                       scale = scale,
                       horizontalFlip = horizontalFlip,
                       verticalFlip = verticalFlip)
  else:
    drawAnimationFrame(anim, animType, frame,
                       x = pos.x, y = pos.y,
                       color = color,
                       rotation = rotation,
                       scale = scale,
                       horizontalFlip = horizontalFlip,
                       verticalFlip = verticalFlip,
                       origin = origin)
