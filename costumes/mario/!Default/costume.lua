--[[
    Original costume code by MrDoubleA
]]

local playerManager = require("playerManager")

_G.smasFunctions = require("smasFunctions")
_G.smasExtraSounds = require("smasExtraSounds")

local costume = {}

costume.pSpeedAnimationsEnabled = true
costume.yoshiHitAnimationEnabled = false
costume.kickAnimationEnabled = true

costume.hammerID = 171
costume.hammerConfig = {
    gfxwidth = 32,
    gfxheight = 32,
    frames = 8,
    framespeed = 4,
    framestyle = 1,
}



costume.playersList = {}
costume.playerData = {}


costume.enableOptionalThings = false

costume.isSlowFalling = false
costume.slowFallTimer = 0
costume.slowFallMaxTime = 25


costume.isFlyingClassic = false
costume.isFlyingClassicTimer = 0
costume.isFlyingClassicMaxTime = 30


local eventsRegistered = false


local characterSpeedModifiers = {
    [CHARACTER_PEACH] = 0.93,
    [CHARACTER_TOAD]  = 1.07,
}
local characterNeededPSpeeds = {
    [CHARACTER_MARIO] = 35,
    [CHARACTER_LUIGI] = 40,
    [CHARACTER_PEACH] = 80,
    [CHARACTER_TOAD]  = 60,
    [CHARACTER_LINK]  = 10,
}
local characterDeathEffects = {
    [CHARACTER_MARIO] = 3,
    [CHARACTER_LUIGI] = 5,
    [CHARACTER_PEACH] = 129,
    [CHARACTER_TOAD]  = 130,
    [CHARACTER_LINK]  = 134,
}

local deathEffectFrames = 1

local leafPowerups = table.map{PLAYER_LEAF,PLAYER_TANOOKIE}
local shootingPowerups = table.map{PLAYER_FIREFLOWER,PLAYER_ICE,PLAYER_HAMMER}

local smb2Characters = table.map{CHARACTER_PEACH,CHARACTER_TOAD}
local linkCharacters = table.map{CHARACTER_LINK}


-- Detects if the player is on the ground, the redigit way. Sometimes more reliable than just p:isOnGround().
local function isOnGround(p)
    return (
        p.speedY == 0 -- "on a block"
        or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
        or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end


local function isSlidingOnIce(p)
    return (p:mem(0x0A,FIELD_BOOL) and (not p.keys.left and not p.keys.right))
end

local function isSlowFalling(p)
    return (leafPowerups[p.powerup] and p.speedY > 0 and (p.keys.jump or p.keys.altJump))
end


local function canBuildPSpeed(p)
    return (
        costume.pSpeedAnimationsEnabled
        and p.forcedState == FORCEDSTATE_NONE
        and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) -- not dead
        and p.mount ~= MOUNT_BOOT and p.mount ~= MOUNT_CLOWNCAR
        and not p.climbing
        and not p:mem(0x0C,FIELD_BOOL) -- fairy
        and not p:mem(0x44,FIELD_BOOL) -- surfing on a rainbow shell
        and not p:mem(0x4A,FIELD_BOOL) -- statue
        and p:mem(0x34,FIELD_WORD) == 0 -- underwater
    )
end

local function canFall(p)
    return (
        p.forcedState == FORCEDSTATE_NONE
        and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) -- not dead
        and not isOnGround(p)
        and p.mount == MOUNT_NONE
        and not p.climbing
        and not p:mem(0x0C,FIELD_BOOL) -- fairy
        and not p:mem(0x3C,FIELD_BOOL) -- sliding
        and not p:mem(0x44,FIELD_BOOL) -- surfing on a rainbow shell
        and not p:mem(0x4A,FIELD_BOOL) -- statue
        and p:mem(0x34,FIELD_WORD) == 0 -- underwater
    )
end

local function canDuck(p)
    return (
        p.forcedState == FORCEDSTATE_NONE
        and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) -- not dead
        and p.mount == MOUNT_NONE
        and not p.climbing
        and not p:mem(0x0C,FIELD_BOOL) -- fairy
        and not p:mem(0x3C,FIELD_BOOL) -- sliding
        and not p:mem(0x44,FIELD_BOOL) -- surfing on a rainbow shell
        and not p:mem(0x4A,FIELD_BOOL) -- statue
        and not p:mem(0x50,FIELD_BOOL) -- spin jumping
        and p:mem(0x26,FIELD_WORD) == 0 -- picking up something from the top
        and (p:mem(0x34,FIELD_WORD) == 0 or isOnGround(p)) -- underwater or on ground
        and p.holdingNPC == nil

        and (
            p:mem(0x48,FIELD_WORD) == 0 -- not on a slope (ducking on a slope is weird due to sliding)
            or (p.powerup == PLAYER_SMALL and p.holdingNPC == nil) -- small and not holding an NPC
            or p:mem(0x34,FIELD_WORD) > 0 -- underwater
        )
    )
end

local function canHitYoshi(p)
    return (
        costume.yoshiHitAnimationEnabled
        and p.forcedState == FORCEDSTATE_NONE
        and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) -- not dead
        and p.mount == MOUNT_YOSHI
        and not p:mem(0x0C,FIELD_BOOL) -- fairy
    )
end


local clearPipeHorizontalFrames = table.map{2,42,44}
local clearPipeVerticalFrames = table.map{15}

local function isInClearPipe(p)
    local frame = costume.playerData[p].frameInOnDraw

    return (
        p.forcedState == FORCEDSTATE_DOOR
        and (clearPipeHorizontalFrames[frame] or clearPipeVerticalFrames[frame])
    )
end


local function setHeldNPCPosition(p,x,y)
    local holdingNPC = p.holdingNPC

    holdingNPC.x = x
    holdingNPC.y = y


    if holdingNPC.id == 49 and holdingNPC.ai2 > 0 then -- toothy pipe
        -- You'd think that redigit's pointers work, but nope! this has to be done instead
        for _,toothy in NPC.iterate(50,p.section) do
            if toothy.ai1 == p.idx then
                if p.direction == DIR_LEFT then
                    toothy.x = holdingNPC.x - toothy.width
                else
                    toothy.x = holdingNPC.x + holdingNPC.width
                end

                toothy.y = holdingNPC.y
            end
        end
    end
end

local function handleDucking(p)
    if p.keys.down and not smb2Characters[p.character] and (p.powerup == PLAYER_SMALL) and canDuck(p) then
        p:mem(0x12E,FIELD_BOOL,true)

        if isOnGround(p) then
            if p.keys.left then
                p.direction = DIR_LEFT
            elseif p.keys.right then
                p.direction = DIR_RIGHT
            end

            p.keys.left = false
            p.keys.right = false
        end
    end
end


-- This table contains all the custom animations that this costume has.
-- Properties are: frameDelau, loops, setFrameInOnDraw
local animations = {
    standing = {1},
    
    -- Big only animations
    walk = {2,3,2,1, frameDelay = 6},
    run  = {17,18,17,16, frameDelay = 6},
    standingHolding = {8},
    walkHolding = {9,10,9,8, frameDelay = 6},
    fall = {5},
    skid = {6},
    duck = {7},

    -- Small only animation
    walkSmall = {9,2,9,1,   frameDelay = 6},
    runSmall  = {16,17, frameDelay = 6},
    duckSmall = {8},
    skidSmall = {4},
    walkHoldingSmall = {6,5, frameDelay = 6},
    standingHoldingSmall = {5},
    
    runLeaf  = {17,18,17,16, frameDelay = 6},
    fallSmall = {7},

    -- SMB2 characters (like toad)
    walkSmallSMB2 = {2,1,   frameDelay = 6},
    runSmallSMB2  = {16,17, frameDelay = 6},
    walkHoldingSmallSMB2 = {8,9, frameDelay = 6},


    -- Some other animations
    climbing = {25,26, frameDelay = 6},
    climbingStill = {25},
    
    sliding = {24},
    
    shellSurf = {16},
    statue = {0},
    
    duckHolding = {31},

    kick = {20, frameDelay = 12,loops = false},
    kickLeaf = {32, frameDelay = 12,loops = false},

    runJump = {19},
    runJumpSmall = {18},


    clearPipeHorizontal = {19, setFrameInOnDraw = true},
    clearPipeVertical = {15, setFrameInOnDraw = true},


    -- Fire/ice/hammer things
    shootGround = {11,12,11, frameDelay = 6,loops = false},


    -- Leaf things
    slowFall = {5,3,11,3, frameDelay = 5},
    slowFallDuck = {7,27,28,27, frameDelay = 5},
    slowFallHold = {29,10,33,10, frameDelay = 5},
    
    tailAttack = {12,15,14,13, frameDelay = 5},
    
    runSlowFall = {19,20,21,20, frameDelay = 5},
    fallLeafUp = {11},
    runJumpLeafDown = {21},
    runJumpLeaf = {19,20,21,20, frameDelay = 5},


    -- Swimming
    swimIdle = {40,41,42,41, frameDelay = 10},
    swimIdleSmall = {40,41, frameDelay = 10},
    swimStroke = {43,44,43, frameDelay = 4,loops = false},
    swimStrokeSmall = {42,43,42, frameDelay = 4,loops = false},


    -- To fix a dumb bug with toad's spinjump while holding an item
    spinjumpSidwaysToad = {8},
}


-- This function returns the name of the custom animation currently playing.
local function findAnimation(p)
    local data = costume.playerData[p]


    -- What P-Speed values gets used is dependent on if the player has a leaf powerup
    data.atPSpeed = (p.holdingNPC == nil)

    if data.atPSpeed then
        if leafPowerups[p.powerup] then
            data.atPSpeed = p:mem(0x16C,FIELD_BOOL) or p:mem(0x16E,FIELD_BOOL)
        else
            data.atPSpeed = (data.pSpeed >= characterNeededPSpeeds[p.character])
        end
    end


    if p.deathTimer > 0 then
        return nil
    end


    if p.mount == MOUNT_YOSHI then
        return nil
    elseif p.mount ~= MOUNT_NONE then
        return nil
    end


    if p.forcedState == FORCEDSTATE_PIPE then
        local warp = Warp(p:mem(0x15E,FIELD_WORD) - 1)

        local direction
        if p.forcedTimer == 0 then
            direction = warp.entranceDirection
        else
            direction = warp.exitDirection
        end

        if direction == 2 or direction == 4 then
            if p.powerup == PLAYER_SMALL then
                return "walkSmall",0.5
            else
                return "walk",0.5
            end
        end

        return nil
    elseif p.forcedState == FORCEDSTATE_DOOR then
        -- Clear pipe stuff (it's weird)
        local frame = data.frameInOnDraw

        if clearPipeHorizontalFrames[frame] then
            return "clearPipeHorizontal"
        elseif clearPipeVerticalFrames[frame] then
            return "clearPipeVertical"
        end


        return nil
    elseif p.forcedState ~= FORCEDSTATE_NONE then
        return nil
    end


    if p:mem(0x26,FIELD_WORD) > 0 then
        return nil
    end


    if p:mem(0x12E,FIELD_BOOL) then
        if smb2Characters[p.character] then
            return nil
        elseif p.holdingNPC ~= nil then
            return "duckHolding"
        elseif p.powerup == PLAYER_SMALL then
            return "duckSmall"
        elseif isSlowFalling(p) then
            costume.isSlowFalling = true
            return "slowFallDuck"
        elseif costume.slowFallTimer >= 1 and costume.slowFallTimer <= costume.slowFallMaxTime then
            return "slowFallDuck"
        elseif p:mem(0x16E,FIELD_BOOL) then
            costume.isFlyingClassic = true
            return "slowFallDuck"
        else
            return "duck"
        end
    end


    
    if p.climbing then
        if (p.keys.up or p.keys.left or p.keys.right) then
            return "climbing"
        else
            return "climbingStill"
        end
    end
    
    if p:mem(0x3C,FIELD_BOOL) then -- sliding
        return "sliding"
    end
    
    if p:mem(0x44,FIELD_BOOL) then -- shell surfing
        return "shellSurf"
    end
    
    if p:mem(0x4A,FIELD_BOOL) then -- statue
        return "statue"
    end
    
    if p:mem(0x164,FIELD_WORD) ~= 0 then -- tail attack
        return nil
    end


    if p:mem(0x50,FIELD_BOOL) then -- spin jumping
        if smb2Characters[p.character] and p.frame == 5 then -- dumb bug
            return "spinjumpSidwaysToad"
        else
            return nil
        end
    end


    local isShooting = (p:mem(0x118,FIELD_FLOAT) >= 100 and p:mem(0x118,FIELD_FLOAT) <= 118 and shootingPowerups[p.powerup])


    -- Kicking
    if data.currentAnimation == "kick" and not data.animationFinished then
        return data.currentAnimation
    elseif data.currentAnimation == "kickLeaf" and not data.animationFinished then
        return data.currentAnimation
    elseif p.holdingNPC == nil and data.wasHoldingNPC and costume.kickAnimationEnabled then -- stopped holding an NPC
        if not smb2Characters[p.character] then
            local e = Effect.spawn(75, p.x + p.width*0.5 + p.width*0.5*p.direction,p.y + p.height*0.5)

            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5
        end
        if leafPowerups[p.powerup] then
            return "kickLeaf"
        else
            return "kick"
        end
    end


    if isOnGround(p) then
        -- GROUNDED ANIMATIONS --
        if p.speedX == 0 and p.speedY == 0 then
            if p.holdingNPC == nil then
                return "standing"
            else
                if p.powerup == PLAYER_SMALL then
                    return "standingHoldingSmall"
                else
                    return "standingHolding"
                end
            end
        end
        
        
        if isShooting then
            return "shootGround"
        end


        -- Skidding
        if (p.speedX < 0 and p.keys.right) or (p.speedX > 0 and p.keys.left) or p:mem(0x136,FIELD_BOOL) then
            if p.powerup == PLAYER_SMALL then
                return "skidSmall"
            else
                return "skid"
            end
        end


        -- Walking
        if p.speedX ~= 0 and not isSlidingOnIce(p) then
            local walkSpeed = math.max(0.35,math.abs(p.speedX)/Defines.player_walkspeed)

            local animationName

            if data.atPSpeed then
                if not leafPowerups[p.powerup] then
                    animationName = "run"
                else
                    animationName = "runLeaf"
                end
            else
                animationName = "walk"

                if p.holdingNPC ~= nil then
                    animationName = animationName.. "Holding"
                end
            end

            if p.powerup == PLAYER_SMALL then
                animationName = animationName.. "Small"

                if smb2Characters[p.character] then
                    animationName = animationName.. "SMB2"
                end
            end


            return animationName,walkSpeed
        end

        return nil
    elseif (p:mem(0x34,FIELD_WORD) > 0 and p:mem(0x06,FIELD_WORD) == 0) and p.holdingNPC == nil then -- swimming
        -- SWIMMING ANIMATIONS --


        if isShooting then
            if p.powerup == PLAYER_SMALL then
                return "swimStrokeSmall"
            else
                return "swimStroke"
            end
        end
        

        if p:mem(0x38,FIELD_WORD) == 15 then
            if p.powerup == PLAYER_SMALL then
                return "swimStrokeSmall"
            else
                return "swimStroke"
            end
        elseif ((data.currentAnimation == "swimStroke" and p.powerup ~= PLAYER_SMALL) or (data.currentAnimation == "swimStrokeSmall" and p.powerup == PLAYER_SMALL)) and not data.animationFinished then
            return data.currentAnimation
        end
        
        if p.powerup == PLAYER_SMALL then
            return "swimIdleSmall"
        else
            return "swimIdle"
        end
    else
        -- AIR ANIMATIONS --


        if isShooting then
            return "shootGround"
        end
        

        if p:mem(0x16E,FIELD_BOOL) then -- flying with leaf
            costume.isFlyingClassic = true
            if p.holdingNPC == nil then
                return "runJumpLeaf"
            else
                return "slowFallHold"
            end
        end

        
        if data.atPSpeed then
            if isSlowFalling(p) then
                costume.isSlowFalling = true
                return "runSlowFall"
            elseif leafPowerups[p.powerup] and p.speedY > 0 then
                return "runJumpLeafDown"
            elseif costume.slowFallTimer >= 1 and costume.slowFallTimer <= costume.slowFallMaxTime then
                return "runSlowFall"
            else
                if p.powerup == PLAYER_SMALL and not leafPowerups[p.powerup] then
                    return "runJumpSmall"
                else
                    return "runJump"
                end
            end
        end


        if p.holdingNPC == nil then
            if isSlowFalling(p) then
                costume.isSlowFalling = true
                return "slowFall"
            elseif data.useFallingFrame then
                if p.powerup == PLAYER_SMALL and not smb2Characters[p.character] then
                    return "fallSmall"
                elseif leafPowerups[p.powerup] and p.speedY <= 0 then
                    return "fallLeafUp"
                else
                    return "fall"
                end
            end
            if costume.slowFallTimer >= 1 and costume.slowFallTimer <= costume.slowFallMaxTime then
                return "slowFall"
            end
        end
        if p.holdingNPC ~= nil then
            if isSlowFalling(p) then
                return "slowFallHold"
            end
        end

        return nil
    end
end


function costume.onInit(p)
    -- If events have not been registered yet, do so
    if not eventsRegistered then
        registerEvent(costume,"onStart")
        registerEvent(costume,"onTick")
        registerEvent(costume,"onTickEnd")
        registerEvent(costume,"onDraw")
        registerEvent(costume,"onInputUpdate")
        
        eventsRegistered = true
    end


    -- Add this player to the list
    if costume.playerData[p] == nil then
        costume.playerData[p] = {
            currentAnimation = "",
            animationTimer = 0,
            animationSpeed = 1,
            animationFinished = false,

            forcedFrame = nil,

            frameInOnDraw = p.frame,


            pSpeed = 0,
            useFallingFrame = false,
            wasHoldingNPC = false,
            yoshiHitTimer = 0,
            atPSpeed = false,
        }

        table.insert(costume.playersList,p)
    end
end

function costume.onCleanup(p)
    -- Remove the player from the list
    if costume.playerData[p] ~= nil then
        costume.playerData[p] = nil

        local spot = table.ifind(costume.playersList,p)

        if spot ~= nil then
            table.remove(costume.playersList,spot)
        end
    end
end



function costume.onInputUpdate()
    for _,p in ipairs(costume.playersList) do
        local data = costume.playerData[p]
        
        
    end
end

function costume.handleSlowFalling(p)
    if costume.isSlowFalling then
        costume.slowFallTimer = costume.slowFallTimer + 1
        
        if not isOnGround(p) and (p:mem(0x34,FIELD_WORD) == 0 and p:mem(0x06,FIELD_WORD) == 0) and not isSlowFalling(p) then
            p.speedY = Defines.player_grav * 5
        end
        
        if p.keys.jump == KEYS_PRESSED then
            costume.slowFallTimer = 1
        end
        
        if costume.slowFallTimer == 1 then
            Sound.playSFX(33, nil, nil, 15)
        end
        
        if costume.slowFallTimer <= costume.slowFallMaxTime then
            p.y = p.y - 0.3
        end
        
        if costume.slowFallTimer > costume.slowFallMaxTime then
            p.y = p.y + 3
            if p:mem(0x12E,FIELD_BOOL) then
                p.frame = 28
            elseif p.holdingNPC ~= nil then
                p.frame = 33
            else
                p.frame = 5
            end
        end
    end
end

function costume.handleFlying(p)
    if costume.isFlyingClassic then
        costume.isFlyingClassicTimer = costume.isFlyingClassicTimer + 1
        
        if p.keys.jump == KEYS_PRESSED then
            costume.isFlyingClassicTimer = 1
        end
        
        if costume.isFlyingClassicTimer == 1 then
            Sound.playSFX(33, nil, nil, 15)
        end
        
        if costume.isFlyingClassicTimer <= costume.isFlyingClassicMaxTime and p.keys.jump then
            p.y = p.y - 0.5
        end
        
        if costume.isFlyingClassicTimer > costume.isFlyingClassicMaxTime then
            if p.keys.jump then
                p.y = p.y + 5.5
            end
            if p:mem(0x12E,FIELD_BOOL) then
                p.frame = 28
            elseif p.holdingNPC ~= nil then
                p.frame = 33
            else
                p.frame = 19
            end
        end
    end
end

function costume.onTick()
    for _,p in ipairs(costume.playersList) do
        local data = costume.playerData[p]

        handleDucking(p)
        
        if costume.enableOptionalThings then
            if not isOnGround(p) and (p:mem(0x34,FIELD_WORD) == 0 and p:mem(0x06,FIELD_WORD) == 0) then
                if isSlowFalling(p) or (costume.slowFallTimer >= 1 and costume.slowFallTimer <= costume.slowFallMaxTime) then
                    costume.handleSlowFalling(p)
                end
                if p:mem(0x16E,FIELD_BOOL) or (costume.isFlyingClassicTimer >= 1 and costume.isFlyingClassicTimer <= costume.isFlyingClassicMaxTime) then
                    costume.handleFlying(p)
                end
            end
        end
        
        if isOnGround(p) then
            costume.slowFallTimer = 0
            costume.isSlowFalling = false
            costume.isFlyingClassicTimer = 0
            costume.isFlyingClassic = false
        end

        -- Yoshi hitting (creates a small delay between hitting the run button and yoshi actually sticking his tongue out)
        if canHitYoshi(p) then
            if data.yoshiHitTimer > 0 then
                data.yoshiHitTimer = data.yoshiHitTimer + 1

                if data.yoshiHitTimer >= 8 then
                    -- Force yoshi's tongue out
                    p:mem(0x10C,FIELD_WORD,1) -- set tongue out
                    p:mem(0xB4,FIELD_WORD,0) -- set tongue length
                    p:mem(0xB6,FIELD_BOOL,false) -- set tongue retracting

                    SFX.play(50)

                    data.yoshiHitTimer = 0
                else
                    p:mem(0x172,FIELD_BOOL,false)
                end
            elseif p.keys.run and p:mem(0x172,FIELD_BOOL) and (p:mem(0x10C,FIELD_WORD) == 0 and p:mem(0xB8,FIELD_WORD) == 0 and p:mem(0xBA,FIELD_WORD) == 0) then
                p:mem(0x172,FIELD_BOOL,false)
                data.yoshiHitTimer = 1
            end
        else
            data.yoshiHitTimer = 0
        end
    end
end

function costume.onTickEnd()
    for _,p in ipairs(costume.playersList) do
        local data = costume.playerData[p]


        handleDucking(p)


        -- P-Speed
        if canBuildPSpeed(p) then
            if isOnGround(p) then
                if math.abs(p.speedX) >= Defines.player_runspeed*(characterSpeedModifiers[p.character] or 1) then
                    data.pSpeed = math.min(characterNeededPSpeeds[p.character] or 0,data.pSpeed + 1)
                else
                    data.pSpeed = math.max(0,data.pSpeed - 0.3)
                end
            end
        else
            data.pSpeed = 0
        end

        -- Falling (once you start the falling animation, you stay in it)
        if canFall(p) then
            data.useFallingFrame = (data.useFallingFrame or p.speedY > 0)
        else
            data.useFallingFrame = false
        end

        -- Yoshi hit (change yoshi's head frame)
        if data.yoshiHitTimer >= 3 and canHitYoshi(p) then
            local yoshiHeadFrame = p:mem(0x72,FIELD_WORD)

            if yoshiHeadFrame == 0 or yoshiHeadFrame == 5 then
                p:mem(0x72,FIELD_WORD, yoshiHeadFrame + 2)
            end
        end



        -- Find and start the new animation
        local newAnimation,newSpeed,forceRestart = findAnimation(p)

        if data.currentAnimation ~= newAnimation or forceRestart then
            data.currentAnimation = newAnimation
            data.animationTimer = 0
            data.animationFinished = false

            if newAnimation ~= nil and animations[newAnimation] == nil then
                error("Animation '".. newAnimation.. "' does not exist")
            end
        end

        data.animationSpeed = newSpeed or 1

        -- Progress the animation
        local animationData = animations[data.currentAnimation]

        if animationData ~= nil then
            local frameCount = #animationData

            local frameIndex = math.floor(data.animationTimer / (animationData.frameDelay or 1))

            if frameIndex >= frameCount then -- the animation is finished
                if animationData.loops ~= false then -- this animation loops
                    frameIndex = frameIndex % frameCount
                else -- this animation doesn't loop
                    frameIndex = frameCount - 1
                end

                data.animationFinished = true
            end
            
            p.frame = animationData[frameIndex + 1]
            data.forcedFrame = p.frame

            data.animationTimer = data.animationTimer + data.animationSpeed
        else
            data.forcedFrame = nil
        end


        -- For kicking
        data.wasHoldingNPC = (p.holdingNPC ~= nil)
    end
end

function costume.onDraw()
    for _,p in ipairs(costume.playersList) do
        local data = costume.playerData[p]

        data.frameInOnDraw = p.frame
        
        local animationData = animations[data.currentAnimation]
        
        if (animationData ~= nil and animationData.setFrameInOnDraw) and data.forcedFrame ~= nil then
            p.frame = data.forcedFrame
        end
    end
end


Misc.storeLatestCostumeData(costume)

return costume