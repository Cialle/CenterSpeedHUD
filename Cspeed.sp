#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <convar_class>

#define CP_DISPLAY 1    //是否显示
#define CP_DYNAMIC 1    //是否动态

#define CP_POS_H 40    //位置设置％ 例40=0.4

#define CP_STATIC_R 255    //静态颜色R
#define CP_STATIC_G 255    //静态颜色G
#define CP_STATIC_B 255    //静态颜色B

#define CP_DYN_INC_R 255    //动态加速颜色R     Dynamic increase 
#define CP_DYN_INC_G 255    //动态加速颜色G
#define CP_DYN_INC_B 255    //动态加速颜色B
#define CP_DYN_DEC_R 255    //动态减速颜色R     Dynamic decrease
#define CP_DYN_DEC_G 255    //动态减速颜色G
#define CP_DYN_DEC_B 255    //动态减速颜色B



public Plugin myinfo =
{
	name = "CSpeedHud",
	author = "妄为",
	description = "HUD for shavit's bhop timer.",
	version = SHAVIT_VERSION,
	url = "https://github.com/shavitush/bhoptimer"
}