/*
	Keeps the detailed GOKZ jump data until the local database confirms that
	the jump was a PB. Only PBs are sent to the API.

	Debug build: logs landing captures and PB match results to the SourceMod
	log so detail upload failures can be diagnosed on a live server.
	Set sm_threi_jumpstats_debug 0 to disable the log output.
*/

#define RECENT_JUMP_COUNT 8
#define THREI_JUMPSTAT_DETAIL_BUILD "2026-11-07T22:32+08"

static ConVar gCV_JumpstatDetailDebug;
static Jump g_RecentJumps[MAXPLAYERS + 1][RECENT_JUMP_COUNT];
static int gI_RecentJumpModes[MAXPLAYERS + 1][RECENT_JUMP_COUNT];
static int gI_RecentJumpIndex[MAXPLAYERS + 1];
static int gI_RecentJumpCount[MAXPLAYERS + 1];

void OnPluginStart_JumpstatDetails()
{
	gCV_JumpstatDetailDebug = CreateConVar(
		"sm_threi_jumpstats_debug",
		"1",
		"Log PB jump detail capture to the SourceMod log (0 = off).",
		0,
		true,
		0.0,
		true,
		1.0);

	LogMessage("[ThReiJump] detail build %s loaded, queue=%d", THREI_JUMPSTAT_DETAIL_BUILD, RECENT_JUMP_COUNT);
}

public void OnClientDisconnect(int client)
{
	gI_RecentJumpIndex[client] = 0;
	gI_RecentJumpCount[client] = 0;
}

public void GOKZ_JS_OnLanding(Jump jump)
{
	CacheJumpDetails(jump);
}

public void GOKZ_JS_OnJumpstatAlways(Jump jump)
{
	CacheJumpDetails(jump);
}

static void CacheJumpDetails(Jump jump)
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

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int slot = gI_RecentJumpIndex[client];

	// Copy field by field. Whole-struct assignment to an array element has
	// not been reliable here, which left the cached distance at 0.
	g_RecentJumps[client][slot].jumper = jump.jumper;
	g_RecentJumps[client][slot].block = jump.block;
	g_RecentJumps[client][slot].crouchRelease = jump.crouchRelease;
	g_RecentJumps[client][slot].crouchTicks = jump.crouchTicks;
	g_RecentJumps[client][slot].deadair = jump.deadair;
	g_RecentJumps[client][slot].duration = jump.duration;
	g_RecentJumps[client][slot].originalType = jump.originalType;
	g_RecentJumps[client][slot].overlap = jump.overlap;
	g_RecentJumps[client][slot].releaseW = jump.releaseW;
	g_RecentJumps[client][slot].strafes = jump.strafes;
	g_RecentJumps[client][slot].type = jump.type;
	g_RecentJumps[client][slot].deviation = jump.deviation;
	g_RecentJumps[client][slot].distance = jump.distance;
	g_RecentJumps[client][slot].edge = jump.edge;
	g_RecentJumps[client][slot].height = jump.height;
	g_RecentJumps[client][slot].maxSpeed = jump.maxSpeed;
	g_RecentJumps[client][slot].offset = jump.offset;
	g_RecentJumps[client][slot].preSpeed = jump.preSpeed;
	g_RecentJumps[client][slot].sync = jump.sync;
	g_RecentJumps[client][slot].width = jump.width;
	g_RecentJumps[client][slot].miss = jump.miss;

	for (int i = 0; i < JS_MAX_TRACKED_STRAFES; i++)
	{
		g_RecentJumps[client][slot].strafes_gainTicks[i] = jump.strafes_gainTicks[i];
		g_RecentJumps[client][slot].strafes_deadair[i] = jump.strafes_deadair[i];
		g_RecentJumps[client][slot].strafes_overlap[i] = jump.strafes_overlap[i];
		g_RecentJumps[client][slot].strafes_ticks[i] = jump.strafes_ticks[i];
		g_RecentJumps[client][slot].strafes_gain[i] = jump.strafes_gain[i];
		g_RecentJumps[client][slot].strafes_loss[i] = jump.strafes_loss[i];
		g_RecentJumps[client][slot].strafes_sync[i] = jump.strafes_sync[i];
		g_RecentJumps[client][slot].strafes_width[i] = jump.strafes_width[i];
	}

	gI_RecentJumpModes[client][slot] = mode;
	gI_RecentJumpIndex[client] = (slot + 1) % RECENT_JUMP_COUNT;
	if (gI_RecentJumpCount[client] < RECENT_JUMP_COUNT)
	{
		gI_RecentJumpCount[client]++;
	}

	if (gCV_JumpstatDetailDebug != null && gCV_JumpstatDetailDebug.BoolValue)
	{
		LogMessage(
			"[ThReiJump] cache client=%d type=%d mode=%d block=%d dist=%.4f slot=%d count=%d",
			client,
			jump.type,
			mode,
			jump.block,
			jump.distance,
			slot,
			gI_RecentJumpCount[client]);
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
	info.SetString("detail_build", THREI_JUMPSTAT_DETAIL_BUILD);
	info.SetInt("detail_cache", gI_RecentJumpCount[client]);

	// Diagnostic snapshot of the cache, visible in the API's raw payload log.
	char recent[700];
	recent[0] = '\0';
	for (int offset = 1; offset <= gI_RecentJumpCount[client]; offset++)
	{
		int index = (gI_RecentJumpIndex[client] - offset + RECENT_JUMP_COUNT) % RECENT_JUMP_COUNT;
		char item[80];
		FormatEx(
			item,
			sizeof(item),
			"%s#%d t%d m%d b%d d%.4f",
			offset == 1 ? "" : " | ",
			offset,
			g_RecentJumps[client][index].type,
			gI_RecentJumpModes[client][index],
			g_RecentJumps[client][index].block,
			g_RecentJumps[client][index].distance);
		StrCat(recent, sizeof(recent), item);
	}
	info.SetString("detail_recent", recent);

	for (int offset = 1; offset <= gI_RecentJumpCount[client]; offset++)
	{
		int index = (gI_RecentJumpIndex[client] - offset + RECENT_JUMP_COUNT) % RECENT_JUMP_COUNT;

		// A non-block PB (block == 0) can come from the same jump that GOKZ
		// also recorded with a map block. Only compare the block number for
		// actual block PBs.
		bool blockMatches = block == 0 || g_RecentJumps[client][index].block == block;

		if (g_RecentJumps[client][index].type != jumptype
			|| gI_RecentJumpModes[client][index] != mode
			|| !blockMatches
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
		info.SetInt("detail_match", 1);

		if (gCV_JumpstatDetailDebug != null && gCV_JumpstatDetailDebug.BoolValue)
		{
			LogMessage(
				"[ThReiJump] pb client=%d type=%d mode=%d block=%d dist=%.4f cache=%d matched=%d strafes=%d",
				client,
				jumptype,
				mode,
				block,
				distance,
				gI_RecentJumpCount[client],
				index,
				count);
		}
		return;
	}

	if (gCV_JumpstatDetailDebug != null && gCV_JumpstatDetailDebug.BoolValue)
	{
		LogMessage(
			"[ThReiJump] pb client=%d type=%d mode=%d block=%d dist=%.4f cache=%d matched=-1",
			client,
			jumptype,
			mode,
			block,
			distance,
			gI_RecentJumpCount[client]);
	}
	info.SetInt("detail_match", 0);
}
