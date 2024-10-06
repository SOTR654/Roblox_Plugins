--!strict
local StudioService = game:GetService("StudioService")
local ScriptEditorService: ScriptEditorService = game:GetService("ScriptEditorService")

local Frame = script.Frame
local Module = require(script.Data)
local SettingsData, Display = Module(plugin, Frame)

--		Create plugin		--
local Topbar: PluginToolbar = plugin:CreateToolbar("ScriptList")
local dock: DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui("ScriptList", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	300,
	400,
	150,
	200
))
dock.Title = "ScriptList"
Frame.Parent = dock

local SortFrames, Start = {}, {["Active"] = "rbxassetid://6031265978", ["Waiting"] = "rbxassetid://6031068428"}
local TargetMode, CloneScripts, InsertTypeColors = "Script", {}, {
	["Script"] = Color3.fromRGB(225, 225, 225),
	["ModuleScript"] = Color3.fromRGB(165, 105, 255),
	["LocalScript"] = Color3.fromRGB(43, 177, 255),
}
local function ReplaceSource(obj: LuaSourceContainer, Source)
	ScriptEditorService:UpdateSourceAsync(obj, function()		return Source		end)
end
local function CreateLua(Name: string, Source: string)
	local clone: Script = Instance.new(TargetMode)
	clone.Name = Name
	ReplaceSource(clone, Source)
	return clone
end

local Update = {
	["CodeTarget"] = function()
		local Current = SettingsData.Get("Default", {})[TargetMode]
		for ID, B in pairs(SortFrames) do
			B.Default.Image = Start[if Current == ID then "Active" else "Waiting"]
			B.LayoutOrder = (if Current == ID then -1 else 0)
		end
	end,
	["Target"] = function(self, new: string)
		local o = TargetMode
		TargetMode = new
		
		--		Visual		--
		for _, v: typeof(Frame.Insert.Script) in pairs(Frame.Insert:GetChildren()) do
			v.BackgroundColor3 = (if v.Name == new then InsertTypeColors[v.Name] else Color3.fromRGB(64, 64, 64))
			v.Icon.ImageColor3 = (if v.Name == new then Color3.new(0, 0, 0) else Color3.new(1, 1, 1))
		end
		self.CodeTarget()
		if o == new then		return		end
		
		--		Replace		--
		for ID, base: Script in pairs(CloneScripts) do
			CloneScripts[ID] = CreateLua(base.Name, base.Source)
			base:Destroy()
		end
	end
}
local function GetSelection(): (string?, LuaSourceContainer?)
	local current = StudioService.ActiveScript :: LuaSourceContainer
	if not current then		return		end

	--		Document		--
	local docu: ScriptDocument = ScriptEditorService:FindScriptDocument(current)
	if not docu then		return		end

	local Selection = docu:GetSelectedText()
	if #Selection > 1 then		return Selection, current		end
	return
end



--		Load current data		--
local function CreateFrame(ID: string, Info: Module.InfoType)
	--		Button		--
	local Button = script.Button:Clone()
	Button.Name, Button.Box.Text = ID, Info.Name
	Button.Parent = Frame.List
	SortFrames[ID] = Button
	
	--		Object		--
	CloneScripts[ID] = CreateLua(Info.Name, Info.Source)
	
	
	--		Connect		--
	Button.Box.FocusLost:Connect(function()
		Info.Name = Button.Box.Text
		CloneScripts[ID].Name = Info.Name
		task.spawn(SettingsData.Set, ID, Info)
	end)
	Button.Icons.Display.MouseButton1Click:Connect(function()
		plugin:OpenScript(CloneScripts[ID])
	end)
	Button.Icons.Insert.MouseButton1Click:Connect(function()
		local Success, Error = pcall(function()
			local base: Script = Instance.new(TargetMode)
			base.Name = Info.Name
			ReplaceSource(base, Info.Source)

			--		Clones		--
			local newSelection = {}
			for _, v: LuaSourceContainer in pairs(game:GetService("Selection"):Get()) do
				local clone = base:Clone()
				clone.Parent = v
				table.insert(newSelection, clone)
			end
			game:GetService("Selection"):Set(newSelection)
			base:Destroy()
		end)
		if not Success then		Display("Error", "Permission to insert scripts.")		end
	end)
	Button.Icons.Import.MouseButton1Click:Connect(function()
		local new = GetSelection()
		if new then
			Info.Source = new
			Display("Success", "Replaced code successfully")
			ReplaceSource(CloneScripts[ID], new)
		else
			Display("Error", "Invalid selection.")
		end
	end)
	Button.Default.MouseButton1Click:Connect(function()
		SettingsData.Update("Default", function(T)	T[TargetMode] = (if T[TargetMode] == ID then nil else ID)	end)
		Update.CodeTarget()
	end)
	Button.Icons.RemObj.MouseButton1Click:Connect(function()
		task.spawn(SettingsData.Update, "List", function(list)	table.remove(list, table.find(list, ID))	end)
		task.spawn(SettingsData.Set, ID, nil)
		SortFrames[ID] = nil
		Button:Destroy()
	end)
end
for _, ID in pairs(SettingsData.Get("List", {})) do
	local v = SettingsData.Get(ID)
	if v then		CreateFrame(ID, v)		end
end



--		Connect button		--
local button: PluginToolbarButton = Topbar:CreateButton(
	"ScriptList_Open",
	"List of saved scripts.",
	"rbxthumb://type=Asset&id=529831398&w=150&h=150",
	"Script list"
)
button.Click:Connect(function()		dock.Enabled = (not dock.Enabled)		end)
button.ClickableWhenViewportHidden = true



--		Connect Frame		--
for _, v: TextButton in pairs(Frame.Insert:GetChildren()) do
	v.MouseButton1Click:Connect(function()		Update:Target(v.Name)		end)
end
Frame.Add.MouseButton1Click:Connect(function()
	local Selection, current = GetSelection()
	if not Selection or not current then		return		end

	--		Save		--
	local Int, Float = unpack(tostring(os.clock()):split("."))
	local ID = Int.."_"..Float:sub(1, 2)
	local Info: Module.InfoType = {["Source"] = Selection, ["Name"] = current.Name}
	if not SettingsData.Set(ID, Info) then		return		end
	
	--		Add list?		--
	local Success = (SettingsData.Update("List", function(list)	table.insert(list, ID)		end))
	if Success then
		CreateFrame(ID, Info)
	else
		SettingsData.Set(ID, nil)
	end
	Update.CodeTarget()
end)
Update:Target("Script")

--		Active script		--
local Connection: RBXScriptConnection = nil
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()
	if Connection then		Connection:Disconnect()		end
	Connection = nil::any
	
	--		Visual		--
	local v = StudioService.ActiveScript
	Frame.Add.BackgroundColor3 = (if v then Color3.fromRGB(64, 64, 64) else Color3.fromRGB(33, 33, 33))
	Frame.Add.TL.TextColor3 = (if v then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(129, 129, 129))
	if not v then		return		end
	
	--		Connect change?		--
	local docu: ScriptDocument = ScriptEditorService:FindScriptDocument(v)
	if not docu then		return		end
	
	local function onChange()		Frame.SelectionSize.Text = "Selection size: ".. #docu:GetSelectedText()		end
	Connection = docu.SelectionChanged:Connect(onChange)
	onChange()
end)



--		Default script		--
local function IsNewScript(obj: Script): boolean
	if obj:IsA("LocalScript") or obj:IsA("Script") then
		return (obj.Source == 'print("Hello world!")\n')
	elseif obj:IsA("ModuleScript") then
		return (obj.Source == 'local module = {}\n\nreturn module\n')
	end
	return false
end
ScriptEditorService.TextDocumentDidOpen:Connect(function(docu)
	local obj = docu:GetScript() :: Script
	if not obj or not IsNewScript(obj) then		return		end
	
	--		Type		--
	local ID = SettingsData.Get("Default", {})[obj.ClassName]
	if not ID then		return		end
	
	--		Set		--
	local v = SettingsData.Get(ID)
	if v then	ReplaceSource(obj, v.Source)	end
end)
