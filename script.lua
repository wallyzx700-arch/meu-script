    local function SetSt(key)
        if cb then cb(key) end
        for _,sb in ipairs(sBtns) do
            local active=sb[1]==key
            Tw(sb[2],0.14,{BackgroundColor3=active and C.acc or C.card})
            sb[3].TextColor3=active and Color3.new(1,1,1) or C.dim
            sb[3].Font=active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    for _,st in ipairs(stList) do
        local b=Instance.new("TextButton",sRow)
        b.Size=UDim2.new(0,100,1,0); b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(st[1]==def) and C.acc or C.card
        b.BackgroundTransparency=0; Rnd(b,7); b.ZIndex=11
        if st[1]~=def then Str(b,C.bord,1) end
        local l=Instance.new("TextLabel",b)
        l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=st[2]; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(st[1]==def) and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(st[1]==def) and Color3.new(1,1,1) or C.dim; l.ZIndex=12
        table.insert(sBtns,{st[1],b,l})
        b.MouseButton1Click:Connect(function() SetSt(st[1]) end)
    end
end

-- ============================================================
--  FARM PAGE
-- ============================================================
do
    local pg=Pages["FARM"]
    local dot,sl=MkStatus(pg,C.green)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=Farm.Active and Farm.StatusText or "Inativo"
        dot.BackgroundColor3=Farm.Active and C.green or C.red
    end end)

    Sec(pg,"⚔ Auto Farm")
    Tog(pg,"Ativar Auto Farm",false,function(v)
        Farm.Active=v; if not v then Farm.State="idle"; SetCollision(true) end
    end)
    Tog(pg,"Aceitar Quest automaticamente",true,function(v) Farm.UseQuest=v end)
    Tog(pg,"Kill Aura",false,function(v) Farm.KillAura=v end)

    Sec(pg,"Estilo de Luta")
    StyleRow(pg,"melee",function(k) Farm.Style=k end)

    Sec(pg,"Configuração")
    Lbl(pg,"  Altura hover (studs):")
    Inp(pg,"5",function(v) local n=tonumber(v); if n and n>0 then Farm.HoverY=n end end).Text="5"
    Lbl(pg,"  Kill Aura range (studs):")
    Inp(pg,"200",function(v) local n=tonumber(v); if n then Farm.KillAuraRange=n end end).Text="200"
    Lbl(pg,"  Mobs por ciclo:")
    Inp(pg,"10",function(v) local n=tonumber(v); if n and n>0 then Farm.TargetKills=math.floor(n) end end).Text="10"

    Sec(pg,"Calibrar Zonas (2°/3° Mar)")
    Lbl(pg,"  Vá até o ponto e clique calibrar.")

    local selIdx=1
    local selL=Instance.new("TextLabel",pg)
    selL.Size=UDim2.new(1,0,0,32); selL.BackgroundColor3=C.card
    selL.BackgroundTransparency=0; selL.BorderSizePixel=0; Rnd(selL,7); Str(selL,C.bord,1)
    selL.Text="  "..Zones[1].name.."  Lv "..Zones[1].minLv.."-"..Zones[1].maxLv
    selL.TextColor3=C.acc2; selL.TextSize=11; selL.Font=Enum.Font.GothamBold
    selL.TextXAlignment=Enum.TextXAlignment.Left; selL.ZIndex=10; Pad(selL,10,0,0,0)

    local navRow=Instance.new("Frame",pg); navRow.Size=UDim2.new(1,0,0,34)
    navRow.BackgroundTransparency=1; navRow.ZIndex=10
    Lst(navRow,Enum.FillDirection.Horizontal,6)
    local function NavBtn(t2,cb2)
        local b=Instance.new("TextButton",navRow); b.Size=UDim2.new(0.5,-3,1,0)
        b.BackgroundColor3=C.card; b.BackgroundTransparency=0
        b.Text=t2; b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0; Rnd(b,7); Str(b,C.bord,1); b.ZIndex=11
        b.MouseEnter:Connect(function() Tw(b,0.1,{BackgroundColor3=C.cardH}) end)
        b.MouseLeave:Connect(function() Tw(b,0.1,{BackgroundColor3=C.card}) end)
        b.MouseButton1Click:Connect(cb2)
    end
    NavBtn("◄ Anterior",function()
        selIdx=math.max(1,selIdx-1)
        local z=Zones[selIdx]; selL.Text="  "..z.name.."  Lv "..z.minLv.."-"..z.maxLv
        selL.TextColor3=C.acc2
    end)
    NavBtn("Próxima ►",function()
        selIdx=math.min(#Zones,selIdx+1)
        local z=Zones[selIdx]; selL.Text="  "..z.name.."  Lv "..z.minLv.."-"..z.maxLv
        selL.TextColor3=C.acc2
    end)

    Btn(pg,"Calibrar Posição NPC Quest",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        selL.Text="  ✅ "..Zones[selIdx].name.." quest calibrado"; selL.TextColor3=C.green
    end)
    Btn(pg,"Calibrar Posição dos Mobs",function()
        local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        local pos=c.HumanoidRootPart.Position
        Zones[selIdx].mobPos=pos; Zones[selIdx].islePos=pos; Zones[selIdx].calibrate=nil
        selL.Text="  ✅ "..Zones[selIdx].name.." mobs calibrado"; selL.TextColor3=C.green
    end)
    Btn(pg,"Copiar Posição Atual",function()
        local c=LP.Character; if c and c:FindFirstChild("HumanoidRootPart") then
            local pos=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(pos.X,pos.Y,pos.Z)
            pcall(function() setclipboard(s) end)
            selL.Text="  Copiado: "..s; selL.TextColor3=C.acc2
        end
    end)

    Sec(pg,"Zonas")
    for _,z in ipairs(Zones) do
        Lbl(pg,("  Lv %4d–%-4d  %s%s"):format(z.minLv,z.maxLv,z.name,z.calibrate and "  ⚠" or ""),
            z.calibrate and C.orange or C.dim)
    end
end

-- ============================================================
--  BOSS PAGE
-- ============================================================
do
    local pg=Pages["BOSS"]
    local dot,sl=MkStatus(pg,C.red)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=BossConfig.Active and BossConfig.StatusText or "Inativo"
        dot.BackgroundColor3=BossConfig.Active and C.green or C.red
    end end)

    local infoCard=Instance.new("Frame",pg)
    infoCard.Size=UDim2.new(1,0,0,34); infoCard.BackgroundColor3=Color3.fromRGB(8,16,30)
    infoCard.BackgroundTransparency=0; infoCard.BorderSizePixel=0; Rnd(infoCard,8)
    Str(infoCard,Color3.fromRGB(0,80,160),1); infoCard.ZIndex=10
    local infoL=Instance.new("TextLabel",infoCard)
    infoL.Size=UDim2.new(1,0,1,0); infoL.BackgroundTransparency=1
    infoL.Text="🌊 Sea3: Depth King · Drakenfyr · Abyssal · Crab King · Kraken"
    infoL.TextColor3=Color3.fromRGB(80,170,255); infoL.TextSize=10; infoL.Font=Enum.Font.GothamBold
    infoL.TextXAlignment=Enum.TextXAlignment.Center; infoL.ZIndex=11

    Sec(pg,"👑 Auto Boss")
    Tog(pg,"Ativar Auto Boss",false,function(v) BossConfig.Active=v end)
    Sec(pg,"Selecionar Boss")

    local tagColor={sea3=C.teal, hall=C.orange, raid=C.purple}
    local selBtns={}
    for _,b in ipairs(BossList) do
        local row=Instance.new("Frame",pg)
        row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=C.card
        row.BackgroundTransparency=0; row.BorderSizePixel=0; Rnd(row,8); row.ZIndex=10

        local ac=tagColor[b.tag] or C.dim
        if b.tag~="" then
            local leftBar=Instance.new("Frame",row)
            leftBar.Size=UDim2.new(0,3,0.6,0); leftBar.Position=UDim2.new(0,0,0.2,0)
            leftBar.BackgroundColor3=ac; leftBar.BorderSizePixel=0; Rnd(leftBar,2); leftBar.ZIndex=11
        end

        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=b.name.."  —  "..b.notes
        lbl.TextColor3=b.tag~="" and ac or C.text; lbl.TextSize=10
        lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11

        local sel=Instance.new("TextButton",row)
        sel.Size=UDim2.new(0,42,0,24); sel.Position=UDim2.new(1,-50,0.5,-12)
        sel.Text="SEL"; sel.TextColor3=C.text; sel.TextSize=10; sel.Font=Enum.Font.GothamBold
        sel.BackgroundColor3=(BossConfig.SelectedBoss==b.name) and C.acc or C.card
        sel.BorderSizePixel=0; Rnd(sel,5); sel.ZIndex=12
        table.insert(selBtns,{name=b.name, btn=sel})

        sel.MouseButton1Click:Connect(function()
            BossConfig.SelectedBoss=b.name
            for _,sb in ipairs(selBtns) do
                Tw(sb.btn,0.12,{BackgroundColor3=sb.name==b.name and C.acc or C.card})
            end
            sl.Text="Boss: "..b.name
        end)
    end

    Sec(pg,"Configuração")
    StyleRow(pg,"melee",function(k) BossConfig.Style=k end)
    Lbl(pg,"  Altura hover:")
    Inp(pg,"5",function(v) local n=tonumber(v); if n then BossConfig.HoverY=n end end).Text="5"
end

-- ============================================================
--  DUNGEON PAGE
-- ============================================================
do
    local pg=Pages["DUNGEON"]
    local dot,sl=MkStatus(pg,C.green)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=DungeonConfig.Active and DungeonConfig.StatusText or "Inativo"
        dot.BackgroundColor3=DungeonConfig.Active and C.green or C.red
    end end)

    Sec(pg,"🏯 Auto Dungeon")
    Lbl(pg,"  Calibre a posição de cada dungeon abaixo.")
    Tog(pg,"Ativar Auto Dungeon",false,function(v) DungeonConfig.Active=v end)
    Sec(pg,"Posições das Dungeons")

    for _,d in ipairs({{lab="1° Mar",key="Pos1"},{lab="2° Mar",key="Pos2"},{lab="3° Mar",key="Pos3"}}) do
        Lbl(pg,"  "..d.lab..":")
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,34)
        row.BackgroundTransparency=1; row.ZIndex=10
        Lst(row,Enum.FillDirection.Horizontal,6)

        local posL=Instance.new("TextLabel",row); posL.Size=UDim2.new(0.6,0,1,0)
        posL.BackgroundColor3=C.card; posL.BackgroundTransparency=0; posL.Text="Não calibrado"
        posL.TextColor3=C.dim; posL.TextSize=10; posL.Font=Enum.Font.Gotham
        posL.TextXAlignment=Enum.TextXAlignment.Center; posL.BorderSizePixel=0
        Rnd(posL,7); Str(posL,C.bord,1); posL.ZIndex=11

        local calBtn=Instance.new("TextButton",row); calBtn.Size=UDim2.new(0.4,-6,1,0)
        calBtn.BackgroundColor3=C.acc; calBtn.Text="Calibrar"; calBtn.TextColor3=C.text
        calBtn.TextSize=10; calBtn.Font=Enum.Font.GothamBold; calBtn.BorderSizePixel=0
        Rnd(calBtn,7); calBtn.ZIndex=11

        local dk=d.key
        calBtn.MouseButton1Click:Connect(function()
            local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
            local pos=c.HumanoidRootPart.Position; DungeonConfig[dk]=pos
            posL.Text=("%.0f, %.0f, %.0f"):format(pos.X,pos.Y,pos.Z); posL.TextColor3=C.green
        end)
    end

    Sec(pg,"Configuração")
    StyleRow(pg,"melee",function(k) DungeonConfig.Style=k end)
    Lbl(pg,"  Altura hover:")
    Inp(pg,"5",function(v) local n=tonumber(v); if n then DungeonConfig.HoverY=n end end).Text="5"
end

-- ============================================================
--  SEAS PAGE — Sea Events + Sea Hoop unificados
-- ============================================================
do
    local pg=Pages["SEAS"]
    local seaSubMode="events"

    -- status bar único — atualiza conforme sub-aba ativa
    local dot,sl=MkStatus(pg,C.teal)
    task.spawn(function() while SG.Parent do task.wait(0.5)
        if seaSubMode=="events" then
            sl.Text=SeaEvent.Active and SeaEvent.StatusText or "Events inativo"
            dot.BackgroundColor3=SeaEvent.Active and C.green or C.red
        else
            sl.Text=AutoHoop.Active and AutoHoop.StatusText or "Hoop inativo"
            dot.BackgroundColor3=AutoHoop.Active and C.teal or C.red
        end
    end end)

    -- sub-tab switcher
    local switcher=Instance.new("Frame",pg)
    switcher.Size=UDim2.new(1,0,0,40); switcher.BackgroundColor3=C.card
    switcher.BackgroundTransparency=0; switcher.BorderSizePixel=0
    Rnd(switcher,8); Str(switcher,C.bord,1); switcher.ZIndex=10
    Pad(switcher,4,4,4,4)
    Lst(switcher,Enum.FillDirection.Horizontal,4)

    -- content frames
    local evFrame=Instance.new("Frame",pg)
    evFrame.Size=UDim2.new(1,0,0,0); evFrame.AutomaticSize=Enum.AutomaticSize.Y
    evFrame.BackgroundTransparency=1; evFrame.ZIndex=10; Lst(evFrame,Enum.FillDirection.Vertical,6)

    local hoopFrame=Instance.new("Frame",pg)
    hoopFrame.Size=UDim2.new(1,0,0,0); hoopFrame.AutomaticSize=Enum.AutomaticSize.Y
    hoopFrame.BackgroundTransparency=1; hoopFrame.ZIndex=10; hoopFrame.Visible=false
    Lst(hoopFrame,Enum.FillDirection.Vertical,6)

    local subBtns={}
    local function SwitchSea(mode)
        seaSubMode=mode
        evFrame.Visible=(mode=="events"); hoopFrame.Visible=(mode=="hoop")
        for _,sb in ipairs(subBtns) do
            local active=(sb.mode==mode)
            Tw(sb.btn,0.14,{BackgroundColor3=active and C.teal or C.card})
            sb.lbl.TextColor3=active and Color3.new(1,1,1) or C.dim
            sb.lbl.Font=active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
    local function SubBtn(label, mode)
        local b=Instance.new("TextButton",switcher); b.Size=UDim2.new(0.5,-6,1,0)
        b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(mode=="events") and C.teal or C.card
        b.BackgroundTransparency=0; Rnd(b,6); b.ZIndex=11
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0)
        l.BackgroundTransparency=1; l.Text=label; l.TextSize=10
        l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(mode=="events") and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(mode=="events") and Color3.new(1,1,1) or C.dim; l.ZIndex=12
        table.insert(subBtns,{mode=mode,btn=b,lbl=l})
        b.MouseButton1Click:Connect(function() SwitchSea(mode) end)
    end
    SubBtn("🌊  Sea Events","events")
    SubBtn("🔀  Sea Hoop","hoop")

    -- ---- SEA EVENTS ----
    do
        local function S(t) Sec(evFrame,t,C.teal) end
        S("Eventos do Mar")
        Tog(evFrame,"Ativar Sea Events",false,function(v) SeaEvent.Active=v end)
        Tog(evFrame,"Sea Beast",true,function(v) SeaEvent.SeaBeast=v end)
        Tog(evFrame,"Ghost Ship",false,function(v) SeaEvent.GhostShip=v end)
        Tog(evFrame,"Pteranodon (spawn 2h)",false,function(v) SeaEvent.Pteranodon=v end)
        Tog(evFrame,"Serpente (spawn 1h30)",false,function(v) SeaEvent.Serpent=v end)
        S("Configuração")
        StyleRow(evFrame,"melee",function(k) SeaEvent.Style=k end)
        Lbl(evFrame,"  Altura hover:")
        Inp(evFrame,"8",function(v) local n=tonumber(v); if n then SeaEvent.HoverY=n end end).Text="8"
        S("Server Hop Manual")
        Btn(evFrame,"🔀  Server Hop Agora",function() ServerHop() end,true)
    end

    -- ---- SEA HOOP ----
    do
        local function S(t) Sec(hoopFrame,t,C.teal) end
        S("Boss Alvo")
        local hoopSelBtns={}
        for _,t in ipairs(HoopTargets) do
            local row=Instance.new("Frame",hoopFrame)
            row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=C.card
            row.BackgroundTransparency=0; row.BorderSizePixel=0; Rnd(row,8); Str(row,C.bord,1); row.ZIndex=10

            local leftBar=Instance.new("Frame",row)
            leftBar.Size=UDim2.new(0,3,0.6,0); leftBar.Position=UDim2.new(0,0,0.2,0)
            leftBar.BackgroundColor3=C.teal; leftBar.BorderSizePixel=0; Rnd(leftBar,2); leftBar.ZIndex=11

            local lbl=Instance.new("TextLabel",row)
            lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,12,0,0)
            lbl.BackgroundTransparency=1; lbl.Text=t.name.."  —  "..t.notes
            lbl.TextColor3=(AutoHoop.TargetBoss==t.name) and C.teal or C.text
            lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=11

            local sel=Instance.new("TextButton",row)
            sel.Size=UDim2.new(0,42,0,24); sel.Position=UDim2.new(1,-50,0.5,-12)
            sel.Text="SEL"; sel.TextColor3=C.text; sel.TextSize=10; sel.Font=Enum.Font.GothamBold
            sel.BackgroundColor3=(AutoHoop.TargetBoss==t.name) and C.teal or C.card
            sel.BorderSizePixel=0; Rnd(sel,5); sel.ZIndex=12
            table.insert(hoopSelBtns,{name=t.name,btn=sel,lbl=lbl})

            local tn=t.name
            sel.MouseButton1Click:Connect(function()
                AutoHoop.TargetBoss=tn
                for _,sb in ipairs(hoopSelBtns) do
                    local active=(sb.name==tn)
                    Tw(sb.btn,0.12,{BackgroundColor3=active and C.teal or C.card})
                    sb.lbl.TextColor3=active and C.teal or C.text
                end
            end)
        end

        S("Ativar")
        Tog(hoopFrame,"Auto Sea Hoop",false,function(v)
            AutoHoop.Active=v
            if not v then AutoHoop._scanTimer=0; AutoHoop._found=false end
        end)
        Tog(hoopFrame,"Farmar boss ao encontrar",true,function(v) AutoHoop.FightOnFind=v end)

        S("Configuração")
        Lbl(hoopFrame,"  Scan antes de hopar (seg):")
        Inp(hoopFrame,"10",function(v) local n=tonumber(v); if n and n>=2 then AutoHoop.ScanTime=n end end).Text="10"
        StyleRow(hoopFrame,"melee",function(k) AutoHoop.Style=k end)
        Lbl(hoopFrame,"  Altura hover:")
        Inp(hoopFrame,"8",function(v) local n=tonumber(v); if n then AutoHoop.HoverY=n end end).Text="8"
    end
end

-- ============================================================
--  HALLOWEEN PAGE
-- ============================================================
do
    local pg=Pages["HALLOWEEN"]
    local dot,sl=MkStatus(pg,C.orange)
    task.spawn(function() while SG.Parent do task.wait(0.5)
        sl.Text=Halloween.Active and Halloween.StatusText or "Inativo"
        dot.BackgroundColor3=Halloween.Active and C.orange or C.red
    end end)

    local ban=Instance.new("Frame",pg)
    ban.Size=UDim2.new(1,0,0,46); ban.BackgroundColor3=Color3.fromRGB(18,8,4)
    ban.BackgroundTransparency=0; ban.BorderSizePixel=0; Rnd(ban,8); Str(ban,C.orange,1.5); ban.ZIndex=10
    local banL=Instance.new("TextLabel",ban)
    banL.Size=UDim2.new(1,0,0.55,0); banL.Position=UDim2.new(0,0,0,4)
    banL.BackgroundTransparency=1; banL.Text="🎃  Halloween Event — Update 11  🎃"
    banL.TextColor3=C.orange; banL.TextSize=13; banL.Font=Enum.Font.GothamBold
    banL.TextXAlignment=Enum.TextXAlignment.Center; banL.ZIndex=11
    local banS=Instance.new("TextLabel",ban)
    banS.Size=UDim2.new(1,0,0.4,0); banS.Position=UDim2.new(0,0,0.6,0)
    banS.BackgroundTransparency=1
    banS.Text="Depth King · Skull King · Jack-o'-Lantern · Candy Farm"
    banS.TextColor3=C.gold; banS.TextSize=9; banS.Font=Enum.Font.Gotham
    banS.TextXAlignment=Enum.TextXAlignment.Center; banS.ZIndex=11

    Sec(pg,"Modo",C.orange)
    local modeRow=Instance.new("Frame",pg); modeRow.Size=UDim2.new(1,0,0,36)
    modeRow.BackgroundTransparency=1; modeRow.ZIndex=10
    Lst(modeRow,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Left)
    local modeBtns={}
    local modeList={{"candy","🍬 Candy"},{"jacko","🎃 Jack-O"},{"skullking","💀 Skull"},{"depthking","🐢 Depth"}}
    local function SetMode(key)
        Halloween.Mode=key
        for _,mb in ipairs(modeBtns) do
            local active=(mb[1]==key)
            Tw(mb[2],0.14,{BackgroundColor3=active and C.orange or C.card})
            mb[3].TextColor3=active and Color3.new(1,1,1) or C.dim
        end
    end
    for _,m in ipairs(modeList) do
        local b=Instance.new("TextButton",modeRow); b.Size=UDim2.new(0.25,-3,1,0)
        b.Text=""; b.BorderSizePixel=0
        b.BackgroundColor3=(m[1]==Halloween.Mode) and C.orange or C.card
        b.BackgroundTransparency=0; Rnd(b,7); b.ZIndex=11
        if m[1]~=Halloween.Mode then Str(b,C.bord,1) end
        local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,0,1,0)
        l.BackgroundTransparency=1; l.Text=m[2]; l.TextSize=9
        l.TextXAlignment=Enum.TextXAlignment.Center
        l.Font=(m[1]==Halloween.Mode) and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextColor3=(m[1]==Halloween.Mode) and Color3.new(1,1,1) or C.dim; l.ZIndex=12
        table.insert(modeBtns,{m[1],b,l})
        b.MouseButton1Click:Connect(function() SetMode(m[1]) end)
    end

    Sec(pg,"Mar Alvo",C.orange)
    local seaRow=Instance.new("Frame",pg); seaRow.Size=UDim2.new(1,0,0,34)
    seaRow.BackgroundTransparency=1; seaRow.ZIndex=10
    Lst(seaRow,Enum.FillDirection.Horizontal,6)
    local seaBtns={}
    local function SetSea(s)
        Halloween.Sea=s
        for _,sb in ipairs(seaBtns) do
            Tw(sb[2],0.14,{BackgroundColor3=sb[1]==s and C.orange or C.card})
        end
    end
    for _,s in ipairs({1,2,3}) do
        local b=Instance.new("TextButton",seaRow); b.Size=UDim2.new(0,100,1,0)
        b.Text=s.."° Mar"; b.BorderSizePixel=0
        b.BackgroundColor3=(s==Halloween.Sea) and C.orange or C.card
        b.TextColor3=C.text; b.TextSize=11; b.Font=Enum.Font.GothamBold
        b.BackgroundTransparency=0; Rnd(b,7); b.ZIndex=11
        table.insert(seaBtns,{s,b})
        b.MouseButton1Click:Connect(function() SetSea(s) end)
    end

    Sec(pg,"Ativar",C.orange)
    Tog(pg,"Auto Halloween Event",false,function(v) Halloween.Active=v end)
    Tog(pg,"Auto Summon Jack-o'-Lantern",false,function(v) Halloween.AutoSummonJO=v end)

    Sec(pg,"Calibrar Halloween Islands",C.orange)
    for _,hi in ipairs({{1,"1° Mar"},{2,"2° Mar"},{3,"3° Mar"}}) do
        local seaN,seaL=hi[1],hi[2]; Lbl(pg,"  "..seaL..":")
        local row=Instance.new("Frame",pg); row.Size=UDim2.new(1,0,0,32)
        row.BackgroundTransparency=1; row.ZIndex=10
        Lst(row,Enum.FillDirection.Horizontal,6)
        local curPos=HalloweenPos[seaN]
        local posL=Instance.new("TextLabel",row); posL.Size=UDim2.new(0.55,0,1,0)
        posL.BackgroundColor3=C.card; posL.BackgroundTransparency=0
        posL.Text=(curPos==Vector3.new(0,100,0)) and "Não calibrado" or ("%.0f,%.0f,%.0f"):format(curPos.X,curPos.Y,curPos.Z)
        posL.TextColor3=(curPos==Vector3.new(0,100,0)) and C.dim or C.green
        posL.TextSize=9; posL.Font=Enum.Font.Gotham; posL.TextXAlignment=Enum.TextXAlignment.Center
        posL.BorderSizePixel=0; Rnd(posL,6); Str(posL,C.bord,1); posL.ZIndex=11
        local calBtn=Instance.new("TextButton",row); calBtn.Size=UDim2.new(0.24,-6,1,0)
        calBtn.BackgroundColor3=C.orange; calBtn.Text="Calibrar"; calBtn.TextColor3=C.text
        calBtn.TextSize=9; calBtn.Font=Enum.Font.GothamBold; calBtn.BorderSizePixel=0; Rnd(calBtn,6); calBtn.ZIndex=11
        local tpBtn=Instance.new("TextButton",row); tpBtn.Size=UDim2.new(0.21,-6,1,0)
        tpBtn.BackgroundColor3=C.card; tpBtn.Text="Ir"; tpBtn.TextColor3=C.text
        tpBtn.TextSize=9; tpBtn.Font=Enum.Font.GothamBold; tpBtn.BorderSizePixel=0
        Rnd(tpBtn,6); Str(tpBtn,C.bord,1); tpBtn.ZIndex=11
        local sn=seaN
        calBtn.MouseButton1Click:Connect(function()
            local c=LP.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return end
            local pos=c.HumanoidRootPart.Position; HalloweenPos[sn]=pos
            posL.Text=("%.0f,%.0f,%.0f"):format(pos.X,pos.Y,pos.Z); posL.TextColor3=C.green
        end)
        tpBtn.MouseButton1Click:Connect(function() SafeTP(HalloweenPos[sn]) end)
    end

    Sec(pg,"Estilo & Configuração",C.orange)
    StyleRow(pg,"melee",function(k) Halloween.Style=k end)
    Lbl(pg,"  Altura hover:")
    Inp(pg,"6",function(v) local n=tonumber(v); if n then Halloween.HoverY=n end end).Text="6"

    Sec(pg,"Drops — Jack-o'-Lantern",C.gold)
    for _,d in ipairs({
        "Pumpkin Smasher  2.25%  (ou 1000 Candy + 100 Logs)",
        "Pumpkin Head  4.5%  (ou 350 Candy)",
        "Hallo Shawl  6.75%  (ou 750 Candy)",
        "Hallow Lamp  9%  (ou 500 Candy)",
    }) do Lbl(pg,"  🎃 "..d, C.gold) end
    Sec(pg,"Drops — Skull King",C.gold)
    for _,d in ipairs({
        "Bone Scythe  3.375%  (ou 1500 Candy + mats)",
        "Sea King Skull  4.5%  (ou 750 Candy + mats)",
        "Candy — drop comum",
    }) do Lbl(pg,"  💀 "..d, C.gold) end
end

-- ============================================================
--  FRUTAS PAGE
-- ============================================================
do
    local pg=Pages["FRUTAS"]
    local dot,sl=MkStatus(pg,C.gold)
    task.spawn(function() while SG.Parent do task.wait(0.7)
        sl.Text=FruitNotifier.Active and FruitNotifier.StatusText or "Notifier inativo"
        dot.BackgroundColor3=FruitNotifier.Active and C.gold or C.red
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
        local ok,fr=TP_NearestLegendary()
        sl.Text=ok and ("TP: "..fr.name) or "Sem lendária no servidor."
    end, false, Color3.fromRGB(70,50,8))
    Btn(pg,"Ir para Qualquer Fruta",TP_NearestFruit)

    Sec(pg,"Lendárias (Upd11)")
    for _,f in ipairs({
        "Erebus  (Mítica — Upd11, dragon negro)",
        "Loki  (Lendária — Upd11)",
        "Pteranodon  (Mítica — Upd10)",
        "Dragon  (Lendária, rework Upd11)",
        "Toy · Phoenix · Tree · Demon",
        "Gold · Dough · Leopard",
        "Portal/Gate · Gravity · Shadow",
    }) do Lbl(pg,"  🍎 "..f, C.gold) end
end

-- ============================================================
--  ESP PAGE
-- ============================================================
do
    local pg=Pages["ESP"]
    Sec(pg,"👁 Jogadores")
    Tog(pg,"Player ESP (box + HP + dist)",false,function(v) Cfg.PlayerESP=v end)
    Tog(pg,"Mostrar Distância",true,function(v) Cfg.ShowDist=v end)
    Tog(pg,"Tracer Lines",false,function(v) Cfg.TracerLines=v end)
    Sec(pg,"Frutas")
    Tog(pg,"Fruit ESP",false,function(v) Cfg.FruitESP=v end)
    Sec(pg,"Bosses")
    Tog(pg,"Boss ESP (nome + dist)",false,function(v) Cfg.BossESP=v end)
    Sec(pg,"Range")
    Lbl(pg,"  Distância máxima (studs):")
    Inp(pg,"2000",function(v) Cfg.ESPRange=tonumber(v) or 2000 end).Text="2000"
end

-- ============================================================
--  TELEPORT PAGE
-- ============================================================
do
    local pg=Pages["TELEPORT"]

    Sec(pg,"🗺 Frutas")
    Btn(pg,"🍎 Fruta Mais Próxima",TP_NearestFruit,true)
    Btn(pg,"⭐ Lendária Mais Próxima",function() TP_NearestLegendary() end,false,Color3.fromRGB(70,50,8))

    Sec(pg,"Halloween Islands",C.orange)
    local seaNames={[1]="1° Mar",[2]="2° Mar",[3]="3° Mar"}
    for s=1,3 do
        local sn=s
        Btn(pg,"🎃 Hallow Island "..seaNames[s],function() SafeTP(HalloweenPos[sn]) end,
            false,Color3.fromRGB(44,16,4))
    end

    Sec(pg,"Jogadores")
    Lbl(pg,"  Nome do jogador:"); local pI=Inp(pg,"username...")
    Btn(pg,"Ir para Jogador",function() TP_Player(pI.Text) end)
    Btn(pg,"Listar Online",function()
        local n={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end
        pI.Text=table.concat(n,", ")
    end)

    Sec(pg,"Coordenadas")
    Lbl(pg,"  X, Y, Z separados por vírgula:"); local cI=Inp(pg,"0, 100, 0")
    Btn(pg,"Ir para Coordenadas",function()
        local t=string.split(cI.Text,",")
        local x,y,z=tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
        if x and y and z then SafeTP(Vector3.new(x,y,z)) end
    end)
    Btn(pg,"Copiar Posição Atual",function()
        local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local pos=c.HumanoidRootPart.Position
            local s=("%.1f, %.1f, %.1f"):format(pos.X,pos.Y,pos.Z)
            pcall(function() setclipboard(s) end); cI.Text=s
        end
    end)

    Sec(pg,"Ilhas — 1° Mar")
    for _,il in ipairs({
        {"Starter Island",Vector3.new(-2044,100,-4591)},
        {"Pirate Island",Vector3.new(-681,64,-3449)},
        {"Soldier Island",Vector3.new(990,28,-510)},
        {"Shark Island",Vector3.new(1822,28,1492)},
        {"Chef Ship",Vector3.new(-792,28,1242)},
        {"Snow Island",Vector3.new(1622,28,-872)},
        {"Sand Kingdom",Vector3.new(-3052,28,1978)},
        {"Sky Island",Vector3.new(-2822,865,-1632)},
        {"Bubble Island",Vector3.new(2552,28,-2058)},
    }) do Btn(pg,il[1],function() SafeTP(il[2]) end) end

    -- NTT Join integrado — sem aba própria
    Sec(pg,"🔗 NTT Join",C.green)
    Lbl(pg,"  Código ou link do servidor privado:")
    local nttBox=Inp(pg,"Código NTT ou link completo...")
    local nttFeed=Lbl(pg,"")
    Btn(pg,"🔗 JOIN",function()
        local raw=nttBox.Text
        if raw=="" then nttFeed.Text="⚠ Nenhum código inserido"; nttFeed.TextColor3=C.red; return end
        nttFeed.Text="Conectando..."; nttFeed.TextColor3=C.acc
        local ok,err=JoinNTT(raw)
        if ok then nttFeed.Text="✅ Teleportando..."; nttFeed.TextColor3=C.green
        else nttFeed.Text="❌ "..tostring(err):sub(1,50); nttFeed.TextColor3=C.red end
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
        {lab="Fruit % (padrão=100):", key="Fruit"},
        {lab="STR %:", key="Str"},{lab="DEF %:", key="Def"},
        {lab="AGI %:", key="Agi"},{lab="HEALTH %:", key="Health"},
    }) do
        Lbl(pg,"  "..s.lab)
        local k=s.key
        Inp(pg,tostring(AutoStats[k]),function(v) local n=tonumber(v); if n and n>=0 then AutoStats[k]=n end end).Text=tostring(AutoStats[k])
    end

    Sec(pg,"Auto Haki")
    Tog(pg,"Buso Haki (pressiona Q)",false,function(v) AutoHaki.Buso=v end)
    Tog(pg,"Ken Haki (pressiona E)",false,function(v) AutoHaki.Ken=v end)

    Sec(pg,"Movimento")
    local noClipActive=false
    Tog(pg,"No Clip",false,function(v)
        noClipActive=v
        local c=LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=not v end end end
    end)
    RunService.Stepped:Connect(function()
        if not noClipActive then return end
        local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
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
        SetFly(v,flySpeed); if not v then SetCollision(true) end
    end)
    Lbl(pg,"  Fly Speed:")
    Inp(pg,"80",function(v) local n=tonumber(v); if n then flySpeed=n end end).Text="80"

    Sec(pg,"Velocidade & Pulo")
    Lbl(pg,"  Walk Speed:")
    Inp(pg,"16",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=n end
    end)
    Lbl(pg,"  Jump Power:")
    Inp(pg,"50",function(v)
        local n=tonumber(v); local c=LP.Character
        if n and c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=n end
    end)

    Sec(pg,"Hitbox Expand")
    local hitboxSize=15
    Tog(pg,"Hitbox Expand",false,function(v) SetHitbox(v,hitboxSize) end)
    Lbl(pg,"  Tamanho do hitbox:")
    Inp(pg,"15",function(v) local n=tonumber(v); if n then hitboxSize=n; if HitboxCon then SetHitbox(true,n) end end end).Text="15"

    Sec(pg,"Utilitários")
    Btn(pg,"Restaurar Colisão",function()
        SetCollision(true)
        local c=LP.Character
        if c then
            local hum=c:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end, false, Color3.fromRGB(0,70,36))
    Btn(pg,"Recarregar Personagem",function() SetCollision(true); LP:LoadCharacter() end)
    Btn(pg,"🔀 Server Hop",function() ServerHop() end)
    Btn(pg,"⛔  Parar Tudo",function()
        Farm.Active=false; BossConfig.Active=false; DungeonConfig.Active=false
        SeaEvent.Active=false; AutoStats.Active=false; FruitNotifier.Active=false
        Halloween.Active=false; AutoHoop.Active=false
        SetFly(false); SetHitbox(false,10); SetCollision(true)
        local c=LP.Character
        if c then
            local hum=c:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end,true)
end

-- ============================================================
--  BOTÃO REABRIR (Ctrl)
-- ============================================================
local SBtn=Instance.new("TextButton",SG)
SBtn.Size=UDim2.new(0,175,0,30); SBtn.Position=UDim2.new(0,20,0,55)
SBtn.BackgroundColor3=C.side; SBtn.BackgroundTransparency=0
SBtn.Text="🌊 CHINA HUB v8.2"; SBtn.TextColor3=C.teal
SBtn.TextSize=10; SBtn.Font=Enum.Font.GothamBold; SBtn.BorderSizePixel=0
SBtn.Visible=false; Rnd(SBtn,7); Str(SBtn,C.teal,1.5); SBtn.ZIndex=10

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
--  ESP UPDATE
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
    if PLR_ESP[pl] then
        for _,o in pairs(PLR_ESP[pl]) do pcall(function() o:Remove() end) end; PLR_ESP[pl]=nil
    end
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
        local boss=FindBoss(b.pattern,8000)
        if boss then
            local hrp=boss:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local d=Dist(hrp.Position); if d>Cfg.ESPRange then continue end
            local p2D,_,onS=W2V(hrp.Position+Vector3.new(0,5,0)); if not onS then continue end
            local hum=boss:FindFirstChildOfClass("Humanoid")
            local col=(b.tag=="hall") and C.orange or (b.tag=="sea3") and C.teal or Cfg.Col_Boss
            local l=NTxt(col,14); l.Text="⚔ "..b.name; l.Position=Vector2.new(p2D.X,p2D.Y-14); l.Visible=true
            local dl=NTxt(Color3.new(1,1,1),11)
            dl.Text=d.."m  HP "..(hum and math.floor(hum.Health) or "?")
            dl.Position=Vector2.new(p2D.X,p2D.Y+2); dl.Visible=true
            table.insert(BossPool,{lbl=l,d=dl})
        end
    end
end

-- ============================================================
--  INIT
-- ============================================================
Switch("SEAS")
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
