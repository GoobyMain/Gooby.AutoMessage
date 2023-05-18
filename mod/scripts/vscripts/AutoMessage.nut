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

void function RemoveCallback_GameStateEnter( int gameState, void functionref() callbackFunc )
{
    Assert( gameState < clGlobal.gameStateEnterCallbacks.len() )

    Assert( clGlobal.gameStateEnterCallbacks[ gameState ].contains( callbackFunc ), "Have not added " + string( callbackFunc ) + " with AddCallback_GameStateEnter" )

    clGlobal.gameStateEnterCallbacks[ gameState ].remove( clGlobal.gameStateEnterCallbacks[ gameState ].find( callbackFunc ) )
}

void function MatchStart()
{
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageStartText = GetConVarString( "auto_message_start_text" )
    AutoMessageEndText = GetConVarString( "auto_message_end_text" )

    if ( AutoMessageStartText != "" )
        thread SendMessage( AutoMessageStartText, AutoMessageWaitTime )
    
    if ( IsRoundBased() )
    {
        if ( AutoMessageStartText != "" )
            AddCallback_GameStateEnter( eGameState.Postmatch, EpilogueOver )

        RemoveCallback_GameStateEnter( eGameState.WinnerDetermined, MatchEnd )
    }
    
    RemoveCallback_GameStateEnter( eGameState.Prematch, MatchStart )
}

void function MatchHalf()
{
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageHalfText = GetConVarString( "auto_message_half_text" )

    if ( AutoMessageHalfText != "" )
        thread SendMessage( AutoMessageHalfText, AutoMessageWaitTime )
    
}

void function MatchEnd()
{
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )
    AutoMessageEndText = GetConVarString( "auto_message_end_text" )

    if ( AutoMessageEndText != "" )
    {
        wait 1 // This gives enough time for the gamestate to change from eGameState.WinnerDetermined to eGameState.Epilogue if there's an epilogue

        if ( GetGameState() == eGameState.WinnerDetermined ) // eGameState.WinnerDetermined here means there's no epilogue
        {
            // Adjust AutoMessageWaitTime for that 1 second wait from earlier
            if ( AutoMessageWaitTime < 1 )
                AutoMessageWaitTime = 0
            else
                AutoMessageWaitTime = AutoMessageWaitTime - 1.0
            
            thread SendMessage( AutoMessageEndText, AutoMessageWaitTime )
        }
        else if ( GetGameState() == eGameState.Epilogue ) // eGameState.Epilogue means there is epilogue
        {
            MessageSentDuringEpilogue = false

            AddOnDeathCallback( "player", PlayerDiedDuringEpilogue )
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
    thread SendMessageDuringEpilogue( AutoMessageEndText, 0 )
}

void function SendMessageDuringEpilogue( string MessageText, float WaitTime )
{
    wait WaitTime

    if ( MessageSentDuringEpilogue == false )
    {
        MessageSentDuringEpilogue = true

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
// when you die in epilogue, first check if you can respawn, before sending message or removing callbacks
//
// add other events with corresponding messages - pilot execution, titan execution, getting executed, getting shot from far away?