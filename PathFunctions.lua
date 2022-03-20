--				Variables				--
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
			if Name2:gsub("_", "b"):match("^%a") then
				return "." .. Name
			else
				return ('["%s"]'):format(Name)
			end
		end
		
	end
end
local ReplaceLocal = {
	["StarterGui"] = ':GetService("Players").LocalPlayer.PlayerGui',
	["StarterPack"] = ':GetService("Players").LocalPlayer.Backpack',
}



type PathList = {
	[number]: {
		Object: Instance,
		Mode: string
	}
}


--				Module				--
local PF = {}
function PF.GetPathList(Target: Instance): PathList
	local Parent = Target.Parent
	local result = {Target}
	
	--				Get path					--
	while Parent and Parent ~= game do
		result = {Parent, table.unpack(result)}
		Parent = Parent.Parent
	end
	if result[1] ~= workspace then
		result = {game, table.unpack(result)}
	end

	--				Set mode 					--
	for Index, Object in pairs(result) do
		result[Index] = {
			Object = Object,
			Mode = "Normal"
		}
	end
	return result
end
function PF.PathListToPathString(Current:BaseScript, PathList: PathList): string
	local Path = ""
	for Index, Info in pairs(PathList) do
		if Index == 1 then
			Path = (if Info.Object == workspace then "workspace" else "game")
			
		elseif Index == 2 then
			if PathList[1].Object == game and pcall(game.GetService, game, Info.Object.Name) then
				--			Diferent				--
				local Find = ReplaceLocal[Info.Object.Name]
				if Find and Current:IsA("LocalScript") then			Path ..=  Find continue			end
				Path ..=  (':GetService("%s")'):format(Info.Object.Name)
			else
				Path ..= format(Info.Object.Name, Info.Mode)
			end
			
		else
			Path ..= format(Info.Object.Name, Info.Mode)
			
		end
	end
	return Path
end
function PF.InsertPathString(Current: Script, Target: Instance, PathString: string, Index: number)
	--			Get name			--
	local Name = Target.Name
	Name = table.concat(Name:split(" "), "_")
	if not Name:gsub("_", "b"):match("^%a") then
		Name = "Value" .. Index
	end
	
	--			Place			--
	local Base = (Target:IsA("ModuleScript") and 'local %s = require(%s)\n') or 'local %s = %s\n'
	local Success = pcall(function()
		Current.Source = Base:format(Name, PathString) .. Current.Source
	end)
	if Success then
		game:GetService("ChangeHistoryService"):SetWaypoint("Path to instance")
	else
		warn("Path to instance: needs permission to edit the script.")
	end
end



return PF
