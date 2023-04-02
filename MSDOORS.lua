local s,e = pcall(function()
    local function getexploit()
        return (identifyexecutor and table.concat({ identifyexecutor() }, " ")) or ("Unknown")
    end
    local isMobile = false
    local mobiletoggles,mobiletoggleerr=pcall(function()
        local platform = UserInputService:GetPlatform()
        isMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
    end)
    local exploit = getexploit()
    if exploit == "Fluxus" and isMobile == true then 
        loadstring(game:HttpGet(("https://github.com/mstudio45/MSDOORS/blob/main/MSDOORS/Moonsec.lua?raw=true"),true))()
    else
        loadstring(game:HttpGet(("https://github.com/mstudio45/MSDOORS/blob/main/MSDOORS/MSDOORS.lua?raw=true"),true))()
    end
end)
if e then
    print("MSDOORS: Failed to check executor loading main...")
    loadstring(game:HttpGet(("https://github.com/mstudio45/MSDOORS/blob/main/MSDOORS/MSDOORS.lua?raw=true"),true))()
end
