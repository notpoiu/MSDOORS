print("MSDOORS: Loading...")
local LoadstringURL = 'https://scripts.luawl.com/hosted/5055/19216/MSDOORSmain.lua'

function KickPlr(Message)local gui = game.CoreGui.RobloxPromptGui.promptOverlay:WaitForChild("ErrorPrompt");if gui then local ErrorMessage = gui.MessageArea.ErrorFrame.ErrorMessage;ErrorMessage.Text = Message;gui.Size = UDim2.new(0, gui.Size.X.Offset, 0, 50 + game:GetService("TextService"):GetTextSize(ErrorMessage.Text, ErrorMessage.TextSize, ErrorMessage.Font, (Vector2.new(gui.Size.X.Offset - 2 * 20, 1000))).Y + 1 + 36 + 20 + 2 * 20 + 1);end end
local KickMessageHandler = game:GetService("GuiService").ErrorMessageChanged:Connect(function(kickmsg)
	if (kickmsg:match("LDR") or kickmsg:match("LPH")) and kickmsg:match("Invalid HWID") then 
	    local EXE = string.lower((identifyexecutor and table.concat({ identifyexecutor() }, " ") or "Unknown"))

	    if EXE:match("fluxus") and (EXE:match("android") or EXE:match("mobile")) then 
            KickPlr("[MSDOORS]\nYou are using an outdated version of Fluxus Android. Join the discord server (.gg/eeHV6Tsfwd) if you need any help!") 
        else 
            KickPlr("[MSDOORS]\nYour executor is not supported. Join the discord server (.gg/eeHV6Tsfwd)!\n\n[error: Invalid HWID]") 
        end
    end
end)

loadstring(game:HttpGet(LoadstringURL))()
KickMessageHandler:Disconnect()
