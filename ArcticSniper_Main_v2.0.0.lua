--[[
ARCTIC SNIPER — CLEAN REBUILD
Local UI/demo only. Toggles are preferences; no game automation or code redemption is implemented.
]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
if not player then warn("[Arctic Sniper] LocalPlayer unavailable; run this from a client."); return end
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then warn("[Arctic Sniper] PlayerGui unavailable."); return end
local previous = playerGui:FindFirstChild("ArcticSniperMain")
if previous then previous:Destroy() end

local palettes = {
 BLUE={accent=Color3.fromRGB(80,190,255),dark=Color3.fromRGB(20,79,117),bg=Color3.fromRGB(5,12,22),panel=Color3.fromRGB(10,22,36),row=Color3.fromRGB(17,36,53),muted=Color3.fromRGB(140,170,190)},
 HALLOWEEN={accent=Color3.fromRGB(255,137,43),dark=Color3.fromRGB(126,55,14),bg=Color3.fromRGB(20,10,7),panel=Color3.fromRGB(34,19,13),row=Color3.fromRGB(51,29,19),muted=Color3.fromRGB(201,155,121)},
 CHRISTMAS={accent=Color3.fromRGB(70,220,125),dark=Color3.fromRGB(145,28,42),bg=Color3.fromRGB(7,17,13),panel=Color3.fromRGB(13,31,22),row=Color3.fromRGB(22,48,35),muted=Color3.fromRGB(155,205,170)},
 THANKSGIVING={accent=Color3.fromRGB(220,132,49),dark=Color3.fromRGB(111,57,25),bg=Color3.fromRGB(20,13,8),panel=Color3.fromRGB(36,24,15),row=Color3.fromRGB(53,36,23),muted=Color3.fromRGB(205,164,120)},
 TACO={accent=Color3.fromRGB(237,174,54),dark=Color3.fromRGB(139,76,28),bg=Color3.fromRGB(19,14,6),panel=Color3.fromRGB(36,27,12),row=Color3.fromRGB(54,41,19),muted=Color3.fromRGB(216,185,125)},
 SATURDAY={accent=Color3.fromRGB(255,92,180),dark=Color3.fromRGB(117,39,101),bg=Color3.fromRGB(17,8,20),panel=Color3.fromRGB(33,16,38),row=Color3.fromRGB(52,25,57),muted=Color3.fromRGB(215,157,208)}
}
local theme = "BLUE"
local P = palettes[theme]
local prefs = {spam=false,scan=false,scope=false,hide=false,auto=5}
local history = {}
local refreshHistory
local currentCode = ""
local sequenceToken = 0
local gui = Instance.new("ScreenGui")
gui.Name="ArcticSniperMain"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.DisplayOrder=9999; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=playerGui

local function create(class, props, parent)
 local obj=Instance.new(class)
 for k,v in pairs(props or {}) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local function round(obj, radius)
 create("UICorner",{CornerRadius=UDim.new(0,radius or 8)},obj)
end
local function stroke(obj, color)
 create("UIStroke",{Color=color or P.accent,Thickness=1,Transparency=.2},obj)
end
local function label(parent, textValue, size, pos, textSize, color, font)
 return create("TextLabel",{BackgroundTransparency=1,Text=textValue,Size=size,Position=pos,Font=font or Enum.Font.Gotham,TextSize=textSize or 10,TextColor3=color or Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true},parent)
end
local function button(parent, title, size, pos, callback, accent)
 local b=create("TextButton",{Text=title,Size=size,Position=pos,BackgroundColor3=accent and P.dark or P.row,TextColor3=Color3.fromRGB(240,248,255),Font=Enum.Font.GothamSemibold,TextSize=9,BorderSizePixel=0,AutoButtonColor=true},parent)
 round(b,6); stroke(b)
 b.Activated:Connect(function() if callback then callback() end end)
 return b
end
local main=create("Frame",{Name="Main",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(320,430),BackgroundColor3=P.bg,BorderSizePixel=0,Active=true},gui)
round(main,12); stroke(main)
local scale=create("UIScale",{Scale=1},main)
local function fit()
 local cam=workspace.CurrentCamera
 if cam then scale.Scale=math.clamp(math.min((cam.ViewportSize.X-16)/320,(cam.ViewportSize.Y-16)/430),.55,1) end
end
fit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
local header=create("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=P.panel,BorderSizePixel=0,Active=true},main)
round(header,10)
local logo=create("Frame",{Position=UDim2.fromOffset(9,7),Size=UDim2.fromOffset(30,30),BackgroundColor3=P.dark,BorderSizePixel=0},header)
round(logo,8); stroke(logo)
label(logo,"A",UDim2.fromScale(1,1),UDim2.new(),18,Color3.fromRGB(230,246,255),Enum.Font.GothamBlack).TextXAlignment=Enum.TextXAlignment.Center
label(header,"ARCTIC SNIPER",UDim2.fromOffset(150,18),UDim2.fromOffset(47,5),11,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
label(header,"FROST EDITION • LOCAL UI",UDim2.fromOffset(165,14),UDim2.fromOffset(47,23),7,P.muted)
local close=button(header,"×",UDim2.fromOffset(23,23),UDim2.new(1,-29,0,9),function() sequenceToken=sequenceToken+1; gui:Destroy() end,true)
close.TextSize=15
do
 local dragging=false; local startPoint; local startPos
 header.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true; startPoint=input.Position; startPos=main.Position
  end
 end)
 UIS.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local d=input.Position-startPoint
   main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
  end
 end)
 UIS.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
 end)
end
local rail=create("Frame",{Position=UDim2.fromOffset(7,51),Size=UDim2.new(0,57,1,-59),BackgroundColor3=P.panel,BorderSizePixel=0},main)
round(rail,8)
label(rail,"ARCTIC",UDim2.new(1,0,0,18),UDim2.fromOffset(0,5),7,P.muted,Enum.Font.GothamBold).TextXAlignment=Enum.TextXAlignment.Center
local content=create("Frame",{Name="Content",Position=UDim2.fromOffset(70,51),Size=UDim2.new(1,-78,1,-59),BackgroundTransparency=1},main)
local panels={}
local function newPanel(name)
 local f=create("ScrollingFrame",{Name=name,Position=UDim2.new(),Size=UDim2.fromScale(1,1),BackgroundColor3=P.bg,BorderSizePixel=0,Visible=false,ScrollBarThickness=3,ScrollBarImageColor3=P.accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y},content)
 round(f,8); panels[name]=f
 return f
end
local function showPanel(name)
 for _,p in pairs(panels) do p.Visible=false end
 if name=="MAIN" then content.Visible=true else content.Visible=true; panels[name].Visible=true end
end
button(rail,"MAIN",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,29),function() showPanel("MAIN") end,true)
button(rail,"TEST",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,61),function() showPanel("TEST") end)
button(rail,"SET",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,93),function() showPanel("SETTINGS") end)
button(rail,"HIST",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,125),function() showPanel("HISTORY"); refreshHistory() end)
button(rail,"SEQ",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,157),function() showPanel("SEQUENCE") end)
local mini
local function addHistory(code, source)
 if not code or code=="" or code=="waiting..." then return end
 table.insert(history,1,{code=tostring(code),source=source,time=os.date("%I:%M:%S %p")})
 while #history>40 do table.remove(history) end
 if panels.HISTORY then refreshHistory() end
end
-- Main panel controls
label(content,"● STATUS: READY",UDim2.new(.7,0,0,18),UDim2.fromOffset(4,2),8,Color3.fromRGB(125,232,197),Enum.Font.GothamBold)
label(content,"AUTO SUBMIT",UDim2.new(.3,0,0,18),UDim2.new(.7,0,0,2),8,P.accent,Enum.Font.GothamBold)
local codeCard=create("Frame",{Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,0,0,68),BackgroundColor3=P.panel,BorderSizePixel=0},content)
round(codeCard,8); stroke(codeCard)
label(codeCard,"SNIPED CODE / MANUAL INPUT",UDim2.new(1,-65,0,14),UDim2.fromOffset(8,3),7,P.accent,Enum.Font.GothamBold)
local codeBox=create("TextBox",{Position=UDim2.fromOffset(8,20),Size=UDim2.new(1,-76,0,25),BackgroundColor3=P.row,BorderSizePixel=0,Text="waiting...",PlaceholderText="Paste code/text here",TextColor3=Color3.fromRGB(240,248,255),PlaceholderColor3=P.muted,TextSize=10,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},codeCard)
round(codeBox,5)
button(codeCard,"RESET",UDim2.fromOffset(54,23),UDim2.new(1,-62,0,21),function() currentCode=""; codeBox.Text="waiting..." end)
codeBox.FocusLost:Connect(function() currentCode=codeBox.Text; addHistory(currentCode,"Manual input") end)
local function toggle(y,title,subtitle,key)
 local row=create("Frame",{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,35),BackgroundColor3=P.row,BorderSizePixel=0},content)
 round(row,6)
 label(row,title,UDim2.new(1,-80,0,16),UDim2.fromOffset(8,2),8,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
 label(row,subtitle,UDim2.new(1,-80,0,12),UDim2.fromOffset(8,19),6,P.muted)
 local b
 b=button(row,prefs[key] and "ON" or "OFF",UDim2.fromOffset(47,23),UDim2.new(1,-55,.5,-11),function()
  prefs[key]=not prefs[key]; b.Text=prefs[key] and "ON" or "OFF"; b.BackgroundColor3=prefs[key] and P.dark or P.bg
 end,prefs[key])
 b.BackgroundColor3=prefs[key] and P.dark or P.bg
end
toggle(98,"SPAM REDEEM","Preference toggle only","spam")
toggle(138,"SCAN ANNOUNCEMENTS","Scan text you paste below","scan")
toggle(178,"AUTO SCOPE","Preference toggle only","scope")
toggle(218,"HIDE USER","Preference toggle only","hide")
local autoRow=create("Frame",{Position=UDim2.fromOffset(0,258),Size=UDim2.new(1,0,0,38),BackgroundColor3=P.row,BorderSizePixel=0},content)
round(autoRow,6)
label(autoRow,"AUTO SUBMIT PIECES",UDim2.new(1,-95,1,0),UDim2.fromOffset(8,0),8,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
local autoValue=label(autoRow,tostring(prefs.auto),UDim2.fromOffset(25,28),UDim2.new(1,-31,.5,-14),12,P.accent,Enum.Font.GothamBold)
autoValue.TextXAlignment=Enum.TextXAlignment.Center
button(autoRow,"−",UDim2.fromOffset(25,25),UDim2.new(1,-88,.5,-12),function() prefs.auto=math.max(1,prefs.auto-1); autoValue.Text=tostring(prefs.auto) end)
button(autoRow,"+",UDim2.fromOffset(25,25),UDim2.new(1,-59,.5,-12),function() prefs.auto=math.min(5,prefs.auto+1); autoValue.Text=tostring(prefs.auto) end)
local scanBox=create("TextBox",{Position=UDim2.fromOffset(0,302),Size=UDim2.new(1,0,0,48),BackgroundColor3=P.panel,BorderSizePixel=0,Text="",PlaceholderText="Paste announcement fragments here…",TextColor3=Color3.fromRGB(240,248,255),PlaceholderColor3=P.muted,TextSize=9,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},content)
round(scanBox,7); stroke(scanBox)
button(content,"SCAN PASTED TEXT",UDim2.new(1,0,0,29),UDim2.fromOffset(0,355),function()
 if not prefs.scan then
  scanBox.PlaceholderText="Turn SCAN ANNOUNCEMENTS ON first"; return
 end
 local raw=scanBox.Text
 if raw=="" then scanBox.PlaceholderText="Paste text first"; return end
 currentCode=raw; codeBox.Text=raw; addHistory(raw,"Scanned text")
 scanBox.PlaceholderText="Scanned locally • no game connection"
end,true)
-- Tester panel
local tester=newPanel("TEST")
label(tester,"ANNOUNCEMENT TESTER",UDim2.new(1,-12,0,25),UDim2.fromOffset(7,5),12,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
label(tester,"Local banner preview only",UDim2.new(1,-12,0,22),UDim2.fromOffset(7,30),8,P.muted)
local testInput=create("TextBox",{Position=UDim2.fromOffset(7,58),Size=UDim2.new(1,-14,0,65),BackgroundColor3=P.row,BorderSizePixel=0,Text="",PlaceholderText="Type a test announcement…",TextColor3=Color3.fromRGB(240,248,255),PlaceholderColor3=P.muted,TextSize=10,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},tester)
round(testInput,6)
local banner=create("TextLabel",{Position=UDim2.fromOffset(7,133),Size=UDim2.new(1,-14,0,64),BackgroundColor3=P.dark,BorderSizePixel=0,Text="",TextColor3=Color3.fromRGB(255,255,255),TextSize=12,Font=Enum.Font.GothamBold,TextWrapped=true,Visible=false},tester)
round(banner,8); stroke(banner)
button(tester,"SHOW PREVIEW",UDim2.new(.49,0,0,30),UDim2.fromOffset(7,205),function() banner.Text=testInput.Text; banner.Visible=testInput.Text~="" end,true)
button(tester,"HIDE PREVIEW",UDim2.new(.49,0,0,30),UDim2.new(.51,-2,0,205),function() banner.Visible=false end)
-- History panel
local historyPanel=newPanel("HISTORY")
label(historyPanel,"HISTORY",UDim2.new(1,-12,0,25),UDim2.fromOffset(7,5),12,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
label(historyPanel,"Newest first • current session • up to 40 entries",UDim2.new(1,-12,0,22),UDim2.fromOffset(7,30),7,P.muted)
local historyList=create("Frame",{Position=UDim2.fromOffset(7,57),Size=UDim2.new(1,-14,0,285),BackgroundTransparency=1},historyPanel)
refreshHistory=function()
 if not historyList or not historyList.Parent then return end
 for _,c in ipairs(historyList:GetChildren()) do c:Destroy() end
 for i,item in ipairs(history) do
  if i>8 then break end
  local e=create("Frame",{Position=UDim2.fromOffset(0,(i-1)*35),Size=UDim2.new(1,0,0,31),BackgroundColor3=P.row,BorderSizePixel=0},historyList)
  round(e,5)
  label(e,item.code,UDim2.new(1,-8,0,17),UDim2.fromOffset(5,1),8,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
  label(e,item.source.." • "..item.time,UDim2.new(1,-8,0,11),UDim2.fromOffset(5,18),6,P.muted)
 end
end
button(historyPanel,"CLEAR HISTORY",UDim2.new(.49,0,0,29),UDim2.fromOffset(7,350),function() table.clear(history); refreshHistory() end)
button(historyPanel,"BACK",UDim2.new(.49,0,0,29),UDim2.new(.51,-2,0,350),function() showPanel("MAIN") end,true)
-- Sequence panel
local seqPanel=newPanel("SEQUENCE")
label(seqPanel,"SEQUENCE MODE",UDim2.new(1,-12,0,25),UDim2.fromOffset(7,5),12,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
label(seqPanel,"Up to five parts • two seconds apart • local preview",UDim2.new(1,-12,0,22),UDim2.fromOffset(7,30),7,P.muted)
local seqBoxes={}
for i=1,5 do
 label(seqPanel,"PART "..i,UDim2.fromOffset(44,27),UDim2.fromOffset(7,58+(i-1)*39),7,P.accent,Enum.Font.GothamBold)
 local box=create("TextBox",{Position=UDim2.fromOffset(52,58+(i-1)*39),Size=UDim2.new(1,-59,0,27),BackgroundColor3=P.row,BorderSizePixel=0,Text="",PlaceholderText="Optional part "..i,TextColor3=Color3.fromRGB(240,248,255),PlaceholderColor3=P.muted,TextSize=8,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},seqPanel)
 round(box,5); table.insert(seqBoxes,box)
end
local seqStatus=label(seqPanel,"READY • LOCAL PREVIEW ONLY",UDim2.new(1,-14,0,22),UDim2.fromOffset(7,258),7,Color3.fromRGB(125,232,197),Enum.Font.GothamBold)
local seqPreview=create("TextLabel",{Position=UDim2.fromOffset(7,283),Size=UDim2.new(1,-14,0,48),BackgroundColor3=P.dark,BorderSizePixel=0,Text="",TextColor3=Color3.new(1,1,1),TextSize=10,Font=Enum.Font.GothamBold,TextWrapped=true,Visible=false},seqPanel)
round(seqPreview,7)
button(seqPanel,"START",UDim2.new(.32,0,0,29),UDim2.fromOffset(7,340),function()
 sequenceToken=sequenceToken+1; local token=sequenceToken; local parts={}
 for _,box in ipairs(seqBoxes) do local s=string.gsub(box.Text,"^%s*(.-)%s*$","%1"); if s~="" then table.insert(parts,s) end end
 if #parts==0 then seqStatus.Text="ENTER AT LEAST ONE PART"; return end
 task.spawn(function()
  for i,s in ipairs(parts) do
   if token~=sequenceToken or not gui.Parent then return end
   seqPreview.Text=s; seqPreview.Visible=true; seqStatus.Text="SHOWING PART "..i.." / "..#parts
   task.wait(2)
  end
  if token==sequenceToken then seqPreview.Visible=false; seqStatus.Text="SEQUENCE COMPLETE" end
 end)
end,true)
button(seqPanel,"STOP",UDim2.new(.32,0,0,29),UDim2.new(.34,0,0,340),function() sequenceToken=sequenceToken+1; seqPreview.Visible=false; seqStatus.Text="SEQUENCE STOPPED" end)
button(seqPanel,"BACK",UDim2.new(.32,0,0,29),UDim2.new(.68,-2,0,340),function() sequenceToken=sequenceToken+1; seqPreview.Visible=false; showPanel("MAIN") end)
-- Settings / six themes
local settings=newPanel("SETTINGS")
label(settings,"SETTINGS & THEMES",UDim2.new(1,-12,0,25),UDim2.fromOffset(7,5),12,Color3.fromRGB(240,248,255),Enum.Font.GothamBold)
label(settings,"Choose a theme",UDim2.new(1,-12,0,20),UDim2.fromOffset(7,30),8,P.muted)
local themeButtons={}
local themeInfo={{"BLUE","❄ BLUE"},{"HALLOWEEN","🎃 HALLOWEEN"},{"CHRISTMAS","🎄 CHRISTMAS"},{"THANKSGIVING","🦃 THANKSGIVING"},{"TACO","🌮 TACO RAIN"},{"SATURDAY","🎉 ADMIN SATURDAY"}}
local function applyTheme(name)
 theme=palettes[name] and name or "BLUE"; P=palettes[theme]
 main.BackgroundColor3=P.bg; header.BackgroundColor3=P.panel; rail.BackgroundColor3=P.panel; content.BackgroundColor3=P.bg
 for _,obj in ipairs(gui:GetDescendants()) do
  if obj:IsA("TextLabel") and obj.TextColor3~=Color3.fromRGB(240,248,255) and obj.TextColor3~=Color3.new(1,1,1) then obj.TextColor3=P.muted end
  if obj:IsA("UIStroke") then obj.Color=P.accent end
 end
 for name2,b in pairs(themeButtons) do b.BackgroundColor3=(name2==theme) and P.dark or P.row end
end
for i,item in ipairs(themeInfo) do
 local col=(i-1)%2; local row=math.floor((i-1)/2)
 local b=button(settings,item[2],UDim2.new(.5,-11,0,37),UDim2.new(col*.5,7,0,57+row*45),function() applyTheme(item[1]) end,i==1)
 b.TextSize=8; themeButtons[item[1]]=b
end
label(settings,"SPAM REDEEM / AUTO SCOPE / HIDE USER are UI preferences only.",UDim2.new(1,-14,0,40),UDim2.fromOffset(7,202),7,P.muted)
label(settings,"This build does not redeem codes or automate another game.",UDim2.new(1,-14,0,35),UDim2.fromOffset(7,242),7,P.muted)
button(settings,"BACK TO MAIN",UDim2.new(1,-14,0,30),UDim2.fromOffset(7,285),function() showPanel("MAIN") end,true)
-- Draggable floating reopen button
mini=button(gui,"❄ AS",UDim2.fromOffset(66,32),UDim2.new(0,12,.5,-16),function() main.Visible=true; mini.Visible=false end,true)
mini.Visible=false
local miniDrag=false; local miniStart; local miniPos
mini.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then miniDrag=true; miniStart=input.Position; miniPos=mini.Position end
end)
UIS.InputChanged:Connect(function(input)
 if miniDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local d=input.Position-miniStart
  mini.Position=UDim2.new(miniPos.X.Scale,miniPos.X.Offset+d.X,miniPos.Y.Scale,miniPos.Y.Offset+d.Y)
 end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then miniDrag=false end end)
button(header,"—",UDim2.fromOffset(22,22),UDim2.new(1,-55,0,9),function() main.Visible=false; mini.Visible=true end)
showPanel("MAIN")
print("[Arctic Sniper] Clean rebuild loaded • v2.1.0")
