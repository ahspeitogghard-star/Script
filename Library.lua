while not game:IsLoaded() do task.wait() end
for _, UI in ipairs(game.CoreGui:GetChildren()) do
	if UI.Name == "BetterOrion" then 
		UI:Destroy() 
	end
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local OrionLib = {
	Elements = {},
	UIElements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Tabs = {},
	Themes = {
		Default = {
			Main = { Color = Color3.fromRGB(30, 30, 30), Transparency = 0.25 },
			Stroke = { Color = Color3.fromRGB(180, 180, 180), Transparency = 0.45 },
			Divider = { Color = Color3.fromRGB(180, 180, 180), Transparency = 0.85 },
			Text = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
			TextDark = { Color = Color3.fromRGB(200, 200, 200), Transparency = 0 },
			Elements = { Color = Color3.fromRGB(45, 45, 45), Transparency = 0.2 }
		},
		MyCustomTheme = {
			Main = {}, Stroke = {}, Divider = {}, Text = {}, TextDark = {}, Elements = {}
		}
	},
	NotificationSettings = { Enabled = true, Printing = true },
	WindowConfig = { AutoSizedTabHolderX = false, AutoSizedTabHolderY = "Window" },
	BackgroundConfig = { EnabledBackground = false, BackgroundName = "", BackgroundTransparency = 0.2 },
	SelectedTheme = "Default",
	ScriptFolder = "BetterOrion",
	GameName = tostring(game.PlaceId),
	Window = nil,
}

-- Icons
local Icons = {}
local LucideIcons = nil
do
	local Candidates = {
		"https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
		"https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua",
	}
	for _, Url in ipairs(Candidates) do
		local ok, mod = pcall(function() return loadstring(game:HttpGet(Url))() end)
		if ok and type(mod) == "table" then
			if type(mod.GetAsset) == "function" then LucideIcons = mod; break end
			if mod.assets ~= nil then LucideIcons = mod.assets; break end
		end
	end
end

-- Core
local Orion = Instance.new("ScreenGui")
Orion.Name = "BetterOrion"
if syn then
	pcall(function() syn.protect_gui(Orion) end)
	Orion.Parent = game.CoreGui
else
	Orion.Parent = game.CoreGui
end

function OrionLib:IsRunning()
	return Orion.Parent == game.CoreGui
end

-- Local functions
local function GetOrionIcon(IconName)
	if Icons[IconName] ~= nil then return Icons[IconName] else return nil end
end

local function NormalizeIconName(IconName)
	if type(IconName) ~= "string" then return nil end
	local n = string.lower(IconName):gsub("^lucide%-", ""):gsub("%s+", "")
	return n
end

local function ResolveIconData(data)
	if typeof(data) ~= "table" then return data end
	if data.Url then return data end
	if data.id then
		return {
			Url = typeof(data.id) == "number" and ("rbxassetid://" .. tostring(data.id)) or tostring(data.id),
			ImageRectOffset = data.imageRectOffset or Vector2.zero,
			ImageRectSize = data.imageRectSize or Vector2.new(24, 24)
		}
	end
	return data
end

local function GetLucideIcon(IconName)
	if IconName == nil then return nil end
	if typeof(IconName) == "table" then return ResolveIconData(IconName) end
	local n = NormalizeIconName(IconName); if not n then return nil end
	if type(LucideIcons) == "table" then
		if type(LucideIcons.GetAsset) == "function" then
			local d = LucideIcons:GetAsset(n); if d then return ResolveIconData(d) end
		end
		if LucideIcons[n] then return ResolveIconData(LucideIcons[n]) end
		if LucideIcons["lucide-" .. n] then return ResolveIconData(LucideIcons["lucide-" .. n]) end
		if LucideIcons.assets then
			local d = LucideIcons.assets[n] or LucideIcons.assets["lucide-" .. n]
			if d then return ResolveIconData(d) end
		end
	end
	return nil
end

local function AddConnection(Signal, Function)
	if (not OrionLib:IsRunning()) then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while (OrionLib:IsRunning()) do wait() end
	for _, Connection in next, OrionLib.Connections do Connection:Disconnect() end
end)

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in Properties or {} do Object[i] = v end
	for i, v in Children or {} do v.Parent = Object end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	OrionLib.Elements[ElementName] = function(...) return ElementFunction(...) end
end

local function MakeElement(ElementName, ...)
	return OrionLib.Elements[ElementName](...)
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value) Element[Property] = Value end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child) Child.Parent = Element end)
	return Element
end

local function Round(Number, Factor)
	Number = tonumber(Number) or 0
	local sign = Number >= 0 and 1 or -1
	local result = math.floor(Number / Factor + 0.5 * sign) * Factor
	if result < 0 then result = result + Factor end
	if Factor < 1 then
		local str = tostring(Factor)
		local dot = str:find("%.")
		local precision = dot and #str - dot or 0
		result = tonumber(string.format("%." .. precision .. "f", result))
	end
	return result
end

local function ReturnProperty(Object, PropType)
	if Object:IsA("Frame") or Object:IsA("TextButton") then return (PropType == "Color" and "BackgroundColor3") or "BackgroundTransparency" end
	if Object:IsA("ScrollingFrame") then return (PropType == "Color" and "ScrollBarImageColor3") or "ScrollBarImageTransparency" end
	if Object:IsA("UIStroke") then return (PropType == "Color" and "Color") or "Transparency" end
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then return (PropType == "Color" and "TextColor3") or "TextTransparency" end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return (PropType == "Color" and "ImageColor3") or "ImageTransparency" end
end

local function AddThemeObject(Object, Type)
	if not OrionLib.ThemeObjects[Type] then OrionLib.ThemeObjects[Type] = {} end
	table.insert(OrionLib.ThemeObjects[Type], Object)
	local theme = OrionLib.Themes[OrionLib.SelectedTheme][Type]
	Object[ReturnProperty(Object, "Color")] = theme.Color
	Object[ReturnProperty(Object, "Transparency")] = theme.Transparency
	return Object
end

local WhitelistedMouse = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 }
local BlacklistedKeys = {
	Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
	Enum.KeyCode.Slash, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}

local function CheckKey(Table, Key)
	for _, v in next, Table do if v == Key then return true end end
end

-- Create Elements
CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", { CornerRadius = UDim.new(Scale or 0, Offset or 10) })
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", {
		Color = Color or Color3.fromRGB(180, 180, 180),
		Thickness = Thickness or 1,
		Transparency = 0.45,
		Name = "Stroke"
	})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0) })
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4), PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4), PaddingTop = UDim.new(0, Top or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0 })
end)

CreateElement("Frame", function(Color)
	return Create("Frame", { BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 })
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0
	}, { Create("UICorner", { CornerRadius = UDim.new(Scale or 0, Offset or 10) }) })
	return Frame
end)

CreateElement("Button", function()
	return Create("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0
	})
end)

CreateElement("ScrollFrame", function(Color)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color or Color3.fromRGB(180, 180, 180),
		ScrollBarImageTransparency = 0.35,
		ScrollBarThickness = 4,
		BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0)
	})
end)

CreateElement("Image", function(ImageID)
	local img = Create("ImageLabel", { BackgroundTransparency = 1 })
	local resolved = GetOrionIcon(ImageID) or GetLucideIcon(ImageID)
	if type(resolved) == "table" and resolved.Url then
		img.Image = resolved.Url
		img.ImageRectOffset = resolved.ImageRectOffset or Vector2.zero
		img.ImageRectSize = resolved.ImageRectSize or Vector2.new(24, 24)
	elseif resolved then
		img.Image = resolved
	end
	return img
end)

CreateElement("ImageButton", function(ImageID)
	local Image = Create("ImageButton", { Image = ImageID, BackgroundTransparency = 1 })
	return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", {
		Text = Text or "", TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0, TextSize = TextSize or 15,
		Font = Enum.Font.Gotham, RichText = true, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
end)

-- Notifications
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.Name,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 5)
	})
}), {
	Position = UDim2.new(1, -25, 1, -25), Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1), Parent = Orion, Name = "NotificationList"
})

function OrionLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig = NotificationConfig or {}
		NotificationConfig.Name = NotificationConfig.Name or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Content"
		NotificationConfig.Image = NotificationConfig.Image or "bell"
		NotificationConfig.Time = NotificationConfig.Time or 5
		NotificationConfig.Color = NotificationConfig.Color or Color3.fromRGB(30, 30, 30)
		NotificationConfig.TextColor = NotificationConfig.TextColor or Color3.fromRGB(255, 255, 255)
		NotificationConfig.Sound = NotificationConfig.Sound or ""
		NotificationConfig.SoundVolume = NotificationConfig.SoundVolume or 1

		if NotificationConfig.Sound ~= "" then
			local sound = Instance.new("Sound")
			sound.SoundId = NotificationConfig.Sound
			sound.Parent = LocalPlayer:FindFirstChild("Backpack")
			sound.Volume = NotificationConfig.SoundVolume
			sound:Play()
		end

		if OrionLib.NotificationSettings.Printing then
			print(string.format("[Orion] %s: %s", NotificationConfig.Name, NotificationConfig.Content))
		end
		if OrionLib.NotificationSettings.Enabled == false then return end

		local NotificationParent = SetProps(MakeElement("TFrame"), { Size = UDim2.new(0.9, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = NotificationHolder })
		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", NotificationConfig.Color, 0, 10), {
			Parent = NotificationParent, Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0), BackgroundTransparency = 0.15, AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Padding", 12, 12, 12, 12),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("Image", GetLucideIcon(NotificationConfig.Image) or "rbxassetid://4483362458"), {
				Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 0, 0.5, -9),
				ImageColor3 = NotificationConfig.TextColor, Name = "Icon", BackgroundTransparency = 1
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 30, 0, -4),
				Font = Enum.Font.GothamBold, Name = "Title", BackgroundTransparency = 1, TextColor3 = NotificationConfig.TextColor
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 13), {
				Size = NotificationConfig.Content == "" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, -30, 0, 6),
				Position = UDim2.new(0, 30, 0, 20), Font = Enum.Font.GothamSemibold,
				Name = "Content", AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = NotificationConfig.TextColor,
				TextWrapped = true, BackgroundTransparency = 1, Visible = NotificationConfig.Content ~= ""
			})
		})
		local TimerBar = SetProps(MakeElement("RoundFrame", Color3.fromRGB(180, 180, 180), 0, 8), {
			Size = UDim2.new(1, -35, 0, 2), Position = UDim2.new(0, 30, 0, NotificationFrame.AbsoluteSize.Y - 15),
			Name = "TimerBar", Parent = NotificationFrame
		})

		spawn(function()
			TweenService:Create(TimerBar, TweenInfo.new(NotificationConfig.Time - 1, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
			wait(NotificationConfig.Time - 1)
			TweenService:Create(TimerBar, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 0) }):Play()
			wait(0.3); TimerBar.Visible = false
		end)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 30, 0, 0) }):Play()
		wait(NotificationConfig.Time - 0.8)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(NotificationFrame.Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Transparency = 1 }):Play()
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		wait(0.55); NotificationParent:Destroy()
	end)
end

function OrionLib:SetNotifyingState(Config)
	OrionLib.NotificationSettings.Enabled = Config.Enabled
	OrionLib.NotificationSettings.Printing = Config.Printing
end

function OrionLib:MakeWindow(WindowConfig)
	local Val = { FirstTab = true, Minimized = false, UIHidden = false, Tab = "", TabholderSize = UDim2.new(0, 120, 0, 200) }

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Better Orion"
	WindowConfig.SubName = WindowConfig.SubName or ""
	WindowConfig.Size = WindowConfig.Size or UDim2.fromOffset(600, 400)
	WindowConfig.MinSize = WindowConfig.MinSize or UDim2.fromOffset(400, 200)
	WindowConfig.MaxSize = WindowConfig.MaxSize or UDim2.fromOffset(4000, 2000)
	WindowConfig.IntroEnabled = WindowConfig.IntroEnabled or false
	WindowConfig.IntroText = WindowConfig.IntroText or "Better Orion"
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = GetLucideIcon(WindowConfig.Icon) or ""
	WindowConfig.IntroIcon = GetLucideIcon(WindowConfig.IntroIcon) or ""
	WindowConfig.Transparency = WindowConfig.Transparency or 0.25
	WindowConfig.ToggleUIKey = WindowConfig.ToggleUIKey or Enum.KeyCode.Tab
	WindowConfig.SearchBar = WindowConfig.SearchBar or false
	WindowConfig.NewUI = WindowConfig.NewUI or false
	WindowConfig.BackgroundURL = WindowConfig.BackgroundURL or ""
	WindowConfig.BackgroundTransparency = tonumber(WindowConfig.BackgroundTransparency or 0.2)
	WindowConfig.Logo = WindowConfig.Logo or ""

	WindowConfig.WatermarkConfig = WindowConfig.WatermarkConfig or {}
	WindowConfig.WatermarkConfig.Enabled = WindowConfig.WatermarkConfig.Enabled or false
	WindowConfig.WatermarkConfig.Visible = WindowConfig.WatermarkConfig.Visible or false
	WindowConfig.WatermarkConfig.ShowFPS = WindowConfig.WatermarkConfig.ShowFPS or false
	WindowConfig.WatermarkConfig.ShowPing = WindowConfig.WatermarkConfig.ShowPing or false
	WindowConfig.WatermarkConfig.ShowName = WindowConfig.WatermarkConfig.ShowName or false
	WindowConfig.WatermarkConfig.ShowClockTime = WindowConfig.WatermarkConfig.ShowClockTime or false
	WindowConfig.WatermarkConfig.Icon = GetLucideIcon(WindowConfig.WatermarkConfig.Icon) or ""

	WindowConfig.FreeMouse = WindowConfig.FreeMouse or false

	OrionLib.BackgroundURL = WindowConfig.BackgroundURL
	OrionLib.BackgroundTransparency = WindowConfig.BackgroundTransparency

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Name = "TabHolder"
	}), { MakeElement("List"), MakeElement("Padding", 8, 0, 0, 8) }), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1 }), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), { Position = UDim2.new(0, 9, 0, 6), Size = UDim2.new(0, 18, 0, 18) }), "Text")
	})
	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), { Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1 }), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), { Position = UDim2.new(0, 9, 0, 6), Size = UDim2.new(0, 18, 0, 18), Name = "Ico" }), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })

	local function MakeHandle(name, size, position, anchor)
		local h = SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
			Size = size, Position = position, AnchorPoint = anchor,
			BackgroundTransparency = 0.75, Name = name, Active = true
		})
		h:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
		return h
	end

	local HandleRight = MakeHandle("HandleRight", UDim2.new(0, 5, 1, -30), UDim2.new(1, -2, 0, 15), Vector2.new(0, 0))
	local HandleLeft = MakeHandle("HandleLeft", UDim2.new(0, 5, 1, -30), UDim2.new(0, -2, 0, 15), Vector2.new(1, 0))
	local HandleTop = MakeHandle("HandleTop", UDim2.new(1, -30, 0, 5), UDim2.new(0, 15, 0, -2), Vector2.new(0, 1))
	local HandleBottom = MakeHandle("HandleBottom", UDim2.new(1, -30, 0, 5), UDim2.new(0, 15, 1, 2), Vector2.new(0, 0))
	local HandleCorner = MakeHandle("HandleCorner", UDim2.new(0, 14, 0, 14), UDim2.new(1, 3, 1, 3), Vector2.new(1, 1))
	HandleCorner.BackgroundTransparency = 0.55

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 12), {
		Size = UDim2.new(0, 130, 0, 300), Position = UDim2.new(0, 8, 0, 58),
		BackgroundTransparency = WindowConfig.Transparency, Name = "WindowStuff", Active = true
	}), { AddThemeObject(MakeElement("Stroke"), "Stroke"), TabHolder }), "Main")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 18), {
		Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.GothamBlack, Name = "WindowName", Text = WindowConfig.Name
	}), "Text")

	local WindowSubName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.SubName, 12), {
		Size = UDim2.new(1, -WindowName.TextBounds.X - 200, 1, 0),
		Position = UDim2.new(0, WindowName.TextBounds.X + 40, 0, 0),
		Font = Enum.Font.GothamSemibold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		Name = "WindowSubName", Text = WindowConfig.SubName
	}), "TextDark")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundTransparency = 1
	}), "Divider")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 14), {
		Parent = Orion,
		Position = UDim2.new(0.5, -WindowConfig.Size.X.Offset / 2, 0.5, -WindowConfig.Size.Y.Offset / 2),
		Size = WindowConfig.Size, BackgroundTransparency = 0.25, Name = "MainWindow", Visible = false
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
		AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 14), {
			Size = UDim2.new(1, 0, 0, 50), Name = "TopBar", BackgroundTransparency = 0.25, ClipsDescendants = true, Active = true
		}), {
			Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
			WindowTopBarLine,
			SetChildren(SetProps(MakeElement("TFrame"), { Size = UDim2.new(1, -100, 1, 0), Name = "WindowNames" }), { WindowName, WindowSubName }),
			(function()
				if WindowConfig.Logo ~= "" then
					return SetProps(MakeElement("Image", WindowConfig.Logo), {
						Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -170, 0.5, -14),
						AnchorPoint = Vector2.new(1, 0.5), Name = "TopBarLogo",
						ImageColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1
					})
				end
			end)(),
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 8), {
				Size = UDim2.new(0, 70, 0, 30), Position = UDim2.new(1, -80, 0, 10),
				BackgroundTransparency = 0.25, Name = "ButtonsFrame"
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				AddThemeObject(SetProps(Create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 0.5 }), {}), "Divider"),
				CloseBtn, MinimizeBtn
			}), "Elements")
		}), "Main"),
		DragPoint, WindowStuff,
		HandleRight, HandleLeft, HandleTop, HandleBottom, HandleCorner
	}), "Main")

	-- Dragging
	do
		local dragging, dragInput, mousePos, framePos = false
		DragPoint.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, mousePos, framePos = true, input.Position, MainWindow.Position
				input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
		DragPoint.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				MainWindow.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
	end

	-- Resize
	local function AddAxisResize(handle, main, mode)
		local dragging, dragInput, mousePos, frameSize, framePos = false
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, mousePos, frameSize, framePos = true, input.Position, main.Size, main.Position
				input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
		handle.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				local newSize, newPos = frameSize, framePos
				if mode == "right" or mode == "corner" then
					newSize = UDim2.new(frameSize.X.Scale, math.clamp(frameSize.X.Offset + delta.X, WindowConfig.MinSize.X.Offset, WindowConfig.MaxSize.X.Offset), newSize.Y.Scale, newSize.Y.Offset)
				end
				if mode == "left" then
					local newW = math.clamp(frameSize.X.Offset - delta.X, WindowConfig.MinSize.X.Offset, WindowConfig.MaxSize.X.Offset)
					newSize = UDim2.new(frameSize.X.Scale, newW, frameSize.Y.Scale, frameSize.Y.Offset)
					newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset)
				end
				if mode == "bottom" or mode == "corner" then
					newSize = UDim2.new(newSize.X.Scale, newSize.X.Offset, frameSize.Y.Scale, math.clamp(frameSize.Y.Offset + delta.Y, WindowConfig.MinSize.Y.Offset, WindowConfig.MaxSize.Y.Offset))
				end
				if mode == "top" then
					local newH = math.clamp(frameSize.Y.Offset - delta.Y, WindowConfig.MinSize.Y.Offset, WindowConfig.MaxSize.Y.Offset)
					newSize = UDim2.new(frameSize.X.Scale, frameSize.X.Offset, frameSize.Y.Scale, newH)
					newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
				end
				main.Size = newSize; main.Position = newPos; WindowConfig.Size = newSize
			end
		end)
	end
	AddAxisResize(HandleRight, MainWindow, "right")
	AddAxisResize(HandleLeft, MainWindow, "left")
	AddAxisResize(HandleTop, MainWindow, "top")
	AddAxisResize(HandleBottom, MainWindow, "bottom")
	AddAxisResize(HandleCorner, MainWindow, "corner")

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false; Val.UIHidden = true
		OrionLib:MakeNotification({ Name = "Interface Hidden", Content = "Tap " .. tostring(WindowConfig.ToggleUIKey):split(".")[3] .. " to reopen", Time = 3, Image = "activity" })
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == WindowConfig.ToggleUIKey then
			Val.UIHidden = not Val.UIHidden; MainWindow.Visible = not Val.UIHidden
		end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Val.Minimized then
			MainWindow:TweenSize(WindowConfig.Size, Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.3, true)
			WindowStuff.Visible = true
			HandleRight.Visible = true; HandleLeft.Visible = true; HandleTop.Visible = true
			HandleBottom.Visible = true; HandleCorner.Visible = true
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
		else
			WindowStuff.Visible = false
			HandleRight.Visible = false; HandleLeft.Visible = false; HandleTop.Visible = false
			HandleBottom.Visible = false; HandleCorner.Visible = false
			MainWindow:TweenSize(UDim2.new(0, WindowName.TextBounds.X + 200, 0, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.3, true)
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
		end
		Val.Minimized = not Val.Minimized
	end)

	local function LoadSequence()
		MainWindow.Visible = false
		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = Orion, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28), ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 1
		})
		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = Orion, Size = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0), TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold, TextTransparency = 1
		})
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
		wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X / 2), 0.5, 0) }):Play()
		wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
		wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		MainWindow.Visible = true
		LoadSequenceLogo:Destroy(); LoadSequenceText:Destroy()
	end
	if WindowConfig.IntroEnabled then LoadSequence() end

	local TabFunction = {}
	function TabFunction:SetSize(Size) MainWindow.Size = Size end

	function TabFunction:SetIconColor(Color)
		MainWindow.TopBar.WindowIcon.ImageColor3 = Color
		for _, Tab in next, TabHolder:GetChildren() do
			if Tab:IsA("TextButton") then Tab.Ico.ImageColor3 = Color end
		end
	end

	function TabFunction:SetColor(Color)
		MainWindow.BackgroundColor3 = Color; MainWindow.TopBar.BackgroundColor3 = Color; WindowStuff.BackgroundColor3 = Color
	end

	function TabFunction:SetStrokeColor(Color)
		MainWindow.TopBar.ButtonsFrame.Stroke.Color = Color
		MainWindow.TopBar.ButtonsFrame.Frame.BackgroundColor3 = Color
		if WindowConfig.WatermarkConfig.Enabled then WatermarkStroke.Color = Color end
	end

	function TabFunction:SetStrokeTransparency(Transparency)
		MainWindow.TopBar.ButtonsFrame.Stroke.Transparency = Transparency
		MainWindow.TopBar.ButtonsFrame.Frame.BackgroundTransparency = Transparency
	end

	function TabFunction:SetTextColor(Color)
		MainWindow.TopBar.WindowNames.WindowName.TextColor3 = Color
		MainWindow.TopBar.WindowNames.WindowSubName.TextColor3 = Color3.fromRGB(Color.R * 180, Color.G * 180, Color.B * 180)
		for _, Tab in next, TabHolder:GetChildren() do
			if Tab:IsA("TextButton") then Tab.Title.TextColor3 = Color end
		end
	end

	function TabFunction:SetTextTransparency(Transparency)
		MainWindow.TopBar.WindowNames.WindowName.TextTransparency = Transparency
		MainWindow.TopBar.WindowNames.WindowSubName.TextTransparency = Transparency
		for _, Tab in next, TabHolder:GetChildren() do
			if Tab:IsA("TextButton") then Tab.Title.TextTransparency = Transparency end
		end
	end

	function TabFunction:SetTransparency(Transparency)
		MainWindow.BackgroundTransparency = Transparency
		WindowConfig.Transparency = Transparency
	end

	function TabFunction:SetToggleKey(Key)
		WindowConfig.ToggleUIKey = Enum.KeyCode[Key] or Key
	end

	function TabFunction:DestroyElement(Flag)
		if OrionLib.Flags[Flag] ~= nil then OrionLib.Flags[Flag]:Destroy() end
	end

	function TabFunction:SetThemeColor(Theme, Element, ThemeColor)
		OrionLib.Themes[Theme][Element] = ThemeColor
	end

	function TabFunction:SetThemeTransparency(Theme, Element, Transparency)
		OrionLib.Themes[Theme][Element].Transparency = Transparency
	end

	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""
		Val.Tab = TabConfig.Name

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 32), Parent = TabHolder, Name = Val.Tab
		}), {
			AddThemeObject(SetProps(MakeElement("Image", GetLucideIcon(TabConfig.Icon)), {
				AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0), ImageTransparency = 0.4, Name = "Ico", ImageColor3 = Color3.fromRGB(255, 255, 255)
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0), Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold, TextTransparency = 0.4, TextWrapped = false,
				Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
			}), "Text")
		})

		local ContainerLeft = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
			Size = UDim2.new(0.5, -50, 1, -80), Position = UDim2.new(0, WindowStuff.AbsoluteSize.X + 30, 0, 70),
			Parent = MainWindow, Visible = false, Name = "ItemContainerLeft",
			ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180), ScrollBarImageTransparency = 0.35,
			ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
			AutomaticCanvasSize = Enum.AutomaticSize.Y
		}), { MakeElement("List", 0, 14), MakeElement("Padding", 22, 14, 14, 18) }), "Divider")
		ContainerLeft:SetAttribute("tab", Val.Tab)
		AddConnection(ContainerLeft.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			ContainerLeft.CanvasSize = UDim2.new(0, 0, 0, ContainerLeft.UIListLayout.AbsoluteContentSize.Y + 40)
		end)

		local ContainerRight = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
			Size = UDim2.new(0.5, -50, 1, -80), Position = UDim2.new(0.5, 25, 0, 70),
			Parent = MainWindow, Visible = false, Name = "ItemContainerRight",
			ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180), ScrollBarImageTransparency = 0.35,
			ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
			AutomaticCanvasSize = Enum.AutomaticSize.Y
		}), { MakeElement("List", 0, 14), MakeElement("Padding", 22, 14, 14, 18) }), "Divider")
		ContainerRight:SetAttribute("tab", Val.Tab)
		AddConnection(ContainerRight.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			ContainerRight.CanvasSize = UDim2.new(0, 0, 0, ContainerRight.UIListLayout.AbsoluteContentSize.Y + 40)
		end)

		if Val.FirstTab then
			Val.FirstTab = false
			TabFrame.Ico.ImageTransparency = 0; TabFrame.Title.TextTransparency = 0; TabFrame.Title.Font = Enum.Font.GothamBlack
			ContainerLeft.Visible = true; ContainerRight.Visible = true
		end

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { ImageTransparency = 0.4 }):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { TextTransparency = 0.4 }):Play()
				end
			end
			for _, c in next, MainWindow:GetChildren() do
				if c.Name == "ItemContainerLeft" or c.Name == "ItemContainerRight" then c.Visible = false end
			end
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { ImageTransparency = 0 }):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			ContainerLeft.Visible = true; ContainerRight.Visible = true
		end)

		local function GetElements(ItemParent)
			local ElementFunction = { Type = "ElementFunction" }

			local function AddElements(ItemParent2)
				function ItemParent2:AddLabel(Text)
					Text = Text or "Label"
					local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 34), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Label"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
							Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text")
					}), "Elements")

					local F = {}
					function F:Set(t) LabelFrame.Content.Text = t end
					function F:SetColor(c) LabelFrame.BackgroundColor3 = c end
					function F:SetTextColor(c) LabelFrame.Content.TextColor3 = c end
					function F:SetTransparency(t) LabelFrame.BackgroundTransparency = t end
					table.insert(OrionLib.UIElements, F)
					return F
				end

				function ItemParent2:AddParagraph(Text, Content)
					Text = Text or "Title"
					Content = Content or "Content"
					local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 56), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Paragraph"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
							Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 8),
							Font = Enum.Font.GothamBold, Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						AddThemeObject(SetProps(MakeElement("Label", Content, 13), {
							Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 30),
							Font = Enum.Font.GothamSemibold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(200, 200, 200)
						}), "TextDark")
					}), "Elements")

					local F = {}
					function F:Set(c) ParagraphFrame.Content.Text = c end
					table.insert(OrionLib.UIElements, F)
					return F
				end

				function ItemParent2:AddButton(ButtonConfig)
					ButtonConfig = ButtonConfig or {}
					ButtonConfig.Name = ButtonConfig.Name or "Button"
					ButtonConfig.Callback = ButtonConfig.Callback or function() end
					ButtonConfig.Icon = ButtonConfig.Icon or nil
					local Button, Tap, OldButtonName = {}, 0, ButtonConfig.Name
					local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })
					local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 40), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Button"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 14), {
							Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						(function()
							if ButtonConfig.Icon then
								return AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
									Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -30, 0.5, -9),
									ImageColor3 = Color3.fromRGB(255, 255, 255), Name = "Image"
								}), "TextDark")
							end
						end)(),
						Click
					}), "Elements")

					AddConnection(Click.MouseEnter, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play() end)
					AddConnection(Click.MouseLeave, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)
					AddConnection(Click.MouseButton1Up, function()
						Tap += 1
						if Tap == 2 and ButtonConfig.DoubleTap then
							ButtonConfig.Callback()
						elseif Tap == 1 and ButtonConfig.DoubleTap then
							ButtonFrame.Content.Text = "Are you sure?"
							task.wait(ButtonConfig.TapDelay)
							if Tap == 1 then Tap = 0; ButtonFrame.Content.Text = OldButtonName end
						elseif not ButtonConfig.DoubleTap then
							ButtonConfig.Callback()
						end
						Tap = 0; ButtonFrame.Content.Text = OldButtonName
					end)

					function Button:Set(t) ButtonFrame.Content.Text = t end
					function Button:SetColor(c) ButtonFrame.BackgroundColor3 = c end
					function Button:SetTextColor(c) ButtonFrame.Content.TextColor3 = c end
					function Button:SetTransparency(t) ButtonFrame.BackgroundTransparency = t end
					table.insert(OrionLib.UIElements, Button)
					return Button
				end

				function ItemParent2:AddToggle(ToggleConfig)
					ToggleConfig = ToggleConfig or {}
					ToggleConfig.Name = ToggleConfig.Name or "Toggle"
					ToggleConfig.Default = ToggleConfig.Default or false
					ToggleConfig.Callback = ToggleConfig.Callback or function() end
					ToggleConfig.Flag = ToggleConfig.Flag or nil
					local Toggle = { Value = ToggleConfig.Default, Type = "Toggle", Name = ToggleConfig.Name }
					local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })
					local Box = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 6), {
						Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0.5, -12), BackgroundTransparency = 0.5
					}), {
						MakeElement("Stroke", Color3.fromRGB(200, 200, 200), 1.2),
						SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
							Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.new(0.5, 0, 0.5, 0), ImageColor3 = Color3.fromRGB(255, 255, 255),
							ImageTransparency = 1, Name = "Ico"
						})
					})
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Toggle"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 14), {
							Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						Box, Click
					}), "Elements")

					function Toggle:Set(v)
						Toggle.Value = v
						TweenService:Create(Box.Stroke, TweenInfo.new(0.2), { Transparency = v and 0 or 0.5 }):Play()
						TweenService:Create(Box, TweenInfo.new(0.2), { BackgroundTransparency = v and 0.0 or 0.5 }):Play()
						TweenService:Create(Box.Ico, TweenInfo.new(0.2), { ImageTransparency = v and 0 or 1 }):Play()
						ToggleConfig.Callback(v)
					end
					AddConnection(Click.MouseButton1Up, function() Toggle:Set(not Toggle.Value) end)
					AddConnection(Click.MouseEnter, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play() end)
					AddConnection(Click.MouseLeave, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)
					Toggle:Set(ToggleConfig.Default)
					if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end
					table.insert(OrionLib.UIElements, Toggle)
					return Toggle
				end

				function ItemParent2:AddSlider(SliderConfig)
					SliderConfig = SliderConfig or {}
					SliderConfig.Name = SliderConfig.Name or "Slider"
					SliderConfig.Min = SliderConfig.Min or 0
					SliderConfig.Max = SliderConfig.Max or 100
					SliderConfig.Increment = SliderConfig.Increment or 1
					SliderConfig.Default = SliderConfig.Default or 50
					SliderConfig.Callback = SliderConfig.Callback or function() end
					local Slider = { Value = SliderConfig.Default, Type = "Slider" }
					local Dragging = false
					local Bar = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 8), {
						Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 12, 0, 38), BackgroundTransparency = 0.5
					}), {
						MakeElement("Stroke", Color3.fromRGB(200, 200, 200), 1),
						AddThemeObject(SetProps(MakeElement("Label", "0", 12), {
							Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Value", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						(function()
							local fill = MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6)
							fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundTransparency = 0.7
							return fill
						end)()
					})
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 74), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Slider"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 14), {
							Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 10),
							Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						Bar
					}), "Elements")

					local function SetValue(v)
						v = math.clamp(Round(v, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
						Slider.Value = v
						local pct = (v - SliderConfig.Min) / math.max(SliderConfig.Max - SliderConfig.Min, 0.0001)
						TweenService:Create(Bar.Fill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
						Bar.Value.Text = tostring(v)
						SliderConfig.Callback(v)
					end
					Bar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							local pct = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
							SetValue(SliderConfig.Min + (SliderConfig.Max - SliderConfig.Min) * pct)
						end
					end)
					function Slider:Set(v) SetValue(v) end
					SetValue(SliderConfig.Default)
					table.insert(OrionLib.UIElements, Slider)
					return Slider
				end

				function ItemParent2:AddDropdown(DropdownConfig)
					DropdownConfig = DropdownConfig or {}
					DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
					DropdownConfig.Options = DropdownConfig.Options or {}
					DropdownConfig.Default = DropdownConfig.Default or ""
					DropdownConfig.Callback = DropdownConfig.Callback or function() end
					DropdownConfig.MaxSize = DropdownConfig.MaxSize or 6
					local Dropdown = { Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown" }
					local List = SetProps(MakeElement("List"), { HorizontalAlignment = Enum.HorizontalAlignment.Center })
					local Container = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(180, 180, 180)), { List }), {
						Parent = ItemParent, Position = UDim2.new(0, 0, 0, 42), Size = UDim2.new(1, 0, 1, -42),
						ClipsDescendants = true, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180),
						ScrollBarImageTransparency = 0.4
					}), "Divider")
					local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, ClipsDescendants = true, BackgroundTransparency = 0.2, Name = "Dropdown"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						Container,
						SetProps(SetChildren(MakeElement("TFrame"), {
							AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 14), {
								Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 12, 0, 0),
								Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
							}), "Text"),
							AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
								Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -30, 0.5, -9),
								ImageColor3 = Color3.fromRGB(255, 255, 255), Name = "Ico"
							}), "TextDark"),
							Click
						}), { Size = UDim2.new(1, 0, 0, 42), Name = "F" })
					}), "Elements")

					AddConnection(List:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						Container.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y)
					end)

					local function AddOptions(options)
						for _, opt in ipairs(options) do
							local btn = AddThemeObject(SetProps(SetChildren(MakeElement("Button"), {
								MakeElement("Corner", 0, 6),
								AddThemeObject(SetProps(MakeElement("Label", opt, 13), {
									Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0),
									Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
								}), "Text")
							}), { Parent = Container, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ClipsDescendants = true }), "Divider")
							AddConnection(btn.MouseButton1Click, function()
								Dropdown.Value = opt
								Frame.F.Content.Text = DropdownConfig.Name .. ": " .. opt
								DropdownConfig.Callback(opt)
							end)
							Dropdown.Buttons[opt] = btn
						end
					end

					AddConnection(Click.MouseButton1Click, function()
						Dropdown.Toggled = not Dropdown.Toggled
						local targetSize = Dropdown.Toggled and UDim2.new(1, 0, 0, 42 + math.min(#DropdownConfig.Options, DropdownConfig.MaxSize) * 28) or UDim2.new(1, 0, 0, 42)
						TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = targetSize }):Play()
					end)
					AddOptions(DropdownConfig.Options)
					if Dropdown.Options[1] then Frame.F.Content.Text = DropdownConfig.Name .. ": " .. DropdownConfig.Default end
					function Dropdown:Refresh(opts, delete)
						if delete then for _, b in pairs(Dropdown.Buttons) do b:Destroy() end; Dropdown.Buttons = {}; Dropdown.Options = {} end
						Dropdown.Options = opts or {}; AddOptions(Dropdown.Options)
					end
					function Dropdown:Set(v)
						Dropdown.Value = v; Frame.F.Content.Text = DropdownConfig.Name .. ": " .. v; DropdownConfig.Callback(v)
					end
					table.insert(OrionLib.UIElements, Dropdown)
					return Dropdown
				end

				function ItemParent2:AddBind(BindConfig)
					BindConfig = BindConfig or {}
					BindConfig.Name = BindConfig.Name or "Bind"
					BindConfig.Default = BindConfig.Default or ""
					BindConfig.Callback = BindConfig.Callback or function() end
					local Bind = { Value = BindConfig.Default, Binding = false, Type = "Bind" }
					local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })
					local ClickBind = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), ZIndex = 2 })
					local BindBox = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 6), {
						Size = UDim2.new(0, 34, 0, 24), Position = UDim2.new(1, -46, 0.5, -12), BackgroundTransparency = 0.5
					}), {
						MakeElement("Stroke", Color3.fromRGB(200, 200, 200), 1.2),
						AddThemeObject(SetProps(MakeElement("Label", BindConfig.Default, 12), {
							Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Center, Name = "Value", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						ClickBind
					})
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Bind"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
							Size = UDim2.new(1, -55, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						BindBox, Click
					}), "Elements")

					AddConnection(ClickBind.InputEnded, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if Bind.Binding then return end
							Bind.Binding = true; BindBox.Value.Text = ""
						end
					end)
					AddConnection(UserInputService.InputBegan, function(input)
						if UserInputService:GetFocusedTextBox() then return end
						if Bind.Binding then
							if input.KeyCode == Enum.KeyCode.Backspace then Bind.Value = ""; BindBox.Value.Text = ""; Bind.Binding = false; return end
							local k = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
							if k then Bind.Value = k.Name; BindBox.Value.Text = k.Name end
							Bind.Binding = false
						else
							if Bind.Value ~= "" and (input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value) then BindConfig.Callback() end
						end
					end)
					function Bind:Set(k)
						if k == nil or k == "" then Bind.Value = ""; BindBox.Value.Text = ""; return end
						Bind.Value = typeof(k) == "string" and k or k.Name
						BindBox.Value.Text = Bind.Value
					end
					table.insert(OrionLib.UIElements, Bind)
					return Bind
				end

				function ItemParent2:AddTextbox(TextboxConfig)
					TextboxConfig = TextboxConfig or {}
					TextboxConfig.Name = TextboxConfig.Name or "Textbox"
					TextboxConfig.Default = TextboxConfig.Default or ""
					TextboxConfig.Callback = TextboxConfig.Callback or function() end
					TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
					local Textbox = { Value = TextboxConfig.Default, Type = "Textbox" }
					local box = Create("TextBox", {
						Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12),
						BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						TextColor3 = Color3.fromRGB(255, 255, 255), PlaceholderColor3 = Color3.fromRGB(180, 180, 180),
						PlaceholderText = "Input", Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Center, TextSize = 13, ClearTextOnFocus = false, Text = TextboxConfig.Default
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 6) }).Parent = box
					Create("UIStroke", { Color = Color3.fromRGB(200, 200, 200), Thickness = 1, Transparency = 0.25 }).Parent = box
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Textbox"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 14), {
							Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						box
					}), "Elements")
					AddConnection(box.FocusLost, function()
						TextboxConfig.Callback(box.Text); if TextboxConfig.TextDisappear then box.Text = "" end
					end)
					function Textbox:Set(t) box.Text = t end
					table.insert(OrionLib.UIElements, Textbox)
					return Textbox
				end

				function ItemParent2:AddColorpicker(ColorpickerConfig)
					ColorpickerConfig = ColorpickerConfig or {}
					ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
					ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
					ColorpickerConfig.DefaultTransparency = ColorpickerConfig.DefaultTransparency or 0
					ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
					local Colorpicker = { Value = ColorpickerConfig.Default, TransparencyValue = ColorpickerConfig.DefaultTransparency, Type = "Colorpicker" }
					local Box = SetChildren(SetProps(MakeElement("RoundFrame", ColorpickerConfig.Default, 0, 6), {
						Size = UDim2.new(0, 34, 0, 20), Position = UDim2.new(1, -46, 0.5, -10),
						BackgroundTransparency = ColorpickerConfig.DefaultTransparency
					}), { MakeElement("Stroke", Color3.fromRGB(200, 200, 200), 1.2) })
					local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
						Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Colorpicker"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 14), {
							Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
						}), "Text"),
						Box
					}), "Elements")
					function Colorpicker:Set(color, transp)
						Colorpicker.Value = color; Colorpicker.TransparencyValue = transp or 0
						Box.BackgroundColor3 = color; Box.BackgroundTransparency = transp or 0
						ColorpickerConfig.Callback(color, transp or 0)
					end
					table.insert(OrionLib.UIElements, Colorpicker)
					return Colorpicker
				end

				return ItemParent2
			end

			AddElements(ElementFunction)
			return ElementFunction
		end

		local ElementFunction = { Type = "ElementFunction", Name = TabConfig.Name }
		function ElementFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name = SectionConfig.Name or "Section"
			SectionConfig.Side = SectionConfig.Side or "Left"

			local ContainerSection = (SectionConfig.Side == "Left") and ContainerLeft or ContainerRight

			-- SECTION BOX: card visual com stroke, título dentro, holder com gap
			local SectionFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(35, 35, 35), 0, 12), {
				Size = UDim2.new(1, 0, 0, 0),
				Parent = ContainerSection,
				BackgroundTransparency = 0.25,
				Name = "Section",
				AutomaticSize = Enum.AutomaticSize.Y
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Padding", 12, 12, 12, 12),
				SetChildren(SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 0),
					Name = "SectionLayout",
					AutomaticSize = Enum.AutomaticSize.Y
				}), {
					MakeElement("List", 0, 10)
				})
			}), "Elements")

			local Layout = SectionFrame:FindFirstChild("SectionLayout")

			local SectionTitle = AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = 0,
				Font = Enum.Font.GothamBlack,
				Name = "SectionTitle",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1
			}), "Text")
			SectionTitle.Parent = Layout

			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1, BorderSizePixel = 0,
				LayoutOrder = 1, Parent = Layout, Name = "Holder",
				AutomaticSize = Enum.AutomaticSize.Y
			})
			MakeElement("List", 0, 8).Parent = Holder

			local SectionFunction = {}
			for i, v in next, GetElements(Holder) do SectionFunction[i] = v end
			return SectionFunction
		end

		OrionLib.Tabs[TabConfig.Name] = ElementFunction
		return ElementFunction
	end

	OrionLib.Window = TabFunction
	return TabFunction
end

function OrionLib:SetConfigTab(TabName)
	local Pass = true
	if not writefile or not isfile or not listfiles or not readfile or not isfolder or not makefolder or not getcustomasset then
		Pass = false
	end
	if OrionLib.Tabs[TabName] ~= nil and Pass then
		local OrionTab = OrionLib.Tabs[TabName]
		local FolderName = OrionLib.ScriptFolder
		local SelectedConfig = ""

		local section = OrionTab:AddSection({ Name = "Config", Side = "Right" })
		section:AddTextbox({ Name = "Config Name", Callback = function(t) SelectedConfig = t end })
		section:AddButton({
			Name = "Save Config",
			Callback = function()
				if SelectedConfig == "" then return end
				local data = {}
				for name, flag in pairs(OrionLib.Flags) do
					if typeof(flag) == "table" and flag.Value ~= nil then data[name] = { Value = flag.Value } end
				end
				if not isfolder(FolderName .. "/Config/" .. OrionLib.GameName) then makefolder(FolderName .. "/Config/" .. OrionLib.GameName) end
				writefile(FolderName .. "/Config/" .. OrionLib.GameName .. "/" .. SelectedConfig .. ".json", HttpService:JSONEncode(data))
				OrionLib:MakeNotification({ Name = "Config", Content = "Saved: " .. SelectedConfig, Time = 3 })
			end
		})
		section:AddButton({
			Name = "Load Config",
			Callback = function()
				if SelectedConfig == "" then return end
				local path = FolderName .. "/Config/" .. OrionLib.GameName .. "/" .. SelectedConfig .. ".json"
				if not isfile(path) then OrionLib:MakeNotification({ Name = "Config", Content = "Not found", Time = 3 }); return end
				local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
				if not ok then return end
				for name, val in pairs(data) do
					local flag = OrionLib.Flags[name]
					if flag and flag.Set and typeof(val) == "table" then pcall(function() flag:Set(val.Value) end) end
				end
				OrionLib:MakeNotification({ Name = "Config", Content = "Loaded: " .. SelectedConfig, Time = 3 })
			end
		})
		section:AddButton({
			Name = "Delete Config",
			Callback = function()
				if SelectedConfig == "" then return end
				local path = FolderName .. "/Config/" .. OrionLib.GameName .. "/" .. SelectedConfig .. ".json"
				if isfile(path) then delfile(path) end
				OrionLib:MakeNotification({ Name = "Config", Content = "Deleted: " .. SelectedConfig, Time = 3 })
			end
		})
	end
end

function OrionLib:Init()
	local w = game.CoreGui:FindFirstChild("BetterOrion")
	if w and w:FindFirstChild("MainWindow") then w.MainWindow.Visible = true end
end

function OrionLib:Destroy() Orion:Destroy() end

return OrionLib
