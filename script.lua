-- ============================================================
--  China Hub Free v4.1 — King Legacy
--  Farm reescrito | NPC scan automático | Seletor Melee/Sword/Fruit
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
    Col_Player  = Color3.fromRGB(255, 80, 80),
    Col_Fruit   = Color3.fromRGB(80, 220, 80),
}

local Farm = {
    Active      = false,
    State       = "idle",  -- idle | toisle | toquest | fighting | returning
    Timer       = 0,
    Zone        = nil,
    Style       = "melee", -- melee | sword | fruit
    StatusText  = "Inativo",
    KillCount   = 0,
    TargetKills = 10,
}
local AutoAttack  = false
local questNPCRef = nil
local SEA_Y       = 8
local SCAN_RADIUS = 300
local QUEST_TIMEOUT = 120

-- ============================================================
--  DRAWING
-- ============================================================
local function NewText(col, sz)
    local t = Drawing.new("Text")
    t.Color=col or Color3.new(1,1,1); t.Size=sz or 13
    t.Center=true; t.Outline=true; t.Visible=false; return t
end
local function NewBox(col, filled)
    local b = Drawing.new("Square")
    b.Color=col or Color3.new(1,1,1); b.Thickness=1.5
    b.Filled=filled or false; b.Visible=false; return b
end
local function NewLine(col)
    local l = Drawing.new("Line")
    l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Visible=false; return l
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
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local safeY = math.max(pos.Y, 20)
    char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(pos.X, safeY, pos.Z))
    task.wait(0.5)
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        Farm.State = "idle"
        Farm.StatusText = "⚠ Detectado no mar — resetando"
        if Farm.Zone then
            char.HumanoidRootPart.CFrame =
                CFrame.new(Farm.Zone.islePos + Vector3.new(0,15,0))
        end
        return false
    end
    return true
end

-- ============================================================
--  ZONAS
-- ============================================================
local QuestZones = {
    { name="Ilha Inicial",      minLv=1,   maxLv=14,
      islePos=Vector3.new(-210,28,180),    mobPos=Vector3.new(-268,20,215) },
    { name="Base Marinha",      minLv=15,  maxLv=34,
      islePos=Vector3.new(990,28,-510),    mobPos=Vector3.new(948,20,-472) },
    { name="Ilha Buggy",        minLv=35,  maxLv=59,
      islePos=Vector3.new(402,28,-1002),   mobPos=Vector3.new(465,20,-958) },
    { name="Baratie",           minLv=60,  maxLv=89,
      islePos=Vector3.new(-792,28,1242),   mobPos=Vector3.new(-832,20,1198) },
    { name="Arlong Park",       minLv=90,  maxLv=124,
      islePos=Vector3.new(1822,28,1492),   mobPos=Vector3.new(1778,20,1448) },
    { name="Coliseu",           minLv=125, maxLv=174,
      islePos=Vector3.new(1622,28,-872),   mobPos=Vector3.new(1575,20,-935) },
    { name="Ilha dos Tubarões", minLv=175, maxLv=224,
      islePos=Vector3.new(-3052,28,1978),  mobPos=Vector3.new(-3105,20,2022) },
    { name="Marineford",        minLv=225, maxLv=274,
      islePos=Vector3.new(2552,28,-2058),  mobPos=Vector3.new(2508,20,-2135) },
    { name="Shanks Island",     minLv=275, maxLv=324,
      islePos=Vector3.new(-1892,28,-858),  mobPos=Vector3.new(-1945,20,-802) },
    { name="Mihawk Island",     minLv=325, maxLv=374,
      islePos=Vector3.new(-2492,28,-312),  mobPos=Vector3.new(-2562,20,-375) },
    { name="Skypiea",           minLv=375, maxLv=449,
      islePos=Vector3.new(-2822,865,-1632),mobPos=Vector3.new(-2892,858,-1702) },
    { name="Upper Yard",        minLv=450, maxLv=999,
      islePos=Vector3.new(-3102,882,-1922),mobPos=Vector3.new(-3172,872,-1992) },
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
--  Duplo critério: ActionText + BillboardGui com "Missão"
-- ============================================================
local BOAT_NAMES = {
    "boat","ship","navio","ferry","barca","vessel",
    "galleon","embarca","pirate ship","marine ship","barco"
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
                    if t:find("miss") or t:find("quest") then return true end
                end
            end
        end
    end
    return false
end

-- Scan principal — encontra NPC de missão mais próximo de um ponto
local function FindMissionNPC(nearPos, maxRadius)
    maxRadius = maxRadius or SCAN_RADIUS
    local best, bestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj:IsA("ProximityPrompt") then continue end
        local part = obj.Parent
        if not (part and part:IsA("BasePart")) then continue end
        if part.Position.Y < SEA_Y then continue end
        if IsBoatDescendant(part) then continue end

        local d = (part.Position - nearPos).Magnitude
        if d >= maxRadius or d >= bestDist then continue end

        local at = (obj.ActionText or ""):lower()
        local isQuestPrompt = at:find("interagir") or at:find("interact")
            or at:find("quest") or at:find("miss")

        local model = part.Parent
        local hasMissaoUI = model and model:IsA("Model") and HasMissaoLabel(model)

        if isQuestPrompt or hasMissaoUI then
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
--  MOB PRÓXIMO
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
                   (hrp.Position - zoneCenter).Magnitude > (zoneRadius or 400) then
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
--  ESTILOS DE ATAQUE
-- ============================================================
local function EquipSword()
    local char = LP.Character
    if not char or not char:FindFirstChild("Humanoid") then return false end
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("sword") or n:find("katana") or n:find("blade")
               or n:find("cutlass") or n:find("saber") or n:find("espada")
               or n:find("knife") or n:find("dao") or n:find("gun") then
                char.Humanoid:EquipTool(tool)
                task.wait(0.3)
                return true
            end
        end
    end
    -- fallback: equipa a primeira tool
    local t = LP.Backpack:FindFirstChildOfClass("Tool")
    if t then char.Humanoid:EquipTool(t); task.wait(0.3); return true end
    return false
end

local function PressKey(keyCode)
    local pressed = false
    pcall(function()
        if syn and syn.key_press then
            syn.key_press(keyCode); task.wait(0.1); syn.key_release(keyCode)
            pressed = true
        end
    end)
    if not pressed then
        pcall(function()
            if keypress then
                keypress(keyCode); task.wait(0.1)
                if keyrelease then keyrelease(keyCode) end
                pressed = true
            end
        end)
    end
    return pressed
end

local function AttackMob(mob)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
    if dist > 7 then
        char.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(3,2,0))
        task.wait(0.08)
    end

    if Farm.Style == "fruit" then
        -- Tenta Z, depois X, fallback M1
        if not PressKey(0x5A) then -- Z
            local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
            if onScr then VirtualUser:ClickButton1(Vector2.new(sp.X,sp.Y), CFrame.new()) end
        end
    elseif Farm.Style == "sword" then
        EquipSword()
        local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
        if onScr then VirtualUser:ClickButton1(Vector2.new(sp.X,sp.Y), CFrame.new()) end
    else
        -- melee padrão
        local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
        if onScr then VirtualUser:ClickButton1(Vector2.new(sp.X,sp.Y), CFrame.new()) end
    end
end

-- ============================================================
--  AUTO ATAQUE INDEPENDENTE
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not AutoAttack then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(2); continue end
        local mob = NearestMob()
        if mob then AttackMob(mob) end
    end
end)

-- ============================================================
--  AUTO FARM — máquina de estado corrigida
--  idle → toisle → toquest → fighting → returning → idle
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if not Farm.Active then Farm.State = "idle"; continue end

        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1); continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            Farm.StatusText = "⏳ Aguardando respawn..."
            Farm.State = "idle"; task.wait(4); continue
        end

        local lv   = GetLevel()
        local zone = GetZoneForLevel(lv)

        -- ── idle ──────────────────────────────────────────────
        if Farm.State == "idle" then
            Farm.Zone       = zone
            Farm.KillCount  = 0
            questNPCRef     = nil
            Farm.State      = "toisle"
            Farm.Timer      = tick()
            Farm.StatusText = ("Lv %d → %s | Viajando..."):format(lv, zone.name)

        -- ── toisle: TP para o centro da ilha ──────────────────
        elseif Farm.State == "toisle" then
            local ok = SafeTP(Farm.Zone.islePos)
            task.wait(1.3)
            if not ok then Farm.State = "idle"; continue end
            Farm.StatusText = ("Lv %d → %s | Procurando NPC de Missão..."):format(lv, zone.name)
            Farm.State = "toquest"
            Farm.Timer = tick()

        -- ── toquest: scan e aceita missão ─────────────────────
        elseif Farm.State == "toquest" then
            local npc, npcDist = FindMissionNPC(Farm.Zone.islePos, SCAN_RADIUS)

            if npc then
                questNPCRef = npc
                local npcPart = npc.Parent
                -- TP direto no NPC
                if npcPart and npcPart:IsA("BasePart") and npcPart.Position.Y >= SEA_Y then
                    char.HumanoidRootPart.CFrame =
                        CFrame.new(npcPart.Position + Vector3.new(3,1,0))
                    task.wait(0.75)
                end
                -- Aceita missão
                FirePrompt(npc); task.wait(0.5)
                FirePrompt(npc); task.wait(0.5)
                Farm.StatusText = ("Lv %d → %s | ✓ Missão aceita!"):format(lv, zone.name)
                -- Equipa arma se necessário
                if Farm.Style == "sword" then EquipSword() end
                -- TP para mobs
                SafeTP(Farm.Zone.mobPos); task.wait(1.1)
                Farm.State     = "fighting"
                Farm.KillCount = 0
                Farm.Timer     = tick()
            else
                Farm.StatusText = ("Lv %d → %s | NPC não achado (raio %d)..."):format(
                    lv, zone.name, SCAN_RADIUS)
                -- Timeout de 15s: vai para mobs de qualquer forma
                if tick() - Farm.Timer > 15 then
                    SafeTP(Farm.Zone.mobPos); task.wait(1.1)
                    Farm.State = "fighting"; Farm.Timer = tick()
                else
                    task.wait(2)
                end
            end

        -- ── fighting: mata mobs e conta kills ─────────────────
        elseif Farm.State == "fighting" then
            if tick() - Farm.Timer > QUEST_TIMEOUT then
                Farm.State = "returning"; continue
            end

            local mob, dist = NearestMob(Farm.Zone.mobPos, 400)

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                if hrp.Position.Y < SEA_Y then task.wait(0.5); continue end

                local humBefore = mob:FindFirstChildOfClass("Humanoid")
                local hpBefore  = humBefore and humBefore.Health or 0

                AttackMob(mob); task.wait(0.18)

                local humAfter = mob:FindFirstChildOfClass("Humanoid")
                if not humAfter or humAfter.Health <= 0 then
                    if hpBefore > 0 then Farm.KillCount = Farm.KillCount + 1 end
                end

                local curHp = humAfter and math.floor(humAfter.Health) or 0
                Farm.StatusText = ("Lv %d → %s | Kills: %d/%d | HP mob: %d"):format(
                    lv, zone.name, Farm.KillCount, Farm.TargetKills, curHp)

                if Farm.KillCount >= Farm.TargetKills then
                    Farm.State = "returning"
                end
            else
                Farm.StatusText = ("Lv %d → %s | Aguardando respawn... (%d/%d kills)"):format(
                    lv, zone.name, Farm.KillCount, Farm.TargetKills)
                if Farm.KillCount >= Farm.TargetKills then
                    Farm.State = "returning"
                end
                task.wait(1.5)
            end

        -- ── returning: entrega missão e reinicia ──────────────
        elseif Farm.State == "returning" then
            Farm.StatusText = ("Lv %d → %s | Entregando missão..."):format(lv, zone.name)

            SafeTP(Farm.Zone.islePos); task.wait(1.1)

            local retNpc = questNPCRef
            if not retNpc or not retNpc.Parent then
                retNpc = FindMissionNPC(Farm.Zone.islePos, SCAN_RADIUS)
            end

            if retNpc then
                local npcPart = retNpc.Parent
                if npcPart and npcPart:IsA("BasePart") then
                    char.HumanoidRootPart.CFrame =
                        CFrame.new(npcPart.Position + Vector3.new(3,1,0))
                    task.wait(0.75)
                end
                FirePrompt(retNpc); task.wait(0.5)
                FirePrompt(retNpc); task.wait(0.5)
                Farm.StatusText = ("Lv %d → %s | ✓ Missão entregue! Reiniciando..."):format(lv, zone.name)
            else
                Farm.StatusText = ("Lv %d → %s | NPC de entrega não achado"):format(lv, zone.name)
            end

            task.wait(1.0)
            Farm.State = "idle"
        end
    end
end)

-- ============================================================
--  FRUTAS / TP
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
    ["Ilha Inicial"]      = Vector3.new(-210, 28, 180),
    ["Base Marinha"]      = Vector3.new(990,  28,-510),
    ["Ilha Buggy"]        = Vector3.new(402,  28,-1002),
    ["Ilha da Nami"]      = Vector3.new(1250, 28, 640),
    ["Arlong Park"]       = Vector3.new(1822, 28, 1492),
    ["Baratie"]           = Vector3.new(-792, 28, 1242),
    ["Coliseu"]           = Vector3.new(1622, 28,-872),
    ["Ilha dos Tubarões"] = Vector3.new(-3052,28, 1978),
    ["Shanks Island"]     = Vector3.new(-1892,28,-858),
    ["Mihawk Island"]     = Vector3.new(-2492,28,-312),
    ["Marineford"]        = Vector3.new(2552, 28,-2058),
    ["Impel Down"]        = Vector3.new(2820, 28, 1760),
    ["Skypiea"]           = Vector3.new(-2822,865,-1632),
    ["Upper Yard"]        = Vector3.new(-3102,882,-1922),
    ["Sky Coliseu"]       = Vector3.new(-3200,1200,-1600),
    ["Portal 2º Mar"]     = Vector3.new(2900, 28, 900),
}

-- ============================================================
--  GUI
-- ============================================================
local old = CoreGui:FindFirstChild("CHINAHUBV4")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "CHINAHUBV4"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true; SG.Parent = CoreGui

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

local function Corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c
end
local function Stroke(p, col, t)
    local s = Instance.new("UIStroke", p); s.Color = col or C.border; s.Thickness = t or 1; return s
end
local function Pad(p, l, r, t, b)
    local pad = Instance.new("UIPadding", p)
    pad.PaddingLeft=UDim.new(0,l or 0); pad.PaddingRight=UDim.new(0,r or 0)
    pad.PaddingTop=UDim.new(0,t or 0);  pad.PaddingBottom=UDim.new(0,b or 0)
end
local function List(p, dir, pad, ha, va)
    local l = Instance.new("UIListLayout", p)
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.Padding=UDim.new(0, pad or 6)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Top
    return l
end

-- Janela
local WIN = Instance.new("Frame", SG)
WIN.Size=UDim2.new(0,650,0,490); WIN.Position=UDim2.new(0.5,-325,0.5,-245)
WIN.BackgroundColor3=C.bg; WIN.BorderSizePixel=0
Corner(WIN, 10); Stroke(WIN, C.border, 1.5)

-- TopBar
local TopBar = Instance.new("Frame", WIN)
TopBar.Size=UDim2.new(1,0,0,44); TopBar.BackgroundColor3=C.sidebar; TopBar.BorderSizePixel=0
Corner(TopBar, 10)

local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Size=UDim2.new(1,-120,1,0); TitleLbl.Position=UDim2.new(0,54,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="⚔  China Hub Free"
TitleLbl.TextColor3=C.text; TitleLbl.TextSize=15; TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left

local Dot = Instance.new("Frame", TopBar)
Dot.Size=UDim2.new(0,10,0,10); Dot.Position=UDim2.new(0,20,0.5,-5)
Dot.BackgroundColor3=C.accent2; Dot.BorderSizePixel=0; Corner(Dot, 5)

local function WinBtn(label, col, xOff)
    local b = Instance.new("TextButton", TopBar)
    b.Size=UDim2.new(0,28,0,28); b.Position=UDim2.new(1,xOff,0.5,-14)
    b.BackgroundColor3=col; b.Text=label; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    Corner(b, 6); return b
end
local CloseBtn = WinBtn("✕", C.red,                      -8)
local MinBtn   = WinBtn("−", Color3.fromRGB(50,100,180), -42)

-- drag
local dragging, dInput, dStart, dPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dStart=inp.Position; dPos=WIN.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseMovement then dInput=inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp==dInput and dragging then
        local d=inp.Position-dStart
        WIN.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Farm.Active=false; AutoAttack=false; SG:Destroy()
end)
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    for _, c in ipairs(WIN:GetChildren()) do
        if c~=TopBar then c.Visible=not minimized end
    end
    WIN.Size=minimized and UDim2.new(0,650,0,44) or UDim2.new(0,650,0,490)
    MinBtn.Text=minimized and "+" or "−"
end)

-- Layout sidebar + content
local Layout = Instance.new("Frame", WIN)
Layout.Position=UDim2.new(0,0,0,44); Layout.Size=UDim2.new(1,0,1,-44)
Layout.BackgroundTransparency=1

local Sidebar = Instance.new("Frame", Layout)
Sidebar.Size=UDim2.new(0,160,1,0); Sidebar.BackgroundColor3=C.sidebar; Sidebar.BorderSizePixel=0
local sbList = List(Sidebar, Enum.FillDirection.Vertical, 4)
sbList.HorizontalAlignment=Enum.HorizontalAlignment.Center
Pad(Sidebar, 8, 8, 10, 10)

local UserRow = Instance.new("Frame", Sidebar)
UserRow.Size=UDim2.new(1,0,0,52); UserRow.BackgroundColor3=C.card
UserRow.BorderSizePixel=0; Corner(UserRow, 8); UserRow.LayoutOrder=0

local UserName = Instance.new("TextLabel", UserRow)
UserName.Size=UDim2.new(1,-10,0,20); UserName.Position=UDim2.new(0,8,0,8)
UserName.BackgroundTransparency=1; UserName.Text=LP.DisplayName
UserName.TextColor3=C.text; UserName.TextSize=11; UserName.Font=Enum.Font.GothamBold
UserName.TextXAlignment=Enum.TextXAlignment.Left

local UserLv = Instance.new("TextLabel", UserRow)
UserLv.Size=UDim2.new(1,-10,0,16); UserLv.Position=UDim2.new(0,8,0,29)
UserLv.BackgroundTransparency=1; UserLv.TextColor3=C.accent2
UserLv.TextSize=10; UserLv.Font=Enum.Font.Gotham; UserLv.TextXAlignment=Enum.TextXAlignment.Left

task.spawn(function()
    while SG.Parent do task.wait(2); UserLv.Text="Lv "..GetLevel() end
end)

local Content = Instance.new("Frame", Layout)
Content.Position=UDim2.new(0,160,0,0); Content.Size=UDim2.new(1,-160,1,0)
Content.BackgroundColor3=C.panel; Content.BorderSizePixel=0

local ContentScroll = Instance.new("ScrollingFrame", Content)
ContentScroll.Size=UDim2.new(1,0,1,0); ContentScroll.BackgroundTransparency=1
ContentScroll.ScrollBarThickness=4; ContentScroll.ScrollBarImageColor3=C.accent
ContentScroll.CanvasSize=UDim2.new(0,0,0,0); ContentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
Pad(ContentScroll, 14, 14, 10, 10)
List(ContentScroll, Enum.FillDirection.Vertical, 8)

local Pages, TabBtns = {}, {}

local function MakePage(id)
    local pg = Instance.new("Frame", ContentScroll)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false
    List(pg, Enum.FillDirection.Vertical, 8)
    Pages[id]=pg; return pg
end

local function SwitchTab(id)
    for k, pg in pairs(Pages) do
        pg.Visible=false
        if TabBtns[k] then
            TabBtns[k].BackgroundTransparency=1
            local l=TabBtns[k]:FindFirstChildOfClass("TextLabel")
            if l then l.TextColor3=C.textDim end
            local d=TabBtns[k]:FindFirstChild("ActiveDot")
            if d then d.Visible=false end
        end
    end
    if Pages[id] then Pages[id].Visible=true end
    if TabBtns[id] then
        TabBtns[id].BackgroundColor3=C.card; TabBtns[id].BackgroundTransparency=0
        local l=TabBtns[id]:FindFirstChildOfClass("TextLabel")
        if l then l.TextColor3=C.text end
        local d=TabBtns[id]:FindFirstChild("ActiveDot")
        if d then d.Visible=true end
    end
    ContentScroll.CanvasPosition=Vector2.new(0,0)
end

local TabDefs = {
    {icon="🏠",label="Home",    order=1},
    {icon="⚔", label="Farm",    order=2},
    {icon="👁", label="ESP",     order=3},
    {icon="🌀", label="Teleport",order=4},
    {icon="🏝", label="Ilhas",   order=5},
    {icon="⚙", label="Misc",    order=6},
    {icon="🔔", label="Webhook", order=7},
}

for _, def in ipairs(TabDefs) do
    MakePage(def.label)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name=def.label; btn.Size=UDim2.new(1,0,0,36)
    btn.BackgroundTransparency=1; btn.Text=""; btn.LayoutOrder=def.order+1
    Corner(btn, 6)

    local iconL = Instance.new("TextLabel", btn)
    iconL.Size=UDim2.new(0,24,1,0); iconL.Position=UDim2.new(0,8,0,0)
    iconL.BackgroundTransparency=1; iconL.Text=def.icon; iconL.TextSize=14
    iconL.Font=Enum.Font.GothamBold; iconL.TextColor3=C.textDim
    iconL.TextXAlignment=Enum.TextXAlignment.Center

    local nameL = Instance.new("TextLabel", btn)
    nameL.Size=UDim2.new(1,-38,1,0); nameL.Position=UDim2.new(0,36,0,0)
    nameL.BackgroundTransparency=1; nameL.Text=def.label; nameL.TextColor3=C.textDim
    nameL.TextSize=12; nameL.Font=Enum.Font.GothamBold
    nameL.TextXAlignment=Enum.TextXAlignment.Left

    local adot = Instance.new("Frame", btn)
    adot.Name="ActiveDot"; adot.Size=UDim2.new(0,3,0.6,0); adot.Position=UDim2.new(0,0,0.2,0)
    adot.BackgroundColor3=C.accent2; adot.BorderSizePixel=0; adot.Visible=false
    Corner(adot, 2)

    TabBtns[def.label]=btn
    btn.MouseButton1Click:Connect(function() SwitchTab(def.label) end)
end

-- ── UI helpers ───────────────────────────────────────────────
local function Section(parent, text)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,0,0,24); row.BackgroundTransparency=1

    local line = Instance.new("Frame", row)
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,8)
    line.BackgroundColor3=C.sep; line.BorderSizePixel=0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(0,0,1,0); lbl.AutomaticSize=Enum.AutomaticSize.X
    lbl.BackgroundColor3=C.panel; lbl.BackgroundTransparency=0
    lbl.Text=" "..text.." "; lbl.TextColor3=C.accent2
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamBold
end

local function Toggle(parent, text, default, cb)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=C.card; row.BorderSizePixel=0
    Corner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.text
    lbl.TextSize=12; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill = Instance.new("TextButton", row)
    pill.Size=UDim2.new(0,46,0,22); pill.Position=UDim2.new(1,-56,0.5,-11)
    pill.Text=""; pill.BorderSizePixel=0
    local state = default or false
    pill.BackgroundColor3=state and C.green or Color3.fromRGB(55,55,70)
    Corner(pill, 11)

    local thumb = Instance.new("Frame", pill)
    thumb.Size=UDim2.new(0,16,0,16)
    thumb.Position=state and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; Corner(thumb, 8)

    local function SetState(v)
        state=v
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=v and C.green or Color3.fromRGB(55,55,70)}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=v and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)}):Play()
        if cb then cb(v) end
    end
    pill.MouseButton1Click:Connect(function() SetState(not state) end)
    return SetState
end

local function Button(parent, text, cb, accent)
    local b = Instance.new("TextButton", parent)
    b.Size=UDim2.new(1,0,0,34)
    b.BackgroundColor3=accent and C.accent or C.card
    b.Text=text; b.TextColor3=C.text; b.TextSize=12
    b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    Corner(b, 6)
    if not accent then Stroke(b, C.border, 1) end
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=accent and C.accent2 or Color3.fromRGB(40,40,65)}):Play()
        task.delay(0.15, function()
            if b and b.Parent then
                TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=accent and C.accent or C.card}):Play()
            end
        end)
        if cb then cb() end
    end)
    return b
end

local function Input(parent, hint, cb)
    local box = Instance.new("TextBox", parent)
    box.Size=UDim2.new(1,0,0,32); box.BackgroundColor3=C.card
    box.Text=""; box.PlaceholderText=hint; box.PlaceholderColor3=C.textDim
    box.TextColor3=C.text; box.TextSize=11; box.Font=Enum.Font.Gotham
    box.BorderSizePixel=0; box.ClearTextOnFocus=false
    Corner(box, 6); Stroke(box, C.border, 1); Pad(box, 10, 10, 0, 0)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return box
end

local function Label(parent, text, col)
    local l = Instance.new("TextLabel", parent)
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1; l.Text=text
    l.TextColor3=col or C.textDim; l.TextSize=11; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
end

-- ============================================================
--  HOME
-- ============================================================
do
    local pg = Pages["Home"]

    local banner = Instance.new("Frame", pg)
    banner.Size=UDim2.new(1,0,0,88); banner.BackgroundColor3=C.card; banner.BorderSizePixel=0
    Corner(banner, 10); Stroke(banner, C.accent, 1.5)
    local grad = Instance.new("UIGradient", banner)
    grad.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(40,20,90)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(15,15,30))}
    grad.Rotation=135

    local banT = Instance.new("TextLabel", banner)
    banT.Size=UDim2.new(1,-20,0,34); banT.Position=UDim2.new(0,14,0,10)
    banT.BackgroundTransparency=1; banT.Text="⚔  China Hub Free"
    banT.TextColor3=Color3.new(1,1,1); banT.TextSize=18; banT.Font=Enum.Font.GothamBold
    banT.TextXAlignment=Enum.TextXAlignment.Left

    local banS = Instance.new("TextLabel", banner)
    banS.Size=UDim2.new(1,-20,0,20); banS.Position=UDim2.new(0,14,0,50)
    banS.BackgroundTransparency=1; banS.Text="King Legacy v10.2-Sea1  |  Build v4.1"
    banS.TextColor3=C.textDim; banS.TextSize=11; banS.Font=Enum.Font.Gotham
    banS.TextXAlignment=Enum.TextXAlignment.Left

    -- Info cards
    local infoRow = Instance.new("Frame", pg)
    infoRow.Size=UDim2.new(1,0,0,56); infoRow.BackgroundTransparency=1
    local iList = List(infoRow, Enum.FillDirection.Horizontal, 8)
    iList.HorizontalAlignment=Enum.HorizontalAlignment.Left

    local function InfoCard(label, val, col)
        local c2 = Instance.new("Frame", infoRow)
        c2.Size=UDim2.new(0,128,1,0); c2.BackgroundColor3=C.card; c2.BorderSizePixel=0
        Corner(c2, 8)
        local vl = Instance.new("TextLabel", c2)
        vl.Size=UDim2.new(1,0,0,28); vl.Position=UDim2.new(0,0,0,8)
        vl.BackgroundTransparency=1; vl.Text=val; vl.TextColor3=col or C.accent2
        vl.TextSize=16; vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Center
        local tl = Instance.new("TextLabel", c2)
        tl.Size=UDim2.new(1,0,0,16); tl.Position=UDim2.new(0,0,0,36)
        tl.BackgroundTransparency=1; tl.Text=label; tl.TextColor3=C.textDim
        tl.TextSize=10; tl.Font=Enum.Font.Gotham; tl.TextXAlignment=Enum.TextXAlignment.Center
        return vl
    end

    local lvCard    = InfoCard("Level",  tostring(GetLevel()), C.accent2)
    local farmCard  = InfoCard("Farm",   "OFF",    C.red)
    local styleCard = InfoCard("Estilo", "Melee",  C.green)

    task.spawn(function()
        while SG.Parent do
            task.wait(1.5)
            lvCard.Text    = tostring(GetLevel())
            farmCard.Text  = Farm.Active and "ON" or "OFF"
            farmCard.TextColor3 = Farm.Active and C.green or C.red
            styleCard.Text = Farm.Style:sub(1,1):upper()..Farm.Style:sub(2)
        end
    end)

    Section(pg, "Sobre")
    Label(pg, "  Auto Farm com scan automático de NPC de Missão.")
    Label(pg, "  Suporte a Melee, Sword e Fruit.")
    Label(pg, "  Calibre as zonas se o TP for para lugar errado.")
    Label(pg, "  Tecla "..tostring(Cfg.HideKey).." — ocultar/mostrar.")
end

-- ============================================================
--  FARM
-- ============================================================
do
    local pg = Pages["Farm"]

    -- Status card
    local statusF = Instance.new("Frame", pg)
    statusF.Size=UDim2.new(1,0,0,46); statusF.BackgroundColor3=Color3.fromRGB(14,24,18)
    statusF.BorderSizePixel=0; Corner(statusF, 8); Stroke(statusF, Color3.fromRGB(30,90,50), 1)

    local statusDot = Instance.new("Frame", statusF)
    statusDot.Size=UDim2.new(0,8,0,8); statusDot.Position=UDim2.new(0,10,0.5,-4)
    statusDot.BackgroundColor3=C.red; statusDot.BorderSizePixel=0; Corner(statusDot, 4)

    local statusLbl = Instance.new("TextLabel", statusF)
    statusLbl.Size=UDim2.new(1,-28,1,0); statusLbl.Position=UDim2.new(0,24,0,0)
    statusLbl.BackgroundTransparency=1; statusLbl.Text="Estado: inativo"
    statusLbl.TextColor3=C.green; statusLbl.TextSize=11; statusLbl.Font=Enum.Font.GothamBold
    statusLbl.TextXAlignment=Enum.TextXAlignment.Left

    task.spawn(function()
        while SG.Parent do
            task.wait(0.8)
            statusLbl.Text=Farm.Active and Farm.StatusText or "Estado: inativo"
            statusDot.BackgroundColor3=Farm.Active and C.green or C.red
        end
    end)

    Section(pg, "Auto Farm")
    Toggle(pg, "🗺  Auto Farm Level (Quest)", false, function(v)
        Farm.Active=v; if not v then Farm.State="idle" end
    end)
    Toggle(pg, "👊  Auto Ataque (ataque livre)", false, function(v)
        AutoAttack=v
    end)

    -- ── SELETOR DE ESTILO ───────────────────────────────────
    Section(pg, "🎮 Estilo de Luta")
    Label(pg, "  Escolha o estilo de combate para o farm:")

    local styleRow = Instance.new("Frame", pg)
    styleRow.Size=UDim2.new(1,0,0,42); styleRow.BackgroundTransparency=1
    local sRL = List(styleRow, Enum.FillDirection.Horizontal, 6)
    sRL.HorizontalAlignment=Enum.HorizontalAlignment.Left

    local styleButtons = {}
    local styles = {
        { key="melee", icon="🥊", label="Melee" },
        { key="sword", icon="⚔️", label="Sword" },
        { key="fruit", icon="🍎", label="Fruit" },
    }

    local function SetStyle(key)
        Farm.Style = key
        for _, sb in ipairs(styleButtons) do
            local isActive = sb.key == key
            TweenService:Create(sb.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = isActive and C.accent or C.card
            }):Play()
            sb.iconL.TextColor3 = isActive and Color3.new(1,1,1) or C.textDim
            sb.nameL.TextColor3 = isActive and Color3.new(1,1,1) or C.textDim
            sb.nameL.Font = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end

    for _, st in ipairs(styles) do
        local btn = Instance.new("TextButton", styleRow)
        btn.Size=UDim2.new(0,122,1,0); btn.Text=""
        btn.BackgroundColor3 = st.key=="melee" and C.accent or C.card
        btn.BorderSizePixel=0; Corner(btn, 8)
        if st.key~="melee" then Stroke(btn, C.border, 1) end

        local iconL = Instance.new("TextLabel", btn)
        iconL.Size=UDim2.new(1,0,0,22); iconL.Position=UDim2.new(0,0,0,4)
        iconL.BackgroundTransparency=1; iconL.Text=st.icon; iconL.TextSize=16
        iconL.Font=Enum.Font.GothamBold
        iconL.TextColor3=st.key=="melee" and Color3.new(1,1,1) or C.textDim
        iconL.TextXAlignment=Enum.TextXAlignment.Center

        local nameL = Instance.new("TextLabel", btn)
        nameL.Size=UDim2.new(1,0,0,16); nameL.Position=UDim2.new(0,0,0,24)
        nameL.BackgroundTransparency=1; nameL.Text=st.label; nameL.TextSize=11
        nameL.Font=st.key=="melee" and Enum.Font.GothamBold or Enum.Font.Gotham
        nameL.TextColor3=st.key=="melee" and Color3.new(1,1,1) or C.textDim
        nameL.TextXAlignment=Enum.TextXAlignment.Center

        table.insert(styleButtons, {key=st.key, btn=btn, iconL=iconL, nameL=nameL})
        btn.MouseButton1Click:Connect(function() SetStyle(st.key) end)
    end

    -- Descrição do estilo
    local styleDesc = Instance.new("TextLabel", pg)
    styleDesc.Size=UDim2.new(1,0,0,16); styleDesc.BackgroundTransparency=1
    styleDesc.TextColor3=C.textDim; styleDesc.TextSize=10; styleDesc.Font=Enum.Font.Gotham
    styleDesc.TextXAlignment=Enum.TextXAlignment.Left
    local styleDescs = {
        melee = "  🥊 Melee: soco padrão (M1)",
        sword = "  ⚔️ Sword: equipa espada/katana do backpack + M1",
        fruit = "  🍎 Fruit: pressiona Z para habilidade (fallback: M1)",
    }
    task.spawn(function()
        while SG.Parent do
            task.wait(0.4); styleDesc.Text=styleDescs[Farm.Style] or ""
        end
    end)

    -- Kills por ciclo
    Section(pg, "⚙️ Configurações")
    Label(pg, "  Mobs para matar antes de entregar missão:")
    local killIn = Input(pg, "10", function(v)
        local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end
    end)
    killIn.Text="10"

    -- Calibrar zonas
    Section(pg, "📍 Calibrar Zonas")
    Label(pg, "  Vá até o ponto e clique calibrar para corrigir TP.")

    local selIdx=1
    local selLbl = Instance.new("TextLabel", pg)
    selLbl.Size=UDim2.new(1,0,0,28); selLbl.BackgroundColor3=C.card; selLbl.BorderSizePixel=0
    selLbl.Text="Zona: "..QuestZones[1].name; selLbl.TextColor3=C.accent2
    selLbl.TextSize=11; selLbl.Font=Enum.Font.GothamBold; Corner(selLbl, 6)

    local arrowRow = Instance.new("Frame", pg)
    arrowRow.Size=UDim2.new(1,0,0,32); arrowRow.BackgroundTransparency=1
    List(arrowRow, Enum.FillDirection.Horizontal, 6)

    local function ArrowBtn(t, cb2)
        local b=Instance.new("TextButton", arrowRow)
        b.Size=UDim2.new(0.5,-3,1,0); b.BackgroundColor3=C.card
        b.Text=t; b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0; Corner(b, 6); Stroke(b, C.border, 1)
        b.MouseButton1Click:Connect(cb2)
    end
    ArrowBtn("◄ Anterior", function()
        selIdx=math.max(1,selIdx-1); selLbl.Text="Zona: "..QuestZones[selIdx].name
    end)
    ArrowBtn("Próxima ►", function()
        selIdx=math.min(#QuestZones,selIdx+1); selLbl.Text="Zona: "..QuestZones[selIdx].name
    end)

    Button(pg, "📍 Calibrar islePos (centro da ilha)", function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        QuestZones[selIdx].islePos=pos
        statusLbl.Text=("✓ islePos [%s] = %.0f,%.0f,%.0f"):format(
            QuestZones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Button(pg, "📍 Calibrar mobPos (área dos mobs)", function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        QuestZones[selIdx].mobPos=pos
        statusLbl.Text=("✓ mobPos [%s] = %.0f,%.0f,%.0f"):format(
            QuestZones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)

    Section(pg, "Zonas de Quest")
    for _, z in ipairs(QuestZones) do
        Label(pg, ("  Lv %3d–%-3d  →  %s"):format(z.minLv,z.maxLv,z.name))
    end
end

-- ============================================================
--  ESP
-- ============================================================
do
    local pg = Pages["ESP"]
    Section(pg, "Jogadores")
    Toggle(pg,"👤  Player ESP",        false,function(v) Cfg.PlayerESP=v end)
    Toggle(pg,"📏  Mostrar Distância", true, function(v) Cfg.ShowDist=v end)
    Toggle(pg,"📡  Tracer Lines",      false,function(v) Cfg.TracerLines=v end)
    Section(pg, "Frutas")
    Toggle(pg,"🍎  Fruit ESP",         false,function(v) Cfg.FruitESP=v end)
    Section(pg, "Configurações")
    Label(pg, "  Distância máxima (studs):")
    local rIn=Input(pg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end); rIn.Text="2000"
end

-- ============================================================
--  TELEPORT
-- ============================================================
do
    local pg = Pages["Teleport"]
    Section(pg, "Frutas")
    Button(pg,"🍎 Teleportar para Fruta Mais Próxima",TP_NearestFruit,true)
    Section(pg, "Jogadores")
    Label(pg,"  Nome do jogador:")
    local plrIn=Input(pg,"username...")
    Button(pg,"→ Ir para Jogador",function() TP_Player(plrIn.Text) end)
    Button(pg,"👥 Listar Online",function()
        local n={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
        plrIn.Text=table.concat(n,", ")
    end)
    Section(pg, "Coordenadas Manuais")
    Label(pg,"  X, Y, Z separados por vírgula:")
    local cIn=Input(pg,"0, 100, 0")
    Button(pg,"→ Ir para Coordenadas",function()
        local t=string.split(cIn.Text,",")
        local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Button(pg,"📋 Copiar Posição Atual",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            local str=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            setclipboard(str); cIn.Text=str
        end
    end)
end

-- ============================================================
--  ILHAS
-- ============================================================
do
    local pg = Pages["Ilhas"]
    Section(pg,"🏝 Sea 1")
    for _,name in ipairs({
        "Ilha Inicial","Base Marinha","Ilha Buggy","Ilha da Nami","Arlong Park",
        "Baratie","Coliseu","Ilha dos Tubarões","Shanks Island","Mihawk Island",
        "Marineford","Impel Down"
    }) do
        local p=Locations[name]
        if p then Button(pg,"→ "..name,function() TP(p) end) end
    end
    Section(pg,"☁ Sky Islands")
    for _,name in ipairs({"Skypiea","Upper Yard","Sky Coliseu"}) do
        local p=Locations[name]
        if p then Button(pg,"→ "..name,function() TP(p) end) end
    end
    Section(pg,"🌊 Segundo Mar")
    Button(pg,"→ Portal 2º Mar",function() TP(Locations["Portal 2º Mar"]) end)
end

-- ============================================================
--  MISC
-- ============================================================
do
    local pg = Pages["Misc"]
    Section(pg,"Movimentação")
    Toggle(pg,"👻  No Clip",false,function(v)
        local c=LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=not v end
        end end
    end)
    Toggle(pg,"🚀  Infinite Jump",false,function(v)
        getgenv()._infJ=v
        if v and not getgenv()._infJConn then
            getgenv()._infJConn=UserInputService.JumpRequest:Connect(function()
                if getgenv()._infJ then
                    local c=LP.Character
                    if c and c:FindFirstChild("Humanoid") then
                        c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        elseif not v and getgenv()._infJConn then
            getgenv()._infJConn:Disconnect(); getgenv()._infJConn=nil
        end
    end)
    Section(pg,"Walk Speed"); Label(pg,"  Padrão: 16")
    Input(pg,"16",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
    end)
    Section(pg,"Jump Power"); Label(pg,"  Padrão: 50")
    Input(pg,"50",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end
    end)
    Section(pg,"Utilitários")
    Button(pg,"📋 Copiar Minha Posição",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            setclipboard(("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z))
        end
    end)
    Button(pg,"🔁 Recarregar Personagem",function() LP:LoadCharacter() end)
end

-- ============================================================
--  WEBHOOK
-- ============================================================
do
    local pg = Pages["Webhook"]
    Section(pg,"URL do Webhook Discord")
    Input(pg,"https://discord.com/api/webhooks/...",function(v) Cfg.WHUrl=v end)
    local function SendWH(title,desc,color)
        if not Cfg.WHUrl or Cfg.WHUrl=="" then return end
        local req=syn and syn.request or (http and http.request) or request
        if not req then return end
        pcall(req,{Url=Cfg.WHUrl,Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HttpService:JSONEncode({username="China Hub Free",embeds={{
                title=title,description=desc,color=color or 16777215,
                footer={text="King Legacy | "..LP.Name},
                timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}})})
    end
    Section(pg,"Envio Manual")
    Label(pg,"  Título:"); local wht=Input(pg,"Título da mensagem...")
    Label(pg,"  Mensagem:"); local whm=Input(pg,"Corpo da mensagem...")
    Button(pg,"📤 Enviar Mensagem",function() SendWH(wht.Text,whm.Text,3447003) end,true)
    Button(pg,"🧪 Testar Conexão",function()
        SendWH("✅ Teste OK","Conectado como **"..LP.Name.."**",65280)
    end)
end

-- ============================================================
--  ESP POOLS / UPDATE
-- ============================================================
local PLR_ESP={}
local function MakePlayerESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={
        box=NewBox(Cfg.Col_Player), name=NewText(Cfg.Col_Player,13),
        dist=NewText(Color3.new(1,1,1),11),
        hpBg=NewBox(Color3.fromRGB(40,40,40),true),
        hpBar=NewBox(Color3.fromRGB(50,220,50),true),
        tracer=NewLine(Cfg.Col_Player),
    }
end
local function KillPlayerESP(pl)
    if PLR_ESP[pl] then
        for _,o in pairs(PLR_ESP[pl]) do pcall(function() o:Remove() end) end
        PLR_ESP[pl]=nil
    end
end
local FruitPool={}
local function ClearPool(pool)
    for _,obj in pairs(pool) do
        if obj.lbl  then pcall(function() obj.lbl:Remove() end) end
        if obj.dist then pcall(function() obj.dist:Remove() end) end
    end
    table.clear(pool)
end

local function UpdatePlayerESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LP then continue end
        if not PLR_ESP[pl] then MakePlayerESP(pl) end
        local obj=PLR_ESP[pl]; if not obj then continue end
        local char=pl.Character
        if not Cfg.PlayerESP or not char
           or not char:FindFirstChild("HumanoidRootPart")
           or not char:FindFirstChild("Humanoid") then
            for _,o in pairs(obj) do o.Visible=false end; continue
        end
        local hrp=char.HumanoidRootPart; local hum=char.Humanoid
        local d=Dist(hrp.Position)
        if d>Cfg.ESPRange then for _,o in pairs(obj) do o.Visible=false end; continue end
        local top2D,_,topV=W2V(hrp.Position+Vector3.new(0,3.2,0))
        local bot2D,_,botV=W2V(hrp.Position-Vector3.new(0,2.8,0))
        if not topV and not botV then for _,o in pairs(obj) do o.Visible=false end; continue end
        local bH=math.abs(top2D.Y-bot2D.Y); local bW=bH*0.55; local bX=top2D.X-bW/2
        obj.box.Size=Vector2.new(bW,bH); obj.box.Position=Vector2.new(bX,top2D.Y)
        obj.box.Color=Cfg.Col_Player; obj.box.Visible=true
        obj.name.Text=pl.DisplayName; obj.name.Position=Vector2.new(top2D.X,top2D.Y-16)
        obj.name.Color=Cfg.Col_Player; obj.name.Visible=true
        obj.dist.Text=d.."m"; obj.dist.Position=Vector2.new(top2D.X,top2D.Y-29)
        obj.dist.Visible=Cfg.ShowDist
        local hp=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        obj.hpBg.Size=Vector2.new(4,bH); obj.hpBg.Position=Vector2.new(bX+bW+3,top2D.Y); obj.hpBg.Visible=true
        obj.hpBar.Size=Vector2.new(4,bH*hp); obj.hpBar.Position=Vector2.new(bX+bW+3,top2D.Y+bH*(1-hp))
        obj.hpBar.Color=Color3.fromRGB(255*(1-hp),255*hp,0); obj.hpBar.Visible=true
        local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
        obj.tracer.From=ctr; obj.tracer.To=bot2D
        obj.tracer.Color=Cfg.Col_Player; obj.tracer.Visible=Cfg.TracerLines
    end
end

local function UpdateFruitESP()
    ClearPool(FruitPool); if not Cfg.FruitESP then return end
    for _,f in ipairs(ScanFruits()) do
        local d=Dist(f.pos); if d>Cfg.ESPRange then continue end
        local p2D,_,onScr=W2V(f.pos); if not onScr then continue end
        local lbl=NewText(Cfg.Col_Fruit,13)
        lbl.Text="🍎 "..f.name; lbl.Position=Vector2.new(p2D.X,p2D.Y-10); lbl.Visible=true
        local dlbl=NewText(Color3.new(1,1,1),11)
        dlbl.Text=d.."m"; dlbl.Position=Vector2.new(p2D.X,p2D.Y+6); dlbl.Visible=true
        table.insert(FruitPool,{lbl=lbl,dist=dlbl})
    end
end

-- ============================================================
--  SHOW/HIDE
-- ============================================================
local ShowBtn=Instance.new("TextButton",SG)
ShowBtn.Size=UDim2.new(0,130,0,32); ShowBtn.Position=UDim2.new(0,20,0,55)
ShowBtn.BackgroundColor3=C.sidebar; ShowBtn.Text="⚔ China Hub Free"
ShowBtn.TextColor3=C.accent2; ShowBtn.TextSize=11; ShowBtn.Font=Enum.Font.GothamBold
ShowBtn.BorderSizePixel=0; ShowBtn.Visible=false
Corner(ShowBtn,8); Stroke(ShowBtn,C.accent,1.5)

local function ToggleVis()
    if WIN.Visible then WIN.Visible=false; ShowBtn.Visible=true
    else WIN.Visible=true; ShowBtn.Visible=false end
end
ShowBtn.MouseButton1Click:Connect(ToggleVis)
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.UserInputType==Enum.UserInputType.Keyboard
       and inp.KeyCode==Cfg.HideKey then ToggleVis() end
end)

-- ============================================================
--  INIT
-- ============================================================
SwitchTab("Home")

for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MakePlayerESP(pl) end)
Players.PlayerRemoving:Connect(KillPlayerESP)
LP.CharacterAdded:Connect(function()
    Farm.State="idle"; task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
end)

local t2=0
RunService.RenderStepped:Connect(function()
    t2=t2+1; UpdatePlayerESP()
    if t2%14==0 then UpdateFruitESP(); t2=0 end
end)

print("[China Hub Free v4.1] Carregado — "..LP.Name)
