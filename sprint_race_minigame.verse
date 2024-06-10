
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
sprint_race_minigame := class(creative_device):

    @editable
    WinnerAwardGranter : item_granter_device = item_granter_device{}

    @editable
    xpGranter : accolades_device = accolades_device{}

    @editable
    MessageDevice : hud_message_device = hud_message_device{}

    @editable
    StartRaceButton1 : button_device = button_device{}
    @editable
    StartRaceButton2 : button_device = button_device{}
    @editable
    StartRaceButton3 : button_device = button_device{}
    @editable
    StartRaceButton4 : button_device = button_device{}

    @editable
    EndZone1 : mutator_zone_device = mutator_zone_device{}
    @editable
    EndZone2 : mutator_zone_device = mutator_zone_device{}
    @editable
    EndZone3 : mutator_zone_device = mutator_zone_device{}
    @editable
    EndZone4 : mutator_zone_device = mutator_zone_device{}

    @editable
    EndLocation1 : map_indicator_device = map_indicator_device{}
    @editable
    EndLocation2 : map_indicator_device = map_indicator_device{}
    @editable
    EndLocation3 : map_indicator_device = map_indicator_device{}
    @editable
    EndLocation4 : map_indicator_device = map_indicator_device{}

    minutesToEndRace : float = 5.0
    standByForRaceStartTime : float = 20.0
    NEndZones : int = 4

    var raceInstance : int = 0
    var randomEndIndex : int = -1
    var startZoneIndex : int = -1

    var racersList : []agent = array{}
    var raceInProgress : logic = false
    var raceStarted : logic = false

    raceEndedMessage<localizes>: message = "Sprint Race has Ended"

    StartRaceButtonText1<localizes>: message = "Start Sprint Race"
    StartRaceButtonText2<localizes>: message = "Disabled (Race in Progress)"

    startRaceCountdownMessage1<localizes>: message = "Ready"
    startRaceCountdownMessage2<localizes>: message = "Set"
    startRaceCountdownMessage3<localizes>: message = "Go!"

    startRacePregameMessage0<localizes>: message = "Enter green zone to participate in sprint race starting shortly (Players: 0)"
    startRacePregameMessage1<localizes>: message = "Enter green zone to participate in sprint race starting shortly (Players: 1)"
    startRacePregameMessage2<localizes>: message = "Enter green zone to participate in sprint race starting shortly (Players: 2)"
    startRacePregameMessage3<localizes>: message = "Enter green zone to participate in sprint race starting shortly (Players: 3)"
    startRacePregameMessage4<localizes>: message = "Enter green zone to participate in sprint race starting shortly (Players: 4+)"

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        initStartRaceButtons()
        initEndZones()

    initStartRaceButtons():void=
        StartRaceButton1.InteractedWithEvent.Subscribe(button1Pressed)
        StartRaceButton2.InteractedWithEvent.Subscribe(button2Pressed)
        StartRaceButton3.InteractedWithEvent.Subscribe(button3Pressed)
        StartRaceButton4.InteractedWithEvent.Subscribe(button4Pressed)

    button1Pressed(Agent: agent):void=
        if(raceInProgress = false):
            set startZoneIndex = 1
            startRaceButtonPressed()

    button2Pressed(Agent: agent):void=
        if(raceInProgress = false):
            set startZoneIndex = 2
            startRaceButtonPressed()

    button3Pressed(Agent: agent):void=
        if(raceInProgress = false):
            set startZoneIndex = 3
            startRaceButtonPressed()
        
    button4Pressed(Agent: agent):void=
        if(raceInProgress = false):
            set startZoneIndex = 4
            startRaceButtonPressed()

    startRaceButtonPressed():void=
        set raceInProgress = true
        disableStartRaceButtons()
        enableStartZone()
        updateSprintRacePregameMessage()
        spawn:
            initRace()

    enableStartZone():void=
        if(startZoneIndex = 1):
            EndZone1.Enable()
        else if(startZoneIndex = 2):
            EndZone2.Enable()
        else if(startZoneIndex = 3):
            EndZone3.Enable()
        else:
            EndZone4.Enable()

    enableStartRaceButtons():void=
        StartRaceButton1.Enable()
        StartRaceButton2.Enable()
        StartRaceButton3.Enable()
        StartRaceButton4.Enable()
        
    disableStartRaceButtons():void=
        StartRaceButton1.Disable()
        StartRaceButton2.Disable()
        StartRaceButton3.Disable()
        StartRaceButton4.Disable()
    
    updateRaceInstance():void=
        set raceInstance += 1
        if(raceInstance > 100):
            set raceInstance = 0

    initRace()<suspends>:void=
        standByForRaceStart()
        var nRacers : int = racersList.Length
        if(nRacers = 0):
            resetSprintRaceMinigame()
        else:
            startRace()

    standByForRaceStart()<suspends>:void=
        Sleep(standByForRaceStartTime)

    startRace()<suspends>:void=
        set raceStarted = true
        disableStartZone()
        countdownForRaceStart()

    disableStartZone():void=
        if(startZoneIndex = 1):
            EndZone1.Disable()
        else if(startZoneIndex = 2):
            EndZone2.Disable()
        else if(startZoneIndex = 3):
            EndZone3.Disable()
        else:
            EndZone4.Disable()

    countdownForRaceStart()<suspends>:void=
        displayCountdown()
        enableRandomEndZone()
        startTimerToEndRace()

    MinutesToSeconds(Minutes : float) : float=
        return 60 * Minutes

    startTimerToEndRace()<suspends>:void=
        thisRaceInstance : int = raceInstance
        Sleep(MinutesToSeconds(minutesToEndRace))
        if(raceInstance = thisRaceInstance):
            resetSprintRaceMinigame()

    displayCountdown()<suspends>:void=
        MessageDevice.SetDisplayTime(0.0)
        MessageDevice.SetText(startRaceCountdownMessage1)
        MessageDevice.Show()
        Sleep(1.0)
        MessageDevice.SetText(startRaceCountdownMessage2)
        MessageDevice.Show()
        Sleep(1.0)
        MessageDevice.SetDisplayTime(3.0)
        MessageDevice.SetText(startRaceCountdownMessage3)
        MessageDevice.Show()

    getRandomEndIndex():void=
        set randomEndIndex = GetRandomInt(1, NEndZones-1)
        nBeforeIndex : int = startZoneIndex - 1
        if(randomEndIndex > nBeforeIndex):
            set randomEndIndex += 1

    enableRandomEndZone():void=
        getRandomEndIndex()
        if(randomEndIndex = 1):
            EndZone1.Enable()
            EndLocation1.Enable()
            if(racer := racersList[0]):
                EndLocation1.ActivateObjectivePulse(racer)
        else if(randomEndIndex = 2):
            EndZone2.Enable()
            EndLocation2.Enable()
            if(racer := racersList[0]):
                EndLocation2.ActivateObjectivePulse(racer)
        else if(randomEndIndex = 3):
            EndZone3.Enable()
            EndLocation3.Enable()
            if(racer := racersList[0]):
                EndLocation3.ActivateObjectivePulse(racer)
        else:
            EndZone4.Enable()
            EndLocation4.Enable()
            if(racer := racersList[0]):
                EndLocation4.ActivateObjectivePulse(racer)

    updateSprintRacePregameMessage():void=
        var nRacers : int = racersList.Length
        if(nRacers = 0):
            MessageDevice.SetText(startRacePregameMessage0)
        else if(nRacers = 1):
            MessageDevice.SetText(startRacePregameMessage1)
        else if(nRacers = 2):
            MessageDevice.SetText(startRacePregameMessage2)
        else if(nRacers = 3):
            MessageDevice.SetText(startRacePregameMessage3)
        else:
            MessageDevice.SetText(startRacePregameMessage4)
        MessageDevice.SetDisplayTime(0.0)
        MessageDevice.Show()

    initEndZones():void=
        EndZone1.AgentEntersEvent.Subscribe(onAgentEntersZone1)
        EndZone2.AgentEntersEvent.Subscribe(onAgentEntersZone2)
        EndZone3.AgentEntersEvent.Subscribe(onAgentEntersZone3)
        EndZone4.AgentEntersEvent.Subscribe(onAgentEntersZone4)
        EndZone1.AgentExitsEvent.Subscribe(onAgentExitsZone1)
        EndZone2.AgentExitsEvent.Subscribe(onAgentExitsZone2)
        EndZone3.AgentExitsEvent.Subscribe(onAgentExitsZone3)
        EndZone4.AgentExitsEvent.Subscribe(onAgentExitsZone4)

    searchRacerList(Agent: agent):logic=
        for(Index := 0..racersList.Length-1):
            if(racer := racersList[Index]):
                if(racer = Agent):
                    return true
        return false

    onAgentEntersZone1(Agent: agent):void=
        if(startZoneIndex = 1):
            onAgentEntersStartZone(Agent)
        else if(randomEndIndex = 1):
            onAgentEntersEndZone(Agent)

    onAgentExitsZone1(Agent: agent):void=
        if(startZoneIndex = 1):
            onAgentExitsStartZone(Agent)

    onAgentEntersZone2(Agent: agent):void=
        if(startZoneIndex = 2):
            onAgentEntersStartZone(Agent)
        else if(randomEndIndex = 2):
            onAgentEntersEndZone(Agent)

    onAgentExitsZone2(Agent: agent):void=
        if(startZoneIndex = 2):
            onAgentExitsStartZone(Agent)

    onAgentEntersZone3(Agent: agent):void=
        if(startZoneIndex = 3):
            onAgentEntersStartZone(Agent)
        else if(randomEndIndex = 3):
            onAgentEntersEndZone(Agent)

    onAgentExitsZone3(Agent: agent):void=
        if(startZoneIndex = 3):
            onAgentExitsStartZone(Agent)

    onAgentEntersZone4(Agent: agent):void=
        if(startZoneIndex = 4):
            onAgentEntersStartZone(Agent)
        else if(randomEndIndex = 4):
            onAgentEntersEndZone(Agent)

    onAgentExitsZone4(Agent: agent):void=
        if(startZoneIndex = 4):
            onAgentExitsStartZone(Agent)

    onAgentEntersStartZone(Agent: agent):void=
        if(raceStarted = false):
            var playerInRacerList: logic = searchRacerList(Agent)

            if(playerInRacerList = false):
                set racersList = racersList + array{Agent}
                updateSprintRacePregameMessage()

    onAgentExitsStartZone(Agent: agent):void=
        if(raceStarted = false):
            var playerInRacerList: logic = searchRacerList(Agent)

            if(playerInRacerList = true):
                removePlayerFromList(Agent)
                updateSprintRacePregameMessage()

    removePlayerFromList(Agent: agent):void=
        var newList : []agent = array{}
        for(Index := 0..racersList.Length-1):
            if(racer := racersList[Index]):
                var playerToRemoveFound : logic = false
                if(racer = Agent):
                    set playerToRemoveFound = true
                if(playerToRemoveFound = false):
                    set newList = newList + array{racer}
        set racersList = newList

    onAgentEntersEndZone(Agent: agent):void=
        var playerInRacerList: logic = searchRacerList(Agent)
        if(playerInRacerList = true):
            awardWinner(Agent)
            resetSprintRaceMinigame()

    awardWinner(Agent: agent):void=
        for(Index := 0..racersList.Length-1):
            WinnerAwardGranter.GrantItem(Agent)
        xpGranter.Award(Agent)

    resetSprintRaceMinigame():void=
        updateRaceInstance()
        showRaceEndedMessage()
        enableStartRaceButtons()
        disableStartZone()
        disableEndZone()
        set racersList = array{}
        set raceInProgress = false
        set raceStarted = false
        set startZoneIndex = -1
        set randomEndIndex = -1

    disableEndZone():void=
        if(randomEndIndex = 1):
            EndZone1.Disable()
            if(racer := racersList[0]):
                EndLocation1.DeactivateObjectivePulse(racer)
            EndLocation1.Disable()
        else if(randomEndIndex = 2):
            EndZone2.Disable()
            if(racer := racersList[0]):
                EndLocation2.DeactivateObjectivePulse(racer)
            EndLocation2.Disable()
        else if(randomEndIndex = 3):
            EndZone3.Disable()
            if(racer := racersList[0]):
                EndLocation3.DeactivateObjectivePulse(racer)
            EndLocation3.Disable()
        else:
            EndZone4.Disable()
            if(racer := racersList[0]):
                EndLocation4.DeactivateObjectivePulse(racer)
            EndLocation4.Disable()

    showRaceEndedMessage():void=
        MessageDevice.SetText(raceEndedMessage)
        MessageDevice.SetDisplayTime(5.0)
        MessageDevice.Show()
