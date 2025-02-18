local pm = require("playerManager")
local smasExtraSounds = require("smasExtraSounds")
local smasFunctions = require("smasFunctions")
local smasExtraActions = require("smasExtraActions")

local costume = {}

costume.loaded = false

local jumphighertimer = 0
local jumphigherframeactive = false

-- Detects if the player is on the ground, the redigit way. Sometimes more reliable than just p:isOnGround().
local function isOnGround(p)
    return (
        player.speedY == 0 -- "on a block"
        or player:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
        or player:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

function isPlayerDucking(p) --Returns if the player is ducking.
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

        and (
            p:mem(0x48,FIELD_WORD) == 0 -- not on a slope (ducking on a slope is weird due to sliding)
            or (p.holdingNPC ~= nil) -- holding an NPC
            or p:mem(0x34,FIELD_WORD) > 0 -- underwater
        )
    )
end

function isJumping(p)
    return (p:mem(0x11E, FIELD_BOOL) and p.keys.jump == KEYS_PRESSED)
end

function costume.onInit(p)
    registerEvent(costume,"onTick")
    if not costume.loaded then
        Sound.loadCostumeSounds()
        costume.loaded = true
    end
    smasExtraActions.enableLongJump = true
    smasExtraActions.longJumpAnimationFrames[1] = {3} --SMB2 Defaults
    for i = 2,7 do
        smasExtraActions.longJumpAnimationFrames[i] = {4}
    end
    smasExtraActions.longJumpAnimationMaxFrames = 1
end

function costume.onCleanup(p)
    Sound.cleanupCostumeSounds()
    smasExtraActions.enableLongJump = false
    smasExtraActions.longJumpAnimationFrames[1] = {3} --SMB2 Defaults
    for i = 2,7 do
        smasExtraActions.longJumpAnimationFrames[i] = {4}
    end
    smasExtraActions.longJumpAnimationMaxFrames = 1
end

Misc.storeLatestCostumeData(costume)

return costume