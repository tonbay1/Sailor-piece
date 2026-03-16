repeat task.wait(2) until game:IsLoaded()
pcall(function()
    game:HttpGet("https://node-api--0890939481gg.replit.app/join")
end)

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local vim = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer

	-- ปิดการแสดง error messages ทั้งหมดอย่างสมบูรณ์
	local oldError = error
	local oldWarn = warn
	local oldPrint = print
	
	-- Override ทุก output functions
	error = function() end
	warn = function() end
	
	-- ปิด ScriptContext errors
	pcall(function()
		game:GetService("ScriptContext").Error:Connect(function() end)
	end)
	
	-- ปิด LogService
	pcall(function()
		game:GetService("LogService").MessageOut:Connect(function() end)
	end)
	
	-- ปิด TestService output
	pcall(function()
		game:GetService("TestService").Error:Connect(function() end)
		game:GetService("TestService").ServerOutput:Connect(function() end)
	end)
	
	-- Override print function อย่างสมบูรณ์
	print = function(...)
		local args = {...}
		if not args[1] then return end
		
		local text = tostring(args[1])
		
		-- บล็อค error messages ทั้งหมด
		local blockedKeywords = {
			"Error", "error", "ERROR",
			"Stack", "stack", "STACK", 
			"attempt to call", "attempt to index",
			"CrossExperience", "CorePackages",
			"DEBUG", "Script", "nil value",
			"ServerScriptService", "ReplicatedStorage",
			"Workspace", "Players"
		}
		
		for _, keyword in ipairs(blockedKeywords) do
			if string.find(text, keyword) then
				return -- ไม่แสดงเลย
			end
		end
		
		-- แสดงเฉพาะ log ที่เราต้องการ
		if string.find(text, "%[HAKI") or string.find(text, "%[SYSTEM%]") or 
		   string.find(text, "%[FARM%]") or string.find(text, "%[WEAPON%]") then
			oldPrint(...)
		end
	end
	
	-- ปิด output ทั้งหมดจาก console
	pcall(function()
		local mt = getrawmetatable(game)
		local oldNamecall = mt.__namecall
		
		setreadonly(mt, false)
		mt.__namecall = function(self, ...)
			local method = getnamecallmethod()
			if method == "print" or method == "warn" or method == "error" then
				return
			end
			return oldNamecall(self, ...)
		end
		setreadonly(mt, true)
	end)

	-- ปิด setting ลดแลค
	local SettingsToggle = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle")

	local settings = {
	"DisablePvP",
	"DisableVFX",
	"DisableOtherVFX",
	"RemoveTexture",
	"AutoSkillC",
	"RemoveShadows"
	}

	for _,setting in ipairs(settings) do
		local current = player:FindFirstChild("Settings")
		and player.Settings:FindFirstChild(setting)

		if not current or current.Value ~= true then
			SettingsToggle:FireServer(setting, true)
		end
	end

	-- ======================

	


	
	local lastQuest = nil
	local BlackScreen = true

	local function setBlack(state)

		if state then
			game.Lighting.Brightness = 0
			game.Lighting.GlobalShadows = false

			for _,v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.LocalTransparencyModifier = 1
				end
			end
		else
			for _,v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.LocalTransparencyModifier = 0
				end
			end
		end

	end

	setBlack(true)

	-- GUI
	local gui = Instance.new("ScreenGui")
	gui.Parent = player.PlayerGui
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.Parent = gui
	button.Size = UDim2.new(0,160,0,45)
	button.Position = UDim2.new(0,20,0.5,-22)
	button.BackgroundColor3 = Color3.fromRGB(25,25,25)
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.Text = "FpsBoot : ON"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16

	-- มุมโค้ง
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,10)
	corner.Parent = button

	-- เส้นขอบ
	local stroke = Instance.new("UIStroke")
	stroke.Parent = button
	stroke.Color = Color3.fromRGB(0,170,255)
	stroke.Thickness = 2

	-- เงา
	local shadow = Instance.new("ImageLabel")
	shadow.Parent = button
	shadow.BackgroundTransparency = 1
	shadow.Size = UDim2.new(1,20,1,20)
	shadow.Position = UDim2.new(0,-10,0,-10)
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.7
	shadow.ZIndex = 0

	button.MouseButton1Click:Connect(function()

	BlackScreen = not BlackScreen
	setBlack(BlackScreen)

	if BlackScreen then
		button.Text = "BlackScreen : ON"
	else
		button.Text = "BlackScreen : OFF"
	end

end)

-- ถ้าตายให้เปิดใหม่ตามสถานะ
player.CharacterAdded:Connect(function()
task.wait(1)
setBlack(BlackScreen)
end)


local hitRemote = ReplicatedStorage.CombatSystem.Remotes.RequestHit
local questRemote = ReplicatedStorage.RemoteEvents.QuestAccept
local abandonRemote = ReplicatedStorage.RemoteEvents.QuestAbandon
local statRemote = ReplicatedStorage.RemoteEvents.AllocateStat
local tpRemote = ReplicatedStorage.Remotes.TeleportToPortal

local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	return char,hrp,hum
end

local char,hrp,hum = getChar()

-- Equip weapon at start
task.spawn(function()
	task.wait(3)
	
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then return end
	
	local currentChar = player.Character
	if not currentChar then return end
	
	local currentHum = currentChar:FindFirstChild("Humanoid")
	if not currentHum then return end
	
	-- List all tools in backpack
	print("=== Tools in Backpack ===")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			print("Found tool:", tool.Name)
		end
	end
	print("=========================")
	
	-- Try Combat first (default weapon)
	local tool = backpack:FindFirstChild("Combat") or currentChar:FindFirstChild("Combat")
	
	if tool and tool.Parent == backpack then
		currentHum:EquipTool(tool)
		print("Equipped Combat from backpack")
	end
end)

-- ======================
-- Inventory Tracker (by Rarity)
-- ======================
local inventoryByRarity = {
	Secret = {},
	Mythical = {},
	Legendary = {},
	Epic = {},
	Rare = {},
	Uncommon = {},
	Common = {}
}

local cratesAndBoxes = {}

task.spawn(function()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local updateInventory = Remotes:WaitForChild("UpdateInventory")
	local requestInventory = Remotes:WaitForChild("RequestInventory")
	
	-- Load configs
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local ItemRarityConfig = require(Modules:WaitForChild("ItemRarityConfig"))
	
	updateInventory.OnClientEvent:Connect(function(category, items)
		print("[INVENTORY] Received update for category:", category, "| Items count:", items and #items or 0)
		
		if not items then return end
		
		-- Track all categories
		if category == "Items" or category == "Accessories" or category == "Auras" or category == "Cosmetics" or category == "Melee" or category == "Sword" or category == "Power" then
			for _, item in pairs(items) do
				local itemName = item.name
				local quantity = item.quantity or 1
				
				if not itemName then continue end
				
				-- Check if it's a crate/box by name
				if itemName:lower():find("crate") or itemName:lower():find("box") or itemName:lower():find("chest") then
					cratesAndBoxes[itemName] = quantity
					print("[INVENTORY] Crate:", itemName, "x"..quantity)
				end
				
				-- Get rarity and store
				local success, rarity = pcall(function()
					return ItemRarityConfig:GetRarity(itemName)
				end)
				
				if success and rarity and inventoryByRarity[rarity] then
					inventoryByRarity[rarity][itemName] = quantity
					if rarity == "Secret" or rarity == "Mythical" or rarity == "Legendary" then
						print("[INVENTORY]", rarity, ":", itemName, "x"..quantity)
					end
				end
			end
		end
	end)
	
	-- Request inventory data on start
	task.wait(3)
	print("[INVENTORY] Requesting inventory data...")
	pcall(function()
		requestInventory:FireServer()
	end)
end)

-- Print inventory by rarity (F1 key)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		local data = player:WaitForChild("Data", 2)
		if not data then return end
		
		local level = data:FindFirstChild("Level") and data.Level.Value or 0
		local money = data:FindFirstChild("Money") and data.Money.Value or 0
		local gems = data:FindFirstChild("Gems") and data.Gems.Value or 0
		
		print("\n========================================")
		print("📊 INVENTORY SUMMARY")
		print("========================================")
		print("⭐ Level: " .. level)
		print("💰 Money: " .. money)
		print("💎 Gems: " .. gems)
		print("========================================\n")
		
		local rarityOrder = {"Secret", "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
		local rarityEmojis = {
			Secret = "🌟",
			Mythical = "✨",
			Legendary = "🔥",
			Epic = "💜",
			Rare = "💙",
			Uncommon = "💚",
			Common = "⚪"
		}
		
		-- Show Crates/Boxes first
		local crateCount = 0
		for _ in pairs(cratesAndBoxes) do
			crateCount = crateCount + 1
		end
		
		if crateCount > 0 then
			print("📦 [CRATES & BOXES] - " .. crateCount .. " types:")
			for crateName, quantity in pairs(cratesAndBoxes) do
				print("   • " .. crateName .. " x" .. quantity)
			end
			print("")
		end
		
		-- Show items by rarity
		for _, rarity in ipairs(rarityOrder) do
			local items = inventoryByRarity[rarity]
			local count = 0
			
			for _ in pairs(items) do
				count = count + 1
			end
			
			if count > 0 then
				print(rarityEmojis[rarity] .. " [" .. rarity:upper() .. "] - " .. count .. " items:")
				for itemName, quantity in pairs(items) do
					print("   • " .. itemName .. " x" .. quantity)
				end
				print("")
			end
		end
		
		print("========================================")
		print("Press F1 to refresh inventory")
		print("========================================\n")
	end
end)

-- ======================
-- Horst Level Display (with Gems + Inventory)
-- ======================
task.spawn(function()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- รอ LocalPlayer
local player = Players.LocalPlayer
while not player do
	task.wait()
	player = Players.LocalPlayer
end

-- รอ Data (เพิ่มเวลารอเป็น 30 วินาที)
local data = player:WaitForChild("Data", 30)
if not data then 
	print("[HORST] ❌ ERROR: Data not found after 30s!")
	return 
end

print("[HORST] ✅ Data loaded successfully")

-- Wait for inventory data to load first
task.wait(5)
print("[HORST] Starting Horst Display with inventory tracking...")

while task.wait(1) do

	-- Get current values directly
	local level = (data:FindFirstChild("Level") and data.Level.Value) or 0
	local money = (data:FindFirstChild("Money") and data.Money.Value) or 0
	local gems = (data:FindFirstChild("Gems") and data.Gems.Value) or 0
	
	-- Check Haki status (safe version - won't break if error)
	local hakiStatus = "❌"
	pcall(function()
		local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
		if statsUI then
			for _, desc in pairs(statsUI:GetDescendants()) do
				if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
					-- Found Haki!
					for _, child in pairs(desc:GetDescendants()) do
						if child.Name == "HakiLevel" and child:IsA("TextLabel") then
							hakiStatus = "✅ " .. child.Text
							break
						end
					end
					if hakiStatus == "❌" then
						hakiStatus = "✅ Haki"
					end
					break
				end
			end
		end
	end)
	
	-- Build item lists by rarity
	local itemLists = {
		Secret = {},
		Mythical = {},
		Legendary = {},
		Epic = {},
		Rare = {},
		Uncommon = {},
		Common = {}
	}
	
	local totalItems = 0
	for rarity, items in pairs(inventoryByRarity) do
		if itemLists[rarity] then
			for itemName, quantity in pairs(items) do
				table.insert(itemLists[rarity], itemName.." x"..quantity)
				totalItems = totalItems + 1
			end
		end
	end
	
	-- Build crates list
	local cratesList = {}
	for crateName, quantity in pairs(cratesAndBoxes) do
		table.insert(cratesList, crateName.." x"..quantity)
	end

	-- Format money and gems with K/M abbreviations
	local moneyStr = money >= 1000000 and string.format("%.1fM", money/1000000) or 
					 money >= 1000 and string.format("%.0fK", money/1000) or tostring(money)
	local gemsStr = gems >= 1000000 and string.format("%.1fM", gems/1000000) or 
					gems >= 1000 and string.format("%.0fK", gems/1000) or tostring(gems)
	
	local message = hakiStatus.." ⭐LVL "..level.." 💰"..moneyStr.." 💎"..gemsStr
	print("[HORST]", message)
	
	-- New priority order: Aura > Clan Reroll > Race Reroll > Trait Reroll > Mythical Chest > Red items
	local auraItems = {}
	local clanRerollItems = {}
	local raceRerollItems = {}
	local traitRerollItems = {}
	local mythicalChestItems = {}
	local redBorderItems = {}
	
	-- Check crates
	for _, crateInfo in pairs(cratesList) do
		local crateName = crateInfo:lower()
		if crateName:find("mythical chest") then
			table.insert(mythicalChestItems, crateInfo)
		end
	end
	
	-- Check items by new priority order
	for rarity, items in pairs(itemLists) do
		for _, itemInfo in pairs(items) do
			local itemName = itemInfo:lower()
			
			-- Priority 1: Aura (highest priority)
			if itemName:find("aura") then
				table.insert(auraItems, itemInfo)
			-- Priority 2: Clan Reroll
			elseif itemName:find("clan reroll") then
				table.insert(clanRerollItems, itemInfo)
			-- Priority 3: Race Reroll
			elseif itemName:find("race reroll") then
				table.insert(raceRerollItems, itemInfo)
			-- Priority 4: Trait Reroll
			elseif itemName:find("trait reroll") then
				table.insert(traitRerollItems, itemInfo)
			-- Priority 6: Red border items (Adamantite, Conqueror Fragment, Diamond)
			elseif itemName:find("adamantite") or itemName:find("conqueror fragment") or itemName:find("diamond") then
				table.insert(redBorderItems, itemInfo)
			end
		end
	end
	
	-- Combine in priority order
	local allImportantItems = {}
	for _, item in pairs(auraItems) do table.insert(allImportantItems, item) end
	for _, item in pairs(clanRerollItems) do table.insert(allImportantItems, item) end
	for _, item in pairs(raceRerollItems) do table.insert(allImportantItems, item) end
	for _, item in pairs(traitRerollItems) do table.insert(allImportantItems, item) end
	for _, item in pairs(mythicalChestItems) do table.insert(allImportantItems, item) end
	for _, item in pairs(redBorderItems) do table.insert(allImportantItems, item) end
	
	-- Show important items with proper formatting and emojis
	if #allImportantItems > 0 then
		-- Limit to max 4 items for better display
		local displayItems = {}
		local maxItems = 4
		
		for i = 1, math.min(maxItems, #allImportantItems) do
			local item = allImportantItems[i]
			local itemLower = item:lower()
			local emoji = ""
			
			-- Add emoji based on item type
			if itemLower:find("aura") then
				emoji = "✨"
			elseif itemLower:find("clan reroll") then
				emoji = "🔄"
			elseif itemLower:find("race reroll") then
				emoji = "🎲"
				item = item:gsub("Race Reroll", "RaceR")
			elseif itemLower:find("trait reroll") then
				emoji = "🎯"
				item = item:gsub("Trait Reroll", "TraitR")
			elseif itemLower:find("mythical chest") then
				emoji = "📦"
			elseif itemLower:find("adamantite") then
				emoji = "💚"
			elseif itemLower:find("diamond") then
				emoji = "💎"
			elseif itemLower:find("conqueror fragment") then
				emoji = "🔥"
			else
				emoji = "⚡"
			end
			
			table.insert(displayItems, emoji..item)
		end
		
		local itemText = table.concat(displayItems, " ")
		if #allImportantItems > maxItems then
			itemText = itemText .. " +" .. (#allImportantItems - maxItems)
		end
		
		message = message .. " " .. itemText
		
		-- Truncate if still too long (max 180 chars total for better readability)
		if #message > 180 then
			message = message:sub(1, 177) .. "..."
		end
	elseif totalItems > 0 or #cratesList > 0 then
		message = message .. " Items: "..totalItems
	else
		message = message .. " Loading..."
	end

	local json = {
		Level = level,
		Money = money,
		Gems = gems,
		Inventory = {
			Crates = #cratesList,
			Secret = #itemLists.Secret,
			Mythical = #itemLists.Mythical,
			Legendary = #itemLists.Legendary,
			Epic = #itemLists.Epic,
			Rare = #itemLists.Rare,
			Uncommon = #itemLists.Uncommon,
			Common = #itemLists.Common,
			TotalItems = totalItems
		},
		CratesDetail = cratesAndBoxes,
		ItemsByRarity = inventoryByRarity,
		CratesList = cratesList,
		ItemLists = itemLists
	}

	local encoded = HttpService:JSONEncode(json)

	pcall(function()
		_G.Horst_SetDescription(message, encoded)
	end)

end

end)
-- auto hit
task.spawn(function()
while task.wait(0.4) do
	pcall(function()

	local currentChar = player.Character
	if not currentChar then return end
	
	local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
	if not currentHrp then return end

	hitRemote:FireServer()

	local nearestNPC
	local distance = math.huge

	for _,npc in ipairs(workspace.NPCs:GetChildren()) do
		if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
			if npc.Humanoid.Health > 0 then
				local dist = (currentHrp.Position - npc.HumanoidRootPart.Position).Magnitude

				if dist < distance then
					distance = dist
					nearestNPC = npc
				end
			end
		end
	end

	-- ถ้ามอนอยู่ใกล้ (เช่น 12 studs)
	if nearestNPC and distance <= 12 then
		vim:SendKeyEvent(true,"Z",false,game)
		task.wait(0.1)
		vim:SendKeyEvent(false,"Z",false,game)
	end

end)
end
end)


-- Auto stat allocation - Sword 50%, Defense 30%, Power 20%
local function allocateStat(statName, amount)
	pcall(function()
		for i = 1, amount do
			statRemote:FireServer(statName, 1)
			task.wait(0.05)
		end
	end)
end

local function autoAllocate()
	local points = 0
	pcall(function()
		points = player.Data.StatPoints.Value or 0
	end)
	
	if points <= 0 then return end
	
	print("[AUTO STATS] Stat points available:", points)
	
	-- อัพแบบสลับกัน: Sword 3, Defense 2, Power 1 (รวม 6 points ต่อรอบ)
	-- สัดส่วน: Sword 50%, Defense 30%, Power 20%
	local swordTotal = 0
	local defenseTotal = 0
	local powerTotal = 0
	
	while points > 0 do
		-- รอบละ 6 points: Sword 3, Defense 2, Power 1
		
		-- อัพ Sword 3 points (หรือน้อยกว่าถ้า points เหลือน้อย)
		local swordNow = math.min(3, points)
		if swordNow > 0 then
			pcall(function()
				statRemote:FireServer("Sword", swordNow)
			end)
			points = points - swordNow
			swordTotal = swordTotal + swordNow
			task.wait(0.1)
		end
		
		if points <= 0 then break end
		
		-- อัพ Defense 2 points
		local defenseNow = math.min(2, points)
		if defenseNow > 0 then
			pcall(function()
				statRemote:FireServer("Defense", defenseNow)
			end)
			points = points - defenseNow
			defenseTotal = defenseTotal + defenseNow
			task.wait(0.1)
		end
		
		if points <= 0 then break end
		
		-- อัพ Power 1 point
		local powerNow = math.min(1, points)
		if powerNow > 0 then
			pcall(function()
				statRemote:FireServer("Power", powerNow)
			end)
			points = points - powerNow
			powerTotal = powerTotal + powerNow
			task.wait(0.1)
		end
	end
	
	print("[AUTO STATS] ✅ Allocated: Sword +" .. swordTotal .. ", Defense +" .. defenseTotal .. ", Power +" .. powerTotal)
end

-- เรียกใช้ autoAllocate ทุก 5 วินาที
task.spawn(function()
	while task.wait(5) do
		pcall(autoAllocate)
	end
end)

-- Auto Open Lucky Boxes
task.spawn(function()
while task.wait(5) do
	pcall(function()
		local currentChar = player.Character
		if not currentChar then return end
		
		local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
		if not currentHrp then return end
		
		-- Find all boxes in workspace
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") or obj:IsA("Part") then
				local name = obj.Name:lower()
				-- Check if it's a box/chest
				if name:find("box") or name:find("chest") or name:find("lucky") or name:find("crate") then
					local boxPart = obj:IsA("Part") and obj or obj:FindFirstChild("HitBox") or obj:FindFirstChild("Main") or obj:FindFirstChildWhichIsA("Part")
					
					if boxPart then
						local distance = (currentHrp.Position - boxPart.Position).Magnitude
						
						-- If box is nearby (within 100 studs)
						if distance <= 100 then
							-- Teleport to box
							currentHrp.CFrame = boxPart.CFrame
							task.wait(0.5)
							
							-- Try to interact (common methods)
							if obj:FindFirstChild("ClickDetector") then
								fireclickdetector(obj.ClickDetector)
							end
							
							-- Try ProximityPrompt
							local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
							if prompt then
								fireproximityprompt(prompt)
							end
							
							task.wait(1)
						end
					end
				end
			end
		end
	end)
end
end)

local function getInfoQuest()
	local success, result = pcall(function()
		return ReplicatedStorage.RemoteEvents.GetQuestArrowTarget:InvokeServer()
	end)
	
	if success and result then
		return result
	else
		return nil
	end
end

local function getBestWeapon()
	local weapons = {}
	
	-- Collect all weapons from Backpack and Character
	for _, container in pairs({player.Backpack, player.Character}) do
		for _, tool in pairs(container:GetChildren()) do
			if tool:IsA("Tool") and tool.Name ~= "Combat" then
				-- Try to get weapon level from name (e.g., "Sword Lv.50")
				local level = tonumber(tool.Name:match("Lv%.?%s*(%d+)")) or 0
				
				-- Store weapon info
				table.insert(weapons, {
					tool = tool,
					name = tool.Name,
					level = level,
					tooltip = tool.ToolTip or ""
				})
			end
		end
	end
	
	-- Sort by level (highest first)
	table.sort(weapons, function(a, b)
		return a.level > b.level
	end)
	
	-- Return best weapon or Combat as fallback
	if #weapons > 0 then
		print("[WEAPON] Best weapon found:", weapons[1].name, "Lv."..weapons[1].level)
		return weapons[1].name
	else
		print("[WEAPON] No weapon found, using Combat")
		return "Combat"
	end
end

local function getnpcQuest(npcname)
	local success, result = pcall(function()
		local module = require(ReplicatedStorage.Modules.QuestConfig)
		for questNPC, questData in pairs(module.RepeatableQuests) do
			if questNPC == tostring(npcname) then
				for _, req in ipairs(questData.requirements) do
					return req.npcType
				end
			end
		end
		return nil
	end)
	
	if success then
		return result
	else
		return nil
	end
end

local function tweenPos(targetCF)
	-- Use direct reference like working example
	local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local startCF = root.CFrame
	local steps = 5
	
	for i = 1, steps do
		local alpha = i / steps
		root.CFrame = startCF:Lerp(targetCF, alpha)
		task.wait(0.05)
	end
end

local function farmNPC(name)
	print("[FARM] Starting to farm:", name)
	
	-- หา NPC ตัวแรกที่มีชีวิต
	local function findAliveNPC()
		-- ลองหา NPC แบบมีเลข 1-5
		for i = 1, 5 do
			local npcName = name .. i
			local npc = workspace.NPCs:FindFirstChild(npcName)
			
			if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				return npc
			end
		end
		
		-- ลองหาแบบไม่มีเลข
		local npc = workspace.NPCs:FindFirstChild(name)
		if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
			return npc
		end
		
		return nil
	end
	
	-- Teleport ไปที่ NPC ตัวแรกที่เจอ (ใช้ tween)
	local firstNPC = findAliveNPC()
	if firstNPC then
		local target = firstNPC:FindFirstChild("HumanoidRootPart")
			or firstNPC:FindFirstChild("Torso")
			or firstNPC:FindFirstChild("UpperTorso")
		
		if target and hrp then
			print("[FARM] Teleporting to:", firstNPC.Name)
			local targetCF = target.CFrame * CFrame.new(0, 5, 10)
			tweenPos(targetCF)
			task.wait(0.5)
		end
	else
		print("[FARM] No NPC found:", name)
		return
	end

	-- เริ่มฟาร์ม
	while task.wait(0.2) do
		if hum.Health <= 0 then 
			print("[FARM] Player died, stopping farm")
			break 
		end

		local found = false

		for i = 1, 5 do
			local npc = workspace.NPCs:FindFirstChild(name .. i)

			if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				found = true

				local target = npc:FindFirstChild("HumanoidRootPart")
					or npc:FindFirstChild("Torso")
					or npc:FindFirstChild("UpperTorso")

				if target then
					local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = target.CFrame * CFrame.new(0, 0, 7)
						task.wait(0.7)
					end
				end
			end
		end
		
		-- ลองหาแบบไม่มีเลข
		if not found then
			local npc = workspace.NPCs:FindFirstChild(name)
			if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				found = true
				
				local target = npc:FindFirstChild("HumanoidRootPart")
					or npc:FindFirstChild("Torso")
					or npc:FindFirstChild("UpperTorso")
				
				if target then
					local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = target.CFrame * CFrame.new(0, 0, 7)
						task.wait(0.7)
					end
				end
			end
		end

		if not found then
			print("[FARM] No more NPCs found, stopping farm")
			break
		end
	end
	
	print("[FARM] Finished farming:", name)
end


local function acceptQuest(questName, mapName)
	print("[QUEST] Checking quest status...")
	
	-- เช็คว่ามี quest UI หรือยัง
	local questUI = player.PlayerGui:FindFirstChild("QuestUI")
	if not questUI then
		warn("[QUEST] QuestUI not found!")
		return
	end
	
	-- ดึงข้อมูล quest
	local questInfo = getInfoQuest()
	if not questInfo then
		warn("[QUEST] Cannot get quest info!")
		return
	end
	
	local questVisible = questUI.Quest.Visible
	
	-- ถ้ายังไม่มี quest
	if not questVisible then
		print("[QUEST] No quest active, teleporting to Quest NPC...")
		
		-- Teleport ไปที่ Quest NPC โดยตรง
		if questInfo.position then
			tweenPos(CFrame.new(questInfo.position))
			task.wait(1)
		end
		
		-- รับ quest ด้วย questInfo.npcName
		print("[QUEST] Accepting quest:", questInfo.npcName)
		pcall(function()
			questRemote:FireServer(questInfo.npcName)
		end)
		
		task.wait(1)
		print("[QUEST] Quest accepted!")
		
	-- ถ้ามี quest แล้วแต่ไม่ตรง
	elseif questVisible then
		local currentTitle = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
		
		if currentTitle ~= questInfo.questTitle then
			print("[QUEST] Wrong quest, abandoning...")
			pcall(function()
				abandonRemote:FireServer("repeatable")
			end)
			task.wait(1)
			
			-- Teleport และรับ quest ใหม่
			if questInfo.position then
				tweenPos(CFrame.new(questInfo.position))
				task.wait(1)
			end
			
			print("[QUEST] Accepting quest:", questInfo.npcName)
			pcall(function()
				questRemote:FireServer(questInfo.npcName)
			end)
			
			task.wait(1)
			print("[QUEST] Quest accepted!")
		else
			print("[QUEST] Already on correct quest:", currentTitle)
		end
	end
end

local function farmBoss(name)

	local npc = workspace.NPCs:FindFirstChild(name)

	if npc and npc:FindFirstChild("Humanoid") then

		local target = npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChild("Torso")
		or npc:FindFirstChild("UpperTorso")

		if target then
			print("Farming Boss:", name)
			while npc.Parent and npc.Humanoid.Health > 0 do
				local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not root then break end
				
				local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
				if not hum or hum.Health <= 0 then break end

				root.CFrame = target.CFrame * CFrame.new(0,0,7)

				task.wait()

			end
			print("Boss defeated:", name)
		end
	else
		-- Boss not found, wait for respawn
		print("Boss not found:", name, "- waiting for respawn")
		task.wait(5)
	end
end

-- Auto Farm All Bosses (DISABLED - main loop already farms bosses by level)
-- Uncomment below if you want to farm bosses separately for rare drops
--[[local bossesToFarm = {
	{name = "MonkeyBoss", minLevel = 500, map = "Jungle"},
	{name = "DesertBoss", minLevel = 1000, map = "Desert"},
	{name = "SnowBoss", minLevel = 2000, map = "Snow"},
	{name = "PandaMiniBoss", minLevel = 4000, map = "Shibuya"},
}

task.spawn(function()
	task.wait(10)
	
	while task.wait(30) do
		pcall(function()
			local level = player.Data.Level.Value
			
			for _, bossInfo in ipairs(bossesToFarm) do
				if level >= bossInfo.minLevel then
					tpRemote:FireServer(bossInfo.map)
					task.wait(2)
					
					local boss = workspace.NPCs:FindFirstChild(bossInfo.name)
					if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
						print("Found boss for drops:", bossInfo.name)
						farmBoss(bossInfo.name)
						task.wait(2)
					end
				end
			end
		end)
	end
end)
--]]

-- ==================== HAKI QUEST CONFIG ====================
local HAKI_QUEST_CONFIG = {
    ENABLED = true,                     -- เปิด/ปิด Haki Quest
    TARGET_KILLS = 150,                 -- เป้าหมาย 150 ตัว
    USE_ONLY_PUNCH = true,              -- ใช้แค่หมัดปกติ
    CHECK_PROGRESS = true,              -- เช็คความคืบหน้า
    HAKI_QUEST_NPC = "HakiQuestNPC",   -- ชื่อ NPC ที่รับภารกิจ
    TARGET_NPC = "Thief",              -- NPC ที่ต้องตี
}
-- ==========================================================

-- Haki Quest System
local function acceptHakiQuest()
    print("[HAKI QUEST] Accepting Haki quest from HakiQuestNPC...")
    
    local hakiNPCPos = Vector3.new(-497.94, 23.66, -1252.64)
    local char = player.Character
    local VIM = game:GetService("VirtualInputManager")
    
    -- เช็คว่ามีภารกิจหลักอยู่หรือไม่ ถ้ามีและไม่ใช่ Haki quest ให้ยกเลิกก่อน
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local currentTitle = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            print("[HAKI QUEST] Current quest:", currentTitle)
            
            if not currentTitle:find("Path to Haki") then
                print("[HAKI QUEST] ⚠️ Has non-Haki quest! Abandoning:", currentTitle)
                abandonRemote:FireServer("repeatable")
                task.wait(2)
                print("[HAKI QUEST] ✅ Quest abandoned!")
            else
                print("[HAKI QUEST] Already has Haki quest, no need to abandon")
                return
            end
        end
    end)
    
    -- Teleport ไป HakiQuestNPC
    tweenPos(CFrame.new(hakiNPCPos))
    task.wait(2)
    
    -- รับภารกิจผ่าน RemoteEvent (ไม่ใช้ E key)
    print("[HAKI QUEST] Accepting quest via RemoteEvent...")
    pcall(function()
        questRemote:FireServer("HakiQuestNPC")
    end)
    task.wait(2)
    
    -- เช็คว่าภารกิจที่รับมาคืออะไร
    task.wait(1)
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local questTitle = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            local questDesc = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            print("[HAKI QUEST] ========================================")
            print("[HAKI QUEST] Quest Title:", questTitle)
            print("[HAKI QUEST] Description:", questDesc)
            print("[HAKI QUEST] ========================================")
        else
            print("[HAKI QUEST] QuestUI not visible after accepting")
        end
    end)
end

local function checkHakiProgress()
    -- เช็คความคืบหน้าภารกิจ Haki
    local questUI = player.PlayerGui:FindFirstChild("QuestUI")
    if questUI and questUI.Quest.Visible then
        print("[HAKI QUEST] ========== QUEST STATUS ==========")
        
        local questTitle = ""
        local questDesc = ""
        local progressText = ""
        local isCompleted = false
        
        -- เช็คชื่อภารกิจ
        pcall(function()
            questTitle = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            print("[HAKI QUEST] Quest Title:", questTitle)
        end)
        
        -- เช็ครายละเอียดภารกิจ
        pcall(function()
            questDesc = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            print("[HAKI QUEST] Description:", questDesc)
        end)
        
        -- เช็คความคืบหน้าหลายวิธี
        pcall(function()
            -- วิธีที่ 3: หาใน QuestInfo ทั้งหมด
            for _, child in pairs(questUI.Quest.Quest.Holder.Content.QuestInfo:GetChildren()) do
                if child:IsA("TextLabel") and string.find(child.Text, "/") then
                    progressText = child.Text
                    print("[HAKI QUEST] Progress:", child.Name, "=", progressText)
                    
                    -- เช็คว่าเสร็จแล้วหรือไม่
                    local current, total = progressText:match("(%d+)/(%d+)")
                    if current and total and tonumber(current) >= tonumber(total) then
                        isCompleted = true
                        print("[HAKI QUEST] ✅ QUEST COMPLETED! (" .. current .. "/" .. total .. ")")
                    end
                end
            end
        end)
        
        print("[HAKI QUEST] ================================")
        
        -- ถ้าภารกิจเสร็จแล้ว ต้อง teleport ไปส่งภารกิจที่ HakiQuestNPC
        if isCompleted then
            print("[HAKI QUEST] 🎉 Quest completed! Teleporting to HakiQuestNPC to turn in...")
            
            -- Teleport ไป HakiQuestNPC
            local hakiNPCPos = Vector3.new(-497.94, 23.66, -1252.64)
            tweenPos(CFrame.new(hakiNPCPos))
            task.wait(3)
            
            -- รับภารกิจใหม่ (ส่งภารกิจเก่า + รับใหม่)
            print("[HAKI QUEST] Turning in quest and accepting new one...")
            pcall(acceptHakiQuest)
            task.wait(3)
            
            -- เช็คว่าได้ Haki แล้วหรือยัง
            local hasHaki = pcall(checkHakiStatus)
            
            return isCompleted
        end
        
        return isCompleted
    else
        print("[HAKI QUEST] No quest UI visible - Teleporting to HakiQuestNPC...")
        
        -- Teleport ไป HakiQuestNPC
        local hakiNPCPos = Vector3.new(-497.94, 23.66, -1252.64)
        tweenPos(CFrame.new(hakiNPCPos))
        task.wait(3)
        
        -- รับภารกิจใหม่
        pcall(acceptHakiQuest)
        task.wait(3)
        pcall(checkHakiStatus)
        
        return true
    end
end

local function checkHakiStatus()
    print("[HAKI STATUS] ========== CHECKING HAKI STATUS ==========")

    local hasHaki = false
    local hakiInfo = ""

    -- วิธีที่ 1: เช็ค HakiProgressionFrame.Visible (ถ้า Visible = true แสดงว่ามี Haki)
    pcall(function()
        local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
        if statsUI then
            for _, desc in pairs(statsUI:GetDescendants()) do
                if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                    -- Frame visible = มี Haki จริง
                    hasHaki = true
                    print("[HAKI STATUS] ✅ HakiProgressionFrame is visible!")
                    
                    -- หา HakiLevel text
                    for _, child in pairs(desc:GetDescendants()) do
                        if child.Name == "HakiLevel" and child:IsA("TextLabel") then
                            hakiInfo = child.Text
                            print("[HAKI STATUS] ✅ HakiLevel:", hakiInfo)
                            break
                        end
                    end
                    break
                end
            end
        end
    end)
    
    if hasHaki then
        print("[HAKI STATUS] ✅ Player HAS Haki!", hakiInfo)
        _G.HAKI_QUEST_MODE = false
        HAKI_QUEST_CONFIG.ENABLED = false
    else
        print("[HAKI STATUS] ❌ Player doesn't have Haki yet")
    end
    
    print("[HAKI STATUS] ================================")
    return hasHaki
end

-- เช็คว่ามี Dark Blade ใน Inventory (ผ่าน Remote) - เหมือน v3
local function checkDarkBlade(targetName)
    targetName = targetName or "Dark Blade"
    local RS = game:GetService("ReplicatedStorage")
    local result = false
    
    local conn
    conn = RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
        for _, item in pairs(data) do
            if item.name == targetName then
                result = true
            end
        end
    end)
    
    RS.Remotes.RequestInventory:FireServer()
    task.wait(1) -- รอให้ทุก tab มาครบ (Items, Melee, Sword, Power, etc.)
    
    pcall(function() conn:Disconnect() end)
    
    return result
end

-- เช็คว่า Dark Blade อยู่ใน Backpack/Character แล้ว (เช็คตรงๆ ไม่เรียก RequestInventory)
local function checkOwnerDarkBlade()
    local has = false
    pcall(function()
        for _, container in pairs({player.Backpack, player.Character}) do
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name or ""
                    local tooltip = tool.ToolTip or ""
                    if tooltip == "Black Blade" or name:find("Dark Blade") then
                        has = true
                        print("[CHECK] ✅ Dark Blade found in", container.Name, ":", name)
                        return
                    end
                end
            end
        end
    end)
    return has
end

-- Equip Dark Blade จาก Inventory → Backpack/Character
local function equipDarkBlade()
    print("[EQUIP] Equipping Dark Blade...")
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
    end)
    task.wait(1)
    
    -- เช็คว่า Equip สำเร็จ
    if checkOwnerDarkBlade() then
        print("[EQUIP] ✅ Dark Blade equipped!")
        return true
    else
        print("[EQUIP] ❌ Failed to equip")
        return false
    end
end

local function resetStats()
    print("[STATS] ========== RESETTING STATS ==========")
    
    pcall(function()
        local resetRemote = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("ResetStats")
        if resetRemote then
            print("[STATS] Resetting all stats...")
            resetRemote:FireServer()
            task.wait(2)
            print("[STATS] ✅ Stats reset successfully!")
        else
            print("[STATS] ❌ ResetStats remote not found")
        end
    end)
    
    print("[STATS] ================================")
end

local function upgradeStats()
    print("[STATS] ========== UPGRADING STATS ==========")
    
    -- เช็คจำนวน Stat Points ที่มี
    local totalStatPoints = 0
    pcall(function()
        totalStatPoints = player.Data.StatPoints.Value or 0
    end)
    
    print("[STATS] Total Stat Points available:", totalStatPoints)
    
    -- แบ่งสเตตัสตามเปอร์เซ็นต์: Sword 50%, Defense 30%, Power 20%
    local swordPoints = math.floor(totalStatPoints * 0.50)
    local defensePoints = math.floor(totalStatPoints * 0.30)
    local powerPoints = math.floor(totalStatPoints * 0.20)
    
    local statsToUpgrade = {
        {name = "Sword", amount = swordPoints},
        {name = "Defense", amount = defensePoints},
        {name = "Power", amount = powerPoints}
    }
    
    print("[STATS] Distribution: Sword", swordPoints, "(50%), Defense", defensePoints, "(30%), Power", powerPoints, "(20%)")
    
    pcall(function()
        local updateRemote = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdatePlayerStats")
        
        if updateRemote then
            for _, stat in ipairs(statsToUpgrade) do
                if stat.amount > 0 then
                    print("[STATS] Upgrading", stat.name, "by", stat.amount, "points...")
                    
                    for i = 1, stat.amount do
                        pcall(function()
                            updateRemote:FireServer(stat.name, 1)
                        end)
                        task.wait(0.1) -- รอเล็กน้อยระหว่างอัพแต่ละครั้ง
                    end
                    
                    print("[STATS] ✅", stat.name, "upgraded!")
                    task.wait(0.5)
                end
            end
            
            print("[STATS] ✅ All stats upgraded successfully!")
            print("[STATS] Final: Sword +" .. swordPoints .. ", Defense +" .. defensePoints .. ", Power +" .. powerPoints)
        else
            print("[STATS] ❌ UpdatePlayerStats remote not found")
        end
    end)
    
    print("[STATS] ================================")
end

local function buyDarkBlade()
    print("[WEAPON PURCHASE] ========== BUYING DARK BLADE ==========")
    
    -- เช็คว่ามีใน Backpack/Character แล้วหรือยัง
    if checkOwnerDarkBlade() then
        print("[WEAPON PURCHASE] ✅ Dark Blade already in Backpack! Just equipping...")
        equipDarkBlade()
        print("[WEAPON PURCHASE] ================================")
        return true
    end
    
    -- เช็คว่ามีใน Inventory หรือไม่ (ยังไม่ได้ Equip)
    print("[WEAPON PURCHASE] Checking Inventory...")
    local hasInInventory = false
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        RS:WaitForChild("Remotes"):WaitForChild("RequestInventory"):FireServer()
        task.wait(3) -- รอให้ Inventory โหลดเสร็จ
        
        -- เช็คว่ามี Dark Blade ใน Inventory
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.ToolTip == "Black Blade") then
                hasInInventory = true
                print("[WEAPON PURCHASE] ✅ Dark Blade found in Inventory!")
                break
            end
        end
    end)
    
    if hasInInventory then
        print("[WEAPON PURCHASE] Dark Blade already in Inventory! Just equipping (no reset)...")
        
        -- แค่ Equip ไม่ต้อง Reset Stats (เพราะ Reset แล้วตอนซื้อครั้งแรก)
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
        end)
        task.wait(2)
        
        print("[WEAPON PURCHASE] ✅ Dark Blade equipped! (no reset needed)")
        print("[WEAPON PURCHASE] ================================")
        return true
    end
    
    -- ยังไม่มีเลย → ต้องซื้อ
    local gem = player.Data.Gems.Value or 0
    local money = player.Data.Money.Value or 0
    print("[WEAPON PURCHASE] Gems:", gem, "Money:", money)
    
    if gem < 150 or money < 250000 then
        print("[WEAPON PURCHASE] ❌ Not enough resources! Need 150 Gems and 250,000 Money")
        return false
    end
    
    print("[WEAPON PURCHASE] Starting purchase process...")
    
    local purchased = false
    for attempt = 1, 20 do
        print("[WEAPON PURCHASE] Attempt", attempt, "to purchase Dark Blade...")
        
        local darkBladeNPCCFrame = CFrame.new(-138.99884, 13.2335539, -1089.99146, 0.180115148, -3.10546184e-08, -0.983645558, 2.62686424e-08, 1, -2.67608993e-08, 0.983645558, -2.10189892e-08, 0.180115148)
        
        local npcHRP = workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart")
        if not npcHRP then
            print("[WEAPON PURCHASE] NPC not found, teleporting...")
            tweenPos(darkBladeNPCCFrame)
            task.wait(2)
        else
            local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
            if prompt then
                print("[WEAPON PURCHASE] Found DarkBladeShopPrompt, triggering...")
                prompt.MaxActivationDistance = math.huge
                fireproximityprompt(prompt)
                task.wait(3)
                
                -- เช็คว่าซื้อสำเร็จ: ใช้ EquipWeapon ดึงดาบ (วิธีที่ทำงานได้)
                print("[WEAPON PURCHASE] Trying to equip Dark Blade from Inventory...")
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
                end)
                task.wait(2)
                
                -- เช็คว่าดาบเข้า Backpack/Character หรือยัง
                local found = false
                for _, container in pairs({player.Character, player.Backpack}) do
                    if container then
                        for _, tool in pairs(container:GetChildren()) do
                            if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.ToolTip == "Black Blade") then
                                found = true
                                break
                            end
                        end
                    end
                    if found then break end
                end
                
                if found then
                    print("[WEAPON PURCHASE] ✅ Dark Blade purchased and equipped!")
                    purchased = true
                    break
                else
                    print("[WEAPON PURCHASE] ⚠️ Purchase may have failed, retrying...")
                end
            else
                print("[WEAPON PURCHASE] ⚠️ DarkBladeShopPrompt not found, retrying...")
                tweenPos(darkBladeNPCCFrame)
                task.wait(2)
            end
        end
        
        task.wait(1)
    end
    
    -- ถ้าซื้อสำเร็จ → Reset Stats ครั้งเดียว + Upgrade Stats
    if purchased then
        print("[WEAPON PURCHASE] Resetting Stats...")
        pcall(function()
            ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("ResetStats"):FireServer()
        end)
        task.wait(2)
        
        pcall(upgradeStats)
        task.wait(2)
        
        print("[WEAPON PURCHASE] ✅ Purchase + Reset + Upgrade complete!")
    end
    
    print("[WEAPON PURCHASE] ================================")
end

-- ฟังก์ชันกลางสำหรับไปหา NPC ส่ง/รับภารกิจ Haki
local function goToHakiNPC()
    local hakiNPCPos = Vector3.new(-497.94, 23.66, -1252.64)
    tweenPos(CFrame.new(hakiNPCPos))
    task.wait(4)
    
    local char = player.Character
    local VIM = game:GetService("VirtualInputManager")
    
    -- กด E key เป็นวิธีหลัก (ทดสอบแล้วได้ผล)
    for i = 1, 5 do
        print("[HAKI QUEST] Press E attempt", i)
        pcall(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(hakiNPCPos) * CFrame.new(0, 0, 3)
            end
        end)
        task.wait(0.5)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(2)
        
        local hasHaki = checkHakiStatus()
        if hasHaki then
            print("[HAKI QUEST] 🎉 Haki obtained via E key!")
            return true
        end
    end
    
    -- Fallback: fireproximityprompt
    print("[HAKI QUEST] Fallback: fireproximityprompt...")
    for i = 1, 3 do
        pcall(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(hakiNPCPos) * CFrame.new(0, 0, 3)
            end
            local hakiNPC = workspace.ServiceNPCs:FindFirstChild("HakiQuestNPC")
            if hakiNPC then
                local npcHRP = hakiNPC:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    local hakiPrompt = npcHRP:FindFirstChild("HakiQuestPrompt")
                    if hakiPrompt then
                        hakiPrompt.MaxActivationDistance = math.huge
                        hakiPrompt.HoldDuration = 0
                        fireproximityprompt(hakiPrompt)
                        print("[HAKI QUEST] ✅ fireproximityprompt fired!")
                    end
                end
            end
        end)
        task.wait(2)
        
        local hasHaki = checkHakiStatus()
        if hasHaki then
            print("[HAKI QUEST] 🎉 Haki obtained!")
            return true
        end
    end
    
    return false
end

local function farmThiefForHaki()
    print("[HAKI QUEST] Starting to farm Thief for Haki quest...")
    
    task.wait(2)
    local targetNPC = "Thief"  -- default
    local killCount = 0
    local lastCheckKills = 0
    
    -- ดึงชื่อ NPC จากภารกิจ (ถ้ามี QuestUI)
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local questTitle = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            local questDesc = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            print("[HAKI QUEST] Quest Title:", questTitle)
            print("[HAKI QUEST] Description:", questDesc)
            
            -- เช็คว่าเป็น Haki quest จริงหรือไม่
            if not questTitle:find("Path to Haki") then
                print("[HAKI QUEST] ⚠️ Not a Haki quest! Abandoning:", questTitle)
                abandonRemote:FireServer("repeatable")
                task.wait(2)
            end
            
            -- ดึงชื่อ NPC จาก description
            local npcName = questDesc:match("Defeat the (%w+)") or questDesc:match("defeat (%w+)")
            if npcName then
                targetNPC = npcName
                print("[HAKI QUEST] Target NPC:", targetNPC)
            end
        else
            print("[HAKI QUEST] No QuestUI visible - will farm Thief by default")
        end
    end)
    
    -- Teleport ไปพื้นที่ NPC
    print("[HAKI QUEST] Teleporting to", targetNPC, "area...")
    pcall(function()
        tpRemote:FireServer("Starter")
    end)
    task.wait(3)
    
    local farmStartTime = tick()
    
    while task.wait(0.5) do
        -- เช็คว่ายังอยู่ใน Haki Quest Mode หรือไม่
        if not HAKI_QUEST_CONFIG.ENABLED or not _G.HAKI_QUEST_MODE then
            print("[HAKI QUEST] Haki Quest mode disabled, stopping...")
            break
        end
        
        -- Timeout 60 นาที
        if tick() - farmStartTime > 3600 then
            print("[HAKI QUEST] ⚠️ Farmed for 60 minutes. Stopping...")
            _G.HAKI_QUEST_MODE = false
            HAKI_QUEST_CONFIG.ENABLED = false
            break
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char.Humanoid.Health <= 0 then continue end
        
        -- ====== เช็คภารกิจทุกรอบ ======
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        local questVisible = questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible
        local shouldGoToNPC = false
        
        if questVisible then
            -- มี QuestUI → เช็ค progress
            pcall(function()
                for _, child in pairs(questUI.Quest.Quest.Holder.Content.QuestInfo:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local text = child.Text
                        -- เช็ค "Completed!" (เครื่องหมายตกใจ)
                        if text:find("Completed!") then
                            shouldGoToNPC = true
                            print("[HAKI QUEST] ✅ Found 'Completed!' - Going to NPC!")
                            break
                        end
                        -- เช็ค progress X/Y
                        if string.find(text, "/") then
                            local current, total = text:match("(%d+)/(%d+)")
                            if current and total then
                                if tonumber(current) >= tonumber(total) then
                                    shouldGoToNPC = true
                                    print("[HAKI QUEST] ✅ Quest completed! (" .. current .. "/" .. total .. ")")
                                end
                            end
                        end
                    end
                end
            end)
        else
            -- ไม่มี QuestUI → ถ้าตีไปมากกว่า 5 ตัวแล้ว ให้ไปเช็คที่ NPC
            if killCount > 5 and (killCount - lastCheckKills) >= 5 then
                print("[HAKI QUEST] No QuestUI + killed", killCount, "mobs - Going to check at NPC...")
                shouldGoToNPC = true
            end
        end
        
        -- ====== ไปหา NPC ส่ง/รับภารกิจ ======
        if shouldGoToNPC then
            print("[HAKI QUEST] 🔄 Going to HakiQuestNPC...")
            lastCheckKills = killCount
            
            local gotHaki = goToHakiNPC()
            if gotHaki then
                print("[HAKI QUEST] 🎉🎉 HAKI OBTAINED!")
                
                -- ไปซื้อ Dark Blade ทันที
                print("[HAKI QUEST] 🛒 Going to buy Dark Blade...")
                _G.HAKI_QUEST_MODE = false
                HAKI_QUEST_CONFIG.ENABLED = false
                
                pcall(function()
                    buyDarkBlade()
                end)
                
                print("[HAKI QUEST] ✅ Haki Quest completed! Exiting...")
                return
            end
            
            -- ยังไม่ได้ Haki → เช็คว่ามีภารกิจใหม่หรือยัง
            task.wait(2)
            local newQuestUI = player.PlayerGui:FindFirstChild("QuestUI")
            local newQuestVisible = newQuestUI and newQuestUI:FindFirstChild("Quest") and newQuestUI.Quest.Visible
            
            if newQuestVisible then
                local newTitle = ""
                pcall(function()
                    newTitle = newQuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
                end)
                print("[HAKI QUEST] New quest after NPC:", newTitle)
                
                -- ดึง NPC ใหม่จาก description
                pcall(function()
                    local newDesc = newQuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
                    local npcName = newDesc:match("Defeat the (%w+)") or newDesc:match("defeat (%w+)")
                    if npcName then
                        targetNPC = npcName
                        print("[HAKI QUEST] New target NPC:", targetNPC)
                    end
                end)
            else
                print("[HAKI QUEST] No new quest visible after NPC visit")
            end
            
            -- กลับไปฟาร์มต่อ
            print("[HAKI QUEST] Teleporting back to farm area...")
            pcall(function()
                tpRemote:FireServer("Starter")
            end)
            task.wait(3)
            continue
        end
        
        -- ====== ฟาร์ม NPC ======
        local npcFound = false
        
        for i = 1, 5 do
            local npcName = targetNPC .. i
            local npc = workspace.NPCs:FindFirstChild(npcName)
            
            if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                npcFound = true
                print("[HAKI QUEST] Found alive", targetNPC .. ":", npcName)
                
                local target = npc:FindFirstChild("HumanoidRootPart")
                if target then
                    print("[HAKI QUEST] Teleporting to:", npcName)
                    
                    while npc.Parent and npc.Humanoid.Health > 0 do
                        if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                        if char.Humanoid.Health <= 0 then break end
                        
                        pcall(function()
                            char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 5)
                        end)
                        
                        pcall(function()
                            ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                        end)
                        
                        task.wait(0.3)
                    end
                    
                    killCount = killCount + 1
                    print("[HAKI QUEST]", targetNPC, "defeated:", npcName, "| Total kills:", killCount)
                    task.wait(0.5)
                    break
                end
            end
        end
        
        if not npcFound then
            print("[HAKI QUEST] No", targetNPC, "found, waiting for respawn...")
            task.wait(3)
        end
    end
end

-- Main Haki Quest Function
local function startHakiQuest()
    if not HAKI_QUEST_CONFIG.ENABLED then return end
    
    print("[HAKI QUEST] Starting Haki Quest System...")
    
    -- รับภารกิจ Haki
    pcall(acceptHakiQuest)
    
    -- เริ่มฟาร์ม Thief
    pcall(farmThiefForHaki)
end

-- Use the working auto quest/farm system from example code
_G.AUTOFUNCTION = true
_G.HAKI_QUEST_MODE = false  -- สลับโหมด

-- ระบบหลักที่จะเช็ค Level → Haki → อาวุธ
task.spawn(function()
    while _G.AUTOFUNCTION do
        task.wait(10) -- เช็คทุก 10 วินาที
        
        local playerLevel = 0
        pcall(function()
            playerLevel = player.Data.Level.Value or 0
        end)
        
        -- เช็คว่าถึง Level 1000 หรือยัง
        if playerLevel >= 1000 then
            -- เช็คว่ามี Haki หรือยัง
            local hasHaki = false
            pcall(function()
                hasHaki = checkHakiStatus()
            end)
            
            if hasHaki then
                -- มี Haki แล้ว → ไปลูปหลัก (ดาบซื้อใน farmThiefForHaki แล้ว)
                print("[SYSTEM] 🎉 Level 1000+ and has Haki! Running Normal Quest System...")
                _G.HAKI_QUEST_MODE = false
                HAKI_QUEST_CONFIG.ENABLED = false
                break
            else
                -- ยังไม่มี Haki ต้องทำ Haki Quest
                if not _G.HAKI_QUEST_MODE then
                    print("[SYSTEM] 🔥 Level 1000+ but no Haki! Starting Haki Quest...")
                    _G.HAKI_QUEST_MODE = true
                    HAKI_QUEST_CONFIG.ENABLED = true
                    pcall(startHakiQuest)
                end
            end
        else
            -- ยังไม่ถึง Level 1000 ทำโค้ดหลักปกติ
            print("[SYSTEM] 📈 Level", playerLevel, "- Running Normal Quest System...")
            _G.HAKI_QUEST_MODE = false
            HAKI_QUEST_CONFIG.ENABLED = false
            break -- ออกจาก loop เพื่อไปทำโค้ดหลัก
        end
    end
end)

-- NORMAL QUEST SYSTEM
task.spawn(function()
    task.wait(15) -- รอให้เช็ค level ก่อน
    
    -- Normal Quest System
    while _G.AUTOFUNCTION do task.wait()
        -- ถ้าอยู่ใน Haki Quest Mode ให้รอ
        if _G.HAKI_QUEST_MODE then
            task.wait(10)
            continue
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char.Humanoid.Health <= 0 then continue end

        local questInfo = getInfoQuest()
        if not questInfo then continue end

        if not player.PlayerGui.QuestUI.Quest.Visible then
            print("not have a quest")
            tweenPos(CFrame.new(questInfo.position))
            questRemote:FireServer(questInfo.npcName)
        elseif player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then
            print("quest not ok")
            abandonRemote:FireServer("repeatable")
        else
            -- Teleport to quest area first
            print("[FARM] Teleporting to quest area...")
            tweenPos(CFrame.new(questInfo.position))
            task.wait(4) -- Wait for NPCs to load
            
            -- เลือกอาวุธ: เช็คก่อนว่า Dark Blade Equip อยู่แล้วหรือยัง
            local toolName = "Combat"
            local RS = game:GetService("ReplicatedStorage")
            
            print("[FARM] === Checking weapon ===")
            
            -- เช็คว่า Dark Blade อยู่ใน Character/Backpack แล้วหรือยัง
            local darkBladeInHand = false
            for _, container in pairs({player.Character, player.Backpack}) do
                if container then
                    for _, tool in pairs(container:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.ToolTip == "Black Blade") then
                            darkBladeInHand = true
                            toolName = "Dark Blade"
                            print("[FARM] ✅ Dark Blade already in", container.Name)
                            break
                        end
                    end
                end
                if darkBladeInHand then break end
            end
            
            -- ถ้ายังไม่มีใน Backpack/Character → ลองเรียก EquipWeapon ดึงจาก Inventory
            if not darkBladeInHand then
                print("[FARM] No Dark Blade in hand, trying EquipWeapon...")
                pcall(function()
                    RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer(unpack({"Equip", "Dark Blade"}))
                end)
                task.wait(2)
                
                -- เช็คอีกรอบ
                for _, container in pairs({player.Character, player.Backpack}) do
                    if container then
                        for _, tool in pairs(container:GetChildren()) do
                            if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.ToolTip == "Black Blade") then
                                darkBladeInHand = true
                                toolName = "Dark Blade"
                                print("[FARM] ✅ Dark Blade equipped from Inventory!")
                                break
                            end
                        end
                    end
                    if darkBladeInHand then break end
                end
            end
            
            if not darkBladeInHand then
                toolName = getBestWeapon()
                print("[FARM] No Dark Blade, using:", toolName)
            end
            
            local npcType = getnpcQuest(questInfo.npcName)
            print("[FARM] Looking for NPC type:", npcType)
            local closest = nil

            for _, v in pairs(workspace.NPCs:GetChildren()) do
                if v:IsA("Model") 
                    and v:FindFirstChild("HumanoidRootPart")
                    and v:FindFirstChild("Humanoid")
                    and v.Humanoid.Health > 0 then
                    
                    local subName = v.Humanoid.DisplayName:gsub("%s+", ""):gsub("%[Lv%.%s*%d+%]", "")
                    
                    -- Exact match (ตรงทุกตัวอักษร)
                    local exactMatch = npcType == tostring(subName) or v.Name == npcType
                    -- Fuzzy match (มีบางส่วนตรงกัน)
                    local fuzzyMatch = subName:find(npcType, 1, true) or v.Name:find(npcType, 1, true)
                    
                    if exactMatch then
                        closest = v
                        print("[FARM] Exact match:", v.Name)
                        break -- เจอตรงๆ หยุดเลย
                    elseif fuzzyMatch then
                        closest = v -- เก็บไว้ก่อน แต่หาต่อ
                        print("[FARM] Fuzzy match:", v.Name)
                    end
                end
            end
        
            if not closest then
                print("[FARM] ❌ NPC not found:", npcType, "- Waiting...")
                task.wait(2)
                continue
            end

            print("Found target NPC:", closest.Name)

            -- freeze
            closest.Humanoid.WalkSpeed = 0
            closest.Humanoid.JumpPower = 0
            closest.HumanoidRootPart.Anchored = true

            local Box = Instance.new("SelectionBox")
            
            Box.Adornee = closest
            Box.Color3 = Color3.fromRGB(0, 255, 0)
            Box.LineThickness = 0.08
            Box.SurfaceTransparency = 0.6
            Box.SurfaceColor3 = Color3.fromRGB(0, 255, 0)
            Box.Parent = workspace
            
            -- Equip weapon
            local tool = nil
            if toolName == "Dark Blade" then
                -- หา Dark Blade ด้วย pattern matching
                for _, container in pairs({player.Backpack, char}) do
                    if container then
                        for _, t in pairs(container:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:find("Dark Blade") or t.ToolTip == "Black Blade") then
                                tool = t
                                break
                            end
                        end
                    end
                    if tool then break end
                end
            else
                -- อาวุธอื่นๆ ใช้ FindFirstChild ปกติ
                tool = player.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
            end
            
            if tool then
                print("[FARM] Equipping:", tool.Name)
                char.Humanoid:EquipTool(tool)
            else
                print("[FARM] ⚠️ Tool not found:", toolName)
            end

            repeat task.wait()
        
                if not closest 
                    or not closest.Parent 
                    or not closest:FindFirstChild("HumanoidRootPart") 
                    or closest.Humanoid.Health <= 0 then
                    break
                end

                tweenPos(CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, 0, 5)))
                
                -- Use all skills and haki
                pcall(function()
                    -- Toggle Haki
                    ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote"):FireServer("Toggle")
                end)
                
                pcall(function()
                    -- Toggle Observation Haki
                    ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ObservationHakiRemote"):FireServer("Toggle")
                end)
                
                -- Use all ability slots (1-4)
                for i = 1, 4 do
                    pcall(function()
                        ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"):FireServer(i)
                    end)
                end
                
                -- Normal attack
                pcall(function()
                    hitRemote:FireServer()
                end)
                
                task.wait(0.1) -- Small delay between attack cycles

            until char.Humanoid.Health <= 0 or not player.PlayerGui.QuestUI.Quest.Visible

            Box:Destroy()
            print("Exit Loop:", closest.Name)
        end
    end
end)
--]]


player.OnTeleport:Connect(function(State)
if State == Enum.TeleportState.Failed then
	task.wait(1.5)
	rejoin()
end
end)
-- ======================
game:GetService("Players").PlayerRemoving:Connect(function()
    pcall(function()
        game:HttpGet("https://node-api--0890939481gg.replit.app/leave")
    end)
end)
