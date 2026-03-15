repeat task.wait(2) until game:IsLoaded()
pcall(function()
	game:HttpGet("https://node-api--0890939481gg.replit.app/join")
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- ======================
-- Settings (reduce lag)
-- ======================
local SettingsToggle = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle")

local settings = {
	"DisablePvP",
	"DisableVFX",
	"DisableOtherVFX",
	"RemoveTexture",
	"AutoSkillC",
	"RemoveShadows"
}

for _, setting in ipairs(settings) do
	local current = player:FindFirstChild("Settings")
		and player.Settings:FindFirstChild(setting)
	if not current or current.Value ~= true then
		SettingsToggle:FireServer(setting, true)
	end
end

-- ======================
-- Remotes
-- ======================
local hitRemote = ReplicatedStorage.CombatSystem.Remotes.RequestHit
local questRemote = ReplicatedStorage.RemoteEvents.QuestAccept
local abandonRemote = ReplicatedStorage.RemoteEvents.QuestAbandon
local statRemote = ReplicatedStorage.RemoteEvents.AllocateStat

-- ======================
-- Helper Functions
-- ======================
local lastQuest = nil
local BlackScreen = true
local startTime = os.time()

local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	return char, hrp, hum
end

local char, hrp, hum = getChar()

function getInfoQuest()
	local quests = {}
	local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetQuestArrowTarget"):InvokeServer()
	for i, v in pairs(result) do
		quests[i] = v
	end
	return quests
end

function getnpcQuest(npcname)
	local module = require(ReplicatedStorage.Modules.QuestConfig)
	for questNPC, questData in pairs(module.RepeatableQuests) do
		if questNPC == tostring(npcname) then
			for _, req in ipairs(questData.requirements) do
				return req.npcType
			end
		end
	end
	return nil
end

-- ======================
-- BlackScreen (FPS Boost)
-- ======================
local function setBlack(state)
	if state then
		game.Lighting.Brightness = 0
		game.Lighting.GlobalShadows = false
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				v.LocalTransparencyModifier = 1
			end
		end
	else
		for _, v in ipairs(workspace:GetDescendants()) do
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
button.Size = UDim2.new(0, 160, 0, 45)
button.Position = UDim2.new(0, 20, 0.5, -22)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "FpsBoost : ON"
button.Font = Enum.Font.GothamBold
button.TextSize = 16

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Parent = button
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Thickness = 2

button.MouseButton1Click:Connect(function()
	BlackScreen = not BlackScreen
	setBlack(BlackScreen)
	if BlackScreen then
		button.Text = "FpsBoost : ON"
	else
		button.Text = "FpsBoost : OFF"
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	setBlack(BlackScreen)
end)

-- ======================
-- Equip best weapon
-- ======================
task.spawn(function()
	task.wait(3)
	pcall(function()
		local backpack = player:WaitForChild("Backpack", 10)
		if not backpack then return end
		local currentChar = player.Character
		if not currentChar then return end
		local currentHum = currentChar:FindFirstChild("Humanoid")
		if not currentHum then return end

		local bestTool = nil
		local bestLevel = 0

		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool.ToolTip == "Black Blade" then
					bestTool = tool
					break
				end
				local level = tonumber(tool.Name:match("%[Lv%.%s*(%d+)%]")) or 0
				if level > bestLevel then
					bestLevel = level
					bestTool = tool
				elseif not bestTool then
					bestTool = tool
				end
			end
		end

		if bestTool and bestTool.Parent == backpack then
			currentHum:EquipTool(bestTool)
			print("Equipped:", bestTool.Name)
		end
	end)
end)

-- ======================
-- Horst Level Display
-- ======================
task.spawn(function()
	local HttpService = game:GetService("HttpService")
	local data = player:WaitForChild("Data", 10)
	if not data then return end

	local levelValue = data:FindFirstChild("Level")
	local moneyValue = data:FindFirstChild("Money")

	while task.wait(1) do
		local level = levelValue and levelValue.Value or 0
		local money = moneyValue and moneyValue.Value or 0
		local message = " Level " .. level .. " Money " .. money
		local json = { Level = level, Money = money }
		local encoded = HttpService:JSONEncode(json)
		pcall(function()
			_G.Horst_SetDescription(message, encoded)
		end)
	end
end)

-- ======================
-- Rare Items Tracker
-- ======================
local rareItemsList = {}

task.spawn(function()
	local updateInventory = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpdateInventory")
	updateInventory.OnClientEvent:Connect(function(category, items)
		if category == "Items" or category == "Accessories" or category == "Auras" or category == "Cosmetics" then
			local ItemRarityConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemRarityConfig"))
			for _, item in pairs(items) do
				local rarity = ItemRarityConfig:GetRarity(item.name)
				if rarity == "Mythical" or rarity == "Secret" or rarity == "Legendary" then
					local itemName = item.name
					local quantity = item.quantity or 1
					if rareItemsList[itemName] then
						rareItemsList[itemName].quantity = quantity
					else
						rareItemsList[itemName] = { name = itemName, rarity = rarity, quantity = quantity }
						print(string.format("NEW %s: %s x%d", rarity:upper(), itemName, quantity))
					end
				end
			end
		end
	end)
end)

-- Print rare items list (F1 key)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		print("=== RARE ITEMS LIST ===")
		for _, item in pairs(rareItemsList) do
			print(string.format("[%s] %s x%d", item.rarity, item.name, item.quantity))
		end
		print("======================")
	end
end)

-- ======================
-- Auto Hit (rapid fire every frame)
-- ======================
task.spawn(function()
	while task.wait() do
		pcall(function()
			hitRemote:FireServer()
		end)
	end
end)

-- ======================
-- Auto Dodge (press Z when NPC nearby)
-- ======================
task.spawn(function()
	while task.wait(0.4) do
		pcall(function()
			local currentChar = player.Character
			if not currentChar then return end
			local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
			if not currentHrp then return end

			local nearestNPC
			local distance = math.huge

			for _, npc in ipairs(workspace.NPCs:GetChildren()) do
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

			if nearestNPC and distance <= 12 then
				vim:SendKeyEvent(true, "Z", false, game)
				task.wait(0.1)
				vim:SendKeyEvent(false, "Z", false, game)
			end
		end)
	end
end)

-- ======================
-- Auto Stat
-- ======================
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			statRemote:FireServer("Melee", 2)
			statRemote:FireServer("Defense", 1)
		end)
	end
end)

-- ======================
-- Anti-AFK
-- ======================
task.spawn(function()
	while task.wait(60) do
		pcall(function()
			ReplicatedStorage.Remotes.AntiAFKHeartbeat:FireServer()
		end)
	end
end)

-- ======================
-- Auto Haki
-- ======================
task.spawn(function()
	while task.wait(5) do
		pcall(function()
			ReplicatedStorage.Remotes.ConquerorHakiRemote:FireServer()
		end)
		pcall(function()
			ReplicatedStorage.RemoteEvents.ObservationHakiRemote:FireServer()
		end)
	end
end)

-- ======================
-- Auto Sprint
-- ======================
task.spawn(function()
	task.wait(3)
	pcall(function()
		ReplicatedStorage.RemoteEvents.SprintToggle:FireServer(true)
	end)
end)

-- ======================
-- farmNPC (like reference script)
-- ======================
local function farmNPC(npcType)
	while task.wait(0.1) do
		if hum.Health <= 0 then break end

		local found = false

		for _, npc in pairs(workspace.NPCs:GetChildren()) do
			if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				local subName = npc.Humanoid.DisplayName:gsub("%s+", ""):gsub("%[Lv%.%s*%d+%]", "")

				if npcType == tostring(subName) or npc.Name == npcType then
					found = true

					local target = npc:FindFirstChild("HumanoidRootPart")
						or npc:FindFirstChild("Torso")
						or npc:FindFirstChild("UpperTorso")

					if target then
						hrp.CFrame = target.CFrame * CFrame.new(0, 0, 7)
					end
				end
			end
		end

		if not found then
			break
		end
	end
end

-- ======================
-- farmBoss (like reference script)
-- ======================
local function farmBoss(npcType)
	for _, npc in pairs(workspace.NPCs:GetChildren()) do
		if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
			local subName = npc.Humanoid.DisplayName:gsub("%s+", ""):gsub("%[Lv%.%s*%d+%]", "")

			if npcType == tostring(subName) or npc.Name == npcType then
				local target = npc:FindFirstChild("HumanoidRootPart")
					or npc:FindFirstChild("Torso")
					or npc:FindFirstChild("UpperTorso")

				if target then
					print("Farming Boss:", npc.Name)
					while npc.Parent and npc.Humanoid.Health > 0 do
						if hum.Health <= 0 then break end
						hrp.CFrame = target.CFrame * CFrame.new(0, 0, 7)
						task.wait(0.1)
					end
					print("Boss defeated:", npc.Name)
				end
				return
			end
		end
	end
	print("Boss not found - waiting for respawn")
	task.wait(5)
end

-- ======================
-- Main Quest Loop (uses dynamic quest system from Sailor piece.lua)
-- ======================
while task.wait(0.3) do

	if hum.Health <= 0 or not char.Parent then
		char, hrp, hum = getChar()
	end

	-- Equip best weapon
	pcall(function()
		local bestTool = nil
		local bestLevel = -1

		for _, container in pairs({player.Backpack, char}) do
			if container then
				for _, tool in pairs(container:GetChildren()) do
					if tool:IsA("Tool") then
						-- Priority 1: Black Blade (best weapon)
						if tool.ToolTip == "Black Blade" or tool.Name == "Black Blade" then
							bestTool = tool
							bestLevel = 99999
							break
						end

						-- Priority 2: highest level weapon
						local lvl = tonumber(tool.Name:match("%[Lv%.%s*(%d+)%]"))
							or tonumber(tool.ToolTip:match("%[Lv%.%s*(%d+)%]"))
							or tonumber(tool.Name:match("Lv%.?%s*(%d+)"))
							or 0

						if tool.Name ~= "Combat" and lvl > bestLevel then
							bestLevel = lvl
							bestTool = tool
						end
					end
				end
			end
			if bestLevel >= 99999 then break end
		end

		-- Fallback to Combat if no better weapon
		if not bestTool then
			bestTool = player.Backpack:FindFirstChild("Combat") or char:FindFirstChild("Combat")
		end

		if bestTool and bestTool.Parent ~= char then
			hum:EquipTool(bestTool)
			print("Equipped:", bestTool.Name, "| Tip:", bestTool.ToolTip)
		end
	end)

	-- Dynamic quest system
	local questInfo = nil
	pcall(function()
		questInfo = getInfoQuest()
	end)

	if not questInfo then
		task.wait(1)
		continue
	end

	-- Check if we have a quest
	if not player.PlayerGui.QuestUI.Quest.Visible then
		print("not have a quest")
		pcall(function()
			hrp.CFrame = CFrame.new(questInfo.position)
		end)
		questRemote:FireServer(questInfo.npcName)
		task.wait(0.5)

	-- Check if wrong quest
	elseif player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then
		print("quest not ok")
		abandonRemote:FireServer("repeatable")
		task.wait(0.5)

	-- Quest is correct, farm NPCs
	else
		-- TP to quest area if far
		if (hrp.Position - questInfo.position).Magnitude >= 50 then
			print("TP to quest...")
			hrp.CFrame = CFrame.new(questInfo.position)
			task.wait(0.5)
		end

		-- Get NPC type from quest
		local npcType = getnpcQuest(questInfo.npcName)
		if npcType then
			print("Farming:", npcType)
			farmNPC(npcType)
		end
	end

	task.wait(0.5)
end

-- ======================
-- On Leave
-- ======================
game:GetService("Players").PlayerRemoving:Connect(function()
	pcall(function()
		game:HttpGet("https://node-api--0890939481gg.replit.app/leave")
	end)
end)
