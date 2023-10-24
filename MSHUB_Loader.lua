local ok = "SCRIPT IS DOWN"
function KickPlr(Message)local gui = game.CoreGui.RobloxPromptGui.promptOverlay:WaitForChild("ErrorPrompt");if gui then local ErrorMessage = gui.MessageArea.ErrorFrame.ErrorMessage;ErrorMessage.Text = Message;gui.Size = UDim2.new(0, gui.Size.X.Offset, 0, 50 + game:GetService("TextService"):GetTextSize(ErrorMessage.Text, ErrorMessage.TextSize, ErrorMessage.Font, (Vector2.new(gui.Size.X.Offset - 2 * 20, 1000))).Y + 1 + 36 + 20 + 2 * 20 + 1);end end
game:GetService("GuiService").ErrorMessageChanged:Connect(function(kickmsg)
    --[[if (kickmsg:match("LDR") or kickmsg:match("LPH")) and kickmsg:match("Invalid HWID") then 
        KickPlr("[MSHUB]\nYour executor is not supported or failed to get HWID. Join the discord server (.gg/J8P563m8aX, .gg/mshub)!\n\n[error: Invalid HWID.]")
    elseif kickmsg:match("Whitelist Error:") then 
        kickmsg = string.gsub(kickmsg, "Whitelist Error:", "LuaGuard Error:")
        KickPlr("[MSHUB]\n".. kickmsg)
    elseif kickmsg:match("Whitelist ERROR [LDR]:") then 
        kickmsg = string.gsub(kickmsg, "Whitelist ERROR [LDR]:", "LuaGuard Error:")
        KickPlr("[MSHUB]\n".. kickmsg)
    end --]]
    if kickmsg == ok then
        KickPlr("[MSHUB]\nSCRIPT IS DOWN\nPlease join the discord for more info about the script: .gg/J8P563m8aX, .gg/mshub")
    end
end)

task.wait()
game.Players.LocalPlayer:Kick(ok)

--loadstring(game:HttpGet('https://scripts.luawl.com/hosted/5055/21534/load_er.lua'))()
