-- Hammerspoon Configuration
-- AeroSpace-style auto-tiling window management
-- Kanata handles: CapsLock -> Esc (tap) | Hyper (hold)
--
-- Key bindings:
--   Hyper + Arrows        = Snap to half/thirds (cycles through sizes)
--   Hyper + Enter         = Fullscreen (fills screen)
--   Hyper + Shift + Enter = Toggle maximize / restore
--   Hyper + W             = Fuzzy window switcher
--   Hyper + Escape        = Toggle auto-tiling mode
--
-- Trackpad gestures (cursor in title bar):
--   4-finger swipe left   = Snap window to left half
--   4-finger swipe right  = Snap window to right half
--   4-finger swipe up     = Maximize window
--   4-finger swipe down   = Minimize window
--
-- Auto-tiling: When enabled, windows auto-arrange in columns

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

hs.window.animationDuration = 0
hs.logger.defaultLogLevel = "warning"

local hyper = { "ctrl", "alt", "cmd" }
local hyperShift = { "ctrl", "alt", "cmd", "shift" }

-- Store original window frames for restore
local savedFrames = {}
local autoTileEnabled = true

--------------------------------------------------------------------------------
-- Auto-reload on config changes
--------------------------------------------------------------------------------

local function reloadConfig(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

--------------------------------------------------------------------------------
-- Auto-Tiling (AeroSpace-style)
--------------------------------------------------------------------------------

local function tileWindows()
  if not autoTileEnabled then
    return
  end

  local screen = hs.screen.mainScreen()
  local frame = screen:frame()
  local windows = hs.window.filter
    .new()
    :setCurrentSpace(true)
    :setScreens({ screen:id() })
    :getWindows(hs.window.filter.sortByFocusedLast)

  -- Filter to standard windows only
  local visibleWindows = {}
  for _, win in ipairs(windows) do
    if win:isStandard() and win:isVisible() then
      table.insert(visibleWindows, win)
    end
  end

  local count = #visibleWindows
  if count == 0 then
    return
  end

  -- Tile windows in columns
  if count == 1 then
    -- Single window: maximize
    visibleWindows[1]:moveToUnit({ x = 0, y = 0, w = 1, h = 1 })
  elseif count == 2 then
    -- Two windows: 50/50 split
    visibleWindows[1]:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 })
    visibleWindows[2]:moveToUnit({ x = 0.5, y = 0, w = 0.5, h = 1 })
  elseif count == 3 then
    -- Three windows: 33/33/33 split
    visibleWindows[1]:moveToUnit({ x = 0, y = 0, w = 0.33, h = 1 })
    visibleWindows[2]:moveToUnit({ x = 0.33, y = 0, w = 0.34, h = 1 })
    visibleWindows[3]:moveToUnit({ x = 0.67, y = 0, w = 0.33, h = 1 })
  else
    -- 4+ windows: main + stacked
    -- First window takes left half, rest stack on right
    visibleWindows[1]:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 })
    local stackCount = count - 1
    local stackHeight = 1 / stackCount
    for i = 2, count do
      local y = (i - 2) * stackHeight
      visibleWindows[i]:moveToUnit({ x = 0.5, y = y, w = 0.5, h = stackHeight })
    end
  end
end

-- Watch for window events to trigger auto-tiling
local windowFilter = hs.window.filter.new():setCurrentSpace(true)

windowFilter:subscribe({
  hs.window.filter.windowCreated,
  hs.window.filter.windowDestroyed,
  hs.window.filter.windowMinimized,
  hs.window.filter.windowUnminimized,
}, function()
  if autoTileEnabled then
    hs.timer.doAfter(0.1, tileWindows)
  end
end)

-- Toggle auto-tiling (Hyper + Escape)
hs.hotkey.bind(hyper, "Escape", function()
  autoTileEnabled = not autoTileEnabled
  if autoTileEnabled then
    hs.alert.show("Auto-tiling ON")
    tileWindows()
  else
    hs.alert.show("Auto-tiling OFF")
  end
end)

--------------------------------------------------------------------------------
-- Manual Window Positions (halves and thirds cycling)
--------------------------------------------------------------------------------

local positions = {
  left = { x = 0, y = 0, w = 0.5, h = 1 },
  right = { x = 0.5, y = 0, w = 0.5, h = 1 },
  top = { x = 0, y = 0, w = 1, h = 0.5 },
  bottom = { x = 0, y = 0.5, w = 1, h = 0.5 },
  leftThird = { x = 0, y = 0, w = 0.33, h = 1 },
  rightThird = { x = 0.67, y = 0, w = 0.33, h = 1 },
  leftTwoThirds = { x = 0, y = 0, w = 0.67, h = 1 },
  rightTwoThirds = { x = 0.33, y = 0, w = 0.67, h = 1 },
  maximize = { x = 0, y = 0, w = 1, h = 1 },
}

local function moveWindow(position)
  local win = hs.window.focusedWindow()
  if win then
    -- Disable auto-tiling temporarily when manually positioning
    autoTileEnabled = false
    win:moveToUnit(position)
  end
end

-- Cycle through horizontal positions
local leftCycle = { "left", "leftThird", "leftTwoThirds" }
local leftCycleIndex = 1

local rightCycle = { "right", "rightThird", "rightTwoThirds" }
local rightCycleIndex = 1

hs.hotkey.bind(hyper, "Left", function()
  moveWindow(positions[leftCycle[leftCycleIndex]])
  leftCycleIndex = (leftCycleIndex % #leftCycle) + 1
  rightCycleIndex = 1
end)

hs.hotkey.bind(hyper, "Right", function()
  moveWindow(positions[rightCycle[rightCycleIndex]])
  rightCycleIndex = (rightCycleIndex % #rightCycle) + 1
  leftCycleIndex = 1
end)

hs.hotkey.bind(hyper, "Up", function()
  moveWindow(positions.top)
end)

hs.hotkey.bind(hyper, "Down", function()
  moveWindow(positions.bottom)
end)

--------------------------------------------------------------------------------
-- Fullscreen (Hyper + Enter) - just fills the screen
--------------------------------------------------------------------------------

hs.hotkey.bind(hyper, "Return", function()
  local win = hs.window.focusedWindow()
  if win then
    autoTileEnabled = false
    win:moveToUnit(positions.maximize)
  end
end)

--------------------------------------------------------------------------------
-- Toggle Maximize/Restore (Hyper + Shift + Enter)
--------------------------------------------------------------------------------

hs.hotkey.bind(hyperShift, "Return", function()
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local id = win:id()
  local currentFrame = win:frame()
  local screenFrame = win:screen():frame()

  local isMaximized = math.abs(currentFrame.x - screenFrame.x) < 10
    and math.abs(currentFrame.y - screenFrame.y) < 10
    and math.abs(currentFrame.w - screenFrame.w) < 10
    and math.abs(currentFrame.h - screenFrame.h) < 10

  autoTileEnabled = false

  if isMaximized and savedFrames[id] then
    win:setFrame(savedFrames[id])
    savedFrames[id] = nil
  else
    savedFrames[id] = currentFrame
    win:moveToUnit(positions.maximize)
  end
end)

--------------------------------------------------------------------------------
-- Fuzzy Window Switcher (Hyper + W)
--------------------------------------------------------------------------------

hs.hotkey.bind(hyper, "W", function()
  local chooser = hs.chooser.new(function(choice)
    if choice then
      local win = hs.window.get(choice.id)
      if win then
        win:focus()
      end
    end
  end)

  local windows = hs.window.allWindows()
  local choices = {}

  for _, win in ipairs(windows) do
    if win:isStandard() then
      local app = win:application()
      table.insert(choices, {
        text = win:title(),
        subText = app and app:name() or "",
        id = win:id(),
        image = app and app:bundleID() and hs.image.imageFromAppBundle(app:bundleID()) or nil,
      })
    end
  end

  chooser:choices(choices)
  chooser:searchSubText(true)
  chooser:show()
end)

--------------------------------------------------------------------------------
-- Trackpad Swipe Gestures (Swipe.spoon)
-- Only triggers when cursor is near window title bar (like Swish)
--------------------------------------------------------------------------------

local Swipe = hs.loadSpoon("Swipe")

local swipe_id, swipe_threshold
local TITLE_BAR_HEIGHT = 50 -- pixels from top of window

-- Check if cursor is in title bar region of any window
local function isCursorInTitleBar()
  local mousePos = hs.mouse.absolutePosition()
  local windows = hs.window.orderedWindows()

  for _, win in ipairs(windows) do
    if win:isStandard() and win:isVisible() then
      local frame = win:frame()
      -- Check if cursor is within title bar region (top 50px of window)
      if
        mousePos.x >= frame.x
        and mousePos.x <= frame.x + frame.w
        and mousePos.y >= frame.y
        and mousePos.y <= frame.y + TITLE_BAR_HEIGHT
      then
        return true, win
      end
    end
  end
  return false, nil
end

-- 4-finger swipe to snap windows (only when cursor in title bar)
Swipe:start(4, function(direction, distance, id)
  if id == swipe_id then
    if distance > swipe_threshold then
      swipe_threshold = math.huge -- only trigger once per swipe

      local inTitleBar, win = isCursorInTitleBar()
      if not inTitleBar or not win then
        return
      end

      autoTileEnabled = false -- disable auto-tile when manually positioning

      if direction == "left" then
        win:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 }) -- snap left
      elseif direction == "right" then
        win:moveToUnit({ x = 0.5, y = 0, w = 0.5, h = 1 }) -- snap right
      elseif direction == "up" then
        win:moveToUnit({ x = 0, y = 0, w = 1, h = 1 }) -- maximize
      elseif direction == "down" then
        win:minimize() -- minimize
      end
    end
  else
    swipe_id = id
    swipe_threshold = 0.2 -- swipe distance > 20% of trackpad
  end
end)

--------------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------------

hs.alert.show("Hammerspoon loaded (auto-tile ON)", 1)
