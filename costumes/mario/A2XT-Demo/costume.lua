local pm = require("playerManager")
local smasExtraSounds = require("smasExtraSounds")
local smasFunctions = require("smasFunctions")

local costume = {}

costume.loaded = false

function costume.onInit(p)
    if not costume.loaded then
        Sound.loadCostumeSounds()
        costume.loaded = true
    end
    Graphics.sprites.hardcoded["48-0"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Container0.png")
    Graphics.sprites.hardcoded["48-1"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Container1.png")
    Graphics.sprites.hardcoded["33-0"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface0.png")
    Graphics.sprites.hardcoded["33-1"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface1.png")
    Graphics.sprites.hardcoded["33-2"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface2.png")
    Graphics.sprites.hardcoded["33-3"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface3.png")
    Graphics.sprites.hardcoded["33-5"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface5.png")
    Graphics.sprites.hardcoded["33-6"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface6.png")
    Graphics.sprites.hardcoded["33-7"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface7.png")
    Graphics.sprites.hardcoded["33-8"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/interface8.png")
    Graphics.sprites.hardcoded["26-2"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Mount.png")
    Graphics.sprites.hardcoded["25-1"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Boot1.png")
    Graphics.sprites.hardcoded["25-2"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Boot2.png")
    Graphics.sprites.hardcoded["25-3"].img = Graphics.loadImageResolved("graphics/customs/AdventuresOfDemo/ui/Boot3.png")
end

function costume.onCleanup(p)
    Sound.cleanupCostumeSounds()
    Graphics.sprites.hardcoded["48-0"].img = nil
    Graphics.sprites.hardcoded["48-1"].img = nil
    Graphics.sprites.hardcoded["33-0"].img = nil
    Graphics.sprites.hardcoded["33-1"].img = nil
    Graphics.sprites.hardcoded["33-2"].img = nil
    Graphics.sprites.hardcoded["33-3"].img = nil
    Graphics.sprites.hardcoded["33-5"].img = nil
    Graphics.sprites.hardcoded["33-6"].img = nil
    Graphics.sprites.hardcoded["33-7"].img = nil
    Graphics.sprites.hardcoded["33-8"].img = nil
    Graphics.sprites.hardcoded["26-2"].img = nil
    Graphics.sprites.hardcoded["25-1"].img = nil
    Graphics.sprites.hardcoded["25-2"].img = nil
    Graphics.sprites.hardcoded["25-3"].img = nil
end

Misc.storeLatestCostumeData(costume)

return costume