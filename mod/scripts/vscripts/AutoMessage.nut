global function InitAutoMessage

global float AutoMessageWaitTime

global string AutoMessageStartText
global string AutoMessageHalfText
global string AutoMessageEndText

global bool MessageSentDuringEpilogue

void function InitAutoMessage()
{
    if ( IsMultiplayer() )
    {
        AddCallback_GameStateEnter( eGameState.Prematch, MatchStart )
        AddCallback_GameStateEnter( eGameState.SwitchingSides, MatchHalf )
        AddCallback_GameStateEnter( eGameState.WinnerDetermined, MatchEnd )
    }
}

void function MatchStart()
{
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageStartText = GetConVarString( "auto_message_start_text" )

    if ( AutoMessageStartText != "" )
        SendMessage( AutoMessageStartText, AutoMessageWaitTime )
    
}

void function MatchHalf()
{
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageHalfText = GetConVarString( "auto_message_half_text" )

    if ( AutoMessageHalfText != "" )
        SendMessage( AutoMessageHalfText, AutoMessageWaitTime )
    
}

void function MatchEnd()
{   
    wait 1 // This gives enough time for the gamestate to change from eGameState.WinnerDetermined to eGameState.Epilogue if there's an epilogue

    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageEndText = GetConVarString( "auto_message_end_text" )

    if ( AutoMessageEndText != "" )
    {
        if ( GetGameState() == eGameState.WinnerDetermined ) // eGameState.WinnerDetermined here means there's no epilogue
        {
            // Adjust AutoMessageWaitTime for that 1 second wait from earlier
            if ( AutoMessageWaitTime < 1 )
                AutoMessageWaitTime = 0
            else
                AutoMessageWaitTime = AutoMessageWaitTime - 1.0
            
            SendMessage( AutoMessageEndText, AutoMessageWaitTime )
        }
        else if ( GetGameState() == eGameState.Epilogue ) // eGameState.Epilogue means there is epilogue
        {
            AddOnDeathCallback( "player", PlayerDiedDuringEpilogue )
            MessageSentDuringEpilogue = false
            // I don't really like using this, the best way to do it would be to write a function to check if there's a callback in the list that calls PlayerDiedDuringEpilogue, but I'm lazy

            AddCallback_GameStateEnter( eGameState.Postmatch, EpilogueOver ) // eGameState.Postmatch means game is over, showing scoreboard
        }
    }
}

void function PlayerDiedDuringEpilogue( entity player )
{
    if ( player == GetLocalClientPlayer() )
    {
        thread SendMessageDuringEpilogue( AutoMessageEndText, AutoMessageWaitTime )
    }
}

void function EpilogueOver()
{
    SendMessageDuringEpilogue( AutoMessageEndText, 0 )
}

void function SendMessageDuringEpilogue( string MessageText, float WaitTime )
{
    wait WaitTime

    if ( MessageSentDuringEpilogue == false )
    {
        MessageSentDuringEpilogue = true //RemoveOnDeathCallback( "player" , PlayerDiedDuringEpilogue )//<----------------------------------------------------------------------------

        GetLocalClientPlayer().ClientCommand( "say " + MessageText )
    }
}

void function SendMessage( string MessageText, float WaitTime )
{
    wait WaitTime
    GetLocalClientPlayer().ClientCommand( "say " + MessageText )
}


// TODO
//
// HANDLE GAMEMODES WITH MULTIPLE ROUNDS - WINNERDETERMINED PLAYS AT END OF EACH ROUND
//
// fix double gg bug if you die at end of epilogue
// caused by removeondeathcallback not stopping sendmessage() if it's already waiting
//
// when you die in epilogue, first check if you can respawn, before sending message or removing callbacks
//
// write functions for managing death callbacks - one to check if it exists and one to remove it
//
// add other events with corresponding messages - pilot execution, titan execution, getting executed, getting shot from far away?