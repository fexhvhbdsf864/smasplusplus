local level_dependencies_normal= require("level_dependencies_normal")

function onEvent(eventName)
    if eventName == "Boss Start" then
        Sound.changeMusic("_OST/Super Mario Bros Spencer/Boss Battle.ogg|m1;c2;r2", 0)
    end
    if eventName == "Boss End" then
        Sound.changeMusic("_OST/Super Mario Bros Spencer/Athletic.ogg|m1;c2;r2", 0)
    end
end