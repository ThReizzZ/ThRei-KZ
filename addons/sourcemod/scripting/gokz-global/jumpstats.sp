/*
	Uploads jumpstat PBs to the ThRei API through the GlobalAPI compatibility
	layer. GOKZ only calls this forward after the local database accepted a new
	personal best, so this does not send every jump.
*/

public void GOKZ_DB_OnJumpstatPB(
	int client,
	int jumptype,
	int mode,
	float distance,
	int block,
	int strafes,
	float sync,
	float pre,
	float max,
	int airtime)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}

	// Only the jump types that the website knows about.
	if (jumptype < 0 || jumptype > 8 || mode < 0 || mode > 2 || distance <= 0.0)
	{
		return;
	}

	if (!GlobalAPI_IsInit() || !GlobalAPI_HasAPIKey())
	{
		return;
	}

	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		return;
	}

	char alias[64];
	GetClientName(client, alias, sizeof(alias));

	// The forward passes airtime as a scaled integer; the API stores seconds.
	float airtimeSeconds = float(airtime) / 10000.0;

	JSON_Object info = new JSON_Object();
	info.SetInt("mode", mode);
	info.SetInt("block", block);
	info.SetInt("strafes", strafes);
	info.SetFloat("sync", sync);
	info.SetFloat("pre", pre);
	info.SetFloat("max", max);
	info.SetFloat("airtime", airtimeSeconds);
	info.SetString("alias", alias);
	AddJumpstatDetails(info, client, jumptype, mode, distance, block);

	char json[8192];
	info.Encode(json, sizeof(json));
	delete info;

	bool sent = GlobalAPI_CreateJumpstat(
		INVALID_FUNCTION,
		0,
		steamid,
		jumptype,
		distance,
		json,
		128,
		0,
		false,
		false,
		false,
		strafes);

	LogMessage("[ThReiJump] upload json_len=%d sent=%d", strlen(json), sent);
}

public void GOKZ_RP_OnJumpReplaySaved(
	int client,
	int jumpType,
	int mode,
	int style,
	float distance,
	int block,
	const char[] filePath)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}

	if (!GlobalAPI_IsInit() || !GlobalAPI_HasAPIKey())
	{
		return;
	}

	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		return;
	}

	GlobalAPI_CreateJumpstatReplay(
		INVALID_FUNCTION,
		0,
		steamid,
		jumpType,
		mode,
		distance,
		block,
		filePath);
}
