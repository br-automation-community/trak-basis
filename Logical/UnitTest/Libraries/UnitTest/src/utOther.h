
#ifndef	__UT_OTHER_H__
#define	__UT_OTHER_H__



typedef enum utProfEnum
{
    utProf_Ev_Start = 0 /*profUSER_EVENT_START*/ ,
    utProf_Ev_Stop = 1 /*profUSER_EVENT_STOP*/,
    utProf_Ev_MsgFail = 2,
    utProf_Ev_MsgInfo,
    utProf_Ev_MsgPass,
    utProf_Ev_MsgAbort,
    utProf_Ev_Abort,
	utProf_Ev_Skipped,
	
    utProf_Ev_SetSetup_Start = 20,
    utProf_Ev_SetSetup_End,
    utProf_Ev_SetTearDown_Start,
    utProf_Ev_SetTearDown_End,
    utProf_Ev_SetCylic_Start,
    utProf_Ev_SetCylic_End,
    utProf_Ev_Suite_Start,
    utProf_Ev_Suite_End,
    utProf_Ev_Name_Set_Start,
    utProf_Ev_Name_Set_End,
    /* Testcase, TestSetup , TestTearDown -- "fixture context" */
    utProf_Ev_Fixture_Start,
    utProf_Ev_Fixture_End,
    utProf_Ev_Name_Test_Start,
    utProf_Ev_Name_Test_End,
    utProf_Ev_TestSetup_Start,
    utProf_Ev_TestSetup_End,
    utProf_Ev_TestTearDown_Start,
    utProf_Ev_TestTearDown_End,
    utProf_Ev_TestCase_Start,
    utProf_Ev_TestCase_End,

} utProfEnum;

#endif/*__UT_OTHER_H__*/
