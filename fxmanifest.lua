fx_version 'cerulean'
game 'gta5'

author 'SzCode / SzCore'
description 'SzCore compatibility shim for common QBCore APIs'
version '1.4.0-rc1'

shared_scripts {'@szcore/shared/jobs.lua','@szcore/shared/gangs.lua','@szcore/shared/items.lua','@szcore/shared/vehicles.lua'}
client_script 'client/main.lua'
server_script 'server/main.lua'
dependency 'szcore'
