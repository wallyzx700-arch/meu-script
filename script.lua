-- ============================================================
--  CHINA HUB FREE  v5.0  —  King Legacy
--  Quest via RemoteFunction  |  workspace.Monster.Mon/Boss
--  Mob-Lock Aereo  |  UI redesenhada sem emojis
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local VIM              = game:GetService("VirtualInputManager")
local RS               = game:GetService("ReplicatedStorage")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
--  LEVEL E QUEST
-- ============================================================
local function GetLevel()
    local ps = LP:FindFirstChild("PlayerStats")
    if ps and ps:FindFirstChild("lvl") then return tonumber(ps.lvl.Value) or 1 end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Level","Lv","level","lvl"}) do
            local v = ls:FindFirstChild(n)
            if v then return tonumber(v.Value) or 1 end
        end
    end
    for _, v in ipairs(LP:GetDescendants()) do
        if (v.Name=="Level" or v.Name=="lvl") and
           (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return tonumber(v.Value) or 1
        end
    end
    return 1
end

local function GetCurrentQuest()
    if LP:FindFirstChild("CurrentQuest") then return LP.CurrentQuest.Value end
    return ""
end

-- ============================================================
--  TABELA DE QUESTS REAIS DO KING LEGACY
--  Nomes exatos dos mobs/quests extraidos do workspace real
-- ============================================================
local QuestZones = {
    {
        name="Starter Island", minLv=1, maxLv=9,
        questDesc="Kill 4 Soldiers",
        mobName="Soldier [Lv.1]", isBoss=false,
        islePos=Vector3.new(-2044,100,-4591),
        mobPos=Vector3.new(-2044,100,-4591),
    },
    {
        name="Starter Island", minLv=10, maxLv=19,
        questDesc="Kill 5 Clown Pirates",
        mobName="Clown Pirate [Lv.10]", isBoss=false,
        islePos=Vector3.new(-2044,100,-4591),
        mobPos=Vector3.new(-2044,100,-4591),
    },
    {
        name="Starter Island", minLv=20, maxLv=29,
        questDesc="Kill 1 Smoky",
        mobName="Smoky [Lv.20]", isBoss=true,
        islePos=Vector3.new(-2044,100,-4591),
        mobPos=Vector3.new(-2044,100,-4591),
    },
    {
        name="Starter Island", minLv=30, maxLv=49,
        questDesc="Kill 1 Tashi",
        mobName="Tashi [Lv.30]", isBoss=true,
        islePos=Vector3.new(-2044,100,-4591),
        mobPos=Vector3.new(-2044,100,-4591),
    },
    {
        name="Pirate Island", minLv=50, maxLv=74,
        questDesc="Kill 6 Clown Swordman",
        mobName="Clown Swordman [Lv.50]", isBoss=false,
        islePos=Vector3.new(-681,64,-3449),
        mobPos=Vector3.new(-681,64,-3449),
    },
    {
        name="Pirate Island", minLv=75, maxLv=99,
        questDesc="Kill 1 The Clown",
        mobName="The Clown [Lv.75]", isBoss=true,
        islePos=Vector3.new(-681,64,-3449),
        mobPos=Vector3.new(-681,64,-3449),
    },
    {
        name="Soldier Island", minLv=100, maxLv=139,
        questDesc="Kill 8 Marines",
        mobName="Marine [Lv.100]", isBoss=false,
        islePos=Vector3.new(990,28,-510),
        mobPos=Vector3.new(948,28,-472),
    },
    {
        name="Soldier Island", minLv=140, maxLv=179,
        questDesc="Kill 1 Ax-Hand Morgan",
        mobName="Ax-Hand Morgan [Lv.140]", isBoss=true,
        islePos=Vector3.new(990,28,-510),
        mobPos=Vector3.new(948,28,-472),
    },
    {
        name="Shark Island", minLv=180, maxLv=224,
        questDesc="Kill 8 Fish Pirates",
        mobName="Fish Pirate [Lv.180]", isBoss=false,
        islePos=Vector3.new(1822,28,1492),
        mobPos=Vector3.new(1778,28,1448),
    },
    {
        name="Shark Island", minLv=225, maxLv=249,
        questDesc="Kill 1 Arlong",
        mobName="Arlong [Lv.225]", isBoss=true,
        islePos=Vector3.new(1822,28,1492),
        mobPos=Vector3.new(1778,28,1448),
    },
    {
        name="Chef Ship", minLv=250, maxLv=349,
        questDesc="Kill 8 Don Krieg Pirates",
        mobName="Don Krieg Pirate [Lv.250]", isBoss=false,
        islePos=Vector3.new(-792,28,1242),
        mobPos=Vector3.new(-832,28,1198),
    },
    {
        name="Chef Ship", minLv=350, maxLv=399,
        questDesc="Kill 1 Don Krieg",
        mobName="Don Krieg [Lv.350]", isBoss=true,
        islePos=Vector3.new(-792,28,1242),
        mobPos=Vector3.new(-832,28,1198),
    },
    {
        name="Snow Island", minLv=400, maxLv=524,
        questDesc="Kill 8 Snow Soldiers",
        mobName="Snow Soldier [Lv.400]", isBoss=false,
        islePos=Vector3.new(1622,28,-872),
        mobPos=Vector3.new(1575,28,-935),
    },
    {
        name="Sand Kingdom", minLv=525, maxLv=799,
        questDesc="Kill 8 Sand Pirates",
        mobName="Sand Pirate [Lv.525]", isBoss=false,
        islePos=Vector3.new(-3052,28,1978),
        mobPos=Vector3.new(-3105,28,2022),
    },
    {
        name="Sky Island", minLv=800, maxLv=999,
        questDesc="Kill 8 Sky Warriors",
        mobName="Sky Warrior [Lv.800]", isBoss=false,
        islePos=Vector3.new(-2822,865,-1632),
        mobPos=Vector3.new(-2892,858,-1702),
    },
    {
        name="Bubble Island", minLv=1000, maxLv=9999,
        questDesc="Kill 8 Bubble Pirates",
        mobName="Bubble Pirate [Lv.1000]", isBoss=false,
        islePos=Vector3.new(2552,28,-2058),
        mobPos=Vector3.new(2508,28,-2135),
    },
}

local function GetZone(lv)
    for _, z in ipairs(QuestZones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return QuestZones[#QuestZones]
end

-- ============================================================
--  QUEST VIA REMOTEFUNCTION (metodo real do KL)
-- ============================================================
local questRF = nil
local function GetQuestRF()
    if questRF then return questRF end
    pcall(function()
        questRF = RS:WaitForChild("Chest",3)
                    :WaitForChild("Functions",3)
                    :WaitForChild("Quest",3)
    end)
    return questRF
end

local function TakeQuest(desc)
    local rf = GetQuestRF(); if not rf then return false end
    local ok = pcall(function() rf:InvokeServer("take", desc) end)
    return ok
end

local function FinishQuest(desc)
    local rf = GetQuestRF(); if not rf then return false end
    pcall(function() rf:InvokeServer("finish", desc) end)
end

-- ============================================================
--  ENCONTRAR MOB NO WORKSPACE
-- ============================================================
local function FindMob(mobName, isBoss)
    local mon = workspace:FindFirstChild("Monster")
    if not mon then
        -- fallback: scan geral
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == mobName then
                local h = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if h and hrp and h.Health > 0 then return obj end
            end
        end
        return nil
    end
    local folder = isBoss
        and (mon:FindFirstChild("Boss") or mon)
        or  (mon:FindFirstChild("Mon")  or mon)
    -- nome exato
    local exact = folder:FindFirstChild(mobName)
    if exact then
        local h = exact:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 and exact:FindFirstChild("HumanoidRootPart") then
            return exact
        end
    end
    -- busca parcial (cobre variações de versao)
    local base = mobName:match("^([%a%s]+)") or mobName:sub(1,8)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj.Name:find(base, 1, true) then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then return obj end
        end
    end
    -- ultimo recurso: scan em todo workspace.Monster
    for _, obj in ipairs(mon:GetDescendants()) do
        if obj:IsA("Model") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0
               and not Players:GetPlayerFromCharacter(obj) then
                return obj
            end
        end
    end
    return nil
end

-- ============================================================
--  FARM CONFIG
-- ============================================================
local Farm = {
    Active      = false,
    State       = "idle",
    StatusText  = "Inativo",
    Style       = "melee",
    KillCount   = 0,
    TargetKills = 10,
    HoverY      = 5,
    Zone        = nil,
    Timer       = 0,
}
local AutoAttack = false
local SEA_Y      = 15
local seaFails   = 0

local function SetCharCollision(v)
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = v end
    end
end

-- ============================================================
--  TELEPORTE SEGURO
-- ============================================================
local function SafeTP(pos)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(
        Vector3.new(pos.X, math.max(pos.Y, 60), pos.Z)
    )
    task.wait(1.2)
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        seaFails = seaFails + 1
        Farm.StatusText = ("COORD ERRADA (%d/3) — Calibre a zona"):format(seaFails)
        if seaFails >= 3 then
            Farm.Active = false; Farm.State = "idle"; seaFails = 0
            Farm.StatusText = "FARM PAUSADO — Calibre as coordenadas"
        else
            Farm.State = "idle"
        end
        return false
    end
    seaFails = 0
    return true
end

-- ============================================================
--  ATAQUE
-- ============================================================
local function EquipSword()
    local char = LP.Character; if not char then return end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("sword") or n:find("katana") or n:find("blade") then
                char.Humanoid:EquipTool(t); task.wait(0.3); return true
            end
        end
    end
    local t = LP.Backpack:FindFirstChildOfClass("Tool")
    if t then char.Humanoid:EquipTool(t); task.wait(0.3) end
end

local function PressKey(kc)
    pcall(function()
        if syn and syn.key_press then
            syn.key_press(kc); task.wait(0.08); syn.key_release(kc)
        elseif keypress then
            keypress(kc); task.wait(0.08); if keyrelease then keyrelease(kc) end
        end
    end)
end

local function AttackMob(mob)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hoverPos = hrp.Position + Vector3.new(0, Farm.HoverY, 0)
    char.HumanoidRootPart.CFrame = CFrame.lookAt(hoverPos, hrp.Position)
    SetCharCollision(false)
    if Farm.Style == "fruit" then PressKey(0x5A) end
    if Farm.Style == "sword" then EquipSword() end
    local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
    if onScr then
        local x, y = math.floor(sp.X), math.floor(sp.Y)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end
end

-- ============================================================
--  AUTO ATAQUE INDEPENDENTE (aba Misc)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not AutoAttack then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(2); continue end
        -- mob mais proximo no workspace.Monster
        local mon = workspace:FindFirstChild("Monster")
        local best, bestD = nil, math.huge
        if mon then
            for _, obj in ipairs(mon:GetDescendants()) do
                if obj:IsA("Model") then
                    local h = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if h and hrp and h.Health > 0
                       and not Players:GetPlayerFromCharacter(obj) then
                        local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if d < bestD then bestD = d; best = obj end
                    end
                end
            end
        end
        if best then AttackMob(best) end
    end
end)

-- ============================================================
--  AUTO FARM PRINCIPAL
--  idle → toisle → takequest → fighting → returning → idle
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if not Farm.Active then Farm.State="idle"; SetCharCollision(true); continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            SetCharCollision(true)
            Farm.StatusText = "Aguardando respawn..."
            Farm.State = "idle"; task.wait(4); continue
        end

        local lv   = GetLevel()
        local zone = GetZone(lv)

        -- IDLE
        if Farm.State == "idle" then
            Farm.Zone      = zone
            Farm.KillCount = 0
            Farm.State     = "toisle"
            Farm.Timer     = tick()
            Farm.StatusText = ("Lv %d  |  %s  |  Viajando"):format(lv, zone.name)

        -- TOISLE: teleporta para a ilha e aceita quest
        elseif Farm.State == "toisle" then
            local ok = SafeTP(Farm.Zone.islePos)
            if not ok then continue end
            task.wait(0.8)

            -- tenta aceitar quest
            local curQ = GetCurrentQuest()
            if curQ ~= Farm.Zone.questDesc then
                TakeQuest(Farm.Zone.questDesc)
                task.wait(0.8)
                TakeQuest(Farm.Zone.questDesc) -- double-fire por seguranca
                task.wait(0.5)
            end

            if Farm.Style == "sword" then EquipSword() end

            -- TP para area dos mobs
            SafeTP(Farm.Zone.mobPos)
            task.wait(0.8)

            Farm.State     = "fighting"
            Farm.KillCount = 0
            Farm.Timer     = tick()
            Farm.StatusText = ("Lv %d  |  %s  |  Lutando"):format(lv, zone.name)

        -- FIGHTING: hover + ataque
        elseif Farm.State == "fighting" then
            -- timeout de seguranca
            if tick() - Farm.Timer > 120 then
                SetCharCollision(true)
                Farm.State = "returning"; continue
            end

            local mob = FindMob(Farm.Zone.mobName, Farm.Zone.isBoss)

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                if hrp.Position.Y < SEA_Y then task.wait(0.3); continue end

                local hBefore = mob:FindFirstChildOfClass("Humanoid")
                local hpBefore = hBefore and hBefore.Health or 0

                AttackMob(mob)
                task.wait(0.15)

                local hAfter = mob:FindFirstChildOfClass("Humanoid")
                if not hAfter or hAfter.Health <= 0 then
                    if hpBefore > 0 then Farm.KillCount = Farm.KillCount + 1 end
                end

                local curHp = hAfter and math.floor(hAfter.Health) or 0
                Farm.StatusText = ("Lv %d  |  Kills %d/%d  |  HP %d"):format(
                    lv, Farm.KillCount, Farm.TargetKills, curHp)

                if Farm.KillCount >= Farm.TargetKills then
                    SetCharCollision(true)
                    Farm.State = "returning"
                end
            else
                -- mob nao encontrado: re-TP na area
                SafeTP(Farm.Zone.mobPos)
                Farm.StatusText = ("Lv %d  |  Aguardando spawn... %d/%d"):format(
                    lv, Farm.KillCount, Farm.TargetKills)
                if Farm.KillCount >= Farm.TargetKills then
                    SetCharCollision(true); Farm.State = "returning"
                end
                task.wait(2)
            end

        -- RETURNING: entrega quest e reinicia
        elseif Farm.State == "returning" then
            SetCharCollision(true)
            Farm.StatusText = ("Lv %d  |  Entregando missao..."):format(lv)
            SafeTP(Farm.Zone.islePos)
            task.wait(1.0)
            FinishQuest(Farm.Zone.questDesc)
            task.wait(0.5)
            FinishQuest(Farm.Zone.questDesc)
            task.wait(0.5)
            Farm.StatusText = ("Lv %d  |  Missao entregue! Reiniciando..."):format(lv)
            task.wait(0.8)
            Farm.State = "idle"
        end
    end
end)

-- ============================================================
--  FRUTAS
-- ============================================================
local FruitKW = {
    "fruit","devil","gumgum","bombomb","chop","smoke","flame","ice","magnet",
    "light","dark","quake","phoenix","dragon","rubb","sand","diamond","paw",
    "gravity","string","shadow","portal","control","venom","leopard",
    "blizzard","gas","surge","rumble","barrier","soul","human","buddha",
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
            if pos then table.insert(out,{name=obj.Name,pos=pos}) end
        end
    end
    return out
end
local function TP(pos)
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
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
    table.sort(fruits, function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

-- ============================================================
--  LOCAIS DE TP
-- ============================================================
local Locs = {
    ["Starter Island"]  = Vector3.new(-2044,100,-4591),
    ["Pirate Island"]   = Vector3.new(-681,64,-3449),
    ["Soldier Island"]  = Vector3.new(990,28,-510),
    ["Shark Island"]    = Vector3.new(1822,28,1492),
    ["Chef Ship"]       = Vector3.new(-792,28,1242),
    ["Snow Island"]     = Vector3.new(1622,28,-872),
    ["Sand Kingdom"]    = Vector3.new(-3052,28,1978),
    ["Sky Island"]      = Vector3.new(-2822,865,-1632),
    ["Bubble Island"]   = Vector3.new(2552,28,-2058),
    ["Lobby Island"]    = Vector3.new(-1892,28,-858),
    ["Zombie Island"]   = Vector3.new(-2492,28,-312),
    ["War Island"]      = Vector3.new(2552,28,-2058),
    ["Fishland"]        = Vector3.new(-3102,882,-1922),
}

-- ============================================================
--  ESP
-- ============================================================
local Cfg = {
    PlayerESP=false, FruitESP=false,
    ShowDist=true, TracerLines=false, ESPRange=2000,
    WHUrl="",
    HideKey=Enum.KeyCode.LeftControl,
    Col_Player=Color3.fromRGB(220,60,60),
    Col_Fruit=Color3.fromRGB(60,220,100),
}

local function NewText(col,sz)
    local t=Drawing.new("Text")
    t.Color=col or Color3.new(1,1,1); t.Size=sz or 13
    t.Center=true; t.Outline=true; t.Visible=false; return t
end
local function NewBox(col,filled)
    local b=Drawing.new("Square")
    b.Color=col or Color3.new(1,1,1); b.Thickness=1.5
    b.Filled=filled or false; b.Visible=false; return b
end
local function NewLine(col)
    local l=Drawing.new("Line")
    l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Visible=false; return l
end
local function W2V(pos)
    local sp=Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X,sp.Y),sp.Z,sp.Z>0
end
local function Dist(pos)
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        return math.floor((c.HumanoidRootPart.Position-pos).Magnitude)
    end
    return 0
end

-- ============================================================
--  GUI — REDESENHADA SEM EMOJIS
-- ============================================================
local old = CoreGui:FindFirstChild("CHINAHUB5")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name="CHINAHUB5"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true; SG.Parent=CoreGui

-- paleta dark elegante
local C = {
    bg       = Color3.fromRGB(10,10,16),
    sidebar  = Color3.fromRGB(14,14,22),
    panel    = Color3.fromRGB(18,18,28),
    card     = Color3.fromRGB(24,24,38),
    cardHov  = Color3.fromRGB(30,30,48),
    accent   = Color3.fromRGB(180,60,255),   -- roxo vibrante
    accent2  = Color3.fromRGB(220,100,255),  -- roxo claro
    accentRed= Color3.fromRGB(220,55,80),
    green    = Color3.fromRGB(60,210,110),
    red      = Color3.fromRGB(210,55,70),
    text     = Color3.fromRGB(230,230,245),
    textDim  = Color3.fromRGB(120,120,145),
    border   = Color3.fromRGB(50,40,80),
    sep      = Color3.fromRGB(30,25,50),
    topbar   = Color3.fromRGB(12,12,20),
}

local function MkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function MkStroke(p,col,t) local s=Instance.new("UIStroke",p); s.Color=col or C.border; s.Thickness=t or 1; return s end
local function MkPad(p,l,r,t,b)
    local pad=Instance.new("UIPadding",p)
    pad.PaddingLeft=UDim.new(0,l or 0); pad.PaddingRight=UDim.new(0,r or 0)
    pad.PaddingTop=UDim.new(0,t or 0);  pad.PaddingBottom=UDim.new(0,b or 0)
end
local function MkList(p,dir,pad,ha)
    local l=Instance.new("UIListLayout",p)
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,pad or 6)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    return l
end

-- janela principal
local WIN = Instance.new("Frame",SG)
WIN.Size=UDim2.new(0,680,0,510)
WIN.Position=UDim2.new(0.5,-340,0.5,-255)
WIN.BackgroundColor3=C.bg; WIN.BorderSizePixel=0
MkCorner(WIN,12)
local winStroke=MkStroke(WIN,C.border,1.5)

-- gradiente sutil na borda
local winGrad=Instance.new("UIGradient",winStroke)
winGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,C.accent),
    ColorSequenceKeypoint.new(0.5,C.border),
    ColorSequenceKeypoint.new(1,C.accent),
}
winGrad.Rotation=90

-- topbar
local TopBar=Instance.new("Frame",WIN)
TopBar.Size=UDim2.new(1,0,0,46)
TopBar.BackgroundColor3=C.topbar; TopBar.BorderSizePixel=0
MkCorner(TopBar,12)

-- faixa colorida na topbar
local TopAccent=Instance.new("Frame",TopBar)
TopAccent.Size=UDim2.new(1,0,0,2)
TopAccent.Position=UDim2.new(0,0,1,-2)
TopAccent.BackgroundColor3=C.accent; TopAccent.BorderSizePixel=0
local topGrad=Instance.new("UIGradient",TopAccent)
topGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,C.accent),
    ColorSequenceKeypoint.new(0.5,C.accent2),
    ColorSequenceKeypoint.new(1,C.accent),
}

-- indicador lateral roxo
local LeftBar=Instance.new("Frame",TopBar)
LeftBar.Size=UDim2.new(0,3,0.6,0)
LeftBar.Position=UDim2.new(0,12,0.2,0)
LeftBar.BackgroundColor3=C.accent; LeftBar.BorderSizePixel=0
MkCorner(LeftBar,2)

-- titulo
local TitleLbl=Instance.new("TextLabel",TopBar)
TitleLbl.Size=UDim2.new(1,-130,1,0)
TitleLbl.Position=UDim2.new(0,24,0,0)
TitleLbl.BackgroundTransparency=1
TitleLbl.Text="CHINA HUB FREE"
TitleLbl.TextColor3=C.text; TitleLbl.TextSize=14
TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left

local SubLbl=Instance.new("TextLabel",TopBar)
SubLbl.Size=UDim2.new(1,-130,0,14)
SubLbl.Position=UDim2.new(0,24,0,27)
SubLbl.BackgroundTransparency=1
SubLbl.Text="King Legacy  v5.0"
SubLbl.TextColor3=C.accent2; SubLbl.TextSize=10
SubLbl.Font=Enum.Font.Gotham
SubLbl.TextXAlignment=Enum.TextXAlignment.Left

-- botoes de janela
local function WinBtn(label,col,off)
    local b=Instance.new("TextButton",TopBar)
    b.Size=UDim2.new(0,24,0,24); b.Position=UDim2.new(1,off,0.5,-12)
    b.BackgroundColor3=col; b.Text=label; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=11; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    MkCorner(b,5); return b
end
local CloseBtn = WinBtn("X", C.red,       -8)
local MinBtn   = WinBtn("_", Color3.fromRGB(50,100,180), -38)

-- drag
local dragging,dInput,dStart,dPos
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
    Farm.Active=false; AutoAttack=false; SetCharCollision(true); SG:Destroy()
end)
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    for _,c in ipairs(WIN:GetChildren()) do
        if c~=TopBar then c.Visible=not minimized end
    end
    WIN.Size=minimized and UDim2.new(0,680,0,46) or UDim2.new(0,680,0,510)
    MinBtn.Text=minimized and "+" or "_"
end)

-- layout
local Layout=Instance.new("Frame",WIN)
Layout.Position=UDim2.new(0,0,0,46); Layout.Size=UDim2.new(1,0,1,-46)
Layout.BackgroundTransparency=1

-- sidebar
local Sidebar=Instance.new("Frame",Layout)
Sidebar.Size=UDim2.new(0,160,1,0); Sidebar.BackgroundColor3=C.sidebar
Sidebar.BorderSizePixel=0
MkCorner(Sidebar,8)
local sbList=MkList(Sidebar,Enum.FillDirection.Vertical,0,Enum.HorizontalAlignment.Left)
MkPad(Sidebar,0,0,8,8)

-- card de usuario no topo da sidebar
local UserCard=Instance.new("Frame",Sidebar)
UserCard.Size=UDim2.new(1,0,0,62); UserCard.BackgroundColor3=C.card
UserCard.BorderSizePixel=0; MkCorner(UserCard,0)
-- faixa accent no user card
local UCBar=Instance.new("Frame",UserCard)
UCBar.Size=UDim2.new(0,3,0.7,0); UCBar.Position=UDim2.new(0,0,0.15,0)
UCBar.BackgroundColor3=C.accent; UCBar.BorderSizePixel=0

local UCName=Instance.new("TextLabel",UserCard)
UCName.Size=UDim2.new(1,-16,0,20); UCName.Position=UDim2.new(0,12,0,10)
UCName.BackgroundTransparency=1; UCName.Text=LP.DisplayName
UCName.TextColor3=C.text; UCName.TextSize=12; UCName.Font=Enum.Font.GothamBold
UCName.TextXAlignment=Enum.TextXAlignment.Left; UCName.LayoutOrder=0

local UCLv=Instance.new("TextLabel",UserCard)
UCLv.Size=UDim2.new(1,-16,0,15); UCLv.Position=UDim2.new(0,12,0,34)
UCLv.BackgroundTransparency=1; UCLv.TextColor3=C.accent2
UCLv.TextSize=10; UCLv.Font=Enum.Font.Gotham; UCLv.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function()
    while SG.Parent do task.wait(2); UCLv.Text="Level  "..GetLevel() end
end)

-- divisor
local SBDiv=Instance.new("Frame",Sidebar)
SBDiv.Size=UDim2.new(1,0,0,1); SBDiv.BackgroundColor3=C.sep
SBDiv.BorderSizePixel=0; SBDiv.LayoutOrder=1

-- conteudo
local Content=Instance.new("Frame",Layout)
Content.Position=UDim2.new(0,160,0,0); Content.Size=UDim2.new(1,-160,1,0)
Content.BackgroundColor3=C.panel; Content.BorderSizePixel=0

local CScroll=Instance.new("ScrollingFrame",Content)
CScroll.Size=UDim2.new(1,0,1,0); CScroll.BackgroundTransparency=1
CScroll.ScrollBarThickness=3; CScroll.ScrollBarImageColor3=C.accent
CScroll.CanvasSize=UDim2.new(0,0,0,0); CScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
MkPad(CScroll,14,14,12,12)
MkList(CScroll,Enum.FillDirection.Vertical,8)

local Pages, TabBtns = {}, {}

local function MakePage(id)
    local pg=Instance.new("Frame",CScroll)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false
    MkList(pg,Enum.FillDirection.Vertical,6)
    Pages[id]=pg; return pg
end

local function SwitchTab(id)
    for k,pg in pairs(Pages) do
        pg.Visible=false
        if TabBtns[k] then
            TabBtns[k].BackgroundTransparency=1
            local l=TabBtns[k]:FindFirstChildOfClass("TextLabel")
            if l then l.TextColor3=C.textDim end
            local d=TabBtns[k]:FindFirstChild("AD")
            if d then d.Visible=false end
        end
    end
    if Pages[id] then Pages[id].Visible=true end
    if TabBtns[id] then
        TabBtns[id].BackgroundColor3=C.cardHov
        TabBtns[id].BackgroundTransparency=0
        local l=TabBtns[id]:FindFirstChildOfClass("TextLabel")
        if l then l.TextColor3=C.text end
        local d=TabBtns[id]:FindFirstChild("AD")
        if d then d.Visible=true end
    end
    CScroll.CanvasPosition=Vector2.new(0,0)
end

local TabDefs = {
    {label="HOME",    order=1},
    {label="FARM",    order=2},
    {label="ESP",     order=3},
    {label="TELEPORT",order=4},
    {label="ILHAS",   order=5},
    {label="MISC",    order=6},
    {label="WEBHOOK", order=7},
}

for _,def in ipairs(TabDefs) do
    MakePage(def.label)
    local btn=Instance.new("TextButton",Sidebar)
    btn.Name=def.label; btn.Size=UDim2.new(1,0,0,38)
    btn.BackgroundTransparency=1; btn.Text=""; btn.LayoutOrder=def.order+2
    -- faixa ativa
    local ad=Instance.new("Frame",btn)
    ad.Name="AD"; ad.Size=UDim2.new(0,3,0.55,0); ad.Position=UDim2.new(0,0,0.225,0)
    ad.BackgroundColor3=C.accent; ad.BorderSizePixel=0; ad.Visible=false; MkCorner(ad,2)
    -- label
    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,0,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=def.label
    lbl.TextColor3=C.textDim; lbl.TextSize=11; lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    TabBtns[def.label]=btn
    btn.MouseButton1Click:Connect(function() SwitchTab(def.label) end)
end

-- ============================================================
--  UI HELPERS
-- ============================================================
local function Section(parent, text)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1
    local line=Instance.new("Frame",row)
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1)
    line.BackgroundColor3=C.sep; line.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,0,1,-2); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.TextColor3=C.accent2
    lbl.TextSize=10; lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Left
end

local function Toggle(parent, text, default, cb)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=C.card; row.BorderSizePixel=0
    MkCorner(row,6)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.text
    lbl.TextSize=12; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",row)
    pill.Size=UDim2.new(0,46,0,22); pill.Position=UDim2.new(1,-56,0.5,-11)
    pill.Text=""; pill.BorderSizePixel=0
    local state=default or false
    pill.BackgroundColor3=state and C.green or Color3.fromRGB(40,40,60)
    MkCorner(pill,11)
    local thumb=Instance.new("Frame",pill)
    thumb.Size=UDim2.new(0,16,0,16)
    thumb.Position=state and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; MkCorner(thumb,8)
    local function Set(v)
        state=v
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=v and C.green or Color3.fromRGB(40,40,60)}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.15),{Position=v and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)}):Play()
        if cb then cb(v) end
    end
    pill.MouseButton1Click:Connect(function() Set(not state) end)
    return Set
end

local function Button(parent, text, cb, accent)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,0,0,36)
    b.BackgroundColor3=accent and C.accent or C.card
    b.Text=text; b.TextColor3=C.text; b.TextSize=12
    b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    MkCorner(b,6)
    if not accent then MkStroke(b,C.border,1) end
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=accent and C.accent2 or C.cardHov}):Play()
        task.delay(0.15,function()
            if b and b.Parent then
                TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=accent and C.accent or C.card}):Play()
            end
        end)
        if cb then cb() end
    end)
    return b
end

local function Input(parent, hint, cb)
    local box=Instance.new("TextBox",parent)
    box.Size=UDim2.new(1,0,0,32); box.BackgroundColor3=C.card
    box.Text=""; box.PlaceholderText=hint; box.PlaceholderColor3=C.textDim
    box.TextColor3=C.text; box.TextSize=11; box.Font=Enum.Font.Gotham
    box.BorderSizePixel=0; box.ClearTextOnFocus=false
    MkCorner(box,6); MkStroke(box,C.border,1); MkPad(box,10,10,0,0)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return box
end

local function Label(parent, text, col)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,16); l.BackgroundTransparency=1; l.Text=text
    l.TextColor3=col or C.textDim; l.TextSize=11; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
end

-- ============================================================
--  HOME
-- ============================================================
do
    local pg=Pages["HOME"]

    -- banner
    local banner=Instance.new("Frame",pg)
    banner.Size=UDim2.new(1,0,0,96); banner.BackgroundColor3=C.card
    banner.BorderSizePixel=0; MkCorner(banner,10)
    MkStroke(banner,C.accent,1.5)
    local bg=Instance.new("UIGradient",banner)
    bg.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(50,10,80)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(10,10,22)),
    }
    bg.Rotation=140
    -- barra decorativa
    local bLine=Instance.new("Frame",banner)
    bLine.Size=UDim2.new(0,3,0.6,0); bLine.Position=UDim2.new(0,14,0.2,0)
    bLine.BackgroundColor3=C.accent2; bLine.BorderSizePixel=0; MkCorner(bLine,2)

    local bT=Instance.new("TextLabel",banner)
    bT.Size=UDim2.new(1,-30,0,30); bT.Position=UDim2.new(0,24,0,14)
    bT.BackgroundTransparency=1; bT.Text="CHINA HUB FREE"
    bT.TextColor3=Color3.new(1,1,1); bT.TextSize=20; bT.Font=Enum.Font.GothamBold
    bT.TextXAlignment=Enum.TextXAlignment.Left

    local bS=Instance.new("TextLabel",banner)
    bS.Size=UDim2.new(1,-30,0,16); bS.Position=UDim2.new(0,24,0,46)
    bS.BackgroundTransparency=1; bS.Text="King Legacy  |  Build 5.0  |  Sea 1"
    bS.TextColor3=C.textDim; bS.TextSize=11; bS.Font=Enum.Font.Gotham
    bS.TextXAlignment=Enum.TextXAlignment.Left

    local bS2=Instance.new("TextLabel",banner)
    bS2.Size=UDim2.new(1,-30,0,14); bS2.Position=UDim2.new(0,24,0,66)
    bS2.BackgroundTransparency=1; bS2.Text="workspace.Monster  |  RemoteFunction Quest"
    bS2.TextColor3=C.accent2; bS2.TextSize=10; bS2.Font=Enum.Font.Gotham
    bS2.TextXAlignment=Enum.TextXAlignment.Left

    -- cards de info
    local infoRow=Instance.new("Frame",pg)
    infoRow.Size=UDim2.new(1,0,0,62); infoRow.BackgroundTransparency=1
    local iList=MkList(infoRow,Enum.FillDirection.Horizontal,8,Enum.HorizontalAlignment.Left)

    local function InfoCard(label,val,col)
        local c2=Instance.new("Frame",infoRow)
        c2.Size=UDim2.new(0,138,1,0); c2.BackgroundColor3=C.card
        c2.BorderSizePixel=0; MkCorner(c2,8); MkStroke(c2,C.sep,1)
        -- faixa top
        local topLine=Instance.new("Frame",c2)
        topLine.Size=UDim2.new(1,0,0,2); topLine.BackgroundColor3=col or C.accent
        topLine.BorderSizePixel=0; MkCorner(topLine,2)
        local vl=Instance.new("TextLabel",c2)
        vl.Size=UDim2.new(1,0,0,26); vl.Position=UDim2.new(0,0,0,8)
        vl.BackgroundTransparency=1; vl.Text=val
        vl.TextColor3=col or C.accent2; vl.TextSize=18
        vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Center
        local tl=Instance.new("TextLabel",c2)
        tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,0,0,38)
        tl.BackgroundTransparency=1; tl.Text=label; tl.TextColor3=C.textDim
        tl.TextSize=10; tl.Font=Enum.Font.Gotham; tl.TextXAlignment=Enum.TextXAlignment.Center
        return vl
    end

    local lvCard    = InfoCard("LEVEL",   tostring(GetLevel()), C.accent2)
    local farmCard  = InfoCard("FARM",    "OFF",   C.red)
    local styleCard = InfoCard("ESTILO",  "Melee", C.green)

    task.spawn(function()
        while SG.Parent do task.wait(1.5)
            lvCard.Text    = tostring(GetLevel())
            farmCard.Text  = Farm.Active and "ON" or "OFF"
            farmCard.TextColor3 = Farm.Active and C.green or C.red
            styleCard.Text = Farm.Style:sub(1,1):upper()..Farm.Style:sub(2)
        end
    end)

    Section(pg,"SOBRE")
    Label(pg,"  Mob-Lock Aereo: personagem fica acima do NPC.")
    Label(pg,"  Quest aceita via RemoteFunction (metodo real do KL).")
    Label(pg,"  Mobs buscados em workspace.Monster.Mon e .Boss.")
    Label(pg,"  Coordenadas reais: Starter (-2044,100,-4591) | Pirate (-681,64,-3449).")
    Label(pg,"  Calibre as demais zonas com o botao na aba Farm.")
    Label(pg,"  Tecla LeftCtrl: ocultar/mostrar.")
end

-- ============================================================
--  FARM
-- ============================================================
do
    local pg=Pages["FARM"]

    -- status card com borda animada
    local statusF=Instance.new("Frame",pg)
    statusF.Size=UDim2.new(1,0,0,48); statusF.BackgroundColor3=Color3.fromRGB(12,22,16)
    statusF.BorderSizePixel=0; MkCorner(statusF,8)
    MkStroke(statusF,Color3.fromRGB(30,80,45),1)

    local sDot=Instance.new("Frame",statusF)
    sDot.Size=UDim2.new(0,8,0,8); sDot.Position=UDim2.new(0,12,0.5,-4)
    sDot.BackgroundColor3=C.red; sDot.BorderSizePixel=0; MkCorner(sDot,4)

    local sLbl=Instance.new("TextLabel",statusF)
    sLbl.Size=UDim2.new(1,-30,1,0); sLbl.Position=UDim2.new(0,26,0,0)
    sLbl.BackgroundTransparency=1; sLbl.Text="Estado: Inativo"
    sLbl.TextColor3=C.green; sLbl.TextSize=11; sLbl.Font=Enum.Font.GothamBold
    sLbl.TextXAlignment=Enum.TextXAlignment.Left

    task.spawn(function()
        while SG.Parent do task.wait(0.7)
            sLbl.Text = Farm.Active and Farm.StatusText or "Estado: Inativo"
            sDot.BackgroundColor3 = Farm.Active and C.green or C.red
        end
    end)

    Section(pg,"AUTO FARM")
    Toggle(pg,"Auto Farm Level (Quest + Mob-Lock)",false,function(v)
        Farm.Active=v
        if not v then Farm.State="idle"; SetCharCollision(true) end
    end)

    -- seletor de estilo
    Section(pg,"ESTILO DE LUTA")

    local styleRow=Instance.new("Frame",pg)
    styleRow.Size=UDim2.new(1,0,0,44); styleRow.BackgroundTransparency=1
    MkList(styleRow,Enum.FillDirection.Horizontal,6,Enum.HorizontalAlignment.Left)

    local sBtns={}
    local styles={
        {key="melee",label="MELEE"},
        {key="sword",label="SWORD"},
        {key="fruit",label="FRUIT"},
    }

    local function SetStyle(key)
        Farm.Style=key
        for _,sb in ipairs(sBtns) do
            local active=sb.key==key
            TweenService:Create(sb.btn,TweenInfo.new(0.15),{
                BackgroundColor3=active and C.accent or C.card
            }):Play()
            sb.lbl.TextColor3=active and Color3.new(1,1,1) or C.textDim
            sb.lbl.Font=active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end

    for _,st in ipairs(styles) do
        local btn=Instance.new("TextButton",styleRow)
        btn.Size=UDim2.new(0,128,1,0); btn.Text=""; btn.BorderSizePixel=0
        btn.BackgroundColor3=st.key=="melee" and C.accent or C.card
        MkCorner(btn,6)
        if st.key~="melee" then MkStroke(btn,C.border,1) end
        local lbl=Instance.new("TextLabel",btn)
        lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text=st.label; lbl.TextSize=12
        lbl.Font=st.key=="melee" and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.TextColor3=st.key=="melee" and Color3.new(1,1,1) or C.textDim
        lbl.TextXAlignment=Enum.TextXAlignment.Center
        table.insert(sBtns,{key=st.key,btn=btn,lbl=lbl})
        btn.MouseButton1Click:Connect(function() SetStyle(st.key) end)
    end

    local styleDesc=Instance.new("TextLabel",pg)
    styleDesc.Size=UDim2.new(1,0,0,14); styleDesc.BackgroundTransparency=1
    styleDesc.TextColor3=C.textDim; styleDesc.TextSize=10; styleDesc.Font=Enum.Font.Gotham
    styleDesc.TextXAlignment=Enum.TextXAlignment.Left
    local sDescs={
        melee="  Melee: M1 de cima (hover aereo)",
        sword="  Sword: equipa espada + M1 de cima",
        fruit="  Fruit: tecla Z/X de cima",
    }
    task.spawn(function()
        while SG.Parent do task.wait(0.4); styleDesc.Text=sDescs[Farm.Style] or "" end
    end)

    Section(pg,"CONFIGURACOES")

    Label(pg,"  Altura acima do mob (studs, padrao: 5):")
    local hIn=Input(pg,"5",function(v)
        local n=tonumber(v); if n and n>0 then Farm.HoverY=n end
    end); hIn.Text="5"

    Label(pg,"  Mobs para matar por ciclo (padrao: 10):")
    local kIn=Input(pg,"10",function(v)
        local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end
    end); kIn.Text="10"

    Section(pg,"CALIBRAR ZONAS")
    Label(pg,"  Va ate o ponto correto no jogo e clique calibrar.")

    local selIdx=1
    local selLbl=Instance.new("TextLabel",pg)
    selLbl.Size=UDim2.new(1,0,0,30); selLbl.BackgroundColor3=C.card
    selLbl.BorderSizePixel=0; MkCorner(selLbl,6)
    selLbl.Text="  "..QuestZones[1].name.."  |  Lv "..QuestZones[1].minLv.."-"..QuestZones[1].maxLv
    selLbl.TextColor3=C.accent2; selLbl.TextSize=11; selLbl.Font=Enum.Font.GothamBold
    selLbl.TextXAlignment=Enum.TextXAlignment.Left; MkPad(selLbl,8,0,0,0)

    local arrowRow=Instance.new("Frame",pg)
    arrowRow.Size=UDim2.new(1,0,0,32); arrowRow.BackgroundTransparency=1
    MkList(arrowRow,Enum.FillDirection.Horizontal,6)

    local function ArrowBtn(t,cb2)
        local b=Instance.new("TextButton",arrowRow)
        b.Size=UDim2.new(0.5,-3,1,0); b.BackgroundColor3=C.card
        b.Text=t; b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0; MkCorner(b,6); MkStroke(b,C.border,1)
        b.MouseButton1Click:Connect(cb2)
    end
    ArrowBtn("< ANTERIOR",function()
        selIdx=math.max(1,selIdx-1)
        local z=QuestZones[selIdx]
        selLbl.Text="  "..z.name.."  |  Lv "..z.minLv.."-"..z.maxLv
    end)
    ArrowBtn("PROXIMA >",function()
        selIdx=math.min(#QuestZones,selIdx+1)
        local z=QuestZones[selIdx]
        selLbl.Text="  "..z.name.."  |  Lv "..z.minLv.."-"..z.maxLv
    end)

    Button(pg,"CALIBRAR islePos (posicao do NPC Quest)",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        QuestZones[selIdx].islePos=pos
        sLbl.Text=("OK — islePos [%s] = %.0f, %.0f, %.0f"):format(
            QuestZones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Button(pg,"CALIBRAR mobPos (area dos mobs)",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        QuestZones[selIdx].mobPos=pos
        sLbl.Text=("OK — mobPos [%s] = %.0f, %.0f, %.0f"):format(
            QuestZones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)

    -- botao de calibrar questDesc (para versoes diferentes)
    Section(pg,"DEPURACAO")
    Label(pg,"  Nome do mob/quest desta zona (edite se precisar):")
    local qdIn=Input(pg,QuestZones[1].questDesc)
    qdIn.Text=QuestZones[1].questDesc
    -- atualiza quando muda de zona
    local origArrow1=arrowRow:FindFirstChildOfClass("TextButton")

    Button(pg,"APLICAR NOME DA QUEST",function()
        QuestZones[selIdx].questDesc=qdIn.Text
        sLbl.Text="OK — quest ["..QuestZones[selIdx].name.."] = "..qdIn.Text
    end)
    Button(pg,"COPIAR POSICAO ATUAL",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            local str=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(str) end)
            sLbl.Text="Copiado: "..str
        end
    end)

    Section(pg,"ZONAS DISPONIVEIS")
    for _,z in ipairs(QuestZones) do
        Label(pg,("  Lv %3d - %-3d  |  %s  |  %s"):format(
            z.minLv,z.maxLv,z.name,z.questDesc))
    end
end

-- ============================================================
--  ESP
-- ============================================================
do
    local pg=Pages["ESP"]
    Section(pg,"JOGADORES")
    Toggle(pg,"Player ESP",          false,function(v) Cfg.PlayerESP=v end)
    Toggle(pg,"Mostrar Distancia",   true, function(v) Cfg.ShowDist=v end)
    Toggle(pg,"Tracer Lines",        false,function(v) Cfg.TracerLines=v end)
    Section(pg,"FRUTAS")
    Toggle(pg,"Fruit ESP",           false,function(v) Cfg.FruitESP=v end)
    Section(pg,"CONFIGURACOES")
    Label(pg,"  Distancia maxima (studs):")
    local rIn=Input(pg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end); rIn.Text="2000"
end

-- ============================================================
--  TELEPORT
-- ============================================================
do
    local pg=Pages["TELEPORT"]
    Section(pg,"FRUTAS")
    Button(pg,"Teleportar para Fruta Mais Proxima",TP_NearestFruit,true)
    Section(pg,"JOGADORES")
    Label(pg,"  Nome do jogador:")
    local plrIn=Input(pg,"username...")
    Button(pg,"Ir para Jogador",function() TP_Player(plrIn.Text) end)
    Button(pg,"Listar Jogadores Online",function()
        local n={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
        plrIn.Text=table.concat(n,", ")
    end)
    Section(pg,"COORDENADAS")
    Label(pg,"  X, Y, Z separados por virgula:")
    local cIn=Input(pg,"0, 100, 0")
    Button(pg,"Ir para Coordenadas",function()
        local t=string.split(cIn.Text,",")
        local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Button(pg,"Copiar Posicao Atual",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            local str=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(str) end); cIn.Text=str
        end
    end)
end

-- ============================================================
--  ILHAS
-- ============================================================
do
    local pg=Pages["ILHAS"]
    Section(pg,"FIRST SEA")
    local order={
        "Starter Island","Pirate Island","Soldier Island","Shark Island",
        "Chef Ship","Snow Island","Sand Kingdom","Sky Island",
        "Bubble Island","Lobby Island","Zombie Island","War Island","Fishland",
    }
    for _,name in ipairs(order) do
        local p=Locs[name]
        if p then Button(pg,name,function() TP(p) end) end
    end
end

-- ============================================================
--  MISC
-- ============================================================
do
    local pg=Pages["MISC"]
    Section(pg,"COMBATE")
    Toggle(pg,"Auto Ataque (ataque livre + hover)",false,function(v)
        AutoAttack=v
    end)
    Section(pg,"MOVIMENTACAO")
    Toggle(pg,"No Clip",false,function(v)
        local c=LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=not v end
        end end
    end)
    Toggle(pg,"Infinite Jump",false,function(v)
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
    Section(pg,"WALK SPEED"); Label(pg,"  Padrao: 16")
    Input(pg,"16",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
    end)
    Section(pg,"JUMP POWER"); Label(pg,"  Padrao: 50")
    Input(pg,"50",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end
    end)
    Section(pg,"UTILITARIOS")
    Button(pg,"Copiar Posicao",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            pcall(function() setclipboard(("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)) end)
        end
    end)
    Button(pg,"Recarregar Personagem",function()
        SetCharCollision(true); LP:LoadCharacter()
    end)
    Button(pg,"Restaurar Colisao",function() SetCharCollision(true) end)
end

-- ============================================================
--  WEBHOOK
-- ============================================================
do
    local pg=Pages["WEBHOOK"]
    Section(pg,"URL DO WEBHOOK DISCORD")
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
    Section(pg,"ENVIO MANUAL")
    Label(pg,"  Titulo:"); local wht=Input(pg,"Titulo...")
    Label(pg,"  Mensagem:"); local whm=Input(pg,"Mensagem...")
    Button(pg,"Enviar",function() SendWH(wht.Text,whm.Text,3447003) end,true)
    Button(pg,"Testar Conexao",function()
        SendWH("Teste OK","Conectado como **"..LP.Name.."**",65280)
    end)
end

-- ============================================================
--  ESP UPDATE
-- ============================================================
local PLR_ESP={}
local function MakePlayerESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={
        box=NewBox(Cfg.Col_Player), name=NewText(Cfg.Col_Player,13),
        dist=NewText(Color3.new(1,1,1),11),
        hpBg=NewBox(Color3.fromRGB(40,40,40),true),
        hpBar=NewBox(Color3.fromRGB(60,210,100),true),
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
        lbl.Text="FRUIT  "..f.name; lbl.Position=Vector2.new(p2D.X,p2D.Y-10); lbl.Visible=true
        local dlbl=NewText(Color3.new(1,1,1),11)
        dlbl.Text=d.."m"; dlbl.Position=Vector2.new(p2D.X,p2D.Y+6); dlbl.Visible=true
        table.insert(FruitPool,{lbl=lbl,dist=dlbl})
    end
end

-- ============================================================
--  SHOW/HIDE BUTTON
-- ============================================================
local ShowBtn=Instance.new("TextButton",SG)
ShowBtn.Size=UDim2.new(0,140,0,32); ShowBtn.Position=UDim2.new(0,20,0,55)
ShowBtn.BackgroundColor3=C.sidebar; ShowBtn.Text="CHINA HUB FREE"
ShowBtn.TextColor3=C.accent2; ShowBtn.TextSize=11; ShowBtn.Font=Enum.Font.GothamBold
ShowBtn.BorderSizePixel=0; ShowBtn.Visible=false
MkCorner(ShowBtn,8); MkStroke(ShowBtn,C.accent,1.5)

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
SwitchTab("HOME")

for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MakePlayerESP(pl) end)
Players.PlayerRemoving:Connect(KillPlayerESP)
LP.CharacterAdded:Connect(function()
    SetCharCollision(true); Farm.State="idle"; task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
end)

local t2=0
RunService.RenderStepped:Connect(function()
    t2=t2+1; UpdatePlayerESP()
    if t2%14==0 then UpdateFruitESP(); t2=0 end
end)

print("[China Hub Free v5.0] Carregado — "..LP.Name)
