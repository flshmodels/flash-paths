local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Rules = require("../src/Rules")
local count = 0
local function test(name, callback)
    local ok, err = pcall(callback)
    assert(ok, name .. ": " .. tostring(err))
    count += 1
    print("PASS " .. name)
end
local function rejects(callback)
    assert(not pcall(callback), "expected an error")
end
for _, name in ipairs(fs.readDir("src")) do
    if name:match("%.luau$") then luau.compile(fs.readFile("src/" .. name)) end
end


local gameRoot = { Name = "Game", children = {} }
function gameRoot:IsA(class) return class == "DataModel" end
local services = {}
function gameRoot:FindService(class) return services[class] end
function gameRoot:GetService(class) return assert(services[class], "Service unavailable") end
local function object(name, parent, class)
    local node = { Name = name, Parent = parent, ClassName = class or "Folder", children = {}, MaxActivationDistance = 10, HoldDuration = 0, RequiresLineOfSight = true, ActionText = "Use", ObjectText = "Door", Enabled = true }
    function node:IsA(candidate) return candidate == self.ClassName end
    function node:IsDescendantOf(ancestor)
        local cursor = self.Parent
        while cursor do if cursor == ancestor then return true end cursor = cursor.Parent end
        return false
    end
    function node:GetChildren() return self.children end
    function node:GetFullName()
        local names, cursor = {}, self
        while cursor and cursor ~= gameRoot do table.insert(names, 1, cursor.Name) cursor = cursor.Parent end
        return table.concat(names, ".")
    end
    function node:WaitForChild(name, timeout)
        assert(timeout == 10)
        for _, child in ipairs(self.children) do if child.Name == name then return child end end
        return nil
    end
    if parent then table.insert(parent.children, node) end
    return node
end
local world = object("Workspace", gameRoot, "Workspace")
services.Workspace = world
local modules = { Rules = Rules }
if fs.isFile("src/Scope.luau") then
    modules.Scope = luau.load(fs.readFile("src/Scope.luau"), { environment = { game = gameRoot } })()
end
local Scope = modules.Scope
local Adapter = luau.load(fs.readFile("src/Adapter.luau"), { environment = {
    require = function(name) return assert(modules[name]) end,
    script = { Parent = { Rules = "Rules", Scope = "Scope" } }, game = gameRoot,
} })()

test("generated immediate lookup resolves the selected objects", function()
    local folder = object("Assets", world)
    local part = object("A.b", folder, "Part")
    local result = Adapter.generate({ part, folder }, false)
    local resolve = luau.load(result.source, { environment = { game = gameRoot } })()
    local refs = resolve()
    assert(refs[1] == part and refs[2] == folder)
end)
test("wait mode resolves existing children and fails on missing ones", function()
    local folder = object("WaitFolder", world)
    local target = object("Child", folder)
    local result = Adapter.generate({ target }, true)
    local resolve = luau.load(result.source, { environment = { game = gameRoot } })()
    assert(resolve()[1] == target)
    folder.children = {}
    rejects(resolve)
end)
test("names with quotes, backslashes, newlines and Unicode stay literal", function()
    local name = 'quote"\\' .. string.char(10) .. "🍃"
    assert(luau.load("return " .. Rules.quote(name))() == name)
    local target = object(name, world)
    local result = Adapter.generate({ target }, false)
    assert(luau.load(result.source, { environment = { game = gameRoot } })()()[1] == target)
end)
test("duplicate sibling names are refused at generation", function()
    local folder = object("Duplicates", world)
    local target = object("Same", folder) object("Same", folder)
    rejects(function() Adapter.generate({ target }, false) end)
end)
test("new duplicate names also fail when generated code runs", function()
    local folder = object("NewDuplicates", world)
    local target = object("Same", folder)
    local source = Adapter.generate({ target }, false).source
    object("Same", folder)
    rejects(luau.load(source, { environment = { game = gameRoot } })())
end)
test("top-level non-services and detached targets are refused", function()
    rejects(function() Adapter.generate({ object("Detached", nil) }, false) end)
    rejects(function() Adapter.generate({ object("Rogue", gameRoot, "Folder") }, false) end)
    rejects(function() Adapter.generate({}, false) end)
end)
test("services are supported and selection duplicates are omitted", function()
    local result = Adapter.generate({ world, world }, false)
    assert(#result.records == 1 and #result.records[1].names == 0)
    assert(luau.load(result.source, { environment = { game = gameRoot } })()()[1] == world)
end)
test("deep paths and oversized output are refused", function()
    local node = object("Deep", world)
    for index = 1, 65 do node = object("N" .. index, node) end
    rejects(function() Adapter.generate({ node }, false) end)
    local records = {}
    for index = 1, 50 do records[index] = { service = "Workspace", names = { string.rep("x", 2000) } } end
    rejects(function() Rules.generate(records, false) end)
    rejects(function() Rules.quote(string.char(255)) end)
end)

print(string.format("%d checks passed", count))
