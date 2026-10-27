--[[
ARCTIC SNIPER v2.0.0
Stable local UI rebuild. This is a UI demo: it does not read private game UI,
redeem codes, or broadcast announcements to other players.
]]
local ok, startupError = pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer
    if not player then error("LocalPlayer is unavailable. Run this in a client LocalScript context.") end
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then error("PlayerGui did not load within 10 seconds.") end
    local previous = playerGui:FindFirstChild("ArcticSniperMain")
    if previous then previous:Destroy() end

    local themes = {
        BLUE = {accent=Color3.fromRGB(80,190,255), dark=Color3.fromRGB(20,79,117), row=Color3.fromRGB(16,29,43), muted=Color3.fromRGB(126,157,181)},
        HALLOWEEN = {accent=Color3.fromRGB(255,137,43), dark=Color3.fromRGB(126,55,14), row=Color3.fromRGB(35,24,20), muted=Color3.fromRGB(190,151,122)},
        CHRISTMAS = {accent=Color3.fromRGB(70,220,125), dark=Color3.fromRGB(145,28,42), row=Color3.fromRGB(24,47,37), muted=Color3.fromRGB(155,205,170)},
        THANKSGIVING = {accent=Color3.fromRGB(220,112,38), dark=Color3.fromRGB(111,57,25), row=Color3.fromRGB(43,31,24), muted=Color3.fromRGB(205,164,120)},
        TACO = {accent=Color3.fromRGB(237,174,54), dark=Color3.fromRGB(139,76,28), row=Color3.fromRGB(48,37,22), muted=Color3.fromRGB(216,185,125)},
        SATURDAY = {accent=Color3.fromRGB(255,92,180), dark=Color3.fromRGB(117,39,101), row=Color3.fromRGB(43,25,48), muted=Color3.fromRGB(215,157,208)}
    }
    local themeName = "BLUE"
    local accent, accentDark, rowColor, muted = themes.BLUE.accent, themes.BLUE.dark, themes.BLUE.row, themes.BLUE.muted
    local bg = Color3.fromRGB(4,9,16)
    local panelColor = Color3.fromRGB(10,18,29)
    local white = Color3.fromRGB(239,248,255)
    local green = Color3.fromRGB(125,232,197)
    local runningSequence = false
    local sequenceToken = 0
    local history = {}
    local main, mini, uiScale, historyList, historyCount, sequenceStatus, sequenceStart
    local sequenceBoxes = {}
    local function make(className, props, parent)
        local obj = Instance.new(className)
        for k,v in pairs(props or {}) do obj[k] = v end
        obj.Parent = parent
        return obj
    end
    local function round(obj, radius)
        make("UICorner", {CornerRadius=UDim.new(0,radius or 8)}, obj)
    end
    local function stroke(obj, color, thickness)
        make("UIStroke", {Color=color or accent, Thickness=thickness or 1, Transparency=0.15}, obj)
    end
    local function label(parent, value, size, pos, fontSize, color, centered, font)
        return make("TextLabel", {
            BackgroundTransparency=1, Text=value or "", Size=size, Position=pos,
            Font=font or Enum.Font.Gotham, TextSize=fontSize or 10,
            TextColor3=color or white,
            TextXAlignment=centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Center, TextWrapped=true
        }, parent)
    end
    local function button(parent, value, size, pos, callback, fill)
        local b = make("TextButton", {
            Size=size, Position=pos, BackgroundColor3=fill or rowColor, BorderSizePixel=0,
            Text=value, TextColor3=white, TextSize=10, Font=Enum.Font.GothamSemibold,
            AutoButtonColor=false
        }, parent)
        round(b,7); stroke(b,accent,1)
        b.Activated:Connect(function()
            if callback then
                local success, err = pcall(callback)
                if not success then warn("[Arctic Sniper] Button error: "..tostring(err)) end
            end
        end)
        return b
    end

    local gui = make("ScreenGui", {
        Name="ArcticSniperMain", ResetOnSpawn=false, IgnoreGuiInset=true,
        DisplayOrder=9999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    }, playerGui)
    main = make("Frame", {
        Name="Main", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(340,430), BackgroundColor3=bg, BorderSizePixel=0,
        ClipsDescendants=true, Active=true
    }, gui)
    round(main,13); stroke(main,accent,1.4)
    uiScale = make("UIScale",{Scale=1},main)
    local function resize()
        local camera = workspace.CurrentCamera
        if camera then
            local v = camera.ViewportSize
            uiScale.Scale = math.clamp(math.min((v.X-18)/340,(v.Y-18)/430,1),0.55,1)
        end
    end
    resize()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end

    -- Halloween intro with a short, non-blocking progress sequence.
    local intro = make("Frame",{Name="Intro",Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0,ZIndex=100},gui)
    local introLogo = make("Frame",{Size=UDim2.fromOffset(70,70),Position=UDim2.new(0.5,-35,0.31,0),BackgroundColor3=accentDark,BorderSizePixel=0,ZIndex=101},intro)
    round(introLogo,18); stroke(introLogo,accent,2)
    label(introLogo,"A",UDim2.fromScale(1,1),UDim2.new(),40,accent,true,Enum.Font.GothamBlack).ZIndex=102
    label(intro,"ARCTIC SNIPER",UDim2.new(1,-24,0,28),UDim2.new(0,12,0.51,0),17,white,true,Enum.Font.GothamBlack).ZIndex=101
    local introStatus = label(intro,"INITIALIZING...",UDim2.new(1,-24,0,20),UDim2.new(0,12,0.58,0),8,muted,true)
    introStatus.ZIndex=101
    local progressBack = make("Frame",{Size=UDim2.new(0.66,0,0,5),Position=UDim2.new(0.17,0,0.66,0),BackgroundColor3=rowColor,BorderSizePixel=0,ZIndex=101},intro)
    round(progressBack,4)
    local progressFill = make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=accent,BorderSizePixel=0,ZIndex=102},progressBack)
    round(progressFill,4)
    local progressText = label(intro,"0%",UDim2.new(1,0,0,18),UDim2.new(0,0,0.69,0),8,accent,true)
    progressText.ZIndex=101

    -- Header and draggable main window.
    local header = make("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=panelColor,BorderSizePixel=0,Active=true},main)
    local logo = make("Frame",{Size=UDim2.fromOffset(28,28),Position=UDim2.fromOffset(9,8),BackgroundColor3=accentDark,BorderSizePixel=0},header)
    round(logo,8); stroke(logo,accent,1)
    local logoLetter = label(logo,"A",UDim2.fromScale(1,1),UDim2.new(),17,accent,true,Enum.Font.GothamBlack)
    label(header,"ARCTIC SNIPER",UDim2.new(0,160,0,18),UDim2.fromOffset(45,5),11,white,false,Enum.Font.GothamBold)
    label(header,"FROST EDITION • v2.0.0",UDim2.new(0,170,0,13),UDim2.fromOffset(45,23),7,muted)
    local closeButton = button(header,"×",UDim2.fromOffset(24,24),UDim2.new(1,-30,0,9),function() gui:Destroy() end,accentDark)
    closeButton.TextSize=16
    local minimizeButton
    local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=main.Position; dragInput=input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input==dragInput then dragging=false; dragInput=nil end
    end)

    local rail = make("Frame",{Position=UDim2.fromOffset(7,50),Size=UDim2.new(0,62,1,-57),BackgroundColor3=panelColor,BorderSizePixel=0},main)
    round(rail,9); stroke(rail,accent,1)
    label(rail,"ARCTIC",UDim2.new(1,0,0,20),UDim2.fromOffset(0,7),7,muted,true,Enum.Font.GothamBold)
    local content = make("Frame",{Position=UDim2.fromOffset(76,50),Size=UDim2.new(1,-83,1,-57),BackgroundTransparency=1},main)
    local panels = {}
    local function showPanel(name)
        for key, panel in pairs(panels) do panel.Visible=(key==name) end
    end

    local function addHistory(titleText, detailText, photoText)
        table.insert(history,1,{title=tostring(titleText),detail=tostring(detailText),time=os.date("%I:%M:%S %p"),photo=photoText or "❄"})
        while #history>50 do table.remove(history) end
        if not historyList then return end
        for _,child in ipairs(historyList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for i,item in ipairs(history) do
            local entry = make("Frame",{Size=UDim2.new(1,-8,0,53),BackgroundColor3=rowColor,BorderSizePixel=0,LayoutOrder=i},historyList)
            round(entry,6); stroke(entry,accent,1)
            label(entry,item.photo,UDim2.fromOffset(28,34),UDim2.fromOffset(5,9),19,accent,true)
            label(entry,item.title,UDim2.new(1,-43,0,15),UDim2.fromOffset(38,3),8,white,false,Enum.Font.GothamBold)
            label(entry,item.detail,UDim2.new(1,-43,0,13),UDim2.fromOffset(38,18),7,muted)
            label(entry,item.time,UDim2.new(1,-43,0,11),UDim2.fromOffset(38,34),6,accent)
        end
        historyCount.Text=tostring(#history).." ENTRIES"
    end

    local home = make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=true},content)
    panels.MAIN=home
    label(home,"ARCTIC STATUS: READY",UDim2.new(1,0,0,20),UDim2.new(),9,green,false,Enum.Font.GothamBold)
    local codeCard=make("Frame",{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,78),BackgroundColor3=panelColor,BorderSizePixel=0},home)
    round(codeCard,9); stroke(codeCard,accent,1)
    label(codeCard,"LOCAL CODE PREVIEW",UDim2.new(1,-12,0,15),UDim2.fromOffset(8,4),8,accent,false,Enum.Font.GothamBold)
    local codeInput=make("TextBox",{Size=UDim2.new(1,-16,0,26),Position=UDim2.fromOffset(8,23),BackgroundColor3=rowColor,BorderSizePixel=0,ClearTextOnFocus=false,Text="",PlaceholderText="Type a code or note...",TextColor3=white,PlaceholderColor3=muted,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},codeCard)
    round(codeInput,6); stroke(codeInput,accent,1)
    label(codeCard,"Local demo only — no redemption calls",UDim2.new(1,-16,0,15),UDim2.fromOffset(8,55),7,muted)
    button(home,"ADD TO HISTORY",UDim2.new(1,0,0,29),UDim2.fromOffset(0,112),function()
        local value=string.gsub(codeInput.Text or "","^%s*(.-)%s*$","%1")
        if value=="" then value="Manual preview entry" end
        addHistory("CODE / NOTE",value,"❄")
    end,accentDark)
    local spamEnabled = false
    local scanEnabled = false
    local scopeEnabled = false
    local hideEnabled = false
    local function previewToggle(y, titleText, subtitle, getter, setter)
        local row = make("Frame",{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,34),BackgroundColor3=rowColor,BorderSizePixel=0},home)
        round(row,7); stroke(row,accent,1)
        label(row,titleText,UDim2.new(1,-72,0,15),UDim2.fromOffset(8,3),8,white,false,Enum.Font.GothamSemibold)
        label(row,subtitle,UDim2.new(1,-72,0,11),UDim2.fromOffset(8,18),6,muted,false)
        local b
        b=button(row,"OFF",UDim2.fromOffset(45,22),UDim2.new(1,-51,0.5,-11),function()
            local nextValue=not getter()
            setter(nextValue)
            b.Text=nextValue and "ON" or "OFF"
            b.BackgroundColor3=nextValue and accentDark or rowColor
        end,rowColor)
        b.TextSize=8
        return b
    end
    previewToggle(151,"SPAM REDEEM","UI preference only — not connected",function() return spamEnabled end,function(v) spamEnabled=v end)
    previewToggle(189,"SCAN ANNOUNCEMENTS","Manual text preview only",function() return scanEnabled end,function(v) scanEnabled=v end)
    previewToggle(227,"AUTO SCOPE","Visual preference only",function() return scopeEnabled end,function(v) scopeEnabled=v end)
    previewToggle(265,"HIDE USER","Visual preference only",function() return hideEnabled end,function(v) hideEnabled=v end)
    label(home,"AUTO SUBMIT PIECES",UDim2.new(1,0,0,16),UDim2.fromOffset(0,306),7,accent,false,Enum.Font.GothamBold)
    local autoChoice=1
    for i=1,5 do
        local b=button(home,tostring(i),UDim2.new(.18,0,0,25),UDim2.new((i-1)*.2,0,0,326),function()
            autoChoice=i
            for _,child in ipairs(home:GetChildren()) do
                if child:IsA("TextButton") and child.Name=="AutoPiece"..i then child.BackgroundColor3=accentDark end
            end
        end,i==1 and accentDark or rowColor)
        b.Name="AutoPiece"..i
        b.TextSize=9
    end

    local tester = make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},content)
    panels.TESTER=tester
    round(tester,9); stroke(tester,accent,1)
    label(tester,"ANNOUNCEMENT TESTER",UDim2.new(1,-20,0,25),UDim2.fromOffset(10,7),11,white,false,Enum.Font.GothamBold)
    label(tester,"Local preview only; nothing is broadcast.",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,31),7,muted,false)
    local announceInput=make("TextBox",{Size=UDim2.new(1,-20,0,58),Position=UDim2.fromOffset(10,57),BackgroundColor3=rowColor,BorderSizePixel=0,ClearTextOnFocus=false,Text="",PlaceholderText="Type preview text...",TextColor3=white,PlaceholderColor3=muted,TextSize=9,Font=Enum.Font.Gotham,TextWrapped=true,MultiLine=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},tester)
    round(announceInput,6); stroke(announceInput,accent,1)
    local banner = label(tester,"",UDim2.new(1,-20,0,34),UDim2.fromOffset(10,120),10,white,true,Enum.Font.GothamBold)
    banner.BackgroundTransparency=0; banner.BackgroundColor3=panelColor; banner.Visible=false; round(banner,7); stroke(banner,accent,1)
    button(tester,"PREVIEW",UDim2.new(1,-20,0,28),UDim2.fromOffset(10,160),function()
        local value=string.gsub(announceInput.Text or "","^%s*(.-)%s*$","%1")
        if value=="" then value="TYPE SOMETHING FIRST" end
        banner.Text=value; banner.Visible=true; addHistory("ANNOUNCEMENT PREVIEW",value,"📣")
    end,accentDark)
    button(tester,"SEQUENCE",UDim2.new(1,-20,0,28),UDim2.fromOffset(10,195),function() showPanel("SEQUENCE") end,rowColor)

    local sequence = make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},content)
    panels.SEQUENCE=sequence
    round(sequence,9); stroke(sequence,accent,1)
    label(sequence,"SEQUENCE MODE",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,7),11,white,false,Enum.Font.GothamBold)
    label(sequence,"Up to five local preview parts • 2 seconds apart",UDim2.new(1,-20,0,25),UDim2.fromOffset(10,30),7,muted,false)
    for i=1,5 do
        local box=make("TextBox",{Name="Part"..i,Size=UDim2.new(1,-20,0,29),Position=UDim2.fromOffset(10,58+(i-1)*34),BackgroundColor3=rowColor,BorderSizePixel=0,ClearTextOnFocus=false,Text="",PlaceholderText="PART "..i,TextColor3=white,PlaceholderColor3=muted,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},sequence)
        round(box,6); stroke(box,accent,1); sequenceBoxes[i]=box
    end
    sequenceStatus=label(sequence,"READY",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,234),7,green,true)
    sequenceStart=button(sequence,"START",UDim2.new(.48,-12,0,28),UDim2.fromOffset(10,258),function()
        if runningSequence then
            runningSequence=false; sequenceToken=sequenceToken+1; sequenceStart.Text="START"; sequenceStatus.Text="STOPPED"; return
        end
        local parts={}
        for _,box in ipairs(sequenceBoxes) do
            local value=string.gsub(box.Text or "","^%s*(.-)%s*$","%1")
            if value~="" then table.insert(parts,value) end
        end
        if #parts==0 then sequenceStatus.Text="FILL AT LEAST ONE PART"; return end
        runningSequence=true; sequenceToken=sequenceToken+1
        local myToken=sequenceToken
        sequenceStart.Text="STOP"; sequenceStatus.Text="RUNNING"
        task.spawn(function()
            for i,part in ipairs(parts) do
                if not runningSequence or sequenceToken~=myToken then break end
                banner.Text=part; banner.Visible=true; sequenceStatus.Text="PART "..i.."/"..#parts
                addHistory("SEQUENCE PREVIEW",part,"📣")
                if i<#parts then task.wait(2) end
            end
            if sequenceToken==myToken then
                runningSequence=false; sequenceStart.Text="START"; sequenceStatus.Text="SEQUENCE FINISHED"
                task.delay(2,function() if banner and banner.Parent then banner.Visible=false end end)
            end
        end)
    end,accentDark)
    button(sequence,"BACK",UDim2.new(.48,-12,0,28),UDim2.new(.52,2,0,258),function()
        runningSequence=false; sequenceToken=sequenceToken+1; sequenceStart.Text="START"; sequenceStatus.Text="CANCELLED"; showPanel("TESTER")
    end,rowColor)

    local historyPanel = make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},content)
    panels.HISTORY=historyPanel
    round(historyPanel,9); stroke(historyPanel,accent,1)
    label(historyPanel,"HISTORY",UDim2.new(1,-100,0,24),UDim2.fromOffset(10,7),11,white,false,Enum.Font.GothamBold)
    historyCount=label(historyPanel,"0 ENTRIES",UDim2.fromOffset(84,20),UDim2.new(1,-94,0,9),7,accent,true)
    historyList=make("ScrollingFrame",{Position=UDim2.fromOffset(8,36),Size=UDim2.new(1,-16,1,-76),BackgroundColor3=panelColor,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},historyPanel)
    round(historyList,7); stroke(historyList,accent,1)
    make("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},historyList)
    button(historyPanel,"CLEAR",UDim2.new(.48,-12,0,27),UDim2.new(0,8,1,-34),function()
        history={}; for _,child in ipairs(historyList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        historyCount.Text="0 ENTRIES"
    end,rowColor)
    button(historyPanel,"BACK",UDim2.new(.48,-12,0,27),UDim2.new(.52,0,1,-34),function() showPanel("MAIN") end,accentDark)

    local settings = make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},content)
    panels.SETTINGS=settings
    round(settings,9); stroke(settings,accent,1)
    label(settings,"SETTINGS",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,7),11,white,false,Enum.Font.GothamBold)
    label(settings,"Choose a theme",UDim2.new(1,-20,0,20),UDim2.fromOffset(10,32),8,muted,false)
    local function applyTheme(name)
        if not themes[name] then return end
        themeName=name
        local palette=themes[name]
        accent,accentDark,rowColor,muted=palette.accent,palette.dark,palette.row,palette.muted
        for _,obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("UIStroke") then obj.Color=accent
            elseif obj:IsA("TextButton") then
                if obj.Name:sub(1,5)=="Theme" then
                    local themeKey=obj.Name:sub(6):upper()
                    obj.BackgroundColor3=(themeKey==name and accentDark or rowColor)
                end
            elseif obj:IsA("TextLabel") then
                if obj.Text=="A" or obj.Text=="ARCTIC STATUS: READY" then obj.TextColor3=(obj.Text=="A" and accent or green)
                elseif obj.Text=="FROST EDITION • v2.0.0" then obj.TextColor3=muted end
            end
        end
        logo.BackgroundColor3=accentDark; logoLetter.TextColor3=accent
        mini.BackgroundColor3=accentDark
    end
    local themeChoices={
        {"BLUE","❄ BLUE",10,60},{"HALLOWEEN","🎃 HALLOWEEN",138,60},
        {"CHRISTMAS","🎄 CHRISTMAS",10,99},{"THANKSGIVING","🦃 THANKSGIVING",138,99},
        {"TACO","🌮 TACO RAIN",10,138},{"SATURDAY","🎉 ADMIN SATURDAY",138,138}
    }
    for _,choice in ipairs(themeChoices) do
        local themeKey,labelText,x,y=choice[1],choice[2],choice[3],choice[4]
        local b=button(settings,labelText,UDim2.new(0,119,0,32),UDim2.fromOffset(x,y),function() applyTheme(themeKey) end,themeKey==themeName and accentDark or rowColor)
        b.Name="Theme"..themeKey
        b.TextSize=8
    end
    label(settings,"Theme changes update the UI colors.",UDim2.new(1,-20,0,28),UDim2.fromOffset(10,181),7,muted,false)

    local feedbackOverlay=make("TextButton",{Name="FeedbackOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.35,BorderSizePixel=0,Text="",Visible=false,AutoButtonColor=false,ZIndex=80},gui)
    local feedbackCard=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.84,0,0,174),BackgroundColor3=panelColor,BorderSizePixel=0,ZIndex=81},feedbackOverlay)
    round(feedbackCard,12); stroke(feedbackCard,accent,1.4)
    label(feedbackCard,"FEEDBACK NOTE",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,7),11,white,false,Enum.Font.GothamBold).ZIndex=82
    local feedbackInput=make("TextBox",{Size=UDim2.new(1,-20,0,76),Position=UDim2.fromOffset(10,34),BackgroundColor3=rowColor,BorderSizePixel=0,ClearTextOnFocus=false,Text="",PlaceholderText="Write a note...",TextColor3=white,PlaceholderColor3=muted,TextSize=9,Font=Enum.Font.Gotham,TextWrapped=true,MultiLine=true,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=82},feedbackCard)
    round(feedbackInput,6); stroke(feedbackInput,accent,1)
    button(feedbackCard,"CLOSE",UDim2.new(.48,-12,0,27),UDim2.fromOffset(10,130),function() feedbackOverlay.Visible=false end,rowColor).ZIndex=82
    button(feedbackCard,"SAVE NOTE",UDim2.new(.48,-12,0,27),UDim2.new(.52,2,0,130),function()
        local value=string.gsub(feedbackInput.Text or "","^%s*(.-)%s*$","%1")
        if value~="" then addHistory("FEEDBACK NOTE",value,"✎") end
        feedbackOverlay.Visible=false
    end,accentDark).ZIndex=82
    feedbackOverlay.Activated:Connect(function() feedbackOverlay.Visible=false end)

    button(rail,"MAIN",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,32),function() showPanel("MAIN") end,accentDark).TextSize=8
    button(rail,"TESTER",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,65),function() showPanel("TESTER") end,rowColor).TextSize=7
    button(rail,"HISTORY",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,98),function() showPanel("HISTORY") end,rowColor).TextSize=7
    button(rail,"SETTINGS",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,131),function() showPanel("SETTINGS") end,rowColor).TextSize=6
    button(rail,"FEEDBACK",UDim2.new(1,-8,0,28),UDim2.fromOffset(4,164),function() feedbackOverlay.Visible=true end,rowColor).TextSize=6
    label(rail,"❄",UDim2.new(1,0,0,20),UDim2.new(0,0,1,-25),12,accent,true)

    -- Floating A button, draggable and synced to the selected theme.
    local minimized=false
    mini=button(gui,"A",UDim2.fromOffset(48,48),UDim2.new(0,14,0.5,-24),function()
        if minimized then
            minimized=false; main.Visible=true
            local target=main.Position
            main.Size=UDim2.fromOffset(100,100)
            main.Position=UDim2.new(0,mini.AbsolutePosition.X+24,0,mini.AbsolutePosition.Y+24)
            main.BackgroundTransparency=1
            mini.Visible=false
            TweenService:Create(main,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(340,430),Position=target,BackgroundTransparency=0}):Play()
        end
    end,accentDark)
    mini.Visible=false; mini.TextSize=25; mini.Font=Enum.Font.GothamBlack; round(mini,14); stroke(mini,accent,1.6)
    local miniDragging, miniStart, miniPos, miniMoved=false,nil,nil,false
    mini.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            miniDragging=true; miniStart=input.Position; miniPos=mini.Position; miniMoved=false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if miniDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-miniStart
            if math.abs(delta.X)>4 or math.abs(delta.Y)>4 then miniMoved=true end
            mini.Position=UDim2.new(miniPos.X.Scale,miniPos.X.Offset+delta.X,miniPos.Y.Scale,miniPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            miniDragging=false
        end
    end)
    minimizeButton=button(header,"—",UDim2.fromOffset(22,22),UDim2.new(1,-58,0,9),function()
        if minimized then return end
        minimized=true; mini.Visible=true
        local oldPos=main.Position; local oldSize=main.Size
        local target=UDim2.new(0,mini.AbsolutePosition.X+24,0,mini.AbsolutePosition.Y+24)
        local tween=TweenService:Create(main,TweenInfo.new(0.20,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(70,70),Position=target,BackgroundTransparency=1})
        tween:Play()
        tween.Completed:Connect(function()
            if not gui.Parent then return end
            main.Visible=false; main.Size=oldSize; main.Position=oldPos; main.BackgroundTransparency=0
        end)
    end,rowColor)

    -- Animate intro after all main objects exist. A failure in the intro never blocks the UI.
    task.spawn(function()
        local stages={"LOADING UI MODULES...","SYNCING THEME...","PREPARING MAIN SCREEN...","READY"}
        for i=1,#stages do
            if not intro.Parent then return end
            introStatus.Text=stages[i]
            TweenService:Create(progressFill,TweenInfo.new(0.16),{Size=UDim2.new(i/#stages,0,1,0)}):Play()
            progressText.Text=tostring(math.floor(i/#stages*100)).."%"
            task.wait(0.18)
        end
        for _,obj in ipairs(intro:GetDescendants()) do
            if obj:IsA("TextLabel") then TweenService:Create(obj,TweenInfo.new(0.18),{TextTransparency=1}):Play()
            elseif obj:IsA("Frame") then TweenService:Create(obj,TweenInfo.new(0.18),{BackgroundTransparency=1}):Play() end
        end
        local fade=TweenService:Create(intro,TweenInfo.new(0.2),{BackgroundTransparency=1})
        fade:Play(); fade.Completed:Wait()
        if intro.Parent then intro:Destroy() end
    end)
    task.delay(2.5,function()
        if gui.Parent then print("[Arctic Sniper] v2.0.0 loaded successfully.") end
    end)
    print("[Arctic Sniper] v2.0.0 UI created.")
end)
if not ok then
    warn("[Arctic Sniper] STARTUP FAILED: "..tostring(startupError))
end
