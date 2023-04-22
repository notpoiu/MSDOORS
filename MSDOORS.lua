print("MSDOORS: Loading...")
game:GetService("GuiService").ErrorMessageChanged:Connect(function(a)
	if(a:match("LDR")or a:match("LPH"))and a:match("Invalid HWID")then 
		game.Players.LocalPlayer:Kick("MSDOORS: Your executor is not supported. Join the discord server (.gg/eeHV6Tsfwd)!")
	end 
end)
loadstring(game:HttpGet('https://scripts.luawl.com/hosted/5055/19135/MSDOORS.lua'))()
