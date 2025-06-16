import std/[json, tables, sequtils]
import raylib

type
  AnimationDirection* = enum
    Forward = 1
    Backward = -1
    PingPong = 0

  Frame* = object
    rect*: Rectangle
    duration*: int
    offset*: Vector2
    sourceSize*: Vector2

  AnimationData* = ref object
    frames*: Table[string, seq[Frame]]
    texture*: ptr Texture

  AnimationState* = object
    # === Core Animation Data ===
    animationData*: AnimationData
    name*: string
    currentFrame*: ptr Frame
    
    # === Frame Control ===
    frame*: int = 0
    timer*: float = 0
    speed*: float = 1.0
    
    # === Playback Control ===
    direction*: AnimationDirection = Forward
    frameDirection*: int = 1
    loop*: bool = true
    paused*: bool = false
    playOnce*: bool = false
    finished*: bool = false
    
    # === Transform Properties ===
    rotation*: float32 = 0.0
    scale*: float32 = 1.0
    
    # === Visual Effects ===
    color*: Color = WHITE
    horizontalFlip*: bool = false
    verticalFlip*: bool = false

proc parseSpritesheetJson(jsonStr: string): Table[string, seq[Frame]] =
  let json = parseJson(jsonStr)
  
  let frames = 
    if json["frames"].kind == JObject:
      # Object format: {"frame_name": {...}}
      json["frames"].pairs.toSeq.mapIt(
        Frame(
          rect: Rectangle(
            x: it[1]["frame"]["x"].getFloat(),
            y: it[1]["frame"]["y"].getFloat(), 
            width: it[1]["frame"]["w"].getFloat(),
            height: it[1]["frame"]["h"].getFloat()
          ),
          duration: it[1]["duration"].getInt(),
          offset: Vector2(
            x: it[1]["spriteSourceSize"]["x"].getFloat(),
            y: it[1]["spriteSourceSize"]["y"].getFloat()
          ),
          sourceSize: Vector2(
            x: it[1]["sourceSize"]["w"].getFloat(),
            y: it[1]["sourceSize"]["h"].getFloat()
          )
        )
      )
    else:
      # Array format: [{"filename": "...", ...}]
      json["frames"].mapIt(
        Frame(
          rect: Rectangle(
            x: it["frame"]["x"].getFloat(),
            y: it["frame"]["y"].getFloat(), 
            width: it["frame"]["w"].getFloat(),
            height: it["frame"]["h"].getFloat()
          ),
          duration: it["duration"].getInt(),
          offset: Vector2(
            x: it["spriteSourceSize"]["x"].getFloat(),
            y: it["spriteSourceSize"]["y"].getFloat()
          ),
          sourceSize: Vector2(
            x: it["sourceSize"]["w"].getFloat(),
            y: it["sourceSize"]["h"].getFloat()
          )
        )
      )
  
  # Map each animation tag to its frame range - creates (name, frames) tuples then converts to Table
  json["meta"]["frameTags"].mapIt(
    (it["name"].getStr(), frames[it["from"].getInt() .. it["to"].getInt()])
  ).toTable

proc loadAnimationData*(jsonStr: string, texture: var Texture): AnimationData =
  AnimationData(
    frames: parseSpritesheetJson(jsonStr),
    texture: addr texture
  )

proc updateAnimation*(state: var AnimationState) =
  if state.paused: return
  
  let frames = state.animationData.frames.getOrDefault(state.name)

  if frames.len == 0: return

  state.timer -= getFrameTime() * state.speed
  if state.timer > 0 and not (state.frame > frames.high): return

  state.frame += state.frameDirection
  if state.frame >= frames.high: state.frame = 0
  let lastFrame = frames.high
  
  template handleBoundary(condition: bool, loopFrame, stopFrame: int) =
    if condition:
      if state.loop and not state.playOnce:
        state.frame = loopFrame
      else:
        state.frame = stopFrame
        state.paused = true
        state.finished = true
  
  case state.direction:
    of Forward:   handleBoundary(state.frame > lastFrame, 0, lastFrame)
    of Backward:  handleBoundary(state.frame < 0, lastFrame, 0)
    of PingPong:
      if state.frameDirection > 0 and state.frame > lastFrame:
        state.frameDirection = -1
        handleBoundary(true, lastFrame - 1, lastFrame)
      elif state.frameDirection < 0 and state.frame < 0:
        state.frameDirection = 1
        handleBoundary(true, 1, 0)
  
  state.frame = state.frame.clamp(0, lastFrame)
  state.timer = frames[state.frame].duration.float / 1000.0

  state.currentFrame = addr frames[state.frame]

proc newAnimation*(animationData: AnimationData, animationName: string): AnimationState =
  result = AnimationState(
    name: animationName,
    animationData: animationData
  )
  updateAnimation(result)
  result.frame = 0

proc getSourceRect*(state: AnimationState, x, y: float32): Rectangle =
  Rectangle(
    x: x,
    y: y,
    width: state.currentFrame.sourceSize.x * state.scale,
    height: state.currentFrame.sourceSize.y * state.scale
  )

proc getSourceRect*(state: AnimationState, pos: Vector2): Rectangle =
  getSourceRect(state, pos.x, pos.y)

proc getTrimmedRect*(state: AnimationState, x, y: float32): Rectangle =
  let currentFrame = state.currentFrame
  
  let adjustedOffsetX = if state.horizontalFlip: 
    (currentFrame.sourceSize.x - currentFrame.rect.width - currentFrame.offset.x) * state.scale
  else: 
    currentFrame.offset.x * state.scale

  let adjustedOffsetY = if state.verticalFlip: 
    (currentFrame.sourceSize.y - currentFrame.rect.height - currentFrame.offset.y) * state.scale
  else: 
    currentFrame.offset.y * state.scale
  
  Rectangle(
    x: x + adjustedOffsetX,
    y: y + adjustedOffsetY,
    width: currentFrame.rect.width * state.scale,
    height: currentFrame.rect.height * state.scale
  )

proc getTrimmedRect*(state: AnimationState, pos: Vector2): Rectangle =
  getTrimmedRect(state, pos.x, pos.y)

# Base frame drawing
proc drawAnimationFrame*(anim: AnimationData, animType: string, frame: int,
                         x: float32,
                         y: float32,
                         color: Color = WHITE,
                         rotation: float32 = 0.0,
                         scale: float32 = 1.0,
                         horizontalFlip: bool = false,
                         verticalFlip: bool = false,
                         origin: Vector2 = Vector2(x: 0.0, y: 0.0)) =

  let currentFrame = anim.frames[animType][frame]

  let frameWidth = currentFrame.rect.width * scale
  let frameHeight = currentFrame.rect.height * scale

  let adjustedOffsetX = if horizontalFlip: 
    (currentFrame.sourceSize.x - currentFrame.rect.width - currentFrame.offset.x) * scale
  else: 
    currentFrame.offset.x * scale

  let adjustedOffsetY = if verticalFlip: 
    (currentFrame.sourceSize.y - currentFrame.rect.height - currentFrame.offset.y) * scale
  else: 
    currentFrame.offset.y * scale

  let source = Rectangle(
    x: currentFrame.rect.x,
    y: currentFrame.rect.y,
    width: if horizontalFlip: -currentFrame.rect.width else: currentFrame.rect.width,
    height: if verticalFlip: -currentFrame.rect.height else: currentFrame.rect.height
  )

  let dest = Rectangle(
    x: x + adjustedOffsetX,
    y: y + adjustedOffsetY,
    width: frameWidth,
    height: frameHeight
  )

  drawTexture(anim.texture[], source, dest, origin, rotation, color)

# Frame drawing with Vector2
proc drawAnimationFrame*(anim: AnimationData, animType: string, frame: int,
                           pos: Vector2,
                           color: Color = WHITE,
                           rotation: float32 = 0.0,
                           scale: float32 = 1.0,
                           horizontalFlip: bool = false,
                           verticalFlip: bool = false,
                           origin: Vector2 = Vector2(x: 0.0, y: 0.0)) =

  drawAnimationFrame(anim, animType, frame,
                        x = pos.x, y = pos.y,
                        color = color,
                        rotation = rotation,
                        scale = scale,
                        horizontalFlip = horizontalFlip,
                        verticalFlip = verticalFlip,
                        origin = origin)

proc drawAnimation*(state: AnimationState, x: float32, y:float32) =
  drawAnimationFrame(state.animationData, state.name, state.frame, x, y, color = state.color, rotation = state.rotation,
   scale = state.scale, horizontalFlip = state.horizontalFlip, verticalFlip = state.verticalFlip)

proc drawAnimation*(state: AnimationState, pos: Vector2) =
  drawAnimationFrame(state.animationData, state.name, state.frame, pos.x, pos.y, color = state.color, rotation = state.rotation,
   scale = state.scale, horizontalFlip = state.horizontalFlip, verticalFlip = state.verticalFlip)