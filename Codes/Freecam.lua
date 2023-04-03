local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local FC_MODULE = {}
local fcRunning = false
local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {
	{Enum.KeyCode.LeftShift, Enum.KeyCode.P}, 
	{Enum.KeyCode.ButtonL1, Enum.KeyCode.DPadRight}
}

local NAV_GAIN = Vector3.one * 64
local PAN_GAIN = Vector2.new(0.75, 1) * 8
local FOV_GAIN = 300

local PITCH_LIMIT = math.rad(90)
local VEL_STIFFNESS = 1.5

local PAN_STIFFNESS = 1
local FOV_STIFFNESS = 4

local function WaitForChildWhichIsA(Parent, ClassName, TimeOut)
	local Child = Parent:FindFirstChildWhichIsA(ClassName)

	if Child then
		return Child
	else
		local Connection
		local Thread = coroutine.running()

		Connection = Parent.ChildAdded:Connect(function(_Child)
			if not Child and _Child:IsA(ClassName) then
				if Connection then
					if Connection.Connected then
						Connection:Disconnect()
					end
					Connection = nil
				end
				Child = _Child
				task.spawn(Thread, Child)
			end
		end)

		if TimeOut then
			task.delay(TimeOut, function()
				if not Child then
					if Connection then
						if Connection.Connected then
							Connection:Disconnect()
						end
						Connection = nil
					end
					task.spawn(Thread, nil)
				end
			end)
		else
			task.delay(5, function()
				if not Child then
					warn(string.format("Infinite yield possible waiting on %s:FindFirstChildWhichIsA(\"%s\")", Parent:GetFullName(), ClassName))
				end
			end)
		end

		assert(coroutine.isyieldable(), "assertion failed!")
		return coroutine.yield()
	end
end

local function LoadFlag(Flag)
	local Success, Result = pcall(function()
		return UserSettings():IsUserFeatureEnabled(Flag)
	end)
	return Success and Result
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local NewCamera = Workspace.CurrentCamera
	if NewCamera then
		Camera = NewCamera
	end
end)

local FFlagUserExitFreecamBreaksWithShiftlock = LoadFlag("UserExitFreecamBreaksWithShiftlock")
local PlayerScripts = WaitForChildWhichIsA(LocalPlayer, "PlayerScripts")
local PlayerGui = WaitForChildWhichIsA(LocalPlayer, "PlayerGui")

local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))

local PlayerInput = {
	InputTypes = {KEYBOARD_MOUSE = "keyboard/mouse", TOUCH = "touch", GAMEPAD = "gamepad"},
	InputTypeChanged = Instance.new("BindableEvent"),
	CurrentInput = nil
}

local function GetInputType(UserInputType)
	if 
		UserInputType == Enum.UserInputType.MouseButton1 
		or UserInputType == Enum.UserInputType.MouseButton2 
		or UserInputType == Enum.UserInputType.MouseButton3 
		or UserInputType == Enum.UserInputType.MouseWheel 
		or UserInputType == Enum.UserInputType.MouseMovement 
		or UserInputType == Enum.UserInputType.Keyboard 
	then
		return PlayerInput.InputTypes.KEYBOARD_MOUSE
	elseif 
		UserInputType == Enum.UserInputType.Touch 
		or UserInputType == Enum.UserInputType.Accelerometer 
		or UserInputType == Enum.UserInputType.Gyro  
	then
		return PlayerInput.InputTypes.TOUCH
	elseif 
		UserInputType == Enum.UserInputType.Gamepad1 
		or UserInputType == Enum.UserInputType.Gamepad2 
		or UserInputType == Enum.UserInputType.Gamepad3 
		or UserInputType == Enum.UserInputType.Gamepad4 
		or UserInputType == Enum.UserInputType.Gamepad5 
		or UserInputType == Enum.UserInputType.Gamepad6 
		or UserInputType == Enum.UserInputType.Gamepad7 
		or UserInputType == Enum.UserInputType.Gamepad8 
	then
		return PlayerInput.InputTypes.GAMEPAD
	end
	return nil
end

local function SetPlayerInputType(UserInputType)
	local PlayerInputType = GetInputType(UserInputType)
	if PlayerInputType and PlayerInputType ~= PlayerInput.CurrentInput then
		PlayerInput.CurrentInput = PlayerInputType
		PlayerInput.InputTypeChanged:Fire(PlayerInputType)
	end
end
SetPlayerInputType(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(SetPlayerInputType)

local Controls = PlayerModule:GetControls()
local Spring = {} do
	Spring.__index = Spring

	function Spring.new(Freq, Pos)
		local self = setmetatable({}, Spring)
		self.F = Freq
		self.P = Pos
		self.V = Pos * 0
		return self
	end

	function Spring:Update(DT, Goal)
		local F = (self.F) * 2 * math.pi
		local P0 = self.P
		local V0 = self.V

		local Offset = Goal - P0
		local Decay = math.exp(-F * DT)

		local P1 = Goal + (V0 * DT - Offset * (F * DT + 1)) * Decay
		local V1 = (F * DT * (Offset * F - V0) + V0) * Decay

		self.P = P1
		self.V = V1

		return P1
	end

	function Spring:Reset(Pos)
		self.Position = Pos
		self.Velocity = Pos * 0
	end
end

local CameraPos = Vector3.zero
local CameraRot = Vector2.zero
local CameraFOV = 0

local VelSpring = Spring.new(VEL_STIFFNESS, Vector3.zero)
local PanSpring = Spring.new(PAN_STIFFNESS, Vector2.zero)
local FOVSpring = Spring.new(FOV_STIFFNESS, 0)

local Input = {} do
	local MIN_TOUCH_SENSITIVITY_FRACTION = 0.25

	local function ThumbstickCurve(X)
		local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

		local function FCurve(X)
			return (math.exp(K_CURVATURE * X) - 1) / (math.exp(K_CURVATURE) - 1)
		end

		local function FDeadzone(X)
			return FCurve((X - K_DEADZONE) / (1 - K_DEADZONE))
		end

		return math.sign(X) * math.clamp(FDeadzone(math.abs(X)), 0, 1)
	end

	local function AdjustTouchPitchSensitivity(Delta)
		if Workspace.CurrentCamera == Camera then
			local Pitch = Camera.CFrame:ToEulerAnglesYXZ()
			if Delta.Y * Pitch >= 0 then
				return Delta
			end
			local CurveY = 1 - (2 * math.abs(Pitch) / math.pi) ^ 0.75
			local Sensitivity = CurveY * (1 - MIN_TOUCH_SENSITIVITY_FRACTION) + MIN_TOUCH_SENSITIVITY_FRACTION
		end
		return Delta
	end

	local function IsInDynamicThumbstickArea(Pos)
		local TouchGui = Controls.touchGui
		if TouchGui and TouchGui:IsDescendantOf(game) then
			local TouchControlFrame = Controls.touchControlFrame
			if TouchControlFrame and TouchControlFrame:IsDescendantOf(game) then
				local ThumbstickFrame = TouchControlFrame:FindFirstChild("DynamicThumbstickFrame")
				if ThumbstickFrame then
					local PosTopLeft = ThumbstickFrame.AbsolutePosition
					local PosBottomRight = PosTopLeft + ThumbstickFrame.AbsoluteSize
					if 
						Pos.X >= PosTopLeft.X 
						and Pos.Y >= PosTopLeft.Y 
						and Pos.X <= PosBottomRight.X 
						and Pos.Y <= PosBottomRight.Y 
					then
						return true
					end
				end
			end
		end
		return false
	end

	local Gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.zero,
		Thumbstick2 = Vector2.zero,
	}

	local Keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}

	local Mouse = {
		Delta = Vector2.zero,
		MouseWheel = 0,
	}

	local Touch = {
		Move = Vector2.zero,
		Pinch = 0,
	}

	local NAV_GAMEPAD_SPEED = Vector3.one
	local NAV_KEYBOARD_SPEED = Vector3.one
	local PAN_MOUSE_SPEED = Vector2.one * (math.pi / 64)
	local PAN_TOUCH_SPEED = Vector2.one * (math.pi / 16)
	local PAN_GAMEPAD_SPEED = Vector2.one * (math.pi / 8)
	local FOV_TOUCH_SPEED = 0.04
	local FOV_WHEEL_SPEED = 1.0
	local FOV_GAMEPAD_SPEED = 0.25
	local NAV_ADJ_SPEED = 0.75
	local NAV_SHIFT_MUL = 0.25

	local Touches = {}
	local DynamicThumbstickInput
	local LastPinchDiameter

	local Events = {}
	local Shift = false
	local NavSpeed = 1

	function Input.Vel(DT)
		local MoveVector = Controls:GetMoveVector()

		NavSpeed = math.clamp(
			NavSpeed + DT * (Keyboard.Up - Keyboard.Down) * NAV_ADJ_SPEED, 
			0.01, 
			4
		)

		local KGamepad = Vector3.new(
			ThumbstickCurve(Gamepad.Thumbstick1.X),
			ThumbstickCurve(Gamepad.ButtonR2) - ThumbstickCurve(Gamepad.ButtonL2),
			ThumbstickCurve(-Gamepad.Thumbstick1.Y)
		) * NAV_GAMEPAD_SPEED

		local KKeyboard = Vector3.new(
			Keyboard.D - Keyboard.A + Keyboard.K - Keyboard.H,
			Keyboard.E - Keyboard.Q + Keyboard.I - Keyboard.Y,
			Keyboard.S - Keyboard.W + Keyboard.J - Keyboard.U
		) * NAV_KEYBOARD_SPEED

		local Result = nil;
		if PlayerInput.CurrentInput == PlayerInput.InputTypes.TOUCH then 
			Result = Vector3.new(
				ThumbstickCurve(MoveVector.X),
				ThumbstickCurve(MoveVector.Y),
				ThumbstickCurve(MoveVector.Z)
			) * NAV_KEYBOARD_SPEED
		else
			Result = (KGamepad + KKeyboard)
		end

		return Result * (NavSpeed * (Shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(DT)
		local KGamepad = Vector2.new(
			ThumbstickCurve(Gamepad.Thumbstick2.Y),
			ThumbstickCurve(-Gamepad.Thumbstick2.X)
		) * PAN_GAMEPAD_SPEED
		local KMouse = Mouse.Delta * PAN_MOUSE_SPEED
		local KTouch = Touch.Move * PAN_TOUCH_SPEED
		Mouse.Delta = Vector2.zero
		Touch.Move = Vector2.zero
		return KGamepad + KMouse + KTouch
	end

	function Input.Fov(DT)
		local KGamepad = (Gamepad.ButtonX - Gamepad.ButtonY) * FOV_GAMEPAD_SPEED
		local KMouse = Mouse.MouseWheel * FOV_WHEEL_SPEED
		local KTouch = Touch.Pinch * FOV_TOUCH_SPEED
		Mouse.MouseWheel = 0
		Touch.Pinch = 0
		return KGamepad + KMouse + KTouch
	end

	local function Keypress(Action, State, Input)
		Keyboard[Input.KeyCode.Name] = State == Enum.UserInputState.Begin and 1 or 0
		return Enum.ContextActionResult.Sink
	end

	local function GpButton(Action, State, Input)
		Gamepad[Input.KeyCode.Name] = State == Enum.UserInputState.Begin and 1 or 0
		return Enum.ContextActionResult.Sink
	end

	local function MousePan(Action, State, Input)
		local Delta = Input.Delta
		Mouse.Delta = Vector2.new(-Delta.Y, -Delta.X)
		return Enum.ContextActionResult.Sink
	end

	local function Thumb(Action, State, Input)
		Gamepad[Input.KeyCode.Name] = Input.Position
		return Enum.ContextActionResult.Sink
	end

	local function Trigger(Action, State, Input)
		Gamepad[Input.KeyCode.Name] = Input.Position.Z
		return Enum.ContextActionResult.Sink
	end

	local function MouseWheel(Action, State, Input)
		Mouse[Input.UserInputType.Name] = -Input.Position.Z
		return Enum.ContextActionResult.Sink
	end

	local function Zero(Table)
		for Key, Value in pairs(Table) do
			Table[Key] = Value * 0
		end
	end

	function Input.StartCapture()
		ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
			Enum.KeyCode.W, Enum.KeyCode.U,
			Enum.KeyCode.A, Enum.KeyCode.H,
			Enum.KeyCode.S, Enum.KeyCode.J,
			Enum.KeyCode.D, Enum.KeyCode.K,
			Enum.KeyCode.E, Enum.KeyCode.I,
			Enum.KeyCode.Q, Enum.KeyCode.Y,
			Enum.KeyCode.Up, Enum.KeyCode.Down
		)
		ContextActionService:BindActionAtPriority("FreecamMousePan", MousePan, false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
		ContextActionService:BindActionAtPriority("FreecamMouseWheel", MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
		ContextActionService:BindActionAtPriority("FreecamGamepadButton", GpButton, false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
		ContextActionService:BindActionAtPriority("FreecamGamepadTrigger", Trigger, false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
		ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb, false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		table.insert(Events, UserInputService.PointerAction:Connect(function(Wheel, Pan, Pinch, GameProcessedEvent)
			if not GameProcessedEvent then
				Mouse.Delta = Vector2.new(-Pan.Y, -Pan.X)
				Mouse.MouseWheel = -Wheel + -Pinch
			end
		end))
		table.insert(Events, UserInputService.InputBegan:Connect(function(Input, Sunk)
			if Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.Begin then
				if not DynamicThumbstickInput and IsInDynamicThumbstickArea(Input.Position) and not Sunk then
					DynamicThumbstickInput = Input
				else
					Touches[Input] = Sunk
				end
			end
		end))
		table.insert(Events, UserInputService.InputChanged:Connect(function(Input, Sunk)
			if Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.Change and Input ~= DynamicThumbstickInput then
				if type(Touches[Input]) ~= "boolean" then
					Touches[Input] = Sunk
				end

				local UnsunkTouches = {}
				for Touch, Sunk in pairs(Touches) do
					if not Sunk then
						table.insert(UnsunkTouches, Touch)
					end
				end

				if table.getn(UnsunkTouches) == 1 then
					if Touches[Input] == false then
						local Delta = Input.Delta
						Touch.Move = Touch.Move + AdjustTouchPitchSensitivity(Vector2.new(-Delta.Y, -Delta.X))
					end
				end

				if table.getn(UnsunkTouches) == 2 then
					local PinchDiameter = (UnsunkTouches[1].Position - UnsunkTouches[2].Position).Magnitude

					if LastPinchDiameter then
						Touch.Pinch = Touch.Pinch + -(PinchDiameter - LastPinchDiameter)
					end

					LastPinchDiameter = PinchDiameter
				else
					LastPinchDiameter = nil
				end
			end
		end))
		table.insert(Events, UserInputService.InputEnded:Connect(function(Input, Sunk)
			if Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.End then
				if Input == DynamicThumbstickInput then
					DynamicThumbstickInput = nil
				end

				if Touches[Input] == false then
					LastPinchDiameter = nil
				end

				Touches[Input] = nil
			end
		end))
		ContextActionService:BindActionAtPriority("FreecamShiftSpeed", function(ActionName, InputState, InputObject)
			if InputState == Enum.UserInputState.Begin then
				Shift = true
			elseif InputState == Enum.UserInputState.End or InputState == Enum.UserInputState.Cancel then
				Shift = false
			end
		end, true, INPUT_PRIORITY, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonR1)
	end

	function Input.StopCapture()
		NavSpeed = 1
		Zero(Gamepad)
		Zero(Keyboard)
		Zero(Mouse)
		ContextActionService:UnbindAction("FreecamKeyboard")
		ContextActionService:UnbindAction("FreecamMousePan")
		ContextActionService:UnbindAction("FreecamMouseWheel")
		ContextActionService:UnbindAction("FreecamGamepadButton")
		ContextActionService:UnbindAction("FreecamGamepadTrigger")
		ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		ContextActionService:UnbindAction("FreecamShiftSpeed")
		Touches = {}
		DynamicThumbstickInput = nil
		LastPinchDiameter = nil
		for _, Event in ipairs(Events) do
			if Event.Connected then
				Event:Disconnect()
			end
		end
		table.clear(Events)
	end
end

local function GetFocusDistance(CameraFrame)
	local Znear = 0.1
	local Viewport = Camera.ViewportSize
	local ProjY = 2 * math.tan(CameraFOV / 2)
	local ProjX = Viewport.X / Viewport.Y * ProjY
	local Fx = CameraFrame.RightVector
	local Fy = CameraFrame.UpVector
	local Fz = CameraFrame.LookVector

	local MinVect = Vector3.zero
	local MinDist = 512

	for X = 0, 1, 0.5 do
		for Y = 0, 1, 0.5 do
			local Cx = (X - 0.5) * ProjX
			local Cy = (Y - 0.5) * ProjY
			local Offset = Fx * Cx - Fy * Cy + Fz
			local Origin = CameraFrame.Position + Offset * Znear
			local RaycastResult = workspace:Raycast(Origin, Offset.Unit * MinDist)
			if RaycastResult then
				local Dist = (RaycastResult.Position - Origin).Magnitude
				if MinDist > Dist then
					MinDist = Dist
					MinVect = Offset.Unit
				end
			end
		end
	end

	return Fz:Dot(MinVect) * MinDist
end

local function StepFreecam(DT)
	local Vel = VelSpring:Update(DT, Input.Vel(DT))
	local Pan = PanSpring:Update(DT, Input.Pan(DT))
	local FOV = FOVSpring:Update(DT, Input.Fov(DT))

	local ZoomFactor = math.sqrt(math.tan(math.rad(70 / 2)) / math.tan(math.rad(CameraFOV / 2)))

	CameraFOV = math.clamp(CameraFOV + FOV * FOV_GAIN * (DT / ZoomFactor), 1, 120)
	CameraRot = CameraRot + Pan * PAN_GAIN * (DT / ZoomFactor)
	CameraRot = Vector2.new(math.clamp(CameraRot.X, -PITCH_LIMIT, PITCH_LIMIT), CameraRot.Y % (2 * math.pi))

	local CameraCFrame = CFrame.new(CameraPos) * CFrame.fromOrientation(CameraRot.X, CameraRot.Y, 0) * CFrame.new(Vel * NAV_GAIN * DT)
	CameraPos = CameraCFrame.Position

	Camera.CFrame = CameraCFrame
	Camera.Focus = CameraCFrame * CFrame.new(0, 0, -GetFocusDistance(CameraCFrame))
	Camera.FieldOfView = CameraFOV
end

local function CheckMouseLockAvailability()
	local DevAllowsMouseLock = LocalPlayer.DevEnableMouseLock
	local DevMovementModeIsScriptable = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
	local UserHasMouseLockModeEnabled = UserGameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
	local UserHasClickToMoveEnabled =  UserGameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
	local MouseLockAvailable = DevAllowsMouseLock and UserHasMouseLockModeEnabled and not UserHasClickToMoveEnabled and not DevMovementModeIsScriptable

	return MouseLockAvailable
end

local PlayerState = {} do
	local MouseBehavior
	local MouseIconEnabled

	local CameraType
	local CameraFocus

	local CameraCFrame
	local CameraFieldOfView

	local Humanoid
	local Thread
	local CoreGuis = {}
	local SetCores = {}
	local CharacterEvents = {}
	local PlayerEvents = {}
	local ScreenGuis = {}

	local CurrentCameraMaxZoomDistance
	local CurrentCameraMinZoomDistance
	local CurrentWalkSpeed

	local CameraMaxZoomDistanceChangedDebounce = false
	local CameraMinZoomDistanceChangedDebounce = false

	local WalkSpeedChangedDebounce = false
	local PlayerStateIsEnabled = false

	local function OnCameraMaxZoomDistanceChanged()
		if not CameraMaxZoomDistanceChangedDebounce then
			CameraMaxZoomDistanceChangedDebounce = true
			if PlayerStateIsEnabled then
				CurrentCameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
				LocalPlayer.CameraMaxZoomDistance = 5
			else
				LocalPlayer.CameraMaxZoomDistance = CurrentCameraMaxZoomDistance
			end
			CameraMaxZoomDistanceChangedDebounce = false
		end
	end

	local function OnCameraMinZoomDistanceChanged()
		if not CameraMinZoomDistanceChangedDebounce then
			CameraMinZoomDistanceChangedDebounce = true
			if PlayerStateIsEnabled then
				CurrentCameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance
				LocalPlayer.CameraMinZoomDistance = 5
			else
				LocalPlayer.CameraMinZoomDistance = CurrentCameraMinZoomDistance
			end
			CameraMinZoomDistanceChangedDebounce = false
		end
	end

	local function OnCharacterAdded(Character)
		local NewHumanoid = WaitForChildWhichIsA(Character, "Humanoid")
		local function OnWalkSpeedChanged()
			if not WalkSpeedChangedDebounce then
				WalkSpeedChangedDebounce = true
				CurrentWalkSpeed = NewHumanoid.WalkSpeed
				if PlayerStateIsEnabled then 
					NewHumanoid.WalkSpeed = 0 
				end
				WalkSpeedChangedDebounce = false
			end
		end
		OnWalkSpeedChanged()
		table.insert(CharacterEvents, NewHumanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(OnWalkSpeedChanged))
		Humanoid = NewHumanoid
	end

	local function OnCharacterRemoving(_)
		for _, Event in ipairs(CharacterEvents) do
			if Event.Connected then
				Event:Disconnect()
			end
		end
		table.clear(CharacterEvents)

		if Humanoid then
			Humanoid.WalkSpeed = CurrentWalkSpeed
			Humanoid = nil
		end
	end

	function PlayerState.Push()
		if not PlayerStateIsEnabled then
			PlayerStateIsEnabled = true

			for Name in pairs(CoreGuis) do
				CoreGuis[Name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[Name])
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[Name], false)
			end

			for Name in pairs(SetCores) do
				SetCores[Name] = StarterGui:GetCore(Name)
				StarterGui:SetCore(Name, false)
			end

			for _, Child in ipairs(PlayerGui:GetChildren()) do
				if Child:IsA("ScreenGui") and Child.Enabled and Child ~= Controls.touchGui and Child.Name ~= "ButtonScreenGui" then
					table.insert(ScreenGuis, Child)
					Child.Enabled = false
				end
			end

			CameraFieldOfView = Camera.FieldOfView
			Camera.FieldOfView = 70

			CameraType = Camera.CameraType
			Camera.CameraType = Enum.CameraType.Custom

			CameraCFrame = Camera.CFrame
			CameraFocus = Camera.Focus

			MouseIconEnabled = UserInputService.MouseIconEnabled
			UserInputService.MouseIconEnabled = false

			if FFlagUserExitFreecamBreaksWithShiftlock and CheckMouseLockAvailability() then
				MouseBehavior = Enum.MouseBehavior.Default
			else
				MouseBehavior = UserInputService.MouseBehavior
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default

			OnCameraMinZoomDistanceChanged()
			table.insert(PlayerEvents, LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(OnCameraMinZoomDistanceChanged))

			OnCameraMaxZoomDistanceChanged()
			table.insert(PlayerEvents, LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(OnCameraMaxZoomDistanceChanged))

			if LocalPlayer.Character then
				Thread = task.spawn(OnCharacterAdded, LocalPlayer.Character)
			end
			table.insert(PlayerEvents, LocalPlayer.CharacterAdded:Connect(OnCharacterAdded))
			table.insert(PlayerEvents, LocalPlayer.CharacterRemoving:Connect(OnCharacterRemoving))
		end
	end

	function PlayerState.Pop()
		if PlayerStateIsEnabled then
			PlayerStateIsEnabled = false

			if Thread and coroutine.status(Thread) == "running" then
				coroutine.close(Thread)
			end

			for Name, IsEnabled in pairs(CoreGuis) do
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[Name], IsEnabled)
			end

			for Name, IsEnabled in pairs(SetCores) do
				StarterGui:SetCore(Name, IsEnabled)
			end

			for _, Gui in ipairs(ScreenGuis) do
				if Gui:IsDescendantOf(game) then
					Gui.Enabled = true
				end
			end
			table.clear(ScreenGuis)

			for _, Event in ipairs(PlayerEvents) do
				if Event.Connected then
					Event:Disconnect()
				end
			end
			table.clear(PlayerEvents)

			if LocalPlayer.Character then
				OnCharacterRemoving(LocalPlayer.Character)
			end

			OnCameraMinZoomDistanceChanged()
			OnCameraMaxZoomDistanceChanged()

			Camera.FieldOfView = CameraFieldOfView
			CameraFieldOfView = nil

			Camera.CameraType = CameraType
			CameraType = nil

			Camera.CFrame = CameraCFrame
			CameraCFrame = nil

			Camera.Focus = CameraFocus
			CameraFocus = nil

			UserInputService.MouseIconEnabled = MouseIconEnabled
			MouseIconEnabled = nil

			UserInputService.MouseBehavior = MouseBehavior
			MouseBehavior = nil
		end
	end

	Players.PlayerRemoving:Connect(function(PlayerRemoving)
		if PlayerRemoving == LocalPlayer then
			for _, Event in ipairs(PlayerEvents) do
				if Event.Connected then
					Event:Disconnect()
				end
			end
			table.clear(PlayerEvents)

			if LocalPlayer.Character then
				OnCharacterRemoving(LocalPlayer.Character)
			end
		end
	end)
end

FC_MODULE.StopFreecam = function()
	if not fcRunning then return end
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
	workspace.Camera.FieldOfView = 70
	fcRunning = false
end

FC_MODULE.StartFreecam = function()
	if fcRunning then
		FC_MODULE.StopFreecam()
	end

	local CameraCFrame = Camera.CFrame
	CameraRot = Vector2.new(CameraCFrame:ToEulerAnglesYXZ())
	CameraPos = CameraCFrame.Position
	CameraFOV = Camera.FieldOfView

	VelSpring:Reset(Vector3.zero)
	PanSpring:Reset(Vector2.zero)
	FOVSpring:Reset(0)

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value + 1, StepFreecam)
	Input.StartCapture()
	fcRunning = true
end

return FC_MODULE
--FC_MODULE.StartFreecam()
--task.wait(10)
--FC_MODULE.StopFreecam()
