--			Plugin			--
local ActionMain = plugin:CreatePluginAction(
	"Path to instance",
	"Path to instance",
	"Insert the path to all selected instances.",
	"http://www.roblox.com/asset/?id=7240646192",
	true
) :: PluginAction
local ActionSecondary = plugin:CreatePluginAction(
	"Path to instance - modifier",
	"Path to instance - modifier",
	"Inserts and modifies the path to all selected instances.",
	"http://www.roblox.com/asset/?id=9149688913",
	true
) :: PluginAction

local PluginWidget = plugin:CreateDockWidgetPluginGui("TestWidget", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, false, true, 450, 250, 450, 250
)) :: DockWidgetPluginGui
PluginWidget.Title = "Path to instance" 



--		Variables		--
local FolderPlugin = script.Parent
local PathFunctions = require(FolderPlugin.PathFunctions)
local Frame = FolderPlugin.Assets.FramePlugin:Clone()


local Information = {
	Mode = Frame.Change.Normal,
	Selected = nil,
	Script = nil,

	Objects = {},
	Selection = {}
}
local function Select(Buttons, Button)
	for _, v in pairs(Buttons:GetChildren()) do
		if v:IsA("TextButton") then		v.Icon.ImageColor3 = Color3.new(1, 1, 1)		end
	end
	if Button then		Button.Icon.ImageColor3 = Color3.new(0, 0, 0)		end
end
local function InstanceButton(Button: TextButton, Object: Instance, FB: Frame)
	return function()
		Information.Selected = Object
		Select(Frame.Instances, Button)
		for _, v in pairs(Frame.PathList:GetChildren()) do
			if v:IsA("Frame") then		v.Visible = false		end
		end
		FB.Visible = true
	end
end



--		Set up			--
Frame.Parent = PluginWidget


--		Triggered		--
ActionMain.Triggered:Connect(function()
	Information.Script = game:GetService("StudioService").ActiveScript
	Information.Selection = game:GetService("Selection"):Get()
	for Index, Target in pairs(Information.Selection) do		
		local PathList = PathFunctions.GetPathList(Target)
		local PathString = PathFunctions.PathListToPathString(Information.Script, PathList)
		PathFunctions.InsertPathString(Information.Script, Target, PathString, Index)
	end
end)
ActionSecondary.Triggered:Connect(function()
	--			Variables and Check			--
	Information.Script = game:GetService("StudioService").ActiveScript
	Information.Selection = game:GetService("Selection"):Get()
	if not Information.Script then				return			end

	--		Clear		--
	Select(Frame.Instances, nil)
	Select(Frame.Change, Frame.Change.Normal)
	for _, v in pairs(Frame.Instances:GetChildren()) do
		if not v:IsA("UIGridLayout") then		v:Destroy()		end
	end
	for _, v in pairs(Frame.PathList:GetChildren()) do
		if not v:IsA("UIGridStyleLayout") then		v:Destroy()		end
	end
	table.clear(Information.Objects)

	--		Send		--
	for Index, Object in pairs(Information.Selection) do
		local FB = FolderPlugin.Assets.FrameBack:Clone()
		FB.Parent = Frame.PathList
		Information.Objects[Object] = {}

		--		Set new buttons		--
		for Index, Info in pairs(PathFunctions.GetPathList(Object)) do
			Information.Objects[Object][Index] = Info
			
			local SubButton = FolderPlugin.Assets.Base:Clone()
			SubButton.Name = (if Info.Object == game then "game" else Info.Object.Name)
			SubButton.Title.Text = SubButton.Name
			SubButton.Parent = FB
			
			local Success, Service = pcall(game.GetService, game, Info.Object.Name)
			if table.find({game, workspace}, Info.Object) or (Success and Service) then
				SubButton.AutoButtonColor = false
				SubButton.Icon:Destroy()
			else
				SubButton.MouseButton1Click:Connect(function()
					SubButton.Icon.ImageRectOffset = Information.Mode.Icon.ImageRectOffset
					SubButton.BackgroundColor3 = Information.Mode.BackgroundColor3
					Information.Objects[Object][Index].Mode = Information.Mode.Name
				end)
			end
		end

		--		To show		--
		local Button = FolderPlugin.Assets.Base:Clone()
		Button.Name = Object.Name
		Button.Title.Text = Object.Name
		Button.Parent = Frame.Instances
		Button.MouseButton1Click:Connect(InstanceButton(Button, Object, FB))
		if Index == 1 then		InstanceButton(Button, Object, FB)()		end
	end
	PluginWidget.Enabled = true
end)



--		Hide		--
game:GetService("Selection").SelectionChanged:Connect(function()
	PluginWidget.Enabled = false
end)



--		Change mode		--
for _, Button in pairs(Frame.Change:GetChildren()) do
	if not Button:IsA("TextButton") then			continue		end
	Button.MouseButton1Click:Connect(function()
		Select(Frame.Change, Button)
		Information.Mode = Button
	end)
end



--		Insert			--
local function InsertScript(Object: Instance)
	local Index = Information.Selection[Object]
	local PathList = Information.Objects[Object]
	
	local PathString = PathFunctions.PathListToPathString(Information.Script, PathList)
	PathFunctions.InsertPathString(Information.Script, Object, PathString, Index)
end
Frame.InsertAll.MouseButton1Click:Connect(function()
	for _, Object in pairs(Information.Selection) do		InsertScript(Object)		end
	PluginWidget.Enabled = false
end)
Frame.Insert.MouseButton1Click:Connect(function()
	InsertScript(Information.Selected)
end)
