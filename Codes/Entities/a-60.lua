return function(_, CanEntityKill)
 local Creator = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/Codes/Entities/Doors_Entity_Spawner.lua"))()
 
-- Create entity
local entity = Creator.createEntity({
    CustomName = "A-60", -- Custom name of your entity
    Model = "https://github.com/plamen6789/CustomDoorsMonsters/blob/main/A-60.rbxm?raw=true", -- Can be GitHub file or rbxassetid
    Speed = 300, -- Percentage, 100 = default Rush speed
    DelayTime = 4, -- Time before starting cycles (seconds)
    HeightOffset = 0,
    CanKill = CanEntityKill or false,
    BreakLights = false,
    FlickerLights = {
        false, -- Enabled
        2, -- Time (seconds)
    },
    Cycles = {
        Min = 1,
        Max = 1,
        WaitTime = 5,
    },
    CamShake = {
        true, -- Enabled
        {5, 50, 0.1, 1}, -- Shake values (don't change if you don't know)
        100, -- Shake start distance (from Entity to you)
    },
    Jumpscare = {
        false, -- Enabled ('false' if you don't want jumpscare)
        {
            Image1 = "rbxassetid://11372489796", -- Image1 url
            Image2 = "rbxassetid://11372489796", -- Image2 url
            Shake = true,
            Sound1 = {
                0, -- SoundId
                { Volume = 0.5 }, -- Sound properties
            },
            Sound2 = {
                0, -- SoundId
                { Volume = 0.5 }, -- Sound properties
            },
            Flashing = {
                true, -- Enabled
                Color3.fromRGB(255, 0, 0), -- Color
            },
            Tease = {
                true, -- Enabled ('false' if you don't want tease)
                Min = 1,
                Max = 3,
            },
        },
    },
    CustomDialog = {"You died to A-60...", "The lights will not flicker, but be careful.", "If you hear it, hide!"}, -- Custom death message (can be as long as you want)
})
Creator.runEntity(entity)
end
