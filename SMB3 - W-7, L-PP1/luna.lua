local level_dependencies_normal= require("level_dependencies_normal")

function onEvent(eventName)
    if eventName == "Shake Screen" then
        Sound.playSFX(22)
        Defines.earthquake = 5
    end
    if eventName == "Reward Received" then
        Sound.muteMusic(-1)
        inventory.addPowerUp(6, 1)
        Sound.playSFX("chest.ogg")
        Sound.playSFX("_OST/Super Mario Bros 3/Battle Mode Win.ogg")
    end
    if eventName == "Win Level" then
        Level.exit(LEVEL_WIN_TYPE_STAR)
    end
end