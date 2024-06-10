
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

zombies_survival_minigame := class(creative_device):

    #----------------------------------------------------------------------------------------------------

    # I.     Wall Buy Weapons Devices
    
    # Buttons
    @editable
    shotgunButton: conditional_button_device = conditional_button_device{}
    @editable
    smgButton: conditional_button_device = conditional_button_device{}
    @editable
    zeusButton: conditional_button_device = conditional_button_device{}
    @editable

    # Granters
    @editable
    shotgunGranter: item_granter_device = item_granter_device{}
    @editable
    smgGranter: item_granter_device = item_granter_device{}
    @editable
    zeusGranter: item_granter_device = item_granter_device{}

    @editable
    xpGranter : accolades_device = accolades_device{}

    #----------------------------------------------------------------------------------------------------

    # II.    Vending Machine Perks Devices

    # Double Tap perk devices
    @editable
    doubleTapButton: conditional_button_device = conditional_button_device{}
    @editable
    doubleTapDevice: damage_amplifier_powerup_device = damage_amplifier_powerup_device{}

    # Stamin-Up perk devices
    @editable
    staminUpButton: conditional_button_device = conditional_button_device{}
    @editable
    staminUpDevice: movement_modulator_device = movement_modulator_device{}

    #----------------------------------------------------------------------------------------------------

    # III.   Mystery Box Devices
    @editable
    weaponSpawner: item_spawner_device = item_spawner_device{}
    @editable
    mysteryBoxButton: conditional_button_device = conditional_button_device{}   

    #----------------------------------------------------------------------------------------------------

    # IV.    Zombies Minigame Devices
    @editable
    zombiesZone: mutator_zone_device = mutator_zone_device{}
    @editable
    zombiesMinigameMessages: hud_message_device = hud_message_device{}
    @editable
    goldGranter: item_granter_device = item_granter_device{}
    @editable
    goldGranterForNuke: item_granter_device = item_granter_device{}
    
    @editable
    zombiesFiend: creature_spawner_device = creature_spawner_device{}
    @editable
    zombiesRanged: creature_spawner_device = creature_spawner_device{}
    @editable
    zombiesPoison: creature_spawner_device = creature_spawner_device{}
    @editable
    zombiesMega: creature_spawner_device = creature_spawner_device{}

    #----------------------------------------------------------------------------------------------------

    # V.     Devices Controller Script

    OnBegin<override>()<suspends>:void=
        initDevices()

    initDevices():void=
        initWallBuys()
        initPerks()
        initMysteryBox()
        initZombies()

    initWallBuys():void=
        shotgunButton.ActivatedEvent.Subscribe(grantShotgun)
        smgButton.ActivatedEvent.Subscribe(grantSmg)
        zeusButton.ActivatedEvent.Subscribe(grantZeus)
    
    grantShotgun(Agent: agent):void=
        shotgunGranter.GrantItem(Agent)
    
    grantSmg(Agent: agent):void=
        smgGranter.GrantItem(Agent)
    
    grantZeus(Agent: agent):void=
        zeusGranter.GrantItem(Agent)

    initPerks():void=
        doubleTapButton.ActivatedEvent.Subscribe(grantDoubleTap)
        staminUpButton.ActivatedEvent.Subscribe(grantStaminUp)

    grantDoubleTap(Agent: agent):void=
        doubleTapDevice.Pickup(Agent)

    grantStaminUp(Agent: agent):void=
        staminUpDevice.Activate(Agent)

    initMysteryBox():void=
        mysteryBoxButton.ActivatedEvent.Subscribe(spinMysteryBox)

    spinMysteryBox(Agent: agent):void=
        mysteryBoxButton.Disable()
        set nCyclesRemaining = N_CYCLES
        spawn{cycleNextWeapon()}

    cycleNextWeapon()<suspends>:void=
        if(nCyclesRemaining > 0):
            weaponSpawner.CycleToNextItem()
            Sleep(CYCLE_DELAY)
            set nCyclesRemaining -= 1
            cycleNextWeapon()
        else:
            mysteryBoxButton.Enable()
            

    #----------------------------------------------------------------------------------------------------

    # VI.    Zombies Minigame Script

    initZombies():void=
        zombiesFiend.EliminatedEvent.Subscribe(zombieEliminated)
        zombiesRanged.EliminatedEvent.Subscribe(zombieEliminated)
        zombiesPoison.EliminatedEvent.Subscribe(zombieEliminated)
        zombiesMega.EliminatedEvent.Subscribe(zombieEliminated)
        zombiesZone.AgentEntersEvent.Subscribe(addPlayerToZone)
        zombiesZone.AgentExitsEvent.Subscribe(removePlayerFromZone)

    getMultiplier():int=
        if(currentRound < 6):
            return 0
        else if(currentRound < 11):
            return 1
        else if(currentRound < 16):
            return 2
        else if(currentRound < 20):
            return 3
        else:
            return 4

    awardZombieElimGold(Agent: agent):void=
        roundMultiplier: int = getMultiplier()
        for(Index := 0..roundMultiplier):
            goldGranter.GrantItem(Agent)


    zombieEliminated(Result: device_ai_interaction_result):void=
        if(roundIsActive = true):
            if(Agent := Result.Source?):
                if(Player := player[Agent]):
                    awardZombieElimGold(Agent)
                    if(doublePointsActive = true):
                        awardZombieElimGold(Agent)

                    if(currentRound < 20):
                        set nZombiesRemaining -= 1
                        if(nZombiesRemaining = 0):
                            set roundIsActive = false
                            xpGranter.Award(Agent)
                            spawn{initNextRound(true)}
                        else if(nZombiesRemaining > 0):
                            rollZombiesChanceEvent()

    chanceEventRolled():logic=
        randomChanceIndex: int = GetRandomInt(1, N_ZOMBIES_FOR_CHANCE)
        if(randomChanceIndex = 1):
            return true
        else:
            return false

    rollZombiesChanceEvent():void=
        var chanceEventActivated: logic = chanceEventRolled()
        if(chanceEventActivated = true):
            var chanceEventIndex: int = GetRandomInt(1, MAX_CHANCE_INDEX)
            if(chanceEventIndex < MAX_CHANCE_INDEX):
                activateChanceEvent1()
            else:
                activateChanceEvent2()
    
    activateChanceEvent1():void=
        displayMessage(zombiesDoublePointsMessage, 0.0)
        set doublePointsActive = true

    activateChanceEvent2():void= 
        displayMessage(zombiesNukedMessage, 0.0)
        awardNukeGoldToPlayers()
        set roundIsActive = false
        spawn{initNextRound(false)}

    awardNukeGoldToPlayers():void=
        for(Index := 0..zombiesList.Length-1):
            if(zPlayer := zombiesList[Index]):
                goldGranterForNuke.GrantItem(zPlayer)
                if(doublePointsActive = true):
                    goldGranterForNuke.GrantItem(zPlayer)

    searchZombiesList(Agent: agent):logic=
        for(Index := 0..zombiesList.Length-1):
            if(zPlayer := zombiesList[Index]):
                if(zPlayer = Agent):
                    return true
        return false

    addPlayerToZone(Agent: agent):void=
        if(Player := player[Agent]):
            if(nPlayersInZone = 0):
                set nPlayersInZone += 1
                startZombiesMinigame()
            else:
                set nPlayersInZone += 1
            addPlayerToArray(Agent)

    addPlayerToArray(Agent: agent):void=
        var playerInZombiesList: logic = searchZombiesList(Agent)

        if(playerInZombiesList = false):
            set zombiesList = zombiesList + array{Agent}

    removePlayerFromZone(Agent: agent):void=
        if(Player := player[Agent]):
            set nPlayersInZone -= 1
            if(nPlayersInZone = 0):
                endZombiesMinigame()
            removePlayerFromArray(Agent)
        
    removePlayerFromArray(Agent: agent):void=
        var playerInZombiesList: logic = searchZombiesList(Agent)

        if(playerInZombiesList = true):
            removePlayerFromList(Agent)
    
    removePlayerFromList(Agent: agent):void=
        var newList : []agent = array{}
        for(Index := 0..zombiesList.Length-1):
            if(zPlayer := zombiesList[Index]):
                var playerToRemoveFound : logic = false
                if(zPlayer = Agent):
                    set playerToRemoveFound = true
                if(playerToRemoveFound = false):
                    set newList = newList + array{zPlayer}
        set zombiesList = newList

    enableZombies():void=
        set roundIsActive = true
        if(currentRound < 4):
            zombiesFiend.Enable()
            set zombiesFiendActive = true
        else if(currentRound < 7):
            zombiesFiend.Enable()
            zombiesPoison.Enable()
            set zombiesFiendActive = true
            set zombiesPoisonActive = true
        else if(currentRound < 10):
            zombiesFiend.Enable()
            zombiesRanged.Enable()
            set zombiesFiendActive = true
            set zombiesRangedActive = true
        else if(currentRound < 13):
            zombiesRanged.Enable()
            zombiesPoison.Enable()
            set zombiesRangedActive = true
            set zombiesPoisonActive = true
        else if(currentRound < 16):
            zombiesFiend.Enable()
            zombiesRanged.Enable()
            zombiesPoison.Enable()
            set zombiesFiendActive = true
            set zombiesRangedActive = true
            set zombiesPoisonActive = true
        else if(currentRound < 19):
            zombiesFiend.Enable()
            zombiesMega.Enable()
            set zombiesFiendActive = true
            set zombiesMegaActive = true
        else:
            zombiesRanged.Enable()
            zombiesPoison.Enable()
            zombiesMega.Enable()
            set zombiesRangedActive = true
            set zombiesPoisonActive = true
            set zombiesMegaActive = true

    disableZombies():void=
        set doublePointsActive = false
        if(zombiesFiendActive = true):
            zombiesFiend.EliminateCreatures()
            zombiesFiend.Disable()
            set zombiesFiendActive = false
        if(zombiesRangedActive = true):
            zombiesRanged.EliminateCreatures()
            zombiesRanged.Disable()
            set zombiesRangedActive = false
        if(zombiesPoisonActive = true):
            zombiesPoison.EliminateCreatures()
            zombiesPoison.Disable()
            set zombiesPoisonActive = false
        if(zombiesMegaActive = true):
            zombiesMega.EliminateCreatures()
            zombiesMega.Disable()
            set zombiesMegaActive = false
    
    startZombiesMinigame():void=
        set currentRound = 1
        set nZombiesForRound = BASE_N_ZOMBIES
        set nZombiesRemaining = nZombiesForRound
        displayZombiesNextRoundMessage()
        enableZombies()

    initNextRound(displayRoundEndMessage: logic)<suspends>:void=
        disableZombies()
        if(displayRoundEndMessage = true):
            displayMessage(zombiesRoundEndMessage, 0.0)
        Sleep(ZOMBIES_NEXT_ROUND_DURATION)

        if(nPlayersInZone > 0):
            set currentRound += 1
            set nZombiesForRound += N_ZOMBIES_TO_ADD
            set nZombiesRemaining = nZombiesForRound

            displayZombiesNextRoundMessage()
            enableZombies()

    endZombiesMinigame():void=
        set roundIsActive = false
        disableZombies()
        displayMessage(zombiesEndMessage, ZOMBIES_ENDED_DURATION)

    displayMessage(zMessage: message, displayTime: float):void=
        zombiesMinigameMessages.SetText(zMessage)
        zombiesMinigameMessages.SetDisplayTime(displayTime)
        zombiesMinigameMessages.Show()

    displayZombiesNextRoundMessage():void=
        setMessageTextToRoundNumber()
        zombiesMinigameMessages.SetDisplayTime(0.0)
        zombiesMinigameMessages.Show()

    #----------------------------------------------------------------------------------------------------

    # VII.   Zombies minigame variables

    # Instance variables
    var nCyclesRemaining: int = 0
    var nPlayersInZone: int = 0
    var currentRound: int = 1
    var nZombiesForRound: int = 0
    var nZombiesRemaining: int = 0
    var roundIsActive: logic = false
    var doublePointsActive: logic = false

    var zombiesFiendActive: logic = false
    var zombiesRangedActive: logic = false
    var zombiesPoisonActive: logic = false
    var zombiesMegaActive: logic = false

    var zombiesList : []agent = array{}

    # Constants
    CYCLE_DELAY: float = 0.25
    FFA_CYCLE_DELAY: float = 5.0
    N_CYCLES: int = 20
    MAX_ROUNDS: int = 20
    ZOMBIES_ENDED_DURATION : float = 5.0
    BASE_N_ZOMBIES: int = 20
    N_ZOMBIES_TO_ADD: int = 2
    ZOMBIES_NEXT_ROUND_DURATION: float = 20.0
    N_ZOMBIES_FOR_CHANCE: int = 100
    MAX_CHANCE_INDEX: int = 4

    # Messages
    zombiesMinigameMessage1<localizes>: message = "Eliminate the Zombies (Round 1)"
    zombiesMinigameMessage2<localizes>: message = "Eliminate the Zombies (Round 2)"
    zombiesMinigameMessage3<localizes>: message = "Eliminate the Zombies (Round 3)"
    zombiesMinigameMessage4<localizes>: message = "Eliminate the Zombies (Round 4)"
    zombiesMinigameMessage5<localizes>: message = "Eliminate the Zombies (Round 5)"
    zombiesMinigameMessage6<localizes>: message = "Eliminate the Zombies (Round 6)"
    zombiesMinigameMessage7<localizes>: message = "Eliminate the Zombies (Round 7)"
    zombiesMinigameMessage8<localizes>: message = "Eliminate the Zombies (Round 8)"
    zombiesMinigameMessage9<localizes>: message = "Eliminate the Zombies (Round 9)"
    zombiesMinigameMessage10<localizes>: message = "Eliminate the Zombies (Round 10)"
    zombiesMinigameMessage11<localizes>: message = "Eliminate the Zombies (Round 11)"
    zombiesMinigameMessage12<localizes>: message = "Eliminate the Zombies (Round 12)"
    zombiesMinigameMessage13<localizes>: message = "Eliminate the Zombies (Round 13)"
    zombiesMinigameMessage14<localizes>: message = "Eliminate the Zombies (Round 14)"
    zombiesMinigameMessage15<localizes>: message = "Eliminate the Zombies (Round 15)"
    zombiesMinigameMessage16<localizes>: message = "Eliminate the Zombies (Round 16)"
    zombiesMinigameMessage17<localizes>: message = "Eliminate the Zombies (Round 17)"
    zombiesMinigameMessage18<localizes>: message = "Eliminate the Zombies (Round 18)"
    zombiesMinigameMessage19<localizes>: message = "Eliminate the Zombies (Round 19)"
    zombiesMinigameMessage20<localizes>: message = "Eliminate the Zombies (Round 20)"

    zombiesRoundEndMessage<localizes>: message = "Zombies Round Completed (Next round starting soon)"
    zombiesEndMessage<localizes>: message = "Zombies Event has Ended"
    zombiesDoublePointsMessage<localizes>: message = "Double Points is Active (Zombies Event)"
    zombiesInstaElimMessage<localizes>: message = "Insta Elim is active (Zombies Event)"
    zombiesNukedMessage<localizes>: message = "Zombies have been Nuked (Next round starting soon)"

    setMessageTextToRoundNumber():void=
        if(currentRound = 1):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage1)
        else if(currentRound = 2):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage2)
        else if(currentRound = 3):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage3)
        else if(currentRound = 4):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage4)
        else if(currentRound = 5):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage5)
        else if(currentRound = 6):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage6)
        else if(currentRound = 7):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage7)
        else if(currentRound = 8):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage8)
        else if(currentRound = 9):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage9)
        else if(currentRound = 10):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage10)
        else if(currentRound = 11):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage11)
        else if(currentRound = 12):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage12)
        else if(currentRound = 13):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage13)
        else if(currentRound = 14):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage14)
        else if(currentRound = 15):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage15)
        else if(currentRound = 16):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage16)
        else if(currentRound = 17):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage17)
        else if(currentRound = 18):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage18)
        else if(currentRound = 19):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage19)
        else if(currentRound = 20):
            zombiesMinigameMessages.SetText(zombiesMinigameMessage20)
