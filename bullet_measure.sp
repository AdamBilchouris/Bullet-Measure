#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PREFIX "[\x05SM\x01]\x01"

//Global variables

//Blue laser model
int gi_beamModel;
//If the user has it on or not
bool gb_measureOn[MAXPLAYERS + 1];
//Points for the user
float gf_points[MAXPLAYERS + 1][2][3];

public Plugin myinfo =
{
	name = "Bullet Measure",
	author = "Ocelot",
	description = "Allows shots to measure distances",
	version = "1.0",
	url = "https://gokz.tv/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_bm", Command_BulletMeasure, "Toggles the bullet measure");
	HookEvent("bullet_impact", Event_BulletImpact);
}

public void OnMapStart()
{
	gi_beamModel = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
} 

public void OnClientDisconnect(int client)
{
	clearPoints(client);
	gb_measureOn[client] = false;
}

public Action Command_BulletMeasure(int client, int args)
{
	if(args != 0)
	{
		ReplyToCommand(client, "%s Usage: sm_bm", PREFIX);
		return Plugin_Handled;
	}
	
	else if(client != 0)
	{
		gb_measureOn[client] = !gb_measureOn[client];
		
		if(gb_measureOn[client] == true)
		{
			displayMenu(client);
			return Plugin_Handled;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public void displayMenu(int client)
{
	Menu menu = new Menu(Menu_Callback);
		
	menu.SetTitle("Bullet Measure");
	menu.AddItem("option1", "Get Actual Distance");
	menu.AddItem("option2", "Clear Points");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			
			if(StrEqual(item, "option1"))
			{	
				if(checkPointsForZero(param1) == true)
				{
					ReplyToCommand(param1, "%s You need to set points first...", PREFIX);
				}
				
				
				else if(checkSecondPoint(param1) == true)
				{
					ReplyToCommand(param1, "%s You have not set your second point yet...", PREFIX, getActualDistance(param1));
				}
				
				else
				{
					getBeam(param1);
					ReplyToCommand(param1, "%s Actual Distance \x09%.2f\x01", PREFIX, getActualDistance(param1));
				}
				
				displayMenu(param1);
			}
			
			else if(StrEqual(item, "option2"))
			{
				
				if(checkPointsForZero(param1) == true)
				{
					ReplyToCommand(param1, "%s You have no points to clear...", PREFIX);
				}
				
				else
				{
					ReplyToCommand(param1, "%s Both points cleared", PREFIX);
					clearPoints(param1);
				}
				
				displayMenu(param1);
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Event_BulletImpact(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));	//Player who shot the bullet
	
	if(gb_measureOn[client] == false)
	{
		return Plugin_Continue;
	}
	
	else
	{
		//get where the bullet hole is
		float position[3];
		
		position[0] = GetEventFloat(event, "x");
		position[1] = GetEventFloat(event, "y");
		position[2] = GetEventFloat(event, "z");
	
		if(gf_points[client][0][0] == 0.0 && gf_points[client][0][1] == 0.0 && gf_points[client][0][2] == 0.0)
		{
			setPoint(client, 0, position[0], position[1], position[2]);
			return Plugin_Continue;
		}
			
		else if(gf_points[client][1][0] == 0.0 && gf_points[client][1][1] == 0.0 && gf_points[client][1][2] == 0.0)
		{
			setPoint(client, 1, position[0], position[1], position[2]);
			return Plugin_Continue;
		}
			
		else
		{
			return Plugin_Continue;
		}
	}
}

//Clears the points
void clearPoints(int client)
{
	gf_points[client][0][0] = 0.0;
	gf_points[client][0][1] = 0.0;
	gf_points[client][0][2] = 0.0;
	
	gf_points[client][1][0] = 0.0;
	gf_points[client][1][1] = 0.0;
	gf_points[client][1][2] = 0.0;
}

bool checkPointsForZero(int client)
{
	if(gf_points[client][0][0] == 0.0 && gf_points[client][0][1] == 0.0 && gf_points[client][0][2] == 0.0 &&
	   gf_points[client][1][0] == 0.0 && gf_points[client][1][1] == 0.0 && gf_points[client][1][2] == 0.0)
	{
		return true;
	}
	
	else
	{
		return false;
	}
}

bool checkSecondPoint(int client)
{
	if(gf_points[client][0][0] != 0.0 && gf_points[client][0][1] != 0.0 && gf_points[client][0][2] != 0.0 &&
	   gf_points[client][1][0] == 0.0 && gf_points[client][1][1] == 0.0 && gf_points[client][1][2] == 0.0)
	{
		return true;
	}
	
	else
	{
		return false;
	}
}

//Sets the points
void setPoint(int client, int point, float x, float y, float z)
{
	gf_points[client][point][0] = x;
	gf_points[client][point][1] = y;
	gf_points[client][point][2] = z;
}

//Get the points
float getActualDistance(int client)
{
	float vec1[3];
	float vec2[3];
	
	for(int i = 0; i < 3; i++)
	{
		vec1[i] = gf_points[client][0][i];
	}
	
	for(int i = 0; i < 3; i++)
	{
		vec2[i] = gf_points[client][1][i];
	}
	
	return GetVectorDistance(vec1, vec2);
}

//Thanks DanZay
//https://bitbucket.org/kztimerglobalteam/gokz/src/master/addons/sourcemod/scripting/gokz-measure/measure_menu.sp
void getBeam(int client)
{
	float vec1[3];
	float vec2[3];
	
	for(int i = 0; i < 3; i++)
	{
		vec1[i] = gf_points[client][0][i];
	}
	
	for(int i = 0; i < 3; i++)
	{
		vec2[i] = gf_points[client][1][i];
	}
	
	measureBeam(client, vec1, vec2, 5.0, 2.0, 200, 200, 200);
}

//https://bitbucket.org/kztimerglobalteam/gokz/src/master/addons/sourcemod/scripting/gokz-measure/measure_menu.sp
void measureBeam(int client, float vecStart[3], float vecEnd[3], float life, float width, int r, int g, int b)
{
	TE_Start("BeamPoints");
	TE_WriteNum("m_nModelIndex", gi_beamModel);
	TE_WriteNum("m_nHaloIndex", 0);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", life);
	TE_WriteFloat("m_fWidth", width);
	TE_WriteFloat("m_fEndWidth", width);
	TE_WriteNum("m_nFadeLength", 0);
	TE_WriteFloat("m_fAmplitude", 0.0);
	TE_WriteNum("m_nSpeed", 0);
	TE_WriteNum("r", r);
	TE_WriteNum("g", g);
	TE_WriteNum("b", b);
	TE_WriteNum("a", 255);
	TE_WriteNum("m_nFlags", 0);
	TE_WriteVector("m_vecStartPoint", vecStart);
	TE_WriteVector("m_vecEndPoint", vecEnd);
	TE_SendToClient(client);
}