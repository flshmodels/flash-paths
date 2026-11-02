local Rules = require(script.Parent.Rules)
local Adapter = {}

function Adapter.generate(selection, waitForChildren)
    assert(#selection > 0 and #selection <= 50, "Select between 1 and 50 objects.")
    local records, seen, checkedParents = {}, {}, {}
    local inspected = 0
    for _, target in ipairs(selection) do
        if not seen[target] then
            assert(target:IsDescendantOf(game), "Selection contains a detached object or the DataModel root.")
            seen[target] = true
            local names, cursor = {}, target
            while cursor.Parent ~= game do
                assert(cursor.Parent and #names < 64, "Path is detached or exceeds 64 child hops.")
                local parent = cursor.Parent
                if not checkedParents[parent] then
                    local children = parent:GetChildren()
                    assert(#children <= 10000, "A parent has more than 10000 children.")
                    inspected += #children
                    assert(inspected <= 100000, "More than 100000 sibling entries inspected. Select a smaller scope.")
                    local counts = {}
                    for _, child in ipairs(children) do counts[child.Name] = (counts[child.Name] or 0) + 1 end
                    checkedParents[parent] = counts
                end
                assert(checkedParents[parent][cursor.Name] == 1, "Ambiguous sibling name: " .. cursor.Name)
                table.insert(names, 1, cursor.Name)
                cursor = parent
            end
            assert(game:FindService(cursor.ClassName) == cursor, "Top-level ancestor is not a registered service.")
            table.insert(records, { service = cursor.ClassName, names = names, path = target:GetFullName(), target = target })
        end
    end
    -- Selection order is preserved so the returned array matches the numbered preview.
    return { records = records, source = Rules.generate(records, waitForChildren) }
end

return Adapter
