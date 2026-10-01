local function sharedJobs()
    local out = {}
    for name, job in pairs(SzCoreJobs or {}) do
        local grades = {}
        for level, grade in pairs(job.grades or {}) do
            grades[tostring(level)] = { name = grade.name, payment = grade.salary or 0, isboss = grade.boss == true }
        end
        out[name] = { label = job.label, type = job.type, defaultDuty = job.defaultDuty == true, offDutyPay = false, grades = grades }
    end
    return out
end

local function sharedItems()
    local out={};for name,item in pairs(SzCoreItems or {}) do out[name]={name=name,label=item.label,weight=item.weight or 0,type=item.weapon and 'weapon' or 'item',image=item.image or (name..'.png'),unique=item.stack==false,useable=item.usable==true,shouldClose=item.close==true,description=item.description or ''} end;return out
end
local function sharedVehicles()
    local out={};for model,v in pairs(SzCoreVehicles or {}) do out[model]={name=v.label,brand=v.brand,model=model,price=v.price or 0,category=v.category or 'misc',hash=joaat(model),shop=v.shop or 'pdm'} end;return out
end
local QBCore = { Functions = {}, Shared = { Jobs = sharedJobs(), Items=sharedItems(), Vehicles=sharedVehicles(), Gangs=SzCoreGangs or {} } }
local wrappers = {}

local function qbData(player)
    player=exports.szcore:GetPlayer(player.PlayerData.source) or player
    local d = player.PlayerData
    return {
        source = d.source, citizenid = d.citizenid, license = d.license, name = d.name,
        charinfo = d.charinfo, money = d.money, metadata = d.metadata, position = d.position,
        job = {name=d.job.name,label=d.job.label,type=d.job.type,onduty=d.job.onduty,payment=d.job.salary,isboss=d.job.boss,grade={name=d.job.gradeName,level=d.job.grade}},
        gang = d.gang,
        items = (function()local out={};if GetResourceState('szcore_inventory')=='started' then local inv=exports.szcore_inventory:GetPlayerInventory(d.source);for slot,e in pairs(inv and inv.items or {})do out[slot]={name=e.name,amount=e.amount,info=e.metadata,slot=slot}end end;return out end)()
    }
end

local function wrap(player)
    if not player then return nil end
    local src = player.PlayerData.source
    local cached = wrappers[src]
    if cached and cached._citizenid==player.PlayerData.citizenid then return cached end
    local functions = {}
    functions.AddMoney = function(account, amount, reason) return player.addMoney(account, amount, reason) end
    functions.RemoveMoney = function(account, amount, reason) return player.removeMoney(account, amount, reason) end
    functions.SetMoney = function(account, amount, reason) return player.setMoney(account, amount, reason) end
    functions.SetJob = function(job, grade) return player.setJob(job, grade) end
    functions.SetJobDuty = function(duty) return player.setDuty(duty) end
    functions.SetMetaData = function(key, value) return player.setMetadata(key, value) end
    functions.GetMetaData = function(key) return player.getMetadata(key) end
    functions.GetMoney = function(account) return player.getMoney(account) end
    functions.Save = function() return player.save(true) end
    functions.AddItem = function(item,amount,slot,info)
        if GetResourceState('szcore_inventory')~='started' then return false end
        local inv=exports.szcore_inventory:GetPlayerInventory(src);return inv and exports.szcore_inventory:AddItem(inv.inventory_id,item,amount,info,slot) or false
    end
    functions.RemoveItem = function(item,amount,slot)
        if GetResourceState('szcore_inventory')~='started' then return false end
        local inv=exports.szcore_inventory:GetPlayerInventory(src);return inv and exports.szcore_inventory:RemoveItem(inv.inventory_id,item,amount) or false
    end
    functions.GetItemByName = function(item)
        if GetResourceState('szcore_inventory')~='started' then return nil end
        local inv=exports.szcore_inventory:GetPlayerInventory(src);if not inv then return nil end
        for slot,e in pairs(inv.items or {}) do if e.name==item then return {name=e.name,amount=e.amount,info=e.metadata,slot=slot} end end
    end

    cached = setmetatable({ Functions = functions }, {__index = function(_, key) if key == 'PlayerData' then return qbData(player) end end})
    cached._citizenid=player.PlayerData.citizenid
    wrappers[src] = cached
    return cached
end

function QBCore.Functions.GetPlayer(source) return wrap(exports.szcore:GetPlayer(source)) end
function QBCore.Functions.GetPlayerByCitizenId(citizenid) return wrap(exports.szcore:GetPlayerByCitizenId(citizenid)) end
function QBCore.Functions.GetQBPlayers()
    local out = {}
    for _, id in ipairs(GetPlayers()) do local src=tonumber(id);local p=exports.szcore:GetPlayer(src);if p then out[src]=wrap(p) end end
    return out
end
function QBCore.Functions.GetPlayersOnDuty(job) local ids=exports.szcore:GetPlayerSourcesByJob(job,true);return ids,#ids end
function QBCore.Functions.HasPermission(source, permission)
    if permission == 'admin' or permission == 'god' then return exports.szcore:IsAdmin(source) end
    return IsPlayerAceAllowed(tostring(source), tostring(permission))
end
function QBCore.Functions.CreateUseableItem(item,cb)
    if GetResourceState('szcore_inventory')=='started' then
        exports.szcore_inventory:RegisterUsableItem(item,function(source,entry,slot) cb(source,{name=entry.name,amount=entry.amount,info=entry.metadata,slot=slot}) end)
    end
end
function QBCore.Functions.CreateCallback(name, cb)
    exports.szcore:CreateCallback(name, function(source, ...)
        local p = promise.new();local resolved=false
        SetTimeout(15000,function()if not resolved then resolved=true;p:resolve({})end end)
        cb(source, function(...) if not resolved then resolved=true;p:resolve({ ... })end end, ...)
        return table.unpack(Citizen.Await(p))
    end)
end

AddEventHandler('szcore:server:playerLoaded', function(source, player) TriggerEvent('QBCore:Server:PlayerLoaded', wrap(player)) end)
AddEventHandler('szcore:server:playerUnloaded', function(source) wrappers[source] = nil;TriggerEvent('QBCore:Server:OnPlayerUnload', source) end)
AddEventHandler('szcore:server:jobChanged', function(source, job)
    local p = exports.szcore:GetPlayer(source);TriggerEvent('QBCore:Server:OnJobUpdate', source, p and qbData(p).job or job)
end)
AddEventHandler('szcore:server:dutyChanged', function(source, duty) TriggerEvent('QBCore:Server:SetDuty', source, duty) end)

exports('GetCoreObject', function() return QBCore end)
AddEventHandler('playerDropped',function()wrappers[source]=nil end)
