

local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer

-- ── Colour palette ──────────────────────────────────────────
local C = {
    bg          = Color3.fromRGB(18, 18, 22),
    panel       = Color3.fromRGB(24, 24, 30),
    section     = Color3.fromRGB(30, 30, 38),
    border      = Color3.fromRGB(55, 45, 70),
    accent      = Color3.fromRGB(210, 120, 230),
    accentDark  = Color3.fromRGB(140, 70, 160),
    accentFill  = Color3.fromRGB(180, 90, 200),
    text        = Color3.fromRGB(230, 220, 240),
    textDim     = Color3.fromRGB(140, 130, 155),
    toggle_off  = Color3.fromRGB(55, 50, 65),
    toggle_on   = Color3.fromRGB(210, 120, 230),
    slider_bg   = Color3.fromRGB(45, 40, 58),
    notif_bg    = Color3.fromRGB(28, 24, 36),
    notif_brd   = Color3.fromRGB(180, 90, 200),
    white       = Color3.fromRGB(255, 255, 255),
    black       = Color3.fromRGB(0, 0, 0),
}

-- ── Font helper (Juca via id, fallback GothamBold) ──────────
local FONT_REGULAR = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular)
local FONT_BOLD    = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
local FONT_SEMI    = Font.new("rbxassetid://12187371840", Enum.FontWeight.SemiBold)

-- ── Tween helper ────────────────────────────────────────────
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint), props):Play()
end

-- ── Utility: make rounded frame ─────────────────────────────
local function mkFrame(props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.bg or C.panel
    f.BorderSizePixel  = 0
    f.Size             = props.size or UDim2.new(1, 0, 0, 30)
    f.Position         = props.pos or UDim2.new(0,0,0,0)
    if props.parent then f.Parent = props.parent end
    if props.radius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.radius)
        corner.Parent = f
    end
    if props.zindex then f.ZIndex = props.zindex end
    return f
end

local function mkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text      = props.text or ""
    l.TextColor3 = props.color or C.text
    l.FontFace  = props.font or FONT_REGULAR
    l.TextSize  = props.size or 13
    l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = props.yalign or Enum.TextYAlignment.Center
    l.Size      = props.sz or UDim2.new(1, -10, 1, 0)
    l.Position  = props.pos or UDim2.new(0, 8, 0, 0)
    if props.parent then l.Parent = props.parent end
    if props.zindex then l.ZIndex = props.zindex end
    return l
end

-- ── Stroke helper ────────────────────────────────────────────
local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

-- ── Dragging ────────────────────────────────────────────────
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  LIBRARY
-- ════════════════════════════════════════════════════════════
local FangLib = {}
FangLib.__index = FangLib

function FangLib.new(title)
    local self = setmetatable({}, FangLib)

    -- ── ScreenGui ───────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name            = "FangLib"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset  = true
    sg.Parent          = (gethui and gethui()) or LocalPlayer.PlayerGui

    self._gui = sg

    -- ── Notification layer (on top) ─────────────────────────
    local notifLayer = Instance.new("Frame")
    notifLayer.Name                  = "NotifLayer"
    notifLayer.BackgroundTransparency = 1
    notifLayer.Size                  = UDim2.new(0, 280, 1, 0)
    notifLayer.Position              = UDim2.new(1, -290, 0, 0)
    notifLayer.ZIndex                = 200
    notifLayer.Parent                = sg
    local notifList = Instance.new("UIListLayout")
    notifList.SortOrder     = Enum.SortOrder.LayoutOrder
    notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifList.Padding       = UDim.new(0, 6)
    notifList.Parent        = notifLayer
    self._notifLayer = notifLayer

    -- ── Main window ─────────────────────────────────────────
    local win = mkFrame{
        bg     = C.bg,
        size   = UDim2.new(0, 780, 0, 500),
        pos    = UDim2.new(0.5, -390, 0.5, -250),
        radius = 6,
        parent = sg,
    }
    win.ClipsDescendants = true
    addStroke(win, C.border, 1)
    self._win = win

    -- Title bar
    local titleBar = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 32),
        pos    = UDim2.new(0, 0, 0, 0),
        radius = 0,
        parent = win,
    }
    local titleLabel = mkLabel{
        text   = title or "Fang.wtf",
        font   = FONT_BOLD,
        size   = 14,
        color  = C.accent,
        sz     = UDim2.new(0, 200, 1, 0),
        pos    = UDim2.new(0, 10, 0, 0),
        parent = titleBar,
    }

    -- Tab bar
    local tabBar = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 28),
        pos    = UDim2.new(0, 0, 0, 32),
        radius = 0,
        parent = win,
    }
    local tabBarList = Instance.new("UIListLayout")
    tabBarList.FillDirection  = Enum.FillDirection.Horizontal
    tabBarList.SortOrder      = Enum.SortOrder.LayoutOrder
    tabBarList.Padding        = UDim.new(0, 2)
    tabBarList.Parent         = tabBar
    Instance.new("UIPadding").Parent = tabBar
    tabBar:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 6)

    -- Content area (two-column)
    local content = mkFrame{
        bg     = C.bg,
        size   = UDim2.new(1, 0, 1, -60),
        pos    = UDim2.new(0, 0, 0, 60),
        parent = win,
    }

    makeDraggable(win, titleBar)

    self._tabBar  = tabBar
    self._content = content
    self._tabs    = {}
    self._activeTab = nil
    self._tabButtons = {}
    self._tabOrder = 0

    -- Close / minimise hints (top right)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text             = "×"
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.Position         = UDim2.new(1, -30, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3       = C.textDim
    closeBtn.FontFace         = FONT_BOLD
    closeBtn.TextSize         = 18
    closeBtn.ZIndex           = 10
    closeBtn.Parent           = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        tween(win, 0.25, {Size = UDim2.new(0, win.AbsoluteSize.X, 0, 0)})
        task.delay(0.26, function() win.Visible = false; win.Size = UDim2.new(0, 780, 0, 500) end)
    end)

    return self
end

-- ────────────────────────────────────────────────────────────
--  Notification
-- ────────────────────────────────────────────────────────────
function FangLib:Notify(opts)
    opts = opts or {}
    local title   = opts.title   or "Notification"
    local msg     = opts.message or ""
    local duration = opts.duration or 4
    local ntype   = opts.type    or "info" -- "info"|"success"|"warning"|"error"

    local typeColors = {
        info    = C.accent,
        success = Color3.fromRGB(100, 220, 130),
        warning = Color3.fromRGB(240, 180, 60),
        error   = Color3.fromRGB(230, 70, 80),
    }
    local accentCol = typeColors[ntype] or C.accent

    local card = mkFrame{
        bg     = C.notif_bg,
        size   = UDim2.new(1, 0, 0, 64),
        radius = 5,
        parent = self._notifLayer,
    }
    card.ClipsDescendants = true
    addStroke(card, accentCol, 1)

    -- Left accent strip
    local strip = mkFrame{
        bg     = accentCol,
        size   = UDim2.new(0, 3, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        parent = card,
    }

    mkLabel{
        text   = title,
        font   = FONT_BOLD,
        size   = 13,
        color  = accentCol,
        sz     = UDim2.new(1, -16, 0, 20),
        pos    = UDim2.new(0, 12, 0, 6),
        parent = card,
    }
    mkLabel{
        text   = msg,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.textDim,
        sz     = UDim2.new(1, -16, 0, 32),
        pos    = UDim2.new(0, 12, 0, 26),
        parent = card,
    }

    -- Progress bar
    local prog = mkFrame{
        bg     = accentCol,
        size   = UDim2.new(1, 0, 0, 2),
        pos    = UDim2.new(0, 0, 1, -2),
        parent = card,
    }
    tween(prog, duration, {Size = UDim2.new(0, 0, 0, 2)})

    -- Slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    tween(card, 0.3, {Position = UDim2.new(0, 0, 0, 0)})

    task.delay(duration, function()
        tween(card, 0.3, {Position = UDim2.new(1, 10, 0, 0)})
        task.delay(0.31, function() card:Destroy() end)
    end)
end

-- ────────────────────────────────────────────────────────────
--  Tab
-- ────────────────────────────────────────────────────────────
function FangLib:AddTab(name)
    self._tabOrder += 1

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Text             = name
    btn.FontFace         = FONT_SEMI
    btn.TextSize         = 12
    btn.TextColor3       = C.textDim
    btn.BackgroundColor3 = C.panel
    btn.BorderSizePixel  = 0
    btn.Size             = UDim2.new(0, 80, 1, 0)
    btn.AutomaticSize    = Enum.AutomaticSize.X
    btn.LayoutOrder      = self._tabOrder
    btn.Parent           = self._tabBar
    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft  = UDim.new(0, 10)
    btnPad.PaddingRight = UDim.new(0, 10)
    btnPad.Parent       = btn

    -- Underline indicator
    local underline = mkFrame{
        bg     = C.accent,
        size   = UDim2.new(1, 0, 0, 2),
        pos    = UDim2.new(0, 0, 1, -2),
        parent = btn,
    }
    underline.Visible = false

    -- Tab pane (two columns)
    local pane = mkFrame{
        bg     = C.bg,
        size   = UDim2.new(1, 0, 1, 0),
        parent = self._content,
    }
    pane.Visible = false

    -- Left column
    local leftCol = mkFrame{
        bg     = C.bg,
        size   = UDim2.new(0.5, -1, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        parent = pane,
    }
    local leftList = Instance.new("UIListLayout")
    leftList.SortOrder = Enum.SortOrder.LayoutOrder
    leftList.Padding   = UDim.new(0, 0)
    leftList.Parent    = leftCol
    local leftPad = Instance.new("UIPadding")
    leftPad.PaddingLeft   = UDim.new(0, 8)
    leftPad.PaddingRight  = UDim.new(0, 8)
    leftPad.PaddingTop    = UDim.new(0, 8)
    leftPad.Parent        = leftCol

    -- Divider
    local div = mkFrame{
        bg   = C.border,
        size = UDim2.new(0, 1, 1, 0),
        pos  = UDim2.new(0.5, 0, 0, 0),
        parent = pane,
    }

    -- Right column
    local rightCol = mkFrame{
        bg     = C.bg,
        size   = UDim2.new(0.5, -1, 1, 0),
        pos    = UDim2.new(0.5, 1, 0, 0),
        parent = pane,
    }
    local rightList = Instance.new("UIListLayout")
    rightList.SortOrder = Enum.SortOrder.LayoutOrder
    rightList.Padding   = UDim.new(0, 0)
    rightList.Parent    = rightCol
    local rightPad = Instance.new("UIPadding")
    rightPad.PaddingLeft  = UDim.new(0, 8)
    rightPad.PaddingRight = UDim.new(0, 8)
    rightPad.PaddingTop   = UDim.new(0, 8)
    rightPad.Parent       = rightCol

    local tabObj = {
        _pane      = pane,
        _leftCol   = leftCol,
        _rightCol  = rightCol,
        _leftList  = leftList,
        _rightList = rightList,
        _leftOrder = 0,
        _rightOrder = 0,
        _lib       = self,
    }

    -- Activate tab
    local function activate()
        if self._activeTab then
            self._activeTab._pane.Visible = false
            local prevBtn = self._tabButtons[self._activeTab]
            if prevBtn then
                prevBtn.btn.TextColor3 = C.textDim
                prevBtn.underline.Visible = false
            end
        end
        self._activeTab = tabObj
        self._tabButtons[tabObj] = {btn = btn, underline = underline}
        pane.Visible = true
        btn.TextColor3 = C.accent
        underline.Visible = true
    end

    btn.MouseButton1Click:Connect(activate)

    if not self._activeTab then activate() end

    self._tabs[name] = tabObj
    self._tabButtons[tabObj] = {btn = btn, underline = underline}

    setmetatable(tabObj, {__index = self})
    tabObj.AddSection  = function(t, sname, side) return FangLib._AddSection(t, sname, side) end
    tabObj.AddToggle   = function(t, ...) return FangLib._AddToggle(t, ...) end
    tabObj.AddSlider   = function(t, ...) return FangLib._AddSlider(t, ...) end
    tabObj.AddButton   = function(t, ...) return FangLib._AddButton(t, ...) end
    tabObj.AddDropdown = function(t, ...) return FangLib._AddDropdown(t, ...) end
    tabObj.AddLabel    = function(t, ...) return FangLib._AddLabel(t, ...) end
    tabObj.AddTextbox  = function(t, ...) return FangLib._AddTextbox(t, ...) end

    return tabObj
end

-- ────────────────────────────────────────────────────────────
--  Helpers for building elements
-- ────────────────────────────────────────────────────────────
local function getCol(tab, side)
    side = side or "left"
    if side == "right" then
        tab._rightOrder += 1
        return tab._rightCol, tab._rightOrder
    else
        tab._leftOrder += 1
        return tab._leftCol, tab._leftOrder
    end
end

-- Section header
function FangLib._AddSection(tab, name, side)
    local col, order = getCol(tab, side)
    local sect = mkFrame{
        bg     = C.section,
        size   = UDim2.new(1, 0, 0, 26),
        radius = 4,
        parent = col,
    }
    sect.LayoutOrder = order

    mkLabel{
        text   = name,
        font   = FONT_BOLD,
        size   = 12,
        color  = C.accent,
        sz     = UDim2.new(1, -10, 1, 0),
        pos    = UDim2.new(0, 8, 0, 0),
        parent = sect,
    }

    local spad = Instance.new("UIPadding")
    spad.PaddingBottom = UDim.new(0, 4)
    spad.Parent        = sect

    -- Return a section table so items can be added under it
    local sectionObj = {_col = col, _tab = tab, _order = order, _side = side}

    sectionObj.AddToggle   = function(s, ...) return FangLib._AddToggle(tab, ..., side) end
    sectionObj.AddSlider   = function(s, ...) return FangLib._AddSlider(tab, ..., side) end
    sectionObj.AddButton   = function(s, ...) return FangLib._AddButton(tab, ..., side) end
    sectionObj.AddDropdown = function(s, ...) return FangLib._AddDropdown(tab, ..., side) end
    sectionObj.AddLabel    = function(s, ...) return FangLib._AddLabel(tab, ..., side) end
    sectionObj.AddTextbox  = function(s, ...) return FangLib._AddTextbox(tab, ..., side) end

    return sectionObj
end

-- ── Toggle ───────────────────────────────────────────────────
function FangLib._AddToggle(tab, label, default, callback, side)
    local col, order = getCol(tab, side)
    local row = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 28),
        radius = 3,
        parent = col,
    }
    row.LayoutOrder = order

    local rpad = Instance.new("UIPadding")
    rpad.PaddingBottom = UDim.new(0, 2)
    rpad.Parent        = row

    mkLabel{
        text   = label,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.text,
        sz     = UDim2.new(1, -50, 1, 0),
        pos    = UDim2.new(0, 8, 0, 0),
        parent = row,
    }

    -- Toggle pill
    local pill = mkFrame{
        bg     = default and C.toggle_on or C.toggle_off,
        size   = UDim2.new(0, 32, 0, 16),
        pos    = UDim2.new(1, -40, 0.5, -8),
        radius = 8,
        parent = row,
    }
    local knob = mkFrame{
        bg     = C.white,
        size   = UDim2.new(0, 12, 0, 12),
        pos    = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        radius = 6,
        parent = pill,
    }

    local state = default or false
    local obj = {}
    obj.Value = state

    local function setState(v, fromCallback)
        state = v
        obj.Value = v
        tween(pill,  0.2, {BackgroundColor3 = v and C.toggle_on or C.toggle_off})
        tween(knob,  0.2, {Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)})
        if fromCallback and callback then callback(v) end
    end

    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            setState(not state, true)
        end
    end)

    function obj:Set(v) setState(v, false) end

    return obj
end

-- ── Slider ───────────────────────────────────────────────────
function FangLib._AddSlider(tab, label, min, max, default, callback, side)
    min     = min     or 0
    max     = max     or 100
    default = default or min
    local col, order = getCol(tab, side)

    local wrap = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 44),
        radius = 3,
        parent = col,
    }
    wrap.LayoutOrder = order

    local wpad = Instance.new("UIPadding")
    wpad.PaddingBottom = UDim.new(0, 2)
    wpad.Parent        = wrap

    mkLabel{
        text   = label,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.text,
        sz     = UDim2.new(1, -60, 0, 20),
        pos    = UDim2.new(0, 8, 0, 2),
        parent = wrap,
    }

    local valLabel = mkLabel{
        text   = tostring(math.round(default)),
        font   = FONT_SEMI,
        size   = 11,
        color  = C.accent,
        sz     = UDim2.new(0, 50, 0, 20),
        pos    = UDim2.new(1, -58, 0, 2),
        xalign = Enum.TextXAlignment.Right,
        parent = wrap,
    }

    local track = mkFrame{
        bg     = C.slider_bg,
        size   = UDim2.new(1, -16, 0, 4),
        pos    = UDim2.new(0, 8, 0, 30),
        radius = 2,
        parent = wrap,
    }
    local fill = mkFrame{
        bg     = C.accentFill,
        size   = UDim2.new((default-min)/(max-min), 0, 1, 0),
        pos    = UDim2.new(0,0,0,0),
        radius = 2,
        parent = track,
    }
    local thumb = mkFrame{
        bg     = C.accent,
        size   = UDim2.new(0, 10, 0, 10),
        pos    = UDim2.new((default-min)/(max-min), -5, 0.5, -5),
        radius = 5,
        parent = track,
    }

    local val = default
    local obj = {}
    obj.Value = val

    local function setVal(v, fire)
        v = math.clamp(v, min, max)
        local dec = (max - min >= 10) and 0 or 2
        v = math.floor(v * (10^dec) + 0.5) / (10^dec)
        val = v
        obj.Value = v
        local pct = (v - min) / (max - min)
        fill.Size  = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)
        valLabel.Text = tostring(v)
        if fire and callback then callback(v) end
    end

    local dragging = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            setVal(min + rel * (max - min), true)
        end
    end)

    function obj:Set(v) setVal(v, false) end

    return obj
end

-- ── Button ───────────────────────────────────────────────────
function FangLib._AddButton(tab, label, callback, side)
    local col, order = getCol(tab, side)
    local btn = Instance.new("TextButton")
    btn.Text             = label
    btn.FontFace         = FONT_SEMI
    btn.TextSize         = 12
    btn.TextColor3       = C.text
    btn.BackgroundColor3 = C.section
    btn.BorderSizePixel  = 0
    btn.Size             = UDim2.new(1, 0, 0, 26)
    btn.LayoutOrder      = order
    btn.Parent           = col
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 3)
    cor.Parent = btn
    addStroke(btn, C.border, 1)

    local bpad = Instance.new("UIPadding")
    bpad.PaddingBottom = UDim.new(0, 2)
    bpad.Parent        = btn

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.accentDark})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.section})
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

-- ── Dropdown ─────────────────────────────────────────────────
function FangLib._AddDropdown(tab, label, options, default, callback, side)
    local col, order = getCol(tab, side)
    local selected = default or options[1] or ""

    local wrap = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 28),
        radius = 3,
        parent = col,
    }
    wrap.LayoutOrder = order
    wrap.ClipsDescendants = false

    local wpad = Instance.new("UIPadding")
    wpad.PaddingBottom = UDim.new(0, 2)
    wpad.Parent        = wrap

    mkLabel{
        text   = label,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.text,
        sz     = UDim2.new(0.55, 0, 1, 0),
        pos    = UDim2.new(0, 8, 0, 0),
        parent = wrap,
    }

    local selBtn = Instance.new("TextButton")
    selBtn.Text             = selected .. "  +"
    selBtn.FontFace         = FONT_REGULAR
    selBtn.TextSize         = 11
    selBtn.TextColor3       = C.textDim
    selBtn.BackgroundColor3 = C.section
    selBtn.BorderSizePixel  = 0
    selBtn.Size             = UDim2.new(0.42, 0, 0, 20)
    selBtn.Position         = UDim2.new(0.57, 0, 0.5, -10)
    selBtn.Parent           = wrap
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 3)
    sc.Parent = selBtn

    -- Dropdown menu
    local menu = mkFrame{
        bg     = C.section,
        size   = UDim2.new(0, selBtn.AbsoluteSize.X, 0, #options * 22 + 4),
        pos    = UDim2.new(0.57, 0, 1, 0),
        radius = 3,
        parent = wrap,
    }
    menu.Visible = false
    menu.ZIndex  = 50
    addStroke(menu, C.border, 1)

    local menuList = Instance.new("UIListLayout")
    menuList.SortOrder = Enum.SortOrder.LayoutOrder
    menuList.Padding   = UDim.new(0, 1)
    menuList.Parent    = menu

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Text             = opt
        optBtn.FontFace         = FONT_REGULAR
        optBtn.TextSize         = 11
        optBtn.TextColor3       = C.text
        optBtn.BackgroundColor3 = C.section
        optBtn.BorderSizePixel  = 0
        optBtn.Size             = UDim2.new(1, 0, 0, 22)
        optBtn.LayoutOrder      = i
        optBtn.ZIndex           = 51
        optBtn.Parent           = menu
        optBtn.MouseEnter:Connect(function()
            tween(optBtn, 0.1, {BackgroundColor3 = C.accentDark})
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, 0.1, {BackgroundColor3 = C.section})
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selBtn.Text = opt .. "  +"
            menu.Visible = false
            if callback then callback(opt) end
        end)
    end

    local open = false
    selBtn.MouseButton1Click:Connect(function()
        open = not open
        menu.Visible = open
        menu.Size = UDim2.new(0, selBtn.AbsoluteSize.X, 0, open and (#options * 22 + 4) or 0)
    end)

    local obj = {}
    obj.Value = selected
    function obj:Set(v)
        selected = v
        selBtn.Text = v .. "  +"
    end
    function obj:UpdateOptions(newOpts)
        for _, c in ipairs(menu:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(newOpts) do
            local ob = Instance.new("TextButton")
            ob.Text             = opt
            ob.FontFace         = FONT_REGULAR
            ob.TextSize         = 11
            ob.TextColor3       = C.text
            ob.BackgroundColor3 = C.section
            ob.BorderSizePixel  = 0
            ob.Size             = UDim2.new(1, 0, 0, 22)
            ob.LayoutOrder      = i
            ob.ZIndex           = 51
            ob.Parent           = menu
            ob.MouseButton1Click:Connect(function()
                selected = opt
                selBtn.Text = opt .. "  +"
                menu.Visible = false
                if callback then callback(opt) end
            end)
        end
    end

    return obj
end

-- ── Label ────────────────────────────────────────────────────
function FangLib._AddLabel(tab, text, side)
    local col, order = getCol(tab, side)
    local lbl = mkLabel{
        text   = text,
        font   = FONT_REGULAR,
        size   = 11,
        color  = C.textDim,
        sz     = UDim2.new(1, -16, 0, 22),
        pos    = UDim2.new(0, 8, 0, 0),
        parent = col,
    }
    lbl.LayoutOrder = order
    local lpad = Instance.new("UIPadding")
    lpad.PaddingBottom = UDim.new(0, 2)
    lpad.Parent        = lbl
    local obj = {}
    obj.Instance = lbl
    function obj:Set(t) lbl.Text = t end
    return obj
end

-- ── Textbox ──────────────────────────────────────────────────
function FangLib._AddTextbox(tab, label, placeholder, callback, side)
    local col, order = getCol(tab, side)
    local wrap = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 44),
        radius = 3,
        parent = col,
    }
    wrap.LayoutOrder = order

    mkLabel{
        text   = label,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.text,
        sz     = UDim2.new(1, -10, 0, 20),
        pos    = UDim2.new(0, 8, 0, 2),
        parent = wrap,
    }

    local box = Instance.new("TextBox")
    box.Text             = ""
    box.PlaceholderText  = placeholder or "..."
    box.PlaceholderColor3 = C.textDim
    box.FontFace         = FONT_REGULAR
    box.TextSize         = 12
    box.TextColor3       = C.text
    box.BackgroundColor3 = C.section
    box.BorderSizePixel  = 0
    box.Size             = UDim2.new(1, -16, 0, 18)
    box.Position         = UDim2.new(0, 8, 0, 24)
    box.TextXAlignment   = Enum.TextXAlignment.Left
    box.Parent           = wrap
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 3)
    bc.Parent = box
    local bpad2 = Instance.new("UIPadding")
    bpad2.PaddingLeft = UDim.new(0, 6)
    bpad2.Parent = box
    addStroke(box, C.border, 1)
    local wpad2 = Instance.new("UIPadding")
    wpad2.PaddingBottom = UDim.new(0, 2)
    wpad2.Parent        = wrap

    box.FocusLost:Connect(function(enter)
        if enter and callback then callback(box.Text) end
    end)

    local obj = {}
    obj.Instance = box
    function obj:Get() return box.Text end
    function obj:Set(v) box.Text = v end
    return obj
end

-- ────────────────────────────────────────────────────────────
--  ColorBox (read-only swatch for visual display like chams)
-- ────────────────────────────────────────────────────────────
function FangLib._AddColorBox(tab, label, default, callback, side)
    local col, order = getCol(tab, side)
    local wrap = mkFrame{
        bg     = C.panel,
        size   = UDim2.new(1, 0, 0, 28),
        radius = 3,
        parent = col,
    }
    wrap.LayoutOrder = order

    mkLabel{
        text   = label,
        font   = FONT_REGULAR,
        size   = 12,
        color  = C.text,
        sz     = UDim2.new(1, -60, 1, 0),
        pos    = UDim2.new(0, 8, 0, 0),
        parent = wrap,
    }

    local swatch = mkFrame{
        bg     = default or C.accent,
        size   = UDim2.new(0, 18, 0, 18),
        pos    = UDim2.new(1, -44, 0.5, -9),
        radius = 3,
        parent = wrap,
    }
    addStroke(swatch, C.border, 1)

    local obj = {}
    obj.Value = default or C.accent
    function obj:Set(c)
        obj.Value = c
        swatch.BackgroundColor3 = c
    end
    return obj
end

-- Expose colorbox on tab
local origIndex = getmetatable({}).__index
function FangLib:GetTab(name) return self._tabs[name] end

-- Patch tab AddColorBox in AddTab closure
local _origAddTab = FangLib.AddTab
function FangLib.AddTab(self, name)
    local t = _origAddTab(self, name)
    t.AddColorBox = function(s, ...) return FangLib._AddColorBox(t, ...) end
    return t
end

return FangLib
