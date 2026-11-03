#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>

#define PLUGIN_VERSION "0.1.0"
#define MAX_BODY 32768
#define MAX_FIELD 256

public Plugin myinfo =
{
    name = "ThRei KZ Uploader",
    author = "ThRei",
    description = "Uploads GOKZ runs to the ThRei KZ API",
    version = PLUGIN_VERSION,
    url = "https://threi.cn"
};

ConVar g_CVEnable;
ConVar g_CVApiUrl;
ConVar g_CVApiKey;
ConVar g_CVBatchSize;
ConVar g_CVInterval;
ConVar g_CVBackfillFrom;
ConVar g_CVDebug;

Database g_DB;
Handle g_Timer;
int g_Cursor;
bool g_Uploading;
bool g_WarnedNoKey;

public void OnPluginStart()
{
    g_CVEnable = CreateConVar("sm_threi_enable", "1", "Enable ThRei KZ uploads", _, true, 0.0, true, 1.0);
    g_CVApiUrl = CreateConVar("sm_threi_api_url", "https://api.threi.cn", "ThRei KZ API base URL");
    g_CVApiKey = CreateConVar("sm_threi_api_key", "", "Server API key from ThRei", FCVAR_PROTECTED);
    g_CVBatchSize = CreateConVar("sm_threi_batch_size", "50", "Runs per upload batch", _, true, 1.0, true, 200.0);
    g_CVInterval = CreateConVar("sm_threi_interval", "15.0", "Upload interval in seconds", _, true, 5.0, true, 300.0);
    g_CVBackfillFrom = CreateConVar("sm_threi_backfill_from", "0", "First TimeID to upload when no cursor exists", _, true, 0.0);
    g_CVDebug = CreateConVar("sm_threi_debug", "0", "Enable debug logging", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "threi-kz-uploader");
    g_CVInterval.AddChangeHook(OnIntervalChanged);

    RegAdminCmd("sm_threi_status", Command_Status, ADMFLAG_ROOT, "Show ThRei KZ uploader status");
    RegAdminCmd("sm_threi_flush", Command_Flush, ADMFLAG_ROOT, "Trigger a ThRei KZ upload now");

    LoadCursor();
    ConnectDatabase();

    g_Timer = CreateTimer(g_CVInterval.FloatValue, Timer_Upload, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
    if (g_Timer != null)
    {
        delete g_Timer;
    }

    SaveCursor();

    if (g_DB != null)
    {
        delete g_DB;
    }
}

public Action Command_Status(int client, int args)
{
    char apiUrl[256];
    g_CVApiUrl.GetString(apiUrl, sizeof(apiUrl));

    ReplyToCommand(
        client,
        "[ThRei] enabled=%d cursor=%d uploading=%d api=%s",
        g_CVEnable.BoolValue,
        g_Cursor,
        g_Uploading,
        apiUrl
    );
    return Plugin_Handled;
}

public Action Command_Flush(int client, int args)
{
    if (g_Uploading)
    {
        ReplyToCommand(client, "[ThRei] an upload is already in progress");
        return Plugin_Handled;
    }

    Timer_Upload(null);
    ReplyToCommand(client, "[ThRei] upload triggered");
    return Plugin_Handled;
}

public void OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_Timer != null)
    {
        delete g_Timer;
    }
    g_Timer = CreateTimer(g_CVInterval.FloatValue, Timer_Upload, _, TIMER_REPEAT);
}

void ConnectDatabase()
{
    char error[256];
    g_DB = SQL_Connect("gokz", true, error, sizeof(error));
    if (g_DB == null)
    {
        SetFailState("Could not connect to the GOKZ database: %s", error);
    }

    SQL_SetCharset(g_DB, "utf8mb4");
}

public Action Timer_Upload(Handle timer)
{
    if (!g_CVEnable.BoolValue || g_Uploading)
    {
        return Plugin_Continue;
    }

    char apiKey[128];
    g_CVApiKey.GetString(apiKey, sizeof(apiKey));
    if (apiKey[0] == '\0')
    {
        if (!g_WarnedNoKey)
        {
            LogError("[ThRei] sm_threi_api_key is empty; uploads are disabled until it is set.");
            g_WarnedNoKey = true;
        }
        return Plugin_Continue;
    }
    g_WarnedNoKey = false;

    if (g_DB == null)
    {
        ConnectDatabase();
    }

    char query[2048];
    FormatEx(
        query,
        sizeof(query),
        "SELECT \
            t.TimeID, \
            CAST(((t.SteamID32 & 4294967295) + 76561197960265728) AS TEXT) AS SteamId64, \
            t.Mode, \
            t.Style, \
            t.RunTime, \
            t.Teleports, \
            COALESCE(p.Alias, '') AS Alias, \
            COALESCE(p.Country, '') AS Country, \
            lower(m.Name) AS MapName, \
            mc.Course, \
            COALESCE(strftime('%%Y-%%m-%%dT%%H:%%M:%%SZ', t.Created), strftime('%%Y-%%m-%%dT%%H:%%M:%%SZ', 'now')) AS CreatedIso \
        FROM Times t \
        JOIN Players p ON p.SteamID32 = t.SteamID32 \
        JOIN MapCourses mc ON mc.MapCourseID = t.MapCourseID \
        JOIN Maps m ON m.MapID = mc.MapID \
        WHERE t.TimeID > %d AND p.Cheater = 0 \
        ORDER BY t.TimeID ASC \
        LIMIT %d",
        g_Cursor,
        g_CVBatchSize.IntValue
    );

    g_Uploading = true;
    SQL_TQuery(g_DB, OnQueryComplete, query, 0, DBPrio_Low);
    return Plugin_Continue;
}

public void OnQueryComplete(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0] != '\0' || results == null)
    {
        LogError("[ThRei] SQLite query failed: %s", error);
        g_Uploading = false;
        return;
    }

    char body[MAX_BODY];
    FormatEx(body, sizeof(body), "{\"runs\":[");
    bool first = true;
    int lastTimeId = g_Cursor;
    int count = 0;

    char steamId64[32];
    char alias[MAX_FIELD];
    char country[MAX_FIELD];
    char mapName[MAX_FIELD];
    char createdIso[64];
    char aliasEscaped[MAX_FIELD * 2];
    char countryEscaped[MAX_FIELD * 2];
    char mapNameEscaped[MAX_FIELD * 2];

    while (SQL_FetchRow(results))
    {
        int timeId = SQL_FetchInt(results, 0);
        SQL_FetchString(results, 1, steamId64, sizeof(steamId64));
        int mode = SQL_FetchInt(results, 2);
        int style = SQL_FetchInt(results, 3);
        int runTime = SQL_FetchInt(results, 4);
        int teleports = SQL_FetchInt(results, 5);
        SQL_FetchString(results, 6, alias, sizeof(alias));
        SQL_FetchString(results, 7, country, sizeof(country));
        SQL_FetchString(results, 8, mapName, sizeof(mapName));
        int course = SQL_FetchInt(results, 9);
        SQL_FetchString(results, 10, createdIso, sizeof(createdIso));

        JsonEscape(alias, aliasEscaped, sizeof(aliasEscaped));
        JsonEscape(country, countryEscaped, sizeof(countryEscaped));
        JsonEscape(mapName, mapNameEscaped, sizeof(mapNameEscaped));

        char item[2048];
        FormatEx(
            item,
            sizeof(item),
            "%s{\"clientRunId\":\"%d:%s\",\"steamId64\":\"%s\",\"alias\":\"%s\",\"country\":\"%s\",\"mapName\":\"%s\",\"course\":%d,\"mode\":%d,\"style\":%d,\"timeMs\":%d,\"teleports\":%d,\"tickrate\":128,\"playedAt\":\"%s\"}",
            first ? "" : ",",
            timeId,
            createdIso,
            steamId64,
            aliasEscaped,
            countryEscaped,
            mapNameEscaped,
            course,
            mode,
            style,
            runTime,
            teleports,
            createdIso
        );

        if (strlen(body) + strlen(item) + 4 >= sizeof(body))
        {
            break;
        }

        StrCat(body, sizeof(body), item);
        first = false;
        lastTimeId = timeId;
        count++;
    }

    StrCat(body, sizeof(body), "]}");

    if (count == 0)
    {
        g_Uploading = false;
        return;
    }

    if (g_CVDebug.BoolValue)
    {
        PrintToServer("[ThRei] uploading %d runs up to TimeID %d", count, lastTimeId);
    }

    SendUpload(body, lastTimeId);
}

void SendUpload(const char[] body, int lastTimeId)
{
    char baseUrl[256];
    char apiKey[128];
    char endpoint[512];

    g_CVApiUrl.GetString(baseUrl, sizeof(baseUrl));
    g_CVApiKey.GetString(apiKey, sizeof(apiKey));
    BuildEndpoint(baseUrl, endpoint, sizeof(endpoint));

    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, endpoint);
    if (request == INVALID_HANDLE)
    {
        LogError("[ThRei] Could not create HTTP request");
        g_Uploading = false;
        return;
    }

    SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/json");
    SteamWorks_SetHTTPRequestHeaderValue(request, "X-API-Key", apiKey);
    SteamWorks_SetHTTPRequestAbsoluteTimeoutMS(request, 30000);
    SteamWorks_SetHTTPRequestRawPostBody(request, "application/json", body, strlen(body));
    SteamWorks_SetHTTPCallbacks(request, OnUploadComplete);
    SteamWorks_SetHTTPRequestContextValue(request, lastTimeId);

    if (!SteamWorks_SendHTTPRequest(request))
    {
        LogError("[ThRei] Could not send HTTP request");
        delete request;
        g_Uploading = false;
        return;
    }
}

public void OnUploadComplete(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any data)
{
    int lastTimeId = data;
    int status = view_as<int>(statusCode);

    if (failure || !requestSuccessful || status < 200 || status >= 300)
    {
        LogError("[ThRei] Upload failed: status=%d failure=%d successful=%d", status, failure, requestSuccessful);
        g_Uploading = false;
        delete request;
        return;
    }

    g_Cursor = lastTimeId;
    SaveCursor();
    g_Uploading = false;

    if (g_CVDebug.BoolValue)
    {
        PrintToServer("[ThRei] upload ok, cursor=%d", g_Cursor);
    }

    delete request;
}

void BuildEndpoint(const char[] baseUrl, char[] output, int maxlen)
{
    strcopy(output, maxlen, baseUrl);

    int length = strlen(output);
    while (length > 0 && output[length - 1] == '/')
    {
        output[length - 1] = '\0';
        length--;
    }

    StrCat(output, maxlen, "/api/v1/ingest/runs");
}

void LoadCursor()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/threi-kz-cursor.txt");

    g_Cursor = g_CVBackfillFrom.IntValue;

    if (!FileExists(path))
    {
        return;
    }

    Handle file = OpenFile(path, "r");
    if (file == null)
    {
        return;
    }

    char line[64];
    if (ReadFileLine(file, line, sizeof(line)))
    {
        TrimString(line);
        g_Cursor = StringToInt(line);
    }

    delete file;
}

void SaveCursor()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/threi-kz-cursor.txt");

    Handle file = OpenFile(path, "w");
    if (file == null)
    {
        LogError("[ThRei] Could not write cursor file: %s", path);
        return;
    }

    WriteFileLine(file, "%d", g_Cursor);
    delete file;
}

void JsonEscape(const char[] input, char[] output, int maxlen)
{
    int j = 0;
    for (int i = 0; input[i] != '\0' && j < maxlen - 1; i++)
    {
        char c = input[i];
        if (c == '"' || c == '\\')
        {
            if (j + 2 >= maxlen)
            {
                break;
            }
            output[j++] = '\\';
            output[j++] = c;
        }
        else if (c == '\n')
        {
            if (j + 2 >= maxlen)
            {
                break;
            }
            output[j++] = '\\';
            output[j++] = 'n';
        }
        else if (c == '\r')
        {
            if (j + 2 >= maxlen)
            {
                break;
            }
            output[j++] = '\\';
            output[j++] = 'r';
        }
        else if (c == '\t')
        {
            if (j + 2 >= maxlen)
            {
                break;
            }
            output[j++] = '\\';
            output[j++] = 't';
        }
        else
        {
            int code = view_as<int>(c) & 0xFF;
            if (code >= 0x20)
            {
                output[j++] = c;
            }
        }
    }
    output[j] = '\0';
}
