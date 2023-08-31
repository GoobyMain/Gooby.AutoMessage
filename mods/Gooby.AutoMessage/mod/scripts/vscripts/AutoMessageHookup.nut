untyped
global function AutoMessageHookup

void function AutoMessageHookup()
{
	ModSettings_AddModTitle("Auto Messages")
	ModSettings_AddModCategory("General settings")

	ModSettings_AddSetting("auto_message_start_text", "Message to send at start of game (ex. glhf)", "string")
	ModSettings_AddSetting("auto_message_half_text", "Message to send at end of first half (ex. gh)", "string")
	ModSettings_AddSetting("auto_message_end_text", "Message to send at end of game (ex. gg)", "string")

	ModSettings_AddSliderSetting("auto_message_wait_time", "Wait duration before sending messages", 0, 10, 0.1, false)
}