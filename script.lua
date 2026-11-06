-- ============================================================
--  CHINA HUB FREE  v7.0  —  King Legacy Update 11
--  Auto Farm | Auto Boss | Auto Dungeon | Auto Raid
--  Sea Events | Kill Aura | Auto Stats | Auto Haki
--  ESP Players/Fruits/Bosses | Fruit Notifier + Discord Webhook
--  Server Hop | Hitbox Expand | Fly Mode
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local VIM              = game:GetService("VirtualInputManager")
local RS               = game:GetService("ReplicatedStorage")
local TS               = game:GetService("TeleportService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local SEA_Y  = 15

-- ============================================================
--  LEVEL
-- ============================================================
local function GetLevel()
    local ps = LP:FindFirstChild("PlayerStats")
    if ps then
        for _, n in ipairs({"lvl","Level","Lv","level","Lvl"}) do
            local v = ps:FindFirstChild(n)
            if v then return math.max(1, tonumber(v.Value) or 1) end
        end
    end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Level","Lv","level","lvl","Lvl"}) do
            local v = ls:FindFirstChild(n)
            if v then return math.max(1, tonumber(v.Value) or 1) end
        end
    end
    return 1
end

local function GetBeli()
    local ps = LP:FindFirstChild("PlayerStats")
    if ps then
        for _, n in ipairs({"Beli","beli","Gold","Coins","Money"}) do
            local v = ps:FindFirstChild(n)
            if v then return tonumber(v.Value) or 0 end
        end
    end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Beli","Gold","Coins","Money"}) do
            local v = ls:FindFirstChild(n)
            if v then return tonumber(v.Value) or 0 end
        end
    end
    return 0
end

local function GetStatPoints()
    local ps = LP:FindFirstChild("PlayerStats")
    if ps then
        for _, n in ipairs({"StatPoints","Points","FreePoints","StatPoint"}) do
            local v = ps:FindFirstChild(n)
            if v then return tonumber(v.Value) or 0 end
        end
    end
    return 0
end

-- ============================================================
--  ZONAS — Update 10/11 (calibrar as novas em jogo)
-- ============================================================
local Zones = {
    { name="Starter Island",      minLv=1,    maxLv=49,
      islePos=Vector3.new(-2044,100,-4591),
      mobPos= Vector3.new(-2044,100,-4591),  radius=400 },

    { name="Pirate Island",       minLv=50,   maxLv=99,
      islePos=Vector3.new(-681,64,-3449),
      mobPos= Vector3.new(-681,64,-3449),    radius=400 },

    { name="Soldier Island",      minLv=100,  maxLv=179,
      islePos=Vector3.new(990,28,-510),
      mobPos= Vector3.new(990,28,-510),      radius=400 },

    { name="Shark Island",        minLv=180,  maxLv=249,
      islePos=Vector3.new(1822,28,1492),
      mobPos= Vector3.new(1822,28,1492),     radius=400 },

    { name="Chef Ship",           minLv=250,  maxLv=399,
      islePos=Vector3.new(-792,28,1242),
      mobPos= Vector3.new(-792,28,1242),     radius=400 },

    { name="Snow Island",         minLv=400,  maxLv=524,
      islePos=Vector3.new(1622,28,-872),
      mobPos= Vector3.new(1622,28,-872),     radius=400 },

    { name="Sand Kingdom",        minLv=525,  maxLv=799,
      islePos=Vector3.new(-3052,28,1978),
      mobPos= Vector3.new(-3052,28,1978),    radius=400 },

    { name="Sky Island",          minLv=800,  maxLv=999,
      islePos=Vector3.new(-2822,865,-1632),
      mobPos= Vector3.new(-2822,865,-1632),  radius=400 },

    { name="Bubble Island",       minLv=1000, maxLv=1499,
      islePos=Vector3.new(2552,28,-2058),
      mobPos= Vector3.new(2552,28,-2058),    radius=400 },

    -- 2° Mar (calibrar in-game)
    { name="2nd Sea – Entrada",   minLv=1500, maxLv=2199,
      islePos=Vector3.new(0,100,0),
      mobPos= Vector3.new(0,100,0),          radius=500,  calibrate=true },

    { name="2nd Sea – Mid",       minLv=2200, maxLv=2999,
      islePos=Vector3.new(0,100,0),
      mobPos= Vector3.new(0,100,0),          radius=500,  calibrate=true },

    -- 3° Mar (calibrar in-game — Update 9/10/11)
    { name="3rd Sea – Inicio",    minLv=3000, maxLv=3799,
      islePos=Vector3.new(0,100,0),
      mobPos= Vector3.new(0,100,0),          radius=600,  calibrate=true },

    { name="3rd Sea – Mid",       minLv=3800, maxLv=4499,
      islePos=Vector3.new(0,100,0),
      mobPos= Vector3.new(0,100,0),          radius=600,  calibrate=true },

    { name="3rd Sea – End (Upd10/11)", minLv=4500, maxLv=9999,
      islePos=Vector3.new(0,100,0),
      mobPos= Vector3.new(0,100,0),          radius=600,  calibrate=true },
}

local function GetZone(lv)
    for _, z in ipairs(Zones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return Zones[#Zones]
end

-- ============================================================
--  FRUTAS LENDÁRIAS / MÍTICAS — lista completa Update 11
-- ============================================================
local LegendaryList = {
    -- Mythical (máxima raridade)
    "Pteranodon",
    -- Legendary — Update 11
    "Erebus", "Loki",
    -- Legendary — Update 10
    "Tree", "TreeFruit", "Tree_Fruit",
    "Demon", "DemonFruit", "Demon_Fruit",
    -- Legendary clássicas
    "Dragon", "DragonFruit", "Dragon_Fruit",
    "Toy", "ToyFruit", "Toy_Fruit",
    "Phoenix", "PhoenixFruit", "Phoenix_Fruit",
    "Gold", "GoldFruit", "Gold_Fruit",
    "Dough", "DoughFruit", "Dough_Fruit",
    "Leopard", "LeopardFruit",
    "Portal", "PortalFruit",
    "Gravity", "GravityFruit",
    "Shadow", "ShadowFruit",
    "Soul", "SoulFruit",
    "Control", "ControlFruit",
    "Venom", "VenomFruit",
    "String", "StringFruit",
    "Gas", "GasFruit",
    "Surge", "SurgeFruit",
    "Rumble", "RumbleFruit",
    "Barrier", "BarrierFruit",
    "Blizzard", "BlizzardFruit",
    "Human", "HumanFruit",
    "Buddha", "BuddhaFruit",
    "Love", "LoveFruit",
}

local function IsFruitLegendary(obj)
    -- Verifica raridade via StringValue dentro do modelo
    local rarV = obj:FindFirstChild("Rarity") or obj:FindFirstChild("Raridade")
        or obj:FindFirstChild("FruitRarity") or obj:FindFirstChild("Type")
    if rarV then
        local r = tostring(rarV.Value):lower()
        if r == "legendary" or r == "mythical" or r == "lendaria" or r == "mitica" then
            return true, rarV.Value
        end
    end
    -- Fallback: nome do objeto
    local name = obj.Name
    for _, kw in ipairs(LegendaryList) do
        if name:lower():find(kw:lower()) then return true, "Legendary(nome)" end
    end
    return false, nil
end

-- ============================================================
--  FRUTAS — scan geral
-- ============================================================
local FruitKW = {
    "fruit","devil","gumgum","chop","smoke","flame","ice","magnet",
    "light","dark","quake","phoenix","dragon","rubb","sand","diamond","paw",
    "gravity","string","shadow","portal","control","venom","leopard","blizzard",
    "gas","surge","rumble","barrier","soul","human","buddha","love",
    "dough","toy","tree","demon","erebus","loki","pteranodon","gold","bounce",
}

local function IsFruit(obj)
    local n = obj.Name:lower()
    for _, k in ipairs(FruitKW) do if n:find(k) then return true end end
    return false
end

local function ScanFruits()
    local out = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsFruit(obj) then
            local pos
            if obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then pos = obj.Position end
            if pos then
                local isLeg, rarity = IsFruitLegendary(obj)
                table.insert(out, {name=obj.Name, pos=pos, legendary=isLeg, rarity=rarity, obj=obj})
            end
        end
    end
    return out
end

-- ============================================================
--  ENCONTRAR MOB — scan universal
-- ============================================================
local function FindMob(nearPos, radius)
    local char = LP.Character; if not char then return nil end
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char
           and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - nearPos).Magnitude
                if d < radius and d < bestD then
                    bestD = d; best = obj
                end
            end
        end
    end
    return best, bestD
end

-- ============================================================
--  ENCONTRAR BOSS por nome parcial
-- ============================================================
local function FindBoss(namePattern, searchRadius)
    searchRadius = searchRadius or 5000
    local char = LP.Character
    local origin = char and char:FindFirstChild("HumanoidRootPart")
        and char.HumanoidRootPart.Position or Vector3.new(0,0,0)
    local best, bestD = nil, math.huge
    local pat = namePattern:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char
           and not Players:GetPlayerFromCharacter(obj)
           and obj.Name:lower():find(pat) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - origin).Magnitude
                if d < searchRadius and d < bestD then bestD = d; best = obj end
            end
        end
    end
    return best, bestD
end

-- ============================================================
--  TELEPORTE SEGURO
-- ============================================================
local seaFails = 0
local function SafeTP(pos)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(
        Vector3.new(pos.X, math.max(pos.Y + 5, 60), pos.Z)
    )
    task.wait(1.2)
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        seaFails = seaFails + 1; return false
    end
    seaFails = 0; return true
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
        return (char.HumanoidRootPart.Position - a.pos).Magnitude
             < (char.HumanoidRootPart.Position - b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

local function TP_NearestLegendary()
    local fruits = ScanFruits()
    local legs = {}
    for _, f in ipairs(fruits) do if f.legendary then table.insert(legs,f) end end
    if #legs == 0 then return false end
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    table.sort(legs, function(a,b)
        return (char.HumanoidRootPart.Position - a.pos).Magnitude
             < (char.HumanoidRootPart.Position - b.pos).Magnitude
    end)
    TP(legs[1].pos); return true, legs[1]
end

-- ============================================================
--  COLISÃO
-- ============================================================
local function SetCollision(v)
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = v end
    end
end

-- ============================================================
--  QUEST RF + PROXIMITY PROMPT FALLBACK
-- ============================================================
local questRF = nil

local function TryGetRF()
    if questRF then return questRF end
    local paths = {
        {"Chest","Functions","Quest"},
        {"Remotes","Quest"},
        {"RemoteEvents","Quest"},
        {"Functions","Quest"},
        {"RemoteFunctions","Quest"},
    }
    for _, p in ipairs(paths) do
        local cur = RS; local ok = true
        for _, seg in ipairs(p) do
            local next = cur:FindFirstChild(seg)
            if not next then ok=false; break end
            cur = next
        end
        if ok then questRF = cur; return questRF end
    end
    return nil
end

local function TakeQuestRF(desc)
    local rf = TryGetRF(); if not rf then return false end
    local ok = pcall(function() rf:InvokeServer("take", desc) end)
    if not ok then ok = pcall(function() rf:InvokeServer(desc) end) end
    return ok
end

local function FindQuestPrompt(nearPos, radius)
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if not (part and part:IsA("BasePart")) then continue end
            local d = (part.Position - nearPos).Magnitude
            if d >= radius or d >= bestD then continue end
            local isBoat = false
            local cur = part
            for _ = 1, 6 do
                cur = cur.Parent
                if not cur then break end
                local n = cur.Name:lower()
                if n:find("boat") or n:find("ship") or n:find("navio") then
                    isBoat = true; break
                end
            end
            if isBoat then continue end
            local at = (obj.ActionText or ""):lower()
            local ot = (obj.ObjectText  or ""):lower()
            if at:find("quest") or at:find("miss") or at:find("interag")
               or ot:find("quest") then
                best = obj; bestD = d
            end
            local model = part.Parent
            if model and model:IsA("Model") and model.Name:lower():find("quest") then
                best = obj; bestD = d
            end
        end
    end
    return best
end

local function FirePP(pp)
    if not pp then return end
    pcall(function() fireproximityprompt(pp) end)
end

-- ============================================================
--  EQUIP TOOL
-- ============================================================
local function EquipFirst(style)
    local char = LP.Character; if not char then return end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if style == "sword" then
                if n:find("sword") or n:find("katana") or n:find("blade") or n:find("cutlass")
                   or n:find("saber") or n:find("scythe") or n:find("broom") then
                    char.Humanoid:EquipTool(t); task.wait(0.25); return
                end
            else
                char.Humanoid:EquipTool(t); task.wait(0.25); return
            end
        end
    end
end

-- ============================================================
--  PRESSIONAR TECLA
-- ============================================================
local function PressKey(kc)
    pcall(function()
        if syn and syn.key_press then
            syn.key_press(kc); task.wait(0.07); syn.key_release(kc)
        elseif keypress then
            keypress(kc); task.wait(0.07); if keyrelease then keyrelease(kc) end
        end
    end)
end

-- ============================================================
--  ATACAR MOB
-- ============================================================
local function AttackMob(mob, hoverY, style)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    hoverY = hoverY or 5
    local over = hrp.Position + Vector3.new(0, hoverY, 0)
    char.HumanoidRootPart.CFrame = CFrame.lookAt(over, hrp.Position)
    SetCollision(false)

    if style == "fruit" then
        PressKey(0x5A); task.wait(0.05); PressKey(0x58)
    elseif style == "sword" then
        EquipFirst("sword")
    end

    local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
    if onScr then
        local x, y = math.floor(sp.X), math.floor(sp.Y)
        VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
        task.wait(0.06)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end
end

-- ============================================================
--  HITBOX EXPAND
-- ============================================================
local HitboxCon = nil
local function SetHitbox(v, size)
    if HitboxCon then HitboxCon:Disconnect(); HitboxCon = nil end
    if not v then return end
    HitboxCon = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Size = Vector3.new(size,size,size) end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    hrp.Size = Vector3.new(size,size,size)
                end
            end
        end
    end)
end

-- ============================================================
--  FLY
-- ============================================================
local flyEnabled = false
local flyBody    = nil

local function SetFly(v, speed)
    flyEnabled = v; speed = speed or 50
    local char = LP.Character; if not char then return end
    if not v then
        if flyBody then flyBody:Destroy(); flyBody = nil end
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if flyBody then flyBody:Destroy() end
    flyBody = Instance.new("BodyVelocity"); flyBody.Parent = hrp
    flyBody.Velocity = Vector3.new(0,0,0); flyBody.MaxForce = Vector3.new(1,1,1)*1e5
    task.spawn(function()
        while flyEnabled and flyBody and flyBody.Parent do
            task.wait()
            local char2 = LP.Character; if not char2 then break end
            local hrp2 = char2:FindFirstChild("HumanoidRootPart"); if not hrp2 then break end
            local cam = Camera.CFrame
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then flyBody.Velocity = dir.Unit * speed
            else flyBody.Velocity = Vector3.new(0,0,0) end
        end
    end)
end

LP.CharacterAdded:Connect(function()
    flyBody = nil
    if flyEnabled then task.wait(1); SetFly(true) end
end)

-- ============================================================
--  SERVER HOP
-- ============================================================
local function ServerHop()
    pcall(function() TS:Teleport(game.PlaceId) end)
end

-- ============================================================
--  WEBHOOK
-- ============================================================
local function SendWebhook(url, title, description, color, fields)
    if not url or url == "" then return end
    local req = syn and syn.request
        or (http and http.request)
        or (request)
    if not req then return end
    local embedFields = fields or {}
    pcall(req, {
        Url    = url,
        Method = "POST",
        Headers= {["Content-Type"]="application/json"},
        Body   = HttpService:JSONEncode({
            username = "China Hub Free | King Legacy",
            avatar_url = "https://tr.rbxcdn.com/180DAY-b65da32af1c66f5c74c6f6ab06ff5bfe/420/420/Image/Webp/noFilter",
            embeds = {{
                title       = title or "Notificação",
                description = description or "",
                color       = color or 10066329,
                fields      = embedFields,
                footer      = { text = "China Hub v7.0 | " .. LP.Name .. " | " .. os.date("!%d/%m/%Y %H:%M:%S") .. " UTC" },
            }}
        })
    })
end

-- ============================================================
--  AUTO STATS
-- ============================================================
local AutoStats = {
    Active    = false,
    Str       = 0,
    Def       = 0,
    Agi       = 0,
    Health    = 0,
    Fruit     = 100,  -- por padrão coloca tudo em fruta
}

local statRemotes = {}
local function FindStatRFs()
    if next(statRemotes) then return true end
    local searchNames = {
        "AddStat","AddPoint","StatAdd","UpgradeStat","Upgrade",
        "AddStr","AddDef","AddAgi","AddHP","AddFruit",
    }
    for _, name in ipairs(searchNames) do
        local rf = RS:FindFirstChild(name, true)
        if rf then statRemotes[name] = rf end
    end
    return next(statRemotes) ~= nil
end

local statNames = {
    Str    = {"Str","Strength","STR","str"},
    Def    = {"Def","Defense","DEF","def"},
    Agi    = {"Agi","Speed","AGI","agi","Spd"},
    Health = {"HP","Health","HEALTH","hp"},
    Fruit  = {"Fruit","Devil","FRUIT","fruit","FruitPow"},
}

local function AddStat(statKey, amount)
    amount = amount or 1
    FindStatRFs()
    for rfName, rf in pairs(statRemotes) do
        for _, statStr in ipairs(statNames[statKey] or {statKey}) do
            pcall(function()
                if rf:IsA("RemoteFunction") then
                    rf:InvokeServer(statStr, amount)
                elseif rf:IsA("RemoteEvent") then
                    rf:FireServer(statStr, amount)
                end
            end)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if not AutoStats.Active then continue end
        local pts = GetStatPoints()
        if pts <= 0 then continue end
        -- distribui 1 ponto por ciclo, seguindo as percentagens
        local total = AutoStats.Str + AutoStats.Def + AutoStats.Agi + AutoStats.Health + AutoStats.Fruit
        if total <= 0 then continue end
        local roll = math.random(1, total)
        local acc  = 0
        local function pick(key, val)
            acc = acc + val
            if roll <= acc then AddStat(key) end
        end
        pick("Str",    AutoStats.Str)
        pick("Def",    AutoStats.Def)
        pick("Agi",    AutoStats.Agi)
        pick("Health", AutoStats.Health)
        pick("Fruit",  AutoStats.Fruit)
    end
end)

-- ============================================================
--  AUTO HAKI
-- ============================================================
local AutoHaki = { Buso=false, Ken=false }

task.spawn(function()
    while true do
        task.wait(2)
        if not (AutoHaki.Buso or AutoHaki.Ken) then continue end
        local char = LP.Character; if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        if AutoHaki.Buso then PressKey(0x51) end  -- Q
        if AutoHaki.Ken  then PressKey(0x45) end  -- E
        task.wait(0.1)
    end
end)

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
    UseQuest    = true,
    KillAura    = false,
    KillAuraRange = 200,
}

-- ============================================================
--  BOSS CONFIG
-- ============================================================
local BossConfig = {
    Active       = false,
    StatusText   = "Inativo",
    Style        = "melee",
    HoverY       = 5,
    AutoTP       = true,
    SelectedBoss = "Death King",
}

local BossList = {
    -- Update 11 Halloween
    { name="Death King",    pattern="Death",    pos=nil, range=3000, notes="Halloween Event Upd11, 11M HP" },
    -- Clássicos
    { name="Kaido",         pattern="Kaido",    pos=nil, range=5000, notes="3° Mar, spawn fixo" },
    { name="Big Mom",       pattern="BigMom",   pos=nil, range=5000, notes="3° Mar, spawn fixo" },
    { name="Sea King",      pattern="SeaKing",  pos=nil, range=8000, notes="Spawn aleatório no mar" },
    { name="Hydra",         pattern="Hydra",    pos=nil, range=5000, notes="Raid" },
    { name="Ghost Ship",    pattern="Ghost",    pos=nil, range=8000, notes="Sea event aleatório" },
    { name="Pteranodon",    pattern="Pterano",  pos=nil, range=8000, notes="Spawn 2h, Update 10" },
    { name="Drakenfyr",     pattern="Drakenfyr",pos=nil, range=8000, notes="3° Mar Event" },
    { name="Arlong",        pattern="Arlong",   pos=nil, range=800,  notes="1° Mar" },
    { name="Don Krieg",     pattern="Krieg",    pos=nil, range=800,  notes="1° Mar" },
    { name="Ax-Hand Morgan",pattern="Morgan",   pos=nil, range=800,  notes="1° Mar" },
}

task.spawn(function()
    while true do
        task.wait(0.3)
        if not BossConfig.Active then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(3); continue end

        -- encontra o boss selecionado
        local bossEntry = nil
        for _, b in ipairs(BossList) do
            if b.name == BossConfig.SelectedBoss then bossEntry = b; break end
        end
        if not bossEntry then task.wait(1); continue end

        local boss, dist = FindBoss(bossEntry.pattern, bossEntry.range)
        if boss then
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y > SEA_Y then
                AttackMob(boss, BossConfig.HoverY, BossConfig.Style)
                local h = boss:FindFirstChildOfClass("Humanoid")
                local hp = h and math.floor(h.Health) or 0
                BossConfig.StatusText = ("%s | HP %d | %.0f studs"):format(
                    bossEntry.name, hp, dist or 0)
            end
        else
            BossConfig.StatusText = bossEntry.name .. " — procurando..."
            task.wait(2)
        end
    end
end)

-- ============================================================
--  DUNGEON CONFIG
-- ============================================================
local DungeonConfig = {
    Active     = false,
    StatusText = "Inativo",
    Style      = "melee",
    HoverY     = 5,
    -- cada mar tem dungeon em ilha específica — calibrar
    Pos1       = Vector3.new(0,100,0),
    Pos2       = Vector3.new(0,100,0),
    Pos3       = Vector3.new(0,100,0),
}

task.spawn(function()
    while true do
        task.wait(0.3)
        if not DungeonConfig.Active then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(3); continue end

        local lv = GetLevel()
        local dunPos = DungeonConfig.Pos1
        if lv >= 1500 then dunPos = DungeonConfig.Pos2 end
        if lv >= 3000 then dunPos = DungeonConfig.Pos3 end

        local mob = FindMob(char.HumanoidRootPart.Position, 600)
        if mob then
            AttackMob(mob, DungeonConfig.HoverY, DungeonConfig.Style)
            local h = mob:FindFirstChildOfClass("Humanoid")
            DungeonConfig.StatusText = ("Dungeon Lv%d | %s | HP %d"):format(
                lv, mob.Name, h and math.floor(h.Health) or 0)
        else
            DungeonConfig.StatusText = ("Dungeon Lv%d | Procurando mobs..."):format(lv)
            -- tenta aceitar a dungeon via ProximityPrompt
            local pp = FindQuestPrompt(dunPos, 500)
            if pp then FirePP(pp); task.wait(0.5) end
            task.wait(1.5)
        end
    end
end)

-- ============================================================
--  SEA EVENT CONFIG
-- ============================================================
local SeaEvent = {
    Active       = false,
    SeaBeast     = true,
    GhostShip    = false,
    StatusText   = "Inativo",
    Style        = "melee",
    HoverY       = 8,
}

task.spawn(function()
    while true do
        task.wait(0.3)
        if not SeaEvent.Active then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(3); continue end

        local target = nil
        if SeaEvent.SeaBeast then
            local beast, _ = FindBoss("SeaBeast", 8000)
            if not beast then beast, _ = FindBoss("Beast", 8000) end
            if beast then target = beast end
        end
        if not target and SeaEvent.GhostShip then
            local gs, _ = FindBoss("Ghost", 8000)
            if gs then target = gs end
        end

        if target then
            local h = target:FindFirstChildOfClass("Humanoid")
            AttackMob(target, SeaEvent.HoverY, SeaEvent.Style)
            SeaEvent.StatusText = ("Sea Event | %s | HP %d"):format(
                target.Name, h and math.floor(h.Health) or 0)
        else
            SeaEvent.StatusText = "Sea Event | Aguardando spawn..."
            task.wait(2)
        end
    end
end)

-- ============================================================
--  FRUIT NOTIFIER
-- ============================================================
local FruitNotifier = {
    Active          = false,
    WebhookUrl      = "",
    ServerHopOnFind = false,
    NotifyAll       = false,  -- se false: só Legendary/Mythical
    LastNotified    = {},     -- evita spam do mesmo obj
    StatusText      = "Inativo",
    ScanInterval    = 3,
    AutoCollect     = false,
}

local function GetServerLink()
    -- Deeplink para o servidor atual
    -- roblox://experiences/start?placeId=PLACEID&gameInstanceId=JOBID
    return ("https://www.roblox.com/games/%s/King-Legacy?privateServerLinkCode=%s"):format(
        tostring(game.PlaceId), tostring(game.JobId))
end

task.spawn(function()
    while true do
        task.wait(FruitNotifier.ScanInterval)
        if not FruitNotifier.Active then continue end

        local fruits = ScanFruits()
        for _, f in ipairs(fruits) do
            if FruitNotifier.NotifyAll or f.legendary then
                -- evita notificar o mesmo objeto duas vezes
                local key = tostring(f.obj) .. tostring(f.name)
                if FruitNotifier.LastNotified[key] then continue end
                FruitNotifier.LastNotified[key] = true
                -- limpa cache após 60s
                task.delay(60, function() FruitNotifier.LastNotified[key] = nil end)

                local rarity = f.rarity or (f.legendary and "Legendary" or "Common")
                FruitNotifier.StatusText = ("🍎 " .. f.name .. " (" .. rarity .. ")")

                if FruitNotifier.WebhookUrl ~= "" then
                    SendWebhook(
                        FruitNotifier.WebhookUrl,
                        "🍎 " .. (f.legendary and "FRUTA LENDÁRIA/MÍTICA SPAWNADA!" or "Fruta encontrada!"),
                        "Uma **" .. f.name .. "** foi detectada no mapa!",
                        f.legendary and 16711680 or 65280,
                        {
                            { name="Raridade",   value=rarity,                       inline=true  },
                            { name="Servidor",   value="`" .. tostring(game.JobId) .. "`",         inline=false },
                            { name="Posição",    value=("X: %.0f Y: %.0f Z: %.0f"):format(f.pos.X,f.pos.Y,f.pos.Z), inline=false },
                            { name="Link Roblox",value=GetServerLink(),              inline=false },
                            { name="Jogador",    value=LP.Name,                      inline=true  },
                        }
                    )
                end

                -- auto-coletar
                if FruitNotifier.AutoCollect then
                    TP(f.pos)
                    task.wait(0.5)
                    local pp = FindQuestPrompt(f.pos, 20)
                    if pp then FirePP(pp) end
                end

                -- server hop se não encontrou lendária e está ativo
                if not f.legendary and FruitNotifier.ServerHopOnFind then
                    -- não hopa por fruta comum
                end
            end
        end
    end
end)

-- server hop automático procurando lendária
task.spawn(function()
    while true do
        task.wait(5)
        if not (FruitNotifier.Active and FruitNotifier.ServerHopOnFind) then continue end
        -- verifica se tem lendária no servidor atual
        local fruits = ScanFruits()
        local hasLeg = false
        for _, f in ipairs(fruits) do
            if f.legendary then hasLeg = true; break end
        end
        if not hasLeg then
            FruitNotifier.StatusText = "Server Hop — procurando lendária..."
            task.wait(8)  -- dá tempo pra escanear antes de hopar
            -- re-checa
            fruits = ScanFruits()
            for _, f in ipairs(fruits) do
                if f.legendary then hasLeg = true; break end
            end
            if not hasLeg then ServerHop() end
        else
            FruitNotifier.StatusText = "Lendária encontrada! Permanecendo no servidor."
        end
    end
end)

-- ============================================================
--  AUTO FARM LOOP PRINCIPAL
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.25)
        if not Farm.Active then
            Farm.State = "idle"; SetCollision(true); continue
        end

        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1); continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            SetCollision(true)
            Farm.StatusText = "Respawnando..."
            Farm.State = "idle"; task.wait(4); continue
        end

        local lv   = GetLevel()
        local zone = GetZone(lv)

        if Farm.State == "idle" then
            Farm.Zone      = zone
            Farm.KillCount = 0
            Farm.StatusText = ("Lv %d  |  %s  |  Viajando"):format(lv, zone.name)
            Farm.State = "tozone"

        elseif Farm.State == "tozone" then
            if zone.calibrate then
                Farm.StatusText = "CALIBRAR: " .. zone.name .. " — use a aba Farm para definir posição"
                Farm.Active = false; Farm.State = "idle"; continue
            end
            local ok = SafeTP(Farm.Zone.mobPos)
            if not ok then continue end

            if Farm.UseQuest then
                local questDescs = {
                    [1]  = "Kill 4 Soldiers",
                    [10] = "Kill 5 Clown Pirates",
                    [20] = "Kill 1 Smoky",
                    [30] = "Kill 1 Tashi",
                    [50] = "Kill 6 Clown Swordman",
                    [75] = "Kill 1 The Clown",
                    [100]= "Kill 8 Marines",
                    [140]= "Kill 1 Ax-Hand Morgan",
                    [180]= "Kill 8 Fish Pirates",
                    [225]= "Kill 1 Arlong",
                    [250]= "Kill 8 Don Krieg Pirates",
                    [350]= "Kill 1 Don Krieg",
                    [400]= "Kill 8 Snow Soldiers",
                    [525]= "Kill 8 Sand Pirates",
                    [800]= "Kill 8 Sky Warriors",
                }
                local desc = nil; local bestT = -1
                for threshold, d in pairs(questDescs) do
                    if lv >= threshold and threshold > bestT then
                        bestT = threshold; desc = d
                    end
                end
                if desc then TakeQuestRF(desc); task.wait(0.5) end
                local pp = FindQuestPrompt(Farm.Zone.islePos, 350)
                if pp then FirePP(pp); task.wait(0.4); FirePP(pp); task.wait(0.3) end
            end

            if Farm.Style == "sword" then EquipFirst("sword") end
            Farm.State = "fighting"; Farm.KillCount = 0
            Farm.StatusText = ("Lv %d  |  %s  |  Lutando"):format(lv, zone.name)

        elseif Farm.State == "fighting" then
            local mob, dist = FindMob(Farm.Zone.mobPos, Farm.Zone.radius)

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                if hrp.Position.Y < SEA_Y then task.wait(0.3); continue end

                local hBefore = mob:FindFirstChildOfClass("Humanoid")
                local hpB     = hBefore and hBefore.Health or 0

                AttackMob(mob, Farm.HoverY, Farm.Style); task.wait(0.15)

                local hAfter = mob:FindFirstChildOfClass("Humanoid")
                if not hAfter or hAfter.Health <= 0 then
                    if hpB > 0 then Farm.KillCount = Farm.KillCount + 1 end
                end

                local curHp = hAfter and math.floor(hAfter.Health) or 0
                Farm.StatusText = ("Lv %d  |  %s  |  %d/%d kills  |  HP mob %d"):format(
                    lv, zone.name, Farm.KillCount, Farm.TargetKills, curHp)

                if Farm.KillCount >= Farm.TargetKills then
                    SetCollision(true); Farm.State = "idle"
                    Farm.StatusText = ("Lv %d  |  Ciclo completo! Reiniciando..."):format(lv)
                end
            else
                SafeTP(Farm.Zone.mobPos)
                Farm.StatusText = ("Lv %d  |  %s  |  Aguardando spawn..."):format(lv, zone.name)
                if Farm.KillCount >= Farm.TargetKills then
                    SetCollision(true); Farm.State = "idle"
                end
                task.wait(2)
            end
        end
    end
end)

-- ============================================================
--  KILL AURA INDEPENDENTE
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not Farm.KillAura then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(2); continue end
        local origin = char.HumanoidRootPart.Position
        local mob = FindMob(origin, Farm.KillAuraRange)
        if mob then AttackMob(mob, Farm.HoverY, Farm.Style) end
    end
end)

-- ============================================================
--  ESP CONFIG
-- ============================================================
local Cfg = {
    PlayerESP    = false,
    FruitESP     = false,
    BossESP      = false,
    ShowDist     = true,
    TracerLines  = false,
    ESPRange     = 2000,
    HideKey      = Enum.KeyCode.LeftControl,
    Col_P        = Color3.fromRGB(220,60,60),
    Col_F_Common = Color3.fromRGB(180,180,180),
    Col_F_Leg    = Color3.fromRGB(255,215,0),
    Col_Boss     = Color3.fromRGB(255,80,20),
}

local function NTxt(col,sz) local t=Drawing.new("Text"); t.Color=col or Color3.new(1,1,1); t.Size=sz or 13; t.Center=true; t.Outline=true; t.Visible=false; return t end
local function NBox(col,f) local b=Drawing.new("Square"); b.Color=col or Color3.new(1,1,1); b.Thickness=1.5; b.Filled=f or false; b.Visible=false; return b end
local function NLine(col) local l=Drawing.new("Line"); l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Visible=false; return l end
local function W2V(pos) local sp=Camera:WorldToViewportPoint(pos); return Vector2.new(sp.X,sp.Y),sp.Z,sp.Z>0 end
local function Dist(pos) local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then return math.floor((c.HumanoidRootPart.Position-pos).Magnitude) end; return 0 end

-- ============================================================
--  GUI
-- ============================================================
local old = CoreGui:FindFirstChild("CHINAHUB7"); if old then old:Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name="CHINAHUB7"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true; SG.Parent=CoreGui

local C = {
    bg    = Color3.fromRGB(8,8,14),
    side  = Color3.fromRGB(11,11,19),
    panel = Color3.fromRGB(15,15,24),
    card  = Color3.fromRGB(20,20,33),
    cardH = Color3.fromRGB(26,26,42),
    acc   = Color3.fromRGB(165,55,255),
    acc2  = Color3.fromRGB(210,100,255),
    green = Color3.fromRGB(55,205,105),
    red   = Color3.fromRGB(215,55,70),
    gold  = Color3.fromRGB(255,215,0),
    text  = Color3.fromRGB(228,228,242),
    dim   = Color3.fromRGB(115,115,140),
    bord  = Color3.fromRGB(45,35,75),
    sep   = Color3.fromRGB(28,22,48),
}

local function Rnd(p,r)  local c=Instance.new("UICorner",p);  c.CornerRadius=UDim.new(0,r or 8) end
local function Str(p,col,t) local s=Instance.new("UIStroke",p); s.Color=col or C.bord; s.Thickness=t or 1; return s end
local function Pad(p,l,r,t,b) local x=Instance.new("UIPadding",p); x.PaddingLeft=UDim.new(0,l or 0); x.PaddingRight=UDim.new(0,r or 0); x.PaddingTop=UDim.new(0,t or 0); x.PaddingBottom=UDim.new(0,b or 0) end
local function Lst(p,dir,sp,ha) local l=Instance.new("UIListLayout",p); l.FillDirection=dir or Enum.FillDirection.Vertical; l.Padding=UDim.new(0,sp or 6); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left; return l end

-- janela
local WIN = Instance.new("Frame", SG)
WIN.Size=UDim2.new(0,700,0,540); WIN.Position=UDim2.new(0.5,-350,0.5,-270)
WIN.BackgroundColor3=C.bg; WIN.BorderSizePixel=0; Rnd(WIN,12)
local ws=Str(WIN,C.bord,1.5)
local wg=Instance.new("UIGradient",ws)
wg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,C.acc),ColorSequenceKeypoint.new(0.5,C.bord),ColorSequenceKeypoint.new(1,C.acc)}
wg.Rotation=90

-- topbar
local Top = Instance.new("Frame",WIN)
Top.Size=UDim2.new(1,0,0,46); Top.BackgroundColor3=C.side; Top.BorderSizePixel=0; Rnd(Top,12)

local TopLine = Instance.new("Frame",Top)
TopLine.Size=UDim2.new(1,0,0,2); TopLine.Position=UDim2.new(0,0,1,-2)
TopLine.BackgroundColor3=C.acc; TopLine.BorderSizePixel=0
local tlg = Instance.new("UIGradient",TopLine)
tlg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,C.acc),ColorSequenceKeypoint.new(0.4,C.acc2),ColorSequenceKeypoint.new(0.6,C.gold),ColorSequenceKeypoint.new(1,C.acc)}

local Dot = Instance.new("Frame",Top)
Dot.Size=UDim2.new(0,3,0.5,0); Dot.Position=UDim2.new(0,12,0.25,0)
Dot.BackgroundColor3=C.acc; Dot.BorderSizePixel=0; Rnd(Dot,2)

local TLbl = Instance.new("TextLabel",Top)
TLbl.Size=UDim2.new(1,-120,0,24); TLbl.Position=UDim2.new(0,22,0,6)
TLbl.BackgroundTransparency=1; TLbl.Text="CHINA HUB FREE"
TLbl.TextColor3=C.text; TLbl.TextSize=14; TLbl.Font=Enum.Font.GothamBold
TLbl.TextXAlignment=Enum.TextXAlignment.Left

local SLbl = Instance.new("TextLabel",Top)
SLbl.Size=UDim2.new(1,-120,0,13); SLbl.Position=UDim2.new(0,22,0,30)
SLbl.BackgroundTransparency=1; SLbl.Text="King Legacy  v7.0  |  Update 11"
SLbl.TextColor3=C.acc2; SLbl.TextSize=10; SLbl.Font=Enum.Font.Gotham
SLbl.TextXAlignment=Enum.TextXAlignment.Left

local function WBtn(lbl,col,off)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,off,0.5,-11)
    b.BackgroundColor3=col; b.Text=lbl; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,5); return b
end
local CBtn = WBtn("X", C.red,   -8)
local MBtn = WBtn("_", Color3.fromRGB(50,100,180), -36)

local drag, dI, dS, dP
Top.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; dS=i.Position; dP=WIN.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
Top.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dI=i end end)
UserInputService.InputChanged:Connect(function(i)
    if i==dI and drag then
        local d=i.Position-dS
        WIN.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y)
    end
end)
CBtn.MouseButton1Click:Connect(function()
    Farm.Active=false; BossConfig.Active=false; DungeonConfig.Active=false
    SeaEvent.Active=false; AutoStats.Active=false; FruitNotifier.Active=false
    SetCollision(true); SetFly(false); SetHitbox(false,10); SG:Destroy()
end)
local mini = false
MBtn.MouseButton1Click:Connect(function()
    mini=not mini
    for _,c in ipairs(WIN:GetChildren()) do if c~=Top then c.Visible=not mini end end
    WIN.Size=mini and UDim2.new(0,700,0,46) or UDim2.new(0,700,0,540)
    MBtn.Text=mini and "+" or "_"
end)

-- layout
local Layout = Instance.new("Frame",WIN)
Layout.Position=UDim2.new(0,0,0,46); Layout.Size=UDim2.new(1,0,1,-46)
Layout.BackgroundTransparency=1

-- sidebar (mais larga: 160px)
local SB = Instance.new("Frame",Layout)
SB.Size=UDim2.new(0,160,1,0); SB.BackgroundColor3=C.side; SB.BorderSizePixel=0
Lst(SB,Enum.FillDirection.Vertical,0); Pad(SB,0,0,8,8)

-- user card
local UC = Instance.new("Frame",SB)
UC.Size=UDim2.new(1,0,0,58); UC.BackgroundColor3=C.card; UC.BorderSizePixel=0; UC.LayoutOrder=0
local ucBar = Instance.new("Frame",UC); ucBar.Size=UDim2.new(0,3,0.6,0); ucBar.Position=UDim2.new(0,0,0.2,0); ucBar.BackgroundColor3=C.acc; ucBar.BorderSizePixel=0
local ucN = Instance.new("TextLabel",UC); ucN.Size=UDim2.new(1,-12,0,20); ucN.Position=UDim2.new(0,10,0,8); ucN.BackgroundTransparency=1; ucN.Text=LP.DisplayName; ucN.TextColor3=C.text; ucN.TextSize=12; ucN.Font=Enum.Font.GothamBold; ucN.TextXAlignment=Enum.TextXAlignment.Left
local ucLv = Instance.new("TextLabel",UC); ucLv.Size=UDim2.new(1,-12,0,14); ucLv.Position=UDim2.new(0,10,0,32); ucLv.BackgroundTransparency=1; ucLv.TextColor3=C.acc2; ucLv.TextSize=10; ucLv.Font=Enum.Font.Gotham; ucLv.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function() while SG.Parent do task.wait(2); ucLv.Text="Lv "..GetLevel().." | "..math.floor(GetBeli()/1000).."K Beli" end end)

local sdiv = Instance.new("Frame",SB); sdiv.Size=UDim2.new(1,0,0,1); sdiv.BackgroundColor3=C.sep; sdiv.BorderSizePixel=0; sdiv.LayoutOrder=1

-- conteúdo
local Con = Instance.new("Frame",Layout)
Con.Position=UDim2.new(0,160,0,0); Con.Size=UDim2.new(1,-160,1,0)
Con.BackgroundColor3=C.panel; Con.BorderSizePixel=0

local CS = Instance.new("ScrollingFrame",Con)
CS.Size=UDim2.new(1,0,1,0); CS.BackgroundTransparency=1
CS.ScrollBarThickness=3; CS.ScrollBarImageColor3=C.acc
CS.CanvasSize=UDim2.new(0,0,0,0); CS.AutomaticCanvasSize=Enum.AutomaticSize.Y
Pad(CS,12,12,10,10); Lst(CS,Enum.FillDirection.Vertical,8)

local Pages, TabBtns = {}, {}
local function MkPage(id)
    local pg=Instance.new("Frame",CS)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false
    Lst(pg,Enum.FillDirection.Vertical,6); Pages[id]=pg; return pg
end
local function Switch(id)
    for k,pg in pairs(Pages) do pg.Visible=false
        if TabBtns[k] then TabBtns[k].BackgroundTransparency=1
            local l=TabBtns[k]:FindFirstChildOfClass("TextLabel"); if l then l.TextColor3=C.dim end
            local d=TabBtns[k]:FindFirstChild("AD"); if d then d.Visible=false end
        end
    end
    if Pages[id] then Pages[id].Visible=true end
    if TabBtns[id] then TabBtns[id].BackgroundColor3=C.cardH; TabBtns[id].BackgroundTransparency=0
        local l=TabBtns[id]:FindFirstChildOfClass("TextLabel"); if l then l.TextColor3=C.text end
        local d=TabBtns[id]:FindFirstChild("AD"); if d then d.Visible=true end
    end
    CS.CanvasPosition=Vector2.new(0,0)
end

local Tabs = {"FARM","BOSS","DUNGEON","SEA EVENT","FRUTAS","ESP","TELEPORT","MISC","WEBHOOK"}
for i, name in ipairs(Tabs) do
    MkPage(name)
    local btn = Instance.new("TextButton",SB)
    btn.Name=name; btn.Size=UDim2.new(1,0,0,34)
    btn.BackgroundTransparency=1; btn.Text=""; btn.LayoutOrder=i+2
    local ad=Instance.new("Frame",btn); ad.Name="AD"
    ad.Size=UDim2.new(0,3,0.5,0); ad.Position=UDim2.new(0,0,0.25,0)
    ad.BackgroundColor3=C.acc; ad.BorderSizePixel=0; ad.Visible=false; Rnd(ad,2)
    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=C.dim
    lbl.TextSize=10; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    TabBtns[name]=btn
    btn.MouseButton1Click:Connect(function() Switch(name) end)
end

-- ============================================================
--  HELPERS UI
-- ============================================================
local function Sec(p,t)
    local row=Instance.new("Frame",p); row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1
    local line=Instance.new("Frame",row); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1); line.BackgroundColor3=C.sep; line.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,0,1,-2); lbl.BackgroundTransparency=1; lbl.Text=t; lbl.TextColor3=C.acc2; lbl.TextSize=10; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
end

local function Tog(p,t,def,cb)
    local row=Instance.new("Frame",p); row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=C.card; row.BorderSizePixel=0; Rnd(row,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=t; lbl.TextColor3=C.text; lbl.TextSize=11; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",row); pill.Size=UDim2.new(0,46,0,22); pill.Position=UDim2.new(1,-56,0.5,-11); pill.Text=""; pill.BorderSizePixel=0
    local st=def or false; pill.BackgroundColor3=st and C.green or Color3.fromRGB(38,38,58); Rnd(pill,11)
    local th=Instance.new("Frame",pill); th.Size=UDim2.new(0,16,0,16); th.Position=st and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8); th.BackgroundColor3=Color3.new(1,1,1); th.BorderSizePixel=0; Rnd(th,8)
    local function Set(v) st=v
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=v and C.green or Color3.fromRGB(38,38,58)}):Play()
        TweenService:Create(th,TweenInfo.new(0.15),{Position=v and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)}):Play()
        if cb then cb(v) end
    end
    pill.MouseButton1Click:Connect(function() Set(not st) end); return Set
end

local function Btn(p,t,cb,acc,colOverride)
    local b=Instance.new("TextButton",p); b.Size=UDim2.new(1,0,0,36)
    local bgCol = colOverride or (acc and C.acc or C.card)
    b.BackgroundColor3=bgCol; b.Text=t; b.TextColor3=C.text
    b.TextSize=11; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,6)
    if not acc and not colOverride then Str(b,C.bord,1) end
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=acc and C.acc2 or C.cardH}):Play()
        task.delay(0.14,function() if b and b.Parent then TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=bgCol}):Play() end end)
        if cb then cb() end
    end); return b
end

local function Inp(p,hint,cb)
    local b=Instance.new("TextBox",p); b.Size=UDim2.new(1,0,0,32); b.BackgroundColor3=C.card
    b.Text=""; b.PlaceholderText=hint; b.PlaceholderColor3=C.dim; b.TextColor3=C.text
    b.TextSize=11; b.Font=Enum.Font.Gotham; b.BorderSizePixel=0; b.ClearTextOnFocus=false
    Rnd(b,6); Str(b,C.bord,1); Pad(b,10,10,0,0)
    b.FocusLost:Connect(function() if cb then cb(b.Text) end end); return b
end

local function Lbl(p,t,col)
    local l=Instance.new("TextLabel",p); l.Size=UDim2.new(1,0,0,16); l.BackgroundTransparency=1
    l.Text=t; l.TextColor3=col or C.dim; l.TextSize=11; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
end

local function StatusBar(p)
    local sf=Instance.new("Frame",p); sf.Size=UDim2.new(1,0,0,42); sf.BackgroundColor3=Color3.fromRGB(10,20,14); sf.BorderSizePixel=0; Rnd(sf,8); Str(sf,Color3.fromRGB(28,78,44),1)
    local sd=Instance.new("Frame",sf); sd.Size=UDim2.new(0,8,0,8); sd.Position=UDim2.new(0,12,0.5,-4); sd.BackgroundColor3=C.red; sd.BorderSizePixel=0; Rnd(sd,4)
    local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,-30,1,0); sl.Position=UDim2.new(0,26,0,0); sl.BackgroundTransparency=1; sl.Text="Inativo"; sl.TextColor3=C.green; sl.TextSize=10; sl.Font=Enum.Font.GothamBold; sl.TextXAlignment=Enum.TextXAlignment.Left
    return sd, sl
end

local function StyleRow(p, def, cb)
    local sRow=Instance.new("Frame",p); sRow.Size=UDim2.new(1,0,0,36); sRow.BackgroundTransparency=1
    Lst(sRow,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Left)
    local sBtns={}
    local stList={{"melee","MELEE"},{"sword","SWORD"},{"fruit","FRUIT"}}
    local function SetSt(key)
        if cb then cb(key) end
        for _,sb in ipairs(sBtns) do local a=sb[1]==key
            TweenService:Create(sb[2],TweenInfo.new(0.14),{BackgroundColor3=a and C.acc or C.card}):Play()
            sb[3].TextColor3=a and Color3.new(1,1,1) or C.dim; sb[3].Font=a and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    for _,st in ipairs(stList) do
        local b=Instance.new("TextButton",sRow); b.Size=UDim2.new(0,100,1,0); b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(st[1]==def) and C.acc or C.card; Rnd(b,6)
        if st[1]~=def then Str(b,C.bord,1) end
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=st[2]; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(st[1]==def) and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(st[1]==def) and Color3.new(1,1,1) or C.dim
        table.insert(sBtns,{st[1],b,l}); b.MouseButton1Click:Connect(function() SetSt(st[1]) end)
    end
end

-- ============================================================
--  FARM PAGE
-- ============================================================
do
    local pg = Pages["FARM"]
    local sd, sl = StatusBar(pg)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=Farm.Active and Farm.StatusText or "Inativo"
        sd.BackgroundColor3=Farm.Active and C.green or C.red
    end end)

    Sec(pg, "AUTO FARM")
    Tog(pg,"Auto Farm (Quest + Mob-Lock Aéreo)",false,function(v)
        Farm.Active=v; if not v then Farm.State="idle"; SetCollision(true) end
    end)
    Tog(pg,"Aceitar Quest automaticamente",true,function(v) Farm.UseQuest=v end)
    Tog(pg,"Kill Aura (ataca mobs próximos)",false,function(v) Farm.KillAura=v end)

    Sec(pg,"ESTILO DE LUTA")
    StyleRow(pg,"melee",function(k) Farm.Style=k end)

    Sec(pg,"CONFIGURAÇÃO")
    Lbl(pg,"  Altura hover (studs):"); local hI=Inp(pg,"5",function(v) local n=tonumber(v); if n and n>0 then Farm.HoverY=n end end); hI.Text="5"
    Lbl(pg,"  Kill Aura range (studs):"); local kAI=Inp(pg,"200",function(v) local n=tonumber(v); if n then Farm.KillAuraRange=n end end); kAI.Text="200"
    Lbl(pg,"  Mobs por ciclo:"); local kI=Inp(pg,"10",function(v) local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end end); kI.Text="10"

    Sec(pg,"CALIBRAR ZONAS")
    Lbl(pg,"  Vá até o ponto no jogo e clique calibrar.")
    local selIdx=1
    local selL=Instance.new("TextLabel",pg); selL.Size=UDim2.new(1,0,0,30); selL.BackgroundColor3=C.card; selL.BorderSizePixel=0; Rnd(selL,6); Pad(selL,10,0,0,0)
    selL.Text=Zones[1].name.."  Lv "..Zones[1].minLv.."-"..Zones[1].maxLv
    selL.TextColor3=C.acc2; selL.TextSize=11; selL.Font=Enum.Font.GothamBold; selL.TextXAlignment=Enum.TextXAlignment.Left
    local aRow=Instance.new("Frame",pg); aRow.Size=UDim2.new(1,0,0,32); aRow.BackgroundTransparency=1; Lst(aRow,Enum.FillDirection.Horizontal,6)
    local function ABtn(t,cb2) local b=Instance.new("TextButton",aRow); b.Size=UDim2.new(0.5,-3,1,0); b.BackgroundColor3=C.card; b.Text=t; b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,6); Str(b,C.bord,1); b.MouseButton1Click:Connect(cb2) end
    ABtn("< ANTERIOR",function() selIdx=math.max(1,selIdx-1); local z=Zones[selIdx]; selL.Text=z.name.."  Lv "..z.minLv.."-"..z.maxLv end)
    ABtn("PRÓXIMA >",function() selIdx=math.min(#Zones,selIdx+1); local z=Zones[selIdx]; selL.Text=z.name.."  Lv "..z.minLv.."-"..z.maxLv end)
    Btn(pg,"CALIBRAR POSIÇÃO NPC QUEST",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        sl.Text=("OK islePos [%s] = %.0f,%.0f,%.0f"):format(Zones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Btn(pg,"CALIBRAR POSIÇÃO DOS MOBS",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].mobPos=pos; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        sl.Text=("OK mobPos [%s] = %.0f,%.0f,%.0f"):format(Zones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Btn(pg,"COPIAR POSIÇÃO ATUAL",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position; local s=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(s) end); sl.Text="Copiado: "..s
        end
    end)
    Sec(pg,"ZONAS (ilhas Upd10/11 = calibrar)")
    for _,z in ipairs(Zones) do
        Lbl(pg,("  Lv %4d-%-4d  %s%s"):format(z.minLv,z.maxLv,z.name,z.calibrate and "  ⚠ CALIBRAR" or ""),
            z.calibrate and Color3.fromRGB(255,180,50) or C.dim)
    end
end

-- ============================================================
--  BOSS PAGE
-- ============================================================
do
    local pg = Pages["BOSS"]
    local sd, sl = StatusBar(pg)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=BossConfig.Active and BossConfig.StatusText or "Inativo"
        sd.BackgroundColor3=BossConfig.Active and C.green or C.red
    end end)

    Sec(pg,"AUTO BOSS  —  Update 11")
    Lbl(pg,"  Death King (Halloween), Kaido, Big Mom,", Color3.fromRGB(255,120,50))
    Lbl(pg,"  Sea King, Hydra, Ghost Ship, Pteranodon")

    Tog(pg,"Auto Boss (hover + ataque aéreo)",false,function(v)
        BossConfig.Active=v
    end)

    Sec(pg,"SELECIONAR BOSS")
    for _, b in ipairs(BossList) do
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,36)
        row.BackgroundColor3=C.card; row.BorderSizePixel=0; Rnd(row,6)
        if b.name=="Death King" then Str(row,Color3.fromRGB(100,30,30),1.5) end
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=b.name.."  —  "..b.notes; lbl.TextColor3=b.name=="Death King" and C.gold or C.text; lbl.TextSize=10; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local sel=Instance.new("TextButton",row); sel.Size=UDim2.new(0,42,0,24); sel.Position=UDim2.new(1,-50,0.5,-12); sel.Text="SEL"; sel.BackgroundColor3=BossConfig.SelectedBoss==b.name and C.acc or C.card; sel.TextColor3=C.text; sel.TextSize=10; sel.Font=Enum.Font.GothamBold; sel.BorderSizePixel=0; Rnd(sel,5)
        sel.MouseButton1Click:Connect(function()
            BossConfig.SelectedBoss=b.name
            -- reset all
            for _, r in ipairs(pg:GetDescendants()) do
                if r:IsA("TextButton") and r.Text=="SEL" then
                    r.BackgroundColor3=C.card
                end
            end
            sel.BackgroundColor3=C.acc
            sl.Text="Boss selecionado: "..b.name
        end)
    end

    Sec(pg,"CONFIGURAÇÃO")
    StyleRow(pg,"melee",function(k) BossConfig.Style=k end)
    Lbl(pg,"  Altura hover:"); Inp(pg,"5",function(v) local n=tonumber(v); if n then BossConfig.HoverY=n end end).Text="5"
end

-- ============================================================
--  DUNGEON PAGE
-- ============================================================
do
    local pg = Pages["DUNGEON"]
    local sd, sl = StatusBar(pg)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=DungeonConfig.Active and DungeonConfig.StatusText or "Inativo"
        sd.BackgroundColor3=DungeonConfig.Active and C.green or C.red
    end end)

    Sec(pg,"AUTO DUNGEON  —  Todos os Mares")
    Lbl(pg,"  Cada mar tem dungeon numa ilha específica.", Color3.fromRGB(180,180,220))
    Lbl(pg,"  Calibre a posição de cada dungeon abaixo.")

    Tog(pg,"Auto Dungeon (kill loop)",false,function(v) DungeonConfig.Active=v end)

    Sec(pg,"POSIÇÕES DAS DUNGEONS (calibrar)")
    local duns = {
        {lab="1° Mar (calibrar pos):",   key="Pos1"},
        {lab="2° Mar (calibrar pos):",   key="Pos2"},
        {lab="3° Mar (calibrar pos):",   key="Pos3"},
    }
    for _, d in ipairs(duns) do
        Lbl(pg,"  "..d.lab)
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,32); row.BackgroundTransparency=1; Lst(row,Enum.FillDirection.Horizontal,6)
        local posL=Instance.new("TextLabel",row); posL.Size=UDim2.new(0.6,0,1,0); posL.BackgroundColor3=C.card; posL.Text="Não calibrado"; posL.TextColor3=C.dim; posL.TextSize=10; posL.Font=Enum.Font.Gotham; posL.TextXAlignment=Enum.TextXAlignment.Center; posL.BorderSizePixel=0; Rnd(posL,6)
        local calBtn=Instance.new("TextButton",row); calBtn.Size=UDim2.new(0.4,-6,1,0); calBtn.BackgroundColor3=C.acc; calBtn.Text="CALIBRAR"; calBtn.TextColor3=C.text; calBtn.TextSize=10; calBtn.Font=Enum.Font.GothamBold; calBtn.BorderSizePixel=0; Rnd(calBtn,6)
        local dk = d.key
        calBtn.MouseButton1Click:Connect(function()
            local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
            local pos=c.HumanoidRootPart.Position; DungeonConfig[dk]=pos
            posL.Text=("%.0f, %.0f, %.0f"):format(pos.X,pos.Y,pos.Z); posL.TextColor3=C.green
        end)
    end

    Sec(pg,"CONFIGURAÇÃO")
    StyleRow(pg,"melee",function(k) DungeonConfig.Style=k end)
    Lbl(pg,"  Altura hover:"); Inp(pg,"5",function(v) local n=tonumber(v); if n then DungeonConfig.HoverY=n end end).Text="5"
end

-- ============================================================
--  SEA EVENT PAGE
-- ============================================================
do
    local pg = Pages["SEA EVENT"]
    local sd, sl = StatusBar(pg)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=SeaEvent.Active and SeaEvent.StatusText or "Inativo"
        sd.BackgroundColor3=SeaEvent.Active and C.green or C.red
    end end)

    Sec(pg,"SEA EVENTS  —  Scan Automático")
    Lbl(pg,"  Sea Beast, Ghost Ship, Pteranodon Boss", Color3.fromRGB(80,180,255))

    Tog(pg,"Ativar Sea Event Auto",false,function(v) SeaEvent.Active=v end)
    Tog(pg,"Sea Beast",true, function(v) SeaEvent.SeaBeast=v end)
    Tog(pg,"Ghost Ship",false,function(v) SeaEvent.GhostShip=v end)

    Sec(pg,"CONFIGURAÇÃO")
    StyleRow(pg,"melee",function(k) SeaEvent.Style=k end)
    Lbl(pg,"  Altura hover:"); Inp(pg,"8",function(v) local n=tonumber(v); if n then SeaEvent.HoverY=n end end).Text="8"

    Sec(pg,"SERVER HOP MANUAL")
    Lbl(pg,"  Pula para servidor aleatório do mesmo jogo.")
    Btn(pg,"SERVER HOP AGORA",function() ServerHop() end, true)
end

-- ============================================================
--  FRUTAS PAGE (Notifier + Collect)
-- ============================================================
do
    local pg = Pages["FRUTAS"]

    -- status notifier
    local sf=Instance.new("Frame",pg); sf.Size=UDim2.new(1,0,0,42); sf.BackgroundColor3=Color3.fromRGB(14,12,8); sf.BorderSizePixel=0; Rnd(sf,8); Str(sf,Color3.fromRGB(80,70,20),1)
    local sd=Instance.new("Frame",sf); sd.Size=UDim2.new(0,8,0,8); sd.Position=UDim2.new(0,12,0.5,-4); sd.BackgroundColor3=C.red; sd.BorderSizePixel=0; Rnd(sd,4)
    local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,-30,1,0); sl.Position=UDim2.new(0,26,0,0); sl.BackgroundTransparency=1; sl.Text="Notifier Inativo"; sl.TextColor3=C.gold; sl.TextSize=10; sl.Font=Enum.Font.GothamBold; sl.TextXAlignment=Enum.TextXAlignment.Left
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=FruitNotifier.Active and FruitNotifier.StatusText or "Notifier Inativo"
        sd.BackgroundColor3=FruitNotifier.Active and C.gold or C.red
    end end)

    Sec(pg,"FRUIT NOTIFIER  —  Lendárias & Míticas")
    Lbl(pg,"  Detecta frutas no mapa e notifica o Discord.", Color3.fromRGB(255,215,80))
    Tog(pg,"Ativar Fruit Notifier",false,function(v) FruitNotifier.Active=v end)
    Tog(pg,"Notificar TODAS as frutas (não só leg.)",false,function(v) FruitNotifier.NotifyAll=v end)
    Tog(pg,"Auto Coletar ao detectar",false,function(v) FruitNotifier.AutoCollect=v end)

    Sec(pg,"SERVER HOP AUTOMÁTICO")
    Lbl(pg,"  Pula servidores até achar lendária, então para.")
    Tog(pg,"Server Hop (procurar lendária)",false,function(v) FruitNotifier.ServerHopOnFind=v end)

    Sec(pg,"WEBHOOK DISCORD (URL)")
    Lbl(pg,"  Cole o URL do webhook do seu servidor.")
    Inp(pg,"https://discord.com/api/webhooks/...",function(v) FruitNotifier.WebhookUrl=v end)

    Sec(pg,"FRUTAS LENDÁRIAS (mapa atual)")
    Lbl(pg,"  Scan manual do servidor atual.")
    Btn(pg,"ESCANEAR FRUTAS AGORA",function()
        local fruits = ScanFruits()
        local legCount = 0
        sl.Text = ("Scan: %d frutas | "):format(#fruits)
        for _, f in ipairs(fruits) do
            if f.legendary then
                legCount = legCount + 1
                sl.Text = sl.Text .. f.name .. " (" .. (f.rarity or "Leg") .. ")  "
            end
        end
        if legCount == 0 then sl.Text = "Scan: " .. #fruits .. " frutas | Nenhuma lendária aqui." end
    end)
    Btn(pg,"IR PARA LENDÁRIA MAIS PRÓXIMA",function()
        local ok, fr = TP_NearestLegendary()
        if ok then sl.Text = "TP para: " .. fr.name
        else sl.Text = "Sem lendária no servidor." end
    end)
    Btn(pg,"IR PARA QUALQUER FRUTA",TP_NearestFruit)

    Sec(pg,"FRUTAS LENDÁRIAS CONHECIDAS (Upd11)")
    local fruitInfo = {
        "Pteranodon  (Mítica)","Erebus/Loki  (Lendária, nova Upd11)",
        "Dragon  (Lendária)","Toy  (Lendária)","Phoenix  (Lendária)",
        "Tree  (Lendária, Upd10)","Demon  (Lendária, Upd10)","Gold  (Lendária)",
        "Dough  (Lendária)","Leopard  (Lendária)","Portal  (Lendária)",
    }
    for _, fi in ipairs(fruitInfo) do Lbl(pg,"  🍎 "..fi, C.gold) end
end

-- ============================================================
--  ESP PAGE
-- ============================================================
do
    local pg = Pages["ESP"]
    Sec(pg,"JOGADORES")
    Tog(pg,"Player ESP (box + HP + dist)",false,function(v) Cfg.PlayerESP=v end)
    Tog(pg,"Mostrar Distância",true, function(v) Cfg.ShowDist=v end)
    Tog(pg,"Tracer Lines", false,function(v) Cfg.TracerLines=v end)
    Sec(pg,"FRUTAS")
    Tog(pg,"Fruit ESP (todas)",      false,function(v) Cfg.FruitESP=v end)
    Sec(pg,"BOSSES")
    Tog(pg,"Boss ESP (nome + dist)", false,function(v) Cfg.BossESP=v end)
    Sec(pg,"RANGE")
    Lbl(pg,"  Distância máxima (studs):")
    Inp(pg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end).Text="2000"
end

-- ============================================================
--  TELEPORT PAGE
-- ============================================================
do
    local pg = Pages["TELEPORT"]
    Sec(pg,"FRUTAS")
    Btn(pg,"Ir para Fruta Mais Próxima",    TP_NearestFruit, true)
    Btn(pg,"Ir para Lendária Mais Próxima", function() TP_NearestLegendary() end, false,
        Color3.fromRGB(80,55,15))

    Sec(pg,"JOGADORES")
    Lbl(pg,"  Nome do jogador:"); local pI=Inp(pg,"username...")
    Btn(pg,"Ir para Jogador",function() TP_Player(pI.Text) end)
    Btn(pg,"Listar Online",function()
        local n={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end; pI.Text=table.concat(n,", ")
    end)

    Sec(pg,"COORDENADAS")
    Lbl(pg,"  X, Y, Z separados por vírgula:"); local cI=Inp(pg,"0, 100, 0")
    Btn(pg,"Ir para Coordenadas",function()
        local t=string.split(cI.Text,","); local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Btn(pg,"Copiar Posição Atual",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position; local s=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(s) end); cI.Text=s
        end
    end)

    Sec(pg,"ILHAS — 1° Mar")
    local isles1 = {
        {"Starter Island",   Vector3.new(-2044,100,-4591)},
        {"Pirate Island",    Vector3.new(-681,64,-3449)},
        {"Soldier Island",   Vector3.new(990,28,-510)},
        {"Shark Island",     Vector3.new(1822,28,1492)},
        {"Chef Ship",        Vector3.new(-792,28,1242)},
        {"Snow Island",      Vector3.new(1622,28,-872)},
        {"Sand Kingdom",     Vector3.new(-3052,28,1978)},
        {"Sky Island",       Vector3.new(-2822,865,-1632)},
        {"Bubble Island",    Vector3.new(2552,28,-2058)},
    }
    for _,il in ipairs(isles1) do
        Btn(pg,il[1],function() SafeTP(il[2]) end)
    end
    Sec(pg,"ILHAS — 2°/3° Mar (calibrar)")
    Lbl(pg,"  Use Calibrar na aba Farm para 2°/3° Mar.")
end

-- ============================================================
--  MISC PAGE
-- ============================================================
do
    local pg = Pages["MISC"]

    Sec(pg,"AUTO STATS  —  Distribui pontos")
    Tog(pg,"Auto Stats Ativo",false,function(v) AutoStats.Active=v end)
    local statDist = {
        {lab="Fruit % (padrão=100):", key="Fruit"},
        {lab="STR %:",                 key="Str"},
        {lab="DEF %:",                 key="Def"},
        {lab="AGI %:",                 key="Agi"},
        {lab="HEALTH %:",              key="Health"},
    }
    for _, s in ipairs(statDist) do
        Lbl(pg,"  "..s.lab)
        local k=s.key; local def=tostring(AutoStats[k])
        Inp(pg,def,function(v) local n=tonumber(v); if n and n>=0 then AutoStats[k]=n end end).Text=def
    end

    Sec(pg,"AUTO HAKI")
    Tog(pg,"Buso Haki (pressiona Q)",false,function(v) AutoHaki.Buso=v end)
    Tog(pg,"Ken Haki (pressiona E)", false,function(v) AutoHaki.Ken=v end)

    Sec(pg,"MOVIMENTO")
    Tog(pg,"No Clip",false,function(v)
        local c=LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=not v end end end
    end)
    Tog(pg,"Infinite Jump",false,function(v)
        getgenv()._infJ=v
        if v and not getgenv()._infJC then
            getgenv()._infJC=UserInputService.JumpRequest:Connect(function()
                if getgenv()._infJ then
                    local c=LP.Character
                    if c and c:FindFirstChild("Humanoid") then c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        elseif not v and getgenv()._infJC then getgenv()._infJC:Disconnect(); getgenv()._infJC=nil end
    end)
    Tog(pg,"Fly Mode (WASD + Espaço/Shift)",false,function(v)
        SetFly(v, flySpeed); if not v then SetCollision(true) end
    end)
    local flySpeed = 80
    Lbl(pg,"  Fly Speed:"); Inp(pg,"80",function(v) local n=tonumber(v); if n then flySpeed=n end end).Text="80"

    Sec(pg,"VELOCIDADE E PULO")
    Lbl(pg,"  Walk Speed (padrão 16):"); Inp(pg,"16",function(v) local n=tonumber(v); local c=LP.Character; if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end end)
    Lbl(pg,"  Jump Power (padrão 50):"); Inp(pg,"50",function(v) local n=tonumber(v); local c=LP.Character; if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end end)

    Sec(pg,"HITBOX EXPAND")
    Tog(pg,"Hitbox Expand (inimigos maiores)",false,function(v) SetHitbox(v, hitboxSize) end)
    local hitboxSize = 15
    Lbl(pg,"  Tamanho do hitbox:"); Inp(pg,"15",function(v) local n=tonumber(v); if n then hitboxSize=n; if HitboxCon then SetHitbox(true,n) end end end).Text="15"

    Sec(pg,"UTILITÁRIOS")
    Btn(pg,"Restaurar Colisão",     function() SetCollision(true) end)
    Btn(pg,"Recarregar Personagem", function() SetCollision(true); LP:LoadCharacter() end)
    Btn(pg,"Parar Tudo",function()
        Farm.Active=false; BossConfig.Active=false; DungeonConfig.Active=false
        SeaEvent.Active=false; AutoStats.Active=false; FruitNotifier.Active=false
        SetFly(false); SetHitbox(false,10); SetCollision(true)
    end, true)
end

-- ============================================================
--  WEBHOOK PAGE
-- ============================================================
do
    local pg = Pages["WEBHOOK"]
    local function WH(title, desc, color)
        SendWebhook(Cfg.WHUrl, title, desc, color)
    end
    Sec(pg,"URL DO WEBHOOK DISCORD")
    Lbl(pg,"  Cole o URL do seu webhook:")
    local wuI=Inp(pg,"https://discord.com/api/webhooks/...",function(v) Cfg.WHUrl=v end)

    Sec(pg,"NOTIFICAÇÕES AUTOMÁTICAS")
    Lbl(pg,"  (também configurável na aba FRUTAS)")
    Tog(pg,"Notificar frutas lendárias (via Fruit Notifier)",false,function(v) FruitNotifier.Active=v; FruitNotifier.WebhookUrl=Cfg.WHUrl end)

    Sec(pg,"ENVIO MANUAL")
    Lbl(pg,"  Título:"); local wt=Inp(pg,"Título...")
    Lbl(pg,"  Mensagem:"); local wm=Inp(pg,"Mensagem...")
    Btn(pg,"Enviar",function() WH(wt.Text, wm.Text, 3447003) end, true)
    Btn(pg,"Testar Conexão",function()
        WH("✅ Conexão OK","China Hub v7.0 conectado — **"..LP.Name.."** | Lv "..GetLevel(), 65280)
    end)

    Sec(pg,"INFO DO SERVIDOR ATUAL")
    Lbl(pg,"  Job ID do servidor:")
    local jbl=Instance.new("TextLabel",pg); jbl.Size=UDim2.new(1,0,0,30); jbl.BackgroundColor3=C.card; jbl.Text=tostring(game.JobId); jbl.TextColor3=C.acc2; jbl.TextSize=10; jbl.Font=Enum.Font.Gotham; jbl.TextXAlignment=Enum.TextXAlignment.Center; jbl.BorderSizePixel=0; Rnd(jbl,6)
    Btn(pg,"Copiar JobId",function()
        pcall(function() setclipboard(tostring(game.JobId)) end)
        jbl.Text="Copiado! "..tostring(game.JobId)
    end)
    Btn(pg,"Enviar Info do Servidor",function()
        WH("🌐 Servidor King Legacy",
            ("Servidor: `%s`\nPlaceId: `%s`\nJogador: **%s**  Lv %d\nLink: %s"):format(
                tostring(game.JobId), tostring(game.PlaceId),
                LP.Name, GetLevel(), GetServerLink()),
            10066329)
    end)
end

-- ============================================================
--  ESP UPDATE
-- ============================================================
local PLR_ESP = {}
local function MkESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={
        box=NBox(Cfg.Col_P), name=NTxt(Cfg.Col_P,13), dist=NTxt(Color3.new(1,1,1),11),
        hpBg=NBox(Color3.fromRGB(38,38,38),true), hpBar=NBox(Color3.fromRGB(55,205,100),true),
        tracer=NLine(Cfg.Col_P)
    }
end
local function KillESP(pl)
    if PLR_ESP[pl] then for _,o in pairs(PLR_ESP[pl]) do pcall(function() o:Remove() end) end; PLR_ESP[pl]=nil end
end

local FPool    = {}
local BossPool = {}

local function ClearPool(pool)
    for _,o in pairs(pool) do
        if o.lbl then pcall(function() o.lbl:Remove() end) end
        if o.d   then pcall(function() o.d:Remove()   end) end
    end; table.clear(pool)
end

local function UpdP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LP then continue end
        if not PLR_ESP[pl] then MkESP(pl) end
        local obj=PLR_ESP[pl]; if not obj then continue end
        local char=pl.Character
        if not Cfg.PlayerESP or not char or not char:FindFirstChild("HumanoidRootPart") then
            for _,o in pairs(obj) do o.Visible=false end; continue
        end
        local hrp=char.HumanoidRootPart; local hum=char:FindFirstChildOfClass("Humanoid")
        local d=Dist(hrp.Position); if d>Cfg.ESPRange then for _,o in pairs(obj) do o.Visible=false end; continue end
        local t2D,_,tV=W2V(hrp.Position+Vector3.new(0,3.2,0)); local b2D,_,bV=W2V(hrp.Position-Vector3.new(0,2.8,0))
        if not tV and not bV then for _,o in pairs(obj) do o.Visible=false end; continue end
        local bH=math.abs(t2D.Y-b2D.Y); local bW=bH*0.55; local bX=t2D.X-bW/2
        obj.box.Size=Vector2.new(bW,bH); obj.box.Position=Vector2.new(bX,t2D.Y); obj.box.Color=Cfg.Col_P; obj.box.Visible=true
        obj.name.Text=pl.DisplayName; obj.name.Position=Vector2.new(t2D.X,t2D.Y-16); obj.name.Color=Cfg.Col_P; obj.name.Visible=true
        obj.dist.Text=d.."m"; obj.dist.Position=Vector2.new(t2D.X,t2D.Y-28); obj.dist.Visible=Cfg.ShowDist
        local hp=hum and math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) or 0
        obj.hpBg.Size=Vector2.new(4,bH); obj.hpBg.Position=Vector2.new(bX+bW+3,t2D.Y); obj.hpBg.Visible=true
        obj.hpBar.Size=Vector2.new(4,bH*hp); obj.hpBar.Position=Vector2.new(bX+bW+3,t2D.Y+bH*(1-hp)); obj.hpBar.Color=Color3.fromRGB(255*(1-hp),255*hp,0); obj.hpBar.Visible=true
        obj.tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); obj.tracer.To=b2D; obj.tracer.Color=Cfg.Col_P; obj.tracer.Visible=Cfg.TracerLines
    end
end

local function UpdF()
    ClearPool(FPool)
    if not Cfg.FruitESP then return end
    local fruits = ScanFruits()
    for _,f in ipairs(fruits) do
        local d=Dist(f.pos); if d>Cfg.ESPRange then continue end
        local p2D,_,onS=W2V(f.pos); if not onS then continue end
        local col = f.legendary and Cfg.Col_F_Leg or Cfg.Col_F_Common
        local l=NTxt(col,13); l.Text=(f.legendary and "★ " or "")..f.name; l.Position=Vector2.new(p2D.X,p2D.Y-10); l.Visible=true
        local dl=NTxt(Color3.new(1,1,1),11); dl.Text=d.."m"; dl.Position=Vector2.new(p2D.X,p2D.Y+5); dl.Visible=true
        table.insert(FPool,{lbl=l,d=dl})
    end
end

local function UpdBoss()
    ClearPool(BossPool)
    if not Cfg.BossESP then return end
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, b in ipairs(BossList) do
        local boss, _ = FindBoss(b.pattern, 8000)
        if boss then
            local hrp=boss:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local d=Dist(hrp.Position); if d>Cfg.ESPRange then continue end
            local p2D,_,onS=W2V(hrp.Position+Vector3.new(0,5,0)); if not onS then continue end
            local hum=boss:FindFirstChildOfClass("Humanoid")
            local l=NTxt(Cfg.Col_Boss,14); l.Text="⚔ "..b.name; l.Position=Vector2.new(p2D.X,p2D.Y-14); l.Visible=true
            local dl=NTxt(Color3.new(1,1,1),11); dl.Text=d.."m  HP "..(hum and math.floor(hum.Health) or "?"); dl.Position=Vector2.new(p2D.X,p2D.Y+2); dl.Visible=true
            table.insert(BossPool,{lbl=l,d=dl})
        end
    end
end

-- show/hide
local SBtn = Instance.new("TextButton",SG)
SBtn.Size=UDim2.new(0,150,0,32); SBtn.Position=UDim2.new(0,20,0,55)
SBtn.BackgroundColor3=C.side; SBtn.Text="CHINA HUB v7.0"; SBtn.TextColor3=C.acc2
SBtn.TextSize=10; SBtn.Font=Enum.Font.GothamBold; SBtn.BorderSizePixel=0; SBtn.Visible=false
Rnd(SBtn,8); Str(SBtn,C.acc,1.5)
local function TogVis()
    if WIN.Visible then WIN.Visible=false; SBtn.Visible=true
    else WIN.Visible=true; SBtn.Visible=false end
end
SBtn.MouseButton1Click:Connect(TogVis)
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==Cfg.HideKey then TogVis() end
end)

-- init
Switch("FARM")
for _,pl in ipairs(Players:GetPlayers()) do MkESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MkESP(pl) end)
Players.PlayerRemoving:Connect(KillESP)
LP.CharacterAdded:Connect(function()
    SetCollision(true); Farm.State="idle"; task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MkESP(pl) end
end)

local espT = 0
RunService.RenderStepped:Connect(function()
    espT = espT + 1; UpdP()
    if espT % 12 == 0 then UpdF(); UpdBoss(); espT=0 end
end)

print("[China Hub Free v7.0 | Update 11] carregado por " .. LP.Name)
