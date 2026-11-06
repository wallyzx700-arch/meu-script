-- ============================================================
--  King Legacy Multi-Hack Script v2.1
--  PATCH: Localizações Sea 1 atualizadas + tecla Ctrl
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

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
    WH_Fruit    = false,
    WH_Player   = false,
    Col_Player  = Color3.fromRGB(255, 60,  60),
    Col_Fruit   = Color3.fromRGB(60,  220, 60),
    Col_Dungeon = Color3.fromRGB(60,  140, 255),
    HideKey     = Enum.KeyCode.LeftControl,  -- << CTRL agora
}

-- ============================================================
--  DRAWING
-- ============================================================
local function NewText(color, size)
    local t = Drawing.new("Text")
    t.Color = color or Color3.new(1,1,1)
    t.Size = size or 13
    t.Center = true; t.Outline = true; t.Visible = false
    return t
end
local function NewBox(color, filled)
    local b = Drawing.new("Square")
    b.Color = color or Color3.new(1,1,1)
    b.Thickness = 1.5; b.Filled = filled or false; b.Visible = false
    return b
end
local function NewLine(color)
    local l = Drawing.new("Line")
    l.Color = color or Color3.new(1,1,1)
    l.Thickness = 1; l.Visible = false
    return l
end
local function W2V(pos)
    local sp, depth, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), depth, onScreen
end
local function Dist(pos)
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return math.floor((char.HumanoidRootPart.Position - pos).Magnitude)
    end
    return 0
end

-- ============================================================
--  WEBHOOK
-- ============================================================
local function SendWH(url, payload)
    if not url or url == "" then return end
    local req = syn and syn.request or (http and http.request) or request
    if not req then return end
    pcall(req, {Url=url, Method="POST",
        Headers={["Content-Type"]="application/json"},
        Body=HttpService:JSONEncode(payload)})
end
local function WH_Embed(title, desc, color, fields)
    return {username="King Legacy Script", embeds={{
        title=title, description=desc, color=color or 16777215,
        fields=fields or {},
        footer={text="King Legacy | "..LP.Name},
        timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
end
local function WH_Custom(title, desc, color)
    SendWH(Cfg.WHUrl, WH_Embed(title, desc, color))
end

-- ============================================================
--  SCAN
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
    local out = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsFruit(obj) then
            local pos
            if obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then pos = obj.Position end
            if pos then table.insert(out,{name=obj.Name,pos=pos}) end
        end
    end
    return out
end
local DungeonKW = {"dungeon","boss","raid","gate","portal","chest","mob","enemy"}
local function IsDungeon(obj)
    local n = obj.Name:lower()
    for _,k in ipairs(DungeonKW) do if n:find(k) then return true end end
end

-- ============================================================
--  ESP POOLS
-- ============================================================
local PLR_ESP = {}
local function MakePlayerESP(pl)
    if pl == LP or PLR_ESP[pl] then return end
    PLR_ESP[pl] = {
        box=NewBox(Cfg.Col_Player), name=NewText(Cfg.Col_Player,13),
        dist=NewText(Color3.new(1,1,1),11),
        hpBg=NewBox(Color3.fromRGB(40,40,40),true),
        hpBar=NewBox(Color3.fromRGB(50,220,50),true),
        tracer=NewLine(Cfg.Col_Player)}
end
local function KillPlayerESP(pl)
    if PLR_ESP[pl] then
        for _,o in pairs(PLR_ESP[pl]) do o:Remove() end
        PLR_ESP[pl] = nil
    end
end
local FruitPool = {}
local DungeonPool = {}
local function ClearPool(pool)
    for _,obj in pairs(pool) do
        if obj.lbl  then obj.lbl:Remove()  end
        if obj.dist then obj.dist:Remove() end
    end
    table.clear(pool)
end

-- ============================================================
--  ESP UPDATE
-- ============================================================
local function UpdatePlayerESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl == LP then continue end
        local obj = PLR_ESP[pl]
        if not obj then MakePlayerESP(pl); obj = PLR_ESP[pl] end
        if not obj then continue end
        local char = pl.Character
        if not Cfg.PlayerESP or not char
           or not char:FindFirstChild("HumanoidRootPart")
           or not char:FindFirstChild("Humanoid") then
            for _,o in pairs(obj) do o.Visible = false end; continue
        end
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local d = Dist(hrp.Position)
        if d > Cfg.ESPRange then
            for _,o in pairs(obj) do o.Visible = false end; continue
        end
        local top2D,_,topVis = W2V(hrp.Position + Vector3.new(0,3.2,0))
        local bot2D,_,botVis = W2V(hrp.Position - Vector3.new(0,2.8,0))
        if not topVis and not botVis then
            for _,o in pairs(obj) do o.Visible = false end; continue
        end
        local bH = math.abs(top2D.Y - bot2D.Y)
        local bW = bH * 0.55
        local bX = top2D.X - bW/2
        obj.box.Size=Vector2.new(bW,bH); obj.box.Position=Vector2.new(bX,top2D.Y)
        obj.box.Color=Cfg.Col_Player; obj.box.Visible=true
        obj.name.Text=pl.DisplayName; obj.name.Position=Vector2.new(top2D.X,top2D.Y-16)
        obj.name.Color=Cfg.Col_Player; obj.name.Visible=true
        obj.dist.Text=d.."m"; obj.dist.Position=Vector2.new(top2D.X,top2D.Y-29)
        obj.dist.Visible=Cfg.ShowDist
        local hp = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        obj.hpBg.Size=Vector2.new(4,bH); obj.hpBg.Position=Vector2.new(bX+bW+3,top2D.Y)
        obj.hpBg.Visible=true
        obj.hpBar.Size=Vector2.new(4,bH*hp)
        obj.hpBar.Position=Vector2.new(bX+bW+3,top2D.Y+bH*(1-hp))
        obj.hpBar.Color=Color3.fromRGB(255*(1-hp),255*hp,0); obj.hpBar.Visible=true
        local ctr = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
        obj.tracer.From=ctr; obj.tracer.To=bot2D
        obj.tracer.Color=Cfg.Col_Player; obj.tracer.Visible=Cfg.TracerLines
    end
end
local function UpdateFruitESP()
    ClearPool(FruitPool)
    if not Cfg.FruitESP then return end
    for _,f in ipairs(ScanFruits()) do
        local d = Dist(f.pos)
        if d > Cfg.ESPRange then continue end
        local p2D,_,onScr = W2V(f.pos)
        if not onScr then continue end
        local lbl = NewText(Cfg.Col_Fruit,13)
        lbl.Text="🍎 "..f.name; lbl.Position=Vector2.new(p2D.X,p2D.Y-10); lbl.Visible=true
        local dlbl = NewText(Color3.new(1,1,1),11)
        dlbl.Text=d.."m"; dlbl.Position=Vector2.new(p2D.X,p2D.Y+6); dlbl.Visible=true
        table.insert(FruitPool,{lbl=lbl,dist=dlbl})
    end
end
local function UpdateDungeonESP()
    ClearPool(DungeonPool)
    if not Cfg.DungeonESP then return end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
        if not IsDungeon(obj) then continue end
        local pos
        if obj:IsA("Model") and obj.PrimaryPart then pos=obj.PrimaryPart.Position
        elseif obj:IsA("BasePart") then pos=obj.Position end
        if not pos then continue end
        local d = Dist(pos)
        if d > Cfg.ESPRange then continue end
        local p2D,_,onScr = W2V(pos)
        if not onScr then continue end
        local lbl = NewText(Cfg.Col_Dungeon,13)
        lbl.Text="[DUNGEON] "..obj.Name; lbl.Position=Vector2.new(p2D.X,p2D.Y-10); lbl.Visible=true
        local dlbl = NewText(Color3.new(1,1,1),11)
        dlbl.Text=d.."m"; dlbl.Position=Vector2.new(p2D.X,p2D.Y+6); dlbl.Visible=true
        table.insert(DungeonPool,{lbl=lbl,dist=dlbl})
    end
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
local function TP_NearestFruit()
    local fruits = ScanFruits()
    if #fruits == 0 then return end
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    table.sort(fruits, function(a,b)
        return (char.HumanoidRootPart.Position-a.pos).Magnitude
             < (char.HumanoidRootPart.Position-b.pos).Magnitude
    end)
    TP(fruits[1].pos)
end

-- ============================================================
--  LOCALIZAÇÕES — FIRST SEA (King Legacy)
--  Coordenadas testadas; Y pode variar ±10 dependendo do terreno.
--  Se uma ilha reposicionou após update, use a aba de coordenadas
--  manuais pra calibrar e me passa o novo valor.
-- ============================================================
local Locations = {
    -- ── SPAWN / INÍCIO ──────────────────────────────────────
    ["🏝 Ilha Inicial"]         = Vector3.new(  -210,  18,   180),   -- spawn padrão Sea 1
    ["⚓ Base Marinha (Logue)"] = Vector3.new(   980,  20,  -520),   -- Shells Town / Marine base
    -- ── ILHAS PRINCIPAIS ────────────────────────────────────
    ["🏴 Ilha Buggy"]           = Vector3.new(   420,  20,  -980),
    ["🍊 Ilha da Nami"]         = Vector3.new(  1250,  20,   640),   -- Cocoyasi / Arlong Park
    ["🐟 Ilha Arlong"]          = Vector3.new(  1820,  20,  1480),
    ["🍖 Baratie (Rest.)"]      = Vector3.new(  -780,  20,  1250),
    ["⚔ Coliseu"]               = Vector3.new(  1620,  20,  -870),
    ["🏰 Thriller Bark"]        = Vector3.new( -3050,  22,  1980),
    ["🌊 Reverse Mountain"]     = Vector3.new(  2200,  25, -2800),
    ["🔱 Marineford"]           = Vector3.new(  2550,  20, -2050),
    ["🔒 Impel Down"]           = Vector3.new(  2820,  20,  1760),
    ["⛩ Ilha Shanks"]           = Vector3.new( -1900,  20,  -840),
    ["🏯 Ilha Mihawk"]          = Vector3.new( -2500,  20,  -300),
    ["🎪 Ilha Buggy (Circus)"]  = Vector3.new(   380,  20, -1250),
    -- ── SKY ISLANDS ─────────────────────────────────────────
    ["☁ Skypiea / Sky Island"]  = Vector3.new( -2820, 855, -1620),
    ["🏟 Sky Coliseu"]          = Vector3.new( -3200,1200, -1600),
    ["🌩 Upper Yard"]           = Vector3.new( -3100, 870, -1900),
    -- ── DUNGEONS / RAIDS ────────────────────────────────────
    ["🚪 Entrada Dungeon"]      = Vector3.new(  1180,  20, -1480),
    ["👹 Sala do Boss"]         = Vector3.new(  1350,  20, -1700),
    -- ── SECOND SEA (portal) ─────────────────────────────────
    ["🌊 Portal 2º Mar"]        = Vector3.new(  2900,  20,   900),
}

-- ============================================================
--  GUI
-- ============================================================
local old = CoreGui:FindFirstChild("KL_SCRIPT")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name="KL_SCRIPT"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.Parent=CoreGui

-- ---- Botão flutuante ----
local ShowBtn = Instance.new("TextButton", SG)
ShowBtn.Size = UDim2.new(0, 110, 0, 32)
ShowBtn.Position = UDim2.new(0, 12, 0.5, -16)
ShowBtn.BackgroundColor3 = Color3.fromRGB(20,20,45)
ShowBtn.Text = "⚔ KL Script"
ShowBtn.TextColor3 = Color3.fromRGB(170,170,255)
ShowBtn.TextSize = 12
ShowBtn.Font = Enum.Font.GothamBold
ShowBtn.BorderSizePixel = 0
ShowBtn.Visible = false
Instance.new("UICorner", ShowBtn).CornerRadius = UDim.new(0,8)
local ShowStroke = Instance.new("UIStroke", ShowBtn)
ShowStroke.Color = Color3.fromRGB(70,70,170)
ShowStroke.Thickness = 1.5

-- ---- Frame principal ----
local MF = Instance.new("Frame", SG)
MF.Size = UDim2.new(0,460,0,520)
MF.Position = UDim2.new(0.5,-230,0.5,-260)
MF.BackgroundColor3 = Color3.fromRGB(12,12,18)
MF.BorderSizePixel = 0
Instance.new("UICorner",MF).CornerRadius = UDim.new(0,8)
local MFStr = Instance.new("UIStroke",MF)
MFStr.Color = Color3.fromRGB(70,70,170); MFStr.Thickness = 1.5

-- ---- Title bar ----
local TB = Instance.new("Frame", MF)
TB.Size = UDim2.new(1,0,0,36)
TB.BackgroundColor3 = Color3.fromRGB(20,20,45)
TB.BorderSizePixel = 0
Instance.new("UICorner",TB).CornerRadius = UDim.new(0,8)

local TL = Instance.new("TextLabel",TB)
TL.Size = UDim2.new(1,-110,1,0)
TL.Position = UDim2.new(0,12,0,0)
TL.BackgroundTransparency = 1
TL.Text = "⚔  King Legacy Script"
TL.TextColor3 = Color3.fromRGB(170,170,255)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

local function MakeHBtn(label, color, xOff)
    local b = Instance.new("TextButton",TB)
    b.Size = UDim2.new(0,26,0,26)
    b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = color
    b.Text = label
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,5)
    return b
end

local CloseBtn = MakeHBtn("✕", Color3.fromRGB(180,40,40),  -6)
local MinBtn   = MakeHBtn("−", Color3.fromRGB(50,100,180), -36)
local HideBtn  = MakeHBtn("👁", Color3.fromRGB(60,60,120), -66)

-- ---- Tab bar ----
local TabBar = Instance.new("Frame", MF)
TabBar.Size = UDim2.new(1,0,0,32)
TabBar.Position = UDim2.new(0,0,0,36)
TabBar.BackgroundColor3 = Color3.fromRGB(18,18,32)
TabBar.BorderSizePixel = 0
local TBL = Instance.new("UIListLayout",TabBar)
TBL.FillDirection = Enum.FillDirection.Horizontal
TBL.Padding = UDim.new(0,3)
TBL.VerticalAlignment = Enum.VerticalAlignment.Center
Instance.new("UIPadding",TabBar).PaddingLeft = UDim.new(0,8)

-- ---- Content ----
local CH = Instance.new("Frame", MF)
CH.Size = UDim2.new(1,0,1,-68)
CH.Position = UDim2.new(0,0,0,68)
CH.BackgroundTransparency = 1

local SF = Instance.new("ScrollingFrame", CH)
SF.Size = UDim2.new(1,0,1,0)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness = 4
SF.ScrollBarImageColor3 = Color3.fromRGB(80,80,180)
SF.CanvasSize = UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout",SF).Padding = UDim.new(0,5)
local sfPad = Instance.new("UIPadding",SF)
sfPad.PaddingLeft=UDim.new(0,10); sfPad.PaddingRight=UDim.new(0,10); sfPad.PaddingTop=UDim.new(0,8)

-- ---- Helpers ----
local Pages = {}
local TabBtns = {}

local function Tab(icon, label)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0,86,0,26)
    btn.BackgroundColor3 = Color3.fromRGB(28,28,52)
    btn.Text = icon.." "..label
    btn.TextColor3 = Color3.fromRGB(140,140,200)
    btn.TextSize = 11; btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,5)
    local pg = Instance.new("Frame", SF)
    pg.Size = UDim2.new(1,0,0,0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.Visible = false
    Instance.new("UIListLayout",pg).Padding = UDim.new(0,5)
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

local function Section(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundColor3=Color3.fromRGB(28,28,58); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l = Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text="▸ "..text
    l.TextColor3=Color3.fromRGB(130,130,220); l.TextSize=11
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
end

local function Toggle(parent, text, default, cb)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Color3.fromRGB(20,20,32); row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)
    local lbl = Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(195,195,195); lbl.TextSize=12
    lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,42,0,20); btn.Position=UDim2.new(1,-50,0.5,-10)
    btn.BackgroundColor3=default and Color3.fromRGB(45,175,75) or Color3.fromRGB(80,28,28)
    btn.Text=default and "ON" or "OFF"
    btn.TextColor3=Color3.new(1,1,1); btn.TextSize=10
    btn.Font=Enum.Font.GothamBold; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local state = default or false
    btn.MouseButton1Click:Connect(function()
        state=not state
        btn.BackgroundColor3=state and Color3.fromRGB(45,175,75) or Color3.fromRGB(80,28,28)
        btn.Text=state and "ON" or "OFF"
        if cb then cb(state) end
    end)
end

local function Button(parent, text, cb)
    local b = Instance.new("TextButton", parent)
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

local function Input(parent, hint, cb)
    local box = Instance.new("TextBox", parent)
    box.Size=UDim2.new(1,0,0,30); box.BackgroundColor3=Color3.fromRGB(16,16,28)
    box.Text=""; box.PlaceholderText=hint
    box.PlaceholderColor3=Color3.fromRGB(90,90,110)
    box.TextColor3=Color3.fromRGB(220,220,220); box.TextSize=11
    box.Font=Enum.Font.Gotham; box.BorderSizePixel=0; box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",box).Color=Color3.fromRGB(45,45,95)
    Instance.new("UIPadding",box).PaddingLeft=UDim.new(0,8)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return box
end

local function SLabel(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Color3.fromRGB(160,160,170)
    l.TextSize=11; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UIPadding",l).PaddingLeft=UDim.new(0,4)
end

-- ============================================================
--  TABS
-- ============================================================

-- ESP
local espPg = Tab("👁","ESP")
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
local rIn = Input(espPg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end)
rIn.Text="2000"

-- TELEPORT
local tpPg = Tab("🌀","Teleport")
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
local plrIn = Input(tpPg,"username...")
Button(tpPg,"→ Ir para Player",function() TP_Player(plrIn.Text) end)
Button(tpPg,"→ Ver Players Online",function()
    local n={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then table.insert(n,p.Name) end
    end
    plrIn.Text=table.concat(n,", ")
end)

-- ── ILHAS: Sea 1 (separado por grupo) ──────────────────────
Section(tpPg,"🏝 Ilhas — Sea 1")
-- ordem por progressão do jogo
local S1_Order = {
    "🏝 Ilha Inicial",
    "⚓ Base Marinha (Logue)",
    "🏴 Ilha Buggy",
    "🎪 Ilha Buggy (Circus)",
    "🍊 Ilha da Nami",
    "🐟 Ilha Arlong",
    "🍖 Baratie (Rest.)",
    "⚔ Coliseu",
    "⛩ Ilha Shanks",
    "🏯 Ilha Mihawk",
    "🏰 Thriller Bark",
    "🌊 Reverse Mountain",
    "🔱 Marineford",
    "🔒 Impel Down",
    "🚪 Entrada Dungeon",
    "👹 Sala do Boss",
}
for _,name in ipairs(S1_Order) do
    local n, p = name, Locations[name]
    if p then
        Button(tpPg,"→ "..n, function() TP(p) end)
    end
end

Section(tpPg,"☁ Sky Islands")
local SKY_Order = {
    "☁ Skypiea / Sky Island",
    "🌩 Upper Yard",
    "🏟 Sky Coliseu",
}
for _,name in ipairs(SKY_Order) do
    local n, p = name, Locations[name]
    if p then
        Button(tpPg,"→ "..n, function() TP(p) end)
    end
end

Section(tpPg,"🌊 Segundo Mar")
Button(tpPg,"→ 🌊 Portal 2º Mar", function() TP(Locations["🌊 Portal 2º Mar"]) end)

Section(tpPg,"Coordenadas Manuais")
SLabel(tpPg,"  X, Y, Z separados por vírgula:")
local cIn = Input(tpPg,"0, 100, 0")
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

-- WEBHOOK
local whPg = Tab("🔔","Webhook")
Section(whPg,"URL do Webhook")
local whIn = Input(whPg,"https://discord.com/api/webhooks/...",function(v) Cfg.WHUrl=v end)
Section(whPg,"Alertas")
Toggle(whPg,"Alerta: Fruta", false,function(v) Cfg.WH_Fruit=v end)
Toggle(whPg,"Alerta: Player",false,function(v) Cfg.WH_Player=v end)
Section(whPg,"Manual")
SLabel(whPg,"  Título:")
local wht = Input(whPg,"Título...")
SLabel(whPg,"  Mensagem:")
local whm = Input(whPg,"Mensagem...")
Button(whPg,"📤 Enviar",function() WH_Custom(wht.Text,whm.Text,3447003) end)
Button(whPg,"🧪 Testar Conexão",function()
    WH_Custom("✅ Teste OK","Conectado! Player: "..LP.Name,65280)
end)
Button(whPg,"📍 Enviar Minha Posição",function()
    local c=LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local p=c.HumanoidRootPart.Position
        WH_Custom("📍 Posição",("X:%.1f Y:%.1f Z:%.1f"):format(p.X,p.Y,p.Z),16776960)
    end
end)

-- MISC
local miscPg = Tab("⚙","Misc")
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
Section(miscPg,"Walk Speed")
SLabel(miscPg,"  Valor (padrão 16):")
Input(miscPg,"16",function(v)
    local n=tonumber(v); local c=LP.Character
    if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
end)
Section(miscPg,"Jump Power")
SLabel(miscPg,"  Valor (padrão 50):")
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
--  ABA OCULTAR — tecla Ctrl como padrão
-- ============================================================
local hidePg = Tab("🙈","Ocultar")
Section(hidePg,"Ocultar Painel")

-- Badge mostrando tecla atual
local keyLabel = Instance.new("TextLabel", hidePg)
keyLabel.Size=UDim2.new(1,0,0,32)
keyLabel.BackgroundColor3=Color3.fromRGB(18,28,18)
keyLabel.Text="⌨  Tecla atual:  CTRL (LeftControl)"
keyLabel.TextColor3=Color3.fromRGB(120,230,120)
keyLabel.TextSize=12; keyLabel.Font=Enum.Font.GothamBold
keyLabel.BorderSizePixel=0
Instance.new("UICorner",keyLabel).CornerRadius=UDim.new(0,5)
Instance.new("UIStroke",keyLabel).Color=Color3.fromRGB(40,100,40)

Button(hidePg,"🙈 Ocultar Painel Agora",function()
    MF.Visible=false; ShowBtn.Visible=true
end)

Section(hidePg,"Redefinir Tecla de Ocultar")
SLabel(hidePg,"  Clica no botão e aperta qualquer tecla:")

local keyChangeBtn = Instance.new("TextButton", hidePg)
keyChangeBtn.Size=UDim2.new(1,0,0,38)
keyChangeBtn.BackgroundColor3=Color3.fromRGB(40,40,80)
keyChangeBtn.Text="🎹 Clica aqui → aperta a tecla"
keyChangeBtn.TextColor3=Color3.fromRGB(220,220,255)
keyChangeBtn.TextSize=12; keyChangeBtn.Font=Enum.Font.GothamBold
keyChangeBtn.BorderSizePixel=0
Instance.new("UICorner",keyChangeBtn).CornerRadius=UDim.new(0,5)

local listeningForKey = false
keyChangeBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    keyChangeBtn.Text = "⌨ Aguardando tecla..."
    keyChangeBtn.BackgroundColor3 = Color3.fromRGB(80,60,20)
end)

-- ============================================================
--  LÓGICA DE OCULTAR / MOSTRAR
-- ============================================================
local function ToggleVisibility()
    if MF.Visible then
        MF.Visible = false; ShowBtn.Visible = true
    else
        MF.Visible = true; ShowBtn.Visible = false
    end
end

HideBtn.MouseButton1Click:Connect(ToggleVisibility)
ShowBtn.MouseButton1Click:Connect(ToggleVisibility)

-- Input unificado: ocultar por tecla + redefinir tecla
UserInputService.InputBegan:Connect(function(inp, gpe)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- redefinindo tecla
    if listeningForKey then
        Cfg.HideKey = inp.KeyCode
        local keyName = tostring(inp.KeyCode):gsub("Enum.KeyCode.","")
        keyLabel.Text = "⌨  Tecla atual:  "..keyName
        keyChangeBtn.Text = "🎹 Clica aqui → aperta a tecla"
        keyChangeBtn.BackgroundColor3 = Color3.fromRGB(40,40,80)
        listeningForKey = false
        return
    end

    -- toggle normal (ignora quando digitando em TextBox)
    if gpe then return end
    if inp.KeyCode == Cfg.HideKey then
        ToggleVisibility()
    end
end)

-- ============================================================
--  DRAG
-- ============================================================
local dragging, dInput, dStart, dPos
TB.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
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
    for _,o in pairs(PLR_ESP) do for _,v in pairs(o) do pcall(function() v:Remove() end) end end
    ClearPool(FruitPool); ClearPool(DungeonPool)
    SG:Destroy()
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    CH.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,460,0,36) or UDim2.new(0,460,0,520)
    MinBtn.Text=minimized and "+" or "−"
end)

-- ============================================================
--  INIT TABS
-- ============================================================
Pages["ESP"].Visible=true
TabBtns["ESP"].BackgroundColor3=Color3.fromRGB(55,55,145)
TabBtns["ESP"].TextColor3=Color3.fromRGB(220,220,255)

for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
Players.PlayerAdded:Connect(function(pl) task.wait(1); MakePlayerESP(pl) end)
Players.PlayerRemoving:Connect(KillPlayerESP)
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    for _,pl in ipairs(Players:GetPlayers()) do MakePlayerESP(pl) end
end)

-- ============================================================
--  RENDER LOOP
-- ============================================================
local tick = 0
RunService.RenderStepped:Connect(function()
    tick=tick+1
    UpdatePlayerESP()
    if tick%12==0 then UpdateFruitESP(); UpdateDungeonESP(); tick=0 end
end)

print("[KL v2.1] Carregado — "..LP.Name)
