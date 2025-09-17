/********************************************************************
 * COPYRIGHT --
 ********************************************************************
 * Program: -
 * Author:
 * Created: August 14, 2012
 ********************************************************************
 * Test registration and handshake
 ********************************************************************/

#include <bur/plctypes.h>

#ifdef _DEFAULT_INCLUDES
#include <AsDefault.h>
#endif

#include "include/utRunner.h"
#include "UtMgr.h"


/* ******************************/
/* TODO: this should be handled by the TestSuite Interface and not with 2 more variables...*/
extern TestSetActive utTestSets[];
extern TestSetList setList;

/* ******************************/


/* Enables this programs test - function pointer called by TestRunnerWebServiceHandler() */
unsigned short run_this_test(UtMgrTestSuite_typ *TestSuiteRef)
{
	switch(TestSuiteRef->Internal.TestHelper.CurrentPhase)
	{
		case utMgrTEST_PHASE_IDLE :
			{	/* Uupdating in idle state (program re-transferred ...) */
			
				/* Note: Accessing .Interal hurts the API definition a bit, but this code acts as helper for UtMgrTestSuite  in the program's context*/ 
				TestSuiteRef->Internal.TestHelper.TestSets = (UDINT)setList.list;
				TestSuiteRef->Internal.TestHelper.TestSetCount = setList.nrOfTestSets;
				TestSuiteRef->Internal.TestHelper.CurrentPhase = utMgrTEST_PHASE_RUNNING;
				return ut_BUSY;
			}
		case utMgrTEST_PHASE_RUNNING :
			{
				TestSetActive *locTestSet = (TestSetActive *)TestSuiteRef->Internal.TestHelper.TestSets;
				if(locTestSet[TestSuiteRef->Internal.TestHelper.CurrentTestSet].active)
				{
					switch(UtMgrTestRunnerRunTest((unsigned long)locTestSet[TestSuiteRef->Internal.TestHelper.CurrentTestSet].set))
					{
						case ut_BUSY :
							break;
						case ut_DONE :		
						case ut_ABORT:
						default:
							/* goto next test set */
							TestSuiteRef->Internal.TestHelper.CurrentTestSet += 1;
							break;	
					}
				}
				else
				{
					TestSuiteRef->Internal.TestHelper.CurrentTestSet++;
				}

				if(TestSuiteRef->Internal.TestHelper.CurrentTestSet >= TestSuiteRef->Internal.TestHelper.TestSetCount)
				{
					TestSuiteRef->Internal.TestHelper.CurrentTestSet = 0;
					TestSuiteRef->Internal.TestHelper.CurrentPhase = utMgrTEST_PHASE_DONE;
				}
				return ut_BUSY;
			}
		case utMgrTEST_PHASE_DONE :
			{
				TestSuiteRef->Internal.TestHelper.CurrentPhase = utMgrTEST_PHASE_IDLE;
				return ut_DONE;
			}
	}
	/* Error occured ...PF?  No specific handling at the moment*/
	return ut_ABORT;
}

	/* Registers Test  */
void utInit(UtMgrTestSuite_typ *TestSuiteRef)
{
	TestSuiteRef->Type = utMgrTEST_TYPE_C;
	TestSuiteRef->Enable = 1;
	/* Note: Accessing .Interal hurts the API definition a bit, but this code acts as helper for UtMgrTestSuite  in the program's context*/ 
	TestSuiteRef->Internal.TestHelper.TestSets = (UDINT)setList.list;
	TestSuiteRef->Internal.TestHelper.TestSetCount = setList.nrOfTestSets;
	UtMgrTestSuite(TestSuiteRef);
}


void utCyclic(UtMgrTestSuite_typ *TestSuiteRef)
{
	UtMgrTestSuite(TestSuiteRef);
	if(TestSuiteRef->TestActive)
	{
		/* The test code runs in programs own context / task class */
		switch(run_this_test(TestSuiteRef))
		{
			case ut_BUSY :
				break;
			case ut_DONE :
				TestSuiteRef->TestFinished = 1;
				break;
			case ut_ABORT :
			default :
				TestSuiteRef->TestAborted = 1;
		}
	}
	else if (TestSuiteRef->TestFinishedAck)
	{
		TestSuiteRef->TestFinished = 0;
		TestSuiteRef->TestAborted = 0;
	}
}


void  utExit(UtMgrTestSuite_typ *TestSuiteRef)
{
	/* Unregisters Test */
	TestSuiteRef->Enable = 0;
	do
	{
		UtMgrTestSuite(TestSuiteRef);
	}
	while(TestSuiteRef->Busy);
}
