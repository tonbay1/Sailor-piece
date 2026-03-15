repeat task.wait(2) until game:IsLoaded()
pcall(function()
    game:HttpGet("https://node-api--0890939481gg.replit.app/join")
end)

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local vim = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer

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

-- รอ Data
local data = player:WaitForChild("Data",10)
if not data then return end

-- Wait for inventory data to load first
task.wait(5)
print("[HORST] Starting Horst Display with inventory tracking...")

while task.wait(1) do

	-- Get current values directly
	local level = (data:FindFirstChild("Level") and data.Level.Value) or 0
	local money = (data:FindFirstChild("Money") and data.Money.Value) or 0
	local gems = (data:FindFirstChild("Gems") and data.Gems.Value) or 0
	
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
	
	local message = "LVL "..level.." M "..moneyStr.." G "..gemsStr
	
	-- Priority items (red border items from image)
	local priorityItems = {}
	local regularItems = {}
	
	-- Check crates - Mythical Chest is priority
	for _, crateInfo in pairs(cratesList) do
		local crateName = crateInfo:lower()
		if crateName:find("mythical chest") then
			table.insert(priorityItems, crateInfo)
		elseif crateName:find("legendary chest") then
			table.insert(regularItems, crateInfo)
		end
	end
	
	-- Check items by priority (red border items first)
	for rarity, items in pairs(itemLists) do
		for _, itemInfo in pairs(items) do
			local itemName = itemInfo:lower()
			
			-- Priority items (red border in image): Adamantite, Conqueror Fragment, Diamond, Mythical Chest
			if itemName:find("adamantite") or itemName:find("conqueror fragment") or itemName:find("diamond") then
				table.insert(priorityItems, itemInfo)
			-- Keep full names for Aura and Clan Reroll
			elseif itemName:find("aura") or itemName:find("clan reroll") then
				table.insert(regularItems, itemInfo)
			-- Other important items
			elseif itemName:find("race reroll") or itemName:find("trait reroll") or 
				   itemName:find("rush key") or itemName:find("mythril") or itemName:find("fragment") then
				table.insert(regularItems, itemInfo)
			end
		end
	end
	
	-- Combine priority and regular items
	local allImportantItems = {}
	for _, item in pairs(priorityItems) do
		table.insert(allImportantItems, item)
	end
	for _, item in pairs(regularItems) do
		table.insert(allImportantItems, item)
	end
	
	-- Show important items with proper formatting
	if #allImportantItems > 0 then
		-- Limit to max 4 items for better display
		local displayItems = {}
		local maxItems = 4
		
		for i = 1, math.min(maxItems, #allImportantItems) do
			local item = allImportantItems[i]
			-- Keep full names for Aura and Clan Reroll as requested
			-- Only shorten other items
			if not item:lower():find("aura") and not item:lower():find("clan reroll") then
				item = item:gsub("Legendary Chest", "L.Chest")
				item = item:gsub("Race Reroll", "RaceR")
				item = item:gsub("Trait Reroll", "TraitR")
				item = item:gsub("Rush Key", "RushK")
				item = item:gsub("Worthiness Fragment", "WorthF")
			end
			table.insert(displayItems, item)
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


-- auto stat
task.spawn(function()
while task.wait(1) do
	pcall(function()
	statRemote:FireServer("Melee",2)
	statRemote:FireServer("Defense",1)
end)
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

local function farmNPC(name)

	while task.wait(0.2) do

		if hum.Health <= 0 then break end

		local found = false

		for i = 1,5 do
			local npc = workspace.NPCs:FindFirstChild(name..i)

			if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				found = true

				local target =
				npc:FindFirstChild("HumanoidRootPart")
				or npc:FindFirstChild("Torso")
				or npc:FindFirstChild("UpperTorso")

				if target then
					hrp.CFrame = target.CFrame * CFrame.new(0,0,7)
					task.wait(0.7)
				end
			end
		end

		if not found then
			break
		end

	end

end


local function acceptQuest(questName, mapName)
	if mapName then
		tpRemote:FireServer(mapName)
		task.wait(1)
	end
	if lastQuest ~= questName then
		pcall(function()
			abandonRemote:FireServer("repeatable")
		end)
		task.wait(0.5)
		questRemote:FireServer(questName)
		lastQuest = questName
	end
	questRemote:FireServer(questName)
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
				if hum.Health <= 0 then break end

				hrp.CFrame = target.CFrame * CFrame.new(0,0,7)

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

while task.wait(0.3) do

	if hum.Health <=0 or not char.Parent then
		char,hrp,hum = getChar()
	end

	local tool = player.Backpack:FindFirstChild("Combat") or char:FindFirstChild("Combat")

	if tool then
		if tool.Parent ~= char then
			hum:EquipTool(tool)
		end
	end

	local level = player.Data.Level.Value

	-- 0-250
	if level <=250 then
		acceptQuest("QuestNPC1")
		farmNPC("Thief")

		-- 250-500
	elseif level <=500 then

		acceptQuest("QuestNPC3", "Jungle")
		farmNPC("Monkey")

		-- 500-750
	elseif level <=750 then

		acceptQuest("QuestNPC4", "Jungle")
		farmBoss("MonkeyBoss")

		-- 750-1000
	elseif level <=1000 then

		acceptQuest("QuestNPC5", "Desert")
		farmNPC("DesertBandit")

		-- 1000-1500
	elseif level <=1500 then

		acceptQuest("QuestNPC6", "Desert")
		farmBoss("DesertBoss")

		-- 1500-2000
	elseif level <=2000 then

		acceptQuest("QuestNPC7", "Snow")
		farmNPC("FrostRogue")

		-- 2000-3000
	elseif level <=3000 then

		acceptQuest("QuestNPC8", "Snow")
		farmBoss("SnowBoss")

		-- 3000-4000
	elseif level <=4000 then

		acceptQuest("QuestNPC9", "Shibuya")
		farmNPC("Sorcerer")

		-- 4000-5000
	elseif level <=5000 then

		acceptQuest("QuestNPC10", "Shibuya")
		farmBoss("PandaMiniBoss")

		-- 5000-6251
	elseif level <=6251 then

		acceptQuest("QuestNPC11", "HuecoMundo")
		farmNPC("Hollow")

		-- 6251-7001
	elseif level <=7001 then

		acceptQuest("QuestNPC12", "Shinjuku")
		farmNPC("StrongSorcerer")

		-- 7001-8001
	elseif level <=8001 then

		acceptQuest("QuestNPC13", "Shinjuku")
		farmNPC("Curse")

		-- 8001-9001
	elseif level <=9001 then

		acceptQuest("QuestNPC14", "Slime")
		farmNPC("Slime")

		-- 9001-10001
	elseif level <=10001 then

		acceptQuest("QuestNPC15", "Academy")
		farmNPC("AcademyTeacher")

		-- 10001-10751
	elseif level <=10751 then

		acceptQuest("QuestNPC16", "Judgement")
		farmNPC("Swordsman")

	end

	task.wait(0.5)

end


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
