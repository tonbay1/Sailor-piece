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
	
	local message = "⭐LVL "..level.." 💰"..moneyStr.." 💎"..gemsStr
	print("[DEBUG] New message format:", message)
	
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

-- Use the working auto quest/farm system from example code
_G.AUTOFUNCTION = true
task.spawn(function()
    while _G.AUTOFUNCTION do task.wait()
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
            
            if (char.HumanoidRootPart.Position - questInfo.position).Magnitude >= 50 and player.PlayerGui.QuestUI.Quest.Visible then
                print("TP to quest...")
                tweenPos(CFrame.new(questInfo.position))
            end
            
            -- Get best weapon automatically (highest level, not Combat)
            local toolName = getBestWeapon()
            local npcType = getnpcQuest(questInfo.npcName)
            local closest = nil

            for _, v in pairs(workspace.NPCs:GetChildren()) do
                if v:IsA("Model") 
                    and v:FindFirstChild("HumanoidRootPart")
                    and v:FindFirstChild("Humanoid")
                    and v.Humanoid.Health > 0 then
                    local subName = v.Humanoid.DisplayName:gsub("%s+", ""):gsub("%[Lv%.%s*%d+%]", "")

                    if npcType == tostring(subName) or v.Name == npcType then
                        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            closest = v
                        end
                    end
                end
            end
        
            if not closest then
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
            local tool = player.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
            if tool then
                char.Humanoid:EquipTool(tool)
            end

            repeat task.wait()
        
                if not closest 
                    or not closest.Parent 
                    or not closest:FindFirstChild("HumanoidRootPart") 
                    or closest.Humanoid.Health <= 0 then
                    break
                end

                tweenPos(CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, 0, 5)))
                
                -- Attack
                pcall(function()
                    hitRemote:FireServer()
                end)

            until char.Humanoid.Health <= 0 or not player.PlayerGui.QuestUI.Quest.Visible

            Box:Destroy()
            print("Exit Loop:", closest.Name)
        end
    end
end)


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
