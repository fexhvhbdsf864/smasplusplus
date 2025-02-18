local warpTransition = require("warpTransition")
local textplus = require("textplus")
local littleDialogue = require("littleDialogue")
_G.pausemenu2 = require("pausemenu2")

if SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
    pausemenu13 = require("pausemenu13/pausemenu13")
end

local pauseplus = require("pauseplus")
local debugbox = require("debugbox")
local smasExtraSounds = require("smasExtraSounds")
local smasHudSystem = require("smasHudSystem")
local smasDateAndTime = require("smasDateAndTime")

littleDialogue.defaultStyleName = "smbx13"
smasBooleans.compatibilityMode13Mode = false

local warps
local effect

local debugtext = true
local fonttester = textplus.loadFont("littleDialogue/font/press-start.ini")

function effectSpawn()
    Routine.wait(0, true)
    warps = Warp.get()
    effect = Effect.spawn(105,warps[11].exitX - 20,warps[11].exitY - 85)
end

function onStart()
    Routine.run(effectSpawn)
    
    if SMBX_VERSION == VER_SEE_MOD then
        
    end
end 

function onEvent(eventName)
    if eventName == "pauseenable" then
        pauseplus.canPause = true
    end
    if eventName == "pausedisable" then
        pauseplus.canPause = false
    end
end

function onTick()
    littleDialogue.defaultStyleName = "smbx13"
end

local snapshottaken = false
local timesnapped

function onKeyboardPressDirect(k)
    if k == VK_F12 then
        timesnapped = string.format("%.1d:%.2d:%.2d.%.3d", lunatime.tick()/(60 * 60 * 65), (lunatime.tick()/(60*65))%60, (lunatime.tick()/65)%60, ((lunatime.tick()%65)/65) * 1000)
        snapshottaken = true
    end
end

function onNPCHarm(eventToken, npc, harmType, culprit)
    if harmType == HARM_TYPE_NPC then
        --Fireball harm
        if not NPC.config[npc.id].nofireball then
            if not eventToken.cancelled then
                eventToken.cancelled = true
                NPC:harm(HARM_TYPE_EXT_FIRE)
                Misc.manuallyRunLunaLuaEvent(true, onNPCHarm, nil, {eventToken, npc, HARM_TYPE_EXT_FIRE, culprit})
            end
        end
        --Iceball harm
        if not NPC.config[npc.id].noiceball then
            if not eventToken.cancelled then
                eventToken.cancelled = true
                NPC:harm(HARM_TYPE_EXT_ICE)
                Misc.manuallyRunLunaLuaEvent(true, onNPCHarm, nil, {eventToken, npc, HARM_TYPE_EXT_ICE, culprit})
            end
        end
        --Hammer harm
        if NPC.config[npc.id].nohammer then
            if culprit and type(culprit) == "NPC" and culprit.id == 171 then
                eventToken.cancelled = true
            end
        elseif not NPC.config[npc.id].nohammer then
            if not eventToken.cancelled then
                eventToken.cancelled = true
                NPC:harm(HARM_TYPE_EXT_HAMMER)
                Misc.manuallyRunLunaLuaEvent(true, onNPCHarm, nil, {eventToken, npc, HARM_TYPE_EXT_HAMMER, culprit})
            end
        end
    end
end

function onDraw()
    if snapshottaken then
        Text.printWP(timesnapped, 100, 100, 3)
    end
    if debugtext then
        textplus.print{x = 0, y = 0, text = "1234567890", font = fonttester, priority = 6, xscale = 2, yscale = 2}
        textplus.print{x = 0, y = 25, text = "abcdefghijklmnopqrstuvwxyz", font = fonttester, priority = 6, xscale = 2, yscale = 2}
        textplus.print{x = 0, y = 50, text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ", font = fonttester, priority = 6, xscale = 2, yscale = 2}
    end
end