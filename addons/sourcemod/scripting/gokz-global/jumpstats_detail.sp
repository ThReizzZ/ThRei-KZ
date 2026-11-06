/*
	Keeps the detailed GOKZ jump data until the local database confirms that
	the jump was a PB. Only PBs are sent to the API.
*/

static Jump g_LastJump[MAXPLAYERS + 1];
static int gI_LastJumpMode[MAXPLAYERS + 1];
static bool gB_HasLastJump[MAXPLAYERS + 1];

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

	g_LastJump[client] = jump;
	gI_LastJumpMode[client] = GOKZ_GetCoreOption(client, Option_Mode);
	gB_HasLastJump[client] = true;
}

void AddJumpstatDetails(
	JSON_Object info,
	int client,
	int jumptype,
	int mode,
	float distance,
	int block)
{
	if (!gB_HasLastJump[client])
	{
		return;
	}

	if (g_LastJump[client].type != jumptype
		|| gI_LastJumpMode[client] != mode
		|| g_LastJump[client].block != block
		|| FloatAbs(g_LastJump[client].distance - distance) > 0.05)
	{
		return;
	}

	info.SetFloat("width", g_LastJump[client].width);
	info.SetFloat("height", g_LastJump[client].height);
	info.SetFloat("offset", g_LastJump[client].offset);
	info.SetFloat("deviation", g_LastJump[client].deviation);
	info.SetInt("crouch_ticks", g_LastJump[client].crouchTicks);
	info.SetInt("overlap", g_LastJump[client].overlap);
	info.SetInt("deadair", g_LastJump[client].deadair);

	JSON_Object strafes = new JSON_Object(true);
	int count = g_LastJump[client].strafes;
	if (count > JS_MAX_TRACKED_STRAFES)
	{
		count = JS_MAX_TRACKED_STRAFES;
	}

	for (int i = 1; i <= count; i++)
	{
		int ticks = g_LastJump[client].strafes_ticks[i];
		float sync = ticks > 0
			? float(g_LastJump[client].strafes_gainTicks[i]) / float(ticks) * 100.0
			: 0.0;
		float airtime = g_LastJump[client].duration > 0
			? float(ticks) / float(g_LastJump[client].duration) * 100.0
			: 0.0;

		JSON_Object strafe = new JSON_Object();
		strafe.SetFloat("sync", sync);
		strafe.SetFloat("gain", g_LastJump[client].strafes_gain[i]);
		strafe.SetFloat("loss", g_LastJump[client].strafes_loss[i]);
		strafe.SetFloat("airtime", airtime);
		strafe.SetFloat("width", g_LastJump[client].strafes_width[i]);
		strafe.SetInt("overlap", g_LastJump[client].strafes_overlap[i]);
		strafe.SetInt("deadair", g_LastJump[client].strafes_deadair[i]);
		strafes.PushObject(strafe);
	}

	info.SetObject("strafes_detail", strafes);
}
