/*
	Globally ban players when they are suspected by gokz-anticheat.
*/



// =====[ PUBLIC ]=====

void GlobalBanPlayer(int client, ACReason reason, const char[] notes, const char[] stats)
{
	char playerName[MAX_NAME_LENGTH], steamid[32], ip[32];
	
	GetClientName(client, playerName, sizeof(playerName));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientIP(client, ip, sizeof(ip));
	
	DataPack dp = new DataPack();
	dp.WriteString(playerName);
	dp.WriteString(steamid);
	
	ConVar durationConVar;
	switch (reason)
	{
		case ACReason_BhopHack: durationConVar = FindConVar("gokz_autoban_duration_bhop_hack");
		case ACReason_BhopMacro: durationConVar = FindConVar("gokz_autoban_duration_bhop_macro");
	}
	int durationMinutes = durationConVar != null ? durationConVar.IntValue : 0;
	
	switch (reason)
	{
		case ACReason_BhopHack:GlobalAPI_CreateBanEx(BanPlayerCallback, dp, steamid, "bhop_hack", stats, notes, ip, durationMinutes);
		case ACReason_BhopMacro:GlobalAPI_CreateBanEx(BanPlayerCallback, dp, steamid, "bhop_macro", stats, notes, ip, durationMinutes);
	}
}

public int BanPlayerCallback(JSON_Object response, GlobalAPIRequestData request, DataPack dp)
{
	char playerName[MAX_NAME_LENGTH], steamid[32];
	
	dp.Reset();
	dp.ReadString(playerName, sizeof(playerName));
	dp.ReadString(steamid, sizeof(steamid));
	delete dp;
	
	if (request.Failure)
	{
		LogError("Failed to globally ban %s (%s).", playerName, steamid);
	}
	return 0;
}
