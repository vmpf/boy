
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local C = {
	bg        = Color3.fromRGB(15, 15, 18),
	panel     = Color3.fromRGB(20, 20, 25),
	panelBrd  = Color3.fromRGB(50, 40, 65),
	row       = Color3.fromRGB(20, 20, 25),
	rowHov    = Color3.fromRGB(28, 26, 35),
	section   = Color3.fromRGB(20, 20, 25),
	sectionLn = Color3.fromRGB(180, 90, 200),
	accent    = Color3.fromRGB(200, 110, 220),
	accentDim = Color3.fromRGB(130, 60, 150),
	sliderFg  = Color3.fromRGB(180, 90, 200),
	sliderBg  = Color3.fromRGB(38, 32, 50),
	toggleOn  = Color3.fromRGB(180, 90, 200),
	toggleOff = Color3.fromRGB(50, 45, 62),
	text      = Color3.fromRGB(220, 210, 230),
	textDim   = Color3.fromRGB(120, 110, 135),
	textSect  = Color3.fromRGB(180, 90, 200),
	white     = Color3.fromRGB(255, 255, 255),
	black     = Color3.fromRGB(0, 0, 0),
	notifBg   = Color3.fromRGB(18, 16, 24),
	ddBg      = Color3.fromRGB(25, 22, 32),
	ddItem    = Color3.fromRGB(28, 25, 36),
}

local FONT_REG  = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular)
local FONT_BOLD = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
local FONT_SEMI = Font.new("rbxassetid://12187371840", Enum.FontWeight.SemiBold)

local function tw(o, t, p) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint), p):Play() end

local function frame(p)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = p.bg or C.panel
	f.BorderSizePixel  = 0
	f.Size     = p.size or UDim2.new(1,0,0,24)
	f.Position = p.pos  or UDim2.new(0,0,0,0)
	if p.clips  ~= nil then f.ClipsDescendants = p.clips end
	if p.zindex then f.ZIndex = p.zindex end
	if p.parent then f.Parent = p.parent end
	if p.r then local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,p.r) c.Parent=f end
	return f
end

local function label(p)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text           = p.text   or ""
	l.TextColor3     = p.color  or C.text
	l.FontFace       = p.font   or FONT_REG
	l.TextSize       = p.ts     or 12
	l.TextXAlignment = p.xa     or Enum.TextXAlignment.Left
	l.TextYAlignment = p.ya     or Enum.TextYAlignment.Center
	l.Size           = p.size   or UDim2.new(1,0,1,0)
	l.Position       = p.pos    or UDim2.new(0,0,0,0)
	l.TextTruncate   = Enum.TextTruncate.AtEnd
	if p.zindex then l.ZIndex = p.zindex end
	if p.parent then l.Parent = p.parent end
	return l
end

local function stroke(p, col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col or C.panelBrd
	s.Thickness = thick or 1
	s.Parent = p
end

local function pad(p, t, r, b, l)
	local u = Instance.new("UIPadding")
	u.PaddingTop    = UDim.new(0, t or 0)
	u.PaddingRight  = UDim.new(0, r or 0)
	u.PaddingBottom = UDim.new(0, b or 0)
	u.PaddingLeft   = UDim.new(0, l or 0)
	u.Parent = p
end

local function list(p, dir, spacing)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.SortOrder     = Enum.SortOrder.LayoutOrder
	l.Padding       = UDim.new(0, spacing or 0)
	l.Parent        = p
	return l
end

local function drag(win, handle)
	local down, di, ds, dp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			down=true ds=i.Position dp=win.Position
		end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then down=false end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then di=i end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i==di and down then
			local d=i.Position-ds
			win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
		end
	end)
end

local function scrollPane(parent, xScale, xOffset, xPos, xPosOff)
	local col = frame{bg=C.panel, size=UDim2.new(xScale,xOffset,1,0), pos=UDim2.new(xPos,xPosOff,0,0), parent=parent, clips=true}
	local sf = Instance.new("ScrollingFrame")
	sf.Size=UDim2.new(1,0,1,0)
	sf.CanvasSize=UDim2.new(0,0,0,0)
	sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
	sf.ScrollBarThickness=2
	sf.ScrollBarImageColor3=C.accent
	sf.BackgroundTransparency=1
	sf.BorderSizePixel=0
	sf.Parent=col
	list(sf, Enum.FillDirection.Vertical, 0)
	pad(sf, 6,6,6,6)
	return sf
end

-- ══════════════════════════════════════════════
local Lumora = {}
Lumora.__index = Lumora

function Lumora.new(title)
	local self = setmetatable({}, Lumora)
	self._tabs={}  self._tabBtns={}  self._active=nil  self._tabIdx=0

	local sg = Instance.new("ScreenGui")
	sg.Name="Lumora" sg.ResetOnSpawn=false
	sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	sg.IgnoreGuiInset=true
	sg.Parent=(gethui and gethui()) or LocalPlayer.PlayerGui
	self._gui=sg

	-- notif layer
	local nl = frame{bg=C.black, size=UDim2.new(0,290,1,0), pos=UDim2.new(1,-298,0,0), parent=sg, clips=false}
	nl.BackgroundTransparency=1 nl.ZIndex=500
	list(nl, Enum.FillDirection.Vertical, 6)
	local nlpad = Instance.new("UIPadding")
	nlpad.PaddingBottom=UDim.new(0,12) nlpad.Parent=nl
	-- anchor to bottom
	local nlLayout = nl:FindFirstChildOfClass("UIListLayout")
	nlLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	self._nl=nl

	-- main window
	local win = frame{
		bg=C.bg, r=4,
		size=UDim2.new(0,760,0,490),
		pos=UDim2.new(0.5,-380,0.5,-245),
		parent=sg, clips=true
	}
	stroke(win, C.panelBrd, 1)
	self._win=win

	-- titlebar
	local tb = frame{bg=C.panel, size=UDim2.new(1,0,0,30), parent=win}
	-- title label left
	label{text=title or "Lumora", font=FONT_BOLD, ts=13, color=C.accent,
		size=UDim2.new(0,200,1,0), pos=UDim2.new(0,10,0,0), parent=tb}

	-- tab buttons right side of titlebar
	local tabHolder = frame{bg=C.panel, size=UDim2.new(1,-210,1,0), pos=UDim2.new(0,200,0,0), parent=tb}
	tabHolder.BackgroundTransparency=1
	list(tabHolder, Enum.FillDirection.Horizontal, 0)
	self._tabHolder=tabHolder

	-- close
	local xBtn = Instance.new("TextButton")
	xBtn.Text="×" xBtn.FontFace=FONT_BOLD xBtn.TextSize=16
	xBtn.TextColor3=C.textDim xBtn.BackgroundTransparency=1
	xBtn.BorderSizePixel=0 xBtn.Size=UDim2.new(0,28,1,0)
	xBtn.Position=UDim2.new(1,-28,0,0) xBtn.ZIndex=10 xBtn.Parent=tb
	xBtn.MouseButton1Click:Connect(function()
		tw(win,0.2,{Size=UDim2.new(0,760,0,0)})
		task.delay(0.21,function() win.Visible=false win.Size=UDim2.new(0,760,0,490) end)
	end)

	-- content
	local content = frame{bg=C.bg, size=UDim2.new(1,0,1,-30), pos=UDim2.new(0,0,0,30), parent=win}
	self._content=content

	drag(win, tb)
	return self
end

-- ── Notifications ──────────────────────────────────────────
function Lumora:Notify(o)
	o=o or {}
	local typeCol = {
		info    = C.accent,
		success = Color3.fromRGB(100,215,130),
		warning = Color3.fromRGB(235,175,55),
		error   = Color3.fromRGB(225,65,75),
	}
	local col = typeCol[o.type or "info"] or C.accent
	local dur = o.duration or 4

	local card = frame{bg=C.notifBg, size=UDim2.new(1,0,0,60), r=4, parent=self._nl}
	card.ClipsDescendants=true
	stroke(card, col, 1)
	-- left strip
	frame{bg=col, size=UDim2.new(0,3,1,0), pos=UDim2.new(0,0,0,0), parent=card}
	label{text=o.title or "Notification", font=FONT_BOLD, ts=12, color=col,
		size=UDim2.new(1,-18,0,18), pos=UDim2.new(0,12,0,6), parent=card}
	label{text=o.message or "", font=FONT_REG, ts=11, color=C.textDim,
		size=UDim2.new(1,-18,0,30), pos=UDim2.new(0,12,0,24), parent=card}
	local prog=frame{bg=col, size=UDim2.new(1,0,0,2), pos=UDim2.new(0,0,1,-2), parent=card}
	tw(prog, dur, {Size=UDim2.new(0,0,0,2)})

	card.Position=UDim2.new(1,10,0,0)
	tw(card,0.25,{Position=UDim2.new(0,0,0,0)})
	task.delay(dur,function()
		tw(card,0.25,{Position=UDim2.new(1,10,0,0)})
		task.delay(0.26,function() card:Destroy() end)
	end)
end

-- ── Tab ────────────────────────────────────────────────────
function Lumora:AddTab(name)
	self._tabIdx+=1

	local btn = Instance.new("TextButton")
	btn.Text=name btn.FontFace=FONT_SEMI btn.TextSize=12
	btn.TextColor3=C.textDim btn.BackgroundColor3=C.panel
	btn.BackgroundTransparency=1
	btn.BorderSizePixel=0 btn.AutomaticSize=Enum.AutomaticSize.X
	btn.Size=UDim2.new(0,0,1,0) btn.LayoutOrder=self._tabIdx
	btn.Parent=self._tabHolder
	pad(btn,0,12,0,12)

	local uline=frame{bg=C.accent, size=UDim2.new(1,0,0,2), pos=UDim2.new(0,0,1,-2), parent=btn}
	uline.Visible=false

	-- pane holds two panel columns
	local pane=frame{bg=C.bg, size=UDim2.new(1,0,1,0), parent=self._content, clips=false}
	pane.Visible=false

	-- LEFT panel box
	local leftBox=frame{
		bg=C.panel, r=3,
		size=UDim2.new(0.5,-8,1,-12),
		pos=UDim2.new(0,6,0,6),
		parent=pane, clips=true
	}
	stroke(leftBox, C.panelBrd, 1)
	local leftSF=Instance.new("ScrollingFrame")
	leftSF.Size=UDim2.new(1,0,1,0)
	leftSF.CanvasSize=UDim2.new(0,0,0,0)
	leftSF.AutomaticCanvasSize=Enum.AutomaticSize.Y
	leftSF.ScrollBarThickness=2
	leftSF.ScrollBarImageColor3=C.accent
	leftSF.BackgroundTransparency=1
	leftSF.BorderSizePixel=0
	leftSF.Parent=leftBox
	list(leftSF,Enum.FillDirection.Vertical,0)
	pad(leftSF,4,4,4,4)

	-- RIGHT panel box
	local rightBox=frame{
		bg=C.panel, r=3,
		size=UDim2.new(0.5,-8,1,-12),
		pos=UDim2.new(0.5,2,0,6),
		parent=pane, clips=false
	}
	stroke(rightBox, C.panelBrd, 1)
	local rightSF=Instance.new("ScrollingFrame")
	rightSF.Size=UDim2.new(1,0,1,0)
	rightSF.CanvasSize=UDim2.new(0,0,0,0)
	rightSF.AutomaticCanvasSize=Enum.AutomaticSize.Y
	rightSF.ScrollBarThickness=2
	rightSF.ScrollBarImageColor3=C.accent
	rightSF.BackgroundTransparency=1
	rightSF.BorderSizePixel=0
	rightSF.ClipsDescendants=false
	rightSF.Parent=rightBox
	list(rightSF,Enum.FillDirection.Vertical,0)
	pad(rightSF,4,4,4,4)

	local tab={
		_lsf=leftSF, _rsf=rightSF,
		_lo=0, _ro=0,
		_pane=pane,
		_lib=self,
	}

	local function activate()
		if self._active then
			self._active._pane.Visible=false
			local pb=self._tabBtns[self._active]
			if pb then pb.btn.TextColor3=C.textDim pb.ul.Visible=false end
		end
		self._active=tab
		self._tabBtns[tab]={btn=btn,ul=uline}
		pane.Visible=true
		btn.TextColor3=C.accent
		uline.Visible=true
	end

	btn.MouseButton1Click:Connect(activate)
	if not self._active then activate() end
	self._tabs[name]=tab

	-- ── helpers ──────────────────────────────────────────
	function tab:_c(side)
		if side=="right" then self._ro+=1 return self._rsf,self._ro
		else self._lo+=1 return self._lsf,self._lo end
	end

	-- SECTION HEADER  (pink label + thin line under)
	function tab:AddSection(name, side)
		local col,order=self:_c(side)
		local wrap=frame{bg=Color3.fromRGB(0,0,0), size=UDim2.new(1,0,0,22), parent=col}
		wrap.BackgroundTransparency=1
		wrap.LayoutOrder=order
		label{text=name, font=FONT_BOLD, ts=12, color=C.textSect,
			size=UDim2.new(1,-8,1,0), pos=UDim2.new(0,6,0,0), parent=wrap}
		local ln=frame{bg=C.sectionLn, size=UDim2.new(1,-12,0,1), pos=UDim2.new(0,6,1,-1), parent=wrap}
		ln.BackgroundTransparency=0.6
	end

	-- TOGGLE  (small coloured square on left, label, small square swatch on right)
	function tab:AddToggle(name, default, callback, side)
		local col,order=self:_c(side)
		local row=frame{bg=C.row, size=UDim2.new(1,0,0,24), parent=col}
		row.LayoutOrder=order
		-- hover
		row.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=C.rowHov}) end)
		row.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=C.row}) end)

		local state=default or false

		-- left indicator square
		local sq=frame{
			bg=state and C.toggleOn or C.toggleOff,
			size=UDim2.new(0,10,0,10),
			pos=UDim2.new(0,6,0.5,-5),
			r=2, parent=row
		}

		label{text=name, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-54,1,0), pos=UDim2.new(0,22,0,0), parent=row}

		-- right swatch square (shows accent or dim)
		local rsq=frame{
			bg=state and C.toggleOn or C.toggleOff,
			size=UDim2.new(0,14,0,14),
			pos=UDim2.new(1,-20,0.5,-7),
			r=2, parent=row
		}

		local obj={Value=state}
		local function set(v,fire)
			state=v obj.Value=v
			tw(sq,0.15,{BackgroundColor3=v and C.toggleOn or C.toggleOff})
			tw(rsq,0.15,{BackgroundColor3=v and C.toggleOn or C.toggleOff})
			if fire and callback then callback(v) end
		end

		local btn2=Instance.new("TextButton")
		btn2.Size=UDim2.new(1,0,1,0) btn2.BackgroundTransparency=1
		btn2.Text="" btn2.BorderSizePixel=0 btn2.Parent=row
		btn2.MouseButton1Click:Connect(function() set(not state,true) end)
		function obj:Set(v) set(v,false) end
		return obj
	end

	-- SLIDER  (full-width pink fill bar, value right inside bar)
	function tab:AddSlider(name, min, max, default, callback, side)
		min=min or 0 max=max or 100 default=math.clamp(default or min,min,max)
		local col,order=self:_c(side)

		-- header row
		local hdr=frame{bg=C.row, size=UDim2.new(1,0,0,20), parent=col}
		hdr.LayoutOrder=order
		label{text=name, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-8,1,0), pos=UDim2.new(0,6,0,0), parent=hdr}

		-- slider track row
		self._lo = (side=="right") and self._ro or self._lo
		if side=="right" then self._ro+=1 else self._lo+=1 end
		local trackOrder=(side=="right") and self._ro or self._lo

		local trackRow=frame{bg=C.sliderBg, size=UDim2.new(1,0,0,18), parent=col, r=2}
		trackRow.LayoutOrder=trackOrder

		local pct=(default-min)/(max-min)
		local fill=frame{bg=C.sliderFg, size=UDim2.new(pct,0,1,0), r=2, parent=trackRow}

		local valLbl=label{
			text=tostring(default),
			font=FONT_SEMI, ts=11, color=C.white,
			xa=Enum.TextXAlignment.Right,
			size=UDim2.new(1,-6,1,0),
			pos=UDim2.new(0,0,0,0),
			parent=trackRow, zindex=2
		}

		local val=default
		local obj={Value=val}
		local function setV(v,fire)
			v=math.clamp(v,min,max)
			local dec=(max-min>=10) and 0 or 2
			v=math.floor(v*(10^dec)+0.5)/(10^dec)
			val=v obj.Value=v
			local p=(v-min)/(max-min)
			fill.Size=UDim2.new(p,0,1,0)
			valLbl.Text=tostring(v)
			if fire and callback then callback(v) end
		end

		local dragging=false
		trackRow.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then
				dragging=true
				local rel=(i.Position.X-trackRow.AbsolutePosition.X)/trackRow.AbsoluteSize.X
				setV(min+rel*(max-min),true)
			end
		end)
		trackRow.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
				local rel=(i.Position.X-trackRow.AbsolutePosition.X)/trackRow.AbsoluteSize.X
				setV(min+rel*(max-min),true)
			end
		end)

		function obj:Set(v) setV(v,false) end
		return obj
	end

	-- BUTTON
	function tab:AddButton(name, callback, side)
		local col,order=self:_c(side)
		local btn3=Instance.new("TextButton")
		btn3.Text=name btn3.FontFace=FONT_SEMI btn3.TextSize=12
		btn3.TextColor3=C.text btn3.BackgroundColor3=C.row
		btn3.BorderSizePixel=0 btn3.Size=UDim2.new(1,0,0,24)
		btn3.LayoutOrder=order btn3.Parent=col
		local cr=Instance.new("UICorner") cr.CornerRadius=UDim.new(0,2) cr.Parent=btn3
		btn3.MouseEnter:Connect(function() tw(btn3,0.1,{BackgroundColor3=C.accentDim}) end)
		btn3.MouseLeave:Connect(function() tw(btn3,0.1,{BackgroundColor3=C.row}) end)
		btn3.MouseButton1Click:Connect(function() if callback then callback() end end)
		return btn3
	end

	-- DROPDOWN  (full width row: label left, "VALUE  +" right, opens list below)
	function tab:AddDropdown(name, options, default, callback, side)
		local col,order=self:_c(side)
		options=options or {}
		local selected=default or options[1] or ""

		-- header label row
		local hdr=frame{bg=Color3.fromRGB(0,0,0), size=UDim2.new(1,0,0,20), parent=col}
		hdr.BackgroundTransparency=1 hdr.LayoutOrder=order
		label{text=name, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-8,1,0), pos=UDim2.new(0,6,0,0), parent=hdr}

		-- value row (full width dark bar)
		if side=="right" then self._ro+=1 else self._lo+=1 end
		local valOrder=(side=="right") and self._ro or self._lo

		local valRow=frame{bg=C.sliderBg, size=UDim2.new(1,0,0,22), r=2, parent=col}
		valRow.LayoutOrder=valOrder
		valRow.ClipsDescendants=false

		-- selected text left
		local selLbl=label{text=selected, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-28,1,0), pos=UDim2.new(0,8,0,0), parent=valRow}

		-- "+" button right
		local plusBtn=Instance.new("TextButton")
		plusBtn.Text="+" plusBtn.FontFace=FONT_BOLD plusBtn.TextSize=14
		plusBtn.TextColor3=C.accent plusBtn.BackgroundTransparency=1
		plusBtn.BorderSizePixel=0
		plusBtn.Size=UDim2.new(0,22,1,0)
		plusBtn.Position=UDim2.new(1,-22,0,0)
		plusBtn.ZIndex=3 plusBtn.Parent=valRow

		-- dropdown menu (absolutely positioned below valRow)
		local menu=frame{
			bg=C.ddBg, r=3,
			size=UDim2.new(1,0,0,0),
			pos=UDim2.new(0,0,1,2),
			parent=valRow, clips=false
		}
		menu.Visible=false menu.ZIndex=100
		stroke(menu, C.panelBrd, 1)
		local menuList=list(menu,Enum.FillDirection.Vertical,0)

		for i,opt in ipairs(options) do
			local item=Instance.new("TextButton")
			item.Text=opt item.FontFace=FONT_REG item.TextSize=12
			item.TextColor3=C.text item.BackgroundColor3=C.ddItem
			item.BorderSizePixel=0 item.Size=UDim2.new(1,0,0,22)
			item.TextXAlignment=Enum.TextXAlignment.Left
			item.LayoutOrder=i item.ZIndex=101 item.Parent=menu
			pad(item,0,0,0,8)
			item.MouseEnter:Connect(function() tw(item,0.08,{BackgroundColor3=C.accentDim}) end)
			item.MouseLeave:Connect(function() tw(item,0.08,{BackgroundColor3=C.ddItem}) end)
			item.MouseButton1Click:Connect(function()
				selected=opt
				selLbl.Text=opt
				menu.Visible=false
				if callback then callback(opt) end
			end)
		end
		menu.Size=UDim2.new(1,0,0,#options*22)

		local open=false
		local function toggle()
			open=not open
			menu.Visible=open
		end
		plusBtn.MouseButton1Click:Connect(toggle)
		valRow.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then toggle() end
		end)

		-- close when clicking elsewhere
		UserInputService.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 and open then
				local gp=i.Position
				local ap=menu.AbsolutePosition
				local as=menu.AbsoluteSize
				if gp.X<ap.X or gp.X>ap.X+as.X or gp.Y<ap.Y or gp.Y>ap.Y+as.Y then
					local vp=valRow.AbsolutePosition
					local vs=valRow.AbsoluteSize
					if not(gp.X>=vp.X and gp.X<=vp.X+vs.X and gp.Y>=vp.Y and gp.Y<=vp.Y+vs.Y) then
						open=false menu.Visible=false
					end
				end
			end
		end)

		local obj={Value=selected}
		function obj:Set(v) selected=v selLbl.Text=v end
		function obj:UpdateOptions(opts)
			options=opts
			for _,c in ipairs(menu:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			for i,opt in ipairs(opts) do
				local item=Instance.new("TextButton")
				item.Text=opt item.FontFace=FONT_REG item.TextSize=12
				item.TextColor3=C.text item.BackgroundColor3=C.ddItem
				item.BorderSizePixel=0 item.Size=UDim2.new(1,0,0,22)
				item.TextXAlignment=Enum.TextXAlignment.Left
				item.LayoutOrder=i item.ZIndex=101 item.Parent=menu
				pad(item,0,0,0,8)
				item.MouseEnter:Connect(function() tw(item,0.08,{BackgroundColor3=C.accentDim}) end)
				item.MouseLeave:Connect(function() tw(item,0.08,{BackgroundColor3=C.ddItem}) end)
				item.MouseButton1Click:Connect(function()
					selected=opt selLbl.Text=opt menu.Visible=false
					if callback then callback(opt) end
				end)
			end
			menu.Size=UDim2.new(1,0,0,#opts*22)
		end
		return obj
	end

	-- LABEL
	function tab:AddLabel(text, side)
		local col,order=self:_c(side)
		local l=label{text=text, font=FONT_REG, ts=11, color=C.textDim,
			size=UDim2.new(1,-12,0,20), pos=UDim2.new(0,6,0,0), parent=col}
		l.LayoutOrder=order
		local obj={Instance=l}
		function obj:Set(t) l.Text=t end
		return obj
	end

	-- TEXTBOX
	function tab:AddTextbox(name, placeholder, callback, side)
		local col,order=self:_c(side)
		local hdr=frame{bg=Color3.fromRGB(0,0,0), size=UDim2.new(1,0,0,20), parent=col}
		hdr.BackgroundTransparency=1 hdr.LayoutOrder=order
		label{text=name, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-8,1,0), pos=UDim2.new(0,6,0,0), parent=hdr}

		if side=="right" then self._ro+=1 else self._lo+=1 end
		local boxOrder=(side=="right") and self._ro or self._lo

		local box=Instance.new("TextBox")
		box.Text="" box.PlaceholderText=placeholder or "..."
		box.PlaceholderColor3=C.textDim box.FontFace=FONT_REG box.TextSize=12
		box.TextColor3=C.text box.BackgroundColor3=C.sliderBg
		box.BorderSizePixel=0 box.Size=UDim2.new(1,0,0,22)
		box.TextXAlignment=Enum.TextXAlignment.Left
		box.LayoutOrder=boxOrder box.Parent=col
		local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,2) bc.Parent=box
		pad(box,0,0,0,8)
		box.FocusLost:Connect(function(enter) if enter and callback then callback(box.Text) end end)
		local obj={Instance=box}
		function obj:Get() return box.Text end
		function obj:Set(v) box.Text=v end
		return obj
	end

	-- COLORBOX  (toggle row but with a colour swatch on right)
	function tab:AddColorBox(name, default, callback, side)
		local col,order=self:_c(side)
		local row=frame{bg=C.row, size=UDim2.new(1,0,0,24), parent=col}
		row.LayoutOrder=order
		local sq=frame{bg=C.toggleOff, size=UDim2.new(0,10,0,10), pos=UDim2.new(0,6,0.5,-5), r=2, parent=row}
		label{text=name, font=FONT_REG, ts=12, color=C.text,
			size=UDim2.new(1,-70,1,0), pos=UDim2.new(0,22,0,0), parent=row}
		local swatch=frame{bg=default or C.accent, size=UDim2.new(0,30,0,14), pos=UDim2.new(1,-38,0.5,-7), r=2, parent=row}
		stroke(swatch, C.panelBrd, 1)
		local obj={Value=default or C.accent}
		function obj:Set(c) obj.Value=c swatch.BackgroundColor3=c end
		return obj
	end

	self._tabs[name]=tab
	return tab
end

return Lumora
