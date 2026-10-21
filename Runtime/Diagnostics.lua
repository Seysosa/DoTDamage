local Diagnostics = {}
local RELEASE = "0.6.0-alpha.22"

function Diagnostics.create(env, addonName)
    local diagnostic = {}
    local store = { schema = 1, release = RELEASE, errors = {} }
    local snapshot, observer = function() return {} end, nil
    local capturing, reporting, observing = false, false, false
    local windowStart, windowErrors = nil, 0
    local function hidden(value)
        if type(env.issecretvalue) ~= "function" then return false end
        local ok, result = pcall(env.issecretvalue, value)
        return not ok or result ~= false
    end
    local function clean(value, depth, seen, budget)
        if hidden(value) then return "<restricted>" end
        local kind = type(value)
        if kind == "string" then return value:sub(1, 4096) end
        if kind == "boolean" then return value end
        if kind == "number" then if value == value and math.abs(value) < 1000000000000000 then return value end; return "<invalid>" end
        if kind == "nil" then return nil end
        if kind ~= "table" then return "<unsupported>" end
        if depth >= 5 or seen[value] or budget.count >= 512 then return "<limited>" end
        seen[value] = true
        local copy = {}
        pcall(function()
            for key, item in pairs(value) do
                if budget.count >= 512 then break end
                local validKey = not hidden(key) and (type(key) == "string" and #key <= 160
                    or type(key) == "number" and key == key and math.abs(key) < 1000000000000000)
                if validKey then
                    budget.count = budget.count + 1
                    copy[key] = clean(item, depth + 1, seen, budget)
                end
            end
        end)
        seen[value] = nil
        return copy
    end
    local function sanitize(value) return clean(value, 0, {}, { count = 0 }) end
    local function context()
        local ok, result = pcall(snapshot)
        return ok and sanitize(result) or { unavailable = true }
    end
    function diagnostic.bind(saved)
        if type(saved) == "table" and not hidden(saved) then
            store = { schema = 1, release = RELEASE, errors = {} }
            local previous = saved.errors
            if type(previous) == "table" and not hidden(previous) then
                for index = math.max(1, #previous - 7), #previous do
                    local error = previous[index]
                    if type(error) == "table" and not hidden(error) then
                        store.errors[#store.errors + 1] = {
                            kind = sanitize(error.kind), message = sanitize(error.message),
                            stack = sanitize(error.stack), count = sanitize(error.count),
                        }
                    end
                end
            end
            if type(saved.firstError) == "table" and not hidden(saved.firstError) then store.firstError = saved.firstError end
            if type(saved.manual) == "table" and not hidden(saved.manual) then store.manual = saved.manual end
        end
        return store
    end
    function diagnostic.setSnapshot(fn) snapshot = fn end
    function diagnostic.capture(kind, message)
        if capturing then return end
        capturing = true
        local ok = pcall(function()
        local text = sanitize(message)
        if type(text) ~= "string" then text = "<unreadable error>" end
        for _, error in ipairs(store.errors) do
            if type(error) == "table" and error.message == text and error.kind == kind then
                error.count = type(error.count) == "number" and math.min(error.count + 1, 1000000) or 1; return
            end
        end
        local now
        if type(env.GetTime) == "function" then
            local good, value = pcall(env.GetTime)
            if good and not hidden(value) and type(value) == "number" then now = value end
        end
        if now and (not windowStart or now - windowStart >= 5) then windowStart, windowErrors = now, 0 end
        if windowErrors >= 8 then
            store.suppressedErrors = math.min((store.suppressedErrors or 0) + 1, 1000000)
            return
        end
        windowErrors = windowErrors + 1
        local trace
        if type(env.debugstack) == "function" then local ok, value = pcall(env.debugstack, 2); if ok then trace = sanitize(value) end end
        local error = { kind = kind, message = text, stack = trace, count = 1,
            context = { unavailable = true, reason = "error_capture_does_not_run_tracking" } }
        if not store.firstError then store.firstError = error end
        store.errors[#store.errors + 1] = error
        if #store.errors > 8 then table.remove(store.errors, 1) end
        end)
        capturing = false
        return ok
    end
    function diagnostic.run(label, fn)
        return xpcall(fn, function(reason) diagnostic.capture(label, reason); return reason end)
    end
    function diagnostic.report()
        if reporting then return nil end
        reporting = true
        local ok, current = false, nil
        if type(env.geterrorhandler) == "function" then ok, current = pcall(env.geterrorhandler) end
        store.manual = { release = RELEASE, context = context(), observerActive = ok and current == observer and observer ~= nil }
        reporting = false
        return store.manual
    end
    function diagnostic.observeErrors()
        if type(env.geterrorhandler) ~= "function" or type(env.seterrorhandler) ~= "function" then return false end
        local ok, prior = pcall(env.geterrorhandler)
        if not ok or type(prior) ~= "function" then return false end
        if prior == observer then return true end
        observer = function(message)
            if observing then return end
            observing = true
            if not hidden(message) and type(message) == "string" and message:gsub("\\", "/"):find("AddOns/" .. addonName .. "/", 1, true) then
                pcall(diagnostic.capture, "lua", message)
            end
            local success, result = pcall(prior, message)
            observing = false
            if success then return result end
        end
        return pcall(env.seterrorhandler, observer)
    end
    function diagnostic.store() return store end
    return diagnostic
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Diagnostics = Diagnostics end
return Diagnostics
