local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
function warnmessage(a,b,c)task.spawn(function()local d=Instance.new("Sound")d.Parent=game.SoundService;d.SoundId="rbxassetid://4590657391"d.Volume=5;d:Play()d.Stopped:Wait()d:Destroy()end)Notification:Notify({Title=a,Description=b},{OutlineColor=Color3.fromRGB(80,80,80),Time=c or 5,Type="image"},{Image="http://www.roblox.com/asset/?id=6023426923",ImageColor=Color3.fromRGB(255,84,84)})end
warnmessage("MSHUB", "You are using an outdated loadstring. Join our discord to get the new one that doesn't change! (discord.gg/J8P563m8aX).", 10)
local Inviter=loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Discord%20Inviter/Source.lua"))();Inviter.Prompt({name = "MSHUB",invite = "discord.gg/J8P563m8aX",})
