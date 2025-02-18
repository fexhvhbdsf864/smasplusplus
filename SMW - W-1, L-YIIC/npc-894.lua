local fencekoopaVertRed = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

local deathEffectID = npcID

-- settings
local config = {
    id = npcID, 
    gfxoffsety = 0, 
    width = 32, 
    height = 32,
    gfxwidth = 32,
    gfxheight = 64,
    frames = 2,
    framestyle = 0,
    framespeed = 8,
    speed = 1,
    nogravity = true,
    jumphurt = false,
    nofireball = false,
    noiceball = false,
    noblockcollision = false,
    score = 2
}
npcManager.setNpcSettings(config)

npcManager.registerHarmTypes(npcID,
{
        HARM_TYPE_JUMP,
        HARM_TYPE_FROMBELOW,
        HARM_TYPE_NPC,
        HARM_TYPE_PROJECTILE_USED,
        HARM_TYPE_LAVA,
        HARM_TYPE_HELD,
        HARM_TYPE_TAIL,
        HARM_TYPE_SPINJUMP,
        HARM_TYPE_OFFSCREEN,
        HARM_TYPE_SWORD
    }, 
    {
        [HARM_TYPE_JUMP]=deathEffectID,
        [HARM_TYPE_FROMBELOW]= deathEffectID,
        [HARM_TYPE_NPC]= deathEffectID,
        [HARM_TYPE_PROJECTILE_USED]= deathEffectID,
        [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
        [HARM_TYPE_HELD]= deathEffectID,
        [HARM_TYPE_TAIL]=deathEffectID,
        [HARM_TYPE_SPINJUMP]=10,
        [HARM_TYPE_OFFSCREEN]=deathEffectID,
        [HARM_TYPE_SWORD]= deathEffectID,
        [HARM_TYPE_EXT_FIRE] = deathEffectID,
    }
);

function fencekoopaVertRed.onInitAPI()
    npcManager.registerEvent(npcID, fencekoopaVertRed, "onTickEndNPC")
end

local fenceLookupTable = { }

for i=174, 186 do
    fenceLookupTable[i] = true
end

function fencekoopaVertRed.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    
    local data = v.data._basegame
    
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        v.data.initialized = false
        v.data.climbDir = 0
        v.data.canSetSpeed = 1
        return
    end
    if not v.data.initialized then    
        if v.direction == -1 then
            v.data.climbDir = -1
        else
            v.data.climbDir = 1
        end
        v.data.initialized = true
    end
    
    local touchingFence = false
    
    local bgos = BGO.getIntersecting(v.x + 0.4 * v.width, v.y + 0.4 * v.height, v.x + 0.6 * v.width, v.y + 0.6 * v.height)
    for index, intersectingBgo in ipairs(bgos) do
        if fenceLookupTable[intersectingBgo.id] == true and intersectingBgo.isHidden == false then
            touchingFence = true
            break
        end
    end
    
    if touchingFence == false then
        v.data.climbDir = -v.data.climbDir
        v.data.canSetSpeed = 1
    end
    
    if (v.collidesBlockBottom or v.collidesBlockUp) then
        v.data.climbDir = -v.data.climbDir
        v.data.canSetSpeed = 1
    end
    
    if v.data.climbDir == -1 and v.data.canSetSpeed == 1 then
        v.speedY = -2
        v.data.canSetSpeed = 0
    elseif v.data.canSetSpeed == 1 then
        v.speedY = 2
        v.data.canSetSpeed = 0
    end
end

return fencekoopaVertRed