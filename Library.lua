-- OrionLib — custom build
-- Dark gray, rounded, soft white strokes, topbar logo, resize handles
-- Author: ANON for dj

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

local OrionLib = {
    Elements = {}, UIElements = {}, ThemeObjects = {}, Connections = {}, Flags = {}, Tabs = {},
    Themes = {
        Default = {
            Main    = { Color = Color3.fromRGB(30, 30, 30),    Transparency = 0.25 },
            Stroke  = { Color = Color3.fromRGB(180, 180, 180), Transparency = 0.45 },
            Divider = { Color = Color3.fromRGB(180, 180, 180), Transparency = 0.85 },
            Text    = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
            TextDark= { Color = Color3.fromRGB(200, 200, 200), Transparency = 0 },
            Elements= { Color = Color3.fromRGB(45, 45, 45),    Transparency = 0.2 }
        }
    },
    NotificationSettings = { Enabled = true, Printing = true },
    BackgroundConfig = { EnabledBackground = false, BackgroundName = "", BackgroundTransparency = 0.2 },
    SelectedTheme = "Default",
    ScriptFolder = "OrionLib",
    GameName = tostring(game.PlaceId),
    Window = nil,
}

-- ICONS
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

local function NormalizeIcon(name)
    if type(name) ~= "string" then return nil end
    local n = string.lower(name):gsub("^lucide%-", ""):gsub("%s+", "")
    return n
end

local function ResolveIconData(data)
    if typeof(data) ~= "table" then return data end
    if data.Url then return data end
    if data.id then
        return {
            Url = typeof(data.id) == "number" and ("rbxassetid://" .. tostring(data.id)) or tostring(data.id),
            ImageRectOffset = data.imageRectOffset or Vector2.zero,
            ImageRectSize   = data.imageRectSize or Vector2.new(24, 24)
        }
    end
    return data
end

local function GetIcon(icon)
    if icon == nil then return nil end
    if typeof(icon) == "table" then return ResolveIconData(icon) end
    local n = NormalizeIcon(icon); if not n then return nil end
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

-- CORE
local Orion = Instance.new("ScreenGui")
Orion.Name = "OrionLib"
if syn and syn.protect_gui then pcall(function() syn.protect_gui(Orion) end) end
Orion.Parent = game.CoreGui

function OrionLib:IsRunning() return Orion.Parent == game.CoreGui end

-- HELPERS
local function Create(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = obj end
    return obj
end
local function SetProps(obj, props) for k, v in pairs(props or {}) do obj[k] = v end return obj end
local function SetChildren(obj, children) for _, c in ipairs(children or {}) do c.Parent = obj end return obj end

local function AddConnection(signal, fn)
    if not OrionLib:IsRunning() then return end
    local conn = signal:Connect(fn)
    table.insert(OrionLib.Connections, conn)
    return conn
end

task.spawn(function()
    while OrionLib:IsRunning() do task.wait() end
    for _, c in ipairs(OrionLib.Connections) do pcall(function() c:Disconnect() end) end
end)

local function Round(num, factor)
    num = tonumber(num) or 0
    local sign = num >= 0 and 1 or -1
    local r = math.floor(num / factor + 0.5 * sign) * factor
    if r < 0 then r = r + factor end
    if factor < 1 then
        local str = tostring(factor)
        local dot = str:find("%.")
        local prec = dot and #str - dot or 0
        r = tonumber(string.format("%." .. prec .. "f", r))
    end
    return r
end

local function ReturnProperty(obj, t)
    if obj:IsA("Frame") or obj:IsA("TextButton") then return (t == "Color" and "BackgroundColor3") or "BackgroundTransparency" end
    if obj:IsA("ScrollingFrame") then return (t == "Color" and "ScrollBarImageColor3") or "ScrollBarImageTransparency" end
    if obj:IsA("UIStroke") then return (t == "Color" and "Color") or "Transparency" end
    if obj:IsA("TextLabel") or obj:IsA("TextBox") then return (t == "Color" and "TextColor3") or "TextTransparency" end
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then return (t == "Color" and "ImageColor3") or "ImageTransparency" end
end

local function AddThemeObject(obj, t)
    if not OrionLib.ThemeObjects[t] then OrionLib.ThemeObjects[t] = {} end
    table.insert(OrionLib.ThemeObjects[t], obj)
    local theme = OrionLib.Themes[OrionLib.SelectedTheme][t]
    obj[ReturnProperty(obj, "Color")] = theme.Color
    obj[ReturnProperty(obj, "Transparency")] = theme.Transparency
    return obj
end

-- ELEMENT BUILDERS
local Elements = {}
local function DefineElement(name, fn) Elements[name] = function(...) return fn(...) end end
local function Make(name, ...) return Elements[name](...) end

DefineElement("Corner", function(scale, offset) return Create("UICorner", { CornerRadius = UDim.new(scale or 0, offset or 10) }) end)
DefineElement("Stroke", function(color, thickness, transparency)
    return Create("UIStroke", { Color = color or Color3.fromRGB(180, 180, 180), Thickness = thickness or 1, Transparency = transparency or 0.45, Name = "Stroke" })
end)
DefineElement("List", function(scale, offset)
    return Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(scale or 0, offset or 0) })
end)
DefineElement("Padding", function(bottom, left, right, top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, bottom or 4), PaddingLeft = UDim.new(0, left or 4),
        PaddingRight = UDim.new(0, right or 4), PaddingTop = UDim.new(0, top or 4)
    })
end)
DefineElement("TFrame", function() return Create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0 }) end)
DefineElement("RoundFrame", function(color, scale, offset)
    local f = Create("Frame", { BackgroundColor3 = color or Color3.fromRGB(30, 30, 30), BorderSizePixel = 0 })
    Create("UICorner", { CornerRadius = UDim.new(scale or 0, offset or 10) }).Parent = f
    return f
end)
DefineElement("Button", function()
    return Create("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0 })
end)
DefineElement("ScrollFrame", function(color)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1, MidImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = color or Color3.fromRGB(180, 180, 180), ScrollBarImageTransparency = 0.35, ScrollBarThickness = 4,
        BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0)
    })
end)

local function ApplyIcon(obj, icon)
    local resolved = GetIcon(icon)
    if type(resolved) == "table" and resolved.Url then
        obj.Image = resolved.Url
        obj.ImageRectOffset = resolved.ImageRectOffset or Vector2.zero
        obj.ImageRectSize   = resolved.ImageRectSize or Vector2.new(24, 24)
    elseif resolved ~= nil then
        obj.Image = resolved
        obj.ImageRectOffset = Vector2.zero
        obj.ImageRectSize   = Vector2.new(0, 0)
    elseif icon ~= nil then
        obj.Image = icon
    end
    return obj
end

DefineElement("Image", function(icon) local img = Create("ImageLabel", { BackgroundTransparency = 1 }); return ApplyIcon(img, icon) end)
DefineElement("Label", function(text, size, transparency)
    return Create("TextLabel", {
        Text = text or "", TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = transparency or 0,
        TextSize = size or 15, Font = Enum.Font.Gotham, RichText = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- NOTIFICATIONS
local NotificationHolder = SetProps(SetChildren(Make("TFrame"), {
    SetProps(Make("List"), { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.Name, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5) })
}), { Position = UDim2.new(1, -25, 1, -25), Size = UDim2.new(0, 300, 1, -25), AnchorPoint = Vector2.new(1, 1), Parent = Orion, Name = "NotificationList" })

function OrionLib:MakeNotification(cfg)
    spawn(function()
        cfg = cfg or {}
        cfg.Name = cfg.Name or "Notification"; cfg.Content = cfg.Content or ""; cfg.Image = cfg.Image or "bell"; cfg.Time = cfg.Time or 5
        local icon = GetIcon(cfg.Image); local iconUrl = type(icon) == "table" and icon.Url or nil
        if OrionLib.NotificationSettings.Printing then print(string.format("[Orion] %s: %s", cfg.Name, cfg.Content)) end
        if OrionLib.NotificationSettings.Enabled == false then return end

        local parent = SetProps(Make("TFrame"), { Size = UDim2.new(0.9, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = NotificationHolder })
        local frame = SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 10), {
            Parent = parent, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(1, -55, 0, 0), BackgroundTransparency = 0.15, AutomaticSize = Enum.AutomaticSize.Y
        }), {
            Make("Padding", 12, 12, 12, 12),
            Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
            SetProps(Make("Image", iconUrl or "rbxassetid://4483362458"), { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 0, 0.5, -9), ImageColor3 = Color3.fromRGB(255, 255, 255), Name = "Icon", BackgroundTransparency = 1 }),
            SetProps(Make("Label", cfg.Name, 15), { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 30, 0, -4), Font = Enum.Font.GothamBold, Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255) }),
            SetProps(Make("Label", cfg.Content, 13), { Size = cfg.Content == "" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 30, 0, 20), Font = Enum.Font.GothamSemibold, Name = "Content", AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, Visible = cfg.Content ~= "", TextColor3 = Color3.fromRGB(220, 220, 220) })
        })
        local timer = SetProps(Make("RoundFrame", Color3.fromRGB(180, 180, 180), 0, 8), { Size = UDim2.new(1, -35, 0, 2), Position = UDim2.new(0, 30, 0, frame.AbsoluteSize.Y - 15), Name = "TimerBar", Parent = frame })
        spawn(function()
            TweenService:Create(timer, TweenInfo.new(cfg.Time - 1, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
            wait(cfg.Time - 1)
            TweenService:Create(timer, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 0) }):Play()
            wait(0.3); timer.Visible = false
        end)
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 30, 0, 0) }):Play()
        wait(cfg.Time - 0.8)
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(frame.Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Transparency = 1 }):Play()
        TweenService:Create(frame.Icon, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
        TweenService:Create(frame.Title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        TweenService:Create(frame.Content, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        wait(0.55); parent:Destroy()
    end)
end

function OrionLib:SetNotifyingState(cfg)
    OrionLib.NotificationSettings.Enabled = cfg.Enabled
    OrionLib.NotificationSettings.Printing = cfg.Printing
end

-- WINDOW
function OrionLib:MakeWindow(WindowConfig)
    local Val = { FirstTab = true, Minimized = false, UIHidden = false, Tab = "" }

    WindowConfig = WindowConfig or {}
    WindowConfig.Name         = WindowConfig.Name         or "Orion"
    WindowConfig.SubName      = WindowConfig.SubName      or ""
    WindowConfig.Size         = WindowConfig.Size         or UDim2.fromOffset(600, 400)
    WindowConfig.MinSize      = WindowConfig.MinSize      or UDim2.fromOffset(420, 240)
    WindowConfig.MaxSize      = WindowConfig.MaxSize      or UDim2.fromOffset(4000, 2000)
    WindowConfig.Transparency = WindowConfig.Transparency or 0.25
    WindowConfig.ToggleUIKey  = WindowConfig.ToggleUIKey  or Enum.KeyCode.RightShift
    WindowConfig.Logo         = WindowConfig.Logo         or ""
    WindowConfig.IntroEnabled = WindowConfig.IntroEnabled or false
    WindowConfig.IntroText    = WindowConfig.IntroText    or WindowConfig.Name
    WindowConfig.IntroIcon    = GetIcon(WindowConfig.IntroIcon)

    -- Sidebar tabs
    local TabHolder = AddThemeObject(SetChildren(SetProps(Make("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Name = "TabHolder"
    }), { Make("List"), Make("Padding", 8, 6, 6, 8) }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local CloseBtn = SetChildren(SetProps(Make("Button"), { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1 }), {
        AddThemeObject(SetProps(Make("Image", "rbxassetid://7072725342"), { Position = UDim2.new(0, 9, 0, 8), Size = UDim2.new(0, 16, 0, 16), ImageColor3 = Color3.fromRGB(255, 255, 255) }), "Text")
    })
    local MinimizeBtn = SetChildren(SetProps(Make("Button"), { Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1 }), {
        AddThemeObject(SetProps(Make("Image", "rbxassetid://7072719338"), { Position = UDim2.new(0, 9, 0, 8), Size = UDim2.new(0, 16, 0, 16), ImageColor3 = Color3.fromRGB(255, 255, 255), Name = "Ico" }), "Text")
    })

    local DragPoint = SetProps(Make("TFrame"), { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })

    local function MakeHandle(name, size, position, anchor)
        local h = SetProps(Make("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
            Size = size, Position = position, AnchorPoint = anchor,
            BackgroundTransparency = 0.75, Name = name, Active = true
        })
        h:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
        return h
    end

    local HandleRight  = MakeHandle("HandleRight",  UDim2.new(0, 5, 1, -30),  UDim2.new(1, -2, 0, 15),   Vector2.new(0, 0))
    local HandleLeft   = MakeHandle("HandleLeft",   UDim2.new(0, 5, 1, -30),  UDim2.new(0, -2, 0, 15),   Vector2.new(1, 0))
    local HandleTop    = MakeHandle("HandleTop",    UDim2.new(1, -30, 0, 5),  UDim2.new(0, 15, 0, -2),   Vector2.new(0, 1))
    local HandleBottom = MakeHandle("HandleBottom", UDim2.new(1, -30, 0, 5),  UDim2.new(0, 15, 1, 2),    Vector2.new(0, 0))
    local HandleCorner = MakeHandle("HandleCorner", UDim2.new(0, 14, 0, 14),  UDim2.new(1, 3, 1, 3),     Vector2.new(1, 1))
    HandleCorner.BackgroundTransparency = 0.55

    local WindowStuff = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 12), {
        Size = UDim2.new(0, 130, 0, 300), Position = UDim2.new(0, 8, 0, 58),
        BackgroundTransparency = WindowConfig.Transparency, Name = "WindowStuff", Active = true
    }), { Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45), TabHolder }), "Main")

    local WindowName = AddThemeObject(SetProps(Make("Label", WindowConfig.Name, 18), {
        Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 20, 0, 0),
        Font = Enum.Font.GothamBlack, Name = "WindowName", Text = WindowConfig.Name
    }), "Text")

    local WindowSubName = AddThemeObject(SetProps(Make("Label", WindowConfig.SubName, 12), {
        Size = UDim2.new(1, -WindowName.TextBounds.X - 200, 1, 0),
        Position = UDim2.new(0, WindowName.TextBounds.X + 40, 0, 0),
        Font = Enum.Font.GothamSemibold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        Name = "WindowSubName", Text = WindowConfig.SubName
    }), "TextDark")

    local WindowTopBarLine = AddThemeObject(SetProps(Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundTransparency = 1
    }), {}), "Divider")

    local MainWindow = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 14), {
        Parent = Orion, Position = UDim2.new(0.5, -WindowConfig.Size.X.Offset / 2, 0.5, -WindowConfig.Size.Y.Offset / 2),
        Size = WindowConfig.Size, BackgroundTransparency = 0.25, Name = "MainWindow", Visible = false
    }), {
        Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
        AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 14), {
            Size = UDim2.new(1, 0, 0, 50), Name = "TopBar", BackgroundTransparency = 0.25, ClipsDescendants = true, Active = true
        }), {
            Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
            WindowTopBarLine,
            SetChildren(SetProps(Make("TFrame"), { Size = UDim2.new(1, -100, 1, 0), Name = "WindowNames" }), { WindowName, WindowSubName }),
            (function()
                if WindowConfig.Logo ~= "" then
                    return SetProps(Make("Image", WindowConfig.Logo), {
                        Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -170, 0.5, -14),
                        AnchorPoint = Vector2.new(1, 0.5), Name = "TopBarLogo",
                        ImageColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1
                    })
                end
            end)(),
            AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(30, 30, 30), 0, 8), {
                Size = UDim2.new(0, 70, 0, 30), Position = UDim2.new(1, -80, 0, 10),
                BackgroundTransparency = 0.25, Name = "ButtonsFrame"
            }), {
                Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
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

    AddConnection(UserInputService.InputBegan, function(input)
        if input.KeyCode == WindowConfig.ToggleUIKey then
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
        local logo = SetProps(Make("Image", WindowConfig.IntroIcon), {
            Parent = Orion, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 30, 0, 30), ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 1
        })
        local text = SetProps(Make("Label", WindowConfig.IntroText, 14), {
            Parent = Orion, Size = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 40, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextTransparency = 1
        })
        TweenService:Create(logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { ImageTransparency = 0 }):Play()
        wait(0.8)
        TweenService:Create(logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -(text.TextBounds.X / 2), 0.5, 0) }):Play()
        wait(0.3)
        TweenService:Create(text, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
        wait(1.5)
        TweenService:Create(text, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
        MainWindow.Visible = true; logo:Destroy(); text:Destroy()
    end
    if WindowConfig.IntroEnabled then task.spawn(LoadSequence) end

    local TabFunction = {}
    function TabFunction:SetSize(size) MainWindow.Size = size end
    function TabFunction:SetColor(color)
        MainWindow.BackgroundColor3 = color; MainWindow.TopBar.BackgroundColor3 = color; WindowStuff.BackgroundColor3 = color
    end
    function TabFunction:SetToggleKey(key) WindowConfig.ToggleUIKey = Enum.KeyCode[key] or key end
    function TabFunction:DestroyElement(flag) if OrionLib.Flags[flag] then OrionLib.Flags[flag]:Destroy() end end

    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        Val.Tab = TabConfig.Name

        -- Tab button
        local TabFrame = SetChildren(SetProps(Make("Button"), { Size = UDim2.new(1, 0, 0, 32), Parent = TabHolder, Name = Val.Tab }), {
            AddThemeObject(SetProps(Make("Image", GetIcon(TabConfig.Icon)), {
                AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 10, 0.5, 0),
                ImageTransparency = 0.4, Name = "Ico", ImageColor3 = Color3.fromRGB(255, 255, 255)
            }), "Text"),
            AddThemeObject(SetProps(Make("Label", TabConfig.Name, 14), {
                Size = UDim2.new(1, -35, 1, 0), Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.GothamSemibold, TextTransparency = 0.4, Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
            }), "Text")
        })

        -- Containers
                local ContainerLeft = AddThemeObject(SetChildren(SetProps(Make("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
            Size = UDim2.new(0.5, -50, 1, -80), Position = UDim2.new(0, WindowStuff.AbsoluteSize.X + 30, 0, 70),
            Parent = MainWindow, Visible = false, Name = "ItemContainerLeft",
            ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180), ScrollBarImageTransparency = 0.35,
            ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }), { Make("List", 0, 20), Make("Padding", 22, 14, 14, 18) }), "Divider")
        ContainerLeft:SetAttribute("tab", Val.Tab)

        local ContainerRight = AddThemeObject(SetChildren(SetProps(Make("ScrollFrame", Color3.fromRGB(180, 180, 180)), {
            Size = UDim2.new(0.5, -50, 1, -80), Position = UDim2.new(0.5, 25, 0, 70),
            Parent = MainWindow, Visible = false, Name = "ItemContainerRight",
            ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180), ScrollBarImageTransparency = 0.35,
            ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }), { Make("List", 0, 20), Make("Padding", 22, 14, 14, 18) }), "Divider")
        ContainerRight:SetAttribute("tab", Val.Tab)

        if Val.FirstTab then
            Val.FirstTab = false
            TabFrame.Ico.ImageTransparency = 0; TabFrame.Title.TextTransparency = 0; TabFrame.Title.Font = Enum.Font.GothamBlack
            ContainerLeft.Visible = true; ContainerRight.Visible = true
        end

        AddConnection(TabFrame.MouseButton1Click, function()
            for _, tab in ipairs(TabHolder:GetChildren()) do
                if tab:IsA("TextButton") then
                    tab.Title.Font = Enum.Font.GothamSemibold
                    TweenService:Create(tab.Ico, TweenInfo.new(0.2), { ImageTransparency = 0.4 }):Play()
                    TweenService:Create(tab.Title, TweenInfo.new(0.2), { TextTransparency = 0.4 }):Play()
                end
            end
            for _, c in ipairs(MainWindow:GetChildren()) do
                if c.Name == "ItemContainerLeft" or c.Name == "ItemContainerRight" then c.Visible = false end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.2), { ImageTransparency = 0 }):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            TabFrame.Title.Font = Enum.Font.GothamBlack
            ContainerLeft.Visible = true; ContainerRight.Visible = true
        end)

        -- Element builders
        local function BuildElements(ItemParent)
            local E = {}

            function E:AddButton(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Button"
                cfg.Callback = cfg.Callback or function() end
                cfg.Icon = cfg.Icon or nil
                local Button = {}
                local Click = SetProps(Make("Button"), { Size = UDim2.new(1, 0, 1, 0) })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 40), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Button"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                        Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    (function()
                        if cfg.Icon then
                            return AddThemeObject(SetProps(Make("Image", GetIcon(cfg.Icon)), {
                                Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -30, 0.5, -9),
                                ImageColor3 = Color3.fromRGB(255, 255, 255), Name = "Image"
                            }), "Text")
                        end
                    end)(),
                    Click
                }), "Elements")
                AddConnection(Click.MouseEnter, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play() end)
                AddConnection(Click.MouseLeave, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)
                AddConnection(Click.MouseButton1Up, function() cfg.Callback() end)
                function Button:Set(text) Frame.Content.Text = text end
                function Button:Destroy() Frame:Destroy() end
                table.insert(OrionLib.UIElements, Button); return Button
            end

            function E:AddToggle(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Toggle"; cfg.Default = cfg.Default or false
                cfg.Callback = cfg.Callback or function() end; cfg.Flag = cfg.Flag or nil
                local Toggle = { Value = cfg.Default, Type = "Toggle", Name = cfg.Name }
                local Click = SetProps(Make("Button"), { Size = UDim2.new(1, 0, 1, 0) })
                local Box = SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 6), {
                    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0.5, -12), BackgroundTransparency = 0.5
                }), {
                    Make("Stroke", Color3.fromRGB(200, 200, 200), 1.2, 0.25),
                    SetProps(Make("Image", "rbxassetid://3944680095"), {
                        Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                        ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 1, Name = "Ico"
                    })
                })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Toggle"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    Box, Click
                }), "Elements")
                function Toggle:Set(value)
                    Toggle.Value = value
                    TweenService:Create(Box.Stroke, TweenInfo.new(0.2), { Transparency = value and 0 or 0.5 }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.2), { BackgroundTransparency = value and 0.0 or 0.5 }):Play()
                    TweenService:Create(Box.Ico, TweenInfo.new(0.2), { ImageTransparency = value and 0 or 1 }):Play()
                    cfg.Callback(value)
                end
                AddConnection(Click.MouseButton1Up, function() Toggle:Set(not Toggle.Value) end)
                AddConnection(Click.MouseEnter, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play() end)
                AddConnection(Click.MouseLeave, function() TweenService:Create(Frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)
                Toggle:Set(cfg.Default)
                if cfg.Flag then OrionLib.Flags[cfg.Flag] = Toggle end
                table.insert(OrionLib.UIElements, Toggle); return Toggle
            end

            function E:AddSlider(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Slider"; cfg.Min = cfg.Min or 0; cfg.Max = cfg.Max or 100
                cfg.Increment = cfg.Increment or 1; cfg.Default = cfg.Default or cfg.Min
                cfg.Callback = cfg.Callback or function() end
                local Slider = { Value = cfg.Default, Type = "Slider" }
                local Dragging = false
                local Bar = SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 8), {
                    Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 12, 0, 38), BackgroundTransparency = 0.5
                }), {
                    Make("Stroke", Color3.fromRGB(200, 200, 200), 1, 0.25),
                    AddThemeObject(SetProps(Make("Label", "0", 12), {
                        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Value", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    (function()
                        local fill = Make("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6)
                        fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundTransparency = 0.7
                        return fill
                    end)()
                })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 74), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Slider"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                        Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    Bar
                }), "Elements")
                local function SetValue(v)
                    v = math.clamp(Round(v, cfg.Increment), cfg.Min, cfg.Max)
                    Slider.Value = v
                    local pct = (v - cfg.Min) / math.max(cfg.Max - cfg.Min, 0.0001)
                    TweenService:Create(Bar.Fill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                    Bar.Value.Text = tostring(v); cfg.Callback(v)
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
                        SetValue(cfg.Min + (cfg.Max - cfg.Min) * pct)
                    end
                end)
                function Slider:Set(v) SetValue(v) end
                SetValue(cfg.Default)
                table.insert(OrionLib.UIElements, Slider); return Slider
            end

            function E:AddDropdown(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Dropdown"; cfg.Options = cfg.Options or {}
                cfg.Default = cfg.Default or ""; cfg.Callback = cfg.Callback or function() end
                cfg.MaxSize = cfg.MaxSize or 6
                local Dropdown = { Value = cfg.Default, Options = cfg.Options, Buttons = {}, Toggled = false, Type = "Dropdown" }
                local List = SetProps(Make("List"), { HorizontalAlignment = Enum.HorizontalAlignment.Center })
                local Container = AddThemeObject(SetProps(SetChildren(Make("ScrollFrame", Color3.fromRGB(180, 180, 180)), { List }), {
                    Parent = ItemParent, Position = UDim2.new(0, 0, 0, 42), Size = UDim2.new(1, 0, 1, -42),
                    ClipsDescendants = true, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180),
                    ScrollBarImageTransparency = 0.4
                }), "Divider")
                local Click = SetProps(Make("Button"), { Size = UDim2.new(1, 0, 1, 0) })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, ClipsDescendants = true, BackgroundTransparency = 0.2, Name = "Dropdown"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    Container,
                    SetProps(SetChildren(Make("TFrame"), {
                        AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                            Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                            Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
                        }), "Text"),
                        AddThemeObject(SetProps(Make("Image", "rbxassetid://7072706796"), {
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
                        local btn = AddThemeObject(SetProps(SetChildren(Make("Button"), {
                            Make("Corner", 0, 6),
                            AddThemeObject(SetProps(Make("Label", opt, 13, 0.3), {
                                Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0),
                                Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
                            }), "Text")
                        }), { Parent = Container, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ClipsDescendants = true }), "Divider")
                        AddConnection(btn.MouseButton1Click, function()
                            Dropdown.Value = opt
                            Frame.F.Content.Text = cfg.Name .. ": " .. opt
                            cfg.Callback(opt)
                        end)
                        Dropdown.Buttons[opt] = btn
                    end
                end
                AddConnection(Click.MouseButton1Click, function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    local targetSize = Dropdown.Toggled and UDim2.new(1, 0, 0, 42 + math.min(#cfg.Options, cfg.MaxSize) * 28) or UDim2.new(1, 0, 0, 42)
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = targetSize }):Play()
                end)
                AddOptions(cfg.Options)
                if Dropdown.Options[1] then Frame.F.Content.Text = cfg.Name .. ": " .. cfg.Default end
                function Dropdown:Refresh(opts, delete)
                    if delete then for _, b in pairs(Dropdown.Buttons) do b:Destroy() end; Dropdown.Buttons = {}; Dropdown.Options = {} end
                    Dropdown.Options = opts or {}; AddOptions(Dropdown.Options)
                end
                function Dropdown:Set(v)
                    Dropdown.Value = v; Frame.F.Content.Text = cfg.Name .. ": " .. v; cfg.Callback(v)
                end
                table.insert(OrionLib.UIElements, Dropdown); return Dropdown
            end

            function E:AddBind(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Bind"; cfg.Default = cfg.Default or ""
                cfg.Callback = cfg.Callback or function() end; cfg.Hold = cfg.Hold or false
                local Bind = { Value = cfg.Default, Binding = false, Type = "Bind" }
                local Click = SetProps(Make("Button"), { Size = UDim2.new(1, 0, 1, 0) })
                local ClickBind = SetProps(Make("Button"), { Size = UDim2.new(1, 0, 1, 0), ZIndex = 2 })
                local BindBox = SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(0, 0, 0), 0, 6), {
                    Size = UDim2.new(0, 34, 0, 24), Position = UDim2.new(1, -46, 0.5, -12), BackgroundTransparency = 0.5
                }), {
                    Make("Stroke", Color3.fromRGB(200, 200, 200), 1.2, 0.25),
                    AddThemeObject(SetProps(Make("Label", cfg.Default, 12), {
                        Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center, Name = "Value", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    ClickBind
                })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Bind"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
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
                        if Bind.Value ~= "" and (input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value) then cfg.Callback() end
                    end
                end)
                function Bind:Set(k)
                    if k == nil or k == "" then Bind.Value = ""; BindBox.Value.Text = ""; return end
                    Bind.Value = typeof(k) == "string" and k or k.Name
                    BindBox.Value.Text = Bind.Value
                end
                table.insert(OrionLib.UIElements, Bind); return Bind
            end

            function E:AddTextbox(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Textbox"; cfg.Default = cfg.Default or ""
                cfg.Callback = cfg.Callback or function() end; cfg.TextDisappear = cfg.TextDisappear or false
                local Textbox = { Value = cfg.Default, Type = "Textbox" }
                local box = Create("TextBox", {
                    Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -112, 0.5, -12),
                    BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    TextColor3 = Color3.fromRGB(255, 255, 255), PlaceholderColor3 = Color3.fromRGB(180, 180, 180),
                    PlaceholderText = "Input", Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Center, TextSize = 13, ClearTextOnFocus = false, Text = cfg.Default
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }).Parent = box
                Create("UIStroke", { Color = Color3.fromRGB(200, 200, 200), Thickness = 1, Transparency = 0.25 }).Parent = box
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Textbox"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                        Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    box
                }), "Elements")
                AddConnection(box.FocusLost, function()
                    cfg.Callback(box.Text); if cfg.TextDisappear then box.Text = "" end
                end)
                function Textbox:Set(t) box.Text = t end
                table.insert(OrionLib.UIElements, Textbox); return Textbox
            end

            function E:AddColorpicker(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Colorpicker"; cfg.Default = cfg.Default or Color3.fromRGB(255, 255, 255)
                cfg.DefaultTransparency = cfg.DefaultTransparency or 0; cfg.Callback = cfg.Callback or function() end
                local Colorpicker = { Value = cfg.Default, TransparencyValue = cfg.DefaultTransparency, Type = "Colorpicker" }
                local Box = SetChildren(SetProps(Make("RoundFrame", cfg.Default, 0, 6), {
                    Size = UDim2.new(0, 34, 0, 20), Position = UDim2.new(1, -46, 0.5, -10), BackgroundTransparency = cfg.DefaultTransparency
                }), { Make("Stroke", Color3.fromRGB(200, 200, 200), 1.2, 0.25) })
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 42), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Colorpicker"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Content", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    Box
                }), "Elements")
                function Colorpicker:Set(color, transp)
                    Colorpicker.Value = color; Colorpicker.TransparencyValue = transp or 0
                    Box.BackgroundColor3 = color; Box.BackgroundTransparency = transp or 0
                    cfg.Callback(color, transp or 0)
                end
                table.insert(OrionLib.UIElements, Colorpicker); return Colorpicker
            end

            function E:AddLabel(text)
                local Label = { Type = "Label" }
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 34), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Label"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", text or "", 14), {
                        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text")
                }), "Elements")
                function Label:Set(t) Frame.Content.Text = t end
                table.insert(OrionLib.UIElements, Label); return Label
            end

            function E:AddParagraph(title, content)
                local P = { Type = "Paragraph" }
                local Frame = AddThemeObject(SetChildren(SetProps(Make("RoundFrame", Color3.fromRGB(45, 45, 45), 0, 10), {
                    Size = UDim2.new(1, 0, 0, 56), Parent = ItemParent, BackgroundTransparency = 0.2, Name = "Paragraph"
                }), {
                    Make("Stroke", Color3.fromRGB(180, 180, 180), 1, 0.45),
                    AddThemeObject(SetProps(Make("Label", title or "", 14), {
                        Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 8),
                        Font = Enum.Font.GothamBold, Name = "Title", TextColor3 = Color3.fromRGB(255, 255, 255)
                    }), "Text"),
                    AddThemeObject(SetProps(Make("Label", content or "", 13), {
                        Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 30),
                        Font = Enum.Font.GothamSemibold, Name = "Content", TextWrapped = true, TextColor3 = Color3.fromRGB(200, 200, 200)
                    }), "TextDark")
                }), "Elements")
                function P:Set(c) Frame.Content.Text = c end
                table.insert(OrionLib.UIElements, P); return P
            end

            return E
        end

        -- Tab wrapper / AddSection
        local TabWrapper = {}

        function TabWrapper:AddSection(cfg)
            cfg = cfg or {}
            cfg.Name = cfg.Name or "Section"
            cfg.Side = cfg.Side or "Left"

            local container = (cfg.Side == "Left") and ContainerLeft or ContainerRight

            local Section = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Parent = container, Name = "Section",
                AutomaticSize = Enum.AutomaticSize.Y
            })

            local SectionLayout = Make("List", 0, 0)
            SectionLayout.Parent = Section

            local SectionTitle = AddThemeObject(SetProps(Make("Label", cfg.Name, 14), {
                Size = UDim2.new(1, -12, 0, 20), Position = UDim2.new(0, 0, 0, 0),
                Font = Enum.Font.GothamBlack, Name = "SectionTitle",
                TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1
            }), "Text")
            SectionTitle.Parent = Section

            local Holder = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 26),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Parent = Section, Name = "Holder",
                AutomaticSize = Enum.AutomaticSize.Y
            })

                       local HolderList = Make("List", 0, 8)
            HolderList.Parent = Holder

            local HolderPadding = Make("Padding", 8, 0, 0, 0)
            HolderPadding.Parent = Holder

            local elements = BuildElements(Holder)
            return elements
        end

        OrionLib.Tabs[TabConfig.Name] = TabWrapper
        return TabWrapper
    end

    OrionLib.Window = TabFunction
    return TabFunction
end
-- ← FIM da MakeWindow

-- CONFIG TAB
function OrionLib:SetConfigTab(TabName)
    if not writefile or not readfile or not isfile or not isfolder or not makefolder or not listfiles then
        warn("[OrionLib] Executor does not support files"); return
    end
    local tab = OrionLib.Tabs[TabName]
    if not tab then warn("[OrionLib] Config tab not found: " .. tostring(TabName)); return end

    local FolderName = OrionLib.ScriptFolder
    if not isfolder(FolderName) then makefolder(FolderName) end
    if not isfolder(FolderName .. "/Config") then makefolder(FolderName .. "/Config") end
    local GameFolder = FolderName .. "/Config/" .. OrionLib.GameName
    if not isfolder(GameFolder) then makefolder(GameFolder) end

    local section = tab:AddSection({ Name = "Config", Side = "Right" })
    local selected = ""

    section:AddTextbox({ Name = "Config Name", Callback = function(text) selected = text end })

    section:AddButton({
        Name = "Save Config",
        Callback = function()
            if selected == "" then return end
            local data = {}
            for name, flag in pairs(OrionLib.Flags) do
                if typeof(flag) == "table" and flag.Value ~= nil then data[name] = { Value = flag.Value } end
            end
            writefile(GameFolder .. "/" .. selected .. ".json", HttpService:JSONEncode(data))
            OrionLib:MakeNotification({ Name = "Config", Content = "Saved: " .. selected, Time = 3 })
        end
    })
    section:AddButton({
        Name = "Load Config",
        Callback = function()
            if selected == "" then return end
            local path = GameFolder .. "/" .. selected .. ".json"
            if not isfile(path) then OrionLib:MakeNotification({ Name = "Config", Content = "Not found: " .. selected, Time = 3 }); return end
            local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
            if not ok or typeof(data) ~= "table" then return end
            for name, value in pairs(data) do
                local flag = OrionLib.Flags[name]
                if flag and flag.Set and typeof(value) == "table" then pcall(function() flag:Set(value.Value) end) end
            end
            OrionLib:MakeNotification({ Name = "Config", Content = "Loaded: " .. selected, Time = 3 })
        end
    })
    section:AddButton({
        Name = "Delete Config",
        Callback = function()
            if selected == "" then return end
            local path = GameFolder .. "/" .. selected .. ".json"
            if isfile(path) then delfile(path) end
            OrionLib:MakeNotification({ Name = "Config", Content = "Deleted: " .. selected, Time = 3 })
        end
    })
end

function OrionLib:Init()
    local w = game.CoreGui:FindFirstChild("OrionLib")
    if w and w:FindFirstChild("MainWindow") then w.MainWindow.Visible = true end
end

function OrionLib:Destroy() Orion:Destroy() end

return OrionLib
