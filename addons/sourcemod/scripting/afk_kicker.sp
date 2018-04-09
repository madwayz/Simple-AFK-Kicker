#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[FORK] Anti-AFK",
	author = "Krabos & Shavit & madwayz",
	description = "",
	version = "3.1",
	url = "vk.com/madwayz1337"
};

/*---PLAYER VARS---*/
int bCheckCount[MAXPLAYERS + 1];
float fAFKPos[MAXPLAYERS + 1][3];
/*-----------------*/
ConVar cv_check = null;
ConVar cv_mode = null;
ConVar cv_timer = null;
ConVar cv_captchaTimer = null;

Handle gT_RoundStart = null;

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerRespawn);
	//HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	//HookEvent("round_end", OnRoundEnd);
	
	cv_check = CreateConVar("sm_afk_check", "1", "Сколько проверок должно быть для распознавания afk игрока", _, true, 1.0);
	cv_mode = CreateConVar("sm_afk_mode", "2", "Что делать с afk игроком? 1 - перевод в спектора, 2 - кик", _, true, 1.0, true, 2.0);
	cv_timer = CreateConVar("sm_afk_timer", "10.0", "Через сколько после респавна проверить игрока на АФК?");
	cv_captchaTimer = CreateConVar("sm_afk_captacha_wait", "10", "Через сколько после респавна проверить игрока на АФК?");

}

public void OnClientPostAdminCheck(int lClient)
{
	bCheckCount[lClient] = 0;
}

public void OnPlayerRespawn(Event eEvent, const char[] strName, bool bDontBroadcast)
{
	if(gT_RoundStart != null)
	{
		delete gT_RoundStart;
	}
	
	gT_RoundStart = CreateTimer(cv_timer.FloatValue, Timer_AFKCheck);
	
	int iRespawn = GetClientOfUserId(eEvent.GetInt("userid"));
	if (IsValidClient(iRespawn) && IsPlayerAlive(iRespawn) && IsValidMatch() && GetClientTeam(iRespawn) > 1) RequestFrame(setPos, iRespawn);
}

public void setPos(int iWhoSpawn)
{
	if (IsValidClient(iWhoSpawn) && IsValidMatch()) GetClientAbsOrigin(iWhoSpawn, fAFKPos[iWhoSpawn]);
}

/*public Action OnPlayerDeath(Event eEvent, const char[] strName, bool bDontBroadcast)
{
	checkIsAfk(GetClientOfUserId(eEvent.GetInt("userid")));
}*/

public Action Timer_AFKCheck(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidMatch()) checkIsAfk(i);
	}
	
	gT_RoundStart = null;
	return Plugin_Stop;
}

void checkIsAfk(int client)
{
	float fCheckPos[3];
	GetClientAbsOrigin(client, fCheckPos);
	
	if (fAFKPos[client][0] == fCheckPos[0] && fAFKPos[client][1] == fCheckPos[1])
	{
		if (++bCheckCount[client] >= cv_check.IntValue)
		{
			if (cv_mode.IntValue == 1) ChangeClientTeam(client, 1);
			else PopupAFKMenu(client, cv_captchaTimer.IntValue);
		}
		else return;
	}
	
	bCheckCount[client] = 0;
}

/*public void OnRoundEnd(Event event, const char[] strName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) > 1) checkIsAfk(i);
	}
}*/

void PopupAFKMenu(int client, int time)
{
	Menu m = new Menu(MenuHandler_AFKVerification);

	m.SetTitle("Может быть Вас кикнуть?");
	m.AddItem("stay", "Нет! Не кикайте меня, я здесь!");
	m.ExitButton = false;
	m.Display(client, time);
}

public int MenuHandler_AFKVerification(Menu m, MenuAction a, int p1, int p2)
{
	switch(a)
	{
		case MenuAction_Select:
		{
			char buffer[8];
			m.GetItem(p2, buffer, 8);

			if(StrEqual(buffer, "stay")) PrintHintText(p1, "AFK верификация успешно пройдена!\nВы не будете кикнуты.");
			else NukeClient(p1);

		}

		case MenuAction_Cancel:
		{
			// no response
			if(p2 == MenuCancel_Timeout) NukeClient(p1);
		}

		case MenuAction_End: delete m;
	}

	return 0;
}

public void NukeClient(int client)
{
	if(IsValidClient(client)) KickClient(client, "Вы были кикнуты за AFK.");
}

stock bool IsValidMatch()
{  
    return (((GameRules_GetProp("m_bMatchWaitingForResume")) == 0) && ((GameRules_GetProp("m_bWarmupPeriod")) == 0));
}

stock bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client));
}