local createBasePartCopy = loadstring(game:HttpGet("https://github.com/mstudio45/MSDOORS/blob/main/Codes/ObjectHighlighter/createBasePartCopy.lua?raw=true"))()

return function(instance)
	if instance:IsA("BasePart") then
		return createBasePartCopy(instance)
	elseif instance:IsA("Humanoid") then
		local humanoid = Instance.new("Humanoid")
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		return humanoid
	elseif instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("CharacterMesh") then
		return instance:Clone()
	end
end
