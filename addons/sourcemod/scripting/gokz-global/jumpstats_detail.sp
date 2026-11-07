/*
	Keeps the detailed GOKZ jump data until the local database confirms that
	the jump was a PB. Only PBs are sent to the API.
*/

#define RECENT_JUMP_COUNT 4

static Jump g_RecentJumps[MAXPLAYERS + 1][RECENT_JUMP_COUNT];
static int gI_RecentJumpModes[MAXPLAYERS + 1][RECENT_JUMP_COUNT];
static int gI_RecentJumpIndex[MAXPLAYERS + 1];
static int gI_RecentJumpCount[MAXPLAYERS + 1];

public void OnClientDisconnect(int client)
{
	gI_RecentJumpIndex[client] = 0;
	gI_RecentJumpCount[client] = 0;
}

public void GOKZ_JS_OnLanding(Jump jump)
{
	int client = jump.jumper;
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}

	if (jump.type < 0 || jump.type > 8 || jump.distance <= 0.0)
	{
		return;
	}

	int slot = gI_RecentJumpIndex[client];
	g_RecentJumps[client][slot] = jump;
	gI_RecentJumpModes[client][slot] = GOKZ_GetCoreOption(client, Option_Mode);
	gI_RecentJumpIndex[client] = (slot + 1) % RECENT_JUMP_COUNT;
	if (gI_RecentJumpCount[client] < RECENT_JUMP_COUNT)
	{
		gI_RecentJumpCount[client]++;
	}
}

void AddJumpstatDetails(
	JSON_Object info,
	int client,
	int jumptype,
	int mode,
	float distance,
	int block)
{
	for (int offset = 1; offset <= gI_RecentJumpCount[client]; offset++)
	{
		int index = (gI_RecentJumpIndex[client] - offset + RECENT_JUMP_COUNT) % RECENT_JUMP_COUNT;

		if (g_RecentJumps[client][index].type != jumptype
			|| gI_RecentJumpModes[client][index] != mode
			|| g_RecentJumps[client][index].block != block
			|| FloatAbs(g_RecentJumps[client][index].distance - distance) > 0.1)
		{
			continue;
		}

		info.SetFloat("width", g_RecentJumps[client][index].width);
		info.SetFloat("height", g_RecentJumps[client][index].height);
		info.SetFloat("offset", g_RecentJumps[client][index].offset);
		info.SetFloat("deviation", g_RecentJumps[client][index].deviation);
		info.SetInt("crouch_ticks", g_RecentJumps[client][index].crouchTicks);
		info.SetInt("overlap", g_RecentJumps[client][index].overlap);
		info.SetInt("deadair", g_RecentJumps[client][index].deadair);
		info.SetInt("release_w", g_RecentJumps[client][index].releaseW);
		info.SetInt("airtime_ticks", g_RecentJumps[client][index].duration);

		JSON_Object strafes = new JSON_Object(true);
		int count = g_RecentJumps[client][index].strafes;
		if (count > JS_MAX_TRACKED_STRAFES)
		{
			count = JS_MAX_TRACKED_STRAFES;
		}

		for (int i = 1; i <= count; i++)
		{
			int ticks = g_RecentJumps[client][index].strafes_ticks[i];
			float sync = ticks > 0
				? float(g_RecentJumps[client][index].strafes_gainTicks[i]) / float(ticks) * 100.0
				: 0.0;
			float airtime = g_RecentJumps[client][index].duration > 0
				? float(ticks) / float(g_RecentJumps[client][index].duration) * 100.0
				: 0.0;

			JSON_Object strafe = new JSON_Object();
			strafe.SetFloat("sync", sync);
			strafe.SetFloat("gain", g_RecentJumps[client][index].strafes_gain[i]);
			strafe.SetFloat("loss", g_RecentJumps[client][index].strafes_loss[i]);
			strafe.SetFloat("airtime", airtime);
			strafe.SetFloat("width", g_RecentJumps[client][index].strafes_width[i]);
			strafe.SetInt("overlap", g_RecentJumps[client][index].strafes_overlap[i]);
			strafe.SetInt("deadair", g_RecentJumps[client][index].strafes_deadair[i]);
			strafes.PushObject(strafe);
		}

		info.SetObject("strafes_detail", strafes);
		return;
	}
}
