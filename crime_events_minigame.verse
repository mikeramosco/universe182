
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
crime_events_minigame := class(creative_device):

    # Notifies players when crime alert minigame has started
    @editable
    messageDevice : hud_message_device = hud_message_device{}

    # Tracks the amount of time players have to complete crime alert minigame
    @editable
    crimeTimer : timer_device = timer_device{}

    # Grants XP Award for completed crime alert minigames
    @editable
    xpGranter : accolades_device = accolades_device{}

    # Grants 50 gold as reward for completed crime alert minigames
    @editable
    goldGranter : item_granter_device = item_granter_device{}
    
    # Grants 1 gold for each guard eliminated
    @editable
    goldGranterForGuardElim : item_granter_device = item_granter_device{}

    # Granters that hold items to be rewarded for completed crime alert minigames
    @editable
    granter1 : item_granter_device = item_granter_device{}
    @editable
    granter2 : item_granter_device = item_granter_device{}
    @editable
    granter3 : item_granter_device = item_granter_device{}

    # Guards are spawned at crime spots to be defeated for crime alert minigame
    @editable
    crimeSpot1 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot2 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot3 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot4 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot5 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot6 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpotBank : guard_spawner_device = guard_spawner_device{}

    @editable
    ctbl1 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl2 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl3 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl4 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl5 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl6 : collectible_object_device = collectible_object_device{}
    @editable
    ctbl7 : collectible_object_device = collectible_object_device{}

    var IsBankCrime : logic = false

    # Number of crime spots
    var NCrimeSpots : int = 6

    # Max number of guards
    var MaxGuards : int = 8

    # Number of remaining guards
    var NGuardsRemaining : int = -1

    # Index of active crime spot
    var RandomCrimeIndex : int = -1

    # Amount of time between crime alert minigames in minutes (5 minutes / 1 minute for testing)
    var StandByMinutes : float = 5.0

    # Amount of time to display messages
    var CrimeAlertMessageDuration : float = 0.0
    var CrimeEndedMessageDuration : float = 5.0

    # Crime alert messages
    CrimeAlertType1Message<localizes>: message = "Crime reported near a landing zone"
    CrimeAlertType2Message<localizes>: message = "Crime reported from a residence"
    CrimeAlertType3Message<localizes>: message = "Crime reported in the city"
    CrimeAlertType4Message<localizes>: message = "Crime reported at the bank"
    
    # Crime alert minigame completed messages
    CrimeAlertSuccessMessage<localizes>: message = "Mission Completed"
    CrimeAlertFailedMessage<localizes>: message = "Mission Failed"
    CrimeAlertEndedMessage<localizes>: message = "Mission Ended"

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        InitGuards()
        InitCollectibles()
        crimeTimer.SuccessEvent.Subscribe(OnTimerCompleted)
        spawn:
            StartCrimeAlertRound()
        InitNPCBattleSimulation()

    # Init all guard spawners to listen for when guards are eliminated
    InitGuards() : void=
        set NGuardsRemaining = MaxGuards
        crimeSpot1.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot2.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot3.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot4.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot5.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot6.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpotBank.EliminatedEvent.Subscribe(OnBankGuardEliminated)

    InitCollectibles() : void=
        ctbl1.CollectedEvent.Subscribe(OnCollected)
        ctbl2.CollectedEvent.Subscribe(OnCollected)
        ctbl3.CollectedEvent.Subscribe(OnCollected)
        ctbl4.CollectedEvent.Subscribe(OnCollected)
        ctbl5.CollectedEvent.Subscribe(OnCollected)
        ctbl6.CollectedEvent.Subscribe(OnCollected)
        ctbl7.CollectedEvent.Subscribe(OnCollected)

    OnCollected(Agent : agent) : void=
        goldGranter.GrantItem(Agent)
        goldGranter.GrantItem(Agent)

    # Tracks when all guards have been eliminated
    OnGuardEliminated(Result : device_ai_interaction_result) : void=
        set NGuardsRemaining -= 1
        if(Agent := Result.Source?):
            if(NGuardsRemaining > 0):
                goldGranterForGuardElim.GrantItem(Agent)
        if(NGuardsRemaining = 0):
            crimeTimer.Complete()
            if(Agent := Result.Source?):
                RewardPlayer(Agent)

    OnBankGuardEliminated(Result : device_ai_interaction_result) : void=
        set NGuardsRemaining -= 1
        if(Agent := Result.Source?):
            if(NGuardsRemaining > 0):
                goldGranterForGuardElim.GrantItem(Agent)
        if(NGuardsRemaining = 0):
            if(Agent := Result.Source?):
                goldGranter.GrantItem(Agent)
                xpGranter.Award(Agent)

    # Reward players with xp, gold, & appropriate item
    RewardPlayer(Agent : agent) : void=
        if(RandomCrimeIndex < 3):
            granter1.GrantItem(Agent)
        else if(RandomCrimeIndex < 5):
            granter2.GrantItem(Agent)
        else if(RandomCrimeIndex < 7):
            granter3.GrantItem(Agent)
        else:
            granter2.GrantItem(Agent)
        goldGranter.GrantItem(Agent)
        xpGranter.Award(Agent)

    # Init timer to reset crime alert round when completed
    OnTimerCompleted(Agent : ?agent) : void=
        DisplayCrimeEndedMessage()
        ResetCrimeAlertRound()

    # Notifies player whether mission was completed or failed
    DisplayCrimeEndedMessage() : void=
        if(IsBankCrime = true):
            messageDevice.SetText(CrimeAlertSuccessMessage)
        else if(NGuardsRemaining = 0):
            messageDevice.SetText(CrimeAlertSuccessMessage)
        else:
            messageDevice.SetText(CrimeAlertFailedMessage)
        messageDevice.SetDisplayTime(CrimeEndedMessageDuration)
        messageDevice.Show()

    # Converts minutes to seconds
    MinutesToSeconds(Minutes : float) : float=
        return 60 * Minutes

    # Delays crime alert minigame for a number of minutes
    StandBy()<suspends> : void=
        Sleep(MinutesToSeconds(StandByMinutes))

    # Each crime alert minigame starts after a delay
    StartCrimeAlertRound()<suspends> : void=
        StandBy()
        BankCrimeChanceIndex : int = GetRandomInt(1, 4)
        if(BankCrimeChanceIndex = 1):
            set IsBankCrime = true
            StartBankCrimeAlert()
        else: 
            set IsBankCrime = false
            StartCrimeAlert()

    SpawnCollectibles() : void=
        RespawnCollectibles()
        ShowThreeRandomCollectibles()

    RespawnCollectibles() : void=
        ctbl1.RespawnForAll()
        ctbl2.RespawnForAll()
        ctbl3.RespawnForAll()
        ctbl4.RespawnForAll()
        ctbl5.RespawnForAll()
        ctbl6.RespawnForAll()
        ctbl7.RespawnForAll()

    ShowThreeRandomCollectibles() : void=
        Collectibles : []collectible_object_device = array{ctbl1, ctbl2, ctbl3, ctbl4, ctbl5, ctbl6, ctbl7}
        RandomLocations : []collectible_object_device = Shuffle(Collectibles)
        if(RndmCtbl := RandomLocations[1]):
            RndmCtbl.Show()
        if(RndmCtbl := RandomLocations[2]):
            RndmCtbl.Show()
        if(RndmCtbl := RandomLocations[3]):
            RndmCtbl.Show()

    StartBankCrimeAlert() : void=
        DisplayBankCrimeAlertMessage()
        SpawnCollectibles()
        crimeSpotBank.Enable()
        crimeTimer.Start()

    # Crime event of some bots starts at random crime spot
    StartCrimeAlert() : void=
        set RandomCrimeIndex = GetRandomInt(1, NCrimeSpots)
        DisplayCrimeAlertMessage()
        SpawnGuards()
        crimeTimer.Start()

    DisplayBankCrimeAlertMessage() : void=
        messageDevice.SetText(CrimeAlertType4Message)
        messageDevice.SetDisplayTime(CrimeAlertMessageDuration)
        messageDevice.Show()

    # Notifies player of crime alert minigame & type of crime
    DisplayCrimeAlertMessage() : void=
        if(RandomCrimeIndex < 3):
            messageDevice.SetText(CrimeAlertType1Message)
        else if(RandomCrimeIndex < 5):
            messageDevice.SetText(CrimeAlertType2Message)
        else if(RandomCrimeIndex < 7):
            messageDevice.SetText(CrimeAlertType3Message)
        else:
            messageDevice.SetText(CrimeAlertType2Message)
        messageDevice.SetDisplayTime(CrimeAlertMessageDuration)
        messageDevice.Show()
    
    # Spawns guards at one of the crime spots for players to defeat
    SpawnGuards() : void=
        if(RandomCrimeIndex = 1):
            crimeSpot1.Enable()
        else if(RandomCrimeIndex = 2):
            crimeSpot2.Enable()
        else if(RandomCrimeIndex = 3):
            crimeSpot3.Enable()
        else if(RandomCrimeIndex = 4):
            crimeSpot4.Enable()
        else if(RandomCrimeIndex = 5):
            crimeSpot5.Enable()
        else if(RandomCrimeIndex = 6):
            crimeSpot6.Enable()

    # Resets all devices and starts over crime alert round
    ResetCrimeAlertRound() : void=
        crimeTimer.Reset()
        ResetGuards()
        spawn:
            StartCrimeAlertRound()
    
    ResetCollectibles() : void=
        ctbl1.Hide()
        ctbl2.Hide()
        ctbl3.Hide()
        ctbl4.Hide()
        ctbl5.Hide()
        ctbl6.Hide()
        ctbl7.Hide()


    # Despawns guards & resets the appropriate guard spawner
    ResetGuards() : void=
        set NGuardsRemaining = MaxGuards
        if(IsBankCrime = true):
            crimeSpotBank.Disable()
            crimeSpotBank.Reset()
            ResetCollectibles()
        else if(RandomCrimeIndex = 1):
            crimeSpot1.Disable()
            crimeSpot1.Reset()
        else if(RandomCrimeIndex = 2):
            crimeSpot2.Disable()
            crimeSpot2.Reset()
        else if(RandomCrimeIndex = 3):
            crimeSpot3.Disable()
            crimeSpot3.Reset()
        else if(RandomCrimeIndex = 4):
            crimeSpot4.Disable()
            crimeSpot4.Reset()
        else if(RandomCrimeIndex = 5):
            crimeSpot5.Disable()
            crimeSpot5.Reset()
        else if(RandomCrimeIndex = 6):
            crimeSpot6.Disable()
            crimeSpot6.Reset()

    # NPC Battle Simulation Script

    # guard spawners
    @editable
    battleNPCs1 : guard_spawner_device = guard_spawner_device{}
    @editable
    battleNPCs2 : guard_spawner_device = guard_spawner_device{}

    # start battle button
    @editable
    startBattleButton : button_device = button_device{}

    # npcs remaining
    var Team1NPCsRemaining : int = -1
    var Team2NPCsRemaining : int = -1

    # max npcs
    MaxNPCs : int = 50

    # simulation messages
    battleStartedMessage<localizes>: message = "NPC Battle Simulation has started"
    npcTeam1WinsMessage<localizes>: message = "Team 1 NPCs have won the battle"
    npcTeam2WinsMessage<localizes>: message = "Team 2 NPCs have won the battle"

    InitNPCBattleSimulation() : void=
        InitBattleNPCs()
        startBattleButton.InteractedWithEvent.Subscribe(startBattleButtonPressed)

    InitBattleNPCs() : void=
        set Team1NPCsRemaining = MaxNPCs
        set Team2NPCsRemaining = MaxNPCs
        battleNPCs1.EliminatedEvent.Subscribe(OnTeam1NPCEliminated)
        battleNPCs2.EliminatedEvent.Subscribe(OnTeam2NPCEliminated)
    
    startBattleButtonPressed(Agent : agent) : void=
        DisplayBattleStartedMessage()
        startBattleButton.Disable()
        spawnBattleNPCs()
    
    DisplayBattleStartedMessage() : void=
        messageDevice.SetText(battleStartedMessage)
        messageDevice.SetDisplayTime(CrimeAlertMessageDuration)
        messageDevice.Show()

    spawnBattleNPCs() : void=
        battleNPCs1.Enable()
        battleNPCs2.Enable()

    OnTeam1NPCEliminated(Result : device_ai_interaction_result) : void=
        set Team1NPCsRemaining -= 1
        if(Agent := Result.Source?):
            goldGranterForGuardElim.GrantItem(Agent)
        if(Team1NPCsRemaining = 0):
            EndSimulation()

    OnTeam2NPCEliminated(Result : device_ai_interaction_result) : void=
        set Team2NPCsRemaining -= 1
        if(Agent := Result.Source?):
            goldGranterForGuardElim.GrantItem(Agent)
        if(Team2NPCsRemaining = 0):
            EndSimulation()

    EndSimulation() : void=
        DisplaySimulationEndedMessage()
        set Team1NPCsRemaining = MaxNPCs
        set Team2NPCsRemaining = MaxNPCs
        battleNPCs1.Disable()
        battleNPCs2.Disable()
        battleNPCs1.Reset()
        battleNPCs2.Reset()
        startBattleButton.Enable()

    DisplaySimulationEndedMessage() : void=
        if(Team1NPCsRemaining > 0):
            messageDevice.SetText(npcTeam1WinsMessage)
        else:
            messageDevice.SetText(npcTeam2WinsMessage)
        messageDevice.SetDisplayTime(CrimeEndedMessageDuration)
        messageDevice.Show()
