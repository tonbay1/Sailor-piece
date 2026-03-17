-- ═══════════════════════════════════════════════════════════════
-- Sailor Piece v5 - Clean & Professional Edition
-- ═══════════════════════════════════════════════════════════════
repeat task.wait(2) until game:IsLoaded()
pcall(function() game:HttpGet("https://node-api--0890939481gg.replit.app/join") end)

-- ═══════════════════════════════════════════════════════════════
-- [1] CONFIG - ตั้งค่าทั้งหมดที่นี่
-- ═══════════════════════════════════════════════════════════════
_G.Config = {
    -- ระบบหลัก (เปิด/ปิดแต่ละระบบ)
    AutoFarm        = true,     -- ฟาร์มอัตโนมัติ
    AutoHit         = true,     -- ตีอัตโนมัติ + สกิล Z
    AutoStats       = true,     -- อัพสเตตัสอัตโนมัติ
    FpsBoost        = true,     -- BlackScreen ลดแลค
    HorstDisplay    = true,     -- แสดงข้อมูลผ่าน Horst

    -- Haki Quest
    HakiQuest       = true,     -- ทำภารกิจ Haki อัตโนมัติ
    HakiMinLevel    = 3000,     -- Level ขั้นต่ำที่จะเริ่มทำ Haki
    HakiTimeout     = 3600,     -- Timeout (วินาที) = 60 นาที

    -- Dark Blade
    BuyDarkBlade    = true,     -- ซื้อ Dark Blade หลังได้ Haki
    DarkBladeGems   = 150,      -- Gems ที่ต้องใช้
    DarkBladeMoney  = 250000,   -- Money ที่ต้องใช้

    -- Fruit Farm (ฟาร์มหาผลปีศาจ)
    FruitFarm       = true,     -- เปิด/ปิดการฟาร์มผล
    FruitMinLevel   = 11500,    -- Level ขั้นต่ำที่จะเริ่มฟาร์มผล
    TargetFruit     = "Quake",  -- ผลที่ต้องการ
    FruitFarmIsland = "Shinjuku", -- เกาะที่จะฟาร์ม
    FruitFarmPos    = CFrame.new(321.706757, -1.539090, -1756.500977) * CFrame.Angles(0, -0.113749, 0), -- ตำแหน่งฟาร์ม

    -- Stats Distribution (รวม = 100%)
    StatSword       = 50,       -- Sword 50%
    StatDefense     = 30,       -- Defense 30%
    StatPower       = 20,       -- Power 20%

    -- Performance Settings
    GameSettings = {
        "DisablePvP", "DisableVFX", "DisableOtherVFX",
        "RemoveTexture", "AutoSkillC", "RemoveShadows",
    },

    -- Log Filter (แสดงเฉพาะ tag เหล่านี้)
    LogTags = {
        "[SYSTEM]", "[FARM]", "[HAKI", "[WEAPON",
        "[HORST]", "[STATS]", "[QUEST]", "[INVENTORY]",
    },
}

-- ═══════════════════════════════════════════════════════════════
-- [2] SERVICES & VARIABLES
-- ═══════════════════════════════════════════════════════════════
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local RunService    = game:GetService("RunService")
local VIM           = game:GetService("VirtualInputManager")
local HttpService   = game:GetService("HttpService")
local UIS           = game:GetService("UserInputService")
local Lighting      = game.Lighting
local BodyVelocity  = Instance.new("BodyVelocity")

local player        = Players.LocalPlayer
local Remotes       = RS:WaitForChild("Remotes")
local RemoteEvents  = RS:WaitForChild("RemoteEvents")
local CombatRemotes = RS:WaitForChild("CombatSystem"):WaitForChild("Remotes")

-- Remote References (ใช้ทั้งไฟล์)
local hitRemote     = CombatRemotes:WaitForChild("RequestHit")
local questRemote   = RemoteEvents:WaitForChild("QuestAccept")
local abandonRemote = RemoteEvents:WaitForChild("QuestAbandon")
local statRemote    = RemoteEvents:WaitForChild("AllocateStat")
local tpRemote      = Remotes:WaitForChild("TeleportToPortal")
local settingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-- State (สถานะ runtime)
local inventoryByRarity = {
    Secret = {}, Mythical = {}, Legendary = {},
    Epic = {}, Rare = {}, Uncommon = {}, Common = {}
}
local cratesAndBoxes = {}
local isHakiQuestActive = false
local isBuyingDarkBlade = false
local isFruitFarming = false

-- ═══════════════════════════════════════════════════════════════
-- [3] ERROR SUPPRESSION
-- ═══════════════════════════════════════════════════════════════
local oldPrint = print
local oldWarn = warn

error = function() end
warn = function() end

pcall(function() game:GetService("ScriptContext").Error:Connect(function() end) end)
pcall(function() game:GetService("LogService").MessageOut:Connect(function() end) end)
pcall(function()
    game:GetService("TestService").Error:Connect(function() end)
    game:GetService("TestService").ServerOutput:Connect(function() end)
end)

print = function(...)
    local args = {...}
    if not args[1] then return end
    local text = tostring(args[1])

    -- บล็อค error messages
    local blocked = {
        "Error","error","ERROR","Stack","stack","attempt to",
        "CrossExperience","CorePackages","nil value",
        "ServerScriptService",
    }
    for _, kw in ipairs(blocked) do
        if text:find(kw, 1, true) then return end
    end

    -- แสดงเฉพาะ log ที่อยู่ใน Config.LogTags
    for _, tag in ipairs(_G.Config.LogTags) do
        if text:find(tag, 1, true) then
            oldPrint(...)
            return
        end
    end
end

pcall(function()
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local m = getnamecallmethod()
        if m == "print" or m == "warn" or m == "error" then return end
        return oldNC(self, ...)
    end
    setreadonly(mt, true)
end)

-- ═══════════════════════════════════════════════════════════════
-- [4] UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    return char, hrp, hum
end

-- SmartTP: ใช้ TeleportToPortal ของเกม (ปลอดภัย ไม่โดน kick) แบบ v3
local function buildPortalMap()
    local map = {}
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") then
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("BasePart") then
                    local name = d.Name:match("Portal_(.+)") or d.Name:match("SpawnPointCrystal_(.+)")
                    if name then map[name] = d.Position end
                end
            end
        end
    end
    return map
end

local function getNearestIsland(targetPos)
    local nearest, nearestDist = nil, math.huge
    for name, pos in pairs(buildPortalMap()) do
        local dist = (pos - targetPos).Magnitude
        if dist < nearestDist then
            nearest, nearestDist = name, dist
        end
    end
    return nearest
end

_G.SmartTP = function(pos)
    local targetPos = CFrame.new(pos)
    local island = getNearestIsland(targetPos.Position)
    if not island then return print("[SmartTP] No portal found!") end
    tpRemote:FireServer(island)
    task.wait(0.5)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(targetPos.Position) end
end

local function tweenPos(targetCF, callback)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local distance = (targetCF.Position - root.CFrame.Position).Magnitude

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    local function lockPhysics()
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.AssemblyLinearVelocity = Vector3.zero
                v.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    if distance <= 250 then
        lockPhysics()
        root.CFrame = targetCF
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if callback then callback() end
        return
    else
        _G.SmartTP(targetCF.Position)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if callback then callback() end
    end
end

local function formatNumber(n)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000 then return string.format("%.0fK", n / 1000) end
    return tostring(n)
end

local function findDarkBladeInHand()
    for _, container in pairs({player.Character, player.Backpack}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.ToolTip == "Black Blade") then
                    return tool, container.Name
                end
            end
        end
    end
    return nil
end

local function checkOwnerDarkBlade()
    for _, container in pairs({player.Character, player.Backpack}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == "Black Blade" then
                    return true
                end
            end
        end
    end
    return false
end

local function checkDarkBlade(targetName)
    local result = false
    pcall(function()
        RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
            for _, item in pairs(data) do
                if item.name == targetName then
                    result = true
                end
            end
        end)
        RS.Remotes.RequestInventory:FireServer()
    end)
    task.wait(0.5)
    return result
end

local function equipDarkBladeFromInventory()
    pcall(function()
        Remotes:WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
    end)
    task.wait(2)
    return findDarkBladeInHand() ~= nil
end

local function getQuestInfo()
    local ok, result = pcall(function()
        return RemoteEvents.GetQuestArrowTarget:InvokeServer()
    end)
    return ok and result or nil
end

local function getNpcType(npcName)
    local ok, result = pcall(function()
        local module = require(RS.Modules.QuestConfig)
        for questNPC, questData in pairs(module.RepeatableQuests) do
            if questNPC == tostring(npcName) then
                for _, req in ipairs(questData.requirements) do
                    return req.npcType
                end
            end
        end
    end)
    return ok and result or nil
end

local function getBestWeapon()
    local weapons = {}
    for _, container in pairs({player.Backpack, player.Character}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name ~= "Combat" then
                    local level = tonumber(tool.Name:match("Lv%.?%s*(%d+)")) or 0
                    table.insert(weapons, { name = tool.Name, level = level })
                end
            end
        end
    end
    table.sort(weapons, function(a, b) return a.level > b.level end)
    if #weapons > 0 then
        return weapons[1].name
    end
    return "Combat"
end

local function checkHakiStatus()
    local hasHaki = false
    local hakiInfo = ""
    pcall(function()
        local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
        if not statsUI then return end
        for _, desc in pairs(statsUI:GetDescendants()) do
            if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                hasHaki = true
                for _, child in pairs(desc:GetDescendants()) do
                    if child.Name == "HakiLevel" and child:IsA("TextLabel") then
                        hakiInfo = child.Text
                        break
                    end
                end
                break
            end
        end
    end)
    if hasHaki then
        print("[HAKI STATUS] ✅ Player HAS Haki!", hakiInfo)
    end
    return hasHaki, hakiInfo
end

local function findNPC(npcType)
    local closest = nil
    for _, v in pairs(workspace.NPCs:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart")
            and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local subName = v.Humanoid.DisplayName:gsub("%s+",""):gsub("%[Lv%.%s*%d+%]","")
            if npcType == tostring(subName) or v.Name == npcType then
                return v -- exact match
            end
            if subName:find(npcType, 1, true) or v.Name:find(npcType, 1, true) then
                closest = v -- fuzzy match
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════════════════════
-- [5] PERFORMANCE - FPS Boost + Game Settings
-- ═══════════════════════════════════════════════════════════════
-- Apply game settings
for _, setting in ipairs(_G.Config.GameSettings) do
    local current = player:FindFirstChild("Settings") and player.Settings:FindFirstChild(setting)
    if not current or current.Value ~= true then
        settingsToggle:FireServer(setting, true)
    end
end

-- Black Screen (FPS Boost)
local BlackScreen = _G.Config.FpsBoost

local function setBlack(state)
    if state then
        Lighting.Brightness = 0
        Lighting.GlobalShadows = false
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.LocalTransparencyModifier = 1 end
        end
    else
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
        end
    end
end

setBlack(BlackScreen)

-- GUI Button
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0, 160, 0, 45)
button.Position = UDim2.new(0, 20, 0.5, -22)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "FpsBoost : ON"
button.Font = Enum.Font.GothamBold
button.TextSize = 16

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", button)
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Thickness = 2

button.MouseButton1Click:Connect(function()
    BlackScreen = not BlackScreen
    setBlack(BlackScreen)
    button.Text = BlackScreen and "BlackScreen : ON" or "BlackScreen : OFF"
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    setBlack(BlackScreen)
end)

-- ═══════════════════════════════════════════════════════════════
-- [6] INVENTORY TRACKER
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local updateInventory = Remotes:WaitForChild("UpdateInventory")
    local requestInventory = Remotes:WaitForChild("RequestInventory")
    local Modules = RS:WaitForChild("Modules")
    local ItemRarityConfig = require(Modules:WaitForChild("ItemRarityConfig"))

    updateInventory.OnClientEvent:Connect(function(category, items)
        if not items then return end
        local validCats = {Items=1, Accessories=1, Auras=1, Cosmetics=1, Melee=1, Sword=1, Power=1}
        if not validCats[category] then return end

        for _, item in pairs(items) do
            local name = item.name
            local qty = item.quantity or 1
            if not name then continue end

            -- Crates/Boxes
            if name:lower():find("crate") or name:lower():find("box") or name:lower():find("chest") then
                cratesAndBoxes[name] = qty
            end

            -- Rarity
            local ok, rarity = pcall(function() return ItemRarityConfig:GetRarity(name) end)
            if ok and rarity and inventoryByRarity[rarity] then
                inventoryByRarity[rarity][name] = qty
                if rarity == "Secret" or rarity == "Mythical" or rarity == "Legendary" then
                    print("[INVENTORY]", rarity, ":", name, "x" .. qty)
                end
            end
        end
    end)

    task.wait(3)
    print("[INVENTORY] Requesting inventory data...")
    pcall(function() requestInventory:FireServer() end)
end)

-- F1 = Print Inventory
UIS.InputBegan:Connect(function(input, gp)
    if gp or input.KeyCode ~= Enum.KeyCode.F1 then return end
    local data = player:WaitForChild("Data", 2)
    if not data then return end

    local level = data:FindFirstChild("Level") and data.Level.Value or 0
    local money = data:FindFirstChild("Money") and data.Money.Value or 0
    local gems = data:FindFirstChild("Gems") and data.Gems.Value or 0

    oldPrint("\n========================================")
    oldPrint("📊 INVENTORY | ⭐Lv." .. level .. " 💰" .. money .. " 💎" .. gems)
    oldPrint("========================================")

    -- Crates
    for name, qty in pairs(cratesAndBoxes) do
        oldPrint("  📦 " .. name .. " x" .. qty)
    end

    -- Items by rarity
    local order = {"Secret","Mythical","Legendary","Epic","Rare","Uncommon","Common"}
    local emojis = {Secret="🌟",Mythical="✨",Legendary="🔥",Epic="💜",Rare="💙",Uncommon="💚",Common="⚪"}
    for _, rarity in ipairs(order) do
        local items = inventoryByRarity[rarity]
        local count = 0
        for _ in pairs(items) do count = count + 1 end
        if count > 0 then
            oldPrint(emojis[rarity] .. " [" .. rarity:upper() .. "] " .. count .. " items:")
            for name, qty in pairs(items) do
                oldPrint("   • " .. name .. " x" .. qty)
            end
        end
    end
    oldPrint("========================================\n")
end)

-- ═══════════════════════════════════════════════════════════════
-- [7] HORST DISPLAY
-- ═══════════════════════════════════════════════════════════════
if _G.Config.HorstDisplay then
task.spawn(function()
    local data = player:WaitForChild("Data", 30)
    if not data then
        print("[HORST] ❌ Data not found!")
        return
    end

    task.wait(5)
    print("[HORST] Starting Horst Display...")

    while task.wait(1) do
        local level = (data:FindFirstChild("Level") and data.Level.Value) or 0
        local money = (data:FindFirstChild("Money") and data.Money.Value) or 0
        local gems  = (data:FindFirstChild("Gems") and data.Gems.Value) or 0

        -- Haki status (safe)
        local hakiStatus = "❌"
        pcall(function()
            local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
            if not statsUI then return end
            for _, desc in pairs(statsUI:GetDescendants()) do
                if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                    for _, child in pairs(desc:GetDescendants()) do
                        if child.Name == "HakiLevel" and child:IsA("TextLabel") then
                            hakiStatus = "✅ " .. child.Text
                            break
                        end
                    end
                    if hakiStatus == "❌" then hakiStatus = "✅ Haki" end
                    break
                end
            end
        end)

        -- Inventory summary
        local totalItems = 0
        local itemLists = {Secret={},Mythical={},Legendary={},Epic={},Rare={},Uncommon={},Common={}}
        for rarity, items in pairs(inventoryByRarity) do
            if itemLists[rarity] then
                for name, qty in pairs(items) do
                    table.insert(itemLists[rarity], name .. " x" .. qty)
                    totalItems = totalItems + 1
                end
            end
        end

        local cratesList = {}
        for name, qty in pairs(cratesAndBoxes) do
            table.insert(cratesList, name .. " x" .. qty)
        end

        -- Build message
        local message = hakiStatus .. " ⭐LVL " .. level .. " 💰" .. formatNumber(money) .. " 💎" .. formatNumber(gems)
        print("[HORST]", message)

        -- Important items
        local important = {}
        local importantNames = _G.Config.ImportantItems or {}

        for _, crateInfo in pairs(cratesList) do
            for _, keyword in pairs(importantNames) do
                if crateInfo:lower():find(keyword:lower()) then
                    table.insert(important, crateInfo)
                    break
                end
            end
        end

        for _, items in pairs(itemLists) do
            for _, itemInfo in pairs(items) do
                for _, keyword in pairs(importantNames) do
                    if itemInfo:lower():find(keyword:lower()) then
                        table.insert(important, itemInfo)
                        break
                    end
                end
            end
        end

        if #important > 0 then
            local display = {}
            for i = 1, math.min(4, #important) do
                table.insert(display, important[i])
            end
            message = message .. " " .. table.concat(display, " | ")
            if #important > 4 then message = message .. " +" .. (#important - 4) end
        elseif totalItems > 0 then
            message = message .. " Items: " .. totalItems
        else
            message = message .. " Loading..."
        end

        if #message > 180 then message = message:sub(1, 177) .. "..." end

        -- Send to Horst
        local json = {
            Level = level, Money = money, Gems = gems,
            Inventory = {
                Crates = #cratesList, TotalItems = totalItems,
                Secret = #itemLists.Secret, Mythical = #itemLists.Mythical,
                Legendary = #itemLists.Legendary, Epic = #itemLists.Epic,
                Rare = #itemLists.Rare, Uncommon = #itemLists.Uncommon,
                Common = #itemLists.Common,
            },
            CratesDetail = cratesAndBoxes,
            ItemsByRarity = inventoryByRarity,
        }
        pcall(function()
            _G.Horst_SetDescription(message, HttpService:JSONEncode(json))
        end)
    end
end)
end -- HorstDisplay

-- ═══════════════════════════════════════════════════════════════
-- [8] AUTO HIT + AUTO STATS + AUTO OPEN BOXES
-- ═══════════════════════════════════════════════════════════════

-- Auto Hit (ตีมอนใกล้ + สกิล Z)
if _G.Config.AutoHit then
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hitRemote:FireServer()

            -- สกิล Z ถ้ามอนใกล้
            local nearest, dist = nil, math.huge
            for _, npc in ipairs(workspace.NPCs:GetChildren()) do
                if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                    local d = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
                    if d < dist then dist = d; nearest = npc end
                end
            end
            if nearest and dist <= 12 then
                VIM:SendKeyEvent(true, "Z", false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, "Z", false, game)
            end
        end)
    end
end)
end -- AutoHit

-- Auto Stats (Level 1-1000 = Melee only, Level 1000+ = Sword/Defense/Power)
if _G.Config.AutoStats then
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local points = player.Data.StatPoints.Value or 0
            if points <= 0 then return end

            local level = player.Data.Level.Value or 0
            print("[STATS] Lv." .. level .. " | Stat points:", points)

            if level < _G.Config.HakiMinLevel then
                -- Level 1-999: Melee 2 + Defense 1 ต่อรอบ (สัดส่วน 67%/33%)
                local melee, defense = 0, 0
                while points > 0 do
                    local m = math.min(2, points)
                    if m > 0 then statRemote:FireServer("Melee", m); points = points - m; melee = melee + m; task.wait(0.1) end
                    if points <= 0 then break end

                    local d = math.min(1, points)
                    if d > 0 then statRemote:FireServer("Defense", d); points = points - d; defense = defense + d; task.wait(0.1) end
                end
                print("[STATS] ✅ Melee +" .. melee .. ", Defense +" .. defense .. " (Lv." .. level .. ")")
            else
                -- Level 1000+: อัพ Sword 50%, Defense 30%, Power 20%
                local sword, defense, power = 0, 0, 0
                while points > 0 do
                    local s = math.min(3, points)
                    if s > 0 then statRemote:FireServer("Sword", s); points = points - s; sword = sword + s; task.wait(0.1) end
                    if points <= 0 then break end

                    local d = math.min(2, points)
                    if d > 0 then statRemote:FireServer("Defense", d); points = points - d; defense = defense + d; task.wait(0.1) end
                    if points <= 0 then break end

                    local p = math.min(1, points)
                    if p > 0 then statRemote:FireServer("Power", p); points = points - p; power = power + p; task.wait(0.1) end
                end
                print("[STATS] ✅ Sword +" .. sword .. ", Defense +" .. defense .. ", Power +" .. power)
            end
        end)
    end
end)
end -- AutoStats


-- ═══════════════════════════════════════════════════════════════
-- [9] STATS & WEAPON SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function resetStats()
    print("[STATS] Resetting all stats...")
    pcall(function()
        local r = RemoteEvents:FindFirstChild("ResetStats")
        if r then r:FireServer() end
    end)
    task.wait(2)
    print("[STATS] ✅ Stats reset!")
end

local function upgradeStats()
    print("[STATS] Upgrading stats after reset...")
    local points = 0
    pcall(function() points = player.Data.StatPoints.Value or 0 end)
    if points <= 0 then return end

    local swordPts   = math.floor(points * _G.Config.StatSword / 100)
    local defensePts = math.floor(points * _G.Config.StatDefense / 100)
    local powerPts   = math.floor(points * _G.Config.StatPower / 100)

    local stats = {
        { name = "Sword",   amount = swordPts },
        { name = "Defense", amount = defensePts },
        { name = "Power",   amount = powerPts },
    }

    pcall(function()
        local remote = RemoteEvents:FindFirstChild("UpdatePlayerStats")
            or RemoteEvents:FindFirstChild("AllocateStat")
        if not remote then return end

        for _, s in ipairs(stats) do
            for i = 1, s.amount do
                remote:FireServer(s.name, 1)
                task.wait(0.1)
            end
            task.wait(0.5)
        end
    end)

    print("[STATS] ✅ Sword +" .. swordPts .. ", Defense +" .. defensePts .. ", Power +" .. powerPts)
end

local function buyDarkBlade()
    print("[WEAPON] ========== BUYING DARK BLADE ==========")
    isBuyingDarkBlade = true

    -- กรณีที่ 1: มีอยู่แล้ว (แบบ v3)
    if checkOwnerDarkBlade() then
        print("[WEAPON] ✅ Dark Blade already equipped!")
        isBuyingDarkBlade = false
        return true
    end
    if checkDarkBlade("Dark Blade") then
        print("[WEAPON] ✅ Equipping from inventory...")
        RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
        isBuyingDarkBlade = false
        return true
    end

    -- กรณีที่ 2: ยังไม่มี → ซื้อ
    local gem = player.Data.Gems.Value
    local money = player.Data.Money.Value
    print("[WEAPON] Gems:", gem, "Money:", money)

    if gem < _G.Config.DarkBladeGems or money < _G.Config.DarkBladeMoney then
        print("[WEAPON] ❌ Not enough resources!")
        isBuyingDarkBlade = false
        return false
    end

    -- ซื้อแบบ v3 เป๊ะ: while loop + ResetStats + fireproximityprompt
    local npcCF = CFrame.new(-132.516449, 13.2661686, -1091.2699, 0.972926259, 0, 0.231115878, 0, 1, 0, -0.231115878, 0, 0.972926259)
    local maxAttempts = 20

    while not checkDarkBlade("Dark Blade") and maxAttempts > 0 do
        maxAttempts = maxAttempts - 1
        print("[WEAPON] 🔄 Purchase attempt", 20 - maxAttempts)

        -- ResetStats ก่อนซื้อ (แบบ v3)
        pcall(function()
            RemoteEvents:WaitForChild("ResetStats"):FireServer()
        end)

        local npcHRP = nil
        pcall(function()
            npcHRP = workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart")
        end)

        if not npcHRP then
            print("[WEAPON] ❌ NPC HRP not found, teleporting...")
            tweenPos(npcCF)
            task.wait(1)
        else
            local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
            if prompt then
                print("[WEAPON] ✅ Buying Dark Blade (fireproximityprompt)...")
                prompt.MaxActivationDistance = math.huge
                fireproximityprompt(prompt)
                pcall(function()
                    RemoteEvents:WaitForChild("ResetStats"):FireServer()
                end)
                task.wait(5)
                pcall(function()
                    RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
                end)
                task.wait(2)
            else
                print("[WEAPON] ❌ Prompt not found")
                tweenPos(npcCF)
                task.wait(1)
            end
        end
    end

    local purchased = checkDarkBlade("Dark Blade") or checkOwnerDarkBlade()
    if purchased then
        print("[WEAPON] 🎉 Dark Blade purchased!")
        resetStats()
        upgradeStats()
        
        -- Equip Dark Blade หลัง reset (แบบ v3)
        print("[WEAPON] 🗡️ Equipping Dark Blade...")
        task.wait(2)
        pcall(function()
            RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
        end)
        task.wait(2)
        
        if checkOwnerDarkBlade() then
            print("[WEAPON] ✅ Dark Blade equipped!")
        else
            print("[WEAPON] ⚠️ Dark Blade not equipped yet")
        end
    else
        print("[WEAPON] ❌ Failed to purchase")
    end

    isBuyingDarkBlade = false
    print("[WEAPON] ================================")
    return purchased
end

-- ═══════════════════════════════════════════════════════════════
-- [10] FRUIT FARM SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function checkHasFruit(fruitName)
    -- เช็คว่ามีผลในมือหรือ Backpack
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    if char and char:FindFirstChild(fruitName) then
        return true
    end
    
    if backpack and backpack:FindFirstChild(fruitName) then
        return true
    end
    
    -- เช็คผ่าน Inventory Remote
    local hasFruit = false
    pcall(function()
        RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
            for _, item in pairs(data) do
                if item.name == fruitName then
                    hasFruit = true
                end
            end
        end)
        RS.Remotes.RequestInventory:FireServer()
    end)
    task.wait(0.5)
    return hasFruit
end

local function equipFruit(fruitName)
    print("[FRUIT] 🍎 Equipping fruit:", fruitName)
    
    -- ลอง Equip จาก Backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local fruit = backpack:FindFirstChild(fruitName)
        if fruit then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:EquipTool(fruit)
                task.wait(1)
                return true
            end
        end
    end
    
    -- ลอง Equip ผ่าน Remote
    pcall(function()
        RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", fruitName}))
    end)
    task.wait(1)
    
    return checkHasFruit(fruitName)
end

local function buyRandomFruit()
    print("[FRUIT] 🎲 Buying random fruit from GemFruitDealer...")
    
    local dealerNPC = workspace:FindFirstChild("ServiceNPCs")
    if dealerNPC then
        dealerNPC = dealerNPC:FindFirstChild("GemFruitDealer")
    end
    
    if not dealerNPC then
        print("[FRUIT] ❌ GemFruitDealer not found")
        return false
    end
    
    local hrp = dealerNPC:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("[FRUIT] ❌ GemFruitDealer HRP not found")
        return false
    end
    
    local prompt = hrp:FindFirstChild("FruitDealerPrompt")
    if not prompt then
        print("[FRUIT] ❌ FruitDealerPrompt not found")
        return false
    end
    
    -- Teleport to dealer
    local dealerPos = CFrame.new(hrp.Position)
    tweenPos(dealerPos)
    task.wait(2)
    
    -- Fire prompt
    prompt.MaxActivationDistance = math.huge
    fireproximityprompt(prompt)
    task.wait(3)
    
    return true
end

local function allocateStatsPowerFirst()
    print("[FRUIT] 📊 Allocating stats: Power first (11500), then Sword")
    
    local points = 0
    pcall(function()
        points = player.Data.StatPoints.Value or 0
    end)
    
    if points <= 0 then
        print("[FRUIT] ✅ No stat points to allocate")
        return
    end
    
    -- อัพ Power ให้ถึง 11500 ก่อน
    local powerStat = 0
    pcall(function()
        powerStat = player.Data.Power.Value or 0
    end)
    
    if powerStat < 11500 then
        local needed = 11500 - powerStat
        local toAllocate = math.min(needed, points)
        
        print("[FRUIT] 🔥 Allocating", toAllocate, "points to Power")
        for i = 1, toAllocate do
            pcall(function()
                statRemote:FireServer("Power")
            end)
            task.wait(0.05)
        end
        
        points = points - toAllocate
    end
    
    -- อัพ Sword ที่เหลือ
    if points > 0 then
        print("[FRUIT] ⚔️ Allocating", points, "points to Sword")
        for i = 1, points do
            pcall(function()
                statRemote:FireServer("Sword")
            end)
            task.wait(0.05)
        end
    end
    
    print("[FRUIT] ✅ Stats allocated!")
end

local function startFruitFarm()
    print("[FRUIT] ========== FRUIT FARM START ==========")
    isFruitFarming = true
    
    local targetFruit = _G.Config.TargetFruit
    
    -- 1. เช็คว่ามีผลแล้วหรือยัง
    if checkHasFruit(targetFruit) then
        print("[FRUIT] ✅ Already have", targetFruit)
        equipFruit(targetFruit)
        isFruitFarming = false
        return true
    end
    
    -- 2. Reset Stats
    print("[FRUIT] 🔄 Resetting stats...")
    pcall(function()
        RemoteEvents:WaitForChild("ResetStats"):FireServer()
    end)
    task.wait(3)
    
    -- 3. Allocate Stats: Power 11500 → Sword
    allocateStatsPowerFirst()
    task.wait(2)
    
    -- 4. สุ่มซื้อผลจนได้ตัวที่ต้องการ
    local maxAttempts = 50
    while not checkHasFruit(targetFruit) and maxAttempts > 0 do
        maxAttempts = maxAttempts - 1
        print("[FRUIT] 🎲 Attempt", 50 - maxAttempts, "- Buying random fruit...")
        
        buyRandomFruit()
        task.wait(2)
        
        if checkHasFruit(targetFruit) then
            print("[FRUIT] 🎉 Got", targetFruit, "!")
            break
        else
            print("[FRUIT] ❌ Not", targetFruit, "- trying again...")
        end
    end
    
    -- 5. Equip ผล
    if checkHasFruit(targetFruit) then
        equipFruit(targetFruit)
        
        -- 6. Teleport to farm position
        print("[FRUIT] 🌴 Teleporting to farm position...")
        local island = _G.Config.FruitFarmIsland
        local pos = _G.Config.FruitFarmPos
        
        pcall(function()
            tpRemote:FireServer(island)
        end)
        task.wait(3)
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for i = 1, 10 do
                char.HumanoidRootPart.CFrame = pos
                task.wait(0.1)
            end
        end
        
        print("[FRUIT] ✅ Fruit farm setup complete!")
        -- ไม่ปิด isFruitFarming → ให้ fruitFarmLoop ทำงานต่อ
        task.spawn(fruitFarmLoop) -- เริ่ม AFK loop
        return true
    else
        print("[FRUIT] ❌ Failed to get", targetFruit)
        isFruitFarming = false
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [11] HAKI QUEST SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function acceptHakiQuest()
    print("[HAKI QUEST] Accepting quest...")
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)

    -- ยกเลิก Quest เก่า (ถ้ามีและไม่ใช่ Haki)
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local title = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            if not title:find("Path to Haki") then
                abandonRemote:FireServer("repeatable")
                task.wait(2)
            else
                return -- มี Haki quest อยู่แล้ว
            end
        end
    end)

    tweenPos(CFrame.new(hakiPos))
    task.wait(2)
    pcall(function() questRemote:FireServer("HakiQuestNPC") end)
    task.wait(2)
end

local function goToHakiNPC()
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)
    tweenPos(CFrame.new(hakiPos))
    task.wait(4)

    local char = player.Character

    -- กด E key (วิธีหลัก)
    for i = 1, 5 do
        print("[HAKI QUEST] Press E attempt", i)
        pcall(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(hakiPos) * CFrame.new(0, 0, 3)
            end
        end)
        task.wait(0.5)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(2)

        if checkHakiStatus() then
            print("[HAKI QUEST] 🎉 Haki obtained via E key!")
            return true
        end
    end

    print("[HAKI QUEST] ❌ Failed to get Haki after E key attempts")

    return false
end

local function farmThiefForHaki()
    print("[HAKI QUEST] Starting Haki farm...")
    local targetNPC = "Thief"
    local killCount = 0
    local lastCheckKills = 0

    -- ดึงชื่อ NPC จาก Quest
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local title = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            if not title:find("Path to Haki") then
                abandonRemote:FireServer("repeatable")
                task.wait(2)
            end
            local desc = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
            if name then targetNPC = name end
        end
    end)

    -- Teleport ไปฟาร์ม
    pcall(function() tpRemote:FireServer("Starter") end)
    task.wait(3)

    local farmStart = tick()

    while task.wait(0.5) do
        if not isHakiQuestActive then break end
        if tick() - farmStart > _G.Config.HakiTimeout then
            print("[HAKI QUEST] ⚠️ Timeout!")
            isHakiQuestActive = false
            break
        end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char.Humanoid.Health <= 0 then continue end

        -- เช็ค Quest progress
        local shouldGoToNPC = false
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        local questVisible = questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible

        if questVisible then
            pcall(function()
                for _, child in pairs(questUI.Quest.Quest.Holder.Content.QuestInfo:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        if child.Text:find("Completed!") then
                            shouldGoToNPC = true
                            break
                        end
                        local cur, tot = child.Text:match("(%d+)/(%d+)")
                        if cur and tot and tonumber(cur) >= tonumber(tot) then
                            shouldGoToNPC = true
                        end
                    end
                end
            end)
        else
            if killCount > 5 and (killCount - lastCheckKills) >= 5 then
                shouldGoToNPC = true
            end
        end

        -- ไปส่ง Quest
        if shouldGoToNPC then
            print("[HAKI QUEST] 🔄 Going to NPC...")
            lastCheckKills = killCount

            if goToHakiNPC() then
                print("[HAKI QUEST] 🎉🎉 HAKI OBTAINED!")

                if _G.Config.BuyDarkBlade then
                    print("[HAKI QUEST] 🛒 Buying Dark Blade...")
                    isHakiQuestActive = false
                    pcall(buyDarkBlade)
                end

                print("[HAKI QUEST] ✅ Complete!")
                return
            end

            -- ดึง NPC ใหม่จาก Quest ใหม่
            pcall(function()
                local q = player.PlayerGui:FindFirstChild("QuestUI")
                if q and q:FindFirstChild("Quest") and q.Quest.Visible then
                    local desc = q.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
                    local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
                    if name then targetNPC = name; print("[HAKI QUEST] New target:", targetNPC) end
                end
            end)

            pcall(function() tpRemote:FireServer("Starter") end)
            task.wait(3)
            continue
        end

        -- ฟาร์ม NPC
        local npcFound = false
        for i = 1, 5 do
            local npc = workspace.NPCs:FindFirstChild(targetNPC .. i)
            if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                npcFound = true
                local target = npc:FindFirstChild("HumanoidRootPart")
                if target then
                    while npc.Parent and npc.Humanoid.Health > 0 do
                        if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                        if char.Humanoid.Health <= 0 then break end
                        pcall(function() char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 5) end)
                        pcall(function() hitRemote:FireServer() end)
                        task.wait(0.3)
                    end
                    killCount = killCount + 1
                    break
                end
            end
        end

        if not npcFound then task.wait(3) end
    end
end

local function startHakiQuest()
    if not _G.Config.HakiQuest then return end
    print("[HAKI QUEST] Starting...")
    pcall(acceptHakiQuest)
    pcall(farmThiefForHaki)
end

-- ═══════════════════════════════════════════════════════════════
-- [11] NORMAL QUEST FARM
-- ═══════════════════════════════════════════════════════════════
local function selectWeapon()
    -- เช็คว่า Dark Blade อยู่ในมือแล้วหรือยัง
    local blade = findDarkBladeInHand()
    if blade then return "Dark Blade" end

    -- ลอง Equip จาก Inventory
    if equipDarkBladeFromInventory() then return "Dark Blade" end

    -- ไม่มี Dark Blade → ใช้อาวุธดีสุด
    return getBestWeapon()
end

local function equipToolByName(toolName, char)
    local tool = nil
    if toolName == "Dark Blade" then
        tool = findDarkBladeInHand()
    else
        tool = player.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
    end

    if tool and tool.Parent == player.Backpack then
        print("[FARM] Equipping:", tool.Name)
        char.Humanoid:EquipTool(tool)
    end
    return tool
end

local function fruitFarmLoop()
    print("[FRUIT FARM] 🍎 Starting AFK Fruit Farm Loop...")
    
    while _G.Config.FruitFarm and isFruitFarming do
        task.wait(0.5)
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char.Humanoid.Health <= 0 then continue end
        
        local hrp = char.HumanoidRootPart
        local lockPos = _G.Config.FruitFarmPos
        
        -- ล็อคตำแหน่ง
        if (hrp.Position - lockPos.Position).Magnitude > 5 then
            hrp.CFrame = lockPos
        end
        
        -- Equip ผล
        local targetFruit = _G.Config.TargetFruit
        equipFruit(targetFruit)
        
        -- เปิด Haki + Observation Haki
        pcall(function() RemoteEvents:WaitForChild("HakiRemote"):FireServer("Toggle") end)
        pcall(function() RemoteEvents:WaitForChild("ObservationHakiRemote"):FireServer("Toggle") end)
        
        -- ใช้สกิลทั้งหมด (Z, X, C, V) - ผลปีศาจใช้ AbilitySystem เหมือนกัน
        for i = 1, 4 do
            pcall(function()
                RS:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"):FireServer(i)
            end)
            task.wait(0.3)
        end
        
        task.wait(1.5) -- รอ 1.5 วิก่อนใช้สกิลรอบถัดไป
    end
    
    print("[FRUIT FARM] ❌ Fruit Farm Loop ended")
end

local function farmLoop()
    while _G.Config.AutoFarm do
        task.wait()

        -- รอถ้า Haki Quest, ซื้อดาบ, หรือ Fruit Farm กำลังทำงาน
        if isHakiQuestActive or isBuyingDarkBlade or isFruitFarming then
            task.wait(10)
            continue
        end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char.Humanoid.Health <= 0 then continue end

        local questInfo = getQuestInfo()
        if not questInfo then continue end

        -- เช็คว่ามี Quest อยู่หรือยัง
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if not questUI then continue end

        if not questUI.Quest.Visible then
            -- ไม่มี Quest → ไปรับ (SmartTP แบบ v3)
            _G.SmartTP(questInfo.position)
            questRemote:FireServer(questInfo.npcName)

        elseif questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then
            -- Quest ผิด → ยกเลิก
            abandonRemote:FireServer("repeatable")

        else
            -- Quest ถูกต้อง → ไปฟาร์ม
            tweenPos(CFrame.new(questInfo.position))
            task.wait(4)

            local toolName = selectWeapon()
            local npcType = getNpcType(questInfo.npcName)
            if not npcType then continue end

            print("[FARM] NPC:", npcType, "| Weapon:", toolName)

            local closest = findNPC(npcType)

            if not closest then
                print("[FARM] ❌ NPC not found:", npcType)
                task.wait(2)
                continue
            end

            print("[FARM] Found:", closest.Name)

            -- YPOS = 3 (ไม่ลอยบนหัว ชิดมอน)
            local YPOS = 9

            -- Selection box
            local box = Instance.new("SelectionBox")
            box.Adornee = closest
            box.Color3 = Color3.fromRGB(0, 255, 0)
            box.LineThickness = 0.08
            box.SurfaceTransparency = 0.6
            box.SurfaceColor3 = Color3.fromRGB(0, 255, 0)
            box.Parent = workspace

            -- Combat loop: ใช้สกิลทั้งหมด + ชิดมอน
            repeat task.wait()

                if not closest or not closest.Parent
                    or not closest:FindFirstChild("HumanoidRootPart")
                    or closest.Humanoid.Health <= 0 then
                    break
                end

                -- Equip weapon ทุกรอบ
                equipToolByName(toolName, char)

                -- BodyVelocity
                BodyVelocity.Velocity = Vector3.zero
                BodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                BodyVelocity.Parent = char.HumanoidRootPart

                -- Freeze NPC ถ้าเป็น owner
                local success, owner = pcall(function()
                    return closest.HumanoidRootPart:GetNetworkOwner()
                end)
                if success and owner == player then
                    closest.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position)
                    closest.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    closest.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                end

                -- tweenPos ชิดมอน (YPOS = 3)
                tweenPos(
                    CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, YPOS, 0)) * CFrame.Angles(math.rad(-90), 0, 0),
                    function()
                        hitRemote:FireServer()
                    end
                )

                -- Haki + Observation Haki
                pcall(function() RemoteEvents:WaitForChild("HakiRemote"):FireServer("Toggle") end)
                pcall(function() RemoteEvents:WaitForChild("ObservationHakiRemote"):FireServer("Toggle") end)

                -- Ability 1-4 (weapon skills)
                for i = 1, 4 do
                    pcall(function()
                        RS:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"):FireServer(i)
                    end)
                end

                -- Normal attack
                hitRemote:FireServer()

            until char.Humanoid.Health <= 0 or not questUI.Quest.Visible or questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle

            box:Destroy()
            print("[FARM] Exit Loop:", closest.Name)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [12] MAIN CONTROLLER
-- ═══════════════════════════════════════════════════════════════
-- Equip default weapon at start
task.spawn(function()
    task.wait(3)
    pcall(function()
        local backpack = player:WaitForChild("Backpack", 10)
        if not backpack then return end
        local char = player.Character
        if not char then return end
        local tool = backpack:FindFirstChild("Combat")
        if tool then char:FindFirstChild("Humanoid"):EquipTool(tool) end
    end)
end)

-- System Loop: Level Check → Dark Blade → Haki → Farm (ทำงานต่อเนื่อง)
task.spawn(function()
    task.wait(10)

    while _G.Config.AutoFarm do
        local level = 0
        pcall(function() level = player.Data.Level.Value or 0 end)
        print("[SYSTEM] 🔍 Level check:", level)

        -- ===== PRIORITY 1: Fruit Farm (Level >= FruitMinLevel) =====
        if _G.Config.FruitFarm and level >= _G.Config.FruitMinLevel then
            print("[SYSTEM] 🍎 Level " .. level .. " >= " .. _G.Config.FruitMinLevel .. " → Checking Fruit Farm...")
            
            local hasFruit = checkHasFruit(_G.Config.TargetFruit)
            if hasFruit then
                print("[SYSTEM] ✅ Already have " .. _G.Config.TargetFruit .. " → Fruit Farm Mode!")
                isFruitFarming = true -- ตั้ง flag
                equipFruit(_G.Config.TargetFruit)
                
                -- Teleport to fruit farm position
                local island = _G.Config.FruitFarmIsland
                local pos = _G.Config.FruitFarmPos
                pcall(function() tpRemote:FireServer(island) end)
                task.wait(3)
                
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    for i = 1, 10 do
                        char.HumanoidRootPart.CFrame = pos
                        task.wait(0.1)
                    end
                end
                
                -- เริ่ม AFK Fruit Farm Loop
                task.spawn(fruitFarmLoop)
                break -- ออกจาก loop → ให้ fruitFarmLoop ทำงาน
            else
                print("[SYSTEM] ❌ No " .. _G.Config.TargetFruit .. " → Starting Fruit Farm process...")
                pcall(startFruitFarm)
                break -- ออกจาก loop หลังตั้งค่า Fruit Farm เสร็จ
            end
        end

        -- ===== Level < HakiMinLevel → ฟาร์มปกติ =====
        if level < _G.Config.HakiMinLevel then
            print("[SYSTEM] 📈 Level " .. level .. " - Normal Farm (Melee)")
            task.wait(60) -- เช็คใหม่ทุก 60 วิ
            continue
        end

        -- ===== Level >= HakiMinLevel =====
        -- STEP 1: เช็ค Dark Blade ก่อนเลย
        print("[SYSTEM] 🗡️ Checking Dark Blade...")
        local hasBlade = findDarkBladeInHand() ~= nil
        if not hasBlade then
            hasBlade = equipDarkBladeFromInventory()
        end

        if hasBlade then
            print("[SYSTEM] ✅ Dark Blade found! Normal Farm...")
            break -- มีดาบแล้ว → ออกจาก loop ไปฟาร์มปกติ
        end

        -- STEP 2: ไม่มีดาบ → เช็ค Haki
        print("[SYSTEM] ❌ No Dark Blade | Checking Haki...")
        local hasHaki = checkHakiStatus()

        if hasHaki then
            -- STEP 3: มี Haki แต่ไม่มีดาบ → ซื้อดาบ
            print("[SYSTEM] ✅ Has Haki but no Dark Blade → Buying...")
            if _G.Config.BuyDarkBlade then
                pcall(buyDarkBlade)
            end
            print("[SYSTEM] 🗡️ Dark Blade process done! Normal Farm...")
            break
        end

        -- STEP 4: ไม่มีทั้ง Haki + ดาบ → ทำ Haki Quest
        if _G.Config.HakiQuest and not isHakiQuestActive then
            print("[SYSTEM] 🔥 No Haki + No Dark Blade → Starting Haki Quest...")
            isHakiQuestActive = true
            pcall(startHakiQuest)
            -- หลัง Haki Quest เสร็จ (ซื้อดาบใน farmThiefForHaki แล้ว)
            isHakiQuestActive = false
            print("[SYSTEM] ✅ Haki Quest done! Normal Farm...")
            break
        end

        task.wait(60) -- เช็คใหม่ทุก 60 วิ
    end
end)

-- Normal Farm
task.spawn(function()
    task.wait(15)
    pcall(farmLoop)
end)

-- ═══════════════════════════════════════════════════════════════
-- [13] EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════
player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        task.wait(1.5)
        pcall(rejoin)
    end
end)

Players.PlayerRemoving:Connect(function()
    pcall(function()
        game:HttpGet("https://node-api--0890939481gg.replit.app/leave")
    end)
end)

-- ═══════════════════════════════════════════════════════════════
-- [14] HEARTBEAT PHYSICS LOCK (แบบ v3 เป๊ะ)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if player.Character then
            -- ล็อคแค่ velocity (ไม่ล็อค Anchored/PlatformStand) เพื่อให้รับ/ทำดาเมจได้
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    v.CanCollide = false
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end)
