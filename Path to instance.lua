	--			Plugin action			--
local Action = plugin:CreatePluginAction(
	"Path to instance",
	"Path to instance",
	"Insert the path to all selected instances.",
	"http://www.roblox.com/asset/?id=7240646192",
	true
)


--				Variables				--
local ReplaceLocal = {
	['game:GetService("StarterGui")'] = 'game:GetService("Players").LocalPlayer.PlayerGui',
	['game:GetService("StarterPack")'] = 'game:GetService("Players").LocalPlayer.Backpack',
}
local function match(Name:string)
	local gsub = Name:gsub("_", "b")
	if gsub:match("%p") or gsub:match("%s") then
		return ('["%s"]'):format(Name)
	else
		return "." .. Name
	end
end



--			Triggered				--
Action.Triggered:Connect(function()
	local Current = game:GetService("StudioService").ActiveScript
	for N, Target in pairs(game:GetService("Selection"):Get()) do		
		--				Get path					--
		local result = {Target}
		local Parent = Target.Parent
		while Parent and Parent ~= game do
			result = {Parent, unpack(result)}
			Parent = Parent.Parent
		end

		--		Path string		--
		local Path = (result[1] == workspace and "workspace") or "game"
		for Index, Obj in pairs(result) do
			if Index == 1 and Obj ~= workspace then
				local Success, Service = pcall(game.GetService, game, Obj.Name)
				if Success and Service ~= nil then
					Path ..=  (':GetService("%s")'):format(Obj.Name)
				else
					Path ..= match(Obj.Name)
				end
			elseif Obj ~= workspace then
				Path ..= match(Obj.Name)
			end
		end



    --    Diferent				--
		if Current:IsA("LocalScript") then
			for Check, Replacement in pairs(ReplaceLocal) do
				local Sub = Path:sub(0, #Check)
				if Sub ~= Check then					continue					end
				Path = Replacement .. string.sub(Path, #Check+1, #Path)
			end
		end


		--				Replace if not valid				--
		local Name = Target.Name
		Name = table.concat(Name:split(" "), "_")
		if Name:gsub("_", "b"):match("%p") then
			Name = "Value" .. N
		end
		

		--			Insert			--
		local Base = (Target:IsA("ModuleScript") and 'local %s = require(%s)\n') or 'local %s = %s\n'
		local Success = pcall(function()
			Current.Source = Base:format(Name, Path) .. Current.Source
		end)
		if Success then
			game:GetService("ChangeHistoryService"):SetWaypoint("Path to instance")
		else
			warn("Path to instance: needs permission to edit the script.")
		end
	end
end)
