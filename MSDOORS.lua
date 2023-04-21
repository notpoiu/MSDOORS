--[[local isMobile = false
local mobiletoggles,mobiletoggleerr = pcall(function()
	local platform = game:GetService("UserInputService"):GetPlatform()
	isMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
end)

if mobiletoggleerr then
	warn("MSDOORS: Failed to check executor, report this issue to mstudio45:")	
	warn(mobiletoggleerr)
	loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/Moonsec.lua"),true))()
else
	if isMobile == true then
		print("MSDOORS: Loading mobile version...")
		loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/Moonsec.lua"),true))()
	else
		print("MSDOORS: Loading PC version...")
		loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
	end
end--]]

print("MSDOORS: Loading...")
loadstring(game:HttpGet(("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/MSDOORS/MSDOORS.lua"),true))()
