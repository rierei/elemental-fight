local Bots = require('__shared/utils/bots')

local function spawnCustom(player, name, teamId, squadId, trans, unlocks, weapon)
	local existingPlayer = PlayerManager:GetPlayerByName(name)
	local bot = nil

	if existingPlayer ~= nil then
		-- If a player with this name exists and it's not a bot then error out.
		if not Bots:isBot(existingPlayer) then
			return
		end

		-- If it is a bot, then store it and we'll call the spawn function for it after.
		-- This will respawn the bot (killing it if it's already alive).
		bot = existingPlayer

		-- We should also update its team and squad, just in case.
		bot.teamId = teamId
		bot.squadId = squadId
	else
		-- Otherwise, create a new bot. This returns a new Player object.
		bot = Bots:createBot(name, teamId, squadId)
	end

    -- Get the default MpSoldier blueprint and the US assault kit.
	local soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
	local soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))

	-- Create the transform of where to spawn the bot at.
	local transform = LinearTransform()
	transform.trans = trans

	-- And then spawn the bot. This will create and return a new SoldierEntity object.
	local soldier = Bots:spawnBot(bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, unlocks)

	local hiderCustomization = CustomizeSoldierData()
	hiderCustomization.activeSlot = WeaponSlot.WeaponSlot_0
	hiderCustomization.removeAllExistingWeapons = true
	hiderCustomization.overrideCriticalHealthThreshold = 1.0

	local primaryWeapon = UnlockWeaponAndSlot()
	primaryWeapon.weapon = SoldierWeaponUnlockAsset(weapon)
	primaryWeapon.slot = WeaponSlot.WeaponSlot_0

	hiderCustomization.weapons:add(primaryWeapon)

	soldier:ApplyCustomization(hiderCustomization)
end

local function spawn()
    local assaultAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Assault_Appearance01')
	local engiAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Engi_Appearance01')
	local reconAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Recon_Appearance01')
	local supportAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Support_Appearance01')

	local weapon = ResourceManager:SearchForInstanceByGuid(Guid('0D6330BA-D9C4-4644-C605-0351694D1ADC'))

    spawnCustom('Bots:Spawn', 'Bot1', TeamId.Team2, SquadId.SquadNone, Vec3(-306.493164, 70.434372, 270.194336), assaultAppearance, weapon)
    spawnCustom('Bots:Spawn', 'Bot2', TeamId.Team2, SquadId.SquadNone, Vec3(-306.493164, 70.434372, 272.194336), engiAppearance, weapon)
    spawnCustom('Bots:Spawn', 'Bot3', TeamId.Team2, SquadId.SquadNone, Vec3(-306.493164, 70.434372, 274.194336), supportAppearance, weapon )
    spawnCustom('Bots:Spawn', 'Bot4', TeamId.Team2, SquadId.SquadNone, Vec3(-306.493164, 70.434372, 276.194336), reconAppearance, weapon)
end

Events:Subscribe('Bot:Update', function(bot, dt)
	-- Make the bots move forward.
    bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)

	-- Have bots jump with a 1.5% chance per frame.
	local shouldJump = MathUtils:GetRandomInt(0, 1000)

	if shouldJump <= 100 then
		bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1.0)
	end

	bot.input.flags = EntryInputFlags.AuthoritativeAiming
	bot.input.authoritativeAimingPitch = -0.3
	bot.input.authoritativeAimingYaw = 1.5
end)

return { spawn = spawn }