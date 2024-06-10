
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

    # Grants 20 gold as reward for completed crime alert minigames
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
    crimeSpot7 : guard_spawner_device = guard_spawner_device{}
    @editable
    crimeSpot8 : guard_spawner_device = guard_spawner_device{}

    # Number of crime spots
    var NCrimeSpots : int = 8

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

    # Crime alert minigame completed messages
    CrimeAlertSuccessMessage<localizes>: message = "Mission Completed"
    CrimeAlertFailedMessage<localizes>: message = "Mission Failed"

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        InitGuards()
        crimeTimer.SuccessEvent.Subscribe(OnTimerCompleted)
        spawn:
            StartCrimeAlertRound()

    # Init all guard spawners to listen for when guards are eliminated
    InitGuards() : void=
        set NGuardsRemaining = MaxGuards
        crimeSpot1.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot2.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot3.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot4.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot5.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot6.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot7.EliminatedEvent.Subscribe(OnGuardEliminated)
        crimeSpot8.EliminatedEvent.Subscribe(OnGuardEliminated)

    # Tracks when all guards have been eliminated
    OnGuardEliminated(Result : device_ai_interaction_result) : void=
        set NGuardsRemaining -= 1
        if(Agent := Result.Source?):
            if(NGuardsRemaining = 0):
                RewardPlayer(Agent)
                crimeTimer.Complete()
            else:
                goldGranterForGuardElim.GrantItem(Agent)

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
        if(NGuardsRemaining = 0):
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
        StartCrimeAlert()

    # Crime event of some bots starts at random crime spot
    StartCrimeAlert() : void=
        set RandomCrimeIndex = GetRandomInt(1, NCrimeSpots)
        DisplayCrimeAlertMessage()
        SpawnGuards()
        crimeTimer.Start()

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
        else if(RandomCrimeIndex = 7):
            crimeSpot7.Enable()
        else:
            crimeSpot8.Enable()

    # Resets all devices and starts over crime alert round
    ResetCrimeAlertRound() : void=
        crimeTimer.Reset()
        ResetGuards()
        spawn:
            StartCrimeAlertRound()

    # Despawns guards & resets the appropriate guard spawner
    ResetGuards() : void=
        set NGuardsRemaining = MaxGuards
        if(RandomCrimeIndex = 1):
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
        else if(RandomCrimeIndex = 7):
            crimeSpot7.Disable()
            crimeSpot7.Reset()
        else:
            crimeSpot8.Disable()
            crimeSpot8.Reset()
