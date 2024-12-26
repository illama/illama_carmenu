ESX = exports['es_extended']:getSharedObject()

lib.callback.register('illama_carseats:validateSeatChange', function(source, vehicleNetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)

    if not DoesEntityExist(vehicle) then
        return false
    end

    local vehCoords = GetEntityCoords(vehicle)
    local dist = #(playerCoords - vehCoords)

    -- Vérifie que le joueur est dans le même véhicule
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return false
    end

    -- Vérifie la distance
    if dist > Config.MaxDistanceVehicle then
        return false
    end

    return true
end)

-- Configuration
local githubUser = 'illama'
local githubRepo = 'illama_carmenu'

-- Fonction pour récupérer la version locale depuis le fxmanifest
local function GetCurrentVersion()
    local resourceName = GetCurrentResourceName()
    local manifest = LoadResourceFile(resourceName, 'fxmanifest.lua')
    if not manifest then
        return nil
    end
   
    for line in manifest:gmatch("[^\r\n]+") do
        local version = line:match("^version%s+['\"](.+)['\"]")
        if version then
            return version:gsub("%s+", "")
        end
    end
   
    return nil
end

-- Fonction pour vérifier la version
local function CheckVersion()
    local currentVersion = GetCurrentVersion()
    if not currentVersion then
        print(_L('version_read_error'))
        return
    end

    PerformHttpRequest(
        ('https://api.github.com/repos/%s/%s/releases/latest'):format(githubUser, githubRepo),
        function(err, text, headers)
            if err ~= 200 then
                print(_L('github_check_error'))
                return
            end
           
            local data = json.decode(text)
            if not data or not data.tag_name then
                print(_L('github_version_read_error'))
                return
            end
           
            local latestVersion = data.tag_name:gsub("^v", "")
           
            if latestVersion ~= currentVersion then
                print(_L('new_version_available'))
                print(_L('current_version', currentVersion))
                print(_L('latest_version', latestVersion))
                print(_L('release_notes', data.html_url or 'N/A'))
                if data.body then
                    print(_L('changes_list', data.body))
                end
            else
                print(_L('script_up_to_date', currentVersion))
            end
        end,
        'GET',
        '',
        {['User-Agent'] = 'FXServer-'..githubUser}
    )
end

-- Vérifier la version au démarrage
CreateThread(function()
    Wait(5000)
    CheckVersion()
end)