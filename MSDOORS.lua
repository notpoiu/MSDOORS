local s,e = pcall(function()
    local isMobile = false
    local mobiletoggles,mobiletoggleerr=pcall(function()
        local platform = UserInputService:GetPlatform()
        isMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
    end)
  
    if isMobile == true then
        print("MSDOORS: Loading mobile version...")
        loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/Moonsec.lua"),true))()
    else
        print("MSDOORS: Loading PC version...")
        loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
    end
end)

if e then
    print("MSDOORS: Failed to check executor loading main...")
    print(e)
    loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
end
