local _, addon = ...

addon.profiles = {
    HUNTER = {
        beastmastery = { label = "Beast Mastery", weights = {
            hit = 14, crit = 12, dpsRanged = 7, speedRanged = 5, agi = 1.25,
            mp5 = 0.6, rap = 0.5, ap = 0.5, dps2h = 0.5, int = 0.3,
            stamina = 0.3, dpsMH = 0.3, dpsOH = 0.2, spirit = 0.1, str = 0.1,
        } },
        marksmanship = { label = "Marksmanship", weights = {
            hit = 14, crit = 13, dpsRanged = 7.5, speedRanged = 6, agi = 1.25,
            mp5 = 0.6, rap = 0.5, ap = 0.5, dps2h = 0.5, int = 0.3,
            dpsMH = 0.3, stamina = 0.25, dpsOH = 0.2, spirit = 0.1, str = 0.1,
        } },
        survival = { label = "Survival", weights = {
            hit = 14, crit = 12, dpsRanged = 7, speedRanged = 4, agi = 1.25,
            mp5 = 0.6, dps2h = 0.6, rap = 0.5, ap = 0.5, dpsMH = 0.35,
            int = 0.3, stamina = 0.3, dpsOH = 0.2, str = 0.15, spirit = 0.1,
        } },
    },
    MAGE = {
        arcane = { label = "Arcane", weights = {
            hit = 12, crit = 9, dpsRanged = 2, mp5 = 1.5, spellpower = 1,
            arcane = 0.9, frost = 0.5, int = 0.85, mana = 0.03, stamina = 0.2, spirit = 0.1,
        } },
        fire = { label = "Fire", weights = {
            hit = 13, crit = 11, dpsRanged = 2, spellpower = 1, fire = 0.95,
            mp5 = 0.8, int = 0.35, stamina = 0.2, spirit = 0.1,
        } },
        frost = { label = "Frost", weights = {
            hit = 12, crit = 10, dpsRanged = 2, spellpower = 1, frost = 0.95,
            mp5 = 0.8, int = 0.35, stamina = 0.25, spirit = 0.1,
        } },
    },
    ROGUE = {
        assassination = { label = "Assassination", weights = {
            hit = 16, crit = 14, dpsMH = 4.5, dpsOH = 2, speedMH = 5, speedOH = -4,
            agi = 1, str = 0.6, ap = 0.5, stamina = 0.3, dpsRanged = 0.2,
        } },
        combat = { label = "Combat", weights = {
            hit = 16, crit = 12, dpsMH = 4, dpsOH = 2.5, speedMH = 4, speedOH = -3,
            agi = 1, str = 0.6, ap = 0.5, stamina = 0.3, dpsRanged = 0.2,
        } },
        subtlety = { label = "Subtlety", weights = {
            hit = 15, crit = 14, dpsMH = 4, dpsOH = 2, speedMH = 5, speedOH = -2,
            agi = 1.05, str = 0.55, ap = 0.5, stamina = 0.3, dpsRanged = 0.2,
        } },
    },
    WARRIOR = {
        arms = { label = "Arms", weights = {
            hit = 14, crit = 12, dps2h = 6.5, speed2h = 8, dpsMH = 3,
            dpsOH = 1.2, str = 1, agi = 0.6, ap = 0.5, stamina = 0.35, hp5 = 0.1, armor = 0.004,
        } },
        fury = { label = "Fury", weights = {
            hit = 16, crit = 14, dps2h = 6.5, dpsMH = 4, dpsOH = 2.2,
            speedMH = 3, speedOH = -3, str = 1, agi = 0.7, ap = 0.5, stamina = 0.35,
        } },
        protection = { label = "Protection (Tanking)", weights = {
            dodge = 12, parry = 10, hit = 6, block = 5, crit = 4, dpsMH = 2,
            dps2h = 1.5, defense = 1.3, stamina = 1, agi = 0.8, str = 0.45,
            blockValue = 0.4, hp5 = 0.3, ap = 0.25, armor = 0.008,
        } },
    },
    SHAMAN = {
        elemental = { label = "Elemental", weights = {
            mp5 = 1.5, spellpower = 1, nature = 0.9, fire = 0.5, int = 0.45,
            stamina = 0.25, spirit = 0.1, hit = 12, crit = 10, armor = 0.002, dpsMH = 0.4,
        } },
        enhancement = { label = "Enhancement", weights = {
            str = 1, agi = 0.8, ap = 0.5, hit = 14, crit = 14, int = 0.25,
            spellpower = 0.2, nature = 0.15, stamina = 0.35, dps2h = 6.5, dpsMH = 4,
            speed2h = 10, armor = 0.003,
        } },
        restoration = { label = "Restoration (Healing)", weights = {
            heal = 1, spellpower = 1, mp5 = 3, int = 0.5, spirit = 0.3,
            crit = 5, stamina = 0.25, nature = 0.15,
        } },
    },
    PALADIN = {
        holy = { label = "Holy (Healing)", weights = {
            crit = 8, mp5 = 2.5, heal = 1, spellpower = 1, holy = 0.8,
            int = 0.55, spirit = 0.25, stamina = 0.25, dpsMH = 0.1, dps2h = 0.1,
        } },
        protection = { label = "Protection (Tanking)", weights = {
            dodge = 12, parry = 10, block = 6, hit = 4, crit = 3, dpsMH = 1.5,
            defense = 1.2, stamina = 1, mp5 = 0.8, blockValue = 0.5,
            agi = 0.75, str = 0.4, spellpower = 0.25, holy = 0.25, int = 0.3,
            ap = 0.2, armor = 0.008,
        } },
        retribution = { label = "Retribution", weights = {
            hit = 14, crit = 12, dps2h = 6, speed2h = 10, dpsMH = 2,
            str = 1, ap = 0.5, agi = 0.6, stamina = 0.3, spellpower = 0.25,
            holy = 0.25, int = 0.1,
        } },
    },
    PRIEST = {
        discipline = { label = "Discipline (Healing)", weights = {
            crit = 6, mp5 = 2.8, dpsRanged = 1.5, heal = 1, spellpower = 1,
            holy = 0.4, int = 0.6, spirit = 0.55, stamina = 0.25,
        } },
        holy = { label = "Holy (Healing)", weights = {
            crit = 7, mp5 = 3, dpsRanged = 1.5, heal = 1, spellpower = 1,
            holy = 0.35, int = 0.5, spirit = 0.65, stamina = 0.2,
        } },
        shadow = { label = "Shadow", weights = {
            hit = 12, crit = 8, dpsRanged = 2.5, spellpower = 1, shadow = 1,
            mp5 = 1, int = 0.35, spirit = 0.35, stamina = 0.3,
        } },
    },
    DRUID = {
        balance = { label = "Balance", weights = {
            hit = 12, crit = 9, mp5 = 1.5, spellpower = 1, arcane = 0.7,
            nature = 0.7, int = 0.4, spirit = 0.25, stamina = 0.25,
        } },
        feral = { label = "Feral (DPS)", weights = {
            hit = 14, crit = 12, agi = 1, str = 1, ap = 0.5, fap = 0.5,
            stamina = 0.3, int = 0.1, dps2h = 5, dpsMH = 5,
        } },
        feraltank = { label = "Feral (Tanking)", weights = {
            dodge = 12, hit = 5, crit = 4, stamina = 1.1, defense = 1, agi = 1.15,
            str = 0.55, ap = 0.35, fap = 0.35, int = 0.05, armor = 0.012,
            dps2h = 1.2, dpsMH = 1.2,
        } },
        restoration = { label = "Restoration (Healing)", weights = {
            crit = 4, mp5 = 3, heal = 1, spellpower = 1, spirit = 0.6, int = 0.5, stamina = 0.2,
        } },
    },
    WARLOCK = {
        affliction = {
            label = "Affliction",
            weights = {
                spellpower = 1, shadow = 0.95, hit = 13, crit = 6,
                mp5 = 1.3, int = 0.4, spirit = 0.25, stamina = 0.35, dpsRanged = 1.5,
            },
        },
        demonology = {
            label = "Demonology",
            weights = {
                spellpower = 1, shadow = 0.8, fire = 0.35, hit = 12,
                crit = 8, mp5 = 1, int = 0.4, stamina = 0.5, spirit = 0.15, dpsRanged = 1.2,
            },
        },
        destruction = {
            label = "Destruction",
            weights = {
                spellpower = 1, fire = 0.9, shadow = 0.65, hit = 13,
                crit = 11, mp5 = 0.8, int = 0.35, stamina = 0.2, spirit = 0.1, dpsRanged = 2,
            },
        },
    },
}
