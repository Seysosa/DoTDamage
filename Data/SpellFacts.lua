local facts = { families = {}, excluded = {} }
facts.families["druid/lacerate"] = {
    class = "DRUID", owner = "player", mode = "fixed", maxStacks = 5,
    names = { "Aufschlitzen", "Lacerate" },
    ranks = {
        [414644] = { classic = { interval = 3.0, duration = 15.0, school = 1, icon = 132131 }, forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132131 } },
        [1235826] = { forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132131 } },
        [1235827] = { forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132131 } },
    },
}
facts.families["druid/moonfire"] = {
    class = "DRUID", owner = "player", mode = "fixed",
    names = { "Mondfeuer", "Moonfire" },
    ranks = {
        [8921] = { classic = { interval = 3.0, duration = 9.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 9.0, school = 64, icon = 136096 } },
        [8924] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [8925] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [8926] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [8927] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [8928] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [8929] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [9833] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [9834] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [9835] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [20690] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [21669] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
        [429823] = { classic = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 }, forever = { interval = 3.0, duration = 12.0, school = 64, icon = 136096 } },
    },
}
facts.families["druid/rake"] = {
    class = "DRUID", owner = "player", mode = "fixed",
    names = { "Krallenhieb", "Rake" },
    ranks = {
        [1822] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [1823] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [1824] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [9904] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [24331] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [24332] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132122 } },
        [27556] = { classic = { interval = 3.0, duration = 15.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132122 } },
        [27638] = { classic = { interval = 3.0, duration = 15.0, school = 1, icon = 132122 }, forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132122 } },
    },
}
facts.families["druid/rip"] = {
    class = "DRUID", owner = "player", mode = "finisher",
    names = { "Rip", "Zerfetzen" },
    ranks = {
        [1079] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
        [9492] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
        [9493] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
        [9752] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
        [9894] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
        [9896] = { classic = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 }, forever = { interval = 2.0, duration = 12.0, school = 1, icon = 132152 } },
    },
}
facts.families["druid/roots"] = {
    class = "DRUID", owner = "player", mode = "control",
    names = { "Entangling Roots", "Wucherwurzeln" },
    ranks = {
        [339] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 136100 } },
        [1062] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 136100 } },
        [5195] = { classic = { interval = 3.0, duration = 18.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 18.0, school = 8, icon = 136100 } },
        [5196] = { classic = { interval = 3.0, duration = 21.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 21.0, school = 8, icon = 136100 } },
        [9852] = { classic = { interval = 3.0, duration = 24.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 24.0, school = 8, icon = 136100 } },
        [9853] = { classic = { interval = 3.0, duration = 27.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 27.0, school = 8, icon = 136100 } },
        [19970] = { classic = { interval = 3.0, duration = 27.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 27.0, school = 8, icon = 136100 } },
        [19971] = { classic = { interval = 3.0, duration = 24.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 24.0, school = 8, icon = 136100 } },
        [19972] = { classic = { interval = 3.0, duration = 21.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 21.0, school = 8, icon = 136100 } },
        [19973] = { classic = { interval = 3.0, duration = 18.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 18.0, school = 8, icon = 136100 } },
        [19974] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 136100 } },
        [19975] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 136100 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 136100 } },
    },
}
facts.families["druid/swarm"] = {
    class = "DRUID", owner = "player", mode = "fixed",
    names = { "Insect Swarm", "Insektenschwarm" },
    ranks = {
        [5570] = { classic = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 }, forever = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 } },
        [24974] = { classic = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 }, forever = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 } },
        [24975] = { classic = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 }, forever = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 } },
        [24976] = { classic = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 }, forever = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 } },
        [24977] = { classic = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 }, forever = { interval = 2.0, duration = 12.0, school = 8, icon = 136045 } },
    },
}
facts.families["hunter/lacerating"] = {
    class = "HUNTER", owner = "player", mode = "triggered",
    names = { "Aufschlitzende Schläge", "Lacerating Strikes" },
    ranks = {
        [1310533] = { forever = { interval = 0, duration = 0, school = 1, icon = 132155 } },
        [1310536] = { forever = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 } },
    },
}
facts.families["hunter/rend"] = {
    class = "HUNTER", owner = "pet", mode = "pet",
    names = { "Savage Rend", "Wildes Verwunden" },
    ranks = {
        [1265065] = { forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132193 } },
        [1265066] = { forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132193 } },
        [1265067] = { forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132193 } },
        [1265068] = { forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132193 } },
        [1265069] = { forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132193 } },
    },
}
facts.families["hunter/scorpid"] = {
    class = "HUNTER", owner = "pet", mode = "pet", maxStacks = 5,
    names = { "Scorpid Poison", "Skorpidgift" },
    ranks = {
        [24583] = { classic = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 }, forever = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 } },
        [24586] = { classic = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 }, forever = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 } },
        [24587] = { classic = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 }, forever = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 } },
        [24640] = { classic = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 }, forever = { interval = 2.0, duration = 10.0, school = 8, icon = 132274 } },
    },
}
facts.families["hunter/sting"] = {
    class = "HUNTER", owner = "player", mode = "fixed",
    names = { "Schlangenbiss", "Serpent Sting" },
    ranks = {
        [1978] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13549] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13550] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13551] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13552] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13553] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13554] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [13555] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [25295] = { classic = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 15.0, school = 8, icon = 132204 } },
        [425728] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425729] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425730] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425732] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425733] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425734] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425735] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425736] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [425737] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132204 } },
        [1232979] = { classic = { interval = 3.0, duration = 21.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 21.0, school = 8, icon = 132204 } },
        [1232980] = { classic = { interval = 3.0, duration = 42.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 42.0, school = 8, icon = 132204 } },
        [1232981] = { classic = { interval = 3.0, duration = 63.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 63.0, school = 8, icon = 132204 } },
        [1232982] = { classic = { interval = 3.0, duration = 84.0, school = 8, icon = 132204 }, forever = { interval = 3.0, duration = 84.0, school = 8, icon = 132204 } },
    },
}
facts.families["hunter/tendon"] = {
    class = "HUNTER", owner = "pet", mode = "pet",
    names = { "Sehnenriss", "Tendon Rip" },
    ranks = {
        [1265038] = { forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132190 } },
        [1265039] = { forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132190 } },
        [1265040] = { forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132190 } },
        [1265041] = { forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132190 } },
        [1265042] = { forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132190 } },
    },
}
facts.families["hunter/web"] = {
    class = "HUNTER", owner = "pet", mode = "pet",
    names = { "Gespinst", "Web" },
    ranks = {
        [1265843] = { forever = { interval = 1.0, duration = 4.0, school = 8, icon = 136113 } },
        [1265878] = { forever = { interval = 1.0, duration = 4.0, school = 8, icon = 136113 } },
        [1265880] = { forever = { interval = 1.0, duration = 4.0, school = 8, icon = 136113 } },
        [1265881] = { forever = { interval = 1.0, duration = 4.0, school = 8, icon = 136113 } },
        [1265883] = { forever = { interval = 1.0, duration = 4.0, school = 8, icon = 136113 } },
    },
}
facts.families["mage/fireball"] = {
    class = "MAGE", owner = "player", mode = "fixed", maxStacks = 1,
    names = { "Feuerball", "Fireball" },
    ranks = {
        [133] = { classic = { interval = 2.0, duration = 4.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 4.0, school = 4, icon = 135812 } },
        [143] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135812 } },
        [145] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135812 } },
        [3140] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [8400] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [8401] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [8402] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [10148] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [10149] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [10150] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [10151] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [13438] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [15662] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [16412] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [16413] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 1.0, duration = 7.0, school = 4, icon = 135810 } },
        [16415] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 } },
        [18082] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [18105] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 } },
        [18108] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 } },
        [18199] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [18796] = { classic = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
        [21159] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135810 } },
        [21162] = { classic = { interval = 2.0, duration = 10.0, school = 4, icon = 135810 }, forever = { interval = 2.0, duration = 10.0, school = 4, icon = 135810 } },
        [25306] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135812 } },
        [1299850] = { forever = { interval = 2.0, duration = 6.0, school = 4, icon = 135810 } },
    },
}
facts.families["mage/frostfire"] = {
    class = "MAGE", owner = "player", mode = "fixed", maxStacks = 1,
    names = { "Frostfeuerblitz", "Frostfire Bolt" },
    ranks = {
        [401502] = { classic = { interval = 3.0, duration = 9.0, school = 20, icon = 236217 }, forever = { interval = 3.0, duration = 9.0, school = 20, icon = 236217 } },
        [1237312] = { forever = { interval = 3.0, duration = 9.0, school = 20, icon = 236217 } },
        [1237313] = { forever = { interval = 3.0, duration = 9.0, school = 20, icon = 236217 } },
    },
}
facts.families["mage/ignite"] = {
    class = "MAGE", owner = "player", mode = "triggered", damageModel = "observed",
    names = { "Entzünden", "Ignite" },
    ranks = {
        [11119] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 135818 }, forever = { interval = 0, duration = 0, school = 1, icon = 135818 } },
        [11120] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 135818 } },
        [12654] = { classic = { interval = 2.0, duration = 4.0, school = 4, icon = 135818 } },
        [12846] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 135818 } },
        [12847] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 135818 } },
        [12848] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 135818 } },
        [412538] = { classic = { interval = 0, duration = 4.0, school = 4, icon = 135818 }, forever = { interval = 0, duration = 4.0, school = 4, icon = 135818 } },
        [412545] = { classic = { interval = 0, duration = 0, school = 4, icon = 135818 }, forever = { interval = 0, duration = 0, school = 4, icon = 135818 } },
    },
}
facts.families["mage/pyroblast"] = {
    class = "MAGE", owner = "player", mode = "fixed", maxStacks = 1,
    names = { "Pyroblast", "Pyroschlag" },
    ranks = {
        [11366] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12505] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12522] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12523] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12524] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12525] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [12526] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [17273] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [17274] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [18809] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [20228] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [434443] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [460858] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135808 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135808 } },
        [460860] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [1236173] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
        [1236291] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135808 } },
    },
}
facts.families["priest/holyfire"] = {
    class = "PRIEST", owner = "player", mode = "fixed",
    names = { "Heiliges Feuer", "Holy Fire" },
    ranks = {
        [14914] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15261] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15262] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15263] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15264] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15265] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15266] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [15267] = { classic = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 }, forever = { interval = 2.0, duration = 10.0, school = 2, icon = 135972 } },
        [17140] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 } },
        [17141] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 } },
        [17142] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 } },
        [18165] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 } },
        [23860] = { classic = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 }, forever = { interval = 2.0, duration = 8.0, school = 4, icon = 135972 } },
    },
}
facts.families["priest/pain"] = {
    class = "PRIEST", owner = "player", mode = "fixed",
    names = { "Schattenwort: Schmerz", "Shadow Word: Pain" },
    ranks = {
        [589] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [594] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [970] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [992] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [2767] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [10892] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [10893] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [10894] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
        [27605] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136207 } },
    },
}
facts.families["priest/plague"] = {
    class = "PRIEST", owner = "player", mode = "fixed",
    names = { "Devouring Plague", "Verschlingende Seuche" },
    ranks = {
        [2944] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
        [19276] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
        [19277] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
        [19278] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
        [19279] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
        [19280] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136123 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 252997 } },
    },
}
facts.families["rogue/garrote"] = {
    class = "ROGUE", owner = "player", mode = "fixed",
    names = { "Erdrosseln", "Garrote" },
    ranks = {
        [703] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [8631] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [8632] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [8633] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [11289] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [11290] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462724] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462726] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462727] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462728] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462729] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
        [462730] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132297 } },
    },
}
facts.families["rogue/poison"] = {
    class = "ROGUE", owner = "player", mode = "triggered", maxStacks = 5,
    names = { "Deadly Poison", "Deadly Poison II", "Deadly Poison III", "Deadly Poison IV", "Deadly Poison V", "Deadly Poison VI", "Deadly Poison VII", "Tödliches Gift", "Tödliches Gift II", "Tödliches Gift III", "Tödliches Gift IV", "Tödliches Gift V" },
    ranks = {
        [2818] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [2819] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [2823] = { classic = { interval = 0, duration = 0, school = 1, icon = 132290 }, forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [2824] = { classic = { interval = 0, duration = 0, school = 1, icon = 132290 }, forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [2835] = { forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [2837] = { forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [11353] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [11354] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [11355] = { classic = { interval = 0, duration = 0, school = 1, icon = 132290 }, forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [11356] = { classic = { interval = 0, duration = 0, school = 1, icon = 132290 }, forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [11357] = { forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [11358] = { forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [25347] = { forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [25349] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [25351] = { classic = { interval = 0, duration = 0, school = 1, icon = 132290 }, forever = { interval = 0, duration = 0, school = 1, icon = 132290 } },
        [434312] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [434313] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [434314] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [434315] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
        [434316] = { classic = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 }, forever = { interval = 3.0, duration = 12.0, school = 8, icon = 132290 } },
    },
}
facts.families["rogue/rupture"] = {
    class = "ROGUE", owner = "player", mode = "finisher",
    names = { "Blutung", "Bruch", "Rupture" },
    ranks = {
        [1943] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [8639] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [8640] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [11273] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [11274] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [11275] = { classic = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 6.0, school = 1, icon = 132302 } },
        [14874] = { classic = { interval = 2.0, duration = 10.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 10.0, school = 1, icon = 132302 } },
        [14903] = { classic = { interval = 2.0, duration = 2.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 2.0, school = 1, icon = 132302 } },
        [15583] = { classic = { interval = 2.0, duration = 10.0, school = 1, icon = 132302 }, forever = { interval = 2.0, duration = 10.0, school = 1, icon = 132302 } },
        [1271514] = { forever = { interval = 2.0, duration = 10.0, school = 1, icon = 132302 } },
    },
}
facts.families["shaman/flameshock"] = {
    class = "SHAMAN", owner = "player", mode = "fixed",
    names = { "Flame Shock", "Flammenschock" },
    ranks = {
        [8050] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
        [8052] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
        [8053] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
        [10447] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
        [10448] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
        [29228] = { classic = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 }, forever = { interval = 3.0, duration = 12.0, school = 4, icon = 135813 } },
    },
}
facts.families["warlock/agony"] = {
    class = "WARLOCK", owner = "player", mode = "ramp", maxStacks = 1,
    names = { "Bane of Agony", "Curse of Agony", "Fluch der Pein", "Omen der Pein" },
    replacementGroup = "warlock/affliction",
    ranks = {
        [980] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
        [1014] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
        [6217] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
        [11711] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
        [11712] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
        [11713] = { classic = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 }, forever = { interval = 2.0, duration = 24.0, school = 32, icon = 136139 } },
    },
}
facts.families["warlock/corruption"] = {
    class = "WARLOCK", owner = "player", mode = "fixed", maxStacks = 1,
    names = { "Corruption", "Verderbnis" },
    ranks = {
        [172] = { classic = { interval = 3.0, duration = 12.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 12.0, school = 32, icon = 136118 } },
        [6222] = { classic = { interval = 3.0, duration = 15.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 15.0, school = 32, icon = 136118 } },
        [6223] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 } },
        [7648] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 } },
        [11671] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 } },
        [11672] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 } },
        [21068] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 136118 } },
        [25311] = { classic = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 18.0, school = 32, icon = 136118 } },
        [1213450] = { classic = { interval = 3.0, duration = 24.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 24.0, school = 32, icon = 136118 } },
        [1223963] = { classic = { interval = 3.0, duration = 12.0, school = 32, icon = 136118 }, forever = { interval = 3.0, duration = 12.0, school = 32, icon = 136118 } },
    },
}
facts.families["warlock/doom"] = {
    class = "WARLOCK", owner = "player", mode = "delayed", maxStacks = 1,
    names = { "Bane of Doom", "Curse of Doom", "Fluch der Verdammnis", "Omen der Verdammnis" },
    replacementGroup = "warlock/affliction",
    ranks = {
        [603] = { classic = { interval = 60.0, duration = 60.0, school = 32, icon = 136122 }, forever = { interval = 60.0, duration = 60.0, school = 32, icon = 136122 } },
        [449432] = { classic = { interval = 60.0, duration = 60.0, school = 32, icon = 136122 }, forever = { interval = 60.0, duration = 60.0, school = 32, icon = 136122 } },
    },
}
facts.families["warlock/immolate"] = {
    class = "WARLOCK", owner = "player", mode = "fixed", maxStacks = 1,
    names = { "Feuerbrand", "Immolate" },
    ranks = {
        [348] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [707] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [1094] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [2941] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [11665] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [11667] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [11668] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
        [25309] = { classic = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 }, forever = { interval = 3.0, duration = 15.0, school = 4, icon = 135817 } },
    },
}
facts.families["warlock/siphon"] = {
    class = "WARLOCK", owner = "player", mode = "fixed", maxStacks = 1, leech = true,
    names = { "Lebensentzug", "Siphon Life" },
    ranks = {
        [18265] = { classic = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 }, forever = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 } },
        [18879] = { classic = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 }, forever = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 } },
        [18880] = { classic = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 }, forever = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 } },
        [18881] = { classic = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 }, forever = { interval = 3.0, duration = 30.0, school = 32, icon = 136188 } },
    },
}
facts.families["warrior/rend"] = {
    class = "WARRIOR", owner = "player", mode = "fixed",
    names = { "Rend", "Verwunden" },
    ranks = {
        [772] = { classic = { interval = 3.0, duration = 9.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 9.0, school = 1, icon = 132155 } },
        [6546] = { classic = { interval = 3.0, duration = 12.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 12.0, school = 1, icon = 132155 } },
        [6547] = { classic = { interval = 3.0, duration = 15.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 15.0, school = 1, icon = 132155 } },
        [6548] = { classic = { interval = 3.0, duration = 18.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 18.0, school = 1, icon = 132155 } },
        [11572] = { classic = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 } },
        [11573] = { classic = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 } },
        [11574] = { classic = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 }, forever = { interval = 3.0, duration = 21.0, school = 1, icon = 132155 } },
    },
}
facts.families["warrior/wounds"] = {
    class = "WARRIOR", owner = "player", mode = "triggered",
    names = { "Deep Wounds", "Tiefe Wunden" },
    ranks = {
        [12834] = { classic = { interval = 0, duration = 0, school = 1, icon = 132090 }, forever = { interval = 0, duration = 0, school = 1, icon = 132090 } },
        [12849] = { classic = { interval = 0, duration = 0, school = 1, icon = 132090 } },
        [12867] = { classic = { interval = 0, duration = 0, school = 1, icon = 132090 } },
        [23255] = { classic = { interval = 0, duration = 0.0, school = 1, icon = 132090 }, forever = { interval = 0, duration = 0.0, school = 1, icon = 132090 } },
    },
}
facts.excluded[10] = true
facts.excluded[496] = true
facts.excluded[689] = true
facts.excluded[699] = true
facts.excluded[709] = true
facts.excluded[711] = true
facts.excluded[714] = true
facts.excluded[725] = true
facts.excluded[730] = true
facts.excluded[736] = true
facts.excluded[755] = true
facts.excluded[846] = true
facts.excluded[862] = true
facts.excluded[872] = true
facts.excluded[1120] = true
facts.excluded[1196] = true
facts.excluded[1367] = true
facts.excluded[1368] = true
facts.excluded[1369] = true
facts.excluded[1401] = true
facts.excluded[1510] = true
facts.excluded[1540] = true
facts.excluded[1564] = true
facts.excluded[1598] = true
facts.excluded[1949] = true
facts.excluded[2075] = true
facts.excluded[2120] = true
facts.excluded[2121] = true
facts.excluded[2124] = true
facts.excluded[2125] = true
facts.excluded[3067] = true
facts.excluded[3068] = true
facts.excluded[3354] = true
facts.excluded[3599] = true
facts.excluded[3698] = true
facts.excluded[3699] = true
facts.excluded[3700] = true
facts.excluded[3701] = true
facts.excluded[3702] = true
facts.excluded[3703] = true
facts.excluded[3704] = true
facts.excluded[3705] = true
facts.excluded[3706] = true
facts.excluded[3707] = true
facts.excluded[3732] = true
facts.excluded[3751] = true
facts.excluded[4629] = true
facts.excluded[5138] = true
facts.excluded[5139] = true
facts.excluded[5143] = true
facts.excluded[5144] = true
facts.excluded[5145] = true
facts.excluded[5146] = true
facts.excluded[5147] = true
facts.excluded[5148] = true
facts.excluded[5709] = true
facts.excluded[5740] = true
facts.excluded[5741] = true
facts.excluded[6141] = true
facts.excluded[6142] = true
facts.excluded[6219] = true
facts.excluded[6220] = true
facts.excluded[6226] = true
facts.excluded[6227] = true
facts.excluded[6363] = true
facts.excluded[6364] = true
facts.excluded[6365] = true
facts.excluded[6379] = true
facts.excluded[6380] = true
facts.excluded[6381] = true
facts.excluded[6631] = true
facts.excluded[6632] = true
facts.excluded[6637] = true
facts.excluded[7269] = true
facts.excluded[7270] = true
facts.excluded[7378] = true
facts.excluded[7651] = true
facts.excluded[7652] = true
facts.excluded[7653] = true
facts.excluded[7662] = true
facts.excluded[8187] = true
facts.excluded[8189] = true
facts.excluded[8190] = true
facts.excluded[8200] = true
facts.excluded[8288] = true
facts.excluded[8289] = true
facts.excluded[8290] = true
facts.excluded[8291] = true
facts.excluded[8364] = true
facts.excluded[8416] = true
facts.excluded[8417] = true
facts.excluded[8418] = true
facts.excluded[8419] = true
facts.excluded[8420] = true
facts.excluded[8421] = true
facts.excluded[8422] = true
facts.excluded[8423] = true
facts.excluded[8425] = true
facts.excluded[8426] = true
facts.excluded[8427] = true
facts.excluded[8428] = true
facts.excluded[10185] = true
facts.excluded[10186] = true
facts.excluded[10187] = true
facts.excluded[10188] = true
facts.excluded[10189] = true
facts.excluded[10190] = true
facts.excluded[10211] = true
facts.excluded[10212] = true
facts.excluded[10213] = true
facts.excluded[10214] = true
facts.excluded[10215] = true
facts.excluded[10216] = true
facts.excluded[10217] = true
facts.excluded[10218] = true
facts.excluded[10273] = true
facts.excluded[10274] = true
facts.excluded[10437] = true
facts.excluded[10438] = true
facts.excluded[10439] = true
facts.excluded[10440] = true
facts.excluded[10579] = true
facts.excluded[10580] = true
facts.excluded[10581] = true
facts.excluded[10585] = true
facts.excluded[10586] = true
facts.excluded[10587] = true
facts.excluded[10588] = true
facts.excluded[10589] = true
facts.excluded[10590] = true
facts.excluded[10797] = true
facts.excluded[11675] = true
facts.excluded[11676] = true
facts.excluded[11677] = true
facts.excluded[11678] = true
facts.excluded[11679] = true
facts.excluded[11680] = true
facts.excluded[11683] = true
facts.excluded[11684] = true
facts.excluded[11685] = true
facts.excluded[11686] = true
facts.excluded[11693] = true
facts.excluded[11694] = true
facts.excluded[11695] = true
facts.excluded[11696] = true
facts.excluded[11697] = true
facts.excluded[11698] = true
facts.excluded[11699] = true
facts.excluded[11700] = true
facts.excluded[11701] = true
facts.excluded[11702] = true
facts.excluded[11703] = true
facts.excluded[11704] = true
facts.excluded[11705] = true
facts.excluded[11706] = true
facts.excluded[11829] = true
facts.excluded[11990] = true
facts.excluded[12468] = true
facts.excluded[12693] = true
facts.excluded[13795] = true
facts.excluded[13797] = true
facts.excluded[13799] = true
facts.excluded[13812] = true
facts.excluded[13813] = true
facts.excluded[13814] = true
facts.excluded[14294] = true
facts.excluded[14295] = true
facts.excluded[14298] = true
facts.excluded[14299] = true
facts.excluded[14300] = true
facts.excluded[14301] = true
facts.excluded[14302] = true
facts.excluded[14303] = true
facts.excluded[14304] = true
facts.excluded[14305] = true
facts.excluded[14314] = true
facts.excluded[14315] = true
facts.excluded[14316] = true
facts.excluded[14317] = true
facts.excluded[14361] = true
facts.excluded[14362] = true
facts.excluded[14364] = true
facts.excluded[14365] = true
facts.excluded[14366] = true
facts.excluded[14367] = true
facts.excluded[14372] = true
facts.excluded[14373] = true
facts.excluded[15407] = true
facts.excluded[15735] = true
facts.excluded[15736] = true
facts.excluded[15783] = true
facts.excluded[15790] = true
facts.excluded[15791] = true
facts.excluded[16005] = true
facts.excluded[16102] = true
facts.excluded[16375] = true
facts.excluded[16414] = true
facts.excluded[16419] = true
facts.excluded[16568] = true
facts.excluded[16569] = true
facts.excluded[16608] = true
facts.excluded[16914] = true
facts.excluded[16915] = true
facts.excluded[17008] = true
facts.excluded[17165] = true
facts.excluded[17173] = true
facts.excluded[17238] = true
facts.excluded[17243] = true
facts.excluded[17311] = true
facts.excluded[17312] = true
facts.excluded[17313] = true
facts.excluded[17314] = true
facts.excluded[17316] = true
facts.excluded[17317] = true
facts.excluded[17318] = true
facts.excluded[17401] = true
facts.excluded[17402] = true
facts.excluded[17406] = true
facts.excluded[17620] = true
facts.excluded[17682] = true
facts.excluded[18084] = true
facts.excluded[18394] = true
facts.excluded[18399] = true
facts.excluded[18557] = true
facts.excluded[18807] = true
facts.excluded[18808] = true
facts.excluded[18815] = true
facts.excluded[18816] = true
facts.excluded[18817] = true
facts.excluded[18818] = true
facts.excluded[19099] = true
facts.excluded[19296] = true
facts.excluded[19299] = true
facts.excluded[19302] = true
facts.excluded[19303] = true
facts.excluded[19304] = true
facts.excluded[19305] = true
facts.excluded[19350] = true
facts.excluded[19351] = true
facts.excluded[19352] = true
facts.excluded[19353] = true
facts.excluded[19354] = true
facts.excluded[19355] = true
facts.excluded[19356] = true
facts.excluded[19386] = true
facts.excluded[19474] = true
facts.excluded[19475] = true
facts.excluded[19717] = true
facts.excluded[20116] = true
facts.excluded[20296] = true
facts.excluded[20680] = true
facts.excluded[20743] = true
facts.excluded[20754] = true
facts.excluded[20794] = true
facts.excluded[20813] = true
facts.excluded[20827] = true
facts.excluded[20922] = true
facts.excluded[20923] = true
facts.excluded[20924] = true
facts.excluded[20940] = true
facts.excluded[20941] = true
facts.excluded[20952] = true
facts.excluded[20953] = true
facts.excluded[20954] = true
facts.excluded[21096] = true
facts.excluded[21170] = true
facts.excluded[21367] = true
facts.excluded[22272] = true
facts.excluded[22273] = true
facts.excluded[22275] = true
facts.excluded[22822] = true
facts.excluded[22823] = true
facts.excluded[22908] = true
facts.excluded[22910] = true
facts.excluded[22919] = true
facts.excluded[23953] = true
facts.excluded[24131] = true
facts.excluded[24132] = true
facts.excluded[24133] = true
facts.excluded[24134] = true
facts.excluded[24135] = true
facts.excluded[24300] = true
facts.excluded[24335] = true
facts.excluded[24336] = true
facts.excluded[24435] = true
facts.excluded[24585] = true
facts.excluded[24612] = true
facts.excluded[24618] = true
facts.excluded[24669] = true
facts.excluded[24922] = true
facts.excluded[25019] = true
facts.excluded[25345] = true
facts.excluded[25346] = true
facts.excluded[25416] = true
facts.excluded[25671] = true
facts.excluded[25676] = true
facts.excluded[25754] = true
facts.excluded[25755] = true
facts.excluded[25979] = true
facts.excluded[26044] = true
facts.excluded[26143] = true
facts.excluded[26180] = true
facts.excluded[26233] = true
facts.excluded[26457] = true
facts.excluded[26559] = true
facts.excluded[26573] = true
facts.excluded[26574] = true
facts.excluded[26607] = true
facts.excluded[26639] = true
facts.excluded[26693] = true
facts.excluded[26748] = true
facts.excluded[27530] = true
facts.excluded[27618] = true
facts.excluded[27636] = true
facts.excluded[27994] = true
facts.excluded[28310] = true
facts.excluded[28794] = true
facts.excluded[29155] = true
facts.excluded[29407] = true
facts.excluded[30091] = true
facts.excluded[30093] = true
facts.excluded[31751] = true
facts.excluded[365100] = true
facts.excluded[365128] = true
facts.excluded[365188] = true
facts.excluded[365196] = true
facts.excluded[368218] = true
facts.excluded[368235] = true
facts.excluded[368292] = true
facts.excluded[368315] = true
facts.excluded[368320] = true
facts.excluded[369330] = true
facts.excluded[402174] = true
facts.excluded[402261] = true
facts.excluded[402277] = true
facts.excluded[402284] = true
facts.excluded[402289] = true
facts.excluded[402844] = true
facts.excluded[403677] = true
facts.excluded[403685] = true
facts.excluded[403686] = true
facts.excluded[403687] = true
facts.excluded[403688] = true
facts.excluded[403689] = true
facts.excluded[409521] = true
facts.excluded[409524] = true
facts.excluded[409526] = true
facts.excluded[409528] = true
facts.excluded[409530] = true
facts.excluded[409532] = true
facts.excluded[409534] = true
facts.excluded[409535] = true
facts.excluded[412526] = true
facts.excluded[437884] = true
facts.excluded[437887] = true
facts.excluded[446317] = true
facts.excluded[447547] = true
facts.excluded[458285] = true
facts.excluded[458286] = true
facts.excluded[459705] = true
facts.excluded[460692] = true
facts.excluded[460698] = true
facts.excluded[460699] = true
facts.excluded[460700] = true
facts.excluded[461683] = true
facts.excluded[461684] = true
facts.excluded[462221] = true
facts.excluded[468184] = true
facts.excluded[469990] = true
facts.excluded[474204] = true
facts.excluded[474268] = true
facts.excluded[1213271] = true
facts.excluded[1213279] = true
facts.excluded[1213451] = true
facts.excluded[1213862] = true
facts.excluded[1213864] = true
facts.excluded[1213873] = true
facts.excluded[1213874] = true
facts.excluded[1214208] = true
facts.excluded[1215740] = true
facts.excluded[1215753] = true
facts.excluded[1215779] = true
facts.excluded[1215781] = true
facts.excluded[1216500] = true
facts.excluded[1216501] = true
facts.excluded[1220711] = true
facts.excluded[1220862] = true
facts.excluded[1230613] = true
facts.excluded[1230633] = true
facts.excluded[1230639] = true
facts.excluded[1230807] = true
facts.excluded[1230899] = true
facts.excluded[1232755] = true
facts.excluded[1240720] = true
facts.excluded[1240721] = true
facts.excluded[1240723] = true
facts.excluded[1240724] = true
facts.excluded[1240727] = true
facts.excluded[1240730] = true
facts.excluded[1240732] = true
facts.excluded[1240733] = true
facts.excluded[1240734] = true
facts.excluded[1240736] = true
facts.excluded[1278759] = true
facts.excluded[1278965] = true
facts.excluded[1278968] = true
facts.excluded[1279715] = true
facts.excluded[1279719] = true
facts.excluded[1279721] = true
facts.excluded[1279949] = true
facts.excluded[1279976] = true
facts.excluded[1279977] = true
facts.excluded[1279978] = true
facts.excluded[1279979] = true
facts.excluded[1279980] = true
facts.excluded[1279983] = true
facts.excluded[1279985] = true
facts.excluded[1279987] = true
facts.excluded[1279988] = true
facts.excluded[1279989] = true
facts.excluded[1279990] = true
facts.excluded[1280345] = true
facts.excluded[1280346] = true
facts.excluded[1280347] = true
facts.excluded[1280348] = true
facts.excluded[1280349] = true
facts.excluded[1280353] = true
facts.excluded[1282380] = true
facts.excluded[1282381] = true
facts.excluded[1282383] = true
facts.excluded[1282384] = true
facts.excluded[1282385] = true
facts.excluded[1284382] = true
facts.excluded[1289129] = true
facts.excluded[1289130] = true
facts.excluded[1303498] = true
facts.excluded[1303499] = true
facts.excluded[1310087] = true
facts.excluded[1314281] = true
facts.excluded[1316319] = true
facts.excluded[1316697] = true
facts.excluded[1316991] = true
facts.excluded[1316992] = true
facts.excluded[1316993] = true
facts.excluded[1316994] = true
facts.excluded[1316995] = true
facts.excluded[1324196] = true
facts.excluded[1324200] = true
facts.excluded[1324229] = true
local _, namespace = ...
if type(namespace) == "table" then namespace.SpellFacts = facts end
return facts
