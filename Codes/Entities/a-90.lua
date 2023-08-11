return function(_, CanEntityKill)
  if CanEntityKill == true then
		local damage = false
		local started = os.time()
		if getgenv().log == nil then getgenv().log=game:GetService("LogService").MessageOut:Connect(function(msg,type) if msg == "KEPT MOVING" then damage = true end end)end
		require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules["A90"])(require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game))
		repeat task.wait() until damage or (os.time() - started) > 2
		if damage then 
			game:GetService("ReplicatedStorage").GameStats["Player_" .. game.Players.LocalPlayer.Name].Total.DeathCause.Value = "A-90"
		   	pcall(function() firesignal(game.ReplicatedStorage.EntityInfo.DeathHint.OnClientEvent,{"You died to A-90"}, "Yellow") end)
			game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").Health -= 90
		end
		getgenv().log:Disconnect()
		getgenv().log = nil
  else
		require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules["A90"])(require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game))
  end
end
