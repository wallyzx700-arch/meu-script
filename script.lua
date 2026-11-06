-- ============================================================
--  China Hub Free v4.0 — King Legacy
--  GUI estilo OMG Hub | Auto Farm corrigido | Anti-mar
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
--  CONFIG
-- ============================================================
local Cfg = {
    PlayerESP   = false,
    FruitESP    = false,
    ShowDist    = true,
    TracerLines = false,
    ESPRange    = 2000,
    WHUrl       = "",
    HideKey     = Enum.KeyCode.LeftControl,
    Col_Player  = Color3.fromRGB(255, 80,  80),
    Col_Fruit   = Color3.fromRGB(80,  220, 80),
    Col_Dungeon = Color3.fromRGB(80,  160, 255),
}

local Farm = {
    Active     = false,
    Attack     = false,
    State      = "idle",
    Timer      = 0,
    Zone       = nil,
    StatusText = "Inativo",
}

local SEA_Y        = 8
local QUEST_TIMEOUT = 110

-- ============================================================
--  DRAWING UTILS
-- ============================================================
local function NewText(col, sz)
    local t = Drawing.new("Text")
    t.Color = col or Color3.new(1,1,1); t.Size = sz or 13
    t.Center = true; t.Outline = true; t.Visible = false; return t
end
local function NewBox(col, filled)
    local b = Drawing.new("Square")
    b.Color = col or Color3.new(1,1,1); b.Thickness = 1.5
    b.Filled = filled or false; b.Visible = false; return b
end
local function NewLine(col)
    local l = Drawing.new("Line")
    l.Color = col or Color3.new(1,1,1); l.Thickness = 1; l.Visible = false; return l
end
local function W2V(pos)
    local sp = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), sp.Z, sp.Z > 0
end
local function Dist(pos)
    local c = LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        return math.floor((c.HumanoidRootPart.Position - pos).Magnitude)
    end
    return 0
end

-- ============================================================
--  SAFE TP
-- ============================================================
local function SafeTP(pos)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local safeY = math.max(pos.Y, 22)
    char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(pos.X, safeY, pos.Z))
    task.wait(0.45)
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        Farm.State = "idle"
        Farm.StatusText = "⚠ Caiu no mar — resetando"
        if Farm.Zone then
            char.HumanoidRootPart.CFrame =
                CFrame.new(Farm.Zone.islePos + Vector3.new(0, 14, 0))
        end
    end
end

-- ============================================================
--  ZONAS
-- ============================================================
local QuestZones = {
    { name="Ilha Inicial",        minLv=1,   maxLv=14,
      islePos=Vector3.new(-210,28,180),   questPos=Vector3.new(-185,25,148),  mobPos=Vector3.new(-268,20,215) },
    { name="Base Marinha",        minLv=15,  maxLv=34,
      islePos=Vector3.new(990,28,-510),   questPos=Vector3.new(1012,24,-548), mobPos=Vector3.new(948,20,-472) },
    { name="Ilha Buggy",          minLv=35,  maxLv=59,
      islePos=Vector3.new(402,28,-1002),  questPos=Vector3.new(422,24,-1035), mobPos=Vector3.new(465,20,-958) },
    { name="Baratie",             minLv=60,  maxLv=89,
      islePos=Vector3.new(-792,28,1242),  questPos=Vector3.new(-762,24,1272), mobPos=Vector3.new(-832,20,1198) },
    { name="Arlong Park",         minLv=90,  maxLv=124,
      islePos=Vector3.new(1822,28,1492),  questPos=Vector3.new(1848,24,1515), mobPos=Vector3.new(1778,20,1448) },
    { name="Coliseu",             minLv=125, maxLv=174,
      islePos=Vector3.new(1622,28,-872),  questPos=Vector3.new(1648,24,-898), mobPos=Vector3.new(1575,20,-935) },
    { name="Ilha dos Tubarões",   minLv=175, maxLv=224,
      islePos=Vector3.new(-3052,28,1978), questPos=Vector3.new(-3030,24,1958),mobPos=Vector3.new(-3105,20,2022) },
    { name="Marineford",          minLv=225, maxLv=274,
      islePos=Vector3.new(2552,28,-2058), questPos=Vector3.new(2572,24,-2082),mobPos=Vector3.new(2508,20,-2135) },
    { name="Shanks Island",       minLv=275, maxLv=324,
      islePos=Vector3.new(-1892,28,-858), questPos=Vector3.new(-1872,24,-878),mobPos=Vector3.new(-1945,20,-802) },
    { name="Mihawk Island",       minLv=325, maxLv=374,
      islePos=Vector3.new(-2492,28,-312), questPos=Vector3.new(-2512,24,-332),mobPos=Vector3.new(-2562,20,-375) },
    { name="Skypiea",             minLv=375, maxLv=449,
      islePos=Vector3.new(-2822,865,-1632),questPos=Vector3.new(-2842,860,-1652),mobPos=Vector3.new(-2892,858,-1702) },
    { name="Upper Yard",          minLv=450, maxLv=999,
      islePos=Vector3.new(-3102,882,-1922),questPos=Vector3.new(-3122,877,-1942),mobPos=Vector3.new(-3172,872,-1992) },
}

local function GetLevel()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Level","Lv","level","Nivel","nível"}) do
            local v = ls:FindFirstChild(n)
            if v then return v.Value end
        end
    end
    for _, v in ipairs(LP:GetDescendants()) do
        if (v.Name=="Level" or v.Name=="Lv") and
           (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    return 1
end

local function GetZoneForLevel(lv)
    for _, z in ipairs(QuestZones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return QuestZones[#QuestZones]
end

-- ============================================================
--  DETECÇÃO DE NPC DE MISSÃO
--  Critério duplo:
--    1. ProximityPrompt com ActionText contendo "Interagir"
--    2. Ancestral com BillboardGui contendo "Missão" / "Mission"
--  Qualquer dos dois basta; juntos = match perfeito.
--  Exclui NPCs abaixo de SEA_Y e descendentes de barco.
-- ============================================================
local BOAT_NAMES = {
    "boat","ship","navio","ferry","barca","vessel","galleon",
    "embarca","pirate ship","marine ship","barco"
}
local function IsBoatDescendant(obj)
    local cur = obj
    for _ = 1, 8 do
        if not cur or not cur.Parent then break end
        cur = cur.Parent
        local n = cur.Name:lower()
        for _, bad in ipairs(BOAT_NAMES) do
            if n:find(bad) then return true end
        end
    end
    return false
end

local function HasMissaoLabel(model)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            for _, lbl in ipairs(obj:GetDescendants()) do
                if lbl:IsA("TextLabel") or lbl:IsA("TextButton") then
                    local t = lbl.Text:lower()
                    if t:find("miss") or t:find("quest") or t:find("missi") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function FindQuestNPC(nearPos, radius)
    radius = radius or 100
    local best, bestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj:IsA("ProximityPrompt") then continue end
        local part = obj.Parent
        if not (part and part:IsA("BasePart")) then continue end
        if part.Position.Y < SEA_Y then continue end
        if IsBoatDescendant(part) then continue end

        local d = (part.Position - nearPos).Magnitude
        if d >= radius or d >= bestDist then continue end

        local at = (obj.ActionText or ""):lower()
        local isInteract = at:find("interagir") or at:find("interact")
            or at:find("quest") or at:find("missão") or at:find("miss")

        -- Verifica se o modelo-pai tem label de missão
        local model = part.Parent
        local hasMissao = model and model:IsA("Model") and HasMissaoLabel(model)

        -- Aceita se tiver texto de interagir OU label de missão
        if isInteract or hasMissao then
            best = obj; bestDist = d
        end
    end
    return best, bestDist
end

local function FirePrompt(prompt)
    if not prompt then return false end
    return pcall(function() fireproximityprompt(prompt) end)
end

-- ============================================================
--  MOB PRÓXIMO (filtrado por zona)
-- ============================================================
local function NearestMob(zoneCenter, zoneRadius)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local origin = char.HumanoidRootPart.Position
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0
               and not Players:GetPlayerFromCharacter(obj) then
                if zoneCenter and
                   (hrp.Position - zoneCenter).Magnitude > (zoneRadius or 350) then
                    continue
                end
                local d = (origin - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; best = obj end
            end
        end
    end
    return best, bestDist
end

-- ============================================================
--  AUTO M1
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not Farm.Attack then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(2); continue end
        local mob, dist = NearestMob()
        if not mob then continue end
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if dist > 7 then
            char.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(3,2,0))
            task.wait(0.08)
        end
        local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
        if onScr then
            VirtualUser:ClickButton1(Vector2.new(sp.X, sp.Y), CFrame.new())
        end
    end
end)

-- ============================================================
--  AUTO FARM — máquina de estado
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.25)
        if not Farm.Active then Farm.State = "idle"; continue end

        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1); continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            Farm.StatusText = "⏳ Aguardando respawn..."
            task.wait(3); continue
        end

        local lv   = GetLevel()
        local zone = GetZoneForLevel(lv)

        -- idle
        if Farm.State == "idle" then
            Farm.Zone  = zone
            Farm.State = "toquest"
            Farm.Timer = tick()
            Farm.StatusText = ("Lv %d → %s | Indo buscar quest"):format(lv, zone.name)

        -- toquest
        elseif Farm.State == "toquest" then
            SafeTP(Farm.Zone.questPos)
            task.wait(1.1)
            if char.HumanoidRootPart.Position.Y < SEA_Y then
                Farm.State = "idle"; continue
            end

            local npc = FindQuestNPC(Farm.Zone.questPos, 100)
            if npc then
                local npcPart = npc.Parent
                if npcPart and npcPart:IsA("BasePart") and npcPart.Position.Y >= SEA_Y then
                    char.HumanoidRootPart.CFrame =
                        CFrame.new(npcPart.Position + Vector3.new(3, 1, 0))
                    task.wait(0.65)
                end
                FirePrompt(npc); task.wait(0.45)
                FirePrompt(npc); task.wait(0.45)
                Farm.StatusText = ("Lv %d → %s | ✓ Quest aceita"):format(lv, Farm.Zone.name)
            else
                Farm.StatusText = ("Lv %d → %s | NPC não achado"):format(lv, Farm.Zone.name)
            end

            SafeTP(Farm.Zone.mobPos)
            task.wait(0.9)
            if char.HumanoidRootPart.Position.Y < SEA_Y then
                Farm.State = "idle"; continue
            end
            Farm.State = "fighting"
            Farm.Timer = tick()

        -- fighting
        elseif Farm.State == "fighting" then
            if tick() - Farm.Timer > QUEST_TIMEOUT then
                Farm.State = "idle"; continue
            end

            local mob, dist = NearestMob(Farm.Zone.mobPos, 350)
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                if hrp.Position.Y < SEA_Y then task.wait(0.5); continue end
                if dist > 7 then
                    char.HumanoidRootPart.CFrame =
                        CFrame.new(hrp.Position + Vector3.new(3, 2, 0))
                    task.wait(0.1)
                end
                local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
                if onScr then
                    VirtualUser:ClickButton1(Vector2.new(sp.X, sp.Y), CFrame.new())
                end
                local alive = mob:FindFirstChildOfClass("Humanoid")
                Farm.StatusText = ("Lv %d → %s | HP: %d"):format(
                    lv, Farm.Zone.name, alive and math.floor(alive.Health) or 0)
            else
                Farm.StatusText = ("Lv %d → %s | Aguardando respawn..."):format(lv, Farm.Zone.name)
                local ret = FindQuestNPC(Farm.Zone.questPos, 100)
                if ret then
                    local at = (ret.ActionText or ""):lower()
                    if at:find("entreg") or at:find("complet") or at:find("return") or at:find("finish") then
                        SafeTP(Farm.Zone.questPos)
                        task.wait(0.9)
                        FirePrompt(ret); task.wait(0.45)
                        Farm.State = "idle"; continue
                    end
                end
                if tick() - Farm.Timer > QUEST_TIMEOUT then
                    Farm.State = "idle"
                end
                task.wait(1.5)
            end
        end
    end
end)

-- ============================================================
--  FRUTAS
-- ============================================================
local FruitKW = {
    "fruit","devil","gumgum","bombomb","chop","smoke","flame","ice","magnet",
    "light","dark","quake","phoenix","dragon","rubb","sand","diamond","paw",
    "gravity","string","shadow","portal","control","venom","leopard","blizzard",
    "gas","surge","rumble","barrier","soul","human","buddha","love","door"
}
local function IsFruit(obj)
    local n = obj.Name:lower()
    for _, k in ipairs(FruitKW) do if n:find(k) then return true end end
end
local function ScanFruits()
    local out = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsFruit(obj) then
            local pos
            if obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then pos = obj.Position end
            if pos then table.insert(out, {name=obj.Name, pos=pos}) end
        end
    end
    return out
end

local function TP(pos)
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0,4,0))
    end
end
local function TP_Player(name)
    local t = Players:FindFirstChild(name)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        TP(t.Character.HumanoidRootPart.Position)
    end
end
local function TP_NearestFruit()
    local fruits = ScanFruits(); if #fruits == 0 then return end
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    table.sort(fruits, function(a, b)
        return (char.HumanoidRootPart.Position - a.pos).Magnitude
             < (char.HumanoidRootPart.Position - b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

local Locations = {
    ["Ilha Inicial"]       = Vector3.new(-210,  28,  180),
    ["Base Marinha"]       = Vector3.new( 990,  28, -510),
    ["Ilha Buggy"]         = Vector3.new( 402,  28,-1002),
    ["Ilha da Nami"]       = Vector3.new(1250,  28,  640),
    ["Arlong Park"]        = Vector3.new(1822,  28, 1492),
    ["Baratie"]            = Vector3.new(-792,  28, 1242),
    ["Coliseu"]            = Vector3.new(1622,  28, -872),
    ["Ilha dos Tubarões"]  = Vector3.new(-3052, 28, 1978),
    ["Shanks Island"]      = Vector3.new(-1892, 28, -858),
    ["Mihawk Island"]      = Vector3.new(-2492, 28, -312),
    ["Marineford"]         = Vector3.new(2552,  28,-2058),
    ["Impel Down"]         = Vector3.new(2820,  28, 1760),
    ["Skypiea"]            = Vector3.new(-2822, 865,-1632),
    ["Upper Yard"]         = Vector3.new(-3102, 882,-1922),
    ["Sky Coliseu"]        = Vector3.new(-3200,1200,-1600),
    ["Portal 2º Mar"]      = Vector3.new( 2900,  28,  900),
}

-- ============================================================
--  GUI — estilo OMG Hub
--  Sidebar esquerda + content area + animações
-- ============================================================
local old = CoreGui:FindFirstChild("CHINAHUBV4")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "CHINAHUBV4"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.Parent = CoreGui

-- ── Paleta ──────────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(15,  15,  20),
    sidebar  = Color3.fromRGB(18,  18,  28),
    panel    = Color3.fromRGB(22,  22,  34),
    card     = Color3.fromRGB(28,  28,  42),
    accent   = Color3.fromRGB(90,  70, 220),
    accent2  = Color3.fromRGB(130, 90, 255),
    green    = Color3.fromRGB(50,  200, 100),
    red      = Color3.fromRGB(200, 55,  55),
    text     = Color3.fromRGB(220, 220, 230),
    textDim  = Color3.fromRGB(130, 130, 150),
    border   = Color3.fromRGB(50,  50,  80),
    sep      = Color3.fromRGB(35,  35,  55),
}

-- ── Helper: UICorner ────────────────────────────────────────
local function Corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 8); return c
end
local function Stroke(parent, col, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color = col or C.border; s.Thickness = thick or 1; return s
end
local function Pad(parent, l, r, t, b)
    local p = Instance.new("UIPadding", parent)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
end
local function List(parent, dir, pad, align, valign)
    local l = Instance.new("UIListLayout", parent)
    l.FillDirection        = dir    or Enum.FillDirection.Vertical
    l.Padding              = UDim.new(0, pad or 6)
    l.HorizontalAlignment  = align  or Enum.HorizontalAlignment.Left
    l.VerticalAlignment    = valign or Enum.VerticalAlignment.Top
    return l
end

-- ── Janela principal ────────────────────────────────────────
local WIN = Instance.new("Frame", SG)
WIN.Size     = UDim2.new(0, 650, 0, 490)
WIN.Position = UDim2.new(0.5, -325, 0.5, -245)
WIN.BackgroundColor3 = C.bg
WIN.BorderSizePixel  = 0
Corner(WIN, 10)
Stroke(WIN, C.border, 1.5)

-- sombra externa
local Shadow = Instance.new("ImageLabel", SG)
Shadow.Size = UDim2.new(0, 700, 0, 540)
Shadow.Position = UDim2.new(0.5, -350, 0.5, -270)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.new(0,0,0)
Shadow.ImageTransparency = 0.55
Shadow.ZIndex = 0
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
WIN.ZIndex = 1

-- ── TopBar ──────────────────────────────────────────────────
local TopBar = Instance.new("Frame", WIN)
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.sidebar
TopBar.BorderSizePixel  = 0
Corner(TopBar, 10)

-- título
local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Size = UDim2.new(1, -120, 1, 0)
TitleLbl.Position = UDim2.new(0, 54, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "⚔  China Hub Free"
TitleLbl.TextColor3 = C.text
TitleLbl.TextSize = 15
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- logo dot
local Dot = Instance.new("Frame", TopBar)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.Position = UDim2.new(0, 20, 0.5, -5)
Dot.BackgroundColor3 = C.accent2
Dot.BorderSizePixel  = 0
Corner(Dot, 5)

-- versão
local VerLbl = Instance.new("TextLabel", TopBar)
VerLbl.Size = UDim2.new(0, 60, 1, 0)
VerLbl.Position = UDim2.new(0, 36, 0, 0)
VerLbl.BackgroundTransparency = 1
VerLbl.Text = "v4.0"
VerLbl.TextColor3 = C.textDim
VerLbl.TextSize = 10
VerLbl.Font = Enum.Font.Gotham
VerLbl.TextXAlignment = Enum.TextXAlignment.Left

-- botões de janela
local function WinBtn(label, col, xOff)
    local b = Instance.new("TextButton", TopBar)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, xOff, 0.5, -14)
    b.BackgroundColor3 = col
    b.Text = label
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    Corner(b, 6)
    return b
end
local CloseBtn = WinBtn("✕", C.red,    -8)
local MinBtn   = WinBtn("−", Color3.fromRGB(50,100,180), -42)

-- drag
local dragging, dInput, dStart, dPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dStart = inp.Position; dPos = WIN.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then dInput = inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp == dInput and dragging then
        local d = inp.Position - dStart
        WIN.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X,
                                  dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Farm.Active = false; Farm.Attack = false; SG:Destroy()
end)
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in ipairs(WIN:GetChildren()) do
        if c ~= TopBar then c.Visible = not minimized end
    end
    WIN.Size = minimized and UDim2.new(0,650,0,44) or UDim2.new(0,650,0,490)
    MinBtn.Text = minimized and "+" or "−"
end)

-- ── Layout principal (sidebar + content) ────────────────────
local Layout = Instance.new("Frame", WIN)
Layout.Position = UDim2.new(0, 0, 0, 44)
Layout.Size     = UDim2.new(1, 0, 1, -44)
Layout.BackgroundTransparency = 1

-- Sidebar
local Sidebar = Instance.new("Frame", Layout)
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel  = 0
local sbList = List(Sidebar, Enum.FillDirection.Vertical, 4)
sbList.HorizontalAlignment = Enum.HorizontalAlignment.Center
Pad(Sidebar, 8, 8, 10, 10)

-- separador
local Sep = Instance.new("Frame", Sidebar)
Sep.Size = UDim2.new(1, 0, 0, 1)
Sep.BackgroundColor3 = C.sep
Sep.BorderSizePixel = 0
Sep.LayoutOrder = 100

-- player info no sidebar
local UserRow = Instance.new("Frame", Sidebar)
UserRow.Size = UDim2.new(1, 0, 0, 52)
UserRow.BackgroundColor3 = C.card
UserRow.BorderSizePixel = 0
Corner(UserRow, 8)
UserRow.LayoutOrder = 0

local UserName = Instance.new("TextLabel", UserRow)
UserName.Size = UDim2.new(1, -10, 0, 20)
UserName.Position = UDim2.new(0, 8, 0, 8)
UserName.BackgroundTransparency = 1
UserName.Text = LP.DisplayName
UserName.TextColor3 = C.text
UserName.TextSize = 11
UserName.Font = Enum.Font.GothamBold
UserName.TextXAlignment = Enum.TextXAlignment.Left

local UserLv = Instance.new("TextLabel", UserRow)
UserLv.Size = UDim2.new(1, -10, 0, 16)
UserLv.Position = UDim2.new(0, 8, 0, 29)
UserLv.BackgroundTransparency = 1
UserLv.TextColor3 = C.accent2
UserLv.TextSize = 10
UserLv.Font = Enum.Font.Gotham
UserLv.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do
        task.wait(2)
        if SG.Parent then
            UserLv.Text = "Lv " .. GetLevel()
        end
    end
end)

-- Content area
local Content = Instance.new("Frame", Layout)
Content.Position = UDim2.new(0, 160, 0, 0)
Content.Size     = UDim2.new(1, -160, 1, 0)
Content.BackgroundColor3 = C.panel
Content.BorderSizePixel  = 0

-- ── Sidebar tabs ────────────────────────────────────────────
local Pages, TabBtns = {}, {}
local ActiveTab = nil

local TabDefs = {
    { icon="🏠", label="Home",      order=1 },
    { icon="⚔",  label="Farm",      order=2 },
    { icon="👁",  label="ESP",       order=3 },
    { icon="🌀",  label="Teleport",  order=4 },
    { icon="🗺",  label="Ilhas",     order=5 },
    { icon="⚙",  label="Misc",      order=6 },
    { icon="🔔",  label="Webhook",   order=7 },
}

-- ScrollingFrame no content
local ContentScroll = Instance.new("ScrollingFrame", Content)
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = C.accent
ContentScroll.CanvasSize = UDim2.new(0,0,0,0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Pad(ContentScroll, 14, 14, 10, 10)
local contentList = List(ContentScroll, Enum.FillDirection.Vertical, 8)

local function MakePage(id)
    local pg = Instance.new("Frame", ContentScroll)
    pg.Size = UDim2.new(1, 0, 0, 0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1
    pg.Visible = false
    local l = List(pg, Enum.FillDirection.Vertical, 8)
    Pages[id] = pg
    return pg
end

local function SwitchTab(id)
    for k, pg in pairs(Pages) do
        pg.Visible = false
        if TabBtns[k] then
            TabBtns[k].BackgroundColor3 = Color3.fromRGB(0,0,0)
            TabBtns[k].BackgroundTransparency = 1
            local lbl = TabBtns[k]:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = C.textDim end
            local dot = TabBtns[k]:FindFirstChild("ActiveDot")
            if dot then dot.Visible = false end
        end
    end
    if Pages[id] then Pages[id].Visible = true end
    if TabBtns[id] then
        TabBtns[id].BackgroundColor3 = C.card
        TabBtns[id].BackgroundTransparency = 0
        local lbl = TabBtns[id]:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3 = C.text end
        local dot = TabBtns[id]:FindFirstChild("ActiveDot")
        if dot then dot.Visible = true end
    end
    ContentScroll.CanvasPosition = Vector2.new(0,0)
    ActiveTab = id
end

for _, def in ipairs(TabDefs) do
    local pg = MakePage(def.label)

    local btn = Instance.new("TextButton", Sidebar)
    btn.Name = def.label
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.LayoutOrder = def.order + 1
    Corner(btn, 6)

    -- ícone
    local iconLbl = Instance.new("TextLabel", btn)
    iconLbl.Size = UDim2.new(0, 24, 1, 0)
    iconLbl.Position = UDim2.new(0, 8, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = def.icon
    iconLbl.TextSize = 14
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextColor3 = C.textDim
    iconLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- label
    local nameLbl = Instance.new("TextLabel", btn)
    nameLbl.Size = UDim2.new(1, -38, 1, 0)
    nameLbl.Position = UDim2.new(0, 36, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = def.label
    nameLbl.TextColor3 = C.textDim
    nameLbl.TextSize = 12
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- barra ativa (esquerda)
    local dot = Instance.new("Frame", btn)
    dot.Name = "ActiveDot"
    dot.Size = UDim2.new(0, 3, 0.6, 0)
    dot.Position = UDim2.new(0, 0, 0.2, 0)
    dot.BackgroundColor3 = C.accent2
    dot.BorderSizePixel = 0
    dot.Visible = false
    Corner(dot, 2)

    TabBtns[def.label] = btn
    btn.MouseButton1Click:Connect(function() SwitchTab(def.label) end)
end

-- ── UI helpers ──────────────────────────────────────────────
local function Section(parent, text)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1

    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 8)
    line.BackgroundColor3 = C.sep
    line.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.BackgroundColor3 = C.panel
    lbl.BackgroundTransparency = 0
    lbl.Text = " " .. text .. " "
    lbl.TextColor3 = C.accent2
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
end

local function Toggle(parent, text, default, cb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = C.card
    row.BorderSizePixel = 0
    Corner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -68, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- switch pill
    local pill = Instance.new("TextButton", row)
    pill.Size = UDim2.new(0, 46, 0, 22)
    pill.Position = UDim2.new(1, -56, 0.5, -11)
    pill.Text = ""; pill.BorderSizePixel = 0
    local state = default or false
    pill.BackgroundColor3 = state and C.green or Color3.fromRGB(55,55,70)
    Corner(pill, 11)

    local thumb = Instance.new("Frame", pill)
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.Position = state and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.BorderSizePixel = 0
    Corner(thumb, 8)

    local function SetState(v)
        state = v
        local goal = v and C.green or Color3.fromRGB(55,55,70)
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3=goal}):Play()
        local tPos = v and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
        TweenService:Create(thumb, TweenInfo.new(0.15), {Position=tPos}):Play()
        if cb then cb(v) end
    end

    pill.MouseButton1Click:Connect(function() SetState(not state) end)
    return SetState
end

local function Button(parent, text, cb, accent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = accent and C.accent or C.card
    b.Text = text
    b.TextColor3 = C.text
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    Corner(b, 6)
    if not accent then Stroke(b, C.border, 1) end

    b.MouseButton1Click:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {
            BackgroundColor3 = accent and C.accent2 or Color3.fromRGB(40,40,65)
        }):Play()
        task.delay(0.15, function()
            if b and b.Parent then
                TweenService:Create(b, TweenInfo.new(0.08), {
                    BackgroundColor3 = accent and C.accent or C.card
                }):Play()
            end
        end)
        if cb then cb() end
    end)
    return b
end

local function Input(parent, hint, cb)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, 0, 0, 32)
    box.BackgroundColor3 = C.card
    box.Text = ""; box.PlaceholderText = hint
    box.PlaceholderColor3 = C.textDim
    box.TextColor3 = C.text; box.TextSize = 11
    box.Font = Enum.Font.Gotham; box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    Corner(box, 6); Stroke(box, C.border, 1)
    Pad(box, 10, 10, 0, 0)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return box
end

local function Label(parent, text, col)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = col or C.textDim
    l.TextSize = 11; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function StatusCard(parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 44)
    f.BackgroundColor3 = Color3.fromRGB(14, 24, 18)
    f.BorderSizePixel = 0
    Corner(f, 8); Stroke(f, Color3.fromRGB(30, 90, 50), 1)

    local dot2 = Instance.new("Frame", f)
    dot2.Size = UDim2.new(0, 8, 0, 8)
    dot2.Position = UDim2.new(0, 10, 0.5, -4)
    dot2.BackgroundColor3 = C.green
    dot2.BorderSizePixel = 0
    Corner(dot2, 4)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Estado: inativo"
    lbl.TextColor3 = C.green
    lbl.TextSize = 11; lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl, dot2
end

-- ============================================================
--  PÁGINA: HOME
-- ============================================================
do
    local pg = Pages["Home"]

    -- banner
    local banner = Instance.new("Frame", pg)
    banner.Size = UDim2.new(1, 0, 0, 90)
    banner.BackgroundColor3 = C.card
    banner.BorderSizePixel = 0
    Corner(banner, 10)
    Stroke(banner, C.accent, 1.5)

    local grad = Instance.new("UIGradient", banner)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 30)),
    }
    grad.Rotation = 135

    local bannerTitle = Instance.new("TextLabel", banner)
    bannerTitle.Size = UDim2.new(1, -20, 0, 36)
    bannerTitle.Position = UDim2.new(0, 14, 0, 12)
    bannerTitle.BackgroundTransparency = 1
    bannerTitle.Text = "⚔  China Hub Free"
    bannerTitle.TextColor3 = Color3.new(1,1,1)
    bannerTitle.TextSize = 18; bannerTitle.Font = Enum.Font.GothamBold
    bannerTitle.TextXAlignment = Enum.TextXAlignment.Left

    local bannerSub = Instance.new("TextLabel", banner)
    bannerSub.Size = UDim2.new(1, -20, 0, 20)
    bannerSub.Position = UDim2.new(0, 14, 0, 50)
    bannerSub.BackgroundTransparency = 1
    bannerSub.Text = "King Legacy v10.2-Sea1  |  Build v4.0"
    bannerSub.TextColor3 = C.textDim
    bannerSub.TextSize = 11; bannerSub.Font = Enum.Font.Gotham
    bannerSub.TextXAlignment = Enum.TextXAlignment.Left

    -- cards de info
    local infoRow = Instance.new("Frame", pg)
    infoRow.Size = UDim2.new(1, 0, 0, 56)
    infoRow.BackgroundTransparency = 1
    local infoList = List(infoRow, Enum.FillDirection.Horizontal, 8)
    infoList.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function InfoCard(text, val, col)
        local c2 = Instance.new("Frame", infoRow)
        c2.Size = UDim2.new(0, 130, 1, 0)
        c2.BackgroundColor3 = C.card
        c2.BorderSizePixel = 0
        Corner(c2, 8)

        local vl = Instance.new("TextLabel", c2)
        vl.Size = UDim2.new(1, 0, 0, 28)
        vl.Position = UDim2.new(0, 0, 0, 8)
        vl.BackgroundTransparency = 1
        vl.Text = val
        vl.TextColor3 = col or C.accent2
        vl.TextSize = 16; vl.Font = Enum.Font.GothamBold
        vl.TextXAlignment = Enum.TextXAlignment.Center

        local tl = Instance.new("TextLabel", c2)
        tl.Size = UDim2.new(1, 0, 0, 16)
        tl.Position = UDim2.new(0, 0, 0, 36)
        tl.BackgroundTransparency = 1
        tl.Text = text
        tl.TextColor3 = C.textDim
        tl.TextSize = 10; tl.Font = Enum.Font.Gotham
        tl.TextXAlignment = Enum.TextXAlignment.Center
        return vl
    end

    local lvCard   = InfoCard("Level", tostring(GetLevel()), C.accent2)
    local farmCard = InfoCard("Farm", "OFF", C.red)
    local statCard = InfoCard("Status", "Idle", C.textDim)

    task.spawn(function()
        while SG.Parent do
            task.wait(1.5)
            lvCard.Text   = tostring(GetLevel())
            farmCard.Text = Farm.Active and "ON" or "OFF"
            farmCard.Parent.Parent:FindFirstChild("TextLabel") -- dummy
            -- ajusta cor
            local lv2 = farmCard:FindFirstAncestorOfClass("Frame")
            farmCard.TextColor3 = Farm.Active and C.green or C.red
            statCard.Text = Farm.Active and Farm.State or "idle"
        end
    end)

    Section(pg, "Sobre")
    Label(pg, "  Script gratuito para King Legacy.")
    Label(pg, "  Auto Farm com detecção de NPC de Missão.")
    Label(pg, "  Use o botão Calibrar se a zona estiver errada.")
    Label(pg, "  Tecla "..tostring(Cfg.HideKey).." — ocultar/mostrar painel.")
end

-- ============================================================
--  PÁGINA: FARM
-- ============================================================
do
    local pg = Pages["Farm"]

    local statusLbl, statusDot = StatusCard(pg)
    task.spawn(function()
        while SG.Parent do
            task.wait(0.8)
            statusLbl.Text = Farm.Active and Farm.StatusText or "Estado: inativo"
            statusDot.BackgroundColor3 = Farm.Active and C.green or C.red
        end
    end)

    Section(pg, "Auto Farm")
    Toggle(pg, "🗺  Auto Farm Level (Quest)", false, function(v)
        Farm.Active = v; if not v then Farm.State = "idle" end
    end)
    Toggle(pg, "👊  Auto M1 (ataque livre)", false, function(v)
        Farm.Attack = v
    end)

    Section(pg, "📍 Calibrar Zonas")
    Label(pg, "  Vá até o ponto desejado, selecione a zona e clique calibrar.")

    -- zone selector
    local selIdx = 1
    local selLbl = Instance.new("TextLabel", pg)
    selLbl.Size = UDim2.new(1, 0, 0, 28)
    selLbl.BackgroundColor3 = C.card
    selLbl.BorderSizePixel = 0
    selLbl.Text = "Zona: " .. QuestZones[1].name
    selLbl.TextColor3 = C.accent2
    selLbl.TextSize = 11; selLbl.Font = Enum.Font.GothamBold
    Corner(selLbl, 6)

    local arrowRow = Instance.new("Frame", pg)
    arrowRow.Size = UDim2.new(1, 0, 0, 32)
    arrowRow.BackgroundTransparency = 1
    local arrowList = List(arrowRow, Enum.FillDirection.Horizontal, 6)

    local function ArrowBtn(t, cb)
        local b = Instance.new("TextButton", arrowRow)
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.BackgroundColor3 = C.card
        b.Text = t; b.TextColor3 = C.text
        b.TextSize = 12; b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
