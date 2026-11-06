-- ============================================================
--  China Hub Free — King Legacy Script v3.1
--  CORREÇÕES: Anti-mar | Filtro NPC exato ("Interagir") |
--             Anti-barco | Zonas revisadas v10.2-Sea1 |
--             SafeTP | Calibração manual de zona
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

local Farm = {
    Active = false,
    Attack = false,
    State  = "idle",   -- idle | toquest | fighting
    Timer  = 0,
    Zone   = nil,
    StatusText = "Inativo",
}

-- ============================================================
--  DRAWING
-- ============================================================
local function NewText(color,size)
    local t=Drawing.new("Text"); t.Color=color or Color3.new(1,1,1)
    t.Size=size or 13; t.Center=true; t.Outline=true; t.Visible=false; return t
end
local function NewBox(color,filled)
    local b=Drawing.new("Square"); b.Color=color or Color3.new(1,1,1)
    b.Thickness=1.5; b.Filled=filled or false; b.Visible=false; return b
end
local function NewLine(color)
    local l=Drawing.new("Line"); l.Color=color or Color3.new(1,1,1)
    l.Thickness=1; l.Visible=false; return l
end
local function W2V(pos)
    local sp,d,on=Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X,sp.Y),d,on
end
local function Dist(pos)
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        return math.floor((c.HumanoidRootPart.Position-pos).Magnitude)
    end
    return 0
end

-- ============================================================
--  SAFE TP — evita cair no mar
--  Garante Y mínimo de 20 e verifica após TP
-- ============================================================
local SEA_Y = 8  -- abaixo disso = mar

local function SafeTP(pos)
    local char=LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    -- Y mínimo seguro
    local safeY = math.max(pos.Y, 22)
    char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(pos.X, safeY, pos.Z))
    task.wait(0.4)
    -- anti-afogamento: se caiu abaixo do mar, retorna à ilha
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        Farm.State  = "idle"
        Farm.StatusText = "⚠ Caiu no mar — resetando"
        if Farm.Zone then
            char.HumanoidRootPart.CFrame =
                CFrame.new(Farm.Zone.islePos + Vector3.new(0,12,0))
        end
    end
end

-- ============================================================
--  ZONAS POR LEVEL — King Legacy v10.2-Sea1
--  islePos  = ponto central seguro da ilha (Y alto)
--  questPos = área onde o NPC de quest fica
--  mobPos   = área central dos mobs da missão
--
--  Se uma zona vier errada: use o botão "📍 Calibrar" na aba Farm
--  enquanto estiver no lugar certo e informe a zona para corrigir.
-- ============================================================
local QuestZones = {
    {
        name     = "Ilha Inicial",
        minLv=1,  maxLv=14,
        islePos  = Vector3.new(-210,  28,  180),
        questPos = Vector3.new(-185,  25,  148),
        mobPos   = Vector3.new(-268,  20,  215),
    },
    {
        name     = "Base Marinha",
        minLv=15, maxLv=34,
        islePos  = Vector3.new( 990,  28, -510),
        questPos = Vector3.new(1012,  24, -548),
        mobPos   = Vector3.new( 948,  20, -472),
    },
    {
        name     = "Ilha Buggy",
        minLv=35, maxLv=59,
        islePos  = Vector3.new( 402,  28,-1002),
        questPos = Vector3.new( 422,  24,-1035),
        mobPos   = Vector3.new( 465,  20, -958),
    },
    {
        name     = "Baratie",
        minLv=60, maxLv=89,
        islePos  = Vector3.new(-792,  28, 1242),
        questPos = Vector3.new(-762,  24, 1272),
        mobPos   = Vector3.new(-832,  20, 1198),
    },
    {
        name     = "Arlong Park",
        minLv=90, maxLv=124,
        islePos  = Vector3.new(1822,  28, 1492),
        questPos = Vector3.new(1848,  24, 1515),
        mobPos   = Vector3.new(1778,  20, 1448),
    },
    {
        name     = "Coliseu",
        minLv=125,maxLv=174,
        islePos  = Vector3.new(1622,  28, -872),
        questPos = Vector3.new(1648,  24, -898),
        mobPos   = Vector3.new(1575,  20, -935),
    },
    {
        -- "Ilha dos Tubarões" (Nível 180+) — visível na imagem
        name     = "Ilha dos Tubarões",
        minLv=175,maxLv=224,
        islePos  = Vector3.new(-3052, 28, 1978),
        questPos = Vector3.new(-3030, 24, 1958),
        mobPos   = Vector3.new(-3105, 20, 2022),
    },
    {
        name     = "Marineford",
        minLv=225,maxLv=274,
        islePos  = Vector3.new(2552,  28,-2058),
        questPos = Vector3.new(2572,  24,-2082),
        mobPos   = Vector3.new(2508,  20,-2135),
    },
    {
        name     = "Shanks Island",
        minLv=275,maxLv=324,
        islePos  = Vector3.new(-1892, 28, -858),
        questPos = Vector3.new(-1872, 24, -878),
        mobPos   = Vector3.new(-1945, 20, -802),
    },
    {
        name     = "Mihawk Island",
        minLv=325,maxLv=374,
        islePos  = Vector3.new(-2492, 28, -312),
        questPos = Vector3.new(-2512, 24, -332),
        mobPos   = Vector3.new(-2562, 20, -375),
    },
    {
        name     = "Skypiea",
        minLv=375,maxLv=449,
        islePos  = Vector3.new(-2822, 865,-1632),
        questPos = Vector3.new(-2842, 860,-1652),
        mobPos   = Vector3.new(-2892, 858,-1702),
    },
    {
        name     = "Upper Yard",
        minLv=450,maxLv=999,
        islePos  = Vector3.new(-3102, 882,-1922),
        questPos = Vector3.new(-3122, 877,-1942),
        mobPos   = Vector3.new(-3172, 872,-1992),
    },
}

local function GetLevel()
    local ls=LP:FindFirstChild("leaderstats")
    if ls then
        for _,n in ipairs({"Level","Lv","level","Nivel","nível"}) do
            local v=ls:FindFirstChild(n)
            if v then return v.Value end
        end
    end
    for _,v in ipairs(LP:GetDescendants()) do
        if (v.Name=="Level" or v.Name=="Lv") and
           (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    return 1
end

local function GetZoneForLevel(lv)
    for _,z in ipairs(QuestZones) do
        if lv>=z.minLv and lv<=z.maxLv then return z end
    end
    return QuestZones[#QuestZones]
end

-- ============================================================
--  FILTRO DE NPC — evita marinheiro de barco
--  Critérios de exclusão:
--    1. Y < SEA_Y  (está no mar / abaixo do terreno)
--    2. Ancestral com nome de embarcação
--    3. ActionText não é "Interagir" (King Legacy usa esse texto exato)
-- ============================================================
local BOAT_NAMES = {
    "boat","ship","navio","ferry","barca","vessel","galleon","galé",
    "barca","embarca","pirate ship","marine ship","barco"
}
local function IsBoatDescendant(obj)
    local cur=obj
    for _=1,8 do
        if not cur or not cur.Parent then break end
        cur=cur.Parent
        local n=cur.Name:lower()
        for _,bad in ipairs(BOAT_NAMES) do
            if n:find(bad) then return true end
        end
    end
    return false
end

-- King Legacy: o prompt dos NPCs de quest usa ActionText = "Interagir"
-- (confirmado pela screenshot do dj)
local function FindQuestNPC(nearPos, radius)
    radius = radius or 90
    local best, bestDist = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part=obj.Parent
            if not (part and part:IsA("BasePart")) then continue end
            -- filtro Y: não pode estar no mar
            if part.Position.Y < SEA_Y then continue end
            -- filtro barco
            if IsBoatDescendant(part) then continue end
            -- distância
            local d=(part.Position-nearPos).Magnitude
            if d>=radius or d>=bestDist then continue end
            -- filtro ActionText: "Interagir" é o padrão do King Legacy
            local at=(obj.ActionText or ""):lower()
            if at:find("interagir") or at:find("interact") or at:find("quest") then
                best=obj; bestDist=d
            end
        end
    end
    return best, bestDist
end

local function FirePrompt(prompt)
    if not prompt then return false end
    local ok=pcall(function() fireproximityprompt(prompt) end)
    return ok
end

-- ============================================================
--  MOB MAIS PRÓXIMO (filtrado por zona)
-- ============================================================
local function NearestMob(zoneCenter, zoneRadius)
    local char=LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil,math.huge end
    local origin=char.HumanoidRootPart.Position
    local best,bestDist=nil,math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj~=char then
            local hum=obj:FindFirstChildOfClass("Humanoid")
            local hrp=obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>0 and not Players:GetPlayerFromCharacter(obj) then
                -- se tiver zoneCenter, filtra mobs fora da zona
                if zoneCenter and (hrp.Position-zoneCenter).Magnitude > (zoneRadius or 350) then
                    continue
                end
                local d=(origin-hrp.Position).Magnitude
                if d<bestDist then bestDist=d; best=obj end
            end
        end
    end
    return best,bestDist
end

-- ============================================================
--  AUTO M1 — loop independente 0.18s
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.18)
        if not Farm.Attack then continue end
        local char=LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        -- não ataca se personagem morreu
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then task.wait(2); continue end
        local mob,dist=NearestMob()
        if not mob then continue end
        local hrp=mob:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if dist>7 then
            char.HumanoidRootPart.CFrame=CFrame.new(hrp.Position+Vector3.new(3,2,0))
            task.wait(0.08)
        end
        local sp,_,onScr=Camera:WorldToViewportPoint(hrp.Position)
        if onScr then
            VirtualUser:ClickButton1(Vector2.new(sp.X,sp.Y),CFrame.new())
        end
    end
end)

-- ============================================================
--  AUTO FARM QUEST — máquina de estado
--  idle → toquest → fighting → idle
-- ============================================================
local QUEST_TIMEOUT = 100  -- segundos antes de reiniciar ciclo

task.spawn(function()
    while true do
        task.wait(0.25)
        if not Farm.Active then Farm.State="idle"; continue end

        local char=LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1); continue
        end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then
            Farm.StatusText="⏳ Aguardando respawn..."
            task.wait(3); continue
        end

        local lv=GetLevel()
        local zone=GetZoneForLevel(lv)

        -- ── idle: define zona e vai buscar quest ─────────────
        if Farm.State=="idle" then
            Farm.Zone=zone
            Farm.State="toquest"
            Farm.Timer=tick()
            Farm.StatusText=("Lv %d → %s | Indo buscar quest"):format(lv, zone.name)

        -- ── toquest: TP para NPC e fire prompt ───────────────
        elseif Farm.State=="toquest" then
            -- 1. TP para área do NPC
            SafeTP(Farm.Zone.questPos)
            task.wait(1.0)
            if char.HumanoidRootPart.Position.Y < SEA_Y then
                Farm.State="idle"; continue
            end

            -- 2. Busca NPC com ActionText "Interagir" perto do questPos
            local npc, npcDist = FindQuestNPC(Farm.Zone.questPos, 90)
            if npc then
                -- TP direto no NPC para garantir o range do prompt
                local npcPart=npc.Parent
                if npcPart and npcPart:IsA("BasePart") then
                    local npcPos=npcPart.Position
                    if npcPos.Y >= SEA_Y then
                        char.HumanoidRootPart.CFrame =
                            CFrame.new(npcPos + Vector3.new(3,1,0))
                        task.wait(0.6)
                    end
                end
                FirePrompt(npc); task.wait(0.4)
                FirePrompt(npc); task.wait(0.4)  -- segunda vez (confirmar)
                Farm.StatusText=("Lv %d → %s | Quest aceita ✓"):format(lv, Farm.Zone.name)
            else
                -- sem NPC encontrado: vai direto pra mobs mesmo assim
                Farm.StatusText=("Lv %d → %s | NPC não achado — farmando"):format(lv, Farm.Zone.name)
            end

            -- 3. TP para área de mobs
            SafeTP(Farm.Zone.mobPos)
            task.wait(0.8)
            if char.HumanoidRootPart.Position.Y < SEA_Y then
                Farm.State="idle"; continue
            end

            Farm.State="fighting"
            Farm.Timer=tick()

        -- ── fighting: matar mobs e entregar quest ────────────
        elseif Farm.State=="fighting" then
            -- timeout
            if tick()-Farm.Timer > QUEST_TIMEOUT then
                Farm.StatusText=("Timeout — voltando pra quest"):format()
                Farm.State="idle"; continue
            end

            -- mob filtrado pela zona (raio 350 studs do mobPos)
            local mob,dist=NearestMob(Farm.Zone.mobPos, 350)

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp=mob.HumanoidRootPart
                -- verifica que mob não está no mar
                if hrp.Position.Y < SEA_Y then
                    task.wait(0.5); continue
                end
                if dist>7 then
                    char.HumanoidRootPart.CFrame=
                        CFrame.new(hrp.Position+Vector3.new(3,2,0))
                    task.wait(0.1)
                end
                -- M1 no mob (farm attack independente do botão Auto M1)
                local sp,_,onScr=Camera:WorldToViewportPoint(hrp.Position)
                if onScr then
                    VirtualUser:ClickButton1(Vector2.new(sp.X,sp.Y),CFrame.new())
                end
                local alive=mob:FindFirstChildOfClass("Humanoid")
                Farm.StatusText=("Lv %d → %s | Farmando [HP mob: %d]"):format(
                    lv, Farm.Zone.name, alive and math.floor(alive.Health) or 0)
            else
                -- sem mob na zona → aguarda respawn
                Farm.StatusText=("Lv %d → %s | Aguardando respawn..."):format(lv, Farm.Zone.name)
                -- tenta entregar quest enquanto espera
                local ret=FindQuestNPC(Farm.Zone.questPos, 90)
                if ret then
                    local at=(ret.ActionText or ""):lower()
                    -- se prompt mudou para entrega (King Legacy muda o texto quando missão pronta)
                    if at:find("entreg") or at:find("complet") or at:find("return") or at:find("finish") then
                        SafeTP(Farm.Zone.questPos)
                        task.wait(0.8)
                        FirePrompt(ret); task.wait(0.4)
                        Farm.State="idle"
                        continue
                    end
                end
                -- reinicia após 90s sem mob (timeout de respawn)
                if tick()-Farm.Timer > QUEST_TIMEOUT then
                    Farm.State="idle"
                end
                task.wait(1.5)
            end
        end
    end
end)

-- ============================================================
--  SCAN FRUTAS / DUNGEONS
-- ============================================================
local FruitKW={"fruit","devil","gumgum","bombomb","chop","smoke","flame","ice",
    "magnet","light","dark","quake","phoenix","dragon","rubb","sand","diamond",
    "paw","gravity","string","shadow","portal","control","venom","leopard",
    "blizzard","gas","surge","rumble","barrier","soul"}
local function IsFruit(obj)
    local n=obj.Name:lower()
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
local DungeonKW={"dungeon","boss","raid","gate","chest","mob","enemy"}
local function IsDungeon(obj)
    local n=obj.Name:lower()
    for _,k in ipairs(DungeonKW) do if n:find(k) then return true end end
end

-- ============================================================
--  TELEPORT
-- ============================================================
local function TP(pos)
    local char=LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame=CFrame.new(pos+Vector3.new(0,4,0))
    end
end
local function TP_Player(name)
    local t=Players:FindFirstChild(name)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        TP(t.Character.HumanoidRootPart.Position)
    end
end
local function TP_NearestFruit()
    local fruits=ScanFruits(); if #fruits==0 then return end
    local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    table.sort(fruits,function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

local Locations = {
    ["🏝 Ilha Inicial"]     = Vector3.new(-210,  28,  180),
    ["⚓ Base Marinha"]      = Vector3.new( 990,  28, -510),
    ["🏴 Ilha Buggy"]       = Vector3.new( 402,  28,-1002),
    ["🍊 Ilha da Nami"]     = Vector3.new(1250,  28,  640),
    ["🐟 Arlong Park"]      = Vector3.new(1822,  28, 1492),
    ["🍖 Baratie"]          = Vector3.new(-792,  28, 1242),
    ["⚔ Coliseu"]           = Vector3.new(1622,  28, -872),
    ["🦈 Ilha dos Tubarões"]= Vector3.new(-3052, 28, 1978),
    ["⛩ Ilha Shanks"]       = Vector3.new(-1892, 28, -858),
    ["🏯 Ilha Mihawk"]      = Vector3.new(-2492, 28, -312),
    ["🔱 Marineford"]       = Vector3.new(2552,  28,-2058),
    ["🔒 Impel Down"]       = Vector3.new(2820,  28, 1760),
    ["☁ Skypiea"]           = Vector3.new(-2822, 865,-1632),
    ["🌩 Upper Yard"]       = Vector3.new(-3102, 882,-1922),
    ["🏟 Sky Coliseu"]      = Vector3.new(-3200,1200,-1600),
    ["🌊 Portal 2º Mar"]    = Vector3.new( 2900,  28,  900),
}

-- ============================================================
--  GUI
-- ============================================================
local old=CoreGui:FindFirstChild("CHINAHUB")
if old then old:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="CHINAHUB"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=CoreGui

-- ---- ShowBtn ----
local ShowBtn=Instance.new("TextButton",SG)
ShowBtn.Size=UDim2.new(0,130,0,32); ShowBtn.Position=UDim2.new(0,22,0,55)
ShowBtn.BackgroundColor3=Color3.fromRGB(14,14,38)
ShowBtn.Text="⚔ China Hub Free"; ShowBtn.TextColor3=Color3.fromRGB(170,170,255)
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

-- ---- Helpers ----
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

-- ============================================================
--  TABS
-- ============================================================

-- ── FARM ────────────────────────────────────────────────────
local farmPg=Tab("⚔","Farm")

-- Status badge — atualiza em tempo real
local statusRow=Instance.new("Frame",farmPg)
statusRow.Size=UDim2.new(1,0,0,32); statusRow.BackgroundColor3=Color3.fromRGB(14,22,14)
statusRow.BorderSizePixel=0
Instance.new("UICorner",statusRow).CornerRadius=UDim.new(0,5)
Instance.new("UIStroke",statusRow).Color=Color3.fromRGB(30,80,30)
local statusLbl=Instance.new("TextLabel",statusRow)
statusLbl.Size=UDim2.new(1,-10,1,0); statusLbl.Position=UDim2.new(0,8,0,0)
statusLbl.BackgroundTransparency=1; statusLbl.Text="Estado: inativo"
statusLbl.TextColor3=Color3.fromRGB(120,200,120); statusLbl.TextSize=11
statusLbl.Font=Enum.Font.GothamBold; statusLbl.TextXAlignment=Enum.TextXAlignment.Left

task.spawn(function()
    while true do
        task.wait(0.8)
        statusLbl.Text = Farm.Active and Farm.StatusText or "Estado: inativo"
    end
end)

Section(farmPg,"Auto Farm")
Toggle(farmPg,"🗺 Auto Farm Level (Quest)",false,function(v)
    Farm.Active=v; if not v then Farm.State="idle" end
end)
Toggle(farmPg,"👊 Auto M1 (ataque livre)",false,function(v)
    Farm.Attack=v
end)

Section(farmPg,"📍 Calibrar Zonas")
SLabel(farmPg,"  Vá até o NPC de quest e clique Calibrar.")
SLabel(farmPg,"  O questPos da zona atual será atualizado.")

-- Selector de zona para calibrar
local zoneNames={}
for _,z in ipairs(QuestZones) do table.insert(zoneNames,z.name) end
local selectedZoneIdx=1
local zoneSelectLbl=Instance.new("TextLabel",farmPg)
zoneSelectLbl.Size=UDim2.new(1,0,0,22); zoneSelectLbl.BackgroundColor3=Color3.fromRGB(22,22,42)
zoneSelectLbl.BorderSizePixel=0; zoneSelectLbl.Text="Zona: "..QuestZones[1].name
zoneSelectLbl.TextColor3=Color3.fromRGB(180,180,220); zoneSelectLbl.TextSize=11
zoneSelectLbl.Font=Enum.Font.GothamBold
Instance.new("UICorner",zoneSelectLbl).CornerRadius=UDim.new(0,5)

local zoneRow=Instance.new("Frame",farmPg)
zoneRow.Size=UDim2.new(1,0,0,30); zoneRow.BackgroundTransparency=1
local zRL=Instance.new("UIListLayout",zoneRow)
zRL.FillDirection=Enum.FillDirection.Horizontal; zRL.Padding=UDim.new(0,4)

local function ZBtn(text,cb)
    local b=Instance.new("TextButton",zoneRow)
    b.Size=UDim2.new(0.48,0,1,0); b.BackgroundColor3=Color3.fromRGB(35,35,75)
    b.Text=text; b.TextColor3=Color3.fromRGB(200,200,220)
    b.TextSize=11; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(cb); return b
end
ZBtn("◄ Anterior",function()
    selectedZoneIdx=math.max(1,selectedZoneIdx-1)
    zoneSelectLbl.Text="Zona: "..QuestZones[selectedZoneIdx].name
end)
ZBtn("Próxima ►",function()
    selectedZoneIdx=math.min(#QuestZones,selectedZoneIdx+1)
    zoneSelectLbl.Text="Zona: "..QuestZones[selectedZoneIdx].name
end)

Button(farmPg,"📍 Calibrar questPos desta zona",function()
    local c=LP.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
    local pos=c.HumanoidRootPart.Position
    QuestZones[selectedZoneIdx].questPos=pos
    statusLbl.Text=("✓ questPos [%s] = %.0f,%.0f,%.0f"):format(
        QuestZones[selectedZoneIdx].name, pos.X, pos.Y, pos.Z)
end)
Button(farmPg,"📍 Calibrar mobPos desta zona",function()
    local c=LP.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
    local pos=c.HumanoidRootPart.Position
    QuestZones[selectedZoneIdx].mobPos=pos
    statusLbl.Text=("✓ mobPos [%s] = %.0f,%.0f,%.0f"):format(
        QuestZones[selectedZoneIdx].name, pos.X, pos.Y, pos.Z)
end)

Section(farmPg,"Zonas de Quest")
SLabel(farmPg,"  Lv  1-14  → Ilha Inicial")
SLabel(farmPg,"  Lv 15-34  → Base Marinha")
SLabel(farmPg,"  Lv 35-59  → Ilha Buggy")
SLabel(farmPg,"  Lv 60-89  → Baratie")
SLabel(farmPg,"  Lv 90-124 → Arlong Park")
SLabel(farmPg,"  Lv 125-174 → Coliseu")
SLabel(farmPg,"  Lv 175-224 → Ilha dos Tubarões")
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
Toggle(espPg,"Fruit ESP",    false,function(v) Cfg.FruitESP=v end)
Section(espPg,"Dungeon ESP")
Toggle(espPg,"Dungeon ESP",  false,function(v) Cfg.DungeonESP=v end)
Section(espPg,"Alcance")
SLabel(espPg,"  Distância máxima (studs):")
local rIn=Input(espPg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end)
rIn.Text="2000"

-- ── TELEPORT ────────────────────────────────────────────────
local tpPg=Tab("🌀","Teleport")
Section(tpPg,"Frutas")
Button(tpPg,"🍎 Fruta Mais Próxima",TP_NearestFruit)
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
    "🍊 Ilha da Nami","🐟 Arlong Park","🍖 Baratie",
    "⚔ Coliseu","🦈 Ilha dos Tubarões","⛩ Ilha Shanks",
    "🏯 Ilha Mihawk","🔱 Marineford","🔒 Impel Down",
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
    if x and y and z then SafeTP(Vector3.new(x,y,z)) end
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
local function WH_Custom(title,desc,color)
    local function SendWH(url,payload)
        if not url or url=="" then return end
        local req=syn and syn.request or (http and http.request) or request
        if not req then return end
        pcall(req,{Url=url,Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HttpService:JSONEncode(payload)})
    end
    SendWH(Cfg.WHUrl,{username="China Hub Free",embeds={{
        title=title,description=desc,color=color or 16777215,
        footer={text="King Legacy | "..LP.Name},
        timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
end
Button(whPg,"📤 Enviar",function() WH_Custom(wht.Text,whm.Text,3447003) end)
Button(whPg,"🧪 Testar",function() WH_Custom("✅ OK","Conectado! "..LP.Name,65280) end)

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
--  ESP POOLS / UPDATE
-- ============================================================
local PLR_ESP={}
local function MakePlayerESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={
        box=NewBox(Cfg.Col_Player),name=NewText(Cfg.Col_Player,13),
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
        if obj.lbl then obj.lbl:Remove() end
        if obj.dist then obj.dist:Remove() end
    end
    table.clear(pool)
end
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
--  OCULTAR / MOSTRAR
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
    Farm.State="idle"
    task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
end)

local t2=0
RunService.RenderStepped:Connect(function()
    t2=t2+1; UpdatePlayerESP()
    if t2%12==0 then UpdateFruitESP(); UpdateDungeonESP(); t2=0 end
end)

print("[China Hub Free v3.1] Carregado — "..LP.Name)
