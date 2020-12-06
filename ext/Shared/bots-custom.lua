local Bots = require('__shared/utils/bots')

local function spawnBot(p_name, p_kit, p_pos)
	local s_player = PlayerManager:GetPlayerByName(p_name)
	local s_bot = nil

	if s_player ~= nil then
		if not Bots:isBot(s_player) then
			return
		end

		s_bot = s_player

		s_bot.teamId = TeamId.Team2
		s_bot.squadId = SquadId.SquadNone
	else
		s_bot = Bots:createBot(p_name, SquadId.SquadNone, TeamId.Team2)
	end

	local s_transform = LinearTransform()
	s_transform.trans = p_pos

	local s_soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))

	return Bots:spawnBot(s_bot, s_transform, CharacterPoseType.CharacterPoseType_Stand, s_soldierBlueprint, p_kit, {})
end

Events:Subscribe('Bot:Update', function(p_bot, p_time)
    p_bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)

	local s_shouldShot = MathUtils:GetRandomInt(0, 1000)

	if s_shouldShot <= 100 then
		p_bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1.0)
	end

	p_bot.input.flags = EntryInputFlags.AuthoritativeAiming
	p_bot.input.authoritativeAimingPitch = -0.3
	p_bot.input.authoritativeAimingYaw = 1.5
end)

return { spawnBot = spawnBot }