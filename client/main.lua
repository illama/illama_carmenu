ESX = exports['es_extended']:getSharedObject()
local currentLang = Locales['fr']

-- Fonctions utilitaires existantes
local function IsSeatbeltOn()
    return exports['esx_cruisecontrol']:isSeatbeltOn()
end

local function GetDefaultFrenchSeatName(seat)
    if seat == -1 then
        return "Siège avant gauche (Conducteur)"
    elseif seat == 0 then
        return "Siège avant droit (Passager avant)"
    elseif seat == 1 then
        return "Siège arrière gauche"
    elseif seat == 2 then
        return "Siège arrière droit"
    else
        return "Siège #" .. tostring(seat)
    end
end

local function GetFrenchSeatNameForVehicle(vehicle, seat)
    local model = GetEntityModel(vehicle)
    local seatNamesForModel = Config.VehicleSeatNames[model]
    if seatNamesForModel and seatNamesForModel[seat] then
        return seatNamesForModel[seat]
    else
        return GetDefaultFrenchSeatName(seat)
    end
end

local function GetDoorOptions(vehicle)
    local options = {}
    local processedDoors = {}
    local model = GetEntityModel(vehicle)
    
    -- Fonction pour ajouter une porte de manière sécurisée
    local function addDoorOption(index, title)
        if not processedDoors[index] and DoesVehicleHaveDoor(vehicle, index) then
            local doorState = GetVehicleDoorAngleRatio(vehicle, index) > 0
            table.insert(options, {
                title = title,
                description = doorState and "Fermer" or "Ouvrir",
                event = 'illama_carseats:toggleDoor',
                args = {vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle), doorIndex = index}
            })
            processedDoors[index] = true
        end
    end

    -- Ajouter d'abord le capot et le coffre
    if DoesVehicleHaveDoor(vehicle, 4) then
        addDoorOption(4, "Capot")
        processedDoors[4] = true
    end
    
    if DoesVehicleHaveDoor(vehicle, 5) then
        addDoorOption(5, "Coffre")
        processedDoors[5] = true
    end
    
    -- Ensuite ajouter les portes passagers
    addDoorOption(0, "Porte avant gauche")
    addDoorOption(1, "Porte avant droite")
    addDoorOption(2, "Porte arrière gauche")
    addDoorOption(3, "Porte arrière droite")
    
    return options
end

-- Fonction pour obtenir les options de sièges
local function GetSeatOptions(vehicle)
    local options = {}
    local playerPed = PlayerPedId()
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    
    -- Identifier le siège actuel du joueur
    local playerSeat = nil
    for seat = -1, maxSeats - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == playerPed then
            playerSeat = seat
            break
        end
    end
    
    for seat = -1, maxSeats - 1 do
        if seat ~= playerSeat then
            local occupant = GetPedInVehicleSeat(vehicle, seat)
            local seatName = GetFrenchSeatNameForVehicle(vehicle, seat)
            if occupant ~= 0 and occupant ~= playerPed then
                table.insert(options, {
                    title = seatName .. " (Occupé)",
                    description = "Ce siège est déjà pris",
                    disabled = true
                })
            else
                if IsVehicleSeatFree(vehicle, seat) then
                    table.insert(options, {
                        title = seatName,
                        event = 'illama_carseats:initiateSeatChange',
                        args = {vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle), seat = seat}
                    })
                end
            end
        end
    end
    
    return options
end

-- Fonction pour vérifier si le véhicule a des néons installés
local function HasVehicleNeons(vehicle)
    local hasNeon = false
    for i = 0, 3 do
        -- Si au moins un des néons a une couleur définie, c'est que le véhicule a des néons
        local r, g, b = GetVehicleNeonLightsColour(vehicle)
        if r ~= 0 or g ~= 0 or b ~= 0 then
            hasNeon = true
            break
        end
    end
    return hasNeon
end

-- Fonction pour obtenir les options des lumières
local function GetLightOptions(vehicle)
    local options = {}
    local _, lightsOn, highBeamsOn = GetVehicleLightsState(vehicle)
    
    table.insert(options, {
        title = "Phares principaux",
        description = lightsOn == 1 and "Éteindre" or "Allumer",
        event = 'illama_carseats:toggleLights',
        args = {vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle), lightType = "main"}
    })
    
    table.insert(options, {
        title = "Pleins phares",
        description = highBeamsOn == 1 and "Éteindre" or "Allumer",
        event = 'illama_carseats:toggleLights',
        args = {vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle), lightType = "high"}
    })

    -- N'affiche l'option néon que si le véhicule a réellement des néons installés
    if HasVehicleNeons(vehicle) then
        local neonState = false
        for i = 0, 3 do
            if IsVehicleNeonLightEnabled(vehicle, i) then
                neonState = true
                break
            end
        end

        table.insert(options, {
            title = "Néons",
            description = neonState and "Éteindre" or "Allumer",
            event = 'illama_carseats:toggleLights',
            args = {vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle), lightType = "neon"}
        })
    end
    
    return options
end

-- Modifier l'event de toggle des lumières
RegisterNetEvent('illama_carseats:toggleLights')
AddEventHandler('illama_carseats:toggleLights', function(data)
    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    
    local _, lightsOn, highBeamsOn = GetVehicleLightsState(vehicle)
    
    if data.lightType == "main" then
        SetVehicleLights(vehicle, lightsOn == 1 and 1 or 2)
    elseif data.lightType == "high" then
        if highBeamsOn == 1 then
            SetVehicleLights(vehicle, 2)  -- Mode normal
        else
            SetVehicleLights(vehicle, 3)  -- Mode pleins phares
        end
    elseif data.lightType == "neon" then
        -- Vérifie si au moins un néon est allumé
        local neonState = false
        for i = 0, 3 do
            if IsVehicleNeonLightEnabled(vehicle, i) then
                neonState = true
                break
            end
        end
        
        -- Toggle tous les néons
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, not neonState)
        end
    end
end)

-- Events pour le menu principal
RegisterNetEvent('illama_carseats:openMainMenu')
AddEventHandler('illama_carseats:openMainMenu', function(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        ESX.ShowNotification(currentLang['in_vehicle_only'])
        return
    end
    
    -- Options du menu principal
    local mainOptions = {
        {
            title = "Changement de siège",
            description = "Changer de place dans le véhicule",
            menu = 'illama_carseats_seats'
        },
        {
            title = "Gestion des portes",
            description = "Ouvrir/Fermer les portes, le coffre et le capot",
            menu = 'illama_carseats_doors'
        },
        {
            title = "Gestion des lumières",
            description = "Contrôler les phares et les LED",
            menu = 'illama_carseats_lights'
        }
    }
    
    -- Enregistrer les sous-menus
    lib.registerContext({
        id = 'illama_carseats_main',
        title = 'Contrôles du véhicule',
        options = mainOptions
    })
    
    lib.registerContext({
        id = 'illama_carseats_seats',
        title = 'Changement de siège',
        menu = 'illama_carseats_main',
        options = GetSeatOptions(vehicle)
    })
    
    lib.registerContext({
        id = 'illama_carseats_doors',
        title = 'Gestion des portes',
        menu = 'illama_carseats_main',
        options = GetDoorOptions(vehicle)
    })
    
    lib.registerContext({
        id = 'illama_carseats_lights',
        title = 'Gestion des lumières',
        menu = 'illama_carseats_main',
        options = GetLightOptions(vehicle)
    })
    
    lib.showContext('illama_carseats_main')
end)

-- Events pour les actions
RegisterNetEvent('illama_carseats:toggleDoor')
AddEventHandler('illama_carseats:toggleDoor', function(data)
    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    
    local doorState = GetVehicleDoorAngleRatio(vehicle, data.doorIndex) > 0
    if doorState then
        SetVehicleDoorShut(vehicle, data.doorIndex, false)
    else
        SetVehicleDoorOpen(vehicle, data.doorIndex, false, false)
    end
end)


-- Event pour le changement de siège
RegisterNetEvent('illama_carseats:initiateSeatChange')
AddEventHandler('illama_carseats:initiateSeatChange', function(data)
    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    local seat = data.seat
    local playerPed = PlayerPedId()

    -- Vérifications initiales
    if not DoesEntityExist(vehicle) or not IsPedInAnyVehicle(playerPed, false) then
        ESX.ShowNotification(currentLang['in_vehicle_only'])
        return
    end

    if IsSeatbeltOn() then
        ESX.ShowNotification(currentLang['seatbelt_on'])
        return
    end

    lib.callback('illama_carseats:validateSeatChange', false, function(canChange)
        if canChange then
            -- Vérifie si le véhicule est en mouvement
            local speed = GetEntitySpeed(vehicle)
            local isMoving = speed > 0.1 -- 0.1 est un seuil très bas pour détecter le mouvement
            local delay = isMoving and 10000 or 5000 -- 10 secondes si en mouvement, 5 secondes si arrêté

            -- Démarre la barre de progression
            if lib.progressCircle({
                duration = delay,
                label = 'Changement de siège...',
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = false,
                    move = false,
                    combat = true,
                    mouse = false
                },
            }) then
                -- Si la progression est terminée avec succès
                SetPedIntoVehicle(playerPed, vehicle, seat)
            else
                -- Si la progression a été annulée
                ESX.ShowNotification('Changement de siège annulé')
            end
        else
            ESX.ShowNotification(currentLang['not_in_vehicle'])
        end
    end, data.vehicleNetId)
end)

-- Garder une seule définition du keymapping et de la commande
RegisterCommand('vehicle_control_menu', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 then
        -- Options du menu principal
        local mainOptions = {
            {
                title = "Changement de siège",
                description = "Changer de place dans le véhicule",
                menu = 'illama_carseats_seats'
            },
            {
                title = "Gestion des portes",
                description = "Ouvrir/Fermer les portes, le coffre et le capot",
                menu = 'illama_carseats_doors'
            },
            {
                title = "Gestion des lumières",
                description = "Contrôler les phares et les LED",
                menu = 'illama_carseats_lights'
            }
        }
        
        -- Enregistrer les sous-menus
        lib.registerContext({
            id = 'illama_carseats_main',
            title = 'Contrôles du véhicule',
            options = mainOptions,
            closeOnClick = false,
            keepInput = true
        })
        
        lib.registerContext({
            id = 'illama_carseats_seats',
            title = 'Changement de siège',
            menu = 'illama_carseats_main',
            options = GetSeatOptions(vehicle),
            closeOnClick = false,
            keepInput = true
        })
        
        lib.registerContext({
            id = 'illama_carseats_doors',
            title = 'Gestion des portes',
            menu = 'illama_carseats_main',
            options = GetDoorOptions(vehicle),
            closeOnClick = false,
            keepInput = true
        })
        
        lib.registerContext({
            id = 'illama_carseats_lights',
            title = 'Gestion des lumières',
            menu = 'illama_carseats_main',
            options = GetLightOptions(vehicle),
            closeOnClick = false,
            keepInput = true
        })
        
        lib.showContext('illama_carseats_main')
    else
        ESX.ShowNotification(currentLang['in_vehicle_only'])
    end
end, false)

RegisterKeyMapping('vehicle_control_menu', 'Ouvrir le menu de contrôle du véhicule', 'keyboard', 'F4')
-- Thread pour empêcher le passage automatique au siège conducteur
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            SetPedConfigFlag(ped, 184, true)
        else
            SetPedConfigFlag(ped, 184, false)
        end
        Wait(1000)
    end
end)