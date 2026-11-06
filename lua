-- NemoHub Loader | looping loading bar edition
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
    Name = "NEMOHUB",
    Tagline = "PREMIUM SCRIPT HUB",
    Version = "v1.0",
    DiscordInvite = "HOPE U ARE GOOD!", -- <- put your real invite here
    CycleTime = 4,            -- seconds for the bar to go 0 -> 100%
    HideCoreGui = true,
    Accent = Color3.fromRGB(0, 220, 255),   -- cyan
    Accent2 = Color3.fromRGB(150, 70, 255), -- violet
    Accent3 = Color3.fromRGB(255, 70, 190), -- pink
}

local localPlayer = Players.LocalPlayer
local connections = {}
local destroyed = false

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function gradient(inst, points, rotation)
    local g = Instance.new("UIGradient")
    local seq = {}
    for _, p in ipairs(points) do
        table.insert(seq, ColorSequenceKeypoint.new(p[1], p[2]))
    end
    g.Color = ColorSequence.new(seq)
    g.Rotation = rotation or 0
    g.Parent = inst
    return g
end

local function getParent()
    local ok, ui = pcall(function()
        if gethui then return gethui() end
    end)
    if ok and ui then return ui end
    local ok2 = pcall(function() return CoreGui.Name end)
    if ok2 then return CoreGui end
    return localPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------
-- BUILD UI
----------------------------------------------------------------
local function build()
    local parent = getParent()

    pcall(function()
        local old = parent:FindFirstChild("NemoHubLoader")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "NemoHubLoader"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 99999999
    gui.Parent = parent

    -- Background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(4, 5, 12)
    bg.BorderSizePixel = 0
    bg.BackgroundTransparency = 1
    bg.Parent = gui
    local bgGrad = gradient(bg, {
        {0, Color3.fromRGB(8, 10, 26)},
        {0.5, Color3.fromRGB(10, 6, 24)},
        {1, Color3.fromRGB(3, 4, 10)},
    }, 120)

    -- Floating particles
    local particles = {}
    local particleLayer = Instance.new("Frame")
    particleLayer.Size = UDim2.fromScale(1, 1)
    particleLayer.BackgroundTransparency = 1
    particleLayer.ZIndex = 1
    particleLayer.Parent = bg

    local palette = {CONFIG.Accent, CONFIG.Accent2, CONFIG.Accent3}
    for i = 1, 38 do
        local size = math.random(2, 5)
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(size, size)
        p.Position = UDim2.fromScale(math.random(), math.random())
        p.BackgroundColor3 = palette[math.random(1, #palette)]
        p.BackgroundTransparency = math.random(45, 85) / 100
        p.BorderSizePixel = 0
        p.ZIndex = 1
        p.Parent = particleLayer
        corner(p, 10)
        table.insert(particles, {
            frame = p,
            speed = math.random(15, 55) / 1000,
            drift = (math.random() - 0.5) * 0.01,
            x = p.Position.X.Scale,
            y = p.Position.Y.Scale,
        })
    end

    -- Scanline
    local scan = Instance.new("Frame")
    scan.Size = UDim2.new(1, 0, 0, 2)
    scan.BackgroundColor3 = CONFIG.Accent
    scan.BackgroundTransparency = 0.88
    scan.BorderSizePixel = 0
    scan.ZIndex = 2
    scan.Parent = bg

    -- Glow behind dialog
    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.fromScale(0.5, 0.5)
    glow.Size = UDim2.fromOffset(520, 280)
    glow.BackgroundColor3 = CONFIG.Accent2
    glow.BackgroundTransparency = 0.88
    glow.BorderSizePixel = 0
    glow.ZIndex = 2
    glow.Parent = bg
    corner(glow, 40)

    -- Dialog
    local dialogSize = UDim2.fromOffset(460, 250)
    local dialog = Instance.new("Frame")
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.Position = UDim2.fromScale(0.5, 0.5)
    dialog.Size = UDim2.fromOffset(0, 0)
    dialog.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
    dialog.BorderSizePixel = 0
    dialog.ClipsDescendants = true
    dialog.ZIndex = 3
    dialog.Parent = bg
    corner(dialog, 18)
    gradient(dialog, {
        {0, Color3.fromRGB(18, 16, 38)},
        {1, Color3.fromRGB(7, 6, 16)},
    }, 145)

    local dialogStroke = stroke(dialog, CONFIG.Accent, 1.5, 0.15)
    local dialogStrokeGrad = gradient(dialogStroke, {
        {0, CONFIG.Accent},
        {0.5, CONFIG.Accent2},
        {1, CONFIG.Accent3},
    }, 0)

    -- Top accent bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.BorderSizePixel = 0
    topBar.BackgroundColor3 = Color3.new(1, 1, 1)
    topBar.ZIndex = 5
    topBar.Parent = dialog
    local topBarGrad = gradient(topBar, {
        {0, CONFIG.Accent},
        {0.5, CONFIG.Accent2},
        {1, CONFIG.Accent3},
    }, 0)

    -- Logo (two counter-rotating rings + core)
    local logo = Instance.new("Frame")
    logo.Size = UDim2.fromOffset(52, 52)
    logo.Position = UDim2.fromOffset(24, 24)
    logo.BackgroundTransparency = 1
    logo.ZIndex = 4
    logo.Parent = dialog

    local ringOuter = Instance.new("Frame")
    ringOuter.Size = UDim2.fromScale(1, 1)
    ringOuter.BackgroundTransparency = 1
    ringOuter.ZIndex = 4
    ringOuter.Parent = logo
    corner(ringOuter, 100)
    local ringOuterStroke = stroke(ringOuter, Color3.new(1, 1, 1), 3, 0)
    local ringOuterGrad = gradient(ringOuterStroke, {
        {0, CONFIG.Accent},
        {0.5, Color3.fromRGB(20, 20, 50)},
        {1, CONFIG.Accent3},
    }, 0)

    local ringInner = Instance.new("Frame")
    ringInner.AnchorPoint = Vector2.new(0.5, 0.5)
    ringInner.Position = UDim2.fromScale(0.5, 0.5)
    ringInner.Size = UDim2.fromScale(0.64, 0.64)
    ringInner.BackgroundTransparency = 1
    ringInner.ZIndex = 4
    ringInner.Parent = logo
    corner(ringInner, 100)
    local ringInnerStroke = stroke(ringInner, Color3.new(1, 1, 1), 2, 0.1)
    local ringInnerGrad = gradient(ringInnerStroke, {
        {0, CONFIG.Accent3},
        {0.5, Color3.fromRGB(20, 20, 50)},
        {1, CONFIG.Accent2},
    }, 0)

    local core = Instance.new("Frame")
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.5)
    core.Size = UDim2.fromOffset(10, 10)
    core.BackgroundColor3 = Color3.fromRGB(235, 250, 255)
    core.BorderSizePixel = 0
    core.ZIndex = 5
    core.Parent = logo
    corner(core, 10)

    -- Title with gradient text
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(220, 28)
    title.Position = UDim2.fromOffset(92, 22)
    title.BackgroundTransparency = 1
    title.Text = CONFIG.Name
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 26
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 4
    title.Parent = dialog
    local titleGrad = gradient(title, {
        {0, Color3.fromRGB(255, 255, 255)},
        {0.5, CONFIG.Accent},
        {1, CONFIG.Accent2},
    }, 0)

    local tagline = Instance.new("TextLabel")
    tagline.Size = UDim2.fromOffset(220, 14)
    tagline.Position = UDim2.fromOffset(93, 52)
    tagline.BackgroundTransparency = 1
    tagline.Text = CONFIG.Tagline
    tagline.Font = Enum.Font.GothamBold
    tagline.TextSize = 10
    tagline.TextColor3 = Color3.fromRGB(130, 140, 190)
    tagline.TextXAlignment = Enum.TextXAlignment.Left
    tagline.ZIndex = 4
    tagline.Parent = dialog

    -- Version pill
    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(46, 18)
    pill.AnchorPoint = Vector2.new(1, 0)
    pill.Position = UDim2.new(0, 0, 0, 0) -- set after avatar
    pill.BackgroundColor3 = Color3.fromRGB(26, 22, 56)
    pill.BorderSizePixel = 0
    pill.ZIndex = 4
    pill.Parent = dialog
    corner(pill, 9)
    stroke(pill, CONFIG.Accent2, 1, 0.5)
    local pillText = Instance.new("TextLabel")
    pillText.Size = UDim2.fromScale(1, 1)
    pillText.BackgroundTransparency = 1
    pillText.Text = CONFIG.Version
    pillText.Font = Enum.Font.GothamBold
    pillText.TextSize = 10
    pillText.TextColor3 = Color3.fromRGB(200, 185, 255)
    pillText.ZIndex = 5
    pillText.Parent = pill

    -- Avatar
    local avatar = Instance.new("Frame")
    avatar.Size = UDim2.fromOffset(58, 58)
    avatar.AnchorPoint = Vector2.new(1, 0)
    avatar.Position = UDim2.new(1, -24, 0, 20)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 4
    avatar.Parent = dialog
    pill.Position = UDim2.new(1, -96, 0, 26)

    local avatarRing = Instance.new("Frame")
    avatarRing.Size = UDim2.fromScale(1, 1)
    avatarRing.BackgroundTransparency = 1
    avatarRing.ZIndex = 4
    avatarRing.Parent = avatar
    corner(avatarRing, 100)
    local avatarStroke = stroke(avatarRing, Color3.new(1, 1, 1), 3, 0)
    local avatarGrad = gradient(avatarStroke, {
        {0, CONFIG.Accent},
        {0.5, CONFIG.Accent2},
        {1, CONFIG.Accent3},
    }, 0)

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
    avatarImg.Position = UDim2.fromScale(0.5, 0.5)
    avatarImg.Size = UDim2.fromScale(0.8, 0.8)
    avatarImg.BackgroundColor3 = Color3.fromRGB(16, 14, 34)
    avatarImg.ScaleType = Enum.ScaleType.Crop
    avatarImg.ZIndex = 5
    avatarImg.Parent = avatar
    corner(avatarImg, 100)

    task.spawn(function()
        pcall(function()
            avatarImg.Image = Players:GetUserThumbnailAsync(
                localPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
    end)

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -48, 0, 1)
    divider.Position = UDim2.fromOffset(24, 92)
    divider.BorderSizePixel = 0
    divider.BackgroundColor3 = Color3.new(1, 1, 1)
    divider.BackgroundTransparency = 0.7
    divider.ZIndex = 4
    divider.Parent = dialog
    gradient(divider, {
        {0, Color3.fromRGB(20, 20, 50)},
        {0.5, CONFIG.Accent2},
        {1, Color3.fromRGB(20, 20, 50)},
    }, 0)

    -- Status text + percent
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -140, 0, 20)
    status.Position = UDim2.fromOffset(24, 108)
    status.BackgroundTransparency = 1
    status.Text = "Starting up"
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(170, 180, 225)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 4
    status.Parent = dialog

    local percent = Instance.new("TextLabel")
    percent.Size = UDim2.fromOffset(90, 24)
    percent.AnchorPoint = Vector2.new(1, 0)
    percent.Position = UDim2.new(1, -24, 0, 106)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.Font = Enum.Font.GothamBlack
    percent.TextSize = 20
    percent.TextColor3 = Color3.new(1, 1, 1)
    percent.TextXAlignment = Enum.TextXAlignment.Right
    percent.ZIndex = 4
    percent.Parent = dialog
    gradient(percent, {
        {0, CONFIG.Accent},
        {1, CONFIG.Accent3},
    }, 0)

    -- Loading bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -48, 0, 12)
    barBg.Position = UDim2.fromOffset(24, 140)
    barBg.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
    barBg.BorderSizePixel = 0
    barBg.ClipsDescendants = true
    barBg.ZIndex = 4
    barBg.Parent = dialog
    corner(barBg, 6)
    stroke(barBg, CONFIG.Accent2, 1, 0.65)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = barBg
    corner(fill, 6)
    local fillGrad = gradient(fill, {
        {0, CONFIG.Accent},
        {0.5, CONFIG.Accent2},
        {1, CONFIG.Accent3},
    }, 0)

    -- Shine sweeping across the fill
    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(0, 50, 1, 0)
    shine.Position = UDim2.new(-0.3, 0, 0, 0)
    shine.BackgroundColor3 = Color3.new(1, 1, 1)
    shine.BackgroundTransparency = 0.55
    shine.BorderSizePixel = 0
    shine.Rotation = 0
    shine.ZIndex = 6
    shine.Parent = fill
    gradient(shine, {
        {0, Color3.new(1, 1, 1)},
        {0.5, Color3.new(1, 1, 1)},
        {1, Color3.new(1, 1, 1)},
    }, 0).Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })

    -- Glowing head at the tip of the bar
    local head = Instance.new("Frame")
    head.AnchorPoint = Vector2.new(0.5, 0.5)
    head.Size = UDim2.fromOffset(14, 14)
    head.Position = UDim2.new(0, 0, 0.5, 0)
    head.BackgroundColor3 = Color3.new(1, 1, 1)
    head.BackgroundTransparency = 0.2
    head.BorderSizePixel = 0
    head.ZIndex = 7
    head.Parent = barBg
    corner(head, 14)

    -- Segment ticks over the bar
    for i = 1, 9 do
        local tick = Instance.new("Frame")
        tick.Size = UDim2.new(0, 1, 1, 0)
        tick.Position = UDim2.fromScale(i / 10, 0)
        tick.BackgroundColor3 = Color3.fromRGB(4, 5, 12)
        tick.BackgroundTransparency = 0.35
        tick.BorderSizePixel = 0
        tick.ZIndex = 8
        tick.Parent = barBg
    end

    -- Bouncing dots
    local dots = {}
    for i = 1, 3 do
        local d = Instance.new("Frame")
        d.Size = UDim2.fromOffset(6, 6)
        d.AnchorPoint = Vector2.new(0.5, 0.5)
        d.Position = UDim2.new(0.5, (i - 2) * 14, 0, 176)
        d.BackgroundColor3 = CONFIG.Accent
        d.BorderSizePixel = 0
        d.ZIndex = 4
        d.Parent = dialog
        corner(d, 6)
        dots[i] = d
    end

    -- Discord footer
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, -48, 0, 34)
    footer.Position = UDim2.new(0, 24, 1, -48)
    footer.BackgroundColor3 = Color3.fromRGB(14, 13, 32)
    footer.BackgroundTransparency = 1
    footer.BorderSizePixel = 0
    footer.ZIndex = 4
    footer.Parent = dialog
    corner(footer, 10)
    local footerStroke = stroke(footer, CONFIG.Accent2, 1, 1)

    local footerText = Instance.new("TextLabel")
    footerText.Size = UDim2.new(1, -90, 1, 0)
    footerText.Position = UDim2.fromOffset(14, 0)
    footerText.BackgroundTransparency = 1
    footerText.Text = "Join NemoHub  •  " .. CONFIG.DiscordInvite
    footerText.Font = Enum.Font.GothamMedium
    footerText.TextSize = 12
    footerText.TextColor3 = Color3.fromRGB(150, 220, 255)
    footerText.TextXAlignment = Enum.TextXAlignment.Left
    footerText.TextTransparency = 1
    footerText.ZIndex = 5
    footerText.Parent = footer

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.fromOffset(64, 22)
    copyBtn.AnchorPoint = Vector2.new(1, 0.5)
    copyBtn.Position = UDim2.new(1, -8, 0.5, 0)
    copyBtn.BackgroundColor3 = CONFIG.Accent2
    copyBtn.BackgroundTransparency = 1
    copyBtn.Text = "COPY"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 11
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.TextTransparency = 1
    copyBtn.AutoButtonColor = false
    copyBtn.BorderSizePixel = 0
    copyBtn.ZIndex = 5
    copyBtn.Parent = footer
    corner(copyBtn, 7)

    copyBtn.MouseEnter:Connect(function()
        TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.Accent}):Play()
    end)
    copyBtn.MouseLeave:Connect(function()
        TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.Accent2}):Play()
    end)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard("https://" .. CONFIG.DiscordInvite) end
        end)
        copyBtn.Text = "COPIED"
        task.delay(1.5, function()
            if copyBtn and copyBtn.Parent then copyBtn.Text = "COPY" end
        end)
    end)

    ----------------------------------------------------------------
    -- INTRO ANIMATION
    ----------------------------------------------------------------
    TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
    TweenService:Create(dialog, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = dialogSize,
    }):Play()

    task.delay(1.2, function()
        if destroyed then return end
        local ti = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(footer, ti, {BackgroundTransparency = 0}):Play()
        TweenService:Create(footerStroke, ti, {Transparency = 0.5}):Play()
        TweenService:Create(footerText, ti, {TextTransparency = 0}):Play()
        TweenService:Create(copyBtn, ti, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    end)

    ----------------------------------------------------------------
    -- LOOPING ANIMATION
    ----------------------------------------------------------------
    local statuses = {
        {0.00, "Starting up"},
        {0.20, "Loading modules"},
        {0.42, "Preparing interface"},
        {0.64, "Syncing configuration"},
        {0.84, "Almost there"},
        {0.97, "Ready"},
    }

    local startClock = os.clock()
    local lastCycle = 0
    local lastStatus = ""

    local function easeInOut(t)
        return t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2) ^ 2) / 2
    end

    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if destroyed then return end
        local now = os.clock()
        local elapsed = now - startClock

        -- Loop progress
        local cycleFloat = elapsed / CONFIG.CycleTime
        local cycle = math.floor(cycleFloat)
        local t = cycleFloat - cycle
        local alpha = easeInOut(t)

        if cycle ~= lastCycle then
            lastCycle = cycle
            -- flash on loop
            local flash = Instance.new("Frame")
            flash.Size = UDim2.fromScale(1, 1)
            flash.BackgroundColor3 = CONFIG.Accent
            flash.BackgroundTransparency = 0.8
            flash.BorderSizePixel = 0
            flash.ZIndex = 9
            flash.Parent = dialog
            local tw = TweenService:Create(flash, TweenInfo.new(0.45), {BackgroundTransparency = 1})
            tw.Completed:Connect(function() flash:Destroy() end)
            tw:Play()
        end

        fill.Size = UDim2.fromScale(alpha, 1)
        head.Position = UDim2.new(alpha, 0, 0.5, 0)
        percent.Text = string.format("%d%%", math.floor(alpha * 100))

        -- Status text
        local current = statuses[1][2]
        for _, s in ipairs(statuses) do
            if alpha >= s[1] then current = s[2] end
        end
        if current ~= lastStatus then
            lastStatus = current
            status.Text = current
        end

        -- Shine sweep (repeats ~ 3x per cycle)
        local sweep = (elapsed * 0.9) % 1
        shine.Position = UDim2.new(sweep * 1.6 - 0.3, 0, 0, 0)

        -- Animated gradients
        local spin = (elapsed * 90) % 360
        dialogStrokeGrad.Rotation = spin
        avatarGrad.Rotation = spin
        ringOuterGrad.Rotation = spin
        ringInnerGrad.Rotation = -spin * 1.6
        titleGrad.Offset = Vector2.new(math.sin(elapsed * 1.4) * 0.35, 0)
        topBarGrad.Offset = Vector2.new(math.sin(elapsed * 1.1) * 0.5, 0)
        fillGrad.Offset = Vector2.new(math.sin(elapsed * 2) * 0.25, 0)
        bgGrad.Rotation = 120 + math.sin(elapsed * 0.4) * 25

        -- Pulse the core + glow
        local pulse = (math.sin(elapsed * 3) + 1) / 2
        core.Size = UDim2.fromOffset(8 + pulse * 6, 8 + pulse * 6)
        glow.BackgroundTransparency = 0.84 + pulse * 0.08

        -- Bouncing dots
        for i, d in ipairs(dots) do
            local off = math.sin(elapsed * 6 - i * 0.7)
            d.Position = UDim2.new(0.5, (i - 2) * 14, 0, 176 + off * 4)
            d.BackgroundTransparency = 0.5 - off * 0.4
        end

        -- Scanline
        scan.Position = UDim2.new(0, 0, (elapsed / 4.5) % 1, 0)

        -- Particles
        for _, p in ipairs(particles) do
            p.y = p.y - p.speed * dt
            p.x = p.x + p.drift * dt
            if p.y < -0.02 then
                p.y = 1.02
                p.x = math.random()
            end
            p.frame.Position = UDim2.fromScale(p.x, p.y)
        end
    end))

    return gui
end

----------------------------------------------------------------
-- LIFECYCLE
----------------------------------------------------------------
if CONFIG.HideCoreGui then
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)
end

local loaderGui = build()

-- Call this from your script when you want the loader gone:
--   getgenv().NemoHubCloseLoader()
local function close()
    if destroyed then return end
    destroyed = true
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    if loaderGui then
        pcall(function() loaderGui:Destroy() end)
    end
    if CONFIG.HideCoreGui then
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
    end
end

pcall(function()
    getgenv().NemoHubCloseLoader = close
end)

-- The loader (and the loop) keeps running until close() is called
while not destroyed and loaderGui and loaderGui.Parent do
    task.wait(1)
end
