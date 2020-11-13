//Written by Crom
//08/04/2012
//crom29@hotmail.fr

#include "nwnx_sql"
#include "pw_auth_inc"


void main(string sInput)
{

	int nAction;
	string sAccount = SQLEncodeSpecialChars(GetPCPlayerName(OBJECT_SELF));

	//Clean sInput
	while(GetStringLeft(sInput, 1) == " ")
		sInput = GetStringRight(sInput, GetStringLength(sInput)-1);

	while(GetStringRight(sInput, 1) == " ")
		sInput = GetStringLeft(sInput, GetStringLength(sInput)-1);


	if (sInput == "")
		nAction = 0;
	else
		nAction = GetLocalInt(OBJECT_SELF, "nPasswordAction");


	int n;
	int bMessage = FALSE;
	effect eEffect;
	int bTestPassword = TRUE;
	int bPasswordMatch;
	int nPasswordTests;
	switch(nAction)
	{
		case 1:
			FloatingTextStringOnCreature(PW_AUTH_PASSWORD_REGISTERED, OBJECT_SELF, FALSE, 10.0, 16711680, 16750848);
			bMessage = TRUE;
			SQLExecDirect("UPDATE `pw_auth_accounts` SET `salt`=SUBSTRING(MD5(RAND()), -32), `hash`=SHA2(CONCAT('"+sInput+"',`salt`), 256) WHERE name='"+sAccount+"'");
			bTestPassword = FALSE;
			//fallthrough
		case 2:
			if(bTestPassword)
			{
				SQLExecDirect("SELECT SHA2(CONCAT('"+sInput+"',`salt`), 256)=`hash` FROM `pw_auth_accounts` WHERE name='"+sAccount+"'");

				SQLFetch();
				bPasswordMatch = StringToInt(SQLGetData(1));

				if(!bPasswordMatch)
				{
					//Incorrect Password
					nPasswordTests = GetGlobalInt("PWD_TESTS_"+sAccount);
					nPasswordTests++;

					if(nPasswordTests >= PASSWORD_TRY_LIMIT)
					{
						SetGlobalInt("PWD_TESTS_"+sAccount, 0);
						BootPC(OBJECT_SELF);
						break;
					}
					else
					{
						SetGlobalInt("PWD_TESTS_"+sAccount, nPasswordTests);
						DisplayInputBox(OBJECT_SELF, 0, PW_AUTH_PASSWORD_INCORRECT_PLEASE_RETYPE, "gui_pw_auth", "gui_pw_auth", TRUE, "SCREEN_STRINGINPUT_MESSAGEBOX",0,PW_AUTH_GUI_INPUTBOX_VALIDATE,0,PW_AUTH_GUI_INPUTBOX_QUIT,"");
					}
					break;
				}
			}
			//The password is correct/has been set

			SQLExecDirect("INSERT INTO `pw_auth_registry` (name,ip,cdkey) VALUES ('"+sAccount+"','"+GetPCIPAddress(OBJECT_SELF)+"','"+GetPCPublicCDKey(OBJECT_SELF)+"')");
			if(!bMessage)
				FloatingTextStringOnCreature(PW_AUTH_WELCOME, OBJECT_SELF, FALSE, 10.0, 16711680, 16750848);


			eEffect = GetFirstEffect(OBJECT_SELF);
			while(GetIsEffectValid(eEffect))
			{
				if(GetEffectType(eEffect) == EFFECT_TYPE_CUTSCENE_PARALYZE)
				{
					RemoveEffect(OBJECT_SELF, eEffect);
				}
				eEffect = GetNextEffect(OBJECT_SELF);
			}
			break;
			//=================
		default:
			BootPC(OBJECT_SELF);
			break;
	}
}