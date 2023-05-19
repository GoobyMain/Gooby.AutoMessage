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
        const WAIT_FOR_GAMESTATE_CHANGE = 1.0

        wait 1 // This gives enough time for the gamestate to change from eGameState.WinnerDetermined to eGameState.Epilogue if there's an epilogue

        if ( GetGameState() == eGameState.WinnerDetermined ) // eGameState.WinnerDetermined here means there's no epilogue
        {
            // Adjust AutoMessageWaitTime for that wait from earlier
            if ( AutoMessageWaitTime < WAIT_FOR_GAMESTATE_CHANGE )
                AutoMessageWaitTime = 0
            else
                AutoMessageWaitTime = AutoMessageWaitTime - WAIT_FOR_GAMESTATE_CHANGE
            
            thread SendMessage( AutoMessageEndText, AutoMessageWaitTime )
        }
        else if ( GetGameState() == eGameState.Epilogue ) // eGameState.Epilogue means there is epilogue
        {
            MessageSentDuringEpilogue = false

            AddOnDeathCallback( "player", PlayerDiedEpilogue )
            AddCallback_GameStateEnter( eGameState.Postmatch, EpilogueOver ) // eGameState.Postmatch means game is over, showing scoreboard
        }
    }
}

void function PlayerDiedEpilogue( entity player )
{
    if ( player == GetLocalClientPlayer() )
        thread ValidateDeathEpilogue( player )
}

void function ValidateDeathEpilogue( entity player )
{
    const WAIT_FOR_RESPAWN_AVAILABLE = 1.0

    wait WAIT_FOR_RESPAWN_AVAILABLE // This gives enough time for IsRespawnAvailable() to update

    if ( !IsRespawnAvailable( player ) )
    {
        // Adjust AutoMessageWaitTime for wait
        if ( AutoMessageWaitTime < WAIT_FOR_RESPAWN_AVAILABLE )
            AutoMessageWaitTime = 0
        else
            AutoMessageWaitTime = AutoMessageWaitTime - WAIT_FOR_RESPAWN_AVAILABLE

        thread SendMessageEpilogue( AutoMessageEndText, AutoMessageWaitTime )
    }
}

void function EpilogueOver()
{
    thread SendMessageEpilogue( AutoMessageEndText, 0 )
}

void function SendMessageEpilogue( string MessageText, float WaitTime )
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
// add other events with corresponding messages - pilot execution, titan execution, getting executed, getting shot from far away?