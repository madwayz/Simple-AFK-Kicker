#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
  name = "[FORK] Anti-AFK",
  author = "Krabos & Shavit & madwayz",
  description = "",
  version = "3.2",
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
  HookEvent("player_spawn", OnRoundStart);
  
  cv_check = CreateConVar("sm_afk_check", "1", "Сколько проверок должно быть для распознавания afk игрока", _, true, 1.0);
  cv_mode = CreateConVar("sm_afk_mode", "2", "Что делать с afk игроком? 1 - перевод в спектора, 2 - кик", _, true, 1.0, true, 2.0);
  cv_timer = CreateConVar("sm_afk_timer", "20.0", "Через сколько после респавна проверить игрока на АФК?");
  cv_captchaTimer = CreateConVar("sm_afk_captacha_wait", "10", "Через сколько после респавна проверить игрока на АФК?");

}

public void OnClientPostAdminCheck(int lClient)
{
  bCheckCount[lClient] = 0;
}

public void OnRoundStart(Event eEvent, const char[] strName, bool bDontBroadcast)
{
	if(gT_RoundStart != null)
	CloseHandle(gT_RoundStart);
	gT_RoundStart = CreateTimer(cv_timer.FloatValue, Timer_AFKCheck);
	
	for(int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && IsValidMatch()) {
		GetClientAbsOrigin(i, fAFKPos[i]);
		}
	}
}

public Action Timer_AFKCheck(Handle timer)
{
  if (IsValidMatch())
    for(int i = 1; i <= MaxClients; i++)
      if (IsValidClient(i))
        checkIsAfk(i);

  gT_RoundStart = null;
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
      PrintHintText(p1, "AFK верификация успешно пройдена!\nВы не будете кикнуты.");
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
  KickClient(client, "Вы были кикнуты за AFK.");
}

stock bool IsValidMatch()
{  
  return (((GameRules_GetProp("m_bMatchWaitingForResume")) == 0) && ((GameRules_GetProp("m_bWarmupPeriod")) == 0));
}

stock bool IsValidClient(int client)
{
  return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && IsPlayerAlive(client));
}