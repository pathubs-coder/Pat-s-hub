-- Pat's Hub - Simple UI Library (single-file)
-- Drop this into a LocalScript or host as raw and load with loadstring/httpget
local PatHub = {}
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Utility
local function tween(obj, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.InOut
    TweenService:Create(obj, TweenInfo.new(time, style, dir), props):Play()
end

local function make(parent, class, props)
    local inst = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            inst[k] = v
        end
    end
    inst.Parent = parent
    return inst
end

-- Default purple theme
local DefaultTheme = {
    SchemeColor = Color3.fromRGB(138, 43, 226), -- purple
    Background = Color3.fromRGB(24, 24, 30),
    Header = Color3.fromRGB(36, 28, 45),
    TextColor = Color3.fromRGB(240, 240, 240),
    ElementColor = Color3.fromRGB(30, 24, 38)
}

-- Dragging helper
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Create library
function PatHub.CreateLib(libName, themeTable)
    libName = libName or "Pat's Hub"
    local theme = themeTable or DefaultTheme

    -- clean old
    for _,v in pairs(game.CoreGui:GetChildren()) do
        if v.Name == ("PatHub_"..libName) then
            v:Destroy()
        end
    end

    local screen = make(game.CoreGui, "ScreenGui", {
        Name = "PatHub_"..libName,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- main frame
    local main = make(screen, "Frame", {
        Name = "Main",
        Size = UDim2.new(0, 520, 0, 320),
        Position = UDim2.new(0.3, 0, 0.25, 0),
        BackgroundColor3 = theme.Background,
        ClipsDescendants = true
    })
    make(main, "UICorner", {CornerRadius = UDim.new(0,6)})

    -- header
    local header = make(main, "Frame", {
        Name = "Header",
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = theme.Header
    })
    make(header, "UICorner", {CornerRadius = UDim.new(0,6)})
    local title = make(header, "TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7,0,1,0),
        Position = UDim2.new(0.02,0,0,0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = libName,
        TextColor3 = theme.TextColor,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local toggleBtn = make(header, "TextButton", {
        Name = "Toggle",
        Size = UDim2.new(0,30,0,30),
        Position = UDim2.new(0.92,0,0.06,0),
        BackgroundTransparency = 1,
        Text = "—",
        Font = Enum.Font.Gotham,
        TextSize = 20,
        TextColor3 = theme.TextColor
    })

    -- sidebar for tabs
    local sidebar = make(main, "Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0,140,1,-36),
        Position = UDim2.new(0,0,0,36),
        BackgroundColor3 = theme.Header
    })
    make(sidebar, "UICorner", {CornerRadius = UDim.new(0,6)})

    local content = make(main, "Frame", {
        Name = "Content",
        Size = UDim2.new(1,-140,1,-36),
        Position = UDim2.new(0,140,0,36),
        BackgroundTransparency = 1
    })

    -- tab list and pages
    local tabList = make(sidebar, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
    tabList.Padding = UDim.new(0,6)

    local pagesFolder = make(content, "Folder", {Name = "Pages"})

    -- show/hide toggle
    toggleBtn.MouseButton1Click:Connect(function()
        screen.Enabled = not screen.Enabled
    end)

    -- draggable header
    makeDraggable(main, header)

    local Window = {}
    Window._theme = theme
    Window._tabs = {}

    function Window:ToggleUI()
        screen.Enabled = not screen.Enabled
    end

    -- creates a new tab (button in sidebar + page)
    function Window:NewTab(tabName)
        tabName = tabName or "Tab"
        local tabBtn = make(sidebar, "TextButton", {
            Name = tabName.."Btn",
            Size = UDim2.new(1,-12,0,30),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = tabName,
            TextColor3 = self._theme.TextColor,
            TextSize = 14
        })
        local tabPage = make(pagesFolder, "Frame", {
            Name = tabName.."Page",
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Visible = false
        })
        local pageList = make(tabPage, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
        pageList.Padding = UDim.new(0,8)
        table.insert(self._tabs, {btn = tabBtn, page = tabPage})

        -- select first tab automatically
        if #self._tabs == 1 then
            tabBtn.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = self._theme.SchemeColor
            tabPage.Visible = true
        end

        tabBtn.MouseButton1Click:Connect(function()
            for _,t in pairs(self._tabs) do
                t.btn.BackgroundTransparency = 1
                t.btn.BackgroundColor3 = self._theme.Header
                t.page.Visible = false
            end
            tabBtn.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = self._theme.SchemeColor
            tabPage.Visible = true
        end)

        -- return a tab object with NewSection
        local Tab = {}
        function Tab:NewSection(sectionName)
            sectionName = sectionName or "Section"
            local sectionFrame = make(tabPage, "Frame", {
                Name = sectionName.."Section",
                Size = UDim2.new(1, -12, 0, 10), -- auto sized by layout
                BackgroundColor3 = self.ParentTheme and self.ParentTheme.ElementColor or Window._theme.ElementColor
            })
            sectionFrame.BackgroundTransparency = 1
            local head = make(sectionFrame, "TextLabel", {
                Name = "Head",
                Size = UDim2.new(1,0,0,22),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = sectionName,
                TextColor3 = Window._theme.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0,6,0,0)
            })
            local inner = make(sectionFrame, "Frame", {
                Name = "Inner",
                Size = UDim2.new(1,-12,0,40),
                Position = UDim2.new(0,6,0,26),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 1
            })
            local innerList = make(inner, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})
            innerList.Padding = UDim.new(0,6)
            -- ensure section frame sizes to content
            local function updateSize()
                local contentSize = innerList.AbsoluteContentSize.Y
                sectionFrame.Size = UDim2.new(1, -12, 0, 26 + contentSize + 10)
            end
            innerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
            updateSize()

            -- Section methods (add elements)
            local Section = {}

            function Section:NewButton(name, tip, callback)
                name = name or "Button"
                tip = tip or ""
                callback = callback or function() end
                local btn = make(inner, "TextButton", {
                    Size = UDim2.new(1, -12, 0, 30),
                    BackgroundColor3 = Window._theme.ElementColor,
                    AutoButtonColor = false,
                    Text = name,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor
                })
                make(btn, "UICorner", {CornerRadius = UDim.new(0,6)})
                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
                return {
                    Update = function(newName) btn.Text = newName end
                }
            end

            function Section:NewToggle(name, tip, callback)
                name = name or "Toggle"
                tip = tip or ""
                callback = callback or function() end
                local container = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 30), BackgroundTransparency = 1})
                local label = make(container, "TextLabel", {
                    Size = UDim2.new(0.75, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0,6,0,0)
                })
                local togg = make(container, "TextButton", {
                    Size = UDim2.new(0,46,0,22),
                    Position = UDim2.new(0.78, 0, 0.12, 0),
                    BackgroundColor3 = Color3.fromRGB(60,60,60),
                    Text = "Off",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Window._theme.TextColor
                })
                make(togg, "UICorner", {CornerRadius = UDim.new(0,6)})
                local state = false
                togg.MouseButton1Click:Connect(function()
                    state = not state
                    if state then
                        togg.Text = "On"
                        tween(togg, {BackgroundColor3 = Window._theme.SchemeColor}, 0.15)
                    else
                        togg.Text = "Off"
                        tween(togg, {BackgroundColor3 = Color3.fromRGB(60,60,60)}, 0.15)
                    end
                    pcall(callback, state)
                end)
                return {
                    Set = function(v) state = v; togg.Text = v and "On" or "Off"; tween(togg, {BackgroundColor3 = v and Window._theme.SchemeColor or Color3.fromRGB(60,60,60)}, 0.15) end,
                    Get = function() return state end
                }
            end

            function Section:NewSlider(name, tip, min, max, callback)
                name = name or "Slider"
                min = min or 0
                max = max or 100
                callback = callback or function() end
                local container = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 40), BackgroundTransparency = 1})
                local label = make(container, "TextLabel", {
                    Size = UDim2.new(0.6,0,0,18),
                    Position = UDim2.new(0,6,0,0),
                    BackgroundTransparency = 1,
                    Text = name.." ("..min..")",
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local bar = make(container, "Frame", {
                    Size = UDim2.new(0.9, 0, 0, 8),
                    Position = UDim2.new(0.05, 0, 0.5, 6),
                    BackgroundColor3 = Color3.fromRGB(60,60,60)
                })
                make(bar, "UICorner", {CornerRadius = UDim.new(0,6)})
                local fill = make(bar, "Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Window._theme.SchemeColor
                })
                make(fill, "UICorner", {CornerRadius = UDim.new(0,6)})
                local dragging = false
                local mouse = Players.LocalPlayer:GetMouse()
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                bar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInput.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        fill.Size = UDim2.new(rel, 0, 1, 0)
                        local val = math.floor(min + (rel * (max - min)))
                        label.Text = name.." ("..val..")"
                        pcall(callback, val)
                    end
                end)
                return {
                    Set = function(v) local rel = math.clamp((v - min) / (max - min), 0, 1); fill.Size = UDim2.new(rel,0,1,0); label.Text = name.." ("..v..")" end
                }
            end

            function Section:NewDropdown(name, tip, list, callback)
                name = name or "Dropdown"
                list = list or {}
                callback = callback or function() end
                local container = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 30), BackgroundTransparency = 1})
                local label = make(container, "TextLabel", {
                    Size = UDim2.new(0.6,0,1,0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0,6,0,0)
                })
                local btn = make(container, "TextButton", {
                    Size = UDim2.new(0,120,0,22),
                    Position = UDim2.new(0.7,0,0.12,0),
                    Text = "Select",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Window._theme.TextColor,
                    BackgroundColor3 = Window._theme.ElementColor
                })
                make(btn, "UICorner", {CornerRadius = UDim.new(0,6)})
                local dropFrame = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1, Visible = false})
                local listLayout = make(dropFrame, "UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
                listLayout.Padding = UDim.new(0,4)
                for _,v in ipairs(list) do
                    local item = make(dropFrame, "TextButton", {
                        Size = UDim2.new(1,0,0,24),
                        BackgroundColor3 = Window._theme.ElementColor,
                        Text = v,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Window._theme.TextColor,
                        TextSize = 13
                    })
                    make(item, "UICorner", {CornerRadius = UDim.new(0,6)})
                    item.MouseButton1Click:Connect(function()
                        btn.Text = v
                        dropFrame.Visible = false
                        pcall(callback, v)
                    end)
                end
                local function updateDropSize()
                    dropFrame.Size = UDim2.new(1,-12,0,listLayout.AbsoluteContentSize.Y)
                end
                listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateDropSize)
                updateDropSize()
                btn.MouseButton1Click:Connect(function()
                    dropFrame.Visible = not dropFrame.Visible
                end)
                return {
                    SetList = function(newList)
                        for _,c in pairs(dropFrame:GetChildren()) do
                            if c:IsA("TextButton") then c:Destroy() end
                        end
                        for _,v in ipairs(newList) do
                            local item = make(dropFrame, "TextButton", {
                                Size = UDim2.new(1,0,0,24),
                                BackgroundColor3 = Window._theme.ElementColor,
                                Text = v,
                                Font = Enum.Font.Gotham,
                                TextColor3 = Window._theme.TextColor,
                                TextSize = 13
                            })
                            make(item, "UICorner", {CornerRadius = UDim.new(0,6)})
                            item.MouseButton1Click:Connect(function()
                                btn.Text = v
                                dropFrame.Visible = false
                                pcall(callback, v)
                            end)
                        end
                        updateDropSize()
                    end
                }
            end

            function Section:NewTextBox(name, tip, callback)
                name = name or "Textbox"
                callback = callback or function() end
                local container = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 34), BackgroundTransparency = 1})
                local label = make(container, "TextLabel", {
                    Size = UDim2.new(0.45,0,0,18),
                    Position = UDim2.new(0,6,0,0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local box = make(container, "TextBox", {
                    Size = UDim2.new(0.5,0,0,20),
                    Position = UDim2.new(0.5, -6, 0, 6),
                    BackgroundColor3 = Window._theme.ElementColor,
                    ClearTextOnFocus = false,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    PlaceholderText = tip or ""
                })
                make(box, "UICorner", {CornerRadius = UDim.new(0,6)})
                box.FocusLost:Connect(function(entered)
                    if entered then
                        pcall(callback, box.Text)
                        box.Text = ""
                    end
                end)
                return {
                    Get = function() return box.Text end,
                    Set = function(t) box.Text = t end
                }
            end

            function Section:NewKeybind(name, tip, defaultKey, callback)
                name = name or "Keybind"
                callback = callback or function() end
                local container = make(inner, "Frame", {Size = UDim2.new(1, -12, 0, 30), BackgroundTransparency = 1})
                local label = make(container, "TextLabel", {
                    Size = UDim2.new(0.65,0,1,0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Window._theme.TextColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0,6,0,0)
                })
                local keyBtn = make(container, "TextButton", {
                    Size = UDim2.new(0,80,0,22),
                    Position = UDim2.new(0.75,0,0.12,0),
                    Text = tostring(defaultKey or "Key"),
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Window._theme.TextColor,
                    BackgroundColor3 = Window._theme.ElementColor
                })
                make(keyBtn, "UICorner", {CornerRadius = UDim.new(0,6)})
                local binding = defaultKey
                local awaiting = false
                keyBtn.MouseButton1Click:Connect(function()
                    keyBtn.Text = "Press..."
                    awaiting = true
                end)
                UserInput.InputBegan:Connect(function(input, gameProcessed)
                    if awaiting and input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = input.KeyCode
                        keyBtn.Text = tostring(binding)
                        awaiting = false
                    else
                        if input.KeyCode == binding then
                            pcall(callback)
                        end
                    end
                end)
                return {
                    Get = function() return binding end,
                    Set = function(k) binding = k; keyBtn.Text = tostring(k) end
                }
            end

            -- attach Section to the sectionFrame so outer code can return it
            sectionFrame.Parent = tabPage
            updateSize()

            return Section
        end

        return Tab
    end

    -- finalize
    return Window
end

return PatHub
