SysManager.sendToConsole("globalgenerals is now loading...")

local starman = require("starman/star")
local mega2 = require("mega/megashroom")
local playerManager = require("playermanager")
local littleDialogue = require("littleDialogue")
local extendedKoopas = require("extendedKoopas")
local warpTransition = require("warpTransition")
local textplus = require("textplus")
local repll = require("repll")
local namehover = require("namehover")
local hearthover = require("hearthover")
local steve = require("steve")
local yoshi = require("yiYoshi/yiYoshi")
local inputconfigurator = require("inputconfig")
local musicalchairs = require("musicalchairs")

if GameData.enableBattleMode then
    SysManager.sendToConsole("Classic Battle Mode active! Loading the pause menu library...")
    _G.pausemenu2 = require("pausemenu2")
end

_G.smasAceCoins = require("smasAceCoins")
_G.smasAchievementsSystem = require("smasAchievementsSystem")
_G.smasCharacterInfo = require("smasCharacterInfo")
_G.smasCharacterIntros = require("smasCharacterIntros")
_G.smasLayerSystem = require("smasLayerSystem")
_G.smasExtraActions = require("smasExtraActions")
_G.smasBlockSystem = require("smasBlockSystem")
_G.smasPSwitch = require("smasPSwitch")
_G.smasEnemySystem = require("smasEnemySystem")
_G.smasNPCSystem = require("smasNPCSystem")
_G.smas2PlayerSystem = require("smas2PlayerSystem")
_G.smasResolutions = require("smasResolutions")
_G.smasSMB1System = require("smasSMB1System")
_G.smasCameraControl = require("smasCameraControl")
_G.smasZoomSystem = require("smasZoomSystem")

if SMBX_VERSION == VER_SEE_MOD then
    smasOnlinePlay = require("smasOnlinePlay")
end

local numberfont = textplus.loadFont("littleDialogue/font/1.ini")

if not table.icontains(smasTables._noLevelPlaces,Level.filename()) then
    if not SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
        if SaveData.SMASPlusPlus.accessibility.enableTwirl then
            SysManager.sendToConsole("Twirling activated! Loading the twirl library...")
            twirl = require("Twirl")
        end
        if SaveData.SMASPlusPlus.accessibility.enableWallJump then
            SysManager.sendToConsole("Wall jumping activated! Loading the anotherwalljump library...")
            aw = require("anotherwalljump")
            aw.registerAllPlayersDefault()
        end
        if SaveData.SMASPlusPlus.accessibility.enableGroundPound then
            SysManager.sendToConsole("Ground pounding activated! Loading the GroundPound library...")
            GP = require("GroundPound")
            GP.enabled = true
        end
    end
end

if GameData.rushModeActive then
    SysManager.sendToConsole("Rush mode active! Loading rush mode dependencies...")
    level_dependencies_rushmode = require("level_dependencies_rushmode")
end

namehover.active = false
local statusFont = textplus.loadFont("littleDialogue/font/6.ini")

smasHud.visible.starcoins = false
GameData.activateAbilityMessage = false

local easterCrash = false
local easterCrashDone = false
local easterCrashMsg = false
local easterCrashPrevLoad = false
local blockIdx5000Check = false

SaveData._anothercurrency = {SaveData.SMASPlusPlus.hud.coins}

if (table.icontains(smasTables._noTransitionLevels,Level.filename())) or (GameData.rushModeActive) then
    warpTransition.musicFadeOut = false
    warpTransition.levelStartTransition = warpTransition.TRANSITION_NONE
    warpTransition.sameSectionTransition = warpTransition.TRANSITION_NONE
    warpTransition.crossSectionTransition = warpTransition.TRANSITION_NONE
    warpTransition.activateOnInstantWarps = false
end

if SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
    SysManager.sendToConsole("1.3 Mode active! Changing some settings...")
    warpTransition.musicFadeOut = false
    warpTransition.levelStartTransition = warpTransition.TRANSITION_NONE
    warpTransition.sameSectionTransition = warpTransition.TRANSITION_NONE
    warpTransition.crossSectionTransition = warpTransition.TRANSITION_NONE
    warpTransition.activateOnInstantWarps = false
    local keyhole = require("tweaks/keyhole") --Disable X2 keyhole effect
    keyhole.onCameraDraw = function() end
    --mega2.sfxFile = Misc.resolveSoundFile("_OST/_Sound Effects/1.3Mode/megashroom13.ogg")
    --mega2.megagrowsfx = Misc.resolveSoundFile("_OST/_Sound Effects/1.3Mode/megashroom-grow-1.3.ogg")
    --mega2.megashrinksfx = Misc.resolveSoundFile("_OST/_Sound Effects/1.3Mode/megashroom-shrink-1.3.ogg")
    --mega2.megarunningoutsfx = Misc.resolveSoundFile("_OST/_Sound Effects/1.3Mode/megashroom-runningout-1.3.ogg")
    --starman.sfxFile = Misc.resolveSoundFile("_OST/_Sound Effects/1.3Mode/starman.ogg")
end

local killed = false
local killed2 = false

local ready = false

local globalgenerals = {}

function globalgenerals.onInitAPI()
    registerEvent(globalgenerals,"onExit")
    registerEvent(globalgenerals,"onExitLevel")
    registerEvent(globalgenerals,"onStart")
    registerEvent(globalgenerals,"onTick")
    registerEvent(globalgenerals,"onTickEnd")
    registerEvent(globalgenerals,"onCameraUpdate")
    registerEvent(globalgenerals,"onInputUpdate")
    registerEvent(globalgenerals,"onEvent")
    registerEvent(globalgenerals,"onDraw")
    registerEvent(globalgenerals,"onPlayerHarm")
    registerEvent(globalgenerals,"onPostNPCKill")
    registerEvent(globalgenerals,"onPostBlockHit")
    registerEvent(globalgenerals,"onBlockHit")
    registerEvent(globalgenerals,"onPause")
    registerEvent(globalgenerals,"onExplosion")
    registerEvent(globalgenerals,"onKeyboardPress")
    registerEvent(globalgenerals,"onControllerButtonPress")
    
    local Routine = require("routine")
    
    ready = true
end

function lavaShroomEasterEgg()
    SysManager.sendToConsole("1.3 Mode Easter Egg found!")
    easterCrashPrevLoad = true
    smasBooleans.musicMuted = true
    Sound.playSFX("easteregg_smbx13crash.ogg")
    easterCrashMsg = true
    Routine.wait(2, true)
    smasBooleans.musicMuted = false
    Routine.wait(20, true)
    easterCrashMsg = false
    easterCrashDone = true
    easterCrash = false
end

--New pause menu was made, this is to prevent the old pause menu from opening
function globalgenerals.onPause(evt)
    evt.cancelled = true;
    isPauseMenuOpen = not isPauseMenuOpen
end

function globalgenerals.onEvent(eventName)
    if eventName then --If it executes any event...
        if smasBooleans.musicMuted then --If the music has been muted for any reason...
            SysManager.sendToConsole("Event started while music is muted. Storing changed music to the refresh table...")
            for i = 0,20 do
                if Section(i).music ~= 0 then --If the music is anything but 0...
                    Sound.refreshMusic(i) --Refresh that specific section
                    Sound.muteMusic(i) --Then mute
                end
            end
        end
    end
end

if GameData.tempReserve == nil then
    GameData.tempReserve = {}
    for i = 1,200 do
        GameData.tempReserve[i] = 0
    end
end

function globalgenerals.onStart()
    Sound.startupRefreshSystem()
    Playur.failsafeStartupPlayerCheck()
    if Misc.inEditor() then
        debugbox = require("debugbox")
        debugbox.bootactive = true
        if SMBX_VERSION == VER_SEE_MOD then
            Misc.setNewTestModeLevelData(Level.filename())
            SysManager.sendToConsole("SEE MOD ACTIVE! Editor level starter has been set to "..Level.filename()..".")
        end
    end
    if GameData.____mainMenuComplete == true then
        if (mem(0x00B25724, FIELD_STRING) == "SMAS - Start.lvlx") then
            mem(0x00B25724, FIELD_STRING, "map.lvlx")
        end
    end
    if SaveData.lastLevelPlayed == nil then
        SaveData.lastLevelPlayed = Level.filename()
    end
    Sound.checkPWingSoundStatus()
    Sound.checkSMBXSoundSystemStatus()
    for _,p in ipairs(Player.get()) do
        if Misc.inEditor() then
            if GameData.tempReserve ~= {} and GameData.tempReserve ~= nil then
                p.reservePowerup = GameData.tempReserve[p.idx]
            end
        end
    end
end

function globalgenerals.onTickEnd()
    -- Fix blinking when starting the level/changing sections (Thanks MDA!)
    mem(0x00B250D4,FIELD_BOOL,false)
end

function globalgenerals.onTick()
    if lunatime.tick() == 1 then --Failsafe in case
        Sound.loadCostumeSounds()
        smasAlterationSystem.characterAlterationChange(1)
    end
    if smasBooleans.compatibilityMode13Mode then --Makes shells a little slower
        mem(0x00B2C860, FIELD_FLOAT, 7.0999999046326)
    else
        mem(0x00B2C860, FIELD_FLOAT, 6.2)
    end
    if table.icontains(smasTables.__wsmbaLevels,Level.filename()) then
        if not SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
            littleDialogue.defaultStyleName = "smbx13"
        end
        warpTransition.musicFadeOut = false
        warpTransition.levelStartTransition = warpTransition.TRANSITION_NONE
        warpTransition.sameSectionTransition = warpTransition.TRANSITION_NONE
        warpTransition.crossSectionTransition = warpTransition.TRANSITION_NONE
        warpTransition.activateOnInstantWarps = false
    end
    if player.character == CHARACTER_SNAKE then
        smasHud.visible.keys = true
        smasHud.visible.itemBox = true
        smasHud.visible.bombs = true
        smasHud.visible.coins = true
        smasHud.visible.stars = true
        smasHud.visible.timer = true
        smasHud.visible.levelname = true
        smasHud.visible.overworldPlayer = true
    end
    if player.character == CHARACTER_NINJABOMBERMAN then
        smasHud.visible.keys = true
        smasHud.visible.itemBox = true
        smasHud.visible.bombs = true
        smasHud.visible.coins = true
        smasHud.visible.stars = true
        smasHud.visible.timer = true
        smasHud.visible.levelname = true
        smasHud.visible.overworldPlayer = true
    end
    if player.character == CHARACTER_UNCLEBROADSWORD then
        --smasHud.visible.lives = false
    end
    if player.character == CHARACTER_ULTIMATERINKA then
        smasHud.visible.keys = true
        smasHud.visible.itemBox = true
        smasHud.visible.bombs = true
        smasHud.visible.coins = true
        smasHud.visible.stars = true
        smasHud.visible.timer = true
        smasHud.visible.levelname = true
        smasHud.visible.overworldPlayer = true
    end
    for k,block in ipairs(Block.get(smasTables.allLavaBlockIDs)) do
        if block.idx >= 5000 then --Easter egg block IDX detection, for the epic 1.3 mode crash thingy
            blockIdx5000Check = true
        end
    end
    
    if SaveData.SMASPlusPlus.player[1].currentCostume == "SMB3-WALUIGI" and SaveData.currentCharacter == CHARACTER_YOSHI then
        Player.setCostume(10, nil)
    end
    
    if SaveData.GameOverCount == nil then
        SaveData.GameOverCount = 0
    end
    
    if SaveData.goombaStomps == nil then
        SaveData.goombaStomps = 0
    end
    if SaveData.koopaStomps == nil then
        SaveData.koopaStomps = 0
    end
    
    if SaveData.starmansused == nil then
        SaveData.starmansused = 0
    end
    if SaveData.megamushroomssused == nil then
        SaveData.megamushroomssused = 0
    end
    if SaveData.starsgrabbed == nil then
        SaveData.starsgrabbed = 0
    end
    if SaveData.totalmushrooms == nil then
        SaveData.totalmushrooms = 0
    end
    if SaveData.totalfireflowers == nil then
        SaveData.totalfireflowers = 0
    end
    if SaveData.totalleafs == nil then
        SaveData.totalleafs = 0
    end
    if SaveData.totaltanookis == nil then
        SaveData.totaltanookis = 0
    end
    if SaveData.totalhammersuits == nil then
        SaveData.totalhammersuits = 0
    end
    if SaveData.totaliceflowers == nil then
        SaveData.totaliceflowers = 0
    end
    if SaveData.mandatoryStars == nil then
        SaveData.mandatoryStars = 0
    end
    if SaveData.totalMandatoryStars == nil then
        SaveData.totalMandatoryStars = 200 --Value is final, all levels don't have to be beat to end the game
    end
    
    --Deals with secret win fanfares
    if Time.isLast2DigitsTheSameButWithout00(Timer.getValue()) then
        smasBooleans.isTimerInDoubleDigits = true
    elseif not Time.isLast2DigitsTheSameButWithout00(Timer.getValue()) then
        smasBooleans.isTimerInDoubleDigits = false
    end
end

function globalgenerals.onPostNPCKill(npc, harmType)
    for _,p in ipairs(Player.get()) do
        if smasTables.allGoombaNPCIDsTableMapped[npc.id] then
            SaveData.goombaStomps = SaveData.goombaStomps + 1
            SysManager.sendToConsole(tostring(SaveData.goombaStomps).." Goombas have been stomped in total.")
        end
        if smasTables.allKoopaNPCIDsTableMapped[npc.id] then
            SaveData.koopaStomps = SaveData.koopaStomps + 1
            SysManager.sendToConsole(tostring(SaveData.koopaStomps).." Koopas have been stomped in total.")
        end
        if smasTables.allStarmanNPCIDsTableMapped[npc.id] and Colliders.collide(p, npc) then
            SaveData.starmansused = SaveData.starmansused + 1
            SysManager.sendToConsole(tostring(SaveData.starmansused).." Starman's have been used in total.")
        end
        if npc.id == 997 and Colliders.collide(p, npc) then
            SaveData.megamushroomssused = SaveData.megamushroomssused + 1
            SysManager.sendToConsole(tostring(SaveData.megamushroomssused).." Mega Mushroom's have been used in total.")
        end
        if smasTables.allCollectableStarNPCIDsTableMapped[npc.id] and Colliders.collide(p, npc) then
            SaveData.starsgrabbed = SaveData.starsgrabbed + 1
            SysManager.sendToConsole(tostring(SaveData.starsgrabbed).." stars have been grabbed in total.")
        end
        if smasTables.allCoinNPCIDsTableMapped[npc.id] and Colliders.collide(p, npc) then
            SaveData.SMASPlusPlus.hud.coins = SaveData.SMASPlusPlus.hud.coins + 1
            SysManager.sendToConsole(tostring(SaveData.SMASPlusPlus.hud.coins).." coins have been collected in total.")
        end
        if smasTables.allMushroomNPCIDsTableMapped[npc.id] and Colliders.collide(p, npc) then
            SaveData.totalmushrooms = SaveData.totalmushrooms + 1
            SysManager.sendToConsole(tostring(SaveData.totalmushrooms).." Mushrooms have been used in total.")
        end
        if smasTables.allFireFlowerNPCIDsTableMapped[npc.id] and Colliders.collide(p, npc) then
            SaveData.totalfireflowers = SaveData.totalfireflowers + 1
            SysManager.sendToConsole(tostring(SaveData.totalfireflowers).." Fire Flowers have been used in total.")
        end
        if npc.id == 34 and Colliders.collide(p, npc) then
            SaveData.totalleafs = SaveData.totalleafs + 1
            SysManager.sendToConsole(tostring(SaveData.totalleafs).." Super Leafs have been used in total.")
        end
        if npc.id == 169 and Colliders.collide(p, npc) then
            SaveData.totaltanookis = SaveData.totaltanookis + 1
            SysManager.sendToConsole(tostring(SaveData.totaltanookis).." Tanooki Suits have been used in total.")
        end
        if npc.id == 170 and Colliders.collide(p, npc) then
            SaveData.totalhammersuits = SaveData.totalhammersuits + 1
            SysManager.sendToConsole(tostring(SaveData.totalhammersuits).." Hammer Suits have been used in total.")
        end
        if npc.id == 277 or npc.id == 264 and Colliders.collide(p, npc) then
            SaveData.totaliceflowers = SaveData.totaliceflowers + 1
            SysManager.sendToConsole(tostring(SaveData.totaliceflowers).." Ice Flowers have been used in total.")
        end
        if SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
            if smasTables.allInteractableNPCIDs[npc.id] then
                if blockIdx5000Check then
                    if harmType == HARM_TYPE_LAVA then
                        easterCrash = true
                        if not easterCrashPrevLoad then
                            Routine.run(lavaShroomEasterEgg)
                        end
                    end
                end
            end
        end
    end
end

local frametimer = 0
local actualframecount

function globalgenerals.onDraw()
    if not SaveData.SMASPlusPlus.game.onePointThreeModeActivated and not Misc.inMarioChallenge() then
        if player.character <= 5 then
            if SaveData.SMASPlusPlus.player[1].currentCostume == "N/A" then
                player:setCostume(playerManager.getCostumes(player.character)[1])
            end
        end
    elseif SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
        if player.character <= 5 then
            if SaveData.SMASPlusPlus.player[1].currentCostume ~= "N/A" then
                player:setCostume(nil)
            end
        end
    end
    if SaveData._basegame.hud.score >= 9999900 then --Fixing combo sounds when score is set as it's max
        SaveData._basegame.hud.score = 9990000
    end
    
    --Framerate timer stuff
    frametimer = frametimer + 1
    if actualframecount == nil then
        actualframecount = tostring(0)
    end
    if not Misc.isPaused() then
        if frametimer >= 65 then
            actualframecount = tostring(mem(0x00B2C670, FIELD_DWORD))
            frametimer = 0
        end
    end
    if SaveData.SMASPlusPlus.options.enableFramerateCounter then
        textplus.print{x = 8, y = 8, text = actualframecount, font = numberfont, priority = 10, xscale = 1, yscale = 1}
    end
    
    if easterCrashMsg then
        textplus.print{x=Screen.calculateCameraDimensions(145, 1), y=Screen.calculateCameraDimensions(80, 2), text = "Congrats! You reached more than the 5000th block idx and burned a ", priority=5, color=Color.yellow, font=statusFont}
        textplus.print{x=Screen.calculateCameraDimensions(155, 1), y=Screen.calculateCameraDimensions(90, 2), text = "collectable in the lava. This would've crashed SMBX 1.3!", priority=5, color=Color.yellow, font=statusFont}
        textplus.print{x=Screen.calculateCameraDimensions(195, 1), y=Screen.calculateCameraDimensions(100, 2), text = "You're really good at finding secrets, player ;)", priority=5, color=Color.yellow, font=statusFont}
    end
    
    for _,p in ipairs(Player.get()) do --Custom reserve storage
        if p.reservePowerup ~= 0 then
            SaveData.SMASPlusPlus.hud.reserve[_] = p.reservePowerup
            p.reservePowerup = 0
        end
    end
end

function globalgenerals.onExitLevel(winType)
    SysManager.exitLevel(winType)
    if Misc.inEditor() then
        for _,p in ipairs(Player.get()) do
            if SaveData.SMASPlusPlus.hud.reserve[_] ~= 0 then
                GameData.tempReserve[_] = SaveData.SMASPlusPlus.hud.reserve[_]
            end
        end
    end
end

function globalgenerals.onExit()
    if mem(0x00B2C5AC,FIELD_FLOAT) == 0 then
        if (killed == true or killed2 == true) then
            mem(0x00B2C5AC,FIELD_FLOAT,1)
            Level.load(Level.filename())
        end
    end
    if mem(0x00B2C89C, FIELD_BOOL) then --Let's prevent the credits from execution.
        SysManager.sendToConsole("Credits exiting detected! Exiting to the credits level...")
        Level.load("SMAS - Credits.lvlx")
    end
    if not table.icontains(smasTables._friendlyPlaces,Level.filename()) then
        SaveData.lastLevelPlayed = Level.filename()
    end
    if not Misc.inMarioChallenge() then
        for _,p in ipairs(Player.get()) do
            if Misc.inEditor() then
                GameData.tempReserve[p.idx] = p.reservePowerup
            end
        end
        File.writeToFile("loadscreeninfo.txt", "normal,"..tostring(camera.width)..","..tostring(camera.height))
    elseif Misc.inMarioChallenge() then
        File.writeToFile("loadscreeninfo.txt", "mariochallenge,"..tostring(camera.width)..","..tostring(camera.height))
    end
end

return globalgenerals