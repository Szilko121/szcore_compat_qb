local QBCore = { Functions = {}, PlayerData = {} }

local function qbData(d)
    if not d or not d.citizenid then return {} end
    return {
        source = d.source,
        citizenid = d.citizenid,
        name = d.name,
        charinfo = d.charinfo,
        money = d.money,
        metadata = d.metadata,
        position = d.position,
        job = d.job and {
            name = d.job.name,
            label = d.job.label,
            type = d.job.type,
            onduty = d.job.onduty,
            payment = d.job.salary,
            isboss = d.job.boss,
            grade = { name = d.job.gradeName, level = d.job.grade }
        } or {},
        gang = d.gang,
        items = {}
    }
end

function QBCore.Functions.GetPlayerData()
    QBCore.PlayerData = qbData(exports.szcore:GetPlayerData())
    return QBCore.PlayerData
end
function QBCore.Functions.TriggerCallback(name, cb, ...)
    exports.szcore:TriggerCallback(name, function(ok, ...)
        if ok then cb(...) else cb(nil) end
    end, ...)
end
function QBCore.Functions.Notify(text,typ,length)
    if GetResourceState('szcore_ui')=='started' then
        exports.szcore_ui:Notify({description=tostring(text),type=typ or 'info',duration=length or 3500});return
    end
    BeginTextCommandThefeedPost('STRING');AddTextComponentSubstringPlayerName(tostring(text));EndTextCommandThefeedPostTicker(false,false)
end

AddEventHandler('szcore:client:onPlayerLoaded', function(data)
    QBCore.PlayerData = qbData(data)
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
end)
AddEventHandler('szcore:client:onPlayerUnloaded', function()
    QBCore.PlayerData = {}
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)
AddEventHandler('szcore:client:onPlayerData', function(path)
    QBCore.PlayerData = qbData(exports.szcore:GetPlayerData())
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
    if path == 'job' then TriggerEvent('QBCore:Client:OnJobUpdate', QBCore.PlayerData.job) end
    if path:sub(1, 6) == 'money.' then
        local account = path:sub(7)
        TriggerEvent('QBCore:Client:OnMoneyChange', account, QBCore.PlayerData.money[account])
    end
end)

exports('GetCoreObject', function() return QBCore end)
