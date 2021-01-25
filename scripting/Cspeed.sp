#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <convar_class>

#define CP_DISPLAY "0"    //是否显示			
#define CP_DYNAMIC "1"    //是否动态

#define CP_POS_V "36"    //垂直位置设置％ 例40=0.4 		 Vertically position 

#define CP_STATIC_R "255"    //静态颜色R				Static Color
#define CP_STATIC_G "255"    //静态颜色G
#define CP_STATIC_B "255"    //静态颜色B

#define CP_DYN_INC_R "0"    //动态加速颜色R    		 Dynamic increase Color
#define CP_DYN_INC_G "180"    //动态加速颜色G
#define CP_DYN_INC_B "255"    //动态加速颜色B

#define CP_DYN_DEC_R "255"    //动态减速颜色R     	 Dynamic decrease Color
#define CP_DYN_DEC_G "90"    //动态减速颜色G
#define CP_DYN_DEC_B "0"    //动态减速颜色B

#define MAX_SETTINGS 37   	  //设置最大字符尺寸
#define MAX_MENU 64			  //设置最大Menu尺寸

// plugin cvars
Convar gCV_Display = null;
Convar gCV_Dynamic = null;
Convar gCV_Vertically = null;
Convar gCV_Static_r = null;
Convar gCV_Static_g = null;
Convar gCV_Static_b = null;
Convar gCV_Increase_r = null;
Convar gCV_Increase_g = null;
Convar gCV_Increase_b = null;
Convar gCV_Decrease_r = null;
Convar gCV_Decrease_g = null;
Convar gCV_Decrease_b = null;

// Handles
Handle gH_CSCookie = null;
Handle gH_CSpeedhud = null;


/* 
{
	{[0][0] Display,		[0][1]Dynamic, 			[0][2]Vertically}    
	{[1][0] Static_r,		[1][1]Static_g, 		[1][2] Static_b}	 
	{[2][0] Increase_r,		[2][1]Increase_g,		[2][2] Increase_b}	  
	{[3][0] Decrease_r,		[3][1]Decrease_g,		[3][2] Decrease_b}	  
}
用户游戏内centerspeed设置*/
int gI_CSSettings[MAXPLAYERS+1][4][3];
// 上一次的速度
int gI_PreviousSpeed[MAXPLAYERS+1];
// menu参数传递
char gS_MenuTargetInfo[MAXPLAYERS+1][MAX_MENU];
char gS_MenuTargetTitel[MAXPLAYERS+1][MAX_MENU];


/***********************************
全局说明：
char sTemp[] 普遍为临时变量，啥都往里装。
***********************************/
public Plugin myinfo =
{
	name = "CSpeedHud",
	author = "妄为",
	description = "HUDtext for surf or?",
	version = "1",
	url = "https://github.com/Cialle/CenterSpeedHUD"
}

public void OnPluginStart()
{
	LoadTranslations("CenterSpeed.phrases");

	// HUD handle
	gH_CSpeedhud = CreateHudSynchronizer();

	// plugin convars
	gCV_Display = new Convar("cspeed_Display", CP_DISPLAY, "[Cspeed]修改默认：on/off 显示设置", 0, true, 0.0, true, 1.0);
	gCV_Dynamic = new Convar("cspeed_Dynamic", CP_DYNAMIC, "[Cspeed]修改默认：on/off 速度动态显示设置", 0, true, 0.0, true, 1.0);
	gCV_Vertically = new Convar("cspeed_Vertically", CP_POS_V, "[Cspeed]修改默认：0-100 显示高度设置", 0, true, 0.0, true, 100.0);

	gCV_Static_r = new Convar("cspeed_color_Static_R", CP_STATIC_R, "[Cspeed]修改默认：0-255 静态颜色：R通道", 0, true, 0.0, true, 255.0);
	gCV_Static_g = new Convar("cspeed_color_Static_G", CP_STATIC_G, "[Cspeed]修改默认：0-255 静态颜色：G通道", 0, true, 0.0, true, 255.0);
	gCV_Static_b = new Convar("cspeed_color_Static_B", CP_STATIC_B, "[Cspeed]修改默认：0-255 静态颜色：B通道", 0, true, 0.0, true, 255.0);

	gCV_Increase_r = new Convar("cspeed_color_Increase_R", CP_DYN_INC_R, "[Cspeed]修改默认：0-255 动态加速颜色：R通道", 0, true, 0.0, true, 255.0);
	gCV_Increase_g = new Convar("cspeed_color_Increase_G", CP_DYN_INC_G, "[Cspeed]修改默认：0-255 动态加速颜色：G通道", 0, true, 0.0, true, 255.0);
	gCV_Increase_b = new Convar("cspeed_color_Increase_B", CP_DYN_INC_B, "[Cspeed]修改默认：0-255 动态加速颜色：B通道", 0, true, 0.0, true, 255.0);

	gCV_Decrease_r = new Convar("cspeed_color_Decrease_R", CP_DYN_DEC_R, "[Cspeed]修改默认：0-255 动态减速颜色：R通道", 0, true, 0.0, true, 255.0);
	gCV_Decrease_g = new Convar("cspeed_color_Decrease_G", CP_DYN_DEC_G, "[Cspeed]修改默认：0-255 动态减速颜色：G通道", 0, true, 0.0, true, 255.0);
	gCV_Decrease_b = new Convar("cspeed_color_Decrease_B", CP_DYN_DEC_B, "[Cspeed]修改默认：0-255 动态减速颜色：B通道", 0, true, 0.0, true, 255.0);

	
	Convar.AutoExecConfig();

	// commands
	RegConsoleCmd("sm_cspeed", Command_CSpeed, "debug1");

	// cookies
	gH_CSCookie = RegClientCookie("CenterSpeedSetting", "settings", CookieAccess_Protected);
}

public void OnClientCookiesCached(int client)
{/* 初始化cookie */
	char sCSSettings[MAX_SETTINGS];
	GetClientCookie(client, gH_CSCookie, sCSSettings, MAX_SETTINGS);

	if(strlen(sCSSettings) == 0)
	{
		GetDefCSsetting(sCSSettings);
		SetClientCookie(client, gH_CSCookie, sCSSettings);
		CookiestringToInt(client, gI_CSSettings[client]);
	}
	else
	{
		CookiestringToInt(client, gI_CSSettings[client]);
	}

}

void GetDefCSsetting(char buffer[MAX_SETTINGS])
{/* 获取默认cookie设置 */
	int iCSDisplay = gCV_Display.IntValue;
	int iCSDynamic = gCV_Dynamic.IntValue;
	int iCSVertically = gCV_Vertically.IntValue;

	int iCSStatic_r = gCV_Static_r.IntValue;
	int iCSStatic_g = gCV_Static_g.IntValue;
	int iCSStatic_b = gCV_Static_b.IntValue;

	int iCSIncrease_r = gCV_Increase_r.IntValue;
	int iCSIncrease_g = gCV_Increase_g.IntValue;
	int iCSIncrease_b = gCV_Increase_b.IntValue;

	int iCSDecrease_r = gCV_Decrease_r.IntValue;
	int iCSDecrease_g = gCV_Decrease_g.IntValue;
	int iCSDecrease_b = gCV_Decrease_b.IntValue;

	FormatEx(buffer, MAX_SETTINGS, "%03d%03d%03d%03d%03d%03d%03d%03d%03d%03d%03d%03d", 
						iCSDisplay,
						iCSDynamic,
						iCSVertically,
						iCSStatic_r,
						iCSStatic_g,
						iCSStatic_b,
						iCSIncrease_r,
						iCSIncrease_g,
						iCSIncrease_b,
						iCSDecrease_r,
						iCSDecrease_g,
						iCSDecrease_b);

}

void CookiestringToInt(int client, int buffer[4][3])
{/* 从cookie中获取Int型二维数组[4][3] */
	char sCSSettings[MAX_SETTINGS];
	GetClientCookie(client, gH_CSCookie, sCSSettings, MAX_SETTINGS);
	for(int i=0; i<4; i++)
	{
		for(int j=0; j<3; j++)
		{
			char sTemp[5];
			FormatEx(sTemp, 5, "%c%c%c", sCSSettings[(i*9 + j*3)], sCSSettings[(i*9 + j*3)+1], sCSSettings[(i*9 + j*3)+2]);
			buffer[i][j] = StringToInt(sTemp);
		}
	}
}

void IntToCookiestring(int client, int buffer[4][3])
{/* 将Int型二维数组[4][3] 保存到cookie*/
	char sCSSettings[MAX_SETTINGS];
	for (int i=0; i < 4 ; i++)
	{
		for (int j=0; j < 3 ; j++)
		{
			FormatEx(sCSSettings, MAX_SETTINGS, "%s%03d", sCSSettings, buffer[i][j]);	
		}
	}
	SetClientCookie(client, gH_CSCookie, sCSSettings);
}



public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i) || gI_CSSettings[i][0][0] == 0)
		{
			continue;
		}

		UpdateCSpeedHUD(i);
	}
}

stock bool IsValidClient(int client, bool bAlive = false)
{//监测Client是否有效
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

void UpdateCSpeedHUD(int client)
{//显示centerspeed
	/* 				gI_CSSettings[client]

		[0][0] Display,			[0][1]Dynamic, 			[0][2]Vertically
		[1][0] Static_r,		[1][1]Static_g, 		[1][2] Static_b
		[2][0] Increase_r,		[2][1]Increase_g,		[2][2] Increase_b
		[3][0] Decrease_r,		[3][1]Decrease_g,		[3][2] Decrease_b
	*/
	//观察目标
	int target = GetHUDTarget(client);
	//高度
	float fVertically = gI_CSSettings[client][0][2] * 0.01;
	//浮点3D速度
	float fSpeed[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", fSpeed);
	//整数2D速度
	int iSpeed = RoundToNearest(SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0)));
	//判断类型取索引
	int iIndex;

	if(gI_CSSettings[client][0][1] == 0)
	{
		iIndex = 1;
	}	
	else 
	{
		if(gI_PreviousSpeed[client] <= iSpeed)
			{
				iIndex = 2;
			}
		else
			{
				iIndex = 3;
			}

		gI_PreviousSpeed[client] = iSpeed;
	}
	
	SetHudTextParams(-1.0, fVertically, 1.0, gI_CSSettings[client][iIndex][0], gI_CSSettings[client][iIndex][1], gI_CSSettings[client][iIndex][2], 255, 0, 0.25, 0.0, 0.0);
	ShowSyncHudText(client, gH_CSpeedhud, "%d", iSpeed);
}

int GetHUDTarget(int client)
{//返回client观察的目标，如果不在观察则返回client自身
	int target = client;

	if(IsClientObserver(client))
	{
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

		if(iObserverMode >= 3 && iObserverMode <= 5)
		{
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

			if(IsValidClient(iTarget, true))
			{
				target = iTarget;
			}
		}
	}

	return target;
}

public Action Command_CSpeed(int client, int args)
{
	return ShowMenu_CenterSpeed(client, 0);
}

bool AddItemFormat(Menu& menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any ...)
{//添加一个菜单Item
	char display[128];
	VFormat(display, sizeof(display), format, 5);

	return menu.AddItem(info, display, style);
}

Action ShowMenu_CenterSpeed(int client, int item)
{//CSpeed主菜单
	Menu menu = new Menu(MenuHandler_CenterSpeed, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
	menu.SetTitle("%T", "Menu_Title", client);

	AddItemFormat(menu, "00_Display", _, "%T", "Menu_DisplaySpeed", client);
	AddItemFormat(menu, "01_Dynamic", _, "%T", "Menu_Dynamic", client);
	AddItemFormat(menu, "02_Vertically", _, "%T", "Menu_MoveV", client);
	if(gI_CSSettings[client][0][1] == 0)
	{
		AddItemFormat(menu, "10_Static_r", _, "%T", "Menu_Static_r", client);
		AddItemFormat(menu, "11_Static_g", _, "%T", "Menu_Static_g", client);
		AddItemFormat(menu, "12_Static_b", _, "%T", "Menu_Static_b", client);
	}
	else
	{
		AddItemFormat(menu, "20_Increase_r", _, "%T", "Menu_ChangeIncrease_r", client);
		AddItemFormat(menu, "21_Increase_g", _, "%T", "Menu_ChangeIncrease_g", client);
		AddItemFormat(menu, "22_Increase_b", _, "%T", "Menu_ChangeIncrease_b", client);
		AddItemFormat(menu, "30_Decrease_r", _, "%T", "Menu_ChangeDecrease_r", client);
		AddItemFormat(menu, "31_Decrease_g", _, "%T", "Menu_ChangeDecrease_g", client);
		AddItemFormat(menu, "32_Decrease_b", _, "%T", "Menu_ChangeDecrease_b", client);
	}
	AddItemFormat(menu, "Default", _, "%T", "Menu_Default", client);

	menu.ExitButton = true;
	if (item < 6)
		item = 0;
	else if (item < 12)
		item = 6;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MenuHandler_CenterSpeed(Menu menu, MenuAction action, int param1, int param2)
{//CSpeed主菜单Handler
	if(action == MenuAction_Select)
	{
		char sInfo[16];
		char sDisplay[MAX_MENU];
		int style = 0;
		menu.GetItem(param2, sInfo, 16, style, sDisplay, MAX_MENU);

		if(StrEqual(sInfo, "00_Display"))
		{
			gI_CSSettings[param1][0][0] = (gI_CSSettings[param1][0][0] + 1) % 2;
			IntToCookiestring(param1, gI_CSSettings[param1]);
		}
		else if (StrEqual(sInfo, "01_Dynamic"))
		{
			gI_CSSettings[param1][0][1] = (gI_CSSettings[param1][0][1] + 1) % 2;
			IntToCookiestring(param1, gI_CSSettings[param1]);
		}
		else if (StrEqual(sInfo, "Default"))
		{
			char sCookie[MAX_SETTINGS];
			GetDefCSsetting(sCookie);
			SetClientCookie(param1, gH_CSCookie, sCookie);
			CookiestringToInt(param1, gI_CSSettings[param1]);
		}
		else
		{
			FormatEx(gS_MenuTargetInfo[param1], MAX_MENU, "%s", sInfo);
			FormatEx(gS_MenuTargetTitel[param1], MAX_MENU, "%s", sDisplay);
			ShowMenu_ChangeVar(param1, 0);
			return 0;
		}
		ShowMenu_CenterSpeed(param1, GetMenuSelectionPosition());
			
	}

	else if(action == MenuAction_DisplayItem)
	{
		char sInfo[16];
		char sDisplay[MAX_MENU];
		int style = 0;
		menu.GetItem(param2, sInfo, 16, style, sDisplay, MAX_MENU);

		//渲染空行,需要在MenuHandler内修改Display后RedrawMenuItem,否则会影响全局变量gS_MenuTargetTitel！
		if(StrEqual(sInfo, "01_Dynamic") || StrEqual(sInfo, "02_Vertically") || StrEqual(sInfo, "32_Decrease_b"))
		{
			Format(sDisplay, MAX_MENU, "%s\n \n", sDisplay);
		}

		if(StrEqual(sInfo, "00_Display"))
		{
			Format(sDisplay, MAX_MENU, "[%s]%s", (gI_CSSettings[param1][0][0] == 0) ? "OFF": "ON", sDisplay);
		}
		else if (StrEqual(sInfo, "01_Dynamic"))
		{
			Format(sDisplay, MAX_MENU, "[%s]%s", (gI_CSSettings[param1][0][1] == 0) ? "OFF": "ON", sDisplay);
		}
		else if (StrEqual(sInfo, "Default"))
		{
			//
		}
		else
		{
			char sTemp[3];
			FormatEx(sTemp, 3, "%c", sInfo[0]);
			int Index1 = StringToInt(sTemp); // 取第一个位作为数组下标1
			FormatEx(sTemp, 3, "%c", sInfo[1]);
			int Index2 = StringToInt(sTemp); // 取第一个位作为数组下标2
			Format(sDisplay, MAX_MENU, "[%03d]%s", gI_CSSettings[param1][Index1][Index2], sDisplay);
			
		}

		return RedrawMenuItem(sDisplay);
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

Action ShowMenu_ChangeVar(int client, int item)
{//CSpeed数值调整菜单
	//全局变量标识符中的info
	char sTemp[3];
	FormatEx(sTemp, 3, "%c", gS_MenuTargetInfo[client][0]);
	int Index1 = StringToInt(sTemp); // 取第一个位作为数组下标1
	FormatEx(sTemp, 3, "%c", gS_MenuTargetInfo[client][1]);
	int Index2 = StringToInt(sTemp); // 取第一个位作为数组下标2
	Menu menu = new Menu(MenuHandler_ChangeVar, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T \n%s <%03d>", "Menu_ChangeVar_Titel", client , gS_MenuTargetTitel[client], gI_CSSettings[client][Index1][Index2]);

	AddItemFormat(menu, "+1" , _, "＋1");
	AddItemFormat(menu, "+10", _, "＋10");
	AddItemFormat(menu, "+50", _, "＋50\n \n");
	AddItemFormat(menu, "-1" , _, "－1");
	AddItemFormat(menu, "-10", _, "－10");
	AddItemFormat(menu, "-50", _, "－50");

	menu.ExitButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler_ChangeVar(Menu menu, MenuAction action, int param1, int param2)
{//CSpeed数值调整菜单Handler
	if(action == MenuAction_Select)
	{
		//全局变量标识符中的info
		char sTemp[3];
		FormatEx(sTemp, 3, "%c", gS_MenuTargetInfo[param1][0]);
		int Index1 = StringToInt(sTemp); // 取第一个位作为数组下标1
		FormatEx(sTemp, 3, "%c", gS_MenuTargetInfo[param1][1]);
		int Index2 = StringToInt(sTemp); // 取第一个位作为数组下标2
		int maxvar = (StrEqual(gS_MenuTargetInfo[param1], "02_Vertically")) ? 100:255;

		//menu param2 号位 标识符中的info
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		int type = (sInfo[0] == '+')? 1:2;
		ReplaceString(sInfo, 16, "+", "");
		ReplaceString(sInfo, 16, "-", "");
		int ivar = StringToInt(sInfo);

		if(type == 1)
			gI_CSSettings[param1][Index1][Index2] = (maxvar + 1 + gI_CSSettings[param1][Index1][Index2] + ivar) % (maxvar + 1);
		else
			gI_CSSettings[param1][Index1][Index2] = (maxvar + 1 + gI_CSSettings[param1][Index1][Index2] - ivar) % (maxvar + 1);
		IntToCookiestring(param1, gI_CSSettings[param1]);

		ShowMenu_ChangeVar(param1, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		ShowMenu_CenterSpeed(param1, 0);
	}	
	else if(action == MenuAction_End)
	{
		delete menu;
	}
		
	return 0;
}
