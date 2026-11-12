local _, addon = ...

addon.profiles = {
    WARLOCK = {
        affliction = {
            label = "Affliction",
            weights = {
                spellpower = 1, shadow = 0.95, hit = 13, crit = 6,
                mp5 = 1.3, int = 0.4, spirit = 0.25, stamina = 0.35,
            },
        },
        demonology = {
            label = "Demonology",
            weights = {
                spellpower = 1, shadow = 0.8, fire = 0.35, hit = 12,
                crit = 8, mp5 = 1, int = 0.4, stamina = 0.5, spirit = 0.15,
            },
        },
        destruction = {
            label = "Destruction",
            weights = {
                spellpower = 1, fire = 0.9, shadow = 0.65, hit = 13,
                crit = 11, mp5 = 0.8, int = 0.35, stamina = 0.2, spirit = 0.1,
            },
        },
    },
}
