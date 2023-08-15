-- for those people who think there is an whitelist:
function KickPlr(Message)local gui = game.CoreGui.RobloxPromptGui.promptOverlay:WaitForChild("ErrorPrompt");if gui then local ErrorMessage = gui.MessageArea.ErrorFrame.ErrorMessage;ErrorMessage.Text = Message;gui.Size = UDim2.new(0, gui.Size.X.Offset, 0, 50 + game:GetService("TextService"):GetTextSize(ErrorMessage.Text, ErrorMessage.TextSize, ErrorMessage.Font, (Vector2.new(gui.Size.X.Offset - 2 * 20, 1000))).Y + 1 + 36 + 20 + 2 * 20 + 1);end end
game:GetService("GuiService").ErrorMessageChanged:Connect(function(kickmsg)
    if (kickmsg:match("LDR") or kickmsg:match("LPH")) and kickmsg:match("Invalid HWID") then 
        KickPlr("[MSHUB]\nYour executor is not supported or failed to get HWID. Join the discord server (.gg/J8P563m8aX, .gg/mshub)!\n\n[error: Invalid HWID.]")
    elseif kickmsg:match("Whitelist Error:") then 
        kickmsg = string.gsub(kickmsg, "Whitelist Error:", "LuaGuard Error:")
        KickPlr("[MSHUB]\n".. kickmsg)
    elseif kickmsg:match("Whitelist ERROR [LDR]:") then 
        kickmsg = string.gsub(kickmsg, "Whitelist ERROR [LDR]:", "LuaGuard Error:")
        KickPlr("[MSHUB]\n".. kickmsg)
    end 
end)

task.wait()
loadstring(game:HttpGet('https://scripts.luawl.com/hosted/5055/21195/loaderscriptsoreal.lua'))()
