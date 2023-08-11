return function(_, canKill) 
    require(game:GetService("ReplicatedStorage").ClientModules.EntityModules.Void).stuff(require(game.Players.LocalPlayer.PlayerGui:WaitForChild("MainUI").Initiator.Main_Game))
    if canKill == true then
        task.wait(1)
        game.Players.LocalPlayer.Character.Humanoid.Health -= 30
    end
end
