-- ============================================================
--  CHINA HUB FREE  v8.2  —  King Legacy Update 11
--  GUI rebuilt — tema preto sólido
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local VIM              = game:GetService("VirtualInputManager")
local RS               = game:GetService("ReplicatedStorage")
local TS               = game:GetService("TeleportService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local SEA_Y  = 15

-- ============================================================
--  LEVEL / BELI / STAT POINTS
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
--  ZONAS
-- ============================================================
local Zones = {
    {name="Starter Island",        minLv=1,    maxLv=49,
     islePos=Vector3.new(-2044,100,-4591), mobPos=Vector3.new(-2044,100,-4591), radius=400},
    {name="Pirate Island",         minLv=50,   maxLv=99,
     islePos=Vector3.new(-681,64,-3449),   mobPos=Vector3.new(-681,64,-3449),   radius=400},
    {name="Soldier Island",        minLv=100,  maxLv=179,
     islePos=Vector3.new(990,28,-510),     mobPos=Vector3.new(990,28,-510),     radius=400},
    {name="Shark Island",          minLv=180,  maxLv=249,
     islePos=Vector3.new(1822,28,1492),    mobPos=Vector3.new(1822,28,1492),    radius=400},
    {name="Chef Ship",             minLv=250,  maxLv=399,
     islePos=Vector3.new(-792,28,1242),    mobPos=Vector3.new(-792,28,1242),    radius=400},
    {name="Snow Island",           minLv=400,  maxLv=524,
     islePos=Vector3.new(1622,28,-872),    mobPos=Vector3.new(1622,28,-872),    radius=400},
    {name="Sand Kingdom",          minLv=525,  maxLv=799,
     islePos=Vector3.new(-3052,28,1978),   mobPos=Vector3.new(-3052,28,1978),   radius=400},
    {name="Sky Island",            minLv=800,  maxLv=999,
     islePos=Vector3.new(-2822,865,-1632), mobPos=Vector3.new(-2822,865,-1632), radius=400},
    {name="Bubble Island",         minLv=1000, maxLv=1499,
     islePos=Vector3.new(2552,28,-2058),   mobPos=Vector3.new(2552,28,-2058),   radius=400},
    {name="2nd Sea – Entrada",     minLv=1500, maxLv=2199,
     islePos=Vector3.new(0,100,0),         mobPos=Vector3.new(0,100,0),         radius=500, calibrate=true},
    {name="2nd Sea – Mid",         minLv=2200, maxLv=2999,
     islePos=Vector3.new(0,100,0),         mobPos=Vector3.new(0,100,0),         radius=500, calibrate=true},
    {name="3rd Sea – Inicio",      minLv=3000, maxLv=3799,
     islePos=Vector3.new(0,100,0),         mobPos=Vector3.new(0,100,0),         radius=600, calibrate=true},
    {name="3rd Sea – Mid",         minLv=3800, maxLv=4499,
     islePos=Vector3.new(0,100,0),         mobPos=Vector3.new(0,100,0),         radius=600, calibrate=true},
    {name="3rd Sea – End (Upd11)", minLv=4500, maxLv=9999,
     islePos=Vector3.new(0,100,0),         mobPos=Vector3.new(0,100,0),         radius=600, calibrate=true},
}
local function GetZone(lv)
    for _, z in ipairs(Zones) do
        if lv >= z.minLv and lv <= z.maxLv then return z end
    end
    return Zones[#Zones]
end

-- ============================================================
--  HALLOWEEN
-- ============================================================
local HalloweenPos = {[1]=Vector3.new(0,100,0),[2]=Vector3.new(0,100,0),[3]=Vector3.new(0,100,0)}

-- ============================================================
--  FRUTAS LENDÁRIAS
-- ============================================================
local LegendaryList = {
    "Pteranodon","Erebus","ErebusFruit","Loki","LokiFruit","Tree","TreeFruit",
    "Demon","DemonFruit","Dragon","DragonFruit","Toy","ToyFruit","Phoenix","PhoenixFruit",
    "Gold","GoldFruit","Dough","DoughFruit","Leopard","LeopardFruit","Portal","PortalFruit",
    "Gravity","GravityFruit","Shadow","ShadowFruit","Soul","SoulFruit","Control","ControlFruit",
    "Venom","VenomFruit","String","StringFruit","Gas","GasFruit","Surge","SurgeFruit",
    "Rumble","RumbleFruit","Barrier","BarrierFruit","Blizzard","BlizzardFruit",
    "Human","HumanFruit","Buddha","BuddhaFruit","Love","LoveFruit","Gate","GateFruit","Giraffe","GiraffeFruit",
}
local function IsFruitLegendary(obj)
    local rarV = obj:FindFirstChild("Rarity") or obj:FindFirstChild("Raridade")
        or obj:FindFirstChild("FruitRarity") or obj:FindFirstChild("Type")
    if rarV then
        local r = tostring(rarV.Value):lower()
        if r=="legendary" or r=="mythical" or r=="lendaria" or r=="mitica" then return true, rarV.Value end
    end
    for _, kw in ipairs(LegendaryList) do
        if obj.Name:lower():find(kw:lower()) then return true, "Legendary" end
    end
    return false, nil
end
local FruitKW = {
    "fruit","devil","gumgum","chop","smoke","flame","ice","magnet","light","dark","quake",
    "phoenix","dragon","rubb","sand","diamond","paw","gravity","string","shadow","portal",
    "control","venom","leopard","blizzard","gas","surge","rumble","barrier","soul","human",
    "buddha","love","dough","toy","tree","demon","erebus","loki","pteranodon","gold","bounce",
    "gate","giraffe","wolf",
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
--  MOB / BOSS
-- ============================================================
local function FindMob(nearPos, radius)
    local char = LP.Character; if not char then return nil end
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - nearPos).Magnitude
                if d < radius and d < bestD then bestD=d; best=obj end
            end
        end
    end
    return best, bestD
end
local function FindBoss(namePattern, searchRadius)
    searchRadius = searchRadius or 5000
    local char = LP.Character
    local origin = char and char:FindFirstChild("HumanoidRootPart")
        and char.HumanoidRootPart.Position or Vector3.new(0,0,0)
    local best, bestD = nil, math.huge
    local pat = namePattern:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and not Players:GetPlayerFromCharacter(obj)
           and obj.Name:lower():find(pat) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - origin).Magnitude
                if d < searchRadius and d < bestD then bestD=d; best=obj end
            end
        end
    end
    return best, bestD
end

-- ============================================================
--  TELEPORTE
-- ============================================================
local function SafeTP(pos)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(pos.X, math.max(pos.Y+5,60), pos.Z))
    task.wait(1.2)
    return char.HumanoidRootPart.Position.Y >= SEA_Y
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
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    table.sort(fruits, function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end
local function TP_NearestLegendary()
    local fruits = ScanFruits(); local legs={}
    for _, f in ipairs(fruits) do if f.legendary then table.insert(legs,f) end end
    if #legs == 0 then return false end
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    table.sort(legs, function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(legs[1].pos); return true, legs[1]
end

-- ============================================================
--  NTT JOIN
-- ============================================================
local function JoinNTT(raw)
    local code = raw:match("privateServerLinkCode=([^&%s\n\r]+)") or raw:gsub("%s+","")
    if code == "" then return false, "código vazio" end
    local ok, err = pcall(function() TS:TeleportToPrivateServer(game.PlaceId, code) end)
    return ok, err
end

-- ============================================================
--  COLISÃO / QUEST / TOOLS
-- ============================================================
local function SetCollision(v)
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = v end
    end
end
local questRF = nil
local function TryGetRF()
    if questRF then return questRF end
    local paths = {
        {"Chest","Functions","Quest"},{"Remotes","Quest"},
        {"RemoteEvents","Quest"},{"Functions","Quest"},{"RemoteFunctions","Quest"},
    }
    for _, p in ipairs(paths) do
        local cur = RS; local ok = true
        for _, seg in ipairs(p) do
            local nxt = cur:FindFirstChild(seg)
            if not nxt then ok=false; break end; cur=nxt
        end
        if ok then questRF=cur; return questRF end
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
            local isBoat = false; local cur = part
            for _ = 1, 6 do
                cur = cur.Parent; if not cur then break end
                local n = cur.Name:lower()
                if n:find("boat") or n:find("ship") or n:find("navio") then isBoat=true; break end
            end
            if isBoat then continue end
            local at = (obj.ActionText or ""):lower(); local ot = (obj.ObjectText or ""):lower()
            if at:find("quest") or at:find("miss") or at:find("interag") or ot:find("quest")
               or at:find("summon") or at:find("invoke") or at:find("candy") then
                best=obj; bestD=d
            end
            local model = part.Parent
            if model and model:IsA("Model") and (model.Name:lower():find("quest")
               or model.Name:lower():find("altar") or model.Name:lower():find("grave")) then
                best=obj; bestD=d
            end
        end
    end
    return best
end
local function FirePP(pp) if pp then pcall(function() fireproximityprompt(pp) end) end end
local function EquipFirst(style)
    local char = LP.Character; if not char then return end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if style=="sword" then
                if n:find("sword") or n:find("katana") or n:find("blade")
                   or n:find("cutlass") or n:find("saber") or n:find("broom") then
                    char.Humanoid:EquipTool(t); task.wait(0.25); return
                end
            else char.Humanoid:EquipTool(t); task.wait(0.25); return end
        end
    end
end
local function PressKey(kc)
    pcall(function()
        if syn and syn.key_press then syn.key_press(kc); task.wait(0.07); syn.key_release(kc)
        elseif keypress then keypress(kc); task.wait(0.07); if keyrelease then keyrelease(kc) end end
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
    char.HumanoidRootPart.CFrame = CFrame.lookAt(hrp.Position+Vector3.new(0,hoverY,0), hrp.Position)
    local c2 = LP.Character
    if c2 then for _, p in ipairs(c2:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    if style=="fruit" then PressKey(0x5A); task.wait(0.05); PressKey(0x58)
    elseif style=="sword" then EquipFirst("sword") end
    local sp, _, onScr = Camera:WorldToViewportPoint(hrp.Position)
    if onScr then
        local x, y = math.floor(sp.X), math.floor(sp.Y)
        VIM:SendMouseButtonEvent(x,y,0,true,game,0); task.wait(0.06)
        VIM:SendMouseButtonEvent(x,y,0,false,game,0)
    end
    task.wait(0.05)
    local c3 = LP.Character
    if c3 then for _, p in ipairs(c3:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
end

-- ============================================================
--  HITBOX / FLY
-- ============================================================
local HitboxCon = nil
local function SetHitbox(v, size)
    if HitboxCon then HitboxCon:Disconnect(); HitboxCon=nil end
    if not v then return end
    HitboxCon = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Size=Vector3.new(size,size,size) end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hrp=obj:FindFirstChild("HumanoidRootPart")
                local hum=obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health>0 then hrp.Size=Vector3.new(size,size,size) end
            end
        end
    end)
end
local flyEnabled=false; local flyBody=nil; local flySpeed=80
local function SetFly(v, spd)
    flyEnabled=v; spd=spd or flySpeed
    local char=LP.Character; if not char then return end
    if not v then
        if flyBody then flyBody:Destroy(); flyBody=nil end
        local c2=LP.Character
        if c2 then
            for _, p in ipairs(c2:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
            local hum=c2:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        return
    end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if flyBody then flyBody:Destroy() end
    flyBody=Instance.new("BodyVelocity"); flyBody.Parent=hrp
    flyBody.Velocity=Vector3.new(0,0,0); flyBody.MaxForce=Vector3.new(1,1,1)*1e5
    task.spawn(function()
        while flyEnabled and flyBody and flyBody.Parent do
            task.wait()
            local c2=LP.Character; if not c2 then break end
            local h2=c2:FindFirstChild("HumanoidRootPart"); if not h2 then break end
            local cam=Camera.CFrame; local dir=Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
            flyBody.Velocity = dir.Magnitude>0 and dir.Unit*spd or Vector3.new(0,0,0)
        end
    end)
end
LP.CharacterAdded:Connect(function() flyBody=nil; if flyEnabled then task.wait(1); SetFly(true) end end)
local function ServerHop() pcall(function() TS:Teleport(game.PlaceId) end) end

-- ============================================================
--  AUTO STATS / HAKI
-- ============================================================
local AutoStats={Active=false,Str=0,Def=0,Agi=0,Health=0,Fruit=100}
local statRemotes={}
local function FindStatRFs()
    if next(statRemotes) then return true end
    for _, name in ipairs({"AddStat","AddPoint","StatAdd","UpgradeStat","Upgrade","AddStr","AddDef","AddAgi","AddHP","AddFruit"}) do
        local rf=RS:FindFirstChild(name, true); if rf then statRemotes[name]=rf end
    end
    return next(statRemotes)~=nil
end
local statNames={Str={"Str","Strength","STR"},Def={"Def","Defense","DEF"},
                 Agi={"Agi","Speed","AGI"},Health={"HP","Health"},Fruit={"Fruit","Devil","FruitPow"}}
local function AddStat(statKey, amount)
    amount=amount or 1; FindStatRFs()
    for _, rf in pairs(statRemotes) do
        for _, ss in ipairs(statNames[statKey] or {statKey}) do
            pcall(function()
                if rf:IsA("RemoteFunction") then rf:InvokeServer(ss,amount)
                elseif rf:IsA("RemoteEvent") then rf:FireServer(ss,amount) end
            end)
        end
    end
end
task.spawn(function()
    while true do
        task.wait(0.5); if not AutoStats.Active then continue end
        local pts=GetStatPoints(); if pts<=0 then continue end
        local total=AutoStats.Str+AutoStats.Def+AutoStats.Agi+AutoStats.Health+AutoStats.Fruit
        if total<=0 then continue end
        local roll=math.random(1,total); local acc=0
        local function pick(key,val) acc=acc+val; if roll<=acc then AddStat(key) end end
        pick("Str",AutoStats.Str); pick("Def",AutoStats.Def)
        pick("Agi",AutoStats.Agi); pick("Health",AutoStats.Health); pick("Fruit",AutoStats.Fruit)
    end
end)
local AutoHaki={Buso=false,Ken=false}
task.spawn(function()
    while true do
        task.wait(2); if not (AutoHaki.Buso or AutoHaki.Ken) then continue end
        local char=LP.Character; if not char then continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
        if AutoHaki.Buso then PressKey(0x51) end
        if AutoHaki.Ken  then PressKey(0x45) end; task.wait(0.1)
    end
end)

-- ============================================================
--  HALLOWEEN LOOP
-- ============================================================
local Halloween={Active=false,Mode="candy",Sea=1,StatusText="Inativo",Style="melee",HoverY=6,AutoSummonJO=false}
local function ScanCandyMob()
    local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local origin=char.HumanoidRootPart.Position
    local candyMobs={"zombie","skeleton","skull","gorilla","pumpkin","ghost","bat","witch"}
    local best,bestD=nil,math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj~=char and not Players:GetPlayerFromCharacter(obj) then
            local n=obj.Name:lower(); local isCandyMob=false
            for _, kw in ipairs(candyMobs) do if n:find(kw) then isCandyMob=true; break end end
            if isCandyMob then
                local hum=obj:FindFirstChildOfClass("Humanoid"); local hrp=obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then
                    local d=(hrp.Position-origin).Magnitude
                    if d<500 and d<bestD then bestD=d; best=obj end
                end
            end
        end
    end
    return best
end
task.spawn(function()
    while true do
        task.wait(0.3); if not Halloween.Active then continue end
        local char=LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(3); continue end
        local hPos=HalloweenPos[Halloween.Sea]
        if Halloween.Mode=="candy" then
            local mob=ScanCandyMob()
            if mob then
                AttackMob(mob,Halloween.HoverY,Halloween.Style)
                local h=mob:FindFirstChildOfClass("Humanoid")
                Halloween.StatusText=("🍬 Candy | %s | HP %d"):format(mob.Name,h and math.floor(h.Health) or 0)
            else SafeTP(hPos); Halloween.StatusText="🍬 Aguardando mobs..."; task.wait(2) end
        elseif Halloween.Mode=="jacko" then
            local boss,dist=FindBoss("Jack",3000)
            if not boss then boss,dist=FindBoss("Lantern",3000) end
            if not boss then boss,dist=FindBoss("Pumpkin",3000) end
            if boss then
                local h=boss:FindFirstChildOfClass("Humanoid"); AttackMob(boss,Halloween.HoverY,Halloween.Style)
                Halloween.StatusText=("🎃 Jack | HP %d | %.0fm"):format(h and math.floor(h.Health) or 0,dist or 0)
            else SafeTP(hPos); Halloween.StatusText="🎃 Summonando..."
                if Halloween.AutoSummonJO then local pp=FindQuestPrompt(hPos,80); if pp then FirePP(pp); task.wait(0.5) end end
                task.wait(3) end
        elseif Halloween.Mode=="skullking" then
            local boss,dist=FindBoss("Skull",3000); if not boss then boss,dist=FindBoss("SkullKing",3000) end
            if boss then
                AttackMob(boss,Halloween.HoverY,Halloween.Style); local h=boss:FindFirstChildOfClass("Humanoid")
                Halloween.StatusText=("💀 Skull | HP %d | %.0fm"):format(h and math.floor(h.Health) or 0,dist or 0)
            else SafeTP(hPos); Halloween.StatusText="💀 Skull King | Spawn 1h..."; task.wait(5) end
        elseif Halloween.Mode=="depthking" then
            local boss,dist=FindBoss("Depth",10000); if not boss then boss,dist=FindBoss("DepthKing",10000) end
            if boss then
                local hrp=boss:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y>SEA_Y then
                    AttackMob(boss,Halloween.HoverY+10,Halloween.Style); local h=boss:FindFirstChildOfClass("Humanoid")
                    Halloween.StatusText=("🐢 Depth | HP %d | %.0fm"):format(h and math.floor(h.Health) or 0,dist or 0)
                end
            else Halloween.StatusText="🐢 Depth King | Procurando..."; task.wait(4) end
        end
    end
end)

-- ============================================================
--  FARM LOOP
-- ============================================================
local Farm={Active=false,State="idle",StatusText="Inativo",Style="melee",KillCount=0,
            TargetKills=10,HoverY=5,Zone=nil,UseQuest=true,KillAura=false,KillAuraRange=200}
task.spawn(function()
    while true do
        task.wait(0.25)
        if not Farm.Active then Farm.State="idle"; SetCollision(true); continue end
        local char=LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then SetCollision(true); Farm.StatusText="Respawnando..."; Farm.State="idle"; task.wait(4); continue end
        local lv=GetLevel(); local zone=GetZone(lv)
        if Farm.State=="idle" then
            Farm.Zone=zone; Farm.KillCount=0
            Farm.StatusText=("Lv %d | %s | Viajando"):format(lv,zone.name); Farm.State="tozone"
        elseif Farm.State=="tozone" then
            if zone.calibrate then Farm.StatusText="CALIBRAR: "..zone.name; Farm.Active=false; Farm.State="idle"; continue end
            local ok=SafeTP(Farm.Zone.mobPos); if not ok then continue end
            if Farm.UseQuest then
                local questDescs={[1]="Kill 4 Soldiers",[50]="Kill 6 Clown Swordman",[100]="Kill 8 Marines",
                    [140]="Kill 1 Ax-Hand Morgan",[180]="Kill 8 Fish Pirates",[225]="Kill 1 Arlong",
                    [250]="Kill 8 Don Krieg Pirates",[400]="Kill 8 Snow Soldiers",[525]="Kill 8 Sand Pirates",[800]="Kill 8 Sky Warriors"}
                local desc=nil; local bestT=-1
                for threshold,d in pairs(questDescs) do if lv>=threshold and threshold>bestT then bestT=threshold; desc=d end end
                if desc then TakeQuestRF(desc); task.wait(0.5) end
                local pp=FindQuestPrompt(Farm.Zone.islePos,350)
                if pp then FirePP(pp); task.wait(0.4); FirePP(pp); task.wait(0.3) end
            end
            if Farm.Style=="sword" then EquipFirst("sword") end
            Farm.State="fighting"; Farm.KillCount=0
            Farm.StatusText=("Lv %d | %s | Lutando"):format(lv,zone.name)
        elseif Farm.State=="fighting" then
            local mob=FindMob(Farm.Zone.mobPos, Farm.Zone.radius)
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                local hrp=mob.HumanoidRootPart
                if hrp.Position.Y<SEA_Y then task.wait(0.3); continue end
                local hB=mob:FindFirstChildOfClass("Humanoid"); local hpB=hB and hB.Health or 0
                AttackMob(mob,Farm.HoverY,Farm.Style); task.wait(0.15)
                local hA=mob:FindFirstChildOfClass("Humanoid")
                if not hA or hA.Health<=0 then if hpB>0 then Farm.KillCount=Farm.KillCount+1 end end
                Farm.StatusText=("Lv %d | %s | %d/%d kills | HP %d"):format(
                    lv,zone.name,Farm.KillCount,Farm.TargetKills,hA and math.floor(hA.Health) or 0)
                if Farm.KillCount>=Farm.TargetKills then SetCollision(true); Farm.State="idle" end
            else
                SafeTP(Farm.Zone.mobPos)
                Farm.StatusText=("Lv %d | %s | Aguardando spawn..."):format(lv,zone.name)
                if Farm.KillCount>=Farm.TargetKills then SetCollision(true); Farm.State="idle" end
                task.wait(2)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.18); if not Farm.KillAura then continue end
        local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(2); continue end
        local mob=FindMob(char.HumanoidRootPart.Position, Farm.KillAuraRange)
        if mob then AttackMob(mob,Farm.HoverY,Farm.Style) end
    end
end)

-- ============================================================
--  BOSS LOOP
-- ============================================================
local BossConfig={Active=false,StatusText="Inativo",Style="melee",HoverY=5,SelectedBoss="Depth King"}
local BossList={
    {name="Depth King",    pattern="Depth",    range=10000, notes="Upd11 | 3° Mar",      tag="sea3"},
    {name="Skull King",    pattern="Skull",    range=3000,  notes="Halloween | 1h",       tag="hall"},
    {name="Jack-o-Lantern",pattern="Jack",     range=3000,  notes="Halloween | 50 Candy", tag="hall"},
    {name="Drakenfyr",     pattern="Drakenfyr",range=12000, notes="3° Mar Event",          tag="sea3"},
    {name="Chaos Kraken",  pattern="Kraken",   range=12000, notes="3° Mar Event",          tag="sea3"},
    {name="Abyssal Tyrant",pattern="Abyssal",  range=12000, notes="3° Mar | 2h",           tag="sea3"},
    {name="Crab King",     pattern="Crab",     range=12000, notes="3° Mar Event",          tag="sea3"},
    {name="Pteranodon",    pattern="Pterano",  range=8000,  notes="Raid Upd10 | 2h",       tag="raid"},
    {name="Serpente",      pattern="Serpent",  range=8000,  notes="Raid | 1h30",           tag="raid"},
    {name="Kaido",         pattern="Kaido",    range=5000,  notes="3° Mar",                tag=""},
    {name="Big Mom",       pattern="BigMom",   range=5000,  notes="3° Mar",                tag=""},
    {name="Sea King",      pattern="SeaKing",  range=8000,  notes="Legacy Island",         tag=""},
    {name="Hydra",         pattern="Hydra",    range=5000,  notes="Raid",                  tag=""},
    {name="Ghost Ship",    pattern="Ghost",    range=8000,  notes="2° Mar Event",          tag=""},
    {name="Arlong",        pattern="Arlong",   range=800,   notes="1° Mar",                tag=""},
    {name="Don Krieg",     pattern="Krieg",    range=800,   notes="1° Mar",                tag=""},
    {name="Ax-Hand Morgan",pattern="Morgan",   range=800,   notes="1° Mar",                tag=""},
}
task.spawn(function()
    while true do
        task.wait(0.3); if not BossConfig.Active then continue end
        local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(3); continue end
        local bossEntry=nil
        for _,b in ipairs(BossList) do if b.name==BossConfig.SelectedBoss then bossEntry=b; break end end
        if not bossEntry then task.wait(1); continue end
        local boss,dist=FindBoss(bossEntry.pattern, bossEntry.range)
        if boss then
            local hrp=boss:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y>SEA_Y then
                AttackMob(boss,BossConfig.HoverY,BossConfig.Style)
                local h=boss:FindFirstChildOfClass("Humanoid")
                BossConfig.StatusText=("%s | HP %d | %.0fm"):format(bossEntry.name,h and math.floor(h.Health) or 0,dist or 0)
            end
        else BossConfig.StatusText=bossEntry.name.." — procurando..."; task.wait(2) end
    end
end)

-- ============================================================
--  DUNGEON LOOP
-- ============================================================
local DungeonConfig={Active=false,StatusText="Inativo",Style="melee",HoverY=5,
                     Pos1=Vector3.new(0,100,0),Pos2=Vector3.new(0,100,0),Pos3=Vector3.new(0,100,0)}
task.spawn(function()
    while true do
        task.wait(0.3); if not DungeonConfig.Active then continue end
        local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(3); continue end
        local lv=GetLevel()
        local dunPos=lv>=3000 and DungeonConfig.Pos3 or (lv>=1500 and DungeonConfig.Pos2 or DungeonConfig.Pos1)
        local mob=FindMob(char.HumanoidRootPart.Position, 600)
        if mob then
            AttackMob(mob,DungeonConfig.HoverY,DungeonConfig.Style); local h=mob:FindFirstChildOfClass("Humanoid")
            DungeonConfig.StatusText=("Dungeon Lv%d | %s | HP %d"):format(lv,mob.Name,h and math.floor(h.Health) or 0)
        else
            DungeonConfig.StatusText=("Dungeon Lv%d | Procurando..."):format(lv)
            local pp=FindQuestPrompt(dunPos,500); if pp then FirePP(pp); task.wait(0.5) end; task.wait(1.5)
        end
    end
end)

-- ============================================================
--  SEA EVENT LOOP
-- ============================================================
local SeaEvent={Active=false,SeaBeast=true,GhostShip=false,Pteranodon=false,Serpent=false,
                StatusText="Inativo",Style="melee",HoverY=8}
task.spawn(function()
    while true do
        task.wait(0.3); if not SeaEvent.Active then continue end
        local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(3); continue end
        local target=nil
        if SeaEvent.SeaBeast then local b=FindBoss("SeaBeast",8000); if not b then b=FindBoss("Beast",8000) end; if b then target=b end end
        if not target and SeaEvent.GhostShip  then local g=FindBoss("Ghost",8000);   if g then target=g end end
        if not target and SeaEvent.Pteranodon  then local p=FindBoss("Pterano",8000); if p then target=p end end
        if not target and SeaEvent.Serpent     then local s=FindBoss("Serpent",8000); if s then target=s end end
        if target then
            AttackMob(target,SeaEvent.HoverY,SeaEvent.Style); local h=target:FindFirstChildOfClass("Humanoid")
            SeaEvent.StatusText=("Sea Event | %s | HP %d"):format(target.Name,h and math.floor(h.Health) or 0)
        else SeaEvent.StatusText="Sea Event | Aguardando spawn..."; task.wait(2) end
    end
end)

-- ============================================================
--  SEA HOOP LOOP
-- ============================================================
local AutoHoop={Active=false,StatusText="Inativo",TargetBoss="Depth King",ScanTime=10,
                FightOnFind=true,Style="melee",HoverY=8,_scanTimer=0,_found=false}
local HoopTargets={
    {name="Depth King",    pattern="Depth",    range=15000, notes="Tartaruga Upd11"},
    {name="Drakenfyr",     pattern="Drakenfyr",range=15000, notes="Dragon 3° Mar"},
    {name="Abyssal Tyrant",pattern="Abyssal",  range=15000, notes="Spawn 2h"},
    {name="Crab King",     pattern="Crab",     range=15000, notes="Caranguejo gigante"},
    {name="Chaos Kraken",  pattern="Kraken",   range=15000, notes="Kraken 3° Mar"},
}
task.spawn(function()
    while true do
        task.wait(0.4)
        if not AutoHoop.Active then AutoHoop._scanTimer=0; AutoHoop._found=false; continue end
        local char=LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then task.wait(3); continue end
        local entry=nil
        for _,t in ipairs(HoopTargets) do if t.name==AutoHoop.TargetBoss then entry=t; break end end
        if not entry then task.wait(1); continue end
        local boss,dist=FindBoss(entry.pattern, entry.range)
        if boss then
            AutoHoop._scanTimer=0; AutoHoop._found=true
            if AutoHoop.FightOnFind then
                local hrp=boss:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y>SEA_Y then
                    AttackMob(boss,AutoHoop.HoverY,AutoHoop.Style); local h=boss:FindFirstChildOfClass("Humanoid")
                    AutoHoop.StatusText=("✅ %s | HP %d | %.0fm"):format(entry.name,h and math.floor(h.Health) or 0,dist or 0)
                end
            else AutoHoop.StatusText=("✅ %s encontrado | %.0fm"):format(entry.name,dist or 0) end
        else
            AutoHoop._found=false; AutoHoop._scanTimer=AutoHoop._scanTimer+0.4
            AutoHoop.StatusText=("🔍 %s... %.0fs/%ds"):format(entry.name,AutoHoop._scanTimer,AutoHoop.ScanTime)
            if AutoHoop._scanTimer>=AutoHoop.ScanTime then
                boss=FindBoss(entry.pattern, entry.range)
                if boss then AutoHoop._scanTimer=0; continue end
                AutoHoop.StatusText="🔀 Hopping — sem "..entry.name
                AutoHoop._scanTimer=0; task.wait(0.5); ServerHop(); task.wait(6)
            end
        end
    end
end)

-- ============================================================
--  FRUIT NOTIFIER LOOP
-- ============================================================
local FruitNotifier={Active=false,ServerHopOnFind=false,NotifyAll=false,
                     LastNotified={},StatusText="Inativo",ScanInterval=3,AutoCollect=false}
task.spawn(function()
    while true do
        task.wait(FruitNotifier.ScanInterval); if not FruitNotifier.Active then continue end
        for _,f in ipairs(ScanFruits()) do
            if FruitNotifier.NotifyAll or f.legendary then
                local key=tostring(f.obj)..f.name
                if FruitNotifier.LastNotified[key] then continue end
                FruitNotifier.LastNotified[key]=true
                task.delay(60,function() FruitNotifier.LastNotified[key]=nil end)
                FruitNotifier.StatusText="🍎 "..f.name.." ("..(f.rarity or (f.legendary and "Legendary" or "Common"))..")"
                if FruitNotifier.AutoCollect then
                    TP(f.pos); task.wait(0.5); local pp=FindQuestPrompt(f.pos,20); if pp then FirePP(pp) end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(5); if not (FruitNotifier.Active and FruitNotifier.ServerHopOnFind) then continue end
        local hasLeg=false
        for _,f in ipairs(ScanFruits()) do if f.legendary then hasLeg=true; break end end
        if not hasLeg then
            FruitNotifier.StatusText="Hop — procurando lendária..."; task.wait(8)
            hasLeg=false; for _,f in ipairs(ScanFruits()) do if f.legendary then hasLeg=true; break end end
            if not hasLeg then ServerHop() end
        else FruitNotifier.StatusText="Lendária encontrada! Permanecendo." end
    end
end)

-- ============================================================
--  ESP CONFIG
-- ============================================================
local Cfg={
    PlayerESP=false,FruitESP=false,BossESP=false,ShowDist=true,TracerLines=false,ESPRange=2000,
    HideKey=Enum.KeyCode.LeftControl,
    Col_P=Color3.fromRGB(220,60,60),Col_F_Common=Color3.fromRGB(180,180,180),
    Col_F_Leg=Color3.fromRGB(255,215,0),Col_Boss=Color3.fromRGB(255,80,20),
}
local function NTxt(col,sz) local t=Drawing.new("Text"); t.Color=col; t.Size=sz or 13; t.Center=true; t.Outline=true; t.Visible=false; return t end
local function NBox(col,f) local b=Drawing.new("Square"); b.Color=col; b.Thickness=1.5; b.Filled=f or false; b.Visible=false; return b end
local function NLine(col) local l=Drawing.new("Line"); l.Color=col; l.Thickness=1; l.Visible=false; return l end
local function W2V(pos) local sp=Camera:WorldToViewportPoint(pos); return Vector2.new(sp.X,sp.Y),sp.Z,sp.Z>0 end
local function Dist(pos) local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then return math.floor((c.HumanoidRootPart.Position-pos).Magnitude) end; return 0 end

-- ============================================================
--  GUI — TEMA PRETO SÓLIDO
-- ============================================================
local old=CoreGui:FindFirstChild("CHINAHUB82"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="CHINAHUB82"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true; SG.Parent=CoreGui

-- Paleta preta
local K={
    bg    = Color3.fromRGB(0, 0, 0),
    side  = Color3.fromRGB(8, 8, 8),
    panel = Color3.fromRGB(5, 5, 5),
    card  = Color3.fromRGB(14, 14, 14),
    cardH = Color3.fromRGB(22, 22, 22),
    bord  = Color3.fromRGB(40, 40, 40),
    sep   = Color3.fromRGB(28, 28, 28),
    text  = Color3.fromRGB(230, 230, 230),
    dim   = Color3.fromRGB(100, 100, 100),
    acc   = Color3.fromRGB(50, 140, 255),
    acc2  = Color3.fromRGB(100, 180, 255),
    green = Color3.fromRGB(50, 210, 90),
    red   = Color3.fromRGB(210, 50, 60),
    gold  = Color3.fromRGB(255, 205, 45),
    orange= Color3.fromRGB(255, 125, 30),
    teal  = Color3.fromRGB(40, 205, 175),
    purple= Color3.fromRGB(160, 60, 220),
}

local function Rnd(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 6) end
local function Pad(p,l,r,t,b)
    local x=Instance.new("UIPadding",p)
    x.PaddingLeft=UDim.new(0,l or 0); x.PaddingRight=UDim.new(0,r or 0)
    x.PaddingTop=UDim.new(0,t or 0); x.PaddingBottom=UDim.new(0,b or 0)
end
local function Lst(p,dir,sp,ha)
    local l=Instance.new("UIListLayout",p)
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,sp or 4)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    return l
end
local function Tw(o,t,pr) TweenService:Create(o,TweenInfo.new(t),pr):Play() end
local function Stk(p,col,th) local s=Instance.new("UIStroke",p); s.Color=col or K.bord; s.Thickness=th or 1; return s end

-- Janela
local WIN=Instance.new("Frame",SG)
WIN.Size=UDim2.new(0,760,0,560)
WIN.Position=UDim2.new(0.5,-380,0.5,-280)
WIN.BackgroundColor3=K.bg; WIN.BackgroundTransparency=0
WIN.BorderSizePixel=0; Rnd(WIN,8); WIN.ZIndex=5
Stk(WIN,K.bord,1)

-- TopBar
local Top=Instance.new("Frame",WIN)
Top.Size=UDim2.new(1,0,0,46)
Top.BackgroundColor3=K.side; Top.BackgroundTransparency=0
Top.BorderSizePixel=0; Rnd(Top,8); Top.ZIndex=6

-- bottom line on topbar
local topLine=Instance.new("Frame",Top)
topLine.Size=UDim2.new(1,0,0,1); topLine.Position=UDim2.new(0,0,1,-1)
topLine.BackgroundColor3=K.bord; topLine.BorderSizePixel=0; topLine.ZIndex=7

-- accent bar
local acB=Instance.new("Frame",Top)
acB.Size=UDim2.new(0,3,0,28); acB.Position=UDim2.new(0,12,0.5,-14)
acB.BackgroundColor3=K.acc; acB.BorderSizePixel=0; Rnd(acB,2); acB.ZIndex=8

local titleL=Instance.new("TextLabel",Top)
titleL.Size=UDim2.new(0,180,0,20); titleL.Position=UDim2.new(0,22,0,7)
titleL.BackgroundTransparency=1; titleL.Text="CHINA HUB FREE"
titleL.TextColor3=K.text; titleL.TextSize=14; titleL.Font=Enum.Font.GothamBold
titleL.TextXAlignment=Enum.TextXAlignment.Left; titleL.ZIndex=8

local subtL=Instance.new("TextLabel",Top)
subtL.Size=UDim2.new(0,320,0,13); subtL.Position=UDim2.new(0,22,0,29)
subtL.BackgroundTransparency=1; subtL.Text="King Legacy  v8.2  ·  Update 11  ·  Halloween  ·  Sea3 Hoop"
subtL.TextColor3=K.dim; subtL.TextSize=10; subtL.Font=Enum.Font.Gotham
subtL.TextXAlignment=Enum.TextXAlignment.Left; subtL.ZIndex=8

local badge=Instance.new("Frame",Top)
badge.Size=UDim2.new(0,38,0,16); badge.Position=UDim2.new(0,222,0,8)
badge.BackgroundColor3=K.orange; badge.BorderSizePixel=0; Rnd(badge,3); badge.ZIndex=9
local badgeL=Instance.new("TextLabel",badge)
badgeL.Size=UDim2.new(1,0,1,0); badgeL.BackgroundTransparency=1; badgeL.Text="UPD11"
badgeL.TextColor3=Color3.new(1,1,1); badgeL.TextSize=9; badgeL.Font=Enum.Font.GothamBold; badgeL.ZIndex=10

-- window buttons
local function WBtn(lbl,col,xOff)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3=col; b.BackgroundTransparency=0
    b.Text=lbl; b.TextColor3=Color3.new(1,1,1); b.TextSize=12; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; Rnd(b,4); b.ZIndex=8
    b.MouseEnter:Connect(function() Tw(b,0.1,{BackgroundTransparency=0.4}) end)
    b.MouseLeave:Connect(function() Tw(b,0.1,{BackgroundTransparency=0}) end)
    return b
end
local CloseBtn=WBtn("×",K.red,-10)
local MinBtn  =WBtn("−",Color3.fromRGB(30,60,160),-38)

-- drag
local drag,dI,dS,dP
Top.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; dS=i.Position; dP=WIN.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
Top.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dI=i end end)
UserInputService.InputChanged:Connect(function(i)
    if i==dI and drag then local d=i.Position-dS
        WIN.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y) end
end)
CloseBtn.MouseButton1Click:Connect(function()
    Farm.Active=false; BossConfig.Active=false; DungeonConfig.Active=false
    SeaEvent.Active=false; AutoStats.Active=false; FruitNotifier.Active=false
    Halloween.Active=false; AutoHoop.Active=false
    SetCollision(true); SetFly(false); SetHitbox(false,10); SG:Destroy()
end)
local mini=false
MinBtn.MouseButton1Click:Connect(function()
    mini=not mini
    for _,c in ipairs(WIN:GetChildren()) do if c~=Top then c.Visible=not mini end end
    WIN.Size=mini and UDim2.new(0,760,0,46) or UDim2.new(0,760,0,560)
    MinBtn.Text=mini and "+" or "−"
end)

-- Main layout
local Layout=Instance.new("Frame",WIN)
Layout.Position=UDim2.new(0,0,0,46); Layout.Size=UDim2.new(1,0,1,-46)
Layout.BackgroundTransparency=1; Layout.ZIndex=6

-- Sidebar
local SB=Instance.new("Frame",Layout)
SB.Size=UDim2.new(0,150,1,0); SB.BackgroundColor3=K.side
SB.BackgroundTransparency=0; SB.BorderSizePixel=0; SB.ZIndex=7

local sbRight=Instance.new("Frame",SB)
sbRight.Size=UDim2.new(0,1,1,0); sbRight.Position=UDim2.new(1,-1,0,0)
sbRight.BackgroundColor3=K.bord; sbRight.BorderSizePixel=0; sbRight.ZIndex=8

-- User card in sidebar
local UC=Instance.new("Frame",SB)
UC.Size=UDim2.new(1,0,0,62); UC.Position=UDim2.new(0,0,0,0)
UC.BackgroundColor3=K.card; UC.BackgroundTransparency=0; UC.BorderSizePixel=0; UC.ZIndex=8
Pad(UC,12,10,8,8)

local ucBar=Instance.new("Frame",UC)
ucBar.Size=UDim2.new(0,2,1,0); ucBar.Position=UDim2.new(0,-12,0,0)
ucBar.BackgroundColor3=K.acc; ucBar.BorderSizePixel=0; ucBar.ZIndex=9

local ucName=Instance.new("TextLabel",UC)
ucName.Size=UDim2.new(1,0,0,20); ucName.BackgroundTransparency=1
ucName.Text=LP.DisplayName; ucName.TextColor3=K.text; ucName.TextSize=12
ucName.Font=Enum.Font.GothamBold; ucName.TextXAlignment=Enum.TextXAlignment.Left; ucName.ZIndex=9

local ucLine=Instance.new("Frame",UC)
ucLine.Size=UDim2.new(1,0,0,1); ucLine.Position=UDim2.new(0,0,0,24)
ucLine.BackgroundColor3=K.sep; ucLine.BorderSizePixel=0; ucLine.ZIndex=9

local ucSub=Instance.new("TextLabel",UC)
ucSub.Size=UDim2.new(1,0,0,14); ucSub.Position=UDim2.new(0,0,0,30)
ucSub.BackgroundTransparency=1; ucSub.TextColor3=K.dim; ucSub.TextSize=10
ucSub.Font=Enum.Font.Gotham; ucSub.TextXAlignment=Enum.TextXAlignment.Left; ucSub.ZIndex=9
task.spawn(function()
    while SG.Parent do task.wait(2)
        ucSub.Text="Lv "..GetLevel().."  ·  "..math.floor(GetBeli()/1000).."K"
    end
end)

local ucSepLine=Instance.new("Frame",SB)
ucSepLine.Size=UDim2.new(1,0,0,1); ucSepLine.Position=UDim2.new(0,0,0,62)
ucSepLine.BackgroundColor3=K.bord; ucSepLine.BorderSizePixel=0; ucSepLine.ZIndex=8

-- Content area
local Con=Instance.new("Frame",Layout)
Con.Position=UDim2.new(0,150,0,0); Con.Size=UDim2.new(1,-150,1,0)
Con.BackgroundColor3=K.panel; Con.BackgroundTransparency=0; Con.BorderSizePixel=0; Con.ZIndex=7

local CS=Instance.new("ScrollingFrame",Con)
CS.Size=UDim2.new(1,0,1,0); CS.BackgroundTransparency=1
CS.ScrollBarThickness=3; CS.ScrollBarImageColor3=K.acc
CS.CanvasSize=UDim2.new(0,0,0,0); CS.AutomaticCanvasSize=Enum.AutomaticSize.Y; CS.ZIndex=8
Pad(CS,12,12,10,10); Lst(CS,Enum.FillDirection.Vertical,6)

-- ============================================================
--  TAB SYSTEM
-- ============================================================
local Pages, TabBtns={}, {}
local function MkPage(id)
    local pg=Instance.new("Frame",CS)
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.Visible=false; pg.ZIndex=9
    Lst(pg,Enum.FillDirection.Vertical,6); Pages[id]=pg; return pg
end
local function Switch(id)
    for k,pg in pairs(Pages) do pg.Visible=false
        local btn=TabBtns[k]
        if btn then
            Tw(btn.bg,0.12,{BackgroundTransparency=1})
            btn.bar.Visible=false; btn.lbl.TextColor3=K.dim; btn.lbl.Font=Enum.Font.Gotham
        end
    end
    if Pages[id] then Pages[id].Visible=true end
    if TabBtns[id] then local btn=TabBtns[id]
        Tw(btn.bg,0.12,{BackgroundTransparency=0.75})
        btn.bar.Visible=true; btn.lbl.TextColor3=K.text; btn.lbl.Font=Enum.Font.GothamBold
    end
    CS.CanvasPosition=Vector2.new(0,0)
end

local TabDefs={
    {id="FARM",      icon="⚔",  label="Farm",      order=1, accent=K.acc},
    {id="BOSS",      icon="👑",  label="Boss",      order=2, accent=K.acc},
    {id="DUNGEON",   icon="🏯",  label="Dungeon",   order=3, accent=K.acc},
    {id="SEAS",      icon="🌊",  label="Seas",      order=4, accent=K.teal},
    {id="HALLOWEEN", icon="🎃",  label="Halloween", order=5, accent=K.orange},
    {id="FRUTAS",    icon="🍎",  label="Frutas",    order=6, accent=K.gold},
    {id="ESP",       icon="👁",  label="ESP",       order=7, accent=K.acc},
    {id="TELEPORT",  icon="🗺",  label="Teleport",  order=8, accent=K.acc},
    {id="MISC",      icon="⚙",  label="Misc",      order=9, accent=K.acc},
}

for _, td in ipairs(TabDefs) do
    MkPage(td.id)
    local ac=td.accent or K.acc
    local outer=Instance.new("Frame",SB)
    outer.Size=UDim2.new(1,0,0,34)
    outer.Position=UDim2.new(0,0,0,63+(td.order-1)*34)
    outer.BackgroundTransparency=1; outer.ZIndex=9

    local bg=Instance.new("Frame",outer)
    bg.Size=UDim2.new(1,-4,1,-2); bg.Position=UDim2.new(0,2,0,1)
    bg.BackgroundColor3=K.cardH; bg.BackgroundTransparency=1; bg.BorderSizePixel=0; Rnd(bg,5); bg.ZIndex=9

    local bar=Instance.new("Frame",outer)
    bar.Size=UDim2.new(0,2,0,18); bar.Position=UDim2.new(0,0,0.5,-9)
    bar.BackgroundColor3=ac; bar.BorderSizePixel=0; Rnd(bar,1); bar.Visible=false; bar.ZIndex=11

    local ico=Instance.new("TextLabel",outer)
    ico.Size=UDim2.new(0,20,1,0); ico.Position=UDim2.new(0,12,0,0)
    ico.BackgroundTransparency=1; ico.Text=td.icon; ico.TextSize=14; ico.Font=Enum.Font.Gotham; ico.ZIndex=11

    local lbl=Instance.new("TextLabel",outer)
    lbl.Size=UDim2.new(1,-38,1,0); lbl.Position=UDim2.new(0,34,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=td.label; lbl.TextColor3=K.dim; lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11

    local click=Instance.new("TextButton",outer)
    click.Size=UDim2.new(1,0,1,0); click.BackgroundTransparency=1; click.Text=""; click.ZIndex=12
    TabBtns[td.id]={bg=bg, bar=bar, lbl=lbl}
    click.MouseButton1Click:Connect(function() Switch(td.id) end)
    click.MouseEnter:Connect(function()
        if Pages[td.id] and not Pages[td.id].Visible then Tw(bg,0.1,{BackgroundTransparency=0.85}) end
    end)
    click.MouseLeave:Connect(function()
        if Pages[td.id] and not Pages[td.id].Visible then Tw(bg,0.1,{BackgroundTransparency=1}) end
    end)
end

-- ============================================================
--  WIDGET HELPERS
-- ============================================================
-- Section header
local function Sec(p, t, col)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,20)
    f.BackgroundTransparency=1; f.ZIndex=10
    local line=Instance.new("Frame",f); line.Size=UDim2.new(1,0,0,1)
    line.Position=UDim2.new(0,0,1,-1); line.BackgroundColor3=col or K.bord
    line.BackgroundTransparency=0.5; line.BorderSizePixel=0; line.ZIndex=11
    local ll=Instance.new("TextLabel",f); ll.Size=UDim2.new(1,0,1,-2)
    ll.BackgroundTransparency=1; ll.Text=string.upper(t); ll.TextColor3=col or K.dim
    ll.TextSize=9; ll.Font=Enum.Font.GothamBold; ll.TextXAlignment=Enum.TextXAlignment.Left; ll.ZIndex=11
    return f
end

-- Toggle
local function Tog(p, t, def, cb)
    local row=Instance.new("Frame",p); row.Size=UDim2.new(1,0,0,38)
    row.BackgroundColor3=K.card; row.BackgroundTransparency=0; row.BorderSizePixel=0
    Rnd(row,6); Stk(row,K.bord,1); row.ZIndex=10

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=t; lbl.TextColor3=K.text; lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11

    local pill=Instance.new("TextButton",row)
    pill.Size=UDim2.new(0,46,0,22); pill.Position=UDim2.new(1,-58,0.5,-11)
    pill.Text=""; pill.BorderSizePixel=0; Rnd(pill,11); pill.ZIndex=11
    local st=def or false
    pill.BackgroundColor3=st and K.green or Color3.fromRGB(30,30,30)
    Stk(pill,K.bord,1)

    local thumb=Instance.new("Frame",pill); thumb.Size=UDim2.new(0,16,0,16)
    thumb.Position=st and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; Rnd(thumb,8); thumb.ZIndex=12

    local function Set(v)
        st=v
        Tw(pill,0.15,{BackgroundColor3=v and K.green or Color3.fromRGB(30,30,30)})
        Tw(thumb,0.15,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        if cb then cb(v) end
    end
    pill.MouseButton1Click:Connect(function() Set(not st) end)
    return Set
end

-- Button
local function Btn(p, t, cb, isPrimary, colOverride)
    local bgC=colOverride or (isPrimary and K.acc or K.card)
    local b=Instance.new("TextButton",p); b.Size=UDim2.new(1,0,0,36)
    b.BackgroundColor3=bgC; b.BackgroundTransparency=0
    b.Text=t; b.TextColor3=K.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; Rnd(b,6); b.ZIndex=10
    if not isPrimary and not colOverride then Stk(b,K.bord,1) end
    b.MouseEnter:Connect(function() Tw(b,0.1,{BackgroundColor3=K.cardH}) end)
    b.MouseLeave:Connect(function() Tw(b,0.1,{BackgroundColor3=bgC}) end)
    b.MouseButton1Click:Connect(function()
        Tw(b,0.07,{BackgroundColor3=K.cardH})
        task.delay(0.14,function() if b and b.Parent then Tw(b,0.1,{BackgroundColor3=bgC}) end end)
        if cb then cb() end
    end)
    return b
end

-- Input with LABEL above
local function Inp(p, labelText, hint, cb, default)
    -- label
    local lf=Instance.new("Frame",p); lf.Size=UDim2.new(1,0,0,14)
    lf.BackgroundTransparency=1; lf.ZIndex=10
    local ll=Instance.new("TextLabel",lf); ll.Size=UDim2.new(1,0,1,0)
    ll.BackgroundTransparency=1; ll.Text=labelText; ll.TextColor3=K.dim; ll.TextSize=10
    ll.Font=Enum.Font.Gotham; ll.TextXAlignment=Enum.TextXAlignment.Left; ll.ZIndex=11
    -- box
    local b=Instance.new("TextBox",p); b.Size=UDim2.new(1,0,0,32)
    b.BackgroundColor3=K.card; b.BackgroundTransparency=0
    b.Text=default or ""; b.PlaceholderText=hint or ""; b.PlaceholderColor3=K.dim
    b.TextColor3=K.text; b.TextSize=11; b.Font=Enum.Font.Gotham
    b.BorderSizePixel=0; b.ClearTextOnFocus=false
    Rnd(b,6); Stk(b,K.bord,1); Pad(b,10,10,0,0); b.ZIndex=10
    b.FocusLost:Connect(function() if cb then cb(b.Text) end end)
    return b
end

-- Simple label
local function Lbl(p, t, col)
    local l=Instance.new("TextLabel",p); l.Size=UDim2.new(1,0,0,14)
    l.BackgroundTransparency=1; l.Text=t; l.TextColor3=col or K.dim; l.TextSize=10
    l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=10
    return l
end

-- Status bar
local function MkStatus(p, acCol)
    acCol=acCol or K.green
    local sf=Instance.new("Frame",p); sf.Size=UDim2.new(1,0,0,36)
    sf.BackgroundColor3=K.card; sf.BackgroundTransparency=0; sf.BorderSizePixel=0
    Rnd(sf,6); Stk(sf,K.bord,1); sf.ZIndex=10
    local dot=Instance.new("Frame",sf); dot.Size=UDim2.new(0,7,0,7)
    dot.Position=UDim2.new(0,12,0.5,-3.5); dot.BackgroundColor3=K.dim
    dot.BorderSizePixel=0; Rnd(dot,4); dot.ZIndex=11
    local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,-30,1,0)
    sl.Position=UDim2.new(0,26,0,0); sl.BackgroundTransparency=1; sl.Text="Inativo"
    sl.TextColor3=acCol; sl.TextSize=10; sl.Font=Enum.Font.GothamBold
    sl.TextXAlignment=Enum.TextXAlignment.Left; sl.ZIndex=11
    return dot, sl
end

-- Style row
local function StyleRow(p, def, cb)
    local sRow=Instance.new("Frame",p); sRow.Size=UDim2.new(1,0,0,34)
    sRow.BackgroundTransparency=1; sRow.ZIndex=10
    Lst(sRow,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Left)
    local sBtns={}
    local stList={{"melee","⚔ Melee"},{"sword","🗡 Sword"},{"fruit","🍎 Fruit"}}
    local function SetSt(key)
        if cb then cb(key) end
        for _,sb in ipairs(sBtns) do
            local active=sb[1]==key
            Tw(sb[2],0.12,{BackgroundColor3=active and K.acc or K.card})
            sb[3].TextColor3=active and Color3.new(1,1,1) or K.dim
            sb[3].Font=active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    for _,st in ipairs(stList) do
        local b=Instance.new("TextButton",sRow); b.Size=UDim2.new(0,96,1,0)
        b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(st[1]==def) and K.acc or K.card
        b.BackgroundTransparency=0; Rnd(b,6); b.ZIndex=11
        if st[1]~=def then Stk(b,K.bord,1) end
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0)
        l.BackgroundTransparency=1; l.Text=st[2]; l.TextSize=10
        l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(st[1]==def) and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(st[1]==def) and Color3.new(1,1,1) or K.dim; l.ZIndex=12
        table.insert(sBtns,{st[1],b,l})
        b.MouseButton1Click:Connect(function() SetSt(st[1]) end)
    end
end

-- ============================================================
--  FARM PAGE
-- ============================================================
do
    local pg=Pages["FARM"]
    local dot,sl=MkStatus(pg,K.green)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=Farm.Active and Farm.StatusText or "Inativo"
        dot.BackgroundColor3=Farm.Active and K.green or K.red
    end end)
    Sec(pg,"⚔ Auto Farm")
    Tog(pg,"Ativar Auto Farm",false,function(v) Farm.Active=v; if not v then Farm.State="idle"; SetCollision(true) end end)
    Tog(pg,"Aceitar Quest automaticamente",true,function(v) Farm.UseQuest=v end)
    Tog(pg,"Kill Aura",false,function(v) Farm.KillAura=v end)
    Sec(pg,"Estilo de Luta")
    StyleRow(pg,"melee",function(k) Farm.Style=k end)
    Sec(pg,"Configuração")
    Inp(pg,"Altura hover (studs):","5",function(v) local n=tonumber(v); if n and n>0 then Farm.HoverY=n end end,"5")
    Inp(pg,"Kill Aura range (studs):","200",function(v) local n=tonumber(v); if n then Farm.KillAuraRange=n end end,"200")
    Inp(pg,"Mobs por ciclo:","10",function(v) local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end end,"10")
    Sec(pg,"Calibrar Zonas (2°/3° Mar)")
    local selIdx=1
    local selL=Instance.new("TextLabel",pg)
    selL.Size=UDim2.new(1,0,0,30); selL.BackgroundColor3=K.card; selL.BackgroundTransparency=0
    selL.BorderSizePixel=0; Rnd(selL,6); Stk(selL,K.bord,1)
    selL.Text="  "..Zones[1].name.."  Lv "..Zones[1].minLv.."-"..Zones[1].maxLv
    selL.TextColor3=K.acc2; selL.TextSize=11; selL.Font=Enum.Font.GothamBold
    selL.TextXAlignment=Enum.TextXAlignment.Left; selL.ZIndex=10; Pad(selL,10,0,0,0)
    local navRow=Instance.new("Frame",pg); navRow.Size=UDim2.new(1,0,0,32)
    navRow.BackgroundTransparency=1; navRow.ZIndex=10; Lst(navRow,Enum.FillDirection.Horizontal,6)
    local function NavBtn(t2,cb2)
        local b=Instance.new("TextButton",navRow); b.Size=UDim2.new(0.5,-3,1,0)
        b.BackgroundColor3=K.card; b.BackgroundTransparency=0; b.Text=t2
        b.TextColor3=K.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0; Rnd(b,6); Stk(b,K.bord,1); b.ZIndex=11
        b.MouseEnter:Connect(function() Tw(b,0.1,{BackgroundColor3=K.cardH}) end)
        b.MouseLeave:Connect(function() Tw(b,0.1,{BackgroundColor3=K.card}) end)
        b.MouseButton1Click:Connect(cb2)
    end
    NavBtn("◄ Anterior",function()
        selIdx=math.max(1,selIdx-1); local z=Zones[selIdx]
        selL.Text="  "..z.name.."  Lv "..z.minLv.."-"..z.maxLv; selL.TextColor3=K.acc2
    end)
    NavBtn("Próxima ►",function()
        selIdx=math.min(#Zones,selIdx+1); local z=Zones[selIdx]
        selL.Text="  "..z.name.."  Lv "..z.minLv.."-"..z.maxLv; selL.TextColor3=K.acc2
    end)
    Btn(pg,"Calibrar Posição NPC Quest",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        selL.Text="  ✅ "..Zones[selIdx].name.." quest calibrado"; selL.TextColor3=K.green
    end)
    Btn(pg,"Calibrar Posição dos Mobs",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        Zones[selIdx].mobPos=pos; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        selL.Text="  ✅ "..Zones[selIdx].name.." mobs calibrado"; selL.TextColor3=K.green
    end)
    Btn(pg,"Copiar Posição Atual",function()
        local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then
            local pos=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(pos.X,pos.Y,pos.Z)
            pcall(function() setclipboard(s) end); selL.Text="  Copiado: "..s; selL.TextColor3=K.acc2
        end
    end)
    Sec(pg,"Zonas")
    for _,z in ipairs(Zones) do
        Lbl(pg,("  Lv %4d–%-4d  %s%s"):format(z.minLv,z.maxLv,z.name,z.calibrate and "  ⚠" or ""),
            z.calibrate and K.orange or K.dim)
    end
end

-- ============================================================
--  BOSS PAGE
-- ============================================================
do
    local pg=Pages["BOSS"]
    local dot,sl=MkStatus(pg,K.red)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=BossConfig.Active and BossConfig.StatusText or "Inativo"
        dot.BackgroundColor3=BossConfig.Active and K.green or K.red
    end end)
    local infoCard=Instance.new("Frame",pg); infoCard.Size=UDim2.new(1,0,0,32)
    infoCard.BackgroundColor3=Color3.fromRGB(8,16,30); infoCard.BackgroundTransparency=0
    infoCard.BorderSizePixel=0; Rnd(infoCard,6); Stk(infoCard,Color3.fromRGB(0,70,150),1); infoCard.ZIndex=10
    local iL=Instance.new("TextLabel",infoCard); iL.Size=UDim2.new(1,0,1,0); iL.BackgroundTransparency=1
    iL.Text="🌊 Sea3: Depth King · Drakenfyr · Abyssal · Crab King · Kraken"
    iL.TextColor3=Color3.fromRGB(80,170,255); iL.TextSize=10; iL.Font=Enum.Font.GothamBold
    iL.TextXAlignment=Enum.TextXAlignment.Center; iL.ZIndex=11
    Sec(pg,"👑 Auto Boss")
    Tog(pg,"Ativar Auto Boss",false,function(v) BossConfig.Active=v end)
    Sec(pg,"Selecionar Boss")
    local tagColor={sea3=K.teal, hall=K.orange, raid=K.purple}
    local selBtns={}
    for _,b in ipairs(BossList) do
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,36)
        row.BackgroundColor3=K.card; row.BackgroundTransparency=0; row.BorderSizePixel=0
        Rnd(row,6); row.ZIndex=10
        local ac=tagColor[b.tag] or K.dim
        if b.tag~="" then
            local lb2=Instance.new("Frame",row); lb2.Size=UDim2.new(0,2,0.6,0); lb2.Position=UDim2.new(0,0,0.2,0)
            lb2.BackgroundColor3=ac; lb2.BorderSizePixel=0; Rnd(lb2,1); lb2.ZIndex=11
        end
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=b.name.."  —  "..b.notes
        lbl.TextColor3=b.tag~="" and ac or K.text; lbl.TextSize=10
        lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11
        local sel=Instance.new("TextButton",row); sel.Size=UDim2.new(0,40,0,22); sel.Position=UDim2.new(1,-48,0.5,-11)
        sel.Text="SEL"; sel.TextColor3=K.text; sel.TextSize=10; sel.Font=Enum.Font.GothamBold
        sel.BackgroundColor3=(BossConfig.SelectedBoss==b.name) and K.acc or K.cardH
        sel.BorderSizePixel=0; Rnd(sel,4); sel.ZIndex=12
        table.insert(selBtns,{name=b.name, btn=sel})
        sel.MouseButton1Click:Connect(function()
            BossConfig.SelectedBoss=b.name
            for _,sb in ipairs(selBtns) do Tw(sb.btn,0.1,{BackgroundColor3=sb.name==b.name and K.acc or K.cardH}) end
            sl.Text="Boss: "..b.name
        end)
    end
    Sec(pg,"Configuração")
    StyleRow(pg,"melee",function(k) BossConfig.Style=k end)
    Inp(pg,"Altura hover:","5",function(v) local n=tonumber(v); if n then BossConfig.HoverY=n end end,"5")
end

-- ============================================================
--  DUNGEON PAGE
-- ============================================================
do
    local pg=Pages["DUNGEON"]
    local dot,sl=MkStatus(pg,K.green)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=DungeonConfig.Active and DungeonConfig.StatusText or "Inativo"
        dot.BackgroundColor3=DungeonConfig.Active and K.green or K.red
    end end)
    Sec(pg,"🏯 Auto Dungeon")
    Lbl(pg,"  Calibre a posição de cada dungeon abaixo.")
    Tog(pg,"Ativar Auto Dungeon",false,function(v) DungeonConfig.Active=v end)
    Sec(pg,"Posições das Dungeons")
    for _,d in ipairs({{lab="1° Mar",key="Pos1"},{lab="2° Mar",key="Pos2"},{lab="3° Mar",key="Pos3"}}) do
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,32)
        row.BackgroundTransparency=1; row.ZIndex=10; Lst(row,Enum.FillDirection.Horizontal,6)
        local posL=Instance.new("TextLabel",row); posL.Size=UDim2.new(0.6,0,1,0)
        posL.BackgroundColor3=K.card; posL.BackgroundTransparency=0
        posL.Text="  "..d.lab..": Não calibrado"
        posL.TextColor3=K.dim; posL.TextSize=10; posL.Font=Enum.Font.Gotham
        posL.TextXAlignment=Enum.TextXAlignment.Left; posL.BorderSizePixel=0
        Rnd(posL,6); Stk(posL,K.bord,1); posL.ZIndex=11; Pad(posL,8,0,0,0)
        local calBtn=Instance.new("TextButton",row); calBtn.Size=UDim2.new(0.4,-6,1,0)
        calBtn.BackgroundColor3=K.acc; calBtn.Text="Calibrar"; calBtn.TextColor3=K.text
        calBtn.TextSize=10; calBtn.Font=Enum.Font.GothamBold; calBtn.BorderSizePixel=0
        Rnd(calBtn,6); calBtn.ZIndex=11
        local dk=d.key
        calBtn.MouseButton1Click:Connect(function()
            local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
            local pos=c.HumanoidRootPart.Position; DungeonConfig[dk]=pos
            posL.Text=("  "..d.lab..": %.0f, %.0f, %.0f"):format(pos.X,pos.Y,pos.Z); posL.TextColor3=K.green
        end)
    end
    Sec(pg,"Configuração")
    StyleRow(pg,"melee",function(k) DungeonConfig.Style=k end)
    Inp(pg,"Altura hover:","5",function(v) local n=tonumber(v); if n then DungeonConfig.HoverY=n end end,"5")
end

-- ============================================================
--  SEAS PAGE
-- ============================================================
do
    local pg=Pages["SEAS"]
    local seaSubMode="events"
    local dot,sl=MkStatus(pg,K.teal)
    task.spawn(function() while SG.Parent do task.wait(0.5)
        if seaSubMode=="events" then sl.Text=SeaEvent.Active and SeaEvent.StatusText or "Events inativo"
            dot.BackgroundColor3=SeaEvent.Active and K.green or K.red
        else sl.Text=AutoHoop.Active and AutoHoop.StatusText or "Hoop inativo"
            dot.BackgroundColor3=AutoHoop.Active and K.teal or K.red end
    end end)
    -- sub-tab switcher
    local sw=Instance.new("Frame",pg); sw.Size=UDim2.new(1,0,0,36)
    sw.BackgroundColor3=K.card; sw.BackgroundTransparency=0; sw.BorderSizePixel=0
    Rnd(sw,6); Stk(sw,K.bord,1); sw.ZIndex=10; Pad(sw,4,4,4,4)
    Lst(sw,Enum.FillDirection.Horizontal,4)
    local evF=Instance.new("Frame",pg); evF.Size=UDim2.new(1,0,0,0)
    evF.AutomaticSize=Enum.AutomaticSize.Y; evF.BackgroundTransparency=1; evF.ZIndex=10
    Lst(evF,Enum.FillDirection.Vertical,6)
    local hpF=Instance.new("Frame",pg); hpF.Size=UDim2.new(1,0,0,0)
    hpF.AutomaticSize=Enum.AutomaticSize.Y; hpF.BackgroundTransparency=1; hpF.ZIndex=10; hpF.Visible=false
    Lst(hpF,Enum.FillDirection.Vertical,6)
    local subBtns={}
    local function SwitchSea(mode)
        seaSubMode=mode; evF.Visible=(mode=="events"); hpF.Visible=(mode=="hoop")
        for _,sb in ipairs(subBtns) do local active=(sb.mode==mode)
            Tw(sb.btn,0.12,{BackgroundColor3=active and K.teal or K.card})
            sb.lbl.TextColor3=active and Color3.new(1,1,1) or K.dim
            sb.lbl.Font=active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    local function SubBtn(label, mode)
        local b=Instance.new("TextButton",sw); b.Size=UDim2.new(0.5,-6,1,0)
        b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(mode=="events") and K.teal or K.card
        b.BackgroundTransparency=0; Rnd(b,5); b.ZIndex=11
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=label; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(mode=="events") and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(mode=="events") and Color3.new(1,1,1) or K.dim; l.ZIndex=12
        table.insert(subBtns,{mode=mode,btn=b,lbl=l})
        b.MouseButton1Click:Connect(function() SwitchSea(mode) end)
    end
    SubBtn("🌊  Sea Events","events"); SubBtn("🔀  Sea Hoop","hoop")
    -- Sea Events
    do
        Sec(evF,"Eventos do Mar",K.teal)
        Tog(evF,"Ativar Sea Events",false,function(v) SeaEvent.Active=v end)
        Tog(evF,"Sea Beast",true,function(v) SeaEvent.SeaBeast=v end)
        Tog(evF,"Ghost Ship",false,function(v) SeaEvent.GhostShip=v end)
        Tog(evF,"Pteranodon (spawn 2h)",false,function(v) SeaEvent.Pteranodon=v end)
        Tog(evF,"Serpente (spawn 1h30)",false,function(v) SeaEvent.Serpent=v end)
        Sec(evF,"Configuração",K.teal)
        StyleRow(evF,"melee",function(k) SeaEvent.Style=k end)
        Inp(evF,"Altura hover:","8",function(v) local n=tonumber(v); if n then SeaEvent.HoverY=n end end,"8")
        Btn(evF,"🔀  Server Hop Agora",function() ServerHop() end,true)
    end
    -- Sea Hoop
    do
        Sec(hpF,"Boss Alvo",K.teal)
        local hoopSelBtns={}
        for _,t in ipairs(HoopTargets) do
            local row=Instance.new("Frame",hpF); row.Size=UDim2.new(1,0,0,36)
            row.BackgroundColor3=K.card; row.BackgroundTransparency=0; row.BorderSizePixel=0; Rnd(row,6); row.ZIndex=10
            local lb2=Instance.new("Frame",row); lb2.Size=UDim2.new(0,2,0.6,0); lb2.Position=UDim2.new(0,0,0.2,0)
            lb2.BackgroundColor3=K.teal; lb2.BorderSizePixel=0; Rnd(lb2,1); lb2.ZIndex=11
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,10,0,0)
            lbl.BackgroundTransparency=1; lbl.Text=t.name.."  —  "..t.notes
            lbl.TextColor3=(AutoHoop.TargetBoss==t.name) and K.teal or K.text
            lbl.TextSize=10; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11
            local sel=Instance.new("TextButton",row); sel.Size=UDim2.new(0,40,0,22); sel.Position=UDim2.new(1,-48,0.5,-11)
            sel.Text="SEL"; sel.TextColor3=K.text; sel.TextSize=10; sel.Font=Enum.Font.GothamBold
            sel.BackgroundColor3=(AutoHoop.TargetBoss==t.name) and K.teal or K.cardH
            sel.BorderSizePixel=0; Rnd(sel,4); sel.ZIndex=12
            table.insert(hoopSelBtns,{name=t.name,btn=sel,lbl=lbl})
            local tn=t.name
            sel.MouseButton1Click:Connect(function()
                AutoHoop.TargetBoss=tn
                for _,sb in ipairs(hoopSelBtns) do local active=(sb.name==tn)
                    Tw(sb.btn,0.1,{BackgroundColor3=active and K.teal or K.cardH}); sb.lbl.TextColor3=active and K.teal or K.text
                end
            end)
        end
        Sec(hpF,"Ativar",K.teal)
        Tog(hpF,"Auto Sea Hoop",false,function(v) AutoHoop.Active=v; if not v then AutoHoop._scanTimer=0; AutoHoop._found=false end end)
        Tog(hpF,"Farmar boss ao encontrar",true,function(v) AutoHoop.FightOnFind=v end)
        Sec(hpF,"Configuração",K.teal)
        Inp(hpF,"Scan antes de hopar (seg):","10",function(v) local n=tonumber(v); if n and n>=2 then AutoHoop.ScanTime=n end end,"10")
        StyleRow(hpF,"melee",function(k) AutoHoop.Style=k end)
        Inp(hpF,"Altura hover:","8",function(v) local n=tonumber(v); if n then AutoHoop.HoverY=n end end,"8")
    end
end

-- ============================================================
--  HALLOWEEN PAGE
-- ============================================================
do
    local pg=Pages["HALLOWEEN"]
    local dot,sl=MkStatus(pg,K.orange)
    task.spawn(function() while SG.Parent do task.wait(0.5)
        sl.Text=Halloween.Active and Halloween.StatusText or "Inativo"
        dot.BackgroundColor3=Halloween.Active and K.orange or K.red
    end end)
    -- banner
    local ban=Instance.new("Frame",pg); ban.Size=UDim2.new(1,0,0,42)
    ban.BackgroundColor3=Color3.fromRGB(14,6,2); ban.BackgroundTransparency=0
    ban.BorderSizePixel=0; Rnd(ban,6); Stk(ban,K.orange,1); ban.ZIndex=10
    local banL=Instance.new("TextLabel",ban); banL.Size=UDim2.new(1,0,0.55,0); banL.Position=UDim2.new(0,0,0,4)
    banL.BackgroundTransparency=1; banL.Text="🎃  Halloween Event — Update 11  🎃"
    banL.TextColor3=K.orange; banL.TextSize=12; banL.Font=Enum.Font.GothamBold
    banL.TextXAlignment=Enum.TextXAlignment.Center; banL.ZIndex=11
    local banS=Instance.new("TextLabel",ban); banS.Size=UDim2.new(1,0,0.4,0); banS.Position=UDim2.new(0,0,0.6,0)
    banS.BackgroundTransparency=1; banS.Text="Depth King · Skull King · Jack-o'-Lantern · Candy Farm"
    banS.TextColor3=K.gold; banS.TextSize=9; banS.Font=Enum.Font.Gotham
    banS.TextXAlignment=Enum.TextXAlignment.Center; banS.ZIndex=11

    Sec(pg,"Modo",K.orange)
    local modeRow=Instance.new("Frame",pg); modeRow.Size=UDim2.new(1,0,0,34)
    modeRow.BackgroundTransparency=1; modeRow.ZIndex=10
    Lst(modeRow,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Left)
    local modeBtns={}
    local modeList={{"candy","🍬 Candy"},{"jacko","🎃 Jack-O"},{"skullking","💀 Skull"},{"depthking","🐢 Depth"}}
    local function SetMode(key) Halloween.Mode=key
        for _,mb in ipairs(modeBtns) do local active=(mb[1]==key)
            Tw(mb[2],0.12,{BackgroundColor3=active and K.orange or K.card}); mb[3].TextColor3=active and Color3.new(1,1,1) or K.dim
        end
    end
    for _,m in ipairs(modeList) do
        local b=Instance.new("TextButton",modeRow); b.Size=UDim2.new(0.25,-3,1,0)
        b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(m[1]==Halloween.Mode) and K.orange or K.card
        b.BackgroundTransparency=0; Rnd(b,6); b.ZIndex=11
        if m[1]~=Halloween.Mode then Stk(b,K.bord,1) end
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=m[2]; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(m[1]==Halloween.Mode) and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(m[1]==Halloween.Mode) and Color3.new(1,1,1) or K.dim; l.ZIndex=12
        table.insert(modeBtns,{m[1],b,l}); b.MouseButton1Click:Connect(function() SetMode(m[1]) end)
    end
    Sec(pg,"Mar Alvo",K.orange)
    local seaRow=Instance.new("Frame",pg); seaRow.Size=UDim2.new(1,0,0,32)
    seaRow.BackgroundTransparency=1; seaRow.ZIndex=10; Lst(seaRow,Enum.FillDirection.Horizontal,6)
    local seaBtns={}
    local function SetSea(s) Halloween.Sea=s
        for _,sb in ipairs(seaBtns) do Tw(sb[2],0.12,{BackgroundColor3=sb[1]==s and K.orange or K.card}) end
    end
    for _,s in ipairs({1,2,3}) do
        local b=Instance.new("TextButton",seaRow); b.Size=UDim2.new(0,94,1,0)
        b.Text=s.."° Mar"; b.BorderSizePixel=0
        b.BackgroundColor3=(s==Halloween.Sea) and K.orange or K.card
        b.TextColor3=K.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BackgroundTransparency=0; Rnd(b,6); b.ZIndex=11
        table.insert(seaBtns,{s,b}); b.MouseButton1Click:Connect(function() SetSea(s) end)
    end
    Sec(pg,"Ativar",K.orange)
    Tog(pg,"Auto Halloween Event",false,function(v) Halloween.Active=v end)
    Tog(pg,"Auto Summon Jack-o'-Lantern",false,function(v) Halloween.AutoSummonJO=v end)
    Sec(pg,"Calibrar Halloween Islands",K.orange)
    for _,hi in ipairs({{1,"1° Mar"},{2,"2° Mar"},{3,"3° Mar"}}) do
        local seaN,seaL=hi[1],hi[2]
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,30)
        row.BackgroundTransparency=1; row.ZIndex=10; Lst(row,Enum.FillDirection.Horizontal,6)
        local posL=Instance.new("TextLabel",row); posL.Size=UDim2.new(0.56,0,1,0)
        posL.BackgroundColor3=K.card; posL.BackgroundTransparency=0
        posL.Text="  "..seaL..": Não calibrado"; posL.TextColor3=K.dim; posL.TextSize=10; posL.Font=Enum.Font.Gotham
        posL.TextXAlignment=Enum.TextXAlignment.Left; posL.BorderSizePixel=0
        Rnd(posL,6); Stk(posL,K.bord,1); posL.ZIndex=11; Pad(posL,6,0,0,0)
        local calBtn=Instance.new("TextButton",row); calBtn.Size=UDim2.new(0.24,-6,1,0)
        calBtn.BackgroundColor3=K.orange; calBtn.Text="Calibrar"; calBtn.TextColor3=K.text
        calBtn.TextSize=9; calBtn.Font=Enum.Font.GothamBold; calBtn.BorderSizePixel=0; Rnd(calBtn,6); calBtn.ZIndex=11
        local tpBtn=Instance.new("TextButton",row); tpBtn.Size=UDim2.new(0.2,-6,1,0)
        tpBtn.BackgroundColor3=K.card; tpBtn.Text="Ir"; tpBtn.TextColor3=K.text
        tpBtn.TextSize=9; tpBtn.Font=Enum.Font.GothamBold; tpBtn.BorderSizePixel=0
        Rnd(tpBtn,6); Stk(tpBtn,K.bord,1); tpBtn.ZIndex=11
        local sn=seaN
        calBtn.MouseButton1Click:Connect(function()
            local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
            local pos=c.HumanoidRootPart.Position; HalloweenPos[sn]=pos
            posL.Text=("  "..seaL..": %.0f,%.0f,%.0f"):format(pos.X,pos.Y,pos.Z); posL.TextColor3=K.green
        end)
        tpBtn.MouseButton1Click:Connect(function() SafeTP(HalloweenPos[sn]) end)
    end
    Sec(pg,"Estilo & Configuração",K.orange)
    StyleRow(pg,"melee",function(k) Halloween.Style=k end)
    Inp(pg,"Altura hover:","6",function(v) local n=tonumber(v); if n then Halloween.HoverY=n end end,"6")
end

-- ============================================================
--  FRUTAS PAGE
-- ============================================================
do
    local pg=Pages["FRUTAS"]
    local dot,sl=MkStatus(pg,K.gold)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=FruitNotifier.Active and FruitNotifier.StatusText or "Notifier inativo"
        dot.BackgroundColor3=FruitNotifier.Active and K.gold or K.red
    end end)
    Sec(pg,"🍎 Fruit Notifier")
    Tog(pg,"Ativar Fruit Notifier",false,function(v) FruitNotifier.Active=v end)
    Tog(pg,"Notificar TODAS as frutas",false,function(v) FruitNotifier.NotifyAll=v end)
    Tog(pg,"Auto Coletar ao detectar",false,function(v) FruitNotifier.AutoCollect=v end)
    Tog(pg,"Server Hop (procurar lendária)",false,function(v) FruitNotifier.ServerHopOnFind=v end)
    Sec(pg,"Scan Manual")
    Btn(pg,"🔍 Escanear Frutas Agora",function()
        local fruits=ScanFruits(); local legCount=0
        local msg=("Scan: %d frutas | "):format(#fruits)
        for _,f in ipairs(fruits) do if f.legendary then legCount=legCount+1; msg=msg..f.name.." " end end
        sl.Text=legCount==0 and msg.."sem lendárias" or msg
    end)
    Btn(pg,"⭐ Lendária Mais Próxima",function()
        local ok,fr=TP_NearestLegendary(); sl.Text=ok and ("TP: "..fr.name) or "Sem lendária."
    end, false, Color3.fromRGB(50,38,5))
    Btn(pg,"Ir para Qualquer Fruta",TP_NearestFruit)
end

-- ============================================================
--  ESP PAGE
-- ============================================================
do
    local pg=Pages["ESP"]
    Sec(pg,"👁 Jogadores")
    Tog(pg,"Player ESP",false,function(v) Cfg.PlayerESP=v end)
    Tog(pg,"Mostrar Distância",true,function(v) Cfg.ShowDist=v end)
    Tog(pg,"Tracer Lines",false,function(v) Cfg.TracerLines=v end)
    Sec(pg,"Frutas")
    Tog(pg,"Fruit ESP",false,function(v) Cfg.FruitESP=v end)
    Sec(pg,"Bosses")
    Tog(pg,"Boss ESP",false,function(v) Cfg.BossESP=v end)
    Sec(pg,"Range")
    Inp(pg,"Distância máxima (studs):","2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end,"2000")
end

-- ============================================================
--  TELEPORT PAGE
-- ============================================================
do
    local pg=Pages["TELEPORT"]
    Sec(pg,"🗺 Frutas")
    Btn(pg,"🍎 Fruta Mais Próxima",TP_NearestFruit,true)
    Btn(pg,"⭐ Lendária Mais Próxima",function() TP_NearestLegendary() end,false,Color3.fromRGB(50,38,5))
    Sec(pg,"Halloween Islands",K.orange)
    for s=1,3 do local sn=s
        Btn(pg,"🎃 Hallow Island "..s.."° Mar",function() SafeTP(HalloweenPos[sn]) end,false,Color3.fromRGB(35,12,2))
    end
    Sec(pg,"Jogadores")
    local pI=Inp(pg,"Nome do jogador:","username..."); Btn(pg,"Ir para Jogador",function() TP_Player(pI.Text) end)
    Btn(pg,"Listar Online",function()
        local n={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
        pI.Text=table.concat(n,", ")
    end)
    Sec(pg,"Coordenadas")
    local cI=Inp(pg,"X, Y, Z (separado por vírgula):","0, 100, 0")
    Btn(pg,"Ir para Coordenadas",function()
        local t=string.split(cI.Text,","); local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Btn(pg,"Copiar Posição Atual",function()
        local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then
            local pos=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(pos.X,pos.Y,pos.Z)
            pcall(function() setclipboard(s) end); cI.Text=s
        end
    end)
    Sec(pg,"Ilhas — 1° Mar")
    for _,il in ipairs({
        {"Starter Island",Vector3.new(-2044,100,-4591)},{"Pirate Island",Vector3.new(-681,64,-3449)},
        {"Soldier Island",Vector3.new(990,28,-510)},{"Shark Island",Vector3.new(1822,28,1492)},
        {"Chef Ship",Vector3.new(-792,28,1242)},{"Snow Island",Vector3.new(1622,28,-872)},
        {"Sand Kingdom",Vector3.new(-3052,28,1978)},{"Sky Island",Vector3.new(-2822,865,-1632)},
        {"Bubble Island",Vector3.new(2552,28,-2058)},
    }) do Btn(pg,il[1],function() SafeTP(il[2]) end) end
    Sec(pg,"🔗 NTT Join",K.green)
    local nttBox=Inp(pg,"Código ou link do servidor privado:","Código NTT ou link completo...")
    local nttFeed=Lbl(pg,"")
    Btn(pg,"🔗 JOIN",function()
        local raw=nttBox.Text
        if raw=="" then nttFeed.Text="⚠ Nenhum código inserido"; nttFeed.TextColor3=K.red; return end
        nttFeed.Text="Conectando..."; nttFeed.TextColor3=K.acc
        local ok,err=JoinNTT(raw)
        if ok then nttFeed.Text="✅ Teleportando..."; nttFeed.TextColor3=K.green
        else nttFeed.Text="❌ "..tostring(err):sub(1,50); nttFeed.TextColor3=K.red end
    end,true)
end

-- ============================================================
--  MISC PAGE
-- ============================================================
do
    local pg=Pages["MISC"]
    Sec(pg,"⚙ Auto Stats")
    Tog(pg,"Auto Stats Ativo",false,function(v) AutoStats.Active=v end)
    for _,s in ipairs({
        {lab="Fruit % (padrão=100):",key="Fruit"},{lab="STR %:",key="Str"},
        {lab="DEF %:",key="Def"},{lab="AGI %:",key="Agi"},{lab="HEALTH %:",key="Health"},
    }) do
        local k=s.key
        Inp(pg,s.lab,tostring(AutoStats[k]),function(v) local n=tonumber(v); if n and n>=0 then AutoStats[k]=n end end,tostring(AutoStats[k]))
    end
    Sec(pg,"Auto Haki")
    Tog(pg,"Buso Haki (pressiona Q)",false,function(v) AutoHaki.Buso=v end)
    Tog(pg,"Ken Haki (pressiona E)",false,function(v) AutoHaki.Ken=v end)
    Sec(pg,"Movimento")
    local noClipActive=false
    Tog(pg,"No Clip",false,function(v)
        noClipActive=v; local c=LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=not v end end end
    end)
    RunService.Stepped:Connect(function()
        if not noClipActive then return end; local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
    Tog(pg,"Infinite Jump",false,function(v)
        getgenv()._infJ=v
        if v and not getgenv()._infJC then
            getgenv()._infJC=UserInputService.JumpRequest:Connect(function()
                if getgenv()._infJ then local c=LP.Character
                    if c and c:FindFirstChild("Humanoid") then c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        elseif not v and getgenv()._infJC then getgenv()._infJC:Disconnect(); getgenv()._infJC=nil end
    end)
    Tog(pg,"Fly Mode (WASD + Espaço/Shift)",false,function(v) SetFly(v,flySpeed); if not v then SetCollision(true) end end)
    Inp(pg,"Fly Speed:","80",function(v) local n=tonumber(v); if n then flySpeed=n end end,"80")
    Sec(pg,"Velocidade & Pulo")
    Inp(pg,"Walk Speed:","16",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
    end,"16")
    Inp(pg,"Jump Power:","50",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end
    end,"50")
    Sec(pg,"Hitbox Expand")
    local hitboxSize=15
    Tog(pg,"Hitbox Expand",false,function(v) SetHitbox(v,hitboxSize) end)
    Inp(pg,"Tamanho do hitbox:","15",function(v)
        local n=tonumber(v); if n then hitboxSize=n; if HitboxCon then SetHitbox(true,n) end end
    end,"15")
    Sec(pg,"Utilitários")
    Btn(pg,"Restaurar Colisão",function()
        SetCollision(true); local c=LP.Character
        if c then local hum=c:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end end
    end, false, Color3.fromRGB(0,55,28))
    Btn(pg,"Recarregar Personagem",function() SetCollision(true); LP:LoadCharacter() end)
    Btn(pg,"🔀 Server Hop",function() ServerHop() end)
    Btn(pg,"⛔  Parar Tudo",function()
        Farm.Active=false; BossConfig.Active=false; DungeonConfig.Active=false
        SeaEvent.Active=false; AutoStats.Active=false; FruitNotifier.Active=false
        Halloween.Active=false; AutoHoop.Active=false
        SetFly(false); SetHitbox(false,10); SetCollision(true)
        local c=LP.Character; if c then
            local hum=c:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end,true)
end

-- ============================================================
--  BOTÃO REABRIR (Ctrl)
-- ============================================================
local SBtn=Instance.new("TextButton",SG)
SBtn.Size=UDim2.new(0,160,0,28); SBtn.Position=UDim2.new(0,20,0,50)
SBtn.BackgroundColor3=K.side; SBtn.BackgroundTransparency=0
SBtn.Text="🌊 CHINA HUB v8.2"; SBtn.TextColor3=K.teal
SBtn.TextSize=10; SBtn.Font=Enum.Font.GothamBold; SBtn.BorderSizePixel=0
SBtn.Visible=false; Rnd(SBtn,6); Stk(SBtn,K.teal,1); SBtn.ZIndex=10
local function TogVis()
    if WIN.Visible then WIN.Visible=false; SBtn.Visible=true
    else WIN.Visible=true; SBtn.Visible=false end
end
SBtn.MouseButton1Click:Connect(TogVis)
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==Cfg.HideKey then TogVis() end
end)

-- ============================================================
--  ESP UPDATE LOOP
-- ============================================================
local PLR_ESP={}
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
local FPool,BossPool={},{}
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
        local d=Dist(hrp.Position)
        if d>Cfg.ESPRange then for _,o in pairs(obj) do o.Visible=false end; continue end
        local t2D,_,tV=W2V(hrp.Position+Vector3.new(0,3.2,0))
        local b2D,_,bV=W2V(hrp.Position-Vector3.new(0,2.8,0))
        if not tV and not bV then for _,o in pairs(obj) do o.Visible=false end; continue end
        local bH=math.abs(t2D.Y-b2D.Y); local bW=bH*0.55; local bX=t2D.X-bW/2
        obj.box.Size=Vector2.new(bW,bH); obj.box.Position=Vector2.new(bX,t2D.Y); obj.box.Color=Cfg.Col_P; obj.box.Visible=true
        obj.name.Text=pl.DisplayName; obj.name.Position=Vector2.new(t2D.X,t2D.Y-16); obj.name.Color=Cfg.Col_P; obj.name.Visible=true
        obj.dist.Text=d.."m"; obj.dist.Position=Vector2.new(t2D.X,t2D.Y-28); obj.dist.Visible=Cfg.ShowDist
        local hp=hum and math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) or 0
        obj.hpBg.Size=Vector2.new(4,bH); obj.hpBg.Position=Vector2.new(bX+bW+3,t2D.Y); obj.hpBg.Visible=true
        obj.hpBar.Size=Vector2.new(4,bH*hp); obj.hpBar.Position=Vector2.new(bX+bW+3,t2D.Y+bH*(1-hp))
        obj.hpBar.Color=Color3.fromRGB(255*(1-hp),255*hp,0); obj.hpBar.Visible=true
        obj.tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
        obj.tracer.To=b2D; obj.tracer.Color=Cfg.Col_P; obj.tracer.Visible=Cfg.TracerLines
    end
end
local function UpdF()
    ClearPool(FPool); if not Cfg.FruitESP then return end
    for _,f in ipairs(ScanFruits()) do
        local d=Dist(f.pos); if d>Cfg.ESPRange then continue end
        local p2D,_,onS=W2V(f.pos); if not onS then continue end
        local col=f.legendary and Cfg.Col_F_Leg or Cfg.Col_F_Common
        local l=NTxt(col,13); l.Text=(f.legendary and "★ " or "")..f.name; l.Position=Vector2.new(p2D.X,p2D.Y-10); l.Visible=true
        local dl=NTxt(Color3.new(1,1,1),11); dl.Text=d.."m"; dl.Position=Vector2.new(p2D.X,p2D.Y+5); dl.Visible=true
        table.insert(FPool,{lbl=l,d=dl})
    end
end
local function UpdBoss()
    ClearPool(BossPool); if not Cfg.BossESP then return end
    for _,b in ipairs(BossList) do
        local boss=FindBoss(b.pattern,8000); if not boss then continue end
        local hrp=boss:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local d=Dist(hrp.Position); if d>Cfg.ESPRange then continue end
        local p2D,_,onS=W2V(hrp.Position+Vector3.new(0,5,0)); if not onS then continue end
        local hum=boss:FindFirstChildOfClass("Humanoid")
        local col=(b.tag=="hall") and K.orange or (b.tag=="sea3") and K.teal or Cfg.Col_Boss
        local l=NTxt(col,14); l.Text="⚔ "..b.name; l.Position=Vector2.new(p2D.X,p2D.Y-14); l.Visible=true
        local dl=NTxt(Color3.new(1,1,1),11); dl.Text=d.."m  HP "..(hum and math.floor(hum.Health) or "?")
        dl.Position=Vector2.new(p2D.X,p2D.Y+2); dl.Visible=true
        table.insert(BossPool,{lbl=l,d=dl})
    end
end

-- ============================================================
--  INIT
-- ============================================================
Switch("FARM")
for _,pl in ipairs(Players:GetPlayers()) do MkESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MkESP(pl) end)
Players.PlayerRemoving:Connect(KillESP)
LP.CharacterAdded:Connect(function()
    SetCollision(true); Farm.State="idle"; task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MkESP(pl) end
end)
local espT=0
RunService.RenderStepped:Connect(function()
    espT=espT+1; UpdP()
    if espT%12==0 then UpdF(); UpdBoss(); espT=0 end
end)

print("[China Hub Free v8.2 | Update 11] carregado — "..LP.Name)
