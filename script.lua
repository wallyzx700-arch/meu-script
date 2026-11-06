-- ============================================================
--  CHINA HUB FREE  v6.0  —  King Legacy
--  Farm universal: scan de Humanoid vivos em qualquer folder
--  Quest: RF + ProximityPrompt fallback
--  Sem aba Home
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
--  LEVEL
-- ============================================================
local function GetLevel()
    -- King Legacy: PlayerStats.lvl
    local ps = LP:FindFirstChild("PlayerStats")
    if ps then
        for _, n in ipairs({"lvl","Level","Lv","level"}) do
            local v = ps:FindFirstChild(n)
            if v then return math.max(1, tonumber(v.Value) or 1) end
        end
    end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Level","Lv","level","lvl"}) do
            local v = ls:FindFirstChild(n)
            if v then return math.max(1, tonumber(v.Value) or 1) end
        end
    end
    return 1
end

-- ============================================================
--  ZONAS — coordenadas reais Starter + Pirate confirmadas
--  demais: calibrar in-game
-- ============================================================
local Zones = {
    { name="Starter Island",  minLv=1,   maxLv=49,
      islePos=Vector3.new(-2044,100,-4591),
      mobPos= Vector3.new(-2044,100,-4591), radius=400 },

    { name="Pirate Island",   minLv=50,  maxLv=99,
      islePos=Vector3.new(-681,64,-3449),
      mobPos= Vector3.new(-681,64,-3449),  radius=400 },

    { name="Soldier Island",  minLv=100, maxLv=179,
      islePos=Vector3.new(990,28,-510),
      mobPos= Vector3.new(990,28,-510),    radius=400 },

    { name="Shark Island",    minLv=180, maxLv=249,
      islePos=Vector3.new(1822,28,1492),
      mobPos= Vector3.new(1822,28,1492),   radius=400 },

    { name="Chef Ship",       minLv=250, maxLv=399,
      islePos=Vector3.new(-792,28,1242),
      mobPos= Vector3.new(-792,28,1242),   radius=400 },

    { name="Snow Island",     minLv=400, maxLv=524,
      islePos=Vector3.new(1622,28,-872),
      mobPos= Vector3.new(1622,28,-872),   radius=400 },

    { name="Sand Kingdom",    minLv=525, maxLv=799,
      islePos=Vector3.new(-3052,28,1978),
      mobPos= Vector3.new(-3052,28,1978),  radius=400 },

    { name="Sky Island",      minLv=800, maxLv=999,
      islePos=Vector3.new(-2822,865,-1632),
      mobPos= Vector3.new(-2822,865,-1632),radius=400 },

    { name="Bubble Island",   minLv=1000,maxLv=9999,
      islePos=Vector3.new(2552,28,-2058),
      mobPos= Vector3.new(2552,28,-2058),  radius=400 },
}

local function GetZone(lv)
    for _, z in ipairs(Zones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return Zones[#Zones]
end

-- ============================================================
--  ENCONTRAR MOB — scan universal, qualquer folder
--  Nao depende de workspace.Monster nem de nomes especificos
-- ============================================================
local function FindMob(nearPos, radius)
    local char = LP.Character
    if not char then return nil end
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
--  ACEITAR QUEST
--  Tenta RemoteFunction (King Legacy oficial) depois ProximityPrompt
-- ============================================================
local questRF = nil

local function TryGetRF()
    if questRF then return questRF end
    -- tenta os paths conhecidos do KL
    local paths = {
        {"Chest","Functions","Quest"},
        {"Remotes","Quest"},
        {"RemoteEvents","Quest"},
        {"Functions","Quest"},
    }
    for _, p in ipairs(paths) do
        local cur = RS
        local ok = true
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
    if not ok then
        ok = pcall(function() rf:InvokeServer(desc) end)
    end
    return ok
end

-- ProximityPrompt fallback: scan de PPr com texto de quest
local function FindQuestPrompt(nearPos, radius)
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if not (part and part:IsA("BasePart")) then continue end
            local d = (part.Position - nearPos).Magnitude
            if d >= radius or d >= bestD then continue end
            -- filtra barcos
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
            -- modelo pai chamado "Quest"
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
--  FARM CONFIG
-- ============================================================
local Farm = {
    Active      = false,
    State       = "idle",    -- idle|tozone|fighting
    StatusText  = "Inativo",
    Style       = "melee",
    KillCount   = 0,
    TargetKills = 10,
    HoverY      = 5,
    Zone        = nil,
    UseQuest    = true,     -- se false, so mata mobs sem aceitar quest
}
local AutoAttack = false
local SEA_Y      = 15

-- ============================================================
--  TELEPORTE
-- ============================================================
local function SetCollision(v)
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = v end
    end
end

local seaFails = 0
local function SafeTP(pos)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(
        Vector3.new(pos.X, math.max(pos.Y + 5, 60), pos.Z)
    )
    task.wait(1.2)
    if char.HumanoidRootPart.Position.Y < SEA_Y then
        seaFails = seaFails + 1
        Farm.StatusText = ("COORD ERRADA (%d/3) — Calibre"):format(seaFails)
        if seaFails >= 3 then
            Farm.Active = false; Farm.State = "idle"; seaFails = 0
            Farm.StatusText = "PAUSADO — Calibre as coords na aba Farm"
        else Farm.State = "idle" end
        return false
    end
    seaFails = 0; return true
end

-- ============================================================
--  ATAQUE — hover acima + VIM click
-- ============================================================
local function EquipFirst()
    local char = LP.Character; if not char then return end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if Farm.Style == "sword" then
                if n:find("sword") or n:find("katana") or n:find("blade") or n:find("cutlass") then
                    char.Humanoid:EquipTool(t); task.wait(0.25); return
                end
            else
                char.Humanoid:EquipTool(t); task.wait(0.25); return
            end
        end
    end
end

local function PressKey(kc)
    pcall(function()
        if syn and syn.key_press then
            syn.key_press(kc); task.wait(0.07); syn.key_release(kc)
        elseif keypress then
            keypress(kc); task.wait(0.07); if keyrelease then keyrelease(kc) end
        end
    end)
end

local function AttackMob(mob)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    -- posiciona acima do mob, olhando para baixo
    local over = hrp.Position + Vector3.new(0, Farm.HoverY, 0)
    char.HumanoidRootPart.CFrame = CFrame.lookAt(over, hrp.Position)
    SetCollision(false)

    if Farm.Style == "fruit" then
        PressKey(0x5A)  -- Z
        task.wait(0.05)
        PressKey(0x58)  -- X
    elseif Farm.Style == "sword" then
        EquipFirst()
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
--  AUTO FARM LOOP
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

        -- IDLE: define zona e vai
        if Farm.State == "idle" then
            Farm.Zone      = zone
            Farm.KillCount = 0
            Farm.StatusText = ("Lv %d  |  %s  |  Viajando"):format(lv, zone.name)
            Farm.State = "tozone"

        -- TOZONE: TP + aceita quest
        elseif Farm.State == "tozone" then
            local ok = SafeTP(Farm.Zone.mobPos)
            if not ok then continue end

            -- tenta aceitar quest
            if Farm.UseQuest then
                -- metodo 1: RemoteFunction
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
                local desc = nil
                for threshold, d in pairs(questDescs) do
                    if lv >= threshold then
                        if desc == nil then
                            desc = d
                        end
                    end
                end
                -- pega o desc do threshold mais alto <= lv
                local bestThresh = -1
                for threshold, d in pairs(questDescs) do
                    if lv >= threshold and threshold > bestThresh then
                        bestThresh = threshold; desc = d
                    end
                end

                if desc then
                    TakeQuestRF(desc)
                    task.wait(0.5)
                end

                -- metodo 2: ProximityPrompt fallback
                local pp = FindQuestPrompt(Farm.Zone.islePos, 350)
                if pp then
                    FirePP(pp); task.wait(0.4)
                    FirePP(pp); task.wait(0.3)
                end
            end

            if Farm.Style == "sword" then EquipFirst() end

            Farm.State     = "fighting"
            Farm.KillCount = 0
            Farm.StatusText = ("Lv %d  |  %s  |  Lutando"):format(lv, zone.name)

        -- FIGHTING: mata mobs
        elseif Farm.State == "fighting" then
            local mob, dist = FindMob(Farm.Zone.mobPos, Farm.Zone.radius)

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob.HumanoidRootPart
                if hrp.Position.Y < SEA_Y then task.wait(0.3); continue end

                local hBefore = mob:FindFirstChildOfClass("Humanoid")
                local hpB     = hBefore and hBefore.Health or 0

                AttackMob(mob); task.wait(0.15)

                local hAfter = mob:FindFirstChildOfClass("Humanoid")
                if not hAfter or hAfter.Health <= 0 then
                    if hpB > 0 then Farm.KillCount = Farm.KillCount + 1 end
                end

                local curHp = hAfter and math.floor(hAfter.Health) or 0
                Farm.StatusText = ("Lv %d  |  %s  |  %d/%d kills  |  HP %d"):format(
                    lv, zone.name, Farm.KillCount, Farm.TargetKills, curHp)

                if Farm.KillCount >= Farm.TargetKills then
                    SetCollision(true)
                    Farm.State = "idle"
                    Farm.StatusText = ("Lv %d  |  Ciclo completo! Reiniciando..."):format(lv)
                end
            else
                -- nenhum mob: re-TP na area
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
        local origin = char.HumanoidRootPart.Position
        local mob = FindMob(origin, 500)
        if mob then AttackMob(mob) end
    end
end)

-- ============================================================
--  FRUTAS
-- ============================================================
local FruitKW = {"fruit","devil","gumgum","chop","smoke","flame","ice","magnet",
    "light","dark","quake","phoenix","dragon","rubb","sand","diamond","paw",
    "gravity","string","shadow","portal","control","venom","leopard","blizzard",
    "gas","surge","rumble","barrier","soul","human","buddha","love",}
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
local function TP(pos)
    local char=LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame=CFrame.new(pos+Vector3.new(0,5,0))
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

-- ============================================================
--  ESP
-- ============================================================
local Cfg={
    PlayerESP=false,FruitESP=false,ShowDist=true,
    TracerLines=false,ESPRange=2000,WHUrl="",
    HideKey=Enum.KeyCode.LeftControl,
    Col_P=Color3.fromRGB(220,60,60),
    Col_F=Color3.fromRGB(60,210,100),
}
local function NTxt(col,sz) local t=Drawing.new("Text"); t.Color=col or Color3.new(1,1,1); t.Size=sz or 13; t.Center=true; t.Outline=true; t.Visible=false; return t end
local function NBox(col,f) local b=Drawing.new("Square"); b.Color=col or Color3.new(1,1,1); b.Thickness=1.5; b.Filled=f or false; b.Visible=false; return b end
local function NLine(col) local l=Drawing.new("Line"); l.Color=col or Color3.new(1,1,1); l.Thickness=1; l.Visible=false; return l end
local function W2V(pos) local sp=Camera:WorldToViewportPoint(pos); return Vector2.new(sp.X,sp.Y),sp.Z,sp.Z>0 end
local function Dist(pos) local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then return math.floor((c.HumanoidRootPart.Position-pos).Magnitude) end; return 0 end

-- ============================================================
--  GUI
-- ============================================================
local old=CoreGui:FindFirstChild("CHINAHUB6"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="CHINAHUB6"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true; SG.Parent=CoreGui

local C={
    bg    =Color3.fromRGB(8,8,14),
    side  =Color3.fromRGB(11,11,19),
    panel =Color3.fromRGB(15,15,24),
    card  =Color3.fromRGB(20,20,33),
    cardH =Color3.fromRGB(26,26,42),
    acc   =Color3.fromRGB(165,55,255),
    acc2  =Color3.fromRGB(210,100,255),
    green =Color3.fromRGB(55,205,105),
    red   =Color3.fromRGB(215,55,70),
    text  =Color3.fromRGB(228,228,242),
    dim   =Color3.fromRGB(115,115,140),
    bord  =Color3.fromRGB(45,35,75),
    sep   =Color3.fromRGB(28,22,48),
}

local function Rnd(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8) end
local function Str(p,col,t) local s=Instance.new("UIStroke",p); s.Color=col or C.bord; s.Thickness=t or 1; return s end
local function Pad(p,l,r,t,b) local x=Instance.new("UIPadding",p); x.PaddingLeft=UDim.new(0,l or 0); x.PaddingRight=UDim.new(0,r or 0); x.PaddingTop=UDim.new(0,t or 0); x.PaddingBottom=UDim.new(0,b or 0) end
local function Lst(p,dir,sp,ha) local l=Instance.new("UIListLayout",p); l.FillDirection=dir or Enum.FillDirection.Vertical; l.Padding=UDim.new(0,sp or 6); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left; return l end

-- janela
local WIN=Instance.new("Frame",SG)
WIN.Size=UDim2.new(0,660,0,500); WIN.Position=UDim2.new(0.5,-330,0.5,-250)
WIN.BackgroundColor3=C.bg; WIN.BorderSizePixel=0; Rnd(WIN,12)
local ws=Str(WIN,C.bord,1.5)
local wg=Instance.new("UIGradient",ws)
wg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,C.acc),ColorSequenceKeypoint.new(0.5,C.bord),ColorSequenceKeypoint.new(1,C.acc)}
wg.Rotation=90

-- topbar
local Top=Instance.new("Frame",WIN)
Top.Size=UDim2.new(1,0,0,44); Top.BackgroundColor3=C.side; Top.BorderSizePixel=0; Rnd(Top,12)

local TopLine=Instance.new("Frame",Top)
TopLine.Size=UDim2.new(1,0,0,2); TopLine.Position=UDim2.new(0,0,1,-2)
TopLine.BackgroundColor3=C.acc; TopLine.BorderSizePixel=0
local tlg=Instance.new("UIGradient",TopLine)
tlg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,C.acc),ColorSequenceKeypoint.new(0.5,C.acc2),ColorSequenceKeypoint.new(1,C.acc)}

local Dot=Instance.new("Frame",Top)
Dot.Size=UDim2.new(0,3,0.5,0); Dot.Position=UDim2.new(0,12,0.25,0)
Dot.BackgroundColor3=C.acc; Dot.BorderSizePixel=0; Rnd(Dot,2)

local TLbl=Instance.new("TextLabel",Top)
TLbl.Size=UDim2.new(1,-120,0,24); TLbl.Position=UDim2.new(0,22,0,6)
TLbl.BackgroundTransparency=1; TLbl.Text="CHINA HUB FREE"
TLbl.TextColor3=C.text; TLbl.TextSize=14; TLbl.Font=Enum.Font.GothamBold
TLbl.TextXAlignment=Enum.TextXAlignment.Left

local SLbl=Instance.new("TextLabel",Top)
SLbl.Size=UDim2.new(1,-120,0,13); SLbl.Position=UDim2.new(0,22,0,28)
SLbl.BackgroundTransparency=1; SLbl.Text="King Legacy  v6.0"
SLbl.TextColor3=C.acc2; SLbl.TextSize=10; SLbl.Font=Enum.Font.Gotham
SLbl.TextXAlignment=Enum.TextXAlignment.Left

local function WBtn(lbl,col,off)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,off,0.5,-11)
    b.BackgroundColor3=col; b.Text=lbl; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,5); return b
end
local CBtn=WBtn("X",C.red,-8)
local MBtn=WBtn("_",Color3.fromRGB(50,100,180),-36)

local drag,dI,dS,dP
Top.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; dS=i.Position; dP=WIN.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
Top.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dI=i end end)
UserInputService.InputChanged:Connect(function(i)
    if i==dI and drag then local d=i.Position-dS; WIN.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y) end
end)
CBtn.MouseButton1Click:Connect(function() Farm.Active=false; AutoAttack=false; SetCollision(true); SG:Destroy() end)
local mini=false
MBtn.MouseButton1Click:Connect(function()
    mini=not mini
    for _,c in ipairs(WIN:GetChildren()) do if c~=Top then c.Visible=not mini end end
    WIN.Size=mini and UDim2.new(0,660,0,44) or UDim2.new(0,660,0,500)
    MBtn.Text=mini and "+" or "_"
end)

-- layout
local Layout=Instance.new("Frame",WIN)
Layout.Position=UDim2.new(0,0,0,44); Layout.Size=UDim2.new(1,0,1,-44)
Layout.BackgroundTransparency=1

-- sidebar
local SB=Instance.new("Frame",Layout)
SB.Size=UDim2.new(0,150,1,0); SB.BackgroundColor3=C.side; SB.BorderSizePixel=0

local sbList=Lst(SB,Enum.FillDirection.Vertical,0)
Pad(SB,0,0,8,8)

-- user card
local UC=Instance.new("Frame",SB)
UC.Size=UDim2.new(1,0,0,58); UC.BackgroundColor3=C.card; UC.BorderSizePixel=0; UC.LayoutOrder=0
local ucBar=Instance.new("Frame",UC); ucBar.Size=UDim2.new(0,3,0.6,0); ucBar.Position=UDim2.new(0,0,0.2,0); ucBar.BackgroundColor3=C.acc; ucBar.BorderSizePixel=0
local ucN=Instance.new("TextLabel",UC); ucN.Size=UDim2.new(1,-12,0,20); ucN.Position=UDim2.new(0,10,0,8); ucN.BackgroundTransparency=1; ucN.Text=LP.DisplayName; ucN.TextColor3=C.text; ucN.TextSize=12; ucN.Font=Enum.Font.GothamBold; ucN.TextXAlignment=Enum.TextXAlignment.Left
local ucLv=Instance.new("TextLabel",UC); ucLv.Size=UDim2.new(1,-12,0,14); ucLv.Position=UDim2.new(0,10,0,32); ucLv.BackgroundTransparency=1; ucLv.TextColor3=C.acc2; ucLv.TextSize=10; ucLv.Font=Enum.Font.Gotham; ucLv.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function() while SG.Parent do task.wait(2); ucLv.Text="Level  "..GetLevel() end end)

local sdiv=Instance.new("Frame",SB); sdiv.Size=UDim2.new(1,0,0,1); sdiv.BackgroundColor3=C.sep; sdiv.BorderSizePixel=0; sdiv.LayoutOrder=1

-- conteudo
local Con=Instance.new("Frame",Layout)
Con.Position=UDim2.new(0,150,0,0); Con.Size=UDim2.new(1,-150,1,0)
Con.BackgroundColor3=C.panel; Con.BorderSizePixel=0

local CS=Instance.new("ScrollingFrame",Con)
CS.Size=UDim2.new(1,0,1,0); CS.BackgroundTransparency=1
CS.ScrollBarThickness=3; CS.ScrollBarImageColor3=C.acc
CS.CanvasSize=UDim2.new(0,0,0,0); CS.AutomaticCanvasSize=Enum.AutomaticSize.Y
Pad(CS,12,12,10,10); Lst(CS,Enum.FillDirection.Vertical,8)

local Pages,TabBtns={},{}
local function MkPage(id)
    local pg=Instance.new("Frame",CS)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false
    Lst(pg,Enum.FillDirection.Vertical,6)
    Pages[id]=pg; return pg
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

local Tabs={"FARM","ESP","TELEPORT","MISC","WEBHOOK"}
for i,name in ipairs(Tabs) do
    MkPage(name)
    local btn=Instance.new("TextButton",SB)
    btn.Name=name; btn.Size=UDim2.new(1,0,0,36)
    btn.BackgroundTransparency=1; btn.Text=""; btn.LayoutOrder=i+2
    local ad=Instance.new("Frame",btn); ad.Name="AD"
    ad.Size=UDim2.new(0,3,0.5,0); ad.Position=UDim2.new(0,0,0.25,0)
    ad.BackgroundColor3=C.acc; ad.BorderSizePixel=0; ad.Visible=false; Rnd(ad,2)
    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=C.dim
    lbl.TextSize=11; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    TabBtns[name]=btn
    btn.MouseButton1Click:Connect(function() Switch(name) end)
end

-- helpers UI
local function Sec(p,t)
    local row=Instance.new("Frame",p); row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1
    local line=Instance.new("Frame",row); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1); line.BackgroundColor3=C.sep; line.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,0,1,-2); lbl.BackgroundTransparency=1; lbl.Text=t; lbl.TextColor3=C.acc2; lbl.TextSize=10; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
end
local function Tog(p,t,def,cb)
    local row=Instance.new("Frame",p); row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=C.card; row.BorderSizePixel=0; Rnd(row,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=t; lbl.TextColor3=C.text; lbl.TextSize=12; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
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
local function Btn(p,t,cb,acc)
    local b=Instance.new("TextButton",p); b.Size=UDim2.new(1,0,0,36)
    b.BackgroundColor3=acc and C.acc or C.card; b.Text=t; b.TextColor3=C.text
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,6)
    if not acc then Str(b,C.bord,1) end
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=acc and C.acc2 or C.cardH}):Play()
        task.delay(0.14,function() if b and b.Parent then TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=acc and C.acc or C.card}):Play() end end)
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

-- ============================================================
--  FARM PAGE
-- ============================================================
do
    local pg=Pages["FARM"]

    -- status
    local sf=Instance.new("Frame",pg)
    sf.Size=UDim2.new(1,0,0,48); sf.BackgroundColor3=Color3.fromRGB(10,20,14)
    sf.BorderSizePixel=0; Rnd(sf,8); Str(sf,Color3.fromRGB(28,78,44),1)
    local sd=Instance.new("Frame",sf); sd.Size=UDim2.new(0,8,0,8); sd.Position=UDim2.new(0,12,0.5,-4); sd.BackgroundColor3=C.red; sd.BorderSizePixel=0; Rnd(sd,4)
    local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,-30,1,0); sl.Position=UDim2.new(0,26,0,0); sl.BackgroundTransparency=1; sl.Text="Inativo"; sl.TextColor3=C.green; sl.TextSize=11; sl.Font=Enum.Font.GothamBold; sl.TextXAlignment=Enum.TextXAlignment.Left
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=Farm.Active and Farm.StatusText or "Inativo"
        sd.BackgroundColor3=Farm.Active and C.green or C.red
    end end)

    Sec(pg,"AUTO FARM")
    Tog(pg,"Auto Farm (Quest + Mob-Lock Aereo)",false,function(v)
        Farm.Active=v; if not v then Farm.State="idle"; SetCollision(true) end
    end)
    Tog(pg,"Aceitar Quest automaticamente",true,function(v) Farm.UseQuest=v end)

    -- estilo
    Sec(pg,"ESTILO DE LUTA")
    local sRow=Instance.new("Frame",pg); sRow.Size=UDim2.new(1,0,0,40); sRow.BackgroundTransparency=1
    Lst(sRow,Enum.FillDirection.Horizontal,6,Enum.HorizontalAlignment.Left)
    local sBtns={}
    local stList={{"melee","MELEE"},{"sword","SWORD"},{"fruit","FRUIT"}}
    local function SetSt(key)
        Farm.Style=key
        for _,sb in ipairs(sBtns) do local a=sb[1]==key
            TweenService:Create(sb[2],TweenInfo.new(0.14),{BackgroundColor3=a and C.acc or C.card}):Play()
            sb[3].TextColor3=a and Color3.new(1,1,1) or C.dim
            sb[3].Font=a and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    for _,st in ipairs(stList) do
        local b=Instance.new("TextButton",sRow); b.Size=UDim2.new(0,120,1,0); b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=st[1]=="melee" and C.acc or C.card; Rnd(b,6)
        if st[1]~="melee" then Str(b,C.bord,1) end
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=st[2]; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=st[1]=="melee" and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=st[1]=="melee" and Color3.new(1,1,1) or C.dim
        table.insert(sBtns,{st[1],b,l}); b.MouseButton1Click:Connect(function() SetSt(st[1]) end)
    end

    -- config
    Sec(pg,"CONFIGURACAO")
    Lbl(pg,"  Altura hover acima do mob (studs):")
    local hI=Inp(pg,"5",function(v) local n=tonumber(v); if n and n>0 then Farm.HoverY=n end end); hI.Text="5"
    Lbl(pg,"  Mobs por ciclo:")
    local kI=Inp(pg,"10",function(v) local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end end); kI.Text="10"

    -- calibrar
    Sec(pg,"CALIBRAR ZONAS")
    Lbl(pg,"  Va ate o ponto no jogo e clique calibrar.")
    local selIdx=1
    local selL=Instance.new("TextLabel",pg); selL.Size=UDim2.new(1,0,0,30); selL.BackgroundColor3=C.card
    selL.BorderSizePixel=0; Rnd(selL,6); Pad(selL,10,0,0,0)
    selL.Text=Zones[1].name.."  Lv "..Zones[1].minLv.."-"..Zones[1].maxLv
    selL.TextColor3=C.acc2; selL.TextSize=11; selL.Font=Enum.Font.GothamBold; selL.TextXAlignment=Enum.TextXAlignment.Left

    local aRow=Instance.new("Frame",pg); aRow.Size=UDim2.new(1,0,0,32); aRow.BackgroundTransparency=1
    Lst(aRow,Enum.FillDirection.Horizontal,6)
    local function ABtn(t,cb2)
        local b=Instance.new("TextButton",aRow); b.Size=UDim2.new(0.5,-3,1,0)
        b.BackgroundColor3=C.card; b.Text=t; b.TextColor3=C.text; b.TextSize=11
        b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; Rnd(b,6); Str(b,C.bord,1)
        b.MouseButton1Click:Connect(cb2)
    end
    ABtn("< ANTERIOR",function()
        selIdx=math.max(1,selIdx-1); local z=Zones[selIdx]
        selL.Text=z.name.."  Lv "..z.minLv.."-"..z.maxLv
    end)
    ABtn("PROXIMA >",function()
        selIdx=math.min(#Zones,selIdx+1); local z=Zones[selIdx]
        selL.Text=z.name.."  Lv "..z.minLv.."-"..z.maxLv
    end)
    Btn(pg,"CALIBRAR POSICAO DO NPC QUEST",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].islePos=pos
        sl.Text=("OK islePos [%s] = %.0f,%.0f,%.0f"):format(Zones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Btn(pg,"CALIBRAR POSICAO DOS MOBS",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].mobPos=pos; Zones[selIdx].islePos=pos
        sl.Text=("OK mobPos [%s] = %.0f,%.0f,%.0f"):format(Zones[selIdx].name,pos.X,pos.Y,pos.Z)
    end)
    Btn(pg,"COPIAR POSICAO ATUAL",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(s) end); sl.Text="Copiado: "..s
        end
    end)

    Sec(pg,"ZONAS")
    for _,z in ipairs(Zones) do
        Lbl(pg,("  Lv %4d-%-4d  %s"):format(z.minLv,z.maxLv,z.name))
    end
end

-- ============================================================
--  ESP
-- ============================================================
do
    local pg=Pages["ESP"]
    Sec(pg,"JOGADORES")
    Tog(pg,"Player ESP",         false,function(v) Cfg.PlayerESP=v end)
    Tog(pg,"Mostrar Distancia",  true, function(v) Cfg.ShowDist=v end)
    Tog(pg,"Tracer Lines",       false,function(v) Cfg.TracerLines=v end)
    Sec(pg,"FRUTAS")
    Tog(pg,"Fruit ESP",          false,function(v) Cfg.FruitESP=v end)
    Sec(pg,"RANGE")
    Lbl(pg,"  Distancia maxima (studs):")
    local rI=Inp(pg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end); rI.Text="2000"
end

-- ============================================================
--  TELEPORT
-- ============================================================
do
    local pg=Pages["TELEPORT"]
    Sec(pg,"FRUTAS")
    Btn(pg,"Ir para Fruta Mais Proxima",TP_NearestFruit,true)
    Sec(pg,"JOGADORES")
    Lbl(pg,"  Nome do jogador:")
    local pI=Inp(pg,"username...")
    Btn(pg,"Ir para Jogador",function() TP_Player(pI.Text) end)
    Btn(pg,"Listar Online",function()
        local n={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
        pI.Text=table.concat(n,", ")
    end)
    Sec(pg,"COORDENADAS")
    Lbl(pg,"  X, Y, Z separados por virgula:")
    local cI=Inp(pg,"0, 100, 0")
    Btn(pg,"Ir para Coordenadas",function()
        local t=string.split(cI.Text,",")
        local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Btn(pg,"Copiar Posicao Atual",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z)
            pcall(function() setclipboard(s) end); cI.Text=s
        end
    end)
    Sec(pg,"ILHAS RAPIDAS")
    local isles={
        {"Starter Island",Vector3.new(-2044,100,-4591)},
        {"Pirate Island", Vector3.new(-681,64,-3449)},
        {"Soldier Island",Vector3.new(990,28,-510)},
        {"Shark Island",  Vector3.new(1822,28,1492)},
        {"Chef Ship",     Vector3.new(-792,28,1242)},
        {"Snow Island",   Vector3.new(1622,28,-872)},
        {"Sand Kingdom",  Vector3.new(-3052,28,1978)},
        {"Sky Island",    Vector3.new(-2822,865,-1632)},
    }
    for _,il in ipairs(isles) do
        Btn(pg,il[1],function() SafeTP(il[2]) end)
    end
end

-- ============================================================
--  MISC
-- ============================================================
do
    local pg=Pages["MISC"]
    Sec(pg,"COMBATE")
    Tog(pg,"Auto Ataque Livre (hover)",false,function(v) AutoAttack=v end)
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
    Sec(pg,"VELOCIDADE")
    Lbl(pg,"  Walk Speed (padrao 16):"); Inp(pg,"16",function(v) local n=tonumber(v); local c=LP.Character; if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end end)
    Lbl(pg,"  Jump Power (padrao 50):"); Inp(pg,"50",function(v) local n=tonumber(v); local c=LP.Character; if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end end)
    Sec(pg,"UTILITARIOS")
    Btn(pg,"Restaurar Colisao",    function() SetCollision(true) end)
    Btn(pg,"Recarregar Personagem",function() SetCollision(true); LP:LoadCharacter() end)
end

-- ============================================================
--  WEBHOOK
-- ============================================================
do
    local pg=Pages["WEBHOOK"]
    Sec(pg,"URL DISCORD")
    Inp(pg,"https://discord.com/api/webhooks/...",function(v) Cfg.WHUrl=v end)
    local function WH(t,d,col)
        if not Cfg.WHUrl or Cfg.WHUrl=="" then return end
        local req=syn and syn.request or (http and http.request) or request; if not req then return end
        pcall(req,{Url=Cfg.WHUrl,Method="POST",Headers={["Content-Type"]="application/json"},
            Body=HttpService:JSONEncode({username="China Hub Free",embeds={{title=t,description=d,color=col or 16777215,footer={text="KL | "..LP.Name},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})})
    end
    Sec(pg,"ENVIO")
    Lbl(pg,"  Titulo:"); local wt=Inp(pg,"Titulo...")
    Lbl(pg,"  Mensagem:"); local wm=Inp(pg,"Mensagem...")
    Btn(pg,"Enviar",function() WH(wt.Text,wm.Text,3447003) end,true)
    Btn(pg,"Testar",function() WH("Teste OK","Conectado: **"..LP.Name.."**",65280) end)
end

-- ============================================================
--  ESP UPDATE
-- ============================================================
local PLR_ESP={}
local function MkESP(pl)
    if pl==LP or PLR_ESP[pl] then return end
    PLR_ESP[pl]={box=NBox(Cfg.Col_P),name=NTxt(Cfg.Col_P,13),dist=NTxt(Color3.new(1,1,1),11),hpBg=NBox(Color3.fromRGB(38,38,38),true),hpBar=NBox(Color3.fromRGB(55,205,100),true),tracer=NLine(Cfg.Col_P)}
end
local function KillESP(pl)
    if PLR_ESP[pl] then for _,o in pairs(PLR_ESP[pl]) do pcall(function() o:Remove() end) end; PLR_ESP[pl]=nil end
end
local FPool={}
local function ClearFPool()
    for _,o in pairs(FPool) do
        if o.lbl then pcall(function() o.lbl:Remove() end) end
        if o.d   then pcall(function() o.d:Remove()   end) end
    end; table.clear(FPool)
end

local function UpdP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LP then continue end
        if not PLR_ESP[pl] then MkESP(pl) end
        local obj=PLR_ESP[pl]; if not obj then continue end
        local char=pl.Character
        if not Cfg.PlayerESP or not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            for _,o in pairs(obj) do o.Visible=false end; continue
        end
        local hrp=char.HumanoidRootPart; local hum=char.Humanoid
        local d=Dist(hrp.Position); if d>Cfg.ESPRange then for _,o in pairs(obj) do o.Visible=false end; continue end
        local t2D,_,tV=W2V(hrp.Position+Vector3.new(0,3.2,0)); local b2D,_,bV=W2V(hrp.Position-Vector3.new(0,2.8,0))
        if not tV and not bV then for _,o in pairs(obj) do o.Visible=false end; continue end
        local bH=math.abs(t2D.Y-b2D.Y); local bW=bH*0.55; local bX=t2D.X-bW/2
        obj.box.Size=Vector2.new(bW,bH); obj.box.Position=Vector2.new(bX,t2D.Y); obj.box.Color=Cfg.Col_P; obj.box.Visible=true
        obj.name.Text=pl.DisplayName; obj.name.Position=Vector2.new(t2D.X,t2D.Y-16); obj.name.Color=Cfg.Col_P; obj.name.Visible=true
        obj.dist.Text=d.."m"; obj.dist.Position=Vector2.new(t2D.X,t2D.Y-28); obj.dist.Visible=Cfg.ShowDist
        local hp=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        obj.hpBg.Size=Vector2.new(4,bH); obj.hpBg.Position=Vector2.new(bX+bW+3,t2D.Y); obj.hpBg.Visible=true
        obj.hpBar.Size=Vector2.new(4,bH*hp); obj.hpBar.Position=Vector2.new(bX+bW+3,t2D.Y+bH*(1-hp)); obj.hpBar.Color=Color3.fromRGB(255*(1-hp),255*hp,0); obj.hpBar.Visible=true
        obj.tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); obj.tracer.To=b2D; obj.tracer.Color=Cfg.Col_P; obj.tracer.Visible=Cfg.TracerLines
    end
end
local function UpdF()
    ClearFPool(); if not Cfg.FruitESP then return end
    for _,f in ipairs(ScanFruits()) do
        local d=Dist(f.pos); if d>Cfg.ESPRange then continue end
        local p2D,_,onS=W2V(f.pos); if not onS then continue end
        local l=NTxt(Cfg.Col_F,13); l.Text="FRUIT "..f.name; l.Position=Vector2.new(p2D.X,p2D.Y-10); l.Visible=true
        local dl=NTxt(Color3.new(1,1,1),11); dl.Text=d.."m"; dl.Position=Vector2.new(p2D.X,p2D.Y+5); dl.Visible=true
        table.insert(FPool,{lbl=l,d=dl})
    end
end

-- show/hide
local SBtn=Instance.new("TextButton",SG)
SBtn.Size=UDim2.new(0,130,0,30); SBtn.Position=UDim2.new(0,20,0,55)
SBtn.BackgroundColor3=C.side; SBtn.Text="CHINA HUB FREE"; SBtn.TextColor3=C.acc2
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
local t2=0
RunService.RenderStepped:Connect(function()
    t2=t2+1; UpdP()
    if t2%14==0 then UpdF(); t2=0 end
end)

print("[China Hub Free v6.0] "..LP.Name)
