//Written by Crom
//08/04/2012
//crom29@hotmail.fr

// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//              G E N E R A L         I N F O R M A T I O N
// /////////////////////////////////////////////////////////////////////
//
// This script adds a second authentication to your server to prevent people
//	to use somebody else account by skipping bioware authentication.
//
// The script register into MySQL the password of the account (this password
//	is NOT encrypted) and combinations of IP+CDKey that the player uses
//
// It will ask the player to :
//	- Set his password if the password is not registered
//	- Retype his password if his IP of CDKey has not been registered yet
//	- Nothing if the password has been set and the IP/CDKey is registered
//
//
// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//                     R E Q U I R E M E N T S
// /////////////////////////////////////////////////////////////////////
//
// - NWNX4 with the xp_mysql plugin
// - It is **strongly** recommended to use Skywing xp_bugfix NWNX4 plugin, in
//   order to encrypt traffic between the client and server, preventing the
//   password to be sent in plain text.
// - A MariaDB or MySQL server
// - The nwnx_sql include script (bundled with NWNX4)
// - You must modify your OnPCLoad script by adding these two lines:
//		At the top of the file:
//			#include "pw_auth_inc"
//		After void main(){
//			PWAuthOnPCLoad();
//
//
//	The lines below can be configured:


// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//                         S E T T I N G S
// /////////////////////////////////////////////////////////////////////
//Number of times the player will be able to type a wrong password before being kicked
const int PASSWORD_TRY_LIMIT = 3;



// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//                     I N P U T        B O X
// /////////////////////////////////////////////////////////////////////
//Message written when the player has to set his password
const string PW_AUTH_GUI_INPUTBOX_ENTER_NEW_PASSWORD = "Chose a password to protect your account on this server";

//Message written when the player has type his registered password
const string PW_AUTH_GUI_INPUTBOX_ENTER_CURRENT_PASSWORD = "Enter your password for this server";

//Text to display on the validate button
const string PW_AUTH_GUI_INPUTBOX_VALIDATE = "Continue";

//Text to display on the validate button
const string PW_AUTH_GUI_INPUTBOX_QUIT = "Exit";




// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//                 F L O A T I N G         T E X T
// /////////////////////////////////////////////////////////////////////
//Text displayed when asking the player to type his password
const string PW_AUTH_ASK_PASSWORD = "Please chose a password for protecting your account on this server";

//text displayed when the player has successfully registered his password
const string PW_AUTH_PASSWORD_REGISTERED = "Your password has been saved !";

//Text displayed when the player has written a wrong password
const string PW_AUTH_PASSWORD_INCORRECT_PLEASE_RETYPE = "Wrong password !\nPlease try again";

//Text displayed when the player's account case is wrong
const string PW_AUTH_INCORRECT_CASE = "Wrong account case ! Please reconnect with the account: ";

//Text displayed when asking the player to type his password
const string PW_AUTH_WELCOME = "Welcome to the server !";


























// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//					DO NOT TOUCH THESE LINES
// /////////////////////////////////////////////////////////////////////
#include "nwnx_sql"
void PWAuthOnPCLoad()
{
	if(GetLocalInt(GetModule(), "pw_auth_init") == FALSE){
		SQLExecDirect("CREATE TABLE IF NOT EXISTS `pw_auth_accounts` (`name` varchar(45) NOT NULL, `hash` varchar(256) default NULL, `salt` varchar(32) default NULL,  PRIMARY KEY (`name`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;");
		SQLExecDirect("CREATE TABLE IF NOT EXISTS `pw_auth_registry` (`name` varchar(45) NOT NULL, `ip` varchar(15) NOT NULL, `cdkey` varchar(45) NOT NULL, `approved` tinyint(1) default '1', PRIMARY KEY  (`name`,`ip`,`cdkey`)) ENGINE=InnoDB DEFAULT CHARSET=utf8");
	}

	object oPC = GetEnteringObject();
	string sAccount = SQLEncodeSpecialChars(GetPCPlayerName(oPC));

	SQLExecDirect("SELECT `hash`,(BINARY `name`='"+sAccount+"'),`name` FROM `pw_auth_accounts` WHERE LOWER(`name`) = LOWER('"+sAccount+"')");

	string sPassword = "";
	if(SQLFetch())
		sPassword = SQLGetData(1);
	else
		SQLExecDirect("INSERT INTO `pw_auth_accounts` (`name`) VALUES ('"+sAccount+"')");

	if(sPassword == "")//No password registered for this account
	{
		ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneParalyze(), oPC);

		SetLocalInt(oPC, "nPasswordAction", 1);// 1 means "Register password + IP & CDKey"
		DelayCommand(2.0, FloatingTextStringOnCreature(PW_AUTH_ASK_PASSWORD, oPC, FALSE, 15.0, 16711680, 16750848));
		DisplayInputBox(oPC, 0, PW_AUTH_GUI_INPUTBOX_ENTER_NEW_PASSWORD, "gui_pw_auth", "gui_pw_auth", TRUE, "SCREEN_STRINGINPUT_MESSAGEBOX",0,PW_AUTH_GUI_INPUTBOX_VALIDATE,0,PW_AUTH_GUI_INPUTBOX_QUIT,"");
	}
	else
	{
		if(SQLGetData(2) == "0")//Account case mismatch
		{
			ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneParalyze(), oPC);
			SetLocalInt(OBJECT_SELF, "nPasswordAction", -1);//Boot PC
			DisplayMessageBox(oPC, 0, PW_AUTH_INCORRECT_CASE+"'"+SQLGetData(3)+"'", "gui_pw_auth", "", FALSE, "SCREEN_MESSAGEBOX_DEFAULT", 0, PW_AUTH_GUI_INPUTBOX_QUIT);
			return;
		}

		//Check if the CDKey & IP are registered
		SQLExecDirect("SELECT approved FROM `pw_auth_registry` WHERE name='"+sAccount+"' AND ip='"+GetPCIPAddress(oPC)+"' AND cdkey='"+GetPCPublicCDKey(oPC)+"'");

		if(SQLFetch() && StringToInt(SQLGetData(1)))
		{
			//IP & CDKey correctly registered
		}
		else
		{
			//Ask password to register the new IP/CDKey
			ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneParalyze(), oPC);

			SetLocalInt(oPC, "nPasswordAction", 2);//2 means "Register IP & CDKey"
			DisplayInputBox(oPC, 0, PW_AUTH_GUI_INPUTBOX_ENTER_CURRENT_PASSWORD, "gui_pw_auth", "gui_pw_auth", TRUE, "SCREEN_STRINGINPUT_MESSAGEBOX",0,PW_AUTH_GUI_INPUTBOX_VALIDATE,0,PW_AUTH_GUI_INPUTBOX_QUIT,"");
		}
	}
}
