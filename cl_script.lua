


local qbcore <const> = exports['qb-core']:GetCoreObject() 
local current = {} 
local cruiserNotification, distance = nil, nil 

local cruiseEnabled, isMicOn, isFishArea = false, false, false --[[@as boolean]]

local function GetVehicleTypeFromEntity(vehicle)
    if IsThisModelABicycle(GetEntityModel(vehicle)) then
        return "bike"
    elseif IsThisModelAPlane(GetEntityModel(vehicle)) or IsThisModelAHeli(GetEntityModel(vehicle)) then
        return "plane"
    elseif IsThisModelABoat(GetEntityModel(vehicle)) then
        return "boat"
   
    elseif GetVehicleHandlingInt(GetVehiclePedIsIn(PlayerPedId(), false), 'CHandlingData', 'nInitialDriveGears') == 1 and IsThisModelACar(GetEntityModel(vehicle)) then
        return "electric"
    else
        return "normal"
    end
end
local function GetVehicleLocked(pVehicle)
    local isAnyDoorOpen = false
    for door = 0, GetNumberOfVehicleDoors(pVehicle) - 1 do
        if GetVehicleDoorAngleRatio(pVehicle, door) > 0.0 then
            isAnyDoorOpen = true
            break
        end
    end
    return isAnyDoorOpen
end

RegisterNetEvent('RespectVehicleMileage:client:updateMelieage', function (mil, plate)
    if current.inVehicle then
        local pPed = PlayerPedId()
        local pVehicle = GetVehiclePedIsIn(pPed, false)

        if plate == GetVehicleNumberPlateText(pVehicle) then
            distance = mil
        end
    end
end)

RegisterNetEvent('RespectSpeedHud:enteredVehicle', function(_distance, unit)
    current.inVehicle = true
    distance = _distance
    CreateThread(function()
        while current.inVehicle do
            Wait(150)
            local pPed = PlayerPedId()
            local pVehicle = GetVehiclePedIsIn(pPed, false)

            if not DoesEntityExist(pVehicle) or IsPedInAnyVehicle(pPed, false) == false then
                SendNUIMessage({
                    type = "closeUI"
                })

                TriggerEvent('RespectSpeedHud:leftVehicle')
                break
            end

            local height = math.max(0, math.floor(GetEntityHeightAboveGround(pVehicle)))
            local heading = GetEntityHeading(pVehicle)
            local velocity = GetEntityVelocity(pVehicle)
            local horizontalSpeed = math.sqrt(velocity.x ^ 2 + velocity.y ^ 2) * 3.6
            local volume = horizontalSpeed * height
            local airChanges, fanModelFactor = 10, 500
            local airSpeed = math.max(0, math.floor((volume * airChanges) / fanModelFactor))
            local engineHealth = math.max(0, math.floor(GetVehicleEngineHealth(pVehicle) / 10))
            local trailer = GetVehicleTrailerVehicle(pVehicle)
            local trailerSize = 99
            

            
            if GetVehicleTypeFromEntity(pVehicle) == 'boat' then
                heading = heading + 180
            else
                heading = heading - 180
            end


            SendNUIMessage({
                type = "openUI",
                info = {
                    vehType = GetVehicleTypeFromEntity(pVehicle),
                    icons = {
                        isCruise = cruiseEnabled,
                        isSeatbelt = false,
                        isLock = GetVehicleLocked(pVehicle),
                        isLight = (GetVehicleDashboardLights() == 128 or GetVehicleDashboardLights() == 256 or GetVehicleDashboardLights() == 260 or GetVehicleDashboardLights() == 384 or GetVehicleDashboardLights() == 320 or GetVehicleDashboardLights() == 323 or GetVehicleDashboardLights() == 321 or GetVehicleDashboardLights() == 322 or GetVehicleDashboardLights() == 324 or GetVehicleDashboardLights() == 325 or GetVehicleDashboardLights() == 326 or GetVehicleDashboardLights() == 327),
                        isFishArea = isFishArea
                    },
                    isPolice = GetVehicleClass(pVehicle) == 18,
                    
                    rotate = heading,
                    progressRpm = math.floor(GetEntitySpeed(pVehicle) * 3.6),
                    progressValue = math.floor(GetVehicleCurrentRpm(pVehicle) * 100),
                    engine = engineHealth,
                    cruise = cruiserNotification,
                    trailer = trailer and trailerSize,
                    speed = math.floor(GetEntitySpeed(pVehicle) * 3.6),
                    gears = GetVehicleCurrentGear(pVehicle),
                    fuel = math.round(exports["LegacyFuel"]:GetFuel(pVehicle)),
                    driving = math.floor(1),
                    height = height,
                    airSpeed = airSpeed
                }
            })


        end
    end)
end)

RegisterNetEvent('RespectSpeedHud:leftVehicle', function()
    local pPed = PlayerPedId()
    local pVehicle = GetVehiclePedIsIn(pPed, true)
    local maxSpeed = GetVehicleHandlingFloat(pVehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
    SetEntityMaxSpeed(pVehicle, maxSpeed)
    cruiseEnabled = false
    
    cruiserNotification = nil
    current.inVehicle = false
    SendNUIMessage({
        type = "closeUI"
    })
end)

RegisterNetEvent('RespectSpeedHud:client:isFishArea', function(boolean)
    
    isFishArea = boolean
end)



RegisterCommand("+activatecruiser", function()
    local ped = PlayerPedId()
    local inVehicle = IsPedSittingInAnyVehicle(ped)
    
    local vehicle = GetVehiclePedIsIn(ped, false)
    local maxSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
    local cruiserSpeed = GetEntitySpeed(vehicle)
    Wait(250)

    if not inVehicle then
        return
    end

    
    if not (GetPedInVehicleSeat(vehicle, -1) == ped) then
        return
    end

    if GetVehicleType(vehicle) ~= "automobile" then
        qbcore.Functions.Notify('متبث السرعة فقط متاح للمركبات', "error", 5000)
        return
    end

    if not cruiseEnabled then
        if math.floor(cruiserSpeed * 3.6 + 0.5) >= 50 then
            SetEntityMaxSpeed(vehicle, cruiserSpeed)
            cruiserNotification = math.floor(cruiserSpeed * 3.6 + 0.5)
            cruiseEnabled = true
        else
            qbcore.Functions.Notify('يمكن تثبيت السرعة على 50 كم/س او اعلى', "error", 5000)
        end
    else
        SetEntityMaxSpeed(vehicle, maxSpeed)
        cruiseEnabled = false
        cruiserNotification = nil
    end
end, false)

RegisterKeyMapping('+activatecruiser', "", 'keyboard', '')

--

Vehicles = {
    [`md902fire`] = true,
}

RegisterCommand("+carMegaphone", function()
    local plyPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(plyPed)
    local class = GetVehicleClass(vehicle)

    if (class == 18 or Vehicles[GetEntityModel(vehicle)]) then
        TriggerServerEvent("tgiann-voice:SetTalkingOnCarMicrophone", true)
        exports["pma-voice"]:overrideProximityRange(80.0, true)
        isMicOn = true
    end
end, false)

RegisterCommand("-carMegaphone", function()
    if isMicOn then
        TriggerServerEvent("tgiann-voice:SetTalkingOnCarMicrophone", false)
        exports["pma-voice"]:clearProximityOverride()
        isMicOn = false
    end
end, false)

Citizen.CreateThread(function()
    local checkFailed = false
    while true do
        Citizen.Wait(0)

        if IsControlPressed(0, 311) then
            if not isMicOn then
                ExecuteCommand("+carMegaphone")
            end
        elseif isMicOn then
            ExecuteCommand("-carMegaphone")
        end
    
        if isMicOn then
            if qbcore.Functions.GetPlayerData().metadata["isdead"] then -- @TODO
                checkFailed = true
                break
            end

            if not checkFailed then
                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
            else
                checkFailed = false
                ExecuteCommand("-carMegaphone")
            end
        end
    end
end)



RegisterNetEvent("rt-crhud:client:anchor")
AddEventHandler("rt-crhud:client:anchor", function()
    if IsPedInAnyVehicle(PlayerPedId(), true) and IsThisModelABoat(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) then
        qbcore.Functions.Progressbar("anchor", "المرساة", 'fa-sharp fa-solid fa-anchor-lock', 1500, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function() -- Done
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleClass = GetVehicleClass(vehicle)
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))
            if not anchored then
                FreezeEntityPosition(vehicle, true)
                SetBoatAnchor(vehicle, true)
            else
                SetBoatAnchor(vehicle, false)
                FreezeEntityPosition(vehicle, false)
            end
            anchored = not anchored
        end)
    else
        qbcore.Functions.Notify('انت مش داخل قارب', "error", 5000)
    end
end)



AddEventHandler('onResourceStart', function(resource)
  
    if resource == "rt-crhud" then
        Citizen.CreateThread(function ()
            while true do
                Citizen.Wait(100)
                
                
                
                TriggerEvent("RespectSpeedHud:enteredVehicle")
        
        
                
            end
        end)
    else
        print("by rt ")
   end
end)
