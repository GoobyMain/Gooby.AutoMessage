global function InitAutoMessage

global float AutoMessageWaitTime

global string AutoMessageStartText
global string AutoMessageHalfText
global string AutoMessageEndText

global bool MessageSentDuringEpilogue

/*
Is there a client-side callback for when you connect to a server? But that wouldn't trigger when you connect to the main multiplayer menu?
*/

void function InitAutoMessage()
{
    if ( !IsMultiplayer() )
        return

    if ( GetMapName() == "mp_lobby" )
       return
       
    AutoMessageWaitTime = GetConVarFloat( "auto_message_wait_time" )

    AutoMessageStartText = GetConVarString( "auto_message_start_text" )
    AutoMessageHalfText = GetConVarString( "auto_message_half_text" )
    AutoMessageEndText = GetConVarString( "auto_message_end_text" )


    if ( AutoMessageStartText != "" )
        AddCallback_GameStateEnter( eGameState.Prematch, MatchStart )

    if ( AutoMessageHalfText != "" )
        AddCallback_GameStateEnter( eGameState.SwitchingSides, MatchHalf )

    if ( AutoMessageEndText != "" )
    {
        if ( IsRoundBased() )
            AddCallback_GameStateEnter( eGameState.Postmatch, EpilogueOver )
        else
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
    thread SendMessage( AutoMessageStartText, AutoMessageWaitTime )

    RemoveCallback_GameStateEnter( eGameState.Prematch, MatchStart )    
}

void function MatchHalf()
{
    thread SendMessage( AutoMessageHalfText, AutoMessageWaitTime )
}

void function MatchEnd()
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

// try AddOnDeathCallback( GetLocalClientPlayer(), PlayerDiedEpilogue )

// make sure if you join a round based game mid-game, it runs the code in MatchStart() that initializes the right glhf and gg messages

// add other events with corresponding messages - pilot execution, titan execution, getting executed, getting shot from far away? when you get stuck and die?

/*
bool function ShouldDoReplay( entity player, entity attacker, float replayTime, int methodOfDeath )
{
    if ( ShouldDoReplayIsForcedByCode() )
    {
        print( "ShouldDoReplay(): Doing a replay because code forced it." );
        return true
    }

    if ( GetCurrentPlaylistVarInt( "replay_disabled", 0 ) == 1 )
    {
        print( "ShouldDoReplay(): Not doing a replay because 'replay_disabled' is enabled in the current playlist.\n" );
        return false
    }

    switch( methodOfDeath )
    {
        case eDamageSourceId.human_execution:
        case eDamageSourceId.titan_execution:
        {
            print( "ShouldDoReplay(): Not doing a replay because the player died from an execution.\n" );
            return false
        }
    }

    if ( level.nv.replayDisabled )
    {
        print( "ShouldDoReplay(): Not doing a replay because replays are disabled for the level.\n" );
        return false
    }

    if ( Time() - player.p.connectTime <= replayTime ) //Bad things happen if we try to do a kill replay that lasts longer than the player entity existing on the server
    {
        print( "ShouldDoReplay(): Not doing a replay because the player is not old enough.\n" );
        return false
    }

    if ( player == attacker )
    {
        print( "ShouldDoReplay(): Not doing a replay because the attacker is the player.\n" );
        return false
    }

    if ( player.IsBot() == true )
    {
        print( "ShouldDoReplay(): Not doing a replay because the player is a bot.\n" );
        return false
    }

    return AttackerShouldTriggerReplay( attacker )
}
*/