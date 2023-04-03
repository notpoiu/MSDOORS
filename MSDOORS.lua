local s,e = pcall(function()
 --   local function getexploit()
  --      return (identifyexecutor and table.concat({ identifyexecutor() }, " ")) or ("Unknown")
--    end
    local isMobile = false
    local mobiletoggles,mobiletoggleerr=pcall(function()
        local platform = UserInputService:GetPlatform()
        isMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
    end)
    ---local exploit = getexploit()
   -- if exploit == "Fluxus Android" then 
    if isMobile == true then
        loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/Moonsec.lua"),true))()
    else
        loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
    end
end)

if e then
    print("MSDOORS: Failed to check executor loading main...")
    print(e)
    loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
end
