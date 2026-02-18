
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local C = {
	bg         = Color3.fromRGB(18, 18, 22),
	panel      = Color3.fromRGB(24, 24, 30),
	section    = Color3.fromRGB(30, 30, 38),
	border     = Color3.fromRGB(55, 45, 70),
	accent     = Color3.fromRGB(210, 120, 230),
	accentDark = Color3.fromRGB(140, 70, 160),
	accentFill = Color3.fromRGB(180, 90, 200),
	text       = Color3.fromRGB(230, 220, 240),
	textDim    = Color3.fromRGB(140, 130, 155),
	toggleOff  = Color3.fromRGB(55, 50, 65),
	toggleOn   = Color3.fromRGB(210, 120, 230),
	sliderBg   = Color3.fromRGB(45, 40, 58),
	notifBg    = Color3.fromRGB(28, 24, 36),
	white      = Color3.fromRGB(255, 255, 255),
}

local FONT_REG  = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular)
local FONT_BOLD = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
local FONT_SEMI = Font.new("rbxassetid://12187371840", Enum.FontWeight.SemiBold)

local function tw(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint), props):Play()
end

local function mkFrame(p)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = p.bg or C.panel
	f.BorderSizePixel  = 0
	f.Size             = p.size or UDim2.new(1,0,0,30)
	f.Position         = p.pos  or UDim2.new(0,0,0,0)
	if p.parent then f.Parent = p.parent end
	if p.radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, p.radius)
		c.Parent = f
	end
	if p.zindex then f.ZIndex = p.zindex end
	if p.clips  then f.ClipsDescendants = p.clips end
	return f
end

local function mkLabel(p)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text           = p.text   or ""
	l.TextColor3     = p.color  or C.text
	l.FontFace       = p.font   or FONT_REG
	l.TextSize       = p.size   or 13
	l.TextXAlignment = p.xalign or Enum.TextXAlignment.Left
	l.TextYAlignment = p.yalign or Enum.TextYAlignment.Center
	l.Size           = p.sz     or UDim2.new(1,-10,1,0)
	l.Position       = p.pos    or UDim2.new(0,8,0,0)
	if p.parent then l.Parent = p.parent end
	if p.zindex then l.ZIndex = p.zindex end
	return l
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or C.border
	s.Thickness = thickness or 1
	s.Parent    = parent
	return s
end

local function addPad(parent, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, t or 0)
	p.PaddingRight  = UDim.new(0, r or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft   = UDim.new(0, l or 0)
	p.Parent        = parent
	return p
end

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
			local d = i.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

local Lumora = {}
Lumora.__index = Lumora

function Lumora.new(title)
	local self = setmetatable({}, Lumora)
	self._tabs       = {}
	self._tabBtns    = {}
	self._activeTab  = nil
	self._tabOrder   = 0

	local sg = Instance.new("ScreenGui")
	sg.Name           = "Lumora"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.IgnoreGuiInset = true
	sg.Parent         = (gethui and gethui()) or LocalPlayer.PlayerGui
	self._gui = sg

	local notifLayer = mkFrame{bg=Color3.new(0,0,0), size=UDim2.new(0,280,1,0), pos=UDim2.new(1,-290,0,0), parent=sg}
	notifLayer.BackgroundTransparency = 1
	notifLayer.ZIndex = 200
	local notifList = Instance.new("UIListLayout")
	notifList.SortOrder         = Enum.SortOrder.LayoutOrder
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifList.Padding           = UDim.new(0,6)
	notifList.Parent            = notifLayer
	self._notifLayer = notifLayer

	local win = mkFrame{bg=C.bg, size=UDim2.new(0,780,0,500), pos=UDim2.new(0.5,-390,0.5,-250), radius=6, parent=sg, clips=true}
	addStroke(win, C.border, 1)
	self._win = win

	local titleBar = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,32), parent=win}
	mkLabel{text=title or "Lumora", font=FONT_BOLD, size=14, color=C.accent, sz=UDim2.new(0,300,1,0), pos=UDim2.new(0,10,0,0), parent=titleBar}

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text                  = "×"
	closeBtn.Size                  = UDim2.new(0,28,0,28)
	closeBtn.Position              = UDim2.new(1,-30,0,2)
	closeBtn.BackgroundTransparency = 1
	closeBtn.TextColor3            = C.textDim
	closeBtn.FontFace              = FONT_BOLD
	closeBtn.TextSize              = 18
	closeBtn.ZIndex                = 10
	closeBtn.Parent                = titleBar
	closeBtn.MouseButton1Click:Connect(function()
		tw(win, 0.25, {Size=UDim2.new(0,win.AbsoluteSize.X,0,0)})
		task.delay(0.26, function()
			win.Visible = false
			win.Size = UDim2.new(0,780,0,500)
		end)
	end)

	local tabBar = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,28), pos=UDim2.new(0,0,0,32), parent=win}
	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.SortOrder     = Enum.SortOrder.LayoutOrder
	tabList.Padding       = UDim.new(0,2)
	tabList.Parent        = tabBar
	addPad(tabBar, 0,0,0,6)
	self._tabBar = tabBar

	local content = mkFrame{bg=C.bg, size=UDim2.new(1,0,1,-60), pos=UDim2.new(0,0,0,60), parent=win}
	self._content = content

	makeDraggable(win, titleBar)
	return self
end

function Lumora:Notify(opts)
	opts = opts or {}
	local ntype = opts.type or "info"
	local cols  = {
		info    = C.accent,
		success = Color3.fromRGB(100,220,130),
		warning = Color3.fromRGB(240,180,60),
		error   = Color3.fromRGB(230,70,80),
	}
	local col = cols[ntype] or C.accent

	local card = mkFrame{bg=C.notifBg, size=UDim2.new(1,0,0,64), radius=5, parent=self._notifLayer}
	card.ClipsDescendants = true
	addStroke(card, col, 1)

	mkFrame{bg=col, size=UDim2.new(0,3,1,0), parent=card}
	mkLabel{text=opts.title or "Notification", font=FONT_BOLD, size=13, color=col, sz=UDim2.new(1,-16,0,20), pos=UDim2.new(0,12,0,6), parent=card}
	mkLabel{text=opts.message or "", font=FONT_REG, size=12, color=C.textDim, sz=UDim2.new(1,-16,0,32), pos=UDim2.new(0,12,0,26), parent=card}

	local prog = mkFrame{bg=col, size=UDim2.new(1,0,0,2), pos=UDim2.new(0,0,1,-2), parent=card}
	local dur = opts.duration or 4
	tw(prog, dur, {Size=UDim2.new(0,0,0,2)})

	card.Position = UDim2.new(1,10,0,0)
	tw(card, 0.3, {Position=UDim2.new(0,0,0,0)})
	task.delay(dur, function()
		tw(card, 0.3, {Position=UDim2.new(1,10,0,0)})
		task.delay(0.31, function() card:Destroy() end)
	end)
end

function Lumora:AddTab(name)
	self._tabOrder += 1

	local btn = Instance.new("TextButton")
	btn.Text             = name
	btn.FontFace         = FONT_SEMI
	btn.TextSize         = 12
	btn.TextColor3       = C.textDim
	btn.BackgroundColor3 = C.panel
	btn.BorderSizePixel  = 0
	btn.AutomaticSize    = Enum.AutomaticSize.X
	btn.Size             = UDim2.new(0,0,1,0)
	btn.LayoutOrder      = self._tabOrder
	btn.Parent           = self._tabBar
	addPad(btn, 0,10,0,10)

	local underline = mkFrame{bg=C.accent, size=UDim2.new(1,0,0,2), pos=UDim2.new(0,0,1,-2), parent=btn}
	underline.Visible = false

	local pane = mkFrame{bg=C.bg, size=UDim2.new(1,0,1,0), parent=self._content}
	pane.Visible = false

	local leftCol = mkFrame{bg=C.bg, size=UDim2.new(0.5,-1,1,0), parent=pane}
	leftCol.ClipsDescendants = true
	local leftScroll = Instance.new("ScrollingFrame")
	leftScroll.Size                  = UDim2.new(1,0,1,0)
	leftScroll.CanvasSize            = UDim2.new(0,0,0,0)
	leftScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	leftScroll.ScrollBarThickness    = 3
	leftScroll.ScrollBarImageColor3  = C.accent
	leftScroll.BackgroundTransparency = 1
	leftScroll.BorderSizePixel       = 0
	leftScroll.Parent                = leftCol
	local ll = Instance.new("UIListLayout")
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding   = UDim.new(0,2)
	ll.Parent    = leftScroll
	addPad(leftScroll, 8,8,8,8)

	mkFrame{bg=C.border, size=UDim2.new(0,1,1,0), pos=UDim2.new(0.5,0,0,0), parent=pane}

	local rightCol = mkFrame{bg=C.bg, size=UDim2.new(0.5,-1,1,0), pos=UDim2.new(0.5,1,0,0), parent=pane}
	rightCol.ClipsDescendants = true
	local rightScroll = Instance.new("ScrollingFrame")
	rightScroll.Size                  = UDim2.new(1,0,1,0)
	rightScroll.CanvasSize            = UDim2.new(0,0,0,0)
	rightScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	rightScroll.ScrollBarThickness    = 3
	rightScroll.ScrollBarImageColor3  = C.accent
	rightScroll.BackgroundTransparency = 1
	rightScroll.BorderSizePixel       = 0
	rightScroll.Parent                = rightCol
	local rl = Instance.new("UIListLayout")
	rl.SortOrder = Enum.SortOrder.LayoutOrder
	rl.Padding   = UDim.new(0,2)
	rl.Parent    = rightScroll
	addPad(rightScroll, 8,8,8,8)

	local tab = {
		_leftScroll  = leftScroll,
		_rightScroll = rightScroll,
		_leftOrder   = 0,
		_rightOrder  = 0,
		_lib         = self,
	}

	local function activate()
		if self._activeTab then
			self._activeTab._pane.Visible = false
			local prev = self._tabBtns[self._activeTab]
			if prev then
				prev.btn.TextColor3    = C.textDim
				prev.line.Visible      = false
			end
		end
		tab._pane      = pane
		self._activeTab = tab
		self._tabBtns[tab] = {btn=btn, line=underline}
		pane.Visible       = true
		btn.TextColor3     = C.accent
		underline.Visible  = true
	end

	btn.MouseButton1Click:Connect(activate)
	if not self._activeTab then activate() end

	local lib = self

	function tab:_getCol(side)
		if side == "right" then
			self._rightOrder += 1
			return self._rightScroll, self._rightOrder
		else
			self._leftOrder += 1
			return self._leftScroll, self._leftOrder
		end
	end

	function tab:AddSection(name, side)
		local col, order = self:_getCol(side)
		local sect = mkFrame{bg=C.section, size=UDim2.new(1,0,0,26), radius=4, parent=col}
		sect.LayoutOrder = order
		mkLabel{text=name, font=FONT_BOLD, size=12, color=C.accent, sz=UDim2.new(1,-10,1,0), pos=UDim2.new(0,8,0,0), parent=sect}
		addPad(sect, 0,0,4,0)
	end

	function tab:AddToggle(label, default, callback, side)
		local col, order = self:_getCol(side)
		local row = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,28), radius=3, parent=col}
		row.LayoutOrder = order
		addPad(row, 0,0,2,0)
		mkLabel{text=label, font=FONT_REG, size=12, color=C.text, sz=UDim2.new(1,-50,1,0), pos=UDim2.new(0,8,0,0), parent=row}

		local pill = mkFrame{bg=default and C.toggleOn or C.toggleOff, size=UDim2.new(0,32,0,16), pos=UDim2.new(1,-40,0.5,-8), radius=8, parent=row}
		local knob = mkFrame{bg=C.white, size=UDim2.new(0,12,0,12), pos=default and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6), radius=6, parent=pill}

		local state = default or false
		local obj   = {Value = state}

		local function setState(v, fire)
			state     = v
			obj.Value = v
			tw(pill, 0.2, {BackgroundColor3 = v and C.toggleOn or C.toggleOff})
			tw(knob, 0.2, {Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)})
			if fire and callback then callback(v) end
		end

		row.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state, true) end
		end)
		function obj:Set(v) setState(v, false) end
		return obj
	end

	function tab:AddSlider(label, min, max, default, callback, side)
		min     = min     or 0
		max     = max     or 100
		default = default or min
		local col, order = self:_getCol(side)
		local wrap = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,44), radius=3, parent=col}
		wrap.LayoutOrder = order
		addPad(wrap, 0,0,2,0)

		mkLabel{text=label, font=FONT_REG, size=12, color=C.text, sz=UDim2.new(1,-60,0,20), pos=UDim2.new(0,8,0,2), parent=wrap}
		local valLbl = mkLabel{text=tostring(default), font=FONT_SEMI, size=11, color=C.accent, sz=UDim2.new(0,50,0,20), pos=UDim2.new(1,-58,0,2), xalign=Enum.TextXAlignment.Right, parent=wrap}

		local track = mkFrame{bg=C.sliderBg, size=UDim2.new(1,-16,0,4), pos=UDim2.new(0,8,0,30), radius=2, parent=wrap}
		local pct0  = (default-min)/(max-min)
		local fill  = mkFrame{bg=C.accentFill, size=UDim2.new(pct0,0,1,0), radius=2, parent=track}
		local thumb = mkFrame{bg=C.accent, size=UDim2.new(0,10,0,10), pos=UDim2.new(pct0,-5,0.5,-5), radius=5, parent=track}

		local val = default
		local obj = {Value = val}

		local function setVal(v, fire)
			v = math.clamp(v, min, max)
			local dec = (max-min >= 10) and 0 or 2
			v = math.floor(v*(10^dec)+0.5)/(10^dec)
			val = v
			obj.Value = v
			local p = (v-min)/(max-min)
			fill.Size      = UDim2.new(p,0,1,0)
			thumb.Position = UDim2.new(p,-5,0.5,-5)
			valLbl.Text    = tostring(v)
			if fire and callback then callback(v) end
		end

		local dragging = false
		track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
		end)
		track.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				setVal(min + rel*(max-min), true)
			end
		end)

		function obj:Set(v) setVal(v, false) end
		return obj
	end

	function tab:AddButton(label, callback, side)
		local col, order = self:_getCol(side)
		local btn2 = Instance.new("TextButton")
		btn2.Text             = label
		btn2.FontFace         = FONT_SEMI
		btn2.TextSize         = 12
		btn2.TextColor3       = C.text
		btn2.BackgroundColor3 = C.section
		btn2.BorderSizePixel  = 0
		btn2.Size             = UDim2.new(1,0,0,26)
		btn2.LayoutOrder      = order
		btn2.Parent           = col
		local c2 = Instance.new("UICorner") c2.CornerRadius=UDim.new(0,3) c2.Parent=btn2
		addStroke(btn2, C.border, 1)
		addPad(btn2, 0,0,2,0)
		btn2.MouseEnter:Connect(function() tw(btn2,0.15,{BackgroundColor3=C.accentDark}) end)
		btn2.MouseLeave:Connect(function() tw(btn2,0.15,{BackgroundColor3=C.section}) end)
		btn2.MouseButton1Click:Connect(function() if callback then callback() end end)
		return btn2
	end

	function tab:AddDropdown(label, options, default, callback, side)
		local col, order = self:_getCol(side)
		local selected = default or (options and options[1]) or ""
		local wrap = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,28), radius=3, parent=col}
		wrap.LayoutOrder      = order
		wrap.ClipsDescendants = false
		addPad(wrap, 0,0,2,0)

		mkLabel{text=label, font=FONT_REG, size=12, color=C.text, sz=UDim2.new(0.55,0,1,0), pos=UDim2.new(0,8,0,0), parent=wrap}

		local selBtn = Instance.new("TextButton")
		selBtn.Text             = selected.."  +"
		selBtn.FontFace         = FONT_REG
		selBtn.TextSize         = 11
		selBtn.TextColor3       = C.textDim
		selBtn.BackgroundColor3 = C.section
		selBtn.BorderSizePixel  = 0
		selBtn.Size             = UDim2.new(0.42,0,0,20)
		selBtn.Position         = UDim2.new(0.57,0,0.5,-10)
		selBtn.Parent           = wrap
		local sc = Instance.new("UICorner") sc.CornerRadius=UDim.new(0,3) sc.Parent=selBtn

		local menu = mkFrame{bg=C.section, size=UDim2.new(0,120,0,0), pos=UDim2.new(0.57,0,1,0), radius=3, parent=wrap}
		menu.Visible = false
		menu.ZIndex  = 50
		addStroke(menu, C.border, 1)
		local ml = Instance.new("UIListLayout") ml.SortOrder=Enum.SortOrder.LayoutOrder ml.Padding=UDim.new(0,1) ml.Parent=menu

		local function buildOptions(opts)
			for _,c in ipairs(menu:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for i,opt in ipairs(opts) do
				local ob = Instance.new("TextButton")
				ob.Text             = opt
				ob.FontFace         = FONT_REG
				ob.TextSize         = 11
				ob.TextColor3       = C.text
				ob.BackgroundColor3 = C.section
				ob.BorderSizePixel  = 0
				ob.Size             = UDim2.new(1,0,0,22)
				ob.LayoutOrder      = i
				ob.ZIndex           = 51
				ob.Parent           = menu
				ob.MouseEnter:Connect(function() tw(ob,0.1,{BackgroundColor3=C.accentDark}) end)
				ob.MouseLeave:Connect(function() tw(ob,0.1,{BackgroundColor3=C.section}) end)
				ob.MouseButton1Click:Connect(function()
					selected = opt
					selBtn.Text  = opt.."  +"
					menu.Visible = false
					menu.Size    = UDim2.new(0,120,0,0)
					if callback then callback(opt) end
				end)
			end
		end

		buildOptions(options or {})

		local open = false
		selBtn.MouseButton1Click:Connect(function()
			open = not open
			menu.Visible = open
			menu.Size    = open and UDim2.new(0,selBtn.AbsoluteSize.X,0,#options*22+4) or UDim2.new(0,120,0,0)
		end)

		local obj = {Value = selected}
		function obj:Set(v) selected=v selBtn.Text=v.."  +" end
		function obj:UpdateOptions(o) options=o buildOptions(o) end
		return obj
	end

	function tab:AddLabel(text, side)
		local col, order = self:_getCol(side)
		local lbl = mkLabel{text=text, font=FONT_REG, size=11, color=C.textDim, sz=UDim2.new(1,-16,0,22), pos=UDim2.new(0,8,0,0), parent=col}
		lbl.LayoutOrder = order
		addPad(lbl, 0,0,2,0)
		local obj = {Instance=lbl}
		function obj:Set(t) lbl.Text=t end
		return obj
	end

	function tab:AddTextbox(label, placeholder, callback, side)
		local col, order = self:_getCol(side)
		local wrap = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,44), radius=3, parent=col}
		wrap.LayoutOrder = order
		addPad(wrap, 0,0,2,0)
		mkLabel{text=label, font=FONT_REG, size=12, color=C.text, sz=UDim2.new(1,-10,0,20), pos=UDim2.new(0,8,0,2), parent=wrap}
		local box = Instance.new("TextBox")
		box.Text              = ""
		box.PlaceholderText   = placeholder or "..."
		box.PlaceholderColor3 = C.textDim
		box.FontFace          = FONT_REG
		box.TextSize          = 12
		box.TextColor3        = C.text
		box.BackgroundColor3  = C.section
		box.BorderSizePixel   = 0
		box.Size              = UDim2.new(1,-16,0,18)
		box.Position          = UDim2.new(0,8,0,24)
		box.TextXAlignment    = Enum.TextXAlignment.Left
		box.Parent            = wrap
		local bc = Instance.new("UICorner") bc.CornerRadius=UDim.new(0,3) bc.Parent=box
		addPad(box, 0,0,0,6)
		addStroke(box, C.border, 1)
		box.FocusLost:Connect(function(enter) if enter and callback then callback(box.Text) end end)
		local obj = {Instance=box}
		function obj:Get() return box.Text end
		function obj:Set(v) box.Text=v end
		return obj
	end

	function tab:AddColorBox(label, default, callback, side)
		local col, order = self:_getCol(side)
		local wrap = mkFrame{bg=C.panel, size=UDim2.new(1,0,0,28), radius=3, parent=col}
		wrap.LayoutOrder = order
		addPad(wrap, 0,0,2,0)
		mkLabel{text=label, font=FONT_REG, size=12, color=C.text, sz=UDim2.new(1,-60,1,0), pos=UDim2.new(0,8,0,0), parent=wrap}
		local swatch = mkFrame{bg=default or C.accent, size=UDim2.new(0,18,0,18), pos=UDim2.new(1,-44,0.5,-9), radius=3, parent=wrap}
		addStroke(swatch, C.border, 1)
		local obj = {Value = default or C.accent}
		function obj:Set(c) obj.Value=c swatch.BackgroundColor3=c end
		return obj
	end

	self._tabs[name] = tab
	return tab
end

return Lumora
