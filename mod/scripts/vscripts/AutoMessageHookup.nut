untyped
global function AutoMessageHookup

void function AutoMessageHookup()
{
	AddModTitle("Auto Messages")
	AddModCategory("General settings")

	AddConVarSetting("auto_message_start_text", "Message to send at start of game (ex. glhf)", "string")
	AddConVarSetting("auto_message_half_text", "Message to send at end of first half (ex. gh)", "string")
	AddConVarSetting("auto_message_end_text", "Message to send at end of game (ex. gg)", "string")

	AddConVarSettingSlider("auto_message_wait_time", "Wait duration before sending messages", 0, 10, 0.1, false)
}