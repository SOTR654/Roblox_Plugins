local SES = game:GetService('ScriptEditorService')

--		Plugin		--
local ActionMain: PluginAction = plugin:CreatePluginAction(
	"Path to instance",
	"Path to instance",
	"Insert the path to all selected instances.",
	"http://www.roblox.com/asset/?id=7240646192",
	true
)



--		Variables & function		--
local ReplaceLocal = {
	["StarterGui"] = ':GetService("Players").LocalPlayer.PlayerGui',
	["StarterPack"] = ':GetService("Players").LocalPlayer.Backpack',
}
local function format(Name: string, Mode: string)
	if Mode == "WaitForChild" then
		return (':WaitForChild("%s")'):format(Name)
	elseif Mode == "FindFirstChild" then
		return (':FindFirstChild("%s")'):format(Name)
	else
		if Name:find(" ") then
			return ('["%s"]'):format(Name)
		else
			local Name2 = table.concat(Name:split(" "), "_")
			if Name2:gsub("_", "b"):match("^%a") and not Name2:find("&") then
				return "." .. Name
			else
				return ('["%s"]'):format(Name)
			end
		end
	end
end



--		Connect		--
ActionMain.Triggered:Connect(function()
	local TS = game:GetService("StudioService").ActiveScript
	if not TS then		return		end
	
	--		Before		--
	local Document = SES:FindScriptDocument(TS)
	if not Document then		return		end
	
	local Line, Char = Document:GetSelection()
	
	--		Set		--
	local N = 0
	for Index, Target in pairs(game:GetService("Selection"):Get()) do	
		--		PathList		--
		local Parent, PathList = Target.Parent, {Target}
		while Parent and Parent ~= game do
			PathList = {Parent, table.unpack(PathList)}
			Parent = Parent.Parent
		end
		if PathList[1] ~= workspace then
			PathList = {game, table.unpack(PathList)}
		end
		for Index, Object in pairs(PathList) do
			PathList[Index] = {
				Object = Object,
				Mode = "Normal"
			}
		end

		--		String list		--
		local PathString = ""
		for Index, Info in pairs(PathList) do
			if Index == 1 then
				PathString = (if Info.Object == workspace then "workspace" else "game")
			elseif Index == 2 then
				if PathList[1].Object == game and pcall(game.GetService, game, Info.Object.Name) then
					local Find = ReplaceLocal[Info.Object.Name]
					if Find and TS:IsA("LocalScript") then		PathString ..=  Find continue		end
					PathString ..=  (':GetService("%s")'):format(Info.Object.Name)
				else
					PathString ..= format(Info.Object.Name, Info.Mode)
				end
			else
				PathString ..= format(Info.Object.Name, Info.Mode)
			end
		end

		--		Insert		--
		local Name = Target.Name
		Name = table.concat(Name:split(" "), "_")
		if not Name:gsub("_", "b"):match("^%a") or Name:find("&") then		Name = "Value" .. Index		end
		

		--			Place			--
		local Base = ("local %s = "..((Target:IsA("ModuleScript") and 'require(%s)') or '%s').."\n")
		local Success, Error = pcall(SES.UpdateSourceAsync, SES, TS, function(b)  return Base:format(Name, PathString)..b  end)
		if Success then
			game:GetService("ChangeHistoryService"):SetWaypoint("Path to instance")
		else
			warn("Path to instance: needs permission to edit the script.")
			print("Path to instance error:", Error)
		end
	end
	
	--		Selection		--
	local Success = pcall(Document.ForceSetSelectionAsync, Document, Line, Char)
	if not Success then		pcall(Document.ForceSetSelectionAsync, Document, Line, 1)	end
end)
