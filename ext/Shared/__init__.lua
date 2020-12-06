local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}

    self.m_weaponUnlocks = WeaponUnlocks()
    self.m_soldierAppearances = SoldierAppearances()

    self.counter = 1
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(p_player, p_mask, p_message)
        print('Event Player:Chat')

        local s_element = self.m_elementNames[self.counter]

        local s_assaultUSKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))

        local s_soldier1 = BotsCustom.spawnBot('Bot1', s_assaultUSKit, Vec3(-306.493164, 70.434372, 270.194336))
        local s_soldier2 = BotsCustom.spawnBot('Bot2', s_assaultUSKit, Vec3(-306.493164, 70.434372, 272.194336))
        local s_soldier3 = BotsCustom.spawnBot('Bot3', s_assaultUSKit, Vec3(-306.493164, 70.434372, 274.194336))
        local s_soldier4 = BotsCustom.spawnBot('Bot4', s_assaultUSKit, Vec3(-306.493164, 70.434372, 276.194336))

        self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier1.player, s_element, 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4') -- assaultAppearance
        self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier1.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier2.player, s_element, 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7') -- engiAppearance
        self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier2.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier3.player, s_element, '4BE86DA1-0229-448D-A5E2-934E5490E11C') -- reconAppearance
        self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier3.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier4.player, s_element, '23CFF61F-F1E2-4306-AECE-2819E35484D2') -- supportAppearance
        self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier4.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
    end)

    Events:Subscribe('Player:Respawn', function(p_player)
        print('Event Player:Respawn')

        if p_player.SelectWeapon == nil then
            return
        end

        local s_element = self.m_elementNames[self.counter]
        print(s_element)

        self.m_weaponUnlocks:ReplacePlayerWeapons(p_player, s_element)
        self.m_soldierAppearances:ReplacePlayerAppearance(p_player, s_element, 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4')

        self.counter = self.counter % #self.m_elementNames + 1
    end)
end

g_elementalFight = ElementalFight()