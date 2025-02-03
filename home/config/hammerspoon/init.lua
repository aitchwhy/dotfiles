-- -- Reload config
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
--   hs.reload()
-- end)

-- -- Initialize variables
-- local lastShiftPressTime = 0
-- local shiftDoublePressPeriod = 0.3
-- local fnPressed = false

-- -- Function to simulate keypress
-- local function keyStroke(modifiers, key)
--   hs.eventtap.keyStroke(modifiers, key, 0)
-- end

-- -- Fn + HJKL for window/tab navigation
-- local fnHJKL = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local keyCode = event:getKeyCode()
--   local flags = event:getFlags()
  
--   if flags.fn then
--     -- Map fn + h/l to ctrl+shift+tab / ctrl+tab (switch tabs)
--     if keyCode == hs.keycodes.map['h'] then
--       keyStroke({'ctrl', 'shift'}, 'tab')
--       return true
--     elseif keyCode == hs.keycodes.map['l'] then
--       keyStroke({'ctrl'}, 'tab')
--       return true
--     -- Map fn + j/k to cmd+shift+` / cmd+` (switch windows)
--     elseif keyCode == hs.keycodes.map['j'] then
--       keyStroke({'cmd', 'shift'}, '`')
--       return true
--     elseif keyCode == hs.keycodes.map['k'] then
--       keyStroke({'cmd'}, '`')
--       return true
--     end
--   end
--   return false
-- end)
-- fnHJKL:start()

-- -- Double tap left shift to type ~/
-- local leftShiftTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
--   local flags = event:getFlags()
--   local currentTime = hs.timer.secondsSinceEpoch()
  
--   if flags.shift and not flags.cmd and not flags.ctrl and not flags.alt then
--     if (currentTime - lastShiftPressTime) < shiftDoublePressPeriod then
--       hs.eventtap.keyStrokes("~/")
--       lastShiftPressTime = 0
--       return true
--     end
--     lastShiftPressTime = currentTime
--   end
--   return false
-- end)
-- leftShiftTap:start()

-- -- Right Command + V to open Karabiner EventViewer
-- hs.hotkey.bind({"rightcmd"}, "v", function()
--   hs.application.launchOrFocus("/Applications/Karabiner-EventViewer.app")
-- end)

-- -- Control + H to delete
-- hs.hotkey.bind({"ctrl"}, "h", function()
--   keyStroke({}, "delete")
-- end)

-- -- Caps Lock handler (requires Karabiner for the initial mapping)
-- -- Note: The actual Caps Lock to Esc (tap) + Ctrl (hold) needs to be configured in Karabiner
-- -- as Hammerspoon cannot distinguish between tap and hold events for modifier keys

-- -- Mission Control on double-tap right shift
-- -- Note: This is better handled by Karabiner due to the need for variable state tracking

-- -- Equal + Delete to Forward Delete
-- local equalDeleteTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local flags = event:getFlags()
--   local keyCode = event:getKeyCode()
  
--   if keyCode == hs.keycodes.map['delete'] and flags.shift then
--     keyStroke({}, "forwarddelete")
--     return true
--   end
--   return false
-- end)
-- equalDeleteTap:start()

-- -- Fn + Quote/Semicolon to cycle through applications
-- local fnQuoteSemicolon = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local keyCode = event:getKeyCode()
--   local flags = event:getFlags()
  
--   if flags.fn then
--     if keyCode == hs.keycodes.map["'"] then
--       keyStroke({'cmd'}, 'tab')
--       return true
--     elseif keyCode == hs.keycodes.map[';'] then
--       keyStroke({'cmd', 'shift'}, 'tab')
--       return true
--     end
--   end
--   return false
-- end)
-- fnQuoteSemicolon:start()

-- -- Print message to console to confirm config loaded
-- print("Hammerspoon config loaded")

-- -- Note: Some Karabiner features cannot be perfectly replicated in Hammerspoon:
-- -- 1. Modifier key tap vs hold distinctions (like Caps Lock behavior)
-- -- 2. Complex variable state tracking for double-tap behaviors
-- -- 3. Device-specific configurations
-- -- These should remain in Karabiner while using Hammerspoon for other functionality
