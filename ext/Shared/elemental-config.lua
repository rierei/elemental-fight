-- elements names
local names = {
    'water',
    'grass',
    'fire',
    'gold',
    'energy',
}

-- elements colors
local colors = {
    water = Vec3(0, 0.6, 1),
    grass = Vec3(0.2, 0.6, 0.1),
    fire = Vec3(1, 0.3, 0),
    gold = Vec3(0.5, 0.5, 0),
    energy = Vec3(0.4, 0.2, 1)
}

-- impact effects
local effects = {
    water = {'20B18CF1-F2F7-11DF-9BE8-9E0183D704DD', '23298636-5C6F-8CA0-F0EF-6097924181C3'}, -- FX_Impact_Water_S
    grass = {'6C1A14FF-83C9-410E-A7D0-4FD024EBE33A', '06E4F5D2-5883-46A0-B898-2A21E8BFEEDA'}, -- FX_Impact_Foliage_Generic_S_01
    fire = {'29C86406-1ED5-11DE-A58E-D687F51B0F2D', '29C86407-1ED5-11DE-A58E-D687F51B0F2D'}, -- FX_Impact_Metal_01_S
    gold = {'194DFCAE-2059-11DE-A343-9DADD368E3F9', '194DFCAF-2059-11DE-A343-9DADD368E3F9'}, -- FX_Impact_Wood_01_S
    energy = {'8F7973F7-E7F0-11DF-82D1-B3822DF6E38B', 'E54874F1-032A-D424-B337-01C2C6C0AE08'} -- FX_Amb_ElectricSparks_01
}

-- element damage
local damages = {
    neutral = {
        neutral = 1.25,
        water = 0.75,
        fire = 0.75,
        grass = 0.75,
        gold = 0.50,
        energy = 0.50
    },
    water = {
        neutral = 0.75,
        water = 0.75,
        fire = 1.25,
        grass = 0.50,
        gold = 0.50,
        energy = 0.50
    },
    fire = {
        neutral = 0.75,
        water = 0.50,
        fire = 0.75,
        grass = 1.25,
        gold = 0.50,
        energy = 0.50
    },
    grass = {
        neutral = 0.75,
        water = 1.25,
        fire = 0.50,
        grass = 0.75,
        gold = 0.75,
        energy = 0.50
    },
    gold = {
        neutral = 1.25,
        water = 1.25,
        fire = 1.25,
        grass = 1.25,
        gold = 1.25,
        energy = 1.25
    },
    energy = {
        neutral = 1.25,
        water = 1.25,
        fire = 1.25,
        grass = 1.25,
        gold = 1.25,
        energy = 1.25
    }
}

return {
    names = names,
    colors = colors,
    effects = effects,
    damages = damages
}