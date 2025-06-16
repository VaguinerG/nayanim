# Nayanim - Animation Extension for Nim's Raylib

Nayanim is a Nim library that extends Raylib's functionality with animation support, particularly for handling texture atlases in JSON format.

## Features

- **JSON Format Support**: Works with both object `{"frame_name": {...}}` and array `[{"filename": "...", ...}]` formats
- **Frame Querying**: Get source and trimmed rectangles for collision detection and UI positioning
- **Flexible Drawing**: Multiple drawing methods with full transform support
- **Animation Control**: Play once, loop, pause, and direction control
- **Visual Effects**: Flip, rotate, scale, and color tinting

## API

### Core Functions

``` nim
proc loadAnimationData*(jsonStr: string, texture: var Texture): AnimationData
proc newAnimation*(animationData: AnimationData, animationName: string): AnimationState
proc updateAnimation*(state: var AnimationState)
```

### Drawing Functions

``` nim
# Draw using AnimationState (uses internal transform properties)
proc drawAnimation*(state: AnimationState, x: float32, y: float32)
proc drawAnimation*(state: AnimationState, pos: Vector2)

# Direct frame drawing with custom parameters
proc drawAnimationFrame*(anim: AnimationData, animType: string, frame: int, x: float32, y: float32, color: Color = WHITE, rotation: float32 = 0.0, scale: float32 = 1.0, horizontalFlip: bool = false, verticalFlip: bool = false, origin: Vector2 = Vector2(x: 0.0, y: 0.0))
proc drawAnimationFrame*(anim: AnimationData, animType: string, frame: int, pos: Vector2, color: Color = WHITE, rotation: float32 = 0.0, scale: float32 = 1.0, horizontalFlip: bool = false, verticalFlip: bool = false, origin: Vector2 = Vector2(x: 0.0, y: 0.0))
```

### Frame Querying Functions

``` nim
# Get the full source rectangle (useful for UI positioning)
proc getSourceRect*(state: AnimationState, x, y: float32): Rectangle
proc getSourceRect*(state: AnimationState, pos: Vector2): Rectangle

# Get the trimmed rectangle (actual visible pixels, useful for collision)
proc getTrimmedRect*(state: AnimationState, x, y: float32): Rectangle
proc getTrimmedRect*(state: AnimationState, pos: Vector2): Rectangle
```

## Example Usage

``` nim
import raylib, nayanim

initWindow(800, 600, "raylib example - animation")
setTargetFPS(60)

var spriteJson = readFile("spritesheet.json")
var spriteAtlas = loadTexture("spritesheet.png")

let animData = loadAnimationData(spriteJson, spriteAtlas)
var animation = newAnimation(animData, "ATTACK1")

animation.speed = 5.0
animation.scale = 5.0

while not windowShouldClose():
  updateAnimation(animation)
  drawing:
    clearBackground(RAYWHITE)
    drawAnimation(animation, getMousePosition())

closeWindow()
```

## AnimationState Properties

The `AnimationState` object provides extensive control over animation playback and rendering:

### Core Animation Data
- `animationData*: AnimationData` - Reference to the animation data
- `name*: string` - Current animation tag name
- `currentFrame*: ptr Frame` - Pointer to current frame data

### Frame Control
- `frame*: int = 0` - Current frame index
- `timer*: float = 0` - Frame timer
- `speed*: float = 1.0` - Animation speed multiplier

### Playback Control
- `direction*: AnimationDirection = Forward` - Animation direction (Forward, Backward, PingPong)
- `frameDirection*: int = 1` - Internal frame direction for PingPong
- `loop*: bool = true` - Whether animation loops
- `paused*: bool = false` - Animation pause state
- `playOnce*: bool = false` - Stop at end instead of looping
- `finished*: bool = false` - True when playOnce animation completes

### Transform Properties
- `rotation*: float32 = 0.0` - Rotation in radians
- `scale*: float32 = 1.0` - Uniform scale factor

### Visual Effects
- `color*: Color = WHITE` - Tint color
- `horizontalFlip*: bool = false` - Horizontal flip
- `verticalFlip*: bool = false` - Vertical flip

## Frame Querying

The library provides two types of frame rectangles:

- **Source Rectangle**: The full original frame size, useful for UI layout and positioning
- **Trimmed Rectangle**: The actual visible pixels after trimming transparent areas, perfect for collision detection

``` nim
# Get rectangles for current animation frame
let sourceRect = animation.getSourceRect(100.0, 100.0)
let trimmedRect = animation.getTrimmedRect(100.0, 100.0)

# Use for collision detection
if checkCollisionRecs(trimmedRect, playerRect):
  echo "Collision detected!"

# Example: Draw collision rectangle
let mousePos = getMousePosition()
let collisionRect = animation.getTrimmedRect(mousePos)
drawRectangleLines(collisionRect.x.int32, collisionRect.y.int32, 
                  collisionRect.width.int32, collisionRect.height.int32, 1, RED)
```

## Supported JSON Formats

Nayanim automatically detects and supports both common sprite sheet JSON formats:

- **Object format**: `{"frame_name": {"frame": {...}, "duration": 100, ...}}`
- **Array format**: `[{"filename": "frame_0001.png", "frame": {...}, ...}]`

Both formats work seamlessly with the same API.