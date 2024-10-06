local p: Plugin, Frame: typeof(script.Parent.Frame), Tween: TweenBase
local Info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local TextColor = {["Error"] = Color3.fromRGB(255, 147, 53), ["Success"] = Color3.fromRGB(146, 255, 140)}
local Index = 0
local function Display(Type: "Success"|"Error", Base: string, ...)
	Index = (Index%10 + 1)
	
	local List, N = {...}, Index
	local Text = {
		(if Type == "Error" then "Error: " else ""),
		Base,
		(if #List > 0 then (" - (%s)"):format(table.concat(List, ", ")) else "")
	}
	Tween:Cancel()
	
	--		Set properties		--
	Frame.ErrorFrame.TL.TextTransparency = 0
	Frame.ErrorFrame.TL.TextColor3 = TextColor[Type]
	Frame.ErrorFrame.TL.Text = table.concat(Text)
	
	--		Tween		--
	task.delay(1, function()
		if Index == N then		Tween:Play()		end
	end)
end



--		Module		--
local M = {}
function M.Get(key: string, default: any)
	local success, value = pcall(p.GetSetting, p, key)
	if not success then		Display("Error", "Get_"..key, value)	end
	return ((if success then value else nil) or default)
end
function M.Set(key: string, save: any)
	local success, Error = pcall(p.SetSetting, p, key, save)
	if not success then		Display("Error", "Set_"..key, Error)	end
	return success
end
function M.Update(Key: string, Do: ({[string]: any}) -> ())
	local Current = M.Get(Key, {})
	Do(Current)

	--		Save		--
	M.Set(Key, Current)
	return true
end



--		Return		--
export type InfoType = {Name: string, Source: string}
return function(pluginObj: Plugin, F: typeof(script.Parent.Frame))
	p, Frame = pluginObj, F
	Tween = game:GetService("TweenService"):Create(F.ErrorFrame.TL, Info, {["TextTransparency"] = 1})
	return M, Display
end
