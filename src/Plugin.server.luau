if not plugin then return end
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local Ui = require(script.Ui)
local Adapter = require(script.Adapter)
local panel = Ui.new(plugin, "FlashPaths", "Flash Paths", "Paths")
panel.label("Generate an explicit lookup module for the selection. Names are escaped; ambiguous sibling names are refused. No scripts are read, inserted or executed.")
local output
local status
local function clear()
    if output then output.Text = "" end
    if status then status.Text = "Selection or options changed. Generate again." end
end
local mode = panel.cycle("Lookup", { "Immediate", "Wait (10 seconds per hop)" }, clear)
status = panel.label("Select up to 50 objects. The result array follows the selection snapshot order.")
panel.button("Generate lookup module", function()
    clear()
    if RunService:IsRunning() then status.Text = "Stop the play test first." return end
    local ok, result = pcall(Adapter.generate, Selection:Get(), mode() ~= "Immediate")
    if not ok then status.Text = tostring(result) return end
    local names = {}
    for index, record in ipairs(result.records) do table.insert(names, tostring(index) .. ": " .. record.path) end
    status.Text = table.concat(names, "\n") .. "\nCopy the module below. Resolve it in a context where these services and objects are available."
    output.Text = result.source
end)
output = panel.field("Generated Luau (select and copy)", "")
output.MultiLine = true
output.TextEditable = false
output.ClearTextOnFocus = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 13
output.Size = UDim2.new(1, 0, 0, 400)
local connection = Selection.SelectionChanged:Connect(clear)
plugin.Unloading:Connect(function() connection:Disconnect() panel.destroy() end)
