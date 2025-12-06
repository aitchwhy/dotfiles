-- Hammerspoon Configuration
-- AeroSpace-style auto-tiling window management
--
-- Key bindings:
--   Ctrl+Opt + Arrows       = Cycle half → third → two-thirds in that direction
--   Ctrl+Opt+Cmd + Arrows   = Move window to adjacent display
--   Ctrl+Opt+Cmd + Enter    = Fullscreen (fills screen)
--   Ctrl+Opt+Cmd+Shift + Enter = Toggle maximize / restore
--   Ctrl+Opt+Cmd + W        = Fuzzy window switcher
--   Ctrl+Opt+Cmd + Escape   = Toggle auto-tiling mode
--
-- Trackpad gestures (cursor in title bar):
--   4-finger swipe left   = Snap window to left half
--   4-finger swipe right  = Snap window to right half
--   4-finger swipe up     = Maximize window
--   4-finger swipe down   = Minimize window
--
-- Auto-tiling: Per-display, triggers on resize/move

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

hs.window.animationDuration = 0
hs.logger.defaultLogLevel = "warning"

local ctrlOpt = { "ctrl", "alt" } -- resize within display
local hyper = { "ctrl", "alt", "cmd" } -- move between displays + maximize
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

local function tileWindows(targetScreen)
  if not autoTileEnabled then
    return
  end

  local screen = targetScreen or hs.screen.mainScreen()
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
  -- Horizontal positions (full height)
  left = { x = 0, y = 0, w = 0.5, h = 1 },
  right = { x = 0.5, y = 0, w = 0.5, h = 1 },
  leftThird = { x = 0, y = 0, w = 1/3, h = 1 },
  rightThird = { x = 2/3, y = 0, w = 1/3, h = 1 },
  leftTwoThirds = { x = 0, y = 0, w = 2/3, h = 1 },
  rightTwoThirds = { x = 1/3, y = 0, w = 2/3, h = 1 },
  -- Vertical positions (full width)
  top = { x = 0, y = 0, w = 1, h = 0.5 },
  bottom = { x = 0, y = 0.5, w = 1, h = 0.5 },
  topThird = { x = 0, y = 0, w = 1, h = 1/3 },
  bottomThird = { x = 0, y = 2/3, w = 1, h = 1/3 },
  topTwoThirds = { x = 0, y = 0, w = 1, h = 2/3 },
  bottomTwoThirds = { x = 0, y = 1/3, w = 1, h = 2/3 },
  -- Full screen
  maximize = { x = 0, y = 0, w = 1, h = 1 },
}

local function moveWindow(position)
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(position)
    -- Trigger auto-tile for current screen after resize
    hs.timer.doAfter(0.1, function()
      tileWindows(win:screen())
    end)
  end
end

-- Cycle through positions: half → third → two-thirds
-- Each direction has its own cycle that resets when switching directions
local cycles = {
  left = { "left", "leftThird", "leftTwoThirds" },
  right = { "right", "rightThird", "rightTwoThirds" },
  up = { "top", "topThird", "topTwoThirds" },
  down = { "bottom", "bottomThird", "bottomTwoThirds" },
}

local cycleIndices = { left = 1, right = 1, up = 1, down = 1 }
local lastDirection = nil

local function cyclePosition(direction)
  -- Reset other directions when switching
  if lastDirection ~= direction then
    for k, _ in pairs(cycleIndices) do
      cycleIndices[k] = 1
    end
    lastDirection = direction
  end

  local cycle = cycles[direction]
  local idx = cycleIndices[direction]
  moveWindow(positions[cycle[idx]])
  cycleIndices[direction] = (idx % #cycle) + 1
end

hs.hotkey.bind(ctrlOpt, "Left", function() cyclePosition("left") end)
hs.hotkey.bind(ctrlOpt, "Right", function() cyclePosition("right") end)
hs.hotkey.bind(ctrlOpt, "Up", function() cyclePosition("up") end)
hs.hotkey.bind(ctrlOpt, "Down", function() cyclePosition("down") end)

--------------------------------------------------------------------------------
-- Cross-Display Movement (Ctrl+Opt+Cmd + Arrows)
--------------------------------------------------------------------------------

local function moveToScreen(direction)
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local currentScreen = win:screen()
  local targetScreen

  if direction == "left" then
    targetScreen = currentScreen:toWest()
  elseif direction == "right" then
    targetScreen = currentScreen:toEast()
  elseif direction == "up" then
    targetScreen = currentScreen:toNorth()
  elseif direction == "down" then
    targetScreen = currentScreen:toSouth()
  end

  if not targetScreen then
    hs.alert.show("No display in that direction")
    return
  end

  -- Preserve unit rect (proportional position/size)
  local unitRect = win:frame():toUnitRect(currentScreen:frame())
  win:moveToScreen(targetScreen)
  win:moveToUnit(unitRect)

  -- Auto-tile both screens
  hs.timer.doAfter(0.1, function()
    tileWindows(currentScreen)
    tileWindows(targetScreen)
  end)
end

hs.hotkey.bind(hyper, "Left", function()
  moveToScreen("left")
end)
hs.hotkey.bind(hyper, "Right", function()
  moveToScreen("right")
end)
hs.hotkey.bind(hyper, "Up", function()
  moveToScreen("up")
end)
hs.hotkey.bind(hyper, "Down", function()
  moveToScreen("down")
end)

--------------------------------------------------------------------------------
-- Fullscreen (Ctrl+Opt+Cmd + Enter) - just fills the screen
--------------------------------------------------------------------------------

hs.hotkey.bind(hyper, "Return", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(positions.maximize)
    hs.timer.doAfter(0.1, function()
      tileWindows(win:screen())
    end)
  end
end)

--------------------------------------------------------------------------------
-- Toggle Maximize/Restore (Ctrl+Opt+Cmd+Shift + Enter)
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

  if isMaximized and savedFrames[id] then
    win:setFrame(savedFrames[id])
    savedFrames[id] = nil
  else
    savedFrames[id] = currentFrame
    win:moveToUnit(positions.maximize)
  end

  hs.timer.doAfter(0.1, function()
    tileWindows(win:screen())
  end)
end)

--------------------------------------------------------------------------------
-- Fuzzy Window Switcher (Ctrl+Opt+Cmd + W)
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

      if direction == "left" then
        win:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 }) -- snap left
      elseif direction == "right" then
        win:moveToUnit({ x = 0.5, y = 0, w = 0.5, h = 1 }) -- snap right
      elseif direction == "up" then
        win:moveToUnit({ x = 0, y = 0, w = 1, h = 1 }) -- maximize
      elseif direction == "down" then
        win:minimize() -- minimize
      end

      -- Trigger auto-tile after swipe gesture
      hs.timer.doAfter(0.1, function()
        tileWindows(win:screen())
      end)
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
