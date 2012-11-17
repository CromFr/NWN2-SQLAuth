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
		nAction = GetLocalInt(OBJECT_SELF, "nPassWordAction");
	
	
	int n;
	effect eEffect;
	int bTestPassword = TRUE;
	int bPasswordMatch;
	int nPasswordTests;
	switch(nAction)
	{
		case 1:
			FloatingTextStringOnCreature(PASSWORD_REGISTERED, OBJECT_SELF, FALSE, 10.0, 16711680, 16750848);
			SQLExecDirect("UPDATE `"+TABLE_ACCOUNT+"` SET "+TABLE_ACCOUNT_COLUMN_PASSWORD+"=SHA('"+sInput+"') WHERE "+TABLE_ACCOUNT_COLUMN_ACCOUNT+"='"+sAccount+"'");
			bTestPassword = FALSE;
			//=================
		case 2:
			if(bTestPassword)
			{
				SQLExecDirect("SELECT (`"+TABLE_ACCOUNT_COLUMN_PASSWORD+"`=SHA('"+sInput+"')) FROM `"+TABLE_ACCOUNT+"` WHERE "+TABLE_ACCOUNT_COLUMN_ACCOUNT+"='"+sAccount+"'");
				
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
						DisplayInputBox(OBJECT_SELF, 0, PASSWORD_INCORRECT_PLEASE_RETYPE, "gui_pw_auth", "gui_pw_auth", TRUE, "SCREEN_STRINGINPUT_MESSAGEBOX",0,"Valider",0,"Quitter","");
					}
					break;
				}
			}
			//The password is correct/has been set
			
			SQLExecDirect("INSERT INTO `authentification` (account_name,ip,cdkey) VALUES ('"+sAccount+"','"+GetPCIPAddress(OBJECT_SELF)+"','"+GetPCPublicCDKey(OBJECT_SELF)+"')");
			
		
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