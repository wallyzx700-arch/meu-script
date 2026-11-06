-- ============================================================
--  China Hub Free — King Legacy Script v3.0
--  Auto Farm por Quest (NPC → missão → mobs → loop)
--  Auto M1 contínuo | ESP | Teleport | Webhook | Misc
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local VirtualUser      = game:GetService("VirtualUser")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Cfg = {
    PlayerESP   = false,
    FruitESP    = false,
    DungeonESP  = false,
    ShowDist    = true,
    ESPRange    = 2000,
    TracerLines = false,
    WHUrl       = "",
    Col_Player  = Color3.fromRGB(255, 60,  60),
    Col_Fruit   = Color3.fromRGB(60,  220, 60),
    Col_Dungeon = Color3.fromRGB(60,  140, 255),
    HideKey     = Enum.KeyCode.LeftControl,
}

-- ============================================================
--  FARM STATE
-- ============================================================
local Farm = {
    Active  = false,   -- Auto Farm Level (quest loop)
    Attack  = false,   -- Auto M1
    State   = "idle",  -- "idle" | "toquest" | "fighting" | "returning"
    Timer   = 0,
    Zone    = nil,
}

-- ============================================================
--  DRAWING
-- ============================================================
local function NewText(color, size)
    local t = Drawing.new("Text")
    t.Color = color or Color3.new(1,1,1); t.Size = size or 13
    t.Center = true; t.Outline = true; t.Visible = false; return t
end
local function NewBox(color, filled)
    local b = Drawing.new("Square")
    b.Color = color or Color3.new(1,1,1); b.Thickness = 1.5
    b.Filled = filled or false; b.Visible = false; return b
end
local function NewLine(color)
    local l = Drawing.new("Line")
    l.Color = color or Color3.new(1,1,1); l.Thickness = 1; l.Visible = false; return l
end
local function W2V(pos)
    local sp,depth,onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X,sp.Y), depth, onScreen
end
local function Dist(pos)
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return math.floor((char.HumanoidRootPart.Position-pos).Magnitude)
    end
    return 0
end

-- ============================================================
--  TELEPORT
-- ============================================================
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

-- ============================================================
--  SCAN FRUTAS / DUNGEONS
-- ============================================================
local FruitKW = {"fruit","devil","gumgum","bombomb","chop","smoke","flame","ice",
    "magnet","light","dark","quake","phoenix","dragon","rubb","sand","diamond",
    "paw","gravity","string","shadow","portal","control","venom","leopard",
    "blizzard","gas","surge","rumble","barrier","soul"}
local function IsFruit(obj)
    local n = obj.Name:lower()
    for _,k in ipairs(FruitKW) do if n:find(k) then return true end end
end
local function ScanFruits()
    local out={}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsFruit(obj) then
            local pos
            if obj:IsA("Model") and obj.PrimaryPart then pos=obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then pos=obj.Position end
            if pos then table.insert(out,{name=obj.Name,pos=pos}) end
        end
    end
    return out
end
local DungeonKW = {"dungeon","boss","raid","gate","chest","mob","enemy"}
local function IsDungeon(obj)
    local n = obj.Name:lower()
    for _,k in ipairs(DungeonKW) do if n:find(k) then return true end end
end

-- ============================================================
--  LEVEL DO PLAYER
-- ============================================================
local function GetLevel()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local lv = ls:FindFirstChild("Level") or ls:FindFirstChild("Lv") or ls:FindFirstChild("level")
        if lv then return lv.Value end
    end
    -- fallback: procura em PlayerGui / outros
    for _,v in ipairs(LP:GetDescendants()) do
        if (v.Name=="Level" or v.Name=="Lv") and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    return 1
end

-- ============================================================
--  ZONAS DE QUEST POR LEVEL (King Legacy Sea 1)
--  questPos  = posição do NPC de quest
--  mobPos    = centro da área de mobs da missão
--  Nomes de NPC são buscados por ProximityPrompt perto do questPos
-- ============================================================
local QuestZones = {
    {
        name   = "Ilha Inicial",
        minLv  = 1,    maxLv = 14,
        questPos = Vector3.new(-195, 18, 155),
        mobPos   = Vector3.new(-260, 18, 220),
    },
    {
        name   = "Base Marinha",
        minLv  = 15,   maxLv = 34,
        questPos = Vector3.new(1005, 20, -540),
        mobPos   = Vector3.new( 940, 20, -480),
    },
    {
        name   = "Ilha Buggy",
        minLv  = 35,   maxLv = 59,
        questPos = Vector3.new(400, 20, -1010),
        mobPos   = Vector3.new(480, 20,  -930),
    },
    {
        name   = "Baratie",
        minLv  = 60,   maxLv = 89,
        questPos = Vector3.new(-760, 20, 1265),
        mobPos   = Vector3.new(-820, 20, 1200),
    },
    {
        name   = "Arlong Park",
        minLv  = 90,   maxLv = 124,
        questPos = Vector3.new(1840, 20, 1500),
        mobPos   = Vector3.new(1770, 20, 1430),
    },
    {
        name   = "Coliseu",
        minLv  = 125,  maxLv = 174,
        questPos = Vector3.new(1640, 20, -855),
        mobPos   = Vector3.new(1570, 20, -920),
    },
    {
        name   = "Thriller Bark",
        minLv  = 175,  maxLv = 224,
        questPos = Vector3.new(-3030, 22, 1960),
        mobPos   = Vector3.new(-3100, 22, 2020),
    },
    {
        name   = "Marineford",
        minLv  = 225,  maxLv = 274,
        questPos = Vector3.new(2560, 20, -2060),
        mobPos   = Vector3.new(2490, 20, -2130),
    },
    {
        name   = "Shanks Island",
        minLv  = 275,  maxLv = 324,
        questPos = Vector3.new(-1890, 20, -855),
        mobPos   = Vector3.new(-1950, 20, -790),
    },
    {
        name   = "Mihawk Island",
        minLv  = 325,  maxLv = 374,
        questPos = Vector3.new(-2490, 20, -310),
        mobPos   = Vector3.new(-2560, 20, -370),
    },
    {
        name   = "Skypiea",
        minLv  = 375,  maxLv = 450,
        questPos = Vector3.new(-2810, 858, -1635),
        mobPos   = Vector3.new(-2880, 858, -1700),
    },
    {
        name   = "Upper Yard",
        minLv  = 450,  maxLv = 999,
        questPos = Vector3.new(-3090, 872, -1915),
        mobPos   = Vector3.new(-3160, 872, -1980),
    },
}

local function GetZoneForLevel(lv)
    for _, z in ipairs(QuestZones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return QuestZones[#QuestZones]
end

-- ============================================================
--  PROXIMITY PROMPT — quest NPC
--  Busca qualquer ProximityPrompt de NPC perto da posição dada
-- ============================================================
local QuestKW = {"quest","missao","missão","task","talk","falar","aceitar","accept"}
local function FindQuestPrompt(nearPos, radius)
    radius = radius or 70
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local d = (part.Position - nearPos).Magnitude
                if d < radius and d < bestDist then
                    local at = (obj.ActionText or ""):lower()
                    local ot = (obj.ObjectText or ""):lower()
                    local nm = (part.Name or ""):lower()
                    local ok = false
                    for _,kw in ipairs(QuestKW) do
                        if at:find(kw) or ot:find(kw) or nm:find(kw) then ok=true break end
                    end
                    -- aceita qualquer prompt de NPC se não achar com keyword
                    if ok or nm:find("npc") or nm:find("vendor") or nm:find("man") or nm:find("woman") then
                        best = obj; bestDist = d
                    end
                end
            end
        end
    end
    return best
end

local function FirePrompt(prompt)
    if not prompt then return end
    pcall(function() fireproximityprompt(prompt) end)
end

-- ============================================================
--  MOB MAIS PRÓXIMO
-- ============================================================
local function NearestMob(nearPos)
    local origin = nearPos or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position)
    if not origin then return nil, math.huge end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LP.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local d = (origin - hrp.Position).Magnitude
                if d < bestDist then bestDist=d; best=obj end
            end
        end
    end
    return best, bestDist
end

-- ============================================================
--  AUTO M1 — loop independente, 0.18s
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not Farm.Attack then continue end
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local mob, dist = NearestMob()
        if not mob then continue end
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        -- TP colado no mob se longe
        if dist > 7 then
            char.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(3,2,0))
            task.wait(0.08)
        end
        -- M1 click
        local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
        if onScr then
            VirtualUser:ClickButton1(Vector2.new(sp.X, sp.Y), CFrame.new())
        end
    end
end)

-- ============================================================
--  AUTO FARM QUEST — máquina de estado
--  idle → toquest → fighting → idle
-- ============================================================
local QUEST_TIMEOUT = 90   -- segundos pra resetar se travar

task.spawn(function()
    while true do
        task.wait(0.2)
        if not Farm.Active then Farm.State="idle"; continue end

        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end

        local lv   = GetLevel()
        local zone = GetZoneForLevel(lv)

        -- ── STATE: idle → ir pegar quest ─────────────────────
        if Farm.State == "idle" then
            Farm.Zone  = zone
            Farm.State = "toquest"
            Farm.Timer = tick()

        -- ── STATE: toquest → TP + fire prompt ────────────────
        elseif Farm.State == "toquest" then
            TP(Farm.Zone.questPos)
            task.wait(1.2)

            -- tenta fire o prompt de quest
            local prompt = FindQuestPrompt(Farm.Zone.questPos, 70)
            if prompt then
                FirePrompt(prompt)
                task.wait(0.6)
                -- segundo fire (confirmar/aceitar)
                FirePrompt(prompt)
                task.wait(0.4)
            else
                -- sem prompt achado: vai direto pra mob area mesmo assim
            end

            Farm.State = "fighting"
            Farm.Timer = tick()
            -- TP para área de mobs
            TP(Farm.Zone.mobPos)
            task.wait(0.8)

        -- ── STATE: fighting → atacar mobs / aguardar quest ───
        elseif Farm.State == "fighting" then
            -- timeout → volta pegar quest
            if tick() - Farm.Timer > QUEST_TIMEOUT then
                Farm.State = "idle"
                continue
            end

            local mob, dist = NearestMob(Farm.Zone.mobPos)
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                -- se mob longe da mobPos → não é da zona, ignora
                if (hrp.Position - Farm.Zone.mobPos).Magnitude < 300 then
                    if dist > 7 then
                        char.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(3,2,0))
                        task.wait(0.1)
                    end
                else
                    -- sem mob na zona → volta pra mobPos e aguarda respawn
                    TP(Farm.Zone.mobPos)
                    task.wait(2)
                end
            else
                -- sem mob → aguarda respawn
                task.wait(1.5)
            end

            -- verifica se quest completa (procura prompt de entregar)
            local returnPrompt = FindQuestPrompt(Farm.Zone.questPos, 70)
            -- tenta entregar se flag de quest completa aparecer no prompt
            -- (King Legacy mostra prompt diferente quando missão pronta)
            if returnPrompt then
                local at = (returnPrompt.ActionText or ""):lower()
                if at:find("entreg") or at:find("complet") or at:find("return") or at:find("finish") then
                    TP(Farm.Zone.questPos)
                    task.wait(1)
                    FirePrompt(returnPrompt)
                    task.wait(0.5)
                    Farm.State = "idle"
                end
            end
        end
    end
end)

-- ============================================================
--  ESP POOLS
-- ============================================================
local PLR_ESP = {}
local function MakePlayerESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={
        box=NewBox(Cfg.Col_Player), name=NewText(Cfg.Col_Player,13),
        dist=NewText(Color3.new(1,1,1),11),
        hpBg=NewBox(Color3.fromRGB(40,40,40),true),
        hpBar=NewBox(Color3.fromRGB(50,220,50),true),
        tracer=NewLine(Cfg.Col_Player)}
end
local function KillPlayerESP(pl)
    if PLR_ESP[pl] then
        for _,o in pairs(PLR_ESP[pl]) do o:Remove() end
        PLR_ESP[pl]=nil
    end
end
local FruitPool,DungeonPool={},{}
local function ClearPool(pool)
    for _,obj in pairs(pool) do
        if obj.lbl  then obj.lbl:Remove() end
        if obj.dist then obj.dist:Remove() end
    end
    table.clear(pool)
end

-- ============================================================
--  ESP UPDATE
-- ============================================================
local function UpdatePlayerESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LP then continue end
        local obj=PLR_ESP[pl]
        if not obj then MakePlayerESP(pl); obj=PLR_ESP[pl] end
        if not obj then continue end
        local char=pl.Character
        if not Cfg.PlayerESP or not char
           or not char:FindFirstChild("HumanoidRootPart")
           or not char:FindFirstChild("Humanoid") then
            for _,o in pairs(obj) do o.Visible=false end; continue
        end
        local hrp=char.HumanoidRootPart; local hum=char.Humanoid
        local d=Dist(hrp.Position)
        if d>Cfg.ESPRange then for _,o in pairs(obj) do o.Visible=false end; continue end
        local top2D,_,topVis=W2V(hrp.Position+Vector3.new(0,3.2,0))
        local bot2D,_,botVis=W2V(hrp.Position-Vector3.new(0,2.8,0))
        if not topVis and not botVis then for _,o in pairs(obj) do o.Visible=false end; continue end
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
local function UpdateDungeonESP()
    ClearPool(DungeonPool); if not Cfg.DungeonESP then return end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
        if not IsDungeon(obj) then continue end
        local pos
        if obj:IsA("Model") and obj.PrimaryPart then pos=obj.PrimaryPart.Position
        elseif obj:IsA("BasePart") then pos=obj.Position end
        if not pos then continue end
        local d=Dist(pos); if d>Cfg.ESPRange then continue end
        local p2D,_,onScr=W2V(pos); if not onScr then continue end
        local lbl=NewText(Cfg.Col_Dungeon,13)
        lbl.Text="[D] "..obj.Name; lbl.Position=Vector2.new(p2D.X,p2D.Y-10); lbl.Visible=true
        local dlbl=NewText(Color3.new(1,1,1),11)
        dlbl.Text=d.."m"; dlbl.Position=Vector2.new(p2D.X,p2D.Y+6); dlbl.Visible=true
        table.insert(DungeonPool,{lbl=lbl,dist=dlbl})
    end
end

-- ============================================================
--  LOCALIZAÇÕES
-- ============================================================
local Locations = {
    ["🏝 Ilha Inicial"]         = Vector3.new( -210,  18,   180),
    ["⚓ Base Marinha"]          = Vector3.new(  980,  20,  -520),
    ["🏴 Ilha Buggy"]           = Vector3.new(  420,  20,  -980),
    ["🍊 Ilha da Nami"]         = Vector3.new( 1250,  20,   640),
    ["🐟 Ilha Arlong"]          = Vector3.new( 1820,  20,  1480),
    ["🍖 Baratie"]              = Vector3.new( -780,  20,  1250),
    ["⚔ Coliseu"]               = Vector3.new( 1620,  20,  -870),
    ["⛩ Ilha Shanks"]           = Vector3.new(-1900,  20,  -840),
    ["🏯 Ilha Mihawk"]          = Vector3.new(-2500,  20,  -300),
    ["🏰 Thriller Bark"]        = Vector3.new(-3050,  22,  1980),
    ["🌊 Reverse Mountain"]     = Vector3.new( 2200,  25, -2800),
    ["🔱 Marineford"]           = Vector3.new( 2550,  20, -2050),
    ["🔒 Impel Down"]           = Vector3.new( 2820,  20,  1760),
    ["🚪 Entrada Dungeon"]      = Vector3.new( 1180,  20, -1480),
    ["☁ Skypiea"]               = Vector3.new(-2820, 855, -1620),
    ["🌩 Upper Yard"]           = Vector3.new(-3100, 870, -1900),
    ["🏟 Sky Coliseu"]          = Vector3.new(-3200,1200, -1600),
    ["🌊 Portal 2º Mar"]        = Vector3.new( 2900,  20,   900),
}
local function TP_NearestFruit()
    local fruits=ScanFruits(); if #fruits==0 then return end
    local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    table.sort(fruits,function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

-- ============================================================
--  GUI
-- ============================================================
local old=CoreGui:FindFirstChild("CHINAHUB")
if old then old:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="CHINAHUB"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=CoreGui

-- ---- Botão flutuante — top-left ----
local ShowBtn=Instance.new("TextButton",SG)
ShowBtn.Size=UDim2.new(0,130,0,32); ShowBtn.Position=UDim2.new(0,22,0,55)
ShowBtn.BackgroundColor3=Color3.fromRGB(14,14,38)
ShowBtn.Text="⚔ China Hub Free"
ShowBtn.TextColor3=Color3.fromRGB(170,170,255)
ShowBtn.TextSize=11; ShowBtn.Font=Enum.Font.GothamBold
ShowBtn.BorderSizePixel=0; ShowBtn.Visible=false
Instance.new("UICorner",ShowBtn).CornerRadius=UDim.new(0,8)
local ss=Instance.new("UIStroke",ShowBtn)
ss.Color=Color3.fromRGB(70,70,170); ss.Thickness=1.5

-- ---- Frame principal ----
local MF=Instance.new("Frame",SG)
MF.Size=UDim2.new(0,460,0,520); MF.Position=UDim2.new(0.5,-230,0.5,-260)
MF.BackgroundColor3=Color3.fromRGB(12,12,18); MF.BorderSizePixel=0
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,8)
local MFStr=Instance.new("UIStroke",MF)
MFStr.Color=Color3.fromRGB(70,70,170); MFStr.Thickness=1.5

-- ---- Title bar ----
local TB=Instance.new("Frame",MF)
TB.Size=UDim2.new(1,0,0,36); TB.BackgroundColor3=Color3.fromRGB(20,20,45); TB.BorderSizePixel=0
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,8)
local TL=Instance.new("TextLabel",TB)
TL.Size=UDim2.new(1,-110,1,0); TL.Position=UDim2.new(0,12,0,0)
TL.BackgroundTransparency=1; TL.Text="⚔  China Hub Free"
TL.TextColor3=Color3.fromRGB(170,170,255); TL.TextSize=14
TL.Font=Enum.Font.GothamBold; TL.TextXAlignment=Enum.TextXAlignment.Left

local function MakeHBtn(label,color,xOff)
    local b=Instance.new("TextButton",TB)
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3=color; b.Text=label; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=13; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); return b
end
local CloseBtn=MakeHBtn("✕",Color3.fromRGB(180,40,40), -6)
local MinBtn  =MakeHBtn("−",Color3.fromRGB(50,100,180),-36)
local HideBtn =MakeHBtn("👁",Color3.fromRGB(60,60,120),-66)

-- ---- Tab bar ----
local TabBar=Instance.new("Frame",MF)
TabBar.Size=UDim2.new(1,0,0,32); TabBar.Position=UDim2.new(0,0,0,36)
TabBar.BackgroundColor3=Color3.fromRGB(18,18,32); TabBar.BorderSizePixel=0
local TBL=Instance.new("UIListLayout",TabBar)
TBL.FillDirection=Enum.FillDirection.Horizontal; TBL.Padding=UDim.new(0,3)
TBL.VerticalAlignment=Enum.VerticalAlignment.Center
Instance.new("UIPadding",TabBar).PaddingLeft=UDim.new(0,8)

-- ---- Content ----
local CH=Instance.new("Frame",MF)
CH.Size=UDim2.new(1,0,1,-68); CH.Position=UDim2.new(0,0,0,68); CH.BackgroundTransparency=1
local SF=Instance.new("ScrollingFrame",CH)
SF.Size=UDim2.new(1,0,1,0); SF.BackgroundTransparency=1
SF.ScrollBarThickness=4; SF.ScrollBarImageColor3=Color3.fromRGB(80,80,180)
SF.CanvasSize=UDim2.new(0,0,0,0); SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",SF).Padding=UDim.new(0,5)
local sfPad=Instance.new("UIPadding",SF)
sfPad.PaddingLeft=UDim.new(0,10); sfPad.PaddingRight=UDim.new(0,10); sfPad.PaddingTop=UDim.new(0,8)

-- ---- GUI helpers ----
local Pages,TabBtns={},{}
local function Tab(icon,label)
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,76,0,26); btn.BackgroundColor3=Color3.fromRGB(28,28,52)
    btn.Text=icon.." "..label; btn.TextColor3=Color3.fromRGB(140,140,200)
    btn.TextSize=10; btn.Font=Enum.Font.GothamBold; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local pg=Instance.new("Frame",SF)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false
    Instance.new("UIListLayout",pg).Padding=UDim.new(0,5)
    Pages[label]=pg; TabBtns[label]=btn
    btn.MouseButton1Click:Connect(function()
        for k,p in pairs(Pages) do
            p.Visible=false
            TabBtns[k].BackgroundColor3=Color3.fromRGB(28,28,52)
            TabBtns[k].TextColor3=Color3.fromRGB(140,140,200)
        end
        pg.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(55,55,145)
        btn.TextColor3=Color3.fromRGB(220,220,255)
        SF.CanvasPosition=Vector2.new(0,0)
    end)
    return pg
end
local function Section(parent,text)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundColor3=Color3.fromRGB(28,28,58); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,8,0,0); l.BackgroundTransparency=1
    l.Text="▸ "..text; l.TextColor3=Color3.fromRGB(130,130,220); l.TextSize=11
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
end
local function Toggle(parent,text,default,cb)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Color3.fromRGB(20,20,32); row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.TextColor3=Color3.fromRGB(195,195,195); lbl.TextSize=12
    lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,42,0,20); btn.Position=UDim2.new(1,-50,0.5,-10)
    btn.BackgroundColor3=default and Color3.fromRGB(45,175,75) or Color3.fromRGB(80,28,28)
    btn.Text=default and "ON" or "OFF"; btn.TextColor3=Color3.new(1,1,1)
    btn.TextSize=10; btn.Font=Enum.Font.GothamBold; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local state=default or false
    btn.MouseButton1Click:Connect(function()
        state=not state
        btn.BackgroundColor3=state and Color3.fromRGB(45,175,75) or Color3.fromRGB(80,28,28)
        btn.Text=state and "ON" or "OFF"
        if cb then cb(state) end
    end)
end
local function Button(parent,text,cb)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,0,0,30); b.BackgroundColor3=Color3.fromRGB(38,38,88)
    b.Text=text; b.TextColor3=Color3.fromRGB(215,215,255)
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function()
        b.BackgroundColor3=Color3.fromRGB(55,55,130)
        task.delay(0.15,function() if b and b.Parent then b.BackgroundColor3=Color3.fromRGB(38,38,88) end end)
        if cb then cb() end
    end)
end
local function Input(parent,hint,cb)
    local box=Instance.new("TextBox",parent)
    box.Size=UDim2.new(1,0,0,30); box.BackgroundColor3=Color3.fromRGB(16,16,28)
    box.Text=""; box.PlaceholderText=hint; box.PlaceholderColor3=Color3.fromRGB(90,90,110)
    box.TextColor3=Color3.fromRGB(220,220,220); box.TextSize=11
    box.Font=Enum.Font.Gotham; box.BorderSizePixel=0; box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",box).Color=Color3.fromRGB(45,45,95)
    Instance.new("UIPadding",box).PaddingLeft=UDim.new(0,8)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return box
end
local function SLabel(parent,text)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1; l.Text=text
    l.TextColor3=Color3.fromRGB(160,160,170); l.TextSize=11; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UIPadding",l).PaddingLeft=UDim.new(0,4)
end

-- ---- Status badge (Farm) ----
local function StatusBadge(parent)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,28); f.BackgroundColor3=Color3.fromRGB(14,22,14); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",f).Color=Color3.fromRGB(30,80,30)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,8,0,0); l.BackgroundTransparency=1
    l.Text="Estado: inativo"; l.TextColor3=Color3.fromRGB(120,200,120)
    l.TextSize=11; l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

-- ============================================================
--  TABS
-- ============================================================

-- ── FARM ────────────────────────────────────────────────────
local farmPg=Tab("⚔","Farm")
Section(farmPg,"Auto Farm por Quest")

local statusLbl=StatusBadge(farmPg)

-- atualiza badge a cada segundo
task.spawn(function()
    local stateNames={idle="🔵 Aguardando",toquest="🟡 Indo pegar quest",
        fighting="🟢 Farmando",returning="🔴 Voltando"}
    while true do
        task.wait(1)
        if not Farm.Active then
            statusLbl.Text="Estado: inativo"
        else
            local lv=GetLevel()
            local zone=Farm.Zone and Farm.Zone.name or "..."
            statusLbl.Text=("Lv %d | %s | %s"):format(
                lv, zone, stateNames[Farm.State] or Farm.State)
        end
    end
end)

Toggle(farmPg,"🗺 Auto Farm Level (Quest)", false, function(v)
    Farm.Active=v
    if not v then Farm.State="idle" end
end)
Toggle(farmPg,"👊 Auto M1 (ataque contínuo)", false, function(v)
    Farm.Attack=v
end)

Section(farmPg,"Zonas de Quest")
SLabel(farmPg,"  Zona detectada automaticamente pelo Level.")
SLabel(farmPg,"  Lv 1-14  → Ilha Inicial")
SLabel(farmPg,"  Lv 15-34 → Base Marinha")
SLabel(farmPg,"  Lv 35-59 → Ilha Buggy")
SLabel(farmPg,"  Lv 60-89 → Baratie")
SLabel(farmPg,"  Lv 90-124 → Arlong Park")
SLabel(farmPg,"  Lv 125-174 → Coliseu")
SLabel(farmPg,"  Lv 175-224 → Thriller Bark")
SLabel(farmPg,"  Lv 225-274 → Marineford")
SLabel(farmPg,"  Lv 275-324 → Shanks Island")
SLabel(farmPg,"  Lv 325-374 → Mihawk Island")
SLabel(farmPg,"  Lv 375-449 → Skypiea")
SLabel(farmPg,"  Lv 450+   → Upper Yard")

-- ── ESP ─────────────────────────────────────────────────────
local espPg=Tab("👁","ESP")
Section(espPg,"Player ESP")
Toggle(espPg,"Player ESP",   false,function(v) Cfg.PlayerESP=v end)
Toggle(espPg,"Distância",    true, function(v) Cfg.ShowDist=v end)
Toggle(espPg,"Tracer Lines", false,function(v) Cfg.TracerLines=v end)
Section(espPg,"Fruit ESP")
Toggle(espPg,"Fruit ESP",    false,function(v) Cfg.FruitESP=v; if not v then ClearPool(FruitPool) end end)
Section(espPg,"Dungeon ESP")
Toggle(espPg,"Dungeon ESP",  false,function(v) Cfg.DungeonESP=v; if not v then ClearPool(DungeonPool) end end)
Section(espPg,"Alcance")
SLabel(espPg,"  Distância máxima (studs):")
local rIn=Input(espPg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end)
rIn.Text="2000"

-- ── TELEPORT ────────────────────────────────────────────────
local tpPg=Tab("🌀","Teleport")
Section(tpPg,"Frutas")
Button(tpPg,"🍎 Fruta Mais Próxima",TP_NearestFruit)
Button(tpPg,"🔄 TP para Todas as Frutas",function()
    task.spawn(function()
        for _,f in ipairs(ScanFruits()) do
            if Dist(f.pos)<2000 then TP(f.pos); task.wait(0.8) end
        end
    end)
end)
Section(tpPg,"Players")
SLabel(tpPg,"  Nome do player:")
local plrIn=Input(tpPg,"username...")
Button(tpPg,"→ Ir para Player",function() TP_Player(plrIn.Text) end)
Button(tpPg,"→ Ver Players Online",function()
    local n={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
    plrIn.Text=table.concat(n,", ")
end)
Section(tpPg,"🏝 Ilhas — Sea 1")
local S1={
    "🏝 Ilha Inicial","⚓ Base Marinha","🏴 Ilha Buggy",
    "🍊 Ilha da Nami","🐟 Ilha Arlong","🍖 Baratie",
    "⚔ Coliseu","⛩ Ilha Shanks","🏯 Ilha Mihawk",
    "🏰 Thriller Bark","🌊 Reverse Mountain","🔱 Marineford",
    "🔒 Impel Down","🚪 Entrada Dungeon",
}
for _,name in ipairs(S1) do
    local n,p=name,Locations[name]
    if p then Button(tpPg,"→ "..n,function() TP(p) end) end
end
Section(tpPg,"☁ Sky Islands")
for _,name in ipairs({"☁ Skypiea","🌩 Upper Yard","🏟 Sky Coliseu"}) do
    local n,p=name,Locations[name]
    if p then Button(tpPg,"→ "..n,function() TP(p) end) end
end
Section(tpPg,"🌊 Segundo Mar")
Button(tpPg,"→ 🌊 Portal 2º Mar",function() TP(Locations["🌊 Portal 2º Mar"]) end)
Section(tpPg,"Coordenadas Manuais")
SLabel(tpPg,"  X, Y, Z separados por vírgula:")
local cIn=Input(tpPg,"0, 100, 0")
Button(tpPg,"→ Ir para Coordenadas",function()
    local t=cIn.Text:split(",")
    local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
    if x and y and z then TP(Vector3.new(x,y,z)) end
end)
Button(tpPg,"📋 Copiar Posição Atual",function()
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local p=c.HumanoidRootPart.Position
        setclipboard(("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z))
        cIn.Text=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
    end
end)

-- ── WEBHOOK ─────────────────────────────────────────────────
local whPg=Tab("🔔","Webhook")
Section(whPg,"URL do Webhook")
Input(whPg,"https://discord.com/api/webhooks/...",function(v) Cfg.WHUrl=v end)
Section(whPg,"Manual")
SLabel(whPg,"  Título:"); local wht=Input(whPg,"Título...")
SLabel(whPg,"  Mensagem:"); local whm=Input(whPg,"Mensagem...")
Button(whPg,"📤 Enviar",function() WH_Custom(wht.Text,whm.Text,3447003) end)
Button(whPg,"🧪 Testar Conexão",function()
    WH_Custom("✅ Teste OK","Conectado! "..LP.Name,65280)
end)
Button(whPg,"📍 Enviar Posição",function()
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local p=c.HumanoidRootPart.Position
        WH_Custom("📍 Posição",("X:%.1f Y:%.1f Z:%.1f"):format(p.X,p.Y,p.Z),16776960)
    end
end)

-- ── MISC ────────────────────────────────────────────────────
local miscPg=Tab("⚙","Misc")
Section(miscPg,"Movimentação")
Toggle(miscPg,"No Clip",false,function(v)
    local c=LP.Character
    if c then for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=not v end
    end end
end)
Toggle(miscPg,"Infinite Jump",false,function(v)
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
Section(miscPg,"Walk Speed"); SLabel(miscPg,"  Valor (padrão 16):")
Input(miscPg,"16",function(v)
    local n=tonumber(v); local c=LP.Character
    if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
end)
Section(miscPg,"Jump Power"); SLabel(miscPg,"  Valor (padrão 50):")
Input(miscPg,"50",function(v)
    local n=tonumber(v); local c=LP.Character
    if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end
end)
Section(miscPg,"Utilitários")
Button(miscPg,"📋 Copiar Minha Posição",function()
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local p=c.HumanoidRootPart.Position
        setclipboard(("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z))
    end
end)
Button(miscPg,"🔁 Recarregar Personagem",function() LP:LoadCharacter() end)

-- ============================================================
--  OCULTAR — Ctrl + botão 👁 + ShowBtn
-- ============================================================
local function ToggleVisibility()
    if MF.Visible then MF.Visible=false; ShowBtn.Visible=true
    else MF.Visible=true; ShowBtn.Visible=false end
end
HideBtn.MouseButton1Click:Connect(ToggleVisibility)
ShowBtn.MouseButton1Click:Connect(ToggleVisibility)
UserInputService.InputBegan:Connect(function(inp,gpe)
    if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
    if gpe then return end
    if inp.KeyCode==Cfg.HideKey then ToggleVisibility() end
end)

-- ============================================================
--  DRAG
-- ============================================================
local dragging,dInput,dStart,dPos
TB.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dStart=inp.Position; dPos=MF.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
TB.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseMovement then dInput=inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp==dInput and dragging then
        local d=inp.Position-dStart
        MF.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
    end
end)

-- ============================================================
--  FECHAR / MINIMIZAR
-- ============================================================
CloseBtn.MouseButton1Click:Connect(function()
    Farm.Active=false; Farm.Attack=false
    for _,o in pairs(PLR_ESP) do for _,v in pairs(o) do pcall(function() v:Remove() end) end end
    ClearPool(FruitPool); ClearPool(DungeonPool); SG:Destroy()
end)
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized; CH.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,460,0,36) or UDim2.new(0,460,0,520)
    MinBtn.Text=minimized and "+" or "−"
end)

-- ============================================================
--  INIT
-- ============================================================
Pages["Farm"].Visible=true
TabBtns["Farm"].BackgroundColor3=Color3.fromRGB(55,55,145)
TabBtns["Farm"].TextColor3=Color3.fromRGB(220,220,255)

for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MakePlayerESP(pl) end)
Players.PlayerRemoving:Connect(KillPlayerESP)
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
end)

local tick2=0
RunService.RenderStepped:Connect(function()
    tick2=tick2+1; UpdatePlayerESP()
    if tick2%12==0 then UpdateFruitESP(); UpdateDungeonESP(); tick2=0 end
end)

print("[China Hub Free v3.0] Carregado — "..LP.Name)
