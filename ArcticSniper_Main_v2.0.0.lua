--[[
ARCTIC SNIPER — SINGLE MAIN SCREEN
Oxide-inspired compact layout with Arctic icy-blue branding.
Local UI/demo only: announcement scanning is not connected to another game's private UI,
redeeming is not implemented, and toggles without backing systems are visual preferences.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("ArcticSniperMain")
if old then old:Destroy() end

local C = {
 BG = Color3.fromRGB(4, 9, 16), PANEL = Color3.fromRGB(10, 18, 29),
 ROW = Color3.fromRGB(16, 29, 43), HOVER = Color3.fromRGB(24, 43, 60),
 BLUE = Color3.fromRGB(80, 190, 255), BLUE_DARK = Color3.fromRGB(20, 79, 117),
 WHITE = Color3.fromRGB(239, 248, 255), MUTED = Color3.fromRGB(126, 157, 181),
 GREEN = Color3.fromRGB(125, 232, 197), BORDER = Color3.fromRGB(39, 83, 111)
}
local BLUE_PALETTE = {
 BLUE = Color3.fromRGB(80, 190, 255), BLUE_DARK = Color3.fromRGB(20, 79, 117),
 BORDER = Color3.fromRGB(39, 83, 111), ROW = Color3.fromRGB(16, 29, 43),
 HOVER = Color3.fromRGB(24, 43, 60), MUTED = Color3.fromRGB(126, 157, 181)
}
local HALLOWEEN_PALETTE = {
 BLUE = Color3.fromRGB(255, 137, 43), BLUE_DARK = Color3.fromRGB(126, 55, 14),
 BORDER = Color3.fromRGB(130, 68, 27), ROW = Color3.fromRGB(35, 24, 20),
 HOVER = Color3.fromRGB(57, 34, 22), MUTED = Color3.fromRGB(190, 151, 122)
}
local CHRISTMAS_PALETTE = {
 BLUE = Color3.fromRGB(70, 220, 125), BLUE_DARK = Color3.fromRGB(145, 28, 42),
 BORDER = Color3.fromRGB(35, 130, 75), ROW = Color3.fromRGB(24, 47, 37),
 HOVER = Color3.fromRGB(35, 68, 48), MUTED = Color3.fromRGB(155, 205, 170)
}
local THANKSGIVING_PALETTE = {
 BLUE = Color3.fromRGB(220, 112, 38), BLUE_DARK = Color3.fromRGB(111, 57, 25),
 BORDER = Color3.fromRGB(168, 104, 39), ROW = Color3.fromRGB(43, 31, 24),
 HOVER = Color3.fromRGB(64, 43, 29), MUTED = Color3.fromRGB(205, 164, 120)
}
local TACO_PALETTE = {
 BLUE = Color3.fromRGB(237, 174, 54), BLUE_DARK = Color3.fromRGB(139, 76, 28),
 BORDER = Color3.fromRGB(181, 111, 42), ROW = Color3.fromRGB(48, 37, 22),
 HOVER = Color3.fromRGB(72, 53, 27), MUTED = Color3.fromRGB(216, 185, 125)
}
local SATURDAY_PALETTE = {
 BLUE = Color3.fromRGB(255, 92, 180), BLUE_DARK = Color3.fromRGB(117, 39, 101),
 BORDER = Color3.fromRGB(178, 69, 151), ROW = Color3.fromRGB(43, 25, 48),
 HOVER = Color3.fromRGB(70, 37, 71), MUTED = Color3.fromRGB(215, 157, 208)
}
local THEME_PALETTES = {BLUE = BLUE_PALETTE, HALLOWEEN = HALLOWEEN_PALETTE, CHRISTMAS = CHRISTMAS_PALETTE, THANKSGIVING = THANKSGIVING_PALETTE, TACO = TACO_PALETTE, SATURDAY = SATURDAY_PALETTE}
local currentTheme = "BLUE"
local mini
local leafLayer
local SETTINGS_FILE = "ArcticSniper_Settings.json"
local SCRIPT_VERSION = "1.2.0"
local VERSION_URL = "https://raw.githubusercontent.com/matthewcastillo2303-sketch/ArcticSniperUpdLayOut/refs/heads/main/ArcticSniper_Version.txt"
local prefs = {scan = false, scope = false, spam = false, hideUser = false, auto = 5, scale = 0.85, theme = "BLUE"}

-- Persistence depends on executor-provided file APIs.
local persistenceLabel
local persistenceState = "File saving unavailable"
local function loadSettings()
 if type(readfile) ~= "function" or type(writefile) ~= "function" then
  persistenceState = "SAVE UNSUPPORTED"
  warn("[Arctic Sniper] Settings won't persist: this executor needs readfile and writefile.")
  return
 end
 local ok, raw = pcall(readfile, SETTINGS_FILE)
 if not ok or type(raw) ~= "string" then
  persistenceState = "SAVE READY"
  return -- First run or file not present yet; don't overwrite anything until a setting changes.
 end
 local decodedOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
 if not decodedOk or type(data) ~= "table" then
  persistenceState = "SAVE ERROR"
  warn("[Arctic Sniper] Couldn't read settings file: invalid JSON.")
  return
 end
 for _, key in ipairs({"scan", "scope", "spam", "hideUser"}) do
  if type(data[key]) == "boolean" then prefs[key] = data[key] end
 end
 if type(data.auto) == "number" then prefs.auto = math.clamp(math.floor(data.auto), 1, 5) end
 if type(data.scale) == "number" then prefs.scale = math.clamp(data.scale, 0.55, 1) end
 if data.theme == "BLUE" or data.theme == "HALLOWEEN" or data.theme == "CHRISTMAS" or data.theme == "THANKSGIVING" or data.theme == "TACO" or data.theme == "SATURDAY" then prefs.theme = data.theme end
 persistenceState = "SETTINGS LOADED"
end
local function saveSettings()
 if type(writefile) ~= "function" then
  persistenceState = "SAVE UNSUPPORTED"
  if persistenceLabel then persistenceLabel.Text = persistenceState end
  return false
 end
 local data = {
  scan = prefs.scan, scope = prefs.scope, spam = prefs.spam, hideUser = prefs.hideUser,
  auto = prefs.auto, scale = prefs.scale, theme = prefs.theme
 }
 local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
 if not ok then
  persistenceState = "SAVE ERROR"
  warn("[Arctic Sniper] Couldn't encode settings.")
  if persistenceLabel then persistenceLabel.Text = persistenceState end
  return false
 end
 local writeOk, writeErr = pcall(writefile, SETTINGS_FILE, encoded)
 if writeOk then
  persistenceState = "SETTINGS SAVED"
 else
  persistenceState = "SAVE ERROR"
  warn("[Arctic Sniper] Writing settings failed: " .. tostring(writeErr))
 end
 if persistenceLabel then persistenceLabel.Text = persistenceState end
 return writeOk
end
loadSettings()
local currentCode = ""
local historyItems = {}
local historyRefresh

local function make(className, props, parent)
 local obj = Instance.new(className)
 for k, v in pairs(props or {}) do obj[k] = v end
 obj.Parent = parent
 return obj
end
local function corner(obj, radius)
 make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end
local function outline(obj, color, thickness)
 make("UIStroke", {Color = color or C.BORDER, Thickness = thickness or 1, Transparency = 0.15}, obj)
end
local function text(parent, value, size, pos, fontSize, color, centered, font)
 return make("TextLabel", {
  BackgroundTransparency = 1, Text = value or "", Size = size, Position = pos,
  Font = font or Enum.Font.Gotham, TextSize = fontSize or 11,
  TextColor3 = color or C.WHITE,
  TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
  TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true
 }, parent)
end
local function button(parent, value, size, pos, callback, color)
 local b = make("TextButton", {
  Size = size, Position = pos, BackgroundColor3 = color or C.ROW,
  BorderSizePixel = 0, Text = value, TextColor3 = C.WHITE,
  TextSize = 10, Font = Enum.Font.GothamSemibold, AutoButtonColor = false
 }, parent)
 corner(b, 7); outline(b)
 local isAccent = color == C.BLUE_DARK
 b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.12), {BackgroundColor3 = C.HOVER}):Play() end)
 b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.12), {BackgroundColor3 = isAccent and C.BLUE_DARK or C.ROW}):Play() end)
 b.Activated:Connect(function() if callback then callback() end end)
 return b
end

local gui = make("ScreenGui", {
 Name = "ArcticSniperMain", ResetOnSpawn = false, IgnoreGuiInset = true,
 DisplayOrder = 9999, ZIndexBehavior = Enum.ZIndexBehavior.Global
}, playerGui)
local main = make("Frame", {
 Name = "Main", AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
 Size = UDim2.fromOffset(320, 420), BackgroundColor3 = C.BG,
 BorderSizePixel = 0, Active = true, ClipsDescendants = true
}, gui)
corner(main, 13); outline(main, C.BORDER, 1.4)
make("UIGradient", {Color = ColorSequence.new({
 ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 38, 59)),
 ColorSequenceKeypoint.new(0.45, Color3.fromRGB(7, 17, 29)),
 ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 8, 15))
}), Rotation = 90}, main)
local panelSheen = make("Frame", {Name = "PanelSheen", Position = UDim2.fromOffset(1,1), Size = UDim2.new(1,-2,0,2), BackgroundColor3 = Color3.fromRGB(190,230,255), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 3}, main)
corner(panelSheen, 2)
leafLayer = make("Frame", {
 Name = "ThemeParticles", Size = UDim2.fromScale(1,1),
 BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
 Active = false, Visible = true, ZIndex = 50
}, main)
local uiScale = make("UIScale", {Scale = 1}, main)
local function resize()
 local camera = workspace.CurrentCamera
 if not camera then return end
 local v = camera.ViewportSize
 uiScale.Scale = math.clamp(math.min((v.X - 18)/320, (v.Y - 18)/420, prefs.scale), .55, 1)
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

-- Header
local header = make("Frame", {Size = UDim2.new(1,0,0,43), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Active = true}, main)
local logo = make("Frame", {Size = UDim2.fromOffset(29,29), Position = UDim2.fromOffset(8,7), BackgroundColor3 = Color3.fromRGB(9,29,49), BorderSizePixel = 0}, header)
corner(logo, 8); outline(logo, Color3.fromRGB(103,174,220))
make("UIGradient", {Color = ColorSequence.new({
 ColorSequenceKeypoint.new(0, Color3.fromRGB(36,82,119)),
 ColorSequenceKeypoint.new(0.48, Color3.fromRGB(13,39,65)),
 ColorSequenceKeypoint.new(1, Color3.fromRGB(4,15,28))
}), Rotation = 90}, logo)
local logoShine = make("Frame", {Position = UDim2.new(0,4,0,3), Size = UDim2.new(1,-8,0,2), BackgroundColor3 = Color3.fromRGB(211,237,255), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2}, logo)
corner(logoShine, 2)
local logoLetter = text(logo, "A", UDim2.fromScale(1,1), UDim2.new(), 18, Color3.fromRGB(221,241,255), true, Enum.Font.GothamBlack)
logoLetter.ZIndex = 3
text(header, "ARCTIC SNIPER", UDim2.new(0,170,0,18), UDim2.fromOffset(44,5), 11, C.WHITE, false, Enum.Font.GothamBold)
text(header, "FROST EDITION", UDim2.new(0,140,0,13), UDim2.fromOffset(45,22), 7, C.MUTED)
local statusDot = make("Frame", {Size = UDim2.fromOffset(6,6), Position = UDim2.new(1,-105,0,13), BackgroundColor3 = C.GREEN, BorderSizePixel = 0}, header)
corner(statusDot, 5)
persistenceLabel = text(header, persistenceState, UDim2.fromOffset(82,15), UDim2.new(1,-112,0,9), 6, C.MUTED)
local closeButton = button(header, "×", UDim2.fromOffset(23,23), UDim2.new(1,-29,0,9), function() gui:Destroy() end, C.BLUE_DARK)
closeButton.TextSize = 16

-- Drag window by the header.
do
 local dragging, startPoint, startPos, dragType = false, nil, nil, nil
 header.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
   dragging = true; startPoint = input.Position; startPos = main.Position; dragType = input.UserInputType
  end
 end)
 UIS.InputChanged:Connect(function(input)
  if not dragging then return end
  local moving = (dragType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
   or (dragType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)
  if moving then
   local delta = input.Position - startPoint
   main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end
 end)
 UIS.InputEnded:Connect(function(input)
  if (dragType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
   or (dragType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch) then
   dragging = false; dragType = nil
  end
 end)
end

-- Minimal rail: only Main and Settings remain.
local rail = make("Frame", {Position = UDim2.fromOffset(7,49), Size = UDim2.new(0,56,1,-56), BackgroundColor3 = C.PANEL, BorderSizePixel = 0}, main)
corner(rail, 9); outline(rail)
text(rail, "ARCTIC", UDim2.new(1,0,0,18), UDim2.fromOffset(0,7), 7, C.MUTED, true, Enum.Font.GothamBold)
local content
local settingsPanel
local testerPanel
local historyPanel
local sequencePanel
local function hideExtraPanels()
 if settingsPanel then settingsPanel.Visible = false end
 if testerPanel then testerPanel.Visible = false end
 if historyPanel then historyPanel.Visible = false end
 if sequencePanel then sequencePanel.Visible = false end
end
button(rail, "MAIN", UDim2.new(1,-8,0,28), UDim2.fromOffset(4,31), function()
 if content then content.Visible = true end
 hideExtraPanels()
end, C.BLUE_DARK).TextSize = 7
button(rail, "TESTER", UDim2.new(1,-8,0,28), UDim2.fromOffset(4,64), function()
 local show = testerPanel and not testerPanel.Visible
 hideExtraPanels()
 if testerPanel then testerPanel.Visible = show end
end, C.ROW).TextSize = 6
button(rail, "SETTINGS", UDim2.new(1,-8,0,28), UDim2.fromOffset(4,97), function()
 local show = settingsPanel and not settingsPanel.Visible
 hideExtraPanels()
 if settingsPanel then settingsPanel.Visible = show end
end, C.ROW).TextSize = 6
button(rail, "HISTORY", UDim2.new(1,-8,0,28), UDim2.fromOffset(4,130), function()
 local show = historyPanel and not historyPanel.Visible
 hideExtraPanels()
 if historyPanel then historyPanel.Visible = show end
end, C.ROW).TextSize = 6
button(rail, "SEQUENCE", UDim2.new(1,-8,0,28), UDim2.fromOffset(4,163), function()
 local show = sequencePanel and not sequencePanel.Visible
 hideExtraPanels()
 if sequencePanel then sequencePanel.Visible = show end
end, C.ROW).TextSize = 5
text(rail, "❄", UDim2.new(1,0,0,20), UDim2.new(0,0,1,-24), 12, C.BLUE, true)

content = make("ScrollingFrame", {Name = "MainContent", Position = UDim2.fromOffset(69,49), Size = UDim2.new(1,-77,1,-56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.BLUE, CanvasSize = UDim2.new(0,0,0,390), ScrollingDirection = Enum.ScrollingDirection.Y, Active = true}, main)

-- Top row and sniped-code card
local topRow = make("Frame", {Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1}, content)
text(topRow, "●  ARCTIC STATUS: READY", UDim2.new(.65,0,1,0), UDim2.new(), 8, C.GREEN)
text(topRow, "AUTO SUBMIT "..prefs.auto, UDim2.new(.35,0,1,0), UDim2.new(.65,0,0,0), 8, C.BLUE, true)

local codeCard = make("Frame", {Position = UDim2.fromOffset(0,22), Size = UDim2.new(1,0,0,69), BackgroundColor3 = C.PANEL, BorderSizePixel = 0}, content)
corner(codeCard, 9); outline(codeCard)
text(codeCard, "SNIPED CODE", UDim2.new(1,-90,0,13), UDim2.fromOffset(9,5), 7, C.BLUE, false, Enum.Font.GothamBold)
local codeLabel = make("TextBox", {
 Size = UDim2.new(1,-100,0,24), Position = UDim2.fromOffset(9,20),
 BackgroundTransparency = 1, BorderSizePixel = 0, ClearTextOnFocus = false,
 Text = "waiting...", TextColor3 = C.WHITE, TextSize = 16,
 Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
 TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false,
 PlaceholderText = "Type or edit code here", PlaceholderColor3 = C.MUTED,
}, codeCard)
codeLabel.FocusLost:Connect(function()
 currentCode = codeLabel.Text
 if currentCode ~= "" and currentCode ~= "waiting..." and historyRefresh then historyRefresh(currentCode, "Manual code") end
end)
local codeHint = text(codeCard, "Local preview • no live game connection", UDim2.new(1,-100,0,13), UDim2.fromOffset(9,45), 7, C.MUTED)
button(codeCard, "RESET", UDim2.fromOffset(52,21), UDim2.new(1,-61,0,8), function()
 currentCode = ""; codeLabel.Text = "waiting..."; codeHint.Text = "Local preview • reset"; codeHint.TextColor3 = C.MUTED
end, C.BLUE_DARK)

local function toggleRow(y, titleText, subtitle, initial, onChanged)
 local row = make("Frame", {Position = UDim2.fromOffset(0,y), Size = UDim2.new(1,0,0,34), BackgroundColor3 = C.ROW, BorderSizePixel = 0}, content)
 corner(row, 7); outline(row)
 text(row, titleText, UDim2.new(1,-62,0,15), UDim2.fromOffset(9,3), 8, C.WHITE, false, Enum.Font.GothamSemibold)
 text(row, subtitle, UDim2.new(1,-62,0,11), UDim2.fromOffset(9,18), 6, C.MUTED)
 local on = initial == true
 local track = make("TextButton", {Size = UDim2.fromOffset(32,17), Position = UDim2.new(1,-40,.5,-8), BackgroundColor3 = on and C.BLUE or C.BG, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, row)
 corner(track, 10)
 local knob = make("Frame", {Size = UDim2.fromOffset(11,11), Position = on and UDim2.new(1,-14,.5,-5) or UDim2.fromOffset(3,3), BackgroundColor3 = C.WHITE, BorderSizePixel = 0}, track)
 corner(knob, 7)
 track.Activated:Connect(function()
  on = not on
  track.BackgroundColor3 = on and C.BLUE or C.BG
  TweenService:Create(knob, TweenInfo.new(.12), {Position = on and UDim2.new(1,-14,.5,-5) or UDim2.fromOffset(3,3)}):Play()
  if onChanged then onChanged(on) end
 end)
 return row
end

toggleRow(91, "scan announcements", "Paste fragments below; scanner does not read private game UI", prefs.scan, function(v)
 prefs.scan = v
 saveSettings()
 codeHint.Text = v and "Paste fragments below, then press SCAN TEXT" or "Scanner paused"
 codeHint.TextColor3 = v and C.BLUE or C.MUTED
end)
toggleRow(127, "auto scope", "Preference toggle only", prefs.scope, function(v) prefs.scope=v; saveSettings() end)
toggleRow(163, "spam redeem", "Preview preference; no redemption calls", prefs.spam, function(v) prefs.spam=v; saveSettings() end)
toggleRow(199, "hide user", "Visual preference only", prefs.hideUser, function(v) prefs.hideUser=v; saveSettings() end)

-- Auto submit selector
local autoRow = make("Frame", {Position = UDim2.fromOffset(0,222), Size = UDim2.new(1,0,0,27), BackgroundColor3 = C.ROW, BorderSizePixel = 0}, content)
corner(autoRow, 7); outline(autoRow)
text(autoRow, "auto submit", UDim2.new(.42,0,0,13), UDim2.fromOffset(9,3), 8, C.WHITE, false, Enum.Font.GothamSemibold)
text(autoRow, "pieces per code", UDim2.new(.42,0,0,10), UDim2.fromOffset(9,16), 6, C.MUTED)
local choices = make("Frame", {Position = UDim2.new(.44,0,0,4), Size = UDim2.new(.54,-5,0,22), BackgroundTransparency = 1}, autoRow)
local choiceButtons = {}
local function setAuto(n)
 prefs.auto = n
 saveSettings()
 for i, b in ipairs(choiceButtons) do
  b.BackgroundColor3 = i == n and C.BLUE_DARK or C.PANEL
  b.TextColor3 = i == n and C.WHITE or C.MUTED
 end
 topRow:FindFirstChildWhichIsA("TextLabel", true).Text = "●  ARCTIC STATUS: READY"
 local labels = topRow:GetChildren()
 for _, child in ipairs(labels) do
  if child:IsA("TextLabel") and child.Text:find("AUTO SUBMIT") then child.Text = "AUTO SUBMIT "..n end
 end
end
for i=1,5 do
 local b = button(choices, tostring(i), UDim2.new(.2,-2,1,0), UDim2.new((i-1)*.2, i == 1 and 0 or 1, 0, 0), function() setAuto(i) end, i == prefs.auto and C.BLUE_DARK or C.PANEL)
 b.TextSize = 8; b.TextColor3 = i == prefs.auto and C.WHITE or C.MUTED
 table.insert(choiceButtons, b)
end

-- Bottom action buttons
local bottom = make("Frame", {Position = UDim2.fromOffset(0,330), Size = UDim2.new(1,0,0,25), BackgroundTransparency = 1}, content)
local fragmentBox = make("TextBox", {
 Size = UDim2.new(.68,-4,1,0), Position = UDim2.new(0,0,0,0),
 BackgroundColor3 = C.ROW, BorderSizePixel = 0, ClearTextOnFocus = false,
 PlaceholderText = "Paste fragments: ABC 12 XY", Text = "", TextColor3 = C.WHITE,
 PlaceholderColor3 = C.MUTED, TextSize = 8, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left
}, bottom)
corner(fragmentBox, 7); outline(fragmentBox)
button(bottom, "SCAN TEXT", UDim2.new(.32,0,1,0), UDim2.new(.68,4,0,0), function()
 local raw = string.upper(fragmentBox.Text or "")
 local pieces = {}
 for piece in string.gmatch(raw, "[A-Z0-9]+") do
  table.insert(pieces, piece)
 end
 if #pieces < 2 then
  codeHint.Text = "Enter 2+ fragments separated by spaces"
  codeHint.TextColor3 = C.MUTED
  return
 end
 currentCode = table.concat(pieces, "")
 codeLabel.Text = currentCode
 if historyRefresh then historyRefresh(currentCode, "Scanned text") end
 codeHint.Text = "Scanned supplied text • verify the result"
 codeHint.TextColor3 = C.GREEN
end, C.BLUE_DARK)

-- This scans text the user supplies; it does not read another game's private banner UI.

-- Local-only announcement: the only visible object is the text itself.
local bannerToken = 0
local oldBannerGui = playerGui:FindFirstChild("ArcticSniperTestBanner")
if oldBannerGui then oldBannerGui:Destroy() end
local bannerGui = make("ScreenGui", {
 Name = "ArcticSniperTestBanner", ResetOnSpawn = false,
 IgnoreGuiInset = true, DisplayOrder = 10000,
 ZIndexBehavior = Enum.ZIndexBehavior.Global
}, playerGui)
-- Black text layer underneath gives the white announcement a visible outline.
local bannerOutline = make("TextLabel", {
 Name = "ArcticTestAnnouncementOutline",
 AnchorPoint = Vector2.new(0.5, 0),
 Position = UDim2.new(0.5, 0, 0, 64),
 Size = UDim2.new(0.9, 0, 0, 44),
 BackgroundTransparency = 1, BorderSizePixel = 0,
 Text = "", TextColor3 = Color3.new(0, 0, 0),
 TextSize = 25, TextScaled = true, TextWrapped = true,
 Font = Enum.Font.GothamBold,
 TextXAlignment = Enum.TextXAlignment.Center,
 TextYAlignment = Enum.TextYAlignment.Center,
 TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0,
 Visible = false, ZIndex = 1000
}, bannerGui)
local bannerBody = make("TextLabel", {
 Name = "ArcticTestAnnouncementText",
 AnchorPoint = Vector2.new(0.5, 0),
 Position = UDim2.new(0.5, 0, 0, 64),
 Size = UDim2.new(0.9, 0, 0, 44),
 BackgroundTransparency = 1, BorderSizePixel = 0,
 Text = "", TextColor3 = Color3.new(1, 1, 1),
 TextSize = 25, TextScaled = true, TextWrapped = true,
 Font = Enum.Font.GothamBold,
 TextXAlignment = Enum.TextXAlignment.Center,
 TextYAlignment = Enum.TextYAlignment.Center,
 TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0,
 Visible = false, ZIndex = 1002
}, bannerGui)
local testBanner = bannerBody

-- Local-only announcement tester. Nothing is sent to a server or other players.
testerPanel = make("Frame", {
 Name = "AnnouncementTester", Position = UDim2.fromOffset(0,0), Size = UDim2.fromScale(1,1),
 BackgroundColor3 = C.BG, BorderSizePixel = 0, Visible = false, ZIndex = 20
}, content)
corner(testerPanel, 9); outline(testerPanel, C.BORDER, 1.2)
text(testerPanel, "TEXT TESTER", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,8), 12, C.WHITE, false, Enum.Font.GothamBold).ZIndex = 21
text(testerPanel, "Preview a fake announcement on your screen only.", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,34), 8, C.MUTED).ZIndex = 21
local announcementInput = make("TextBox", {
 Name = "AnnouncementInput", Size = UDim2.new(1,-20,0,70), Position = UDim2.fromOffset(10,66),
 BackgroundColor3 = C.ROW, BorderSizePixel = 0, ClearTextOnFocus = false,
 Text = "", PlaceholderText = "Type your test announcement here...",
 TextColor3 = C.WHITE, PlaceholderColor3 = C.MUTED, TextSize = 10,
 Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
 TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, MultiLine = true,
 ZIndex = 21
}, testerPanel)
corner(announcementInput, 8); outline(announcementInput)
local previewStatus = text(testerPanel, "LOCAL TEST ONLY • NOT SENT TO ANYONE",
 UDim2.new(1,-20,0,26), UDim2.fromOffset(10,145), 8, C.GREEN, true)
previewStatus.ZIndex = 21
local showTestButton = button(testerPanel, "SEND TEST BANNER", UDim2.new(.62,-13,0,32), UDim2.fromOffset(10,181), function()
 local message = string.gsub(announcementInput.Text or "", "^%s*(.-)%s*$", "%1")
 if message == "" then
  previewStatus.Text = "TYPE A MESSAGE FIRST"
  previewStatus.TextColor3 = C.MUTED
  return
 end
 bannerBody.Text = message
 testBanner.Visible = true
 bannerToken = bannerToken + 1
 local thisToken = bannerToken
 previewStatus.Text = "BANNER SHOWN ON YOUR SCREEN"
 previewStatus.TextColor3 = C.GREEN
 task.delay(5, function()
  if bannerToken == thisToken and testBanner and testBanner.Parent then
   testBanner.Visible = false
    bannerOutline.Visible = false
  end
 end)
end, C.BLUE_DARK)
showTestButton.ZIndex = 21
local clearTestButton = button(testerPanel, "CLEAR", UDim2.new(.38,-7,0,32), UDim2.new(.62,3,0,181), function()
 announcementInput.Text = ""
 previewStatus.Text = "LOCAL TEST ONLY • NOT SENT TO ANYONE"
 previewStatus.TextColor3 = C.GREEN
 testBanner.Visible = false
  bannerOutline.Visible = false
end, C.ROW)
clearTestButton.ZIndex = 21
local testerBackButton = button(testerPanel, "BACK TO MAIN", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,332), function()
 testerPanel.Visible = false
end, C.ROW)
testerBackButton.ZIndex = 21


-- History panel: keeps recent codes in this session, newest first.
historyPanel = make("Frame", {
 Name = "HistoryPanel", Position = UDim2.fromOffset(0,0), Size = UDim2.fromScale(1,1),
 BackgroundColor3 = C.BG, BorderSizePixel = 0, Visible = false, ZIndex = 20
}, content)
corner(historyPanel, 9); outline(historyPanel, C.BORDER, 1.2)
text(historyPanel, "HISTORY", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,8), 12, C.WHITE, false, Enum.Font.GothamBold).ZIndex = 21
text(historyPanel, "Recent codes • newest first • this session only", UDim2.new(1,-20,0,20), UDim2.fromOffset(10,35), 7, C.MUTED).ZIndex = 21
local historyList = make("ScrollingFrame", {
 Name = "HistoryList", Position = UDim2.fromOffset(10,60), Size = UDim2.new(1,-20,1,-108),
 BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 3,
 ScrollBarImageColor3 = C.BLUE, CanvasSize = UDim2.new(0,0,0,0), ZIndex = 21
}, historyPanel)
corner(historyList, 7); outline(historyList)
local historyLayout = make("UIListLayout", {Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder}, historyList)
historyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
 historyList.CanvasSize = UDim2.new(0,0,0,historyLayout.AbsoluteContentSize.Y + 8)
end)
historyRefresh = function(code, source)
 if not code or code == "" or code == "waiting..." then return end
 table.insert(historyItems, 1, {code = tostring(code), source = source or "Code", time = os.date("%I:%M:%S %p")})
 while #historyItems > 40 do table.remove(historyItems) end
 for _, child in ipairs(historyList:GetChildren()) do
  if child:IsA("Frame") then child:Destroy() end
 end
 for i, item in ipairs(historyItems) do
  local entry = make("Frame", {
   Size = UDim2.new(1,-8,0,42), BackgroundColor3 = C.ROW, BorderSizePixel = 0,
   LayoutOrder = i, ZIndex = 22
  }, historyList)
  corner(entry, 6); outline(entry)
  text(entry, item.code, UDim2.new(1,-12,0,18), UDim2.fromOffset(6,2), 10, C.WHITE, false, Enum.Font.GothamBold).ZIndex = 23
  text(entry, item.source.." • "..item.time, UDim2.new(1,-12,0,14), UDim2.fromOffset(6,22), 7, C.MUTED).ZIndex = 23
 end
end
local clearHistoryButton = button(historyPanel, "CLEAR HISTORY", UDim2.new(.48,0,0,28), UDim2.fromOffset(10,0), function()
 historyItems = {}
 for _, child in ipairs(historyList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
end, C.ROW)
clearHistoryButton.Position = UDim2.new(0,10,1,-38); clearHistoryButton.ZIndex = 22
local historyBack = button(historyPanel, "BACK", UDim2.new(.42,0,0,28), UDim2.new(.58,-10,1,-38), function()
 historyPanel.Visible = false
end, C.BLUE_DARK)
historyBack.ZIndex = 22

-- Sequence panel: local-only timed text preview, up to five parts.
sequencePanel = make("Frame", {
 Name = "SequencePanel", Position = UDim2.fromOffset(0,0), Size = UDim2.fromScale(1,1),
 BackgroundColor3 = C.BG, BorderSizePixel = 0, Visible = false, ZIndex = 20
}, content)
corner(sequencePanel, 9); outline(sequencePanel, C.BORDER, 1.2)
text(sequencePanel, "SEQUENCE MODE", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,8), 12, C.WHITE, false, Enum.Font.GothamBold).ZIndex = 21
text(sequencePanel, "Up to 5 announcement parts • 2 seconds apart", UDim2.new(1,-20,0,22), UDim2.fromOffset(10,35), 7, C.MUTED).ZIndex = 21
local sequenceBoxes = {}
for i = 1, 5 do
 local partLabel = text(sequencePanel, "PART "..i, UDim2.fromOffset(42,25), UDim2.fromOffset(10,62+(i-1)*43), 7, C.BLUE, false, Enum.Font.GothamBold)
 partLabel.ZIndex = 22
 local partBox = make("TextBox", {
  Name = "SequencePart"..i, Position = UDim2.fromOffset(53,62+(i-1)*43),
  Size = UDim2.new(1,-63,0,27), BackgroundColor3 = C.ROW, BorderSizePixel = 0,
  ClearTextOnFocus = false, Text = "", PlaceholderText = "Optional message part "..i,
  TextColor3 = C.WHITE, PlaceholderColor3 = C.MUTED, TextSize = 8,
  Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
  TextWrapped = false, ZIndex = 22
 }, sequencePanel)
 corner(partBox, 6); outline(partBox)
 table.insert(sequenceBoxes, partBox)
end
local sequenceStatus = text(sequencePanel, "READY • LOCAL PREVIEW ONLY", UDim2.new(1,-20,0,22), UDim2.fromOffset(10,282), 7, C.GREEN, true)
sequenceStatus.ZIndex = 22
local sequenceToken = 0
local sequenceStart = button(sequencePanel, "START", UDim2.new(.31,-4,0,28), UDim2.fromOffset(10,310), function()
 sequenceToken = sequenceToken + 1
 local myToken = sequenceToken
 local parts = {}
 for _, box in ipairs(sequenceBoxes) do
  local value = string.gsub(box.Text or "", "^%s*(.-)%s*$", "%1")
  if value ~= "" then table.insert(parts, value) end
 end
 if #parts == 0 then sequenceStatus.Text = "ENTER AT LEAST ONE PART"; return end
 task.spawn(function()
  sequenceStatus.Text = "SEQUENCE RUNNING"
  for i, value in ipairs(parts) do
   if myToken ~= sequenceToken then return end
   bannerOutline.Text = value; bannerBody.Text = value
   bannerOutline.Visible = true; bannerBody.Visible = true
   sequenceStatus.Text = "SHOWING PART "..i.." OF "..#parts
   task.wait(2)
  end
  if myToken == sequenceToken then
   bannerOutline.Visible = false; bannerBody.Visible = false
   sequenceStatus.Text = "SEQUENCE COMPLETE"
  end
 end)
end, C.BLUE_DARK)
sequenceStart.ZIndex = 22
local sequenceStop = button(sequencePanel, "STOP", UDim2.new(.31,-4,0,28), UDim2.new(.345,0,0,310), function()
 sequenceToken = sequenceToken + 1
 bannerOutline.Visible = false; bannerBody.Visible = false
 sequenceStatus.Text = "SEQUENCE STOPPED"
end, C.ROW)
sequenceStop.ZIndex = 22
local sequenceBack = button(sequencePanel, "BACK", UDim2.new(.31,-4,0,28), UDim2.new(.69,-1,0,310), function()
 sequenceToken = sequenceToken + 1
 sequencePanel.Visible = false
 bannerOutline.Visible = false; bannerBody.Visible = false
end, C.ROW)
sequenceBack.ZIndex = 22

-- Settings panel: themes, persistence, and update checker.
settingsPanel = make("Frame", {
 Name = "SettingsPanel", Position = UDim2.fromOffset(0,0), Size = UDim2.fromScale(1,1),
 BackgroundColor3 = C.BG, BorderSizePixel = 0, Visible = false, ZIndex = 20
}, content)
corner(settingsPanel, 9); outline(settingsPanel, C.BORDER, 1.2)
text(settingsPanel, "SETTINGS", UDim2.new(1,-20,0,26), UDim2.fromOffset(10,8), 12, C.WHITE, false, Enum.Font.GothamBold).ZIndex = 21
text(settingsPanel, "Choose your Arctic Sniper color theme", UDim2.new(1,-20,0,20), UDim2.fromOffset(10,35), 8, C.MUTED).ZIndex = 21

local function applyTheme(theme)
 if not THEME_PALETTES[theme] then theme = "BLUE" end
 local oldPalette = THEME_PALETTES[currentTheme] or BLUE_PALETTE
 local newPalette = THEME_PALETTES[theme]
 for _, obj in ipairs(gui:GetDescendants()) do
  for _, prop in ipairs({"BackgroundColor3", "TextColor3", "PlaceholderColor3"}) do
   local ok, value = pcall(function() return obj[prop] end)
   if ok and typeof(value) == "Color3" then
    for role, oldColor in pairs(oldPalette) do
     if value == oldColor then
      pcall(function() obj[prop] = newPalette[role] end)
      break
     end
    end
   end
  end
  if obj:IsA("UIStroke") then
   for role, oldColor in pairs(oldPalette) do
    if obj.Color == oldColor then obj.Color = newPalette[role]; break end
   end
  end
 end
 C.BLUE = newPalette.BLUE
 C.BLUE_DARK = newPalette.BLUE_DARK
 C.BORDER = newPalette.BORDER
 C.ROW = newPalette.ROW
 C.HOVER = newPalette.HOVER
 C.MUTED = newPalette.MUTED
 currentTheme = theme
 prefs.theme = theme
 saveSettings()
 if mini then
  mini.Text = theme == "HALLOWEEN" and "🎃 AS" or (theme == "CHRISTMAS" and "🎄 AS" or (theme == "THANKSGIVING" and "🦃 AS" or (theme == "TACO" and "🌮 AS" or (theme == "SATURDAY" and "🎉 AS" or "❄ AS"))))
  mini.BackgroundColor3 = theme == "HALLOWEEN" and Color3.fromRGB(77, 35, 13) or (theme == "CHRISTMAS" and Color3.fromRGB(105, 22, 36) or (theme == "THANKSGIVING" and Color3.fromRGB(75, 39, 20) or (theme == "TACO" and Color3.fromRGB(92, 57, 24) or (theme == "SATURDAY" and Color3.fromRGB(72, 30, 75) or C.PANEL))))
  local miniStroke = mini:FindFirstChildOfClass("UIStroke")
  if miniStroke then miniStroke.Color = newPalette.BLUE end
 end
 if leafLayer then leafLayer.Visible = true end
 for _, tab in pairs(themeTabs or {}) do
  if tab and tab.Parent then
   local selected = tab.Name == theme
   tab.BackgroundColor3 = selected and newPalette.BLUE_DARK or newPalette.ROW
   tab.TextColor3 = selected and Color3.fromRGB(255,255,255) or newPalette.MUTED
  end
 end
end

local themeTabs = {}
local function makeThemeTab(theme, label, xScale, yOffset, paletteColor)
 local tab = button(settingsPanel, label, UDim2.new(1/2, -15, 0, 34), UDim2.new(xScale, xScale == 0 and 8 or 7, 0, yOffset), function()
  applyTheme(theme)
 end, paletteColor)
 tab.Name = theme
 tab.TextSize = 9
 tab.ZIndex = 21
 themeTabs[theme] = tab
 return tab
end
-- Two rows keep all four theme choices visible on narrow mobile screens.
makeThemeTab("BLUE", "❄ NORMAL", 0, 66, C.BLUE_DARK)
makeThemeTab("HALLOWEEN", "🎃 HALLOWEEN", 1/2, 66, C.ROW)
makeThemeTab("CHRISTMAS", "🎄 CHRISTMAS", 0, 106, C.ROW)
makeThemeTab("THANKSGIVING", "🦃 THANKSGIVING", 1/2, 106, C.ROW)
text(settingsPanel, "ADMIN ABUSE THEMES", UDim2.new(1,-20,0,20), UDim2.fromOffset(10,148), 9, C.BLUE, false, Enum.Font.GothamBold).ZIndex = 21
makeThemeTab("TACO", "🌮 TACO RAIN", 0, 170, C.ROW)
makeThemeTab("SATURDAY", "🎉 ADMIN SATURDAY", 1/2, 170, C.ROW)
local backButton = button(settingsPanel, "BACK TO MAIN", UDim2.new(1,-20,0,30), UDim2.fromOffset(10,208), function()
 settingsPanel.Visible = false
end, C.ROW)
backButton.ZIndex = 21
text(settingsPanel, "Admin themes: Taco Rain and Saturday confetti.", UDim2.new(1,-20,0,24), UDim2.fromOffset(10,243), 7, C.MUTED).ZIndex = 21
local versionStatus = text(settingsPanel, "VERSION "..SCRIPT_VERSION.." • NOT CHECKED", UDim2.new(1,-20,0,22), UDim2.fromOffset(10,267), 8, C.MUTED)
versionStatus.ZIndex = 21
local function checkForUpdates()
 versionStatus.Text = "CHECKING FOR UPDATES..."
 versionStatus.TextColor3 = C.BLUE
 task.spawn(function()
  local ok, remoteVersion = pcall(function()
   return game:HttpGet(VERSION_URL)
  end)
  if not ok or type(remoteVersion) ~= "string" then
   versionStatus.Text = "UPDATE CHECK FAILED • TRY AGAIN"
   versionStatus.TextColor3 = C.MUTED
   return
  end
  remoteVersion = string.gsub(remoteVersion, "%s+", "")
  if remoteVersion == "" then
   versionStatus.Text = "VERSION SERVER EMPTY"
   versionStatus.TextColor3 = C.MUTED
  elseif remoteVersion ~= SCRIPT_VERSION then
   versionStatus.Text = "UPDATE AVAILABLE: "..remoteVersion
   versionStatus.TextColor3 = C.BLUE
  else
   versionStatus.Text = "YOU'RE UP TO DATE • "..SCRIPT_VERSION
   versionStatus.TextColor3 = C.GREEN
  end
 end)
end
local updateButton = button(settingsPanel, "CHECK FOR UPDATES", UDim2.new(1,-20,0,30), UDim2.fromOffset(10,292), checkForUpdates, C.BLUE_DARK)
updateButton.ZIndex = 21
persistenceLabel = text(settingsPanel, persistenceState, UDim2.new(1,-20,0,24), UDim2.fromOffset(10,326), 7, C.MUTED)
persistenceLabel.ZIndex = 21

-- Reopen button when minimized
local miniWasDragged = false
mini = button(gui, "❄ AS", UDim2.fromOffset(66,32), UDim2.new(0,12,.5,-16), function()
 if not miniWasDragged then
  main.Visible = true; mini.Visible = false
 end
end, C.PANEL)
mini.Visible = false; outline(mini, Color3.fromRGB(103,174,220))
mini.BackgroundColor3 = Color3.fromRGB(9,29,49)
make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(36,82,119),Color3.fromRGB(4,15,28)), Rotation = 90}, mini)
mini.TextColor3 = Color3.fromRGB(221,241,255)
local miniDragging = false
local miniDragInput
local miniStartPointer
local miniStartPos
local miniDragType
mini.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
  miniWasDragged = false
  miniDragging = true
  miniDragInput = input
  miniStartPointer = input.Position
  miniStartPos = mini.Position
  miniDragType = input.UserInputType
 end
end)
UIS.InputChanged:Connect(function(input)
 if not miniDragging then return end
 local moving = (miniDragType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
  or (miniDragType == Enum.UserInputType.Touch and input == miniDragInput)
 if moving then
  local delta = input.Position - miniStartPointer
  if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then miniWasDragged = true end
  mini.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
 end
end)
UIS.InputEnded:Connect(function(input)
 if (miniDragType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
  or (miniDragType == Enum.UserInputType.Touch and input == miniDragInput) then
  miniDragging = false
  miniDragInput = nil
  miniDragType = nil
 end
end)

-- Theme particles: seasonal effects plus raining tacos for the Admin Abuse theme.
task.spawn(function()
 while gui.Parent do
  task.wait(0.32)
  if leafLayer and leafLayer.Visible then
   local leaf = make("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromOffset(math.random(13,21), math.random(13,21)),
    Position = UDim2.new(math.random(2,98)/100, 0, 0, -24),
    Text = currentTheme == "SATURDAY" and ({"🎉","🎊","✨","💖","⭐"})[math.random(1,5)] or (currentTheme == "TACO" and "🌮" or ((currentTheme == "HALLOWEEN" or currentTheme == "THANKSGIVING") and ({"🍂","🍁","🍃"})[math.random(1,3)] or (currentTheme == "CHRISTMAS" and ({"🍬","🍭","🎄"})[math.random(1,3)] or ({"❄","❅","❆"})[math.random(1,3])))),
    TextSize = math.random(12,18), TextTransparency = 0.08,
    Rotation = math.random(-35,35), TextColor3 = currentTheme == "SATURDAY" and ({Color3.fromRGB(255, 92, 180), Color3.fromRGB(255, 213, 75), Color3.fromRGB(95, 207, 255), Color3.fromRGB(153, 255, 125), Color3.fromRGB(190, 128, 255)})[math.random(1,5)] or (currentTheme == "TACO" and ({Color3.fromRGB(237, 174, 54), Color3.fromRGB(205, 76, 43), Color3.fromRGB(86, 155, 72)})[math.random(1,3)] or (currentTheme == "HALLOWEEN" and Color3.fromRGB(255, 143, 45) or (currentTheme == "THANKSGIVING" and ({Color3.fromRGB(230, 105, 35), Color3.fromRGB(205, 55, 38), Color3.fromRGB(235, 183, 57)})[math.random(1,3)] or (currentTheme == "CHRISTMAS" and (math.random(1,2) == 1 and Color3.fromRGB(255, 65, 80) or Color3.fromRGB(70, 230, 125)) or Color3.fromRGB(170, 225, 255)))),
    Font = Enum.Font.Gotham, BorderSizePixel = 0, Active = false,
    ZIndex = 51
   }, leafLayer)
   local duration = (currentTheme == "TACO" or currentTheme == "SATURDAY") and math.random(18,30)/10 or math.random(28,48)/10
   local target = UDim2.new(math.clamp(leaf.Position.X.Scale + math.random(-12,12)/100, 0, 1), 0, 1, 22)
   local tween = TweenService:Create(leaf, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
    Position = target, Rotation = leaf.Rotation + math.random(120,300), TextTransparency = 0.18
   })
   tween:Play()
   tween.Completed:Connect(function() if leaf then leaf:Destroy() end end)
  end
 end
end)
local minimize = button(header, "—", UDim2.fromOffset(22,22), UDim2.new(1,-55,0,9), function()
 main.Visible = false; mini.Visible = true
end, C.ROW)

-- Apply the saved theme after the UI and minimized button exist.
if prefs.theme == "HALLOWEEN" or prefs.theme == "CHRISTMAS" or prefs.theme == "THANKSGIVING" or prefs.theme == "TACO" or prefs.theme == "SATURDAY" then
 applyTheme(prefs.theme)
else
 applyTheme("BLUE")
end
if persistenceLabel then persistenceLabel.Text = persistenceState end
-- Check once on launch; the Settings button can run the check again any time.
task.delay(1, function()
 if gui and gui.Parent then checkForUpdates() end
end)

print("Arctic Sniper Main Screen loaded (local UI demo) • v"..SCRIPT_VERSION)