_SafeCrackingStates = "Setup"
_onSpot             = false
_try                = 0
isMinigame          = false

function createSafe(combination) 
    RequestStreamedTextureDict( "MPSafeCracking", false )
    RequestAmbientAudioBank( "SAFE_CRACK", false )
    local res
    isMinigame = not isMinigame
    if isMinigame then        
        InitializeSafe(combination)
        playFx("mini@safe_cracking", "idle_base")
        while isMinigame do
            FreezeEntityPosition(PlayerPedId(), true)
            DrawSprites(true)
            res = RunMiniGame()
            
            if res == true then
                return res
            elseif res == false then
                return res
            end
        
            Citizen.Wait(0)
        end
        
    else
        FreezeEntityPosition(PlayerPedId(), false)
    end
end

function InitializeSafe(safeCombination)
    _initDialRotationDirection = "Clockwise"
    _safeCombination = safeCombination

    RelockSafe()
    SetSafeDialStartNumber()
end

function DrawSprites(drawLocks)
    local textureDict = "MPSafeCracking"
    local _aspectRatio = GetAspectRatio( true )
    
    DrawSprite( textureDict, "Dial_BG", 0.48, 0.3, 0.3, _aspectRatio * 0.3, 0, 255, 255, 255, 255 )
    DrawSprite( textureDict, "Dial", 0.48, 0.3, 0.3 * 0.5, _aspectRatio * 0.3 * 0.5, SafeDialRotation, 255, 255, 255, 255 )

    if not drawLocks then
        return
    end

    local xPos = 0.6
    local yPos = (0.3 * 0.5) + 0.035
    for _,lockActive in pairs(_safeLockStatus) do
        local lockString
        if lockActive then
            lockString = "lock_closed"
        else
            lockString = "lock_open"
        end
            
        DrawSprite( textureDict, lockString, xPos, yPos, 0.025, _aspectRatio * 0.015, 0, 231, 194, 81, 255 )
        yPos = yPos + 0.05
    end
end

function RunMiniGame()
    if _SafeCrackingStates == "Setup" then
        

        _SafeCrackingStates = "Cracking"
    elseif _SafeCrackingStates == "Cracking" then
        local isDead = GetEntityHealth(PlayerPedId()) <= 100
        if isDead then
            EndMiniGame(false)
            return false
        end

        if IsControlJustPressed( 0, 33 ) then
            EndMiniGame(false)
            return false
        end

        if IsControlJustPressed( 0, 32 ) then
            if _onSpot then
                ReleaseCurrentPin()
                _onSpot = false
                if IsSafeUnlocked() then
                    EndMiniGame( true, false )
                    return true
                end
            else
                print(_try)
                if _try >= 3 then
                    EndMiniGame(false)
                    return false
                else
                    _try = _try + 1
                    PlaySoundFrontend(0, "TUMBLER_RESET", "SAFE_CRACK_SOUNDSET", true )
                end
            end
        end

        HandleSafeDialMovement()

        local incorrectMovement = _currentLockNum ~= 0 and
            _requiredDialRotationDirection ~= "Idle" and
            _currentDialRotationDirection ~= "Idle" and
            _currentDialRotationDirection ~= _requiredDialRotationDirection

        if not incorrectMovement then
            local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
            local correctMovement = _requiredDialRotationDirection ~= "Idle" and
                                  (_currentDialRotationDirection == _requiredDialRotationDirection or
                                   _lastDialRotationDirection == _requiredDialRotationDirection)
            
            if correctMovement then
                local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
                if pinUnlocked then
                    PlaySoundFrontend(0, "TUMBLER_PIN_FALL", "SAFE_CRACK_SOUNDSET", true )
                    _onSpot = true
                end
            end
        end
    end
end

function HandleSafeDialMovement()                
    if IsControlJustPressed( 0, 34 ) then
        RotateSafeDial("Anticlockwise")
    elseif IsControlJustPressed( 0, 35 ) then
        RotateSafeDial("Clockwise")
    else
        RotateSafeDial("Idle")
    end
end

function RotateSafeDial(rotationDirection)
    
    if rotationDirection == "Anticlockwise" or rotationDirection == "Clockwise" then
        local rotationPerNumber = 3.6
        local multiplier
        if rotationDirection == "Anticlockwise" then
            multiplier = 1
        elseif rotationDirection == "Clockwise" then
            multiplier = -1
        end
        local rotationChange = multiplier * rotationPerNumber
        SafeDialRotation = SafeDialRotation + rotationChange
        PlaySoundFrontend( 0, "TUMBLER_TURN", "SAFE_CRACK_SOUNDSET", true )
    end

    _currentDialRotationDirection = rotationDirection
    _lastDialRotationDirection = rotationDirection
end

function SetSafeDialStartNumber()
    local dialStartNumber = math.random(0, 100)
    SafeDialRotation = 3.6 * dialStartNumber
end

function RelockSafe()
    if not _safeCombination then return end
    
    _safeLockStatus = InitSafeLocks()
    _currentLockNum = 1
    _try = 0
    _requiredDialRotationDirection = _initDialRotationDirection
    _onSpot = false

    for i=1, #_safeCombination do
        _safeLockStatus[i] = true
    end
end

function InitSafeLocks() -- Load the locks
    if not _safeCombination then
        return
    end
    
    local locks = {}
    for i=1, #_safeCombination do
        table.insert(locks, true)
    end

    return locks
end

function GetCurrentSafeDialNumber(currentDialAngle)
    local number = math.floor(100 * (currentDialAngle / 360))
    if number > 0 then number = 100 - number end

    return math.abs(number)
end

function ReleaseCurrentPin()
    _safeLockStatus[_currentLockNum] = false
    _currentLockNum = _currentLockNum + 1

    if _requiredDialRotationDirection == "Anticlockwise" then
        _requiredDialRotationDirection = "Clockwise"
    else
        _requiredDialRotationDirection = "Anticlockwise"
    end
    
    PlaySoundFrontend(0, "TUMBLER_PIN_FALL_FINAL", "SAFE_CRACK_SOUNDSET", true )
end

-- Verifica se o cofre foi finalizado
function IsSafeUnlocked()
    return _safeLockStatus[_currentLockNum] == nil
end

-- Finaliza o minigame. (Adicionar handle dependendo do safeUnlocked)
function EndMiniGame(safeUnlocked)
    if safeUnlocked then
        PlaySoundFrontend(0, "SAFE_DOOR_OPEN", "SAFE_CRACK_SOUNDSET", true )
    else
        PlaySoundFrontend(0, "SAFE_DOOR_CLOSE", "SAFE_CRACK_SOUNDSET", true )
    end
    isMinigame = false
    SafeCrackingStates = "Setup"
    FreezeEntityPosition(PlayerPedId(),false)
    ClearPedTasks(PlayerPedId())
end

function playFx(dict,anim)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), dict, anim, 1.5, 1.5, -1, 16, 0, 0, 0, 0)
end


exports("createSafe", createSafe)
