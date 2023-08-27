local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
function message(text)
	task.spawn(function()
		local notif = Instance.new("Sound");notif.Parent = game.SoundService;notif.SoundId = "rbxassetid://4590657391";notif.Volume = 3;notif:Play();notif.Stopped:Wait();notif:Destroy()
	end)

	task.spawn(function()
		local msg = Instance.new("Message",workspace)
		msg.Text = tostring(text)
		task.wait(5)
		msg:Destroy()
	end)
end

function normalmessage(title, text, timee)
	task.spawn(function()
		local notif = Instance.new("Sound");notif.Parent = game.SoundService;notif.SoundId = "rbxassetid://4590657391";notif.Volume = 3;notif:Play();notif.Stopped:Wait();notif:Destroy()
	end)

	Notification:Notify(
		{Title = title, Description = text},
		{OutlineColor = Color3.fromRGB(80, 80, 80),Time = timee or 5, Type = "default"}
	)
end

function confirmnotification(title, text, timee, callback)
	task.spawn(function()
		local notif = Instance.new("Sound");notif.Parent = game.SoundService;notif.SoundId = "rbxassetid://4590657391";notif.Volume = 3;notif:Play();notif.Stopped:Wait();notif:Destroy()
	end)

	Notification:Notify(
		{Title = title, Description = text},
		{OutlineColor = Color3.fromRGB(80, 80, 80), Time = timee or 10, Type = "option"},
		{Image = "http://www.roblox.com/asset/?id=6023426923", ImageColor = Color3.fromRGB(255, 84, 84), Callback = callback or function(state)end}
	)
end 

function warnmessage(title, text, timee)
	task.spawn(function()
		local notif = Instance.new("Sound");notif.Parent = game.SoundService;notif.SoundId = "rbxassetid://4590657391";notif.Volume = 5;notif:Play();notif.Stopped:Wait();notif:Destroy()
	end)
	Notification:Notify(
		{Title = title, Description = text},
		{OutlineColor = Color3.fromRGB(80, 80, 80),Time = timee or 5, Type = "image"},
		{Image = "http://www.roblox.com/asset/?id=6023426923", ImageColor = Color3.fromRGB(255, 84, 84)}
	)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("EntityInfo"):WaitForChild("CreateElevator"):FireServer({
	["Mods"] = {"SuperHardMode"},
	["FriendsOnly"] = false,
	["MaxPlayers"] = "1"
})
task.wait()
ReplicatedStorage.EntityInfo:WaitForChild("ElevatorStart"):FireServer()
normalmessage("MSHUB", "Joining...", 10)
