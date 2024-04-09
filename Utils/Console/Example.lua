local console = loadstring(game:HttpGet("https://raw.githubusercontent.com/notpoiu/MSDOORS/main/Utils/Console/Utility.lua"))()

-- Regular Print Example
-- args: message, image, color
local message = console.custom_print("[MSHUB]: Example script 😎")
local message = console.custom_print("[MSHUB]: Example script 😎", "", Color3.fromRGB(255, 0, 255))

-- Progressbar Example
local message = console.custom_console_progressbar("[MSHUB]: Authenticating...")
--[[
local message = create_progressbar({
    msg = "[MSHUB]: Authenticating...",
    img = "",
    clr = Color3.fromRGB(255, 255, 255),
    length = 10 -- progressbar steps
})]]

for i = 1, 10 do
    message.update_progress(i)
    task.wait(.05)
end

message.update_message("[MSHUB]: Authenticated!", "rbxasset://textures/AudioDiscovery/done.png", Color3.fromRGB(51, 255, 85))
