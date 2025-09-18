/*
 * COPYRIGHT AND PERMISSION NOTICE
 *
 * Copyright (c) 2003 Embedded Unit Project
 *
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, and/or sell copies of the Software, and to permit persons
 * to whom the Software is furnished to do so, provided that the above
 * copyright notice(s) and this permission notice appear in all copies
 * of the Software and that both the above copyright notice(s) and this
 * permission notice appear in supporting documentation.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
 * OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY
 * SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
 * CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Except as contained in this notice, the name of a copyright holder
 * shall not be used in advertising or otherwise to promote the sale,
 * use or other dealings in this Software without prior written
 * authorization of the copyright holder.
 *
 * $Id: TestCaller.c,v 1.6 2004/02/10 16:19:29 arms22 Exp $
 */
#include "src/utOther.h"
#include "include/Test.h"
#include "include/TestResult.h"

#include "include/TestListener.h"
#include "include/TestCase.h"
#include "include/TestCaller.h"


#include "src/embunit/profiling.h"


extern TestResult *result_;
extern TestCase *self_;


const char *TestCaller_name(TestCaller *self)
{
	return self->name;
}

TestCase cs = new_TestCase(0,0,0,0);

int loopCounter = 0;


char TestCaller_run(TestCaller *self,TestResult *result)
{
	switch(self->state)
	{
		case stateStart:
			{
				self->abort = 0;
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Name_Set_Start);
				loopCounter  = 0;
				self->state = stateSetup;
				
					
				if(0 == (self->mode) )/* Skip */
				{
	
					while(loopCounter < self->numberOfFixtuers)
					{
						cs.isa = (TestImplement *)&TestCaseImplement;
						cs.abort = 0;

						cs.setUp	= self->setUp;
						cs.tearDown	= self->tearDown;

						cs.name		= self->fixtuers[loopCounter].name;
						cs.runTest	= self->fixtuers[loopCounter].test;
					
						cs.mode = self->fixtuers[loopCounter].mode;
						
						TestResult 	*wr = result_;	/*push*/
						TestCase 	*ws = self_;	/*push*/

						result_ 	= result;
						self_ 		= (TestCase *)self; /* Attention TestCase != TestCaller in some structure members! */
					
						TestResult_skipTest(result,(Test*)&cs);
					
						result_ 	= wr;	/*pop*/
						self_ 		= ws;	/*pop*/
					
						loopCounter++;
					}
					
				
					self->state = stateDefault;
					break;
				}
				
			}
		case stateSetup:
			{
				if(self->setUpSuite)
				{
					TestResult 	*wr = result_;	/*push*/
					TestCase 	*ws = self_;	/*push*/

					result_ 	= result;
					self_ 		= (TestCase *)self; /* Attention TestCase != TestCaller in some structure members! */
					TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetSetup_Start);
					switch(self->setUpSuite())
					{
						case ut_BUSY:
							break;
						case ut_DONE:
							self->state = stateRun;
							break;
						case ut_ABORT:
							TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Abort);
							self->state = stateTearDown;
							self->abort = 1;
							break;
					}
					TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetSetup_End);
					if(self->cyclicSetCaller)
					{
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_Start);
						self->cyclicSetCaller();
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_End);
					}
					result_ 	= wr;	/*pop*/
					self_ 		= ws;	/*pop*/

					break;

				}
				else
				{
					self->state = stateRun;
				}

			}
		case stateRun:
			{
				if(!self->numberOfFixtuers)
				{
					self->state= stateTearDown;
					
				}
				else
				{
					if(stateStart == cs.state  )
					{
						/* init test */
						cs.isa = (TestImplement *)&TestCaseImplement;
						cs.abort = 0;

						cs.setUp	= self->setUp;
						cs.tearDown	= self->tearDown;

						cs.name		= self->fixtuers[loopCounter].name;
						cs.runTest	= self->fixtuers[loopCounter].test;
					
						cs.mode = self->fixtuers[loopCounter].mode;
		
						if( 0 == cs.mode) /* skip this test */
						{
							TestResult 	*wr = result_;	/*push*/
							TestCase 	*ws = self_;	/*push*/

							result_ 	= result;
							self_ 		= (TestCase *)self; /* Attention TestCase != TestCaller in some structure members! */
					
							TestResult_skipTest(result,(Test*)&cs);
					
							result_ 	= wr;	/*pop*/
							self_ 		= ws;	/*pop*/

							cs.state =	stateDefault;	
						}

					}
					if( 1 == cs.mode) /*  this test is not skipped */
					{
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Fixture_Start);
						/*run test*/
						Test_run(&cs,result);
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Fixture_End);

						if(self->cyclicSetCaller)
						{

							TestResult 	*wr = result_;	/*push*/
							TestCase *ws = self_;	/*push*/

							result_ 	= result;
							self_ 		= (TestCase *)self; /* Attention TestCase != TestCaller in some structure members! */

							TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_Start);

							self->cyclicSetCaller();

							TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_End);

							result_ 	= wr;	/*pop*/
							self_ 		= ws;	/*pop*/

						}
					}
					/** to go to next test */
					if(stateDefault == cs.state)
					{
						cs.state = stateStart;

						if(cs.abort)
						{
							self->state = stateTearDown;
							self->abort = 1;

							TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Abort);
						}
						else
						{
							loopCounter++;
							/* Last test */
							if(loopCounter == self->numberOfFixtuers )
							{
								loopCounter  = 0;
								self->state = stateTearDown;
							}

						}
					}

				}
				break;
			
			}
		case stateTearDown:
			{
				if(self->tearDownSuite)
				{
					TestResult 	*wr = result_;	/*push*/
					TestCase *ws = self_;	/*push*/

					result_ 	= result;
					self_ 		= (TestCase *)self; /* Attention TestCase != TestCaller in some structure members! */
					switch(self->tearDownSuite())
					{
						case ut_BUSY:
							break;
						case ut_DONE:
							self->state = stateEnd;
							break;
						case ut_ABORT:
							self->state = stateEnd;
							self->abort = 1;
							TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Abort);

							break;
					}
					if(self->cyclicSetCaller)
					{
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_Start);
						self->cyclicSetCaller();
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_SetCylic_End);
					}
					result_ 	= wr;	/*pop*/
					self_ 		= ws;	/*pop*/

					if(stateEnd != self->state)
					{
						break;
					}
				}
				else
				{
					self->state = stateEnd;
				}


			}
		case stateEnd:
		case stateDefault:
		default:
			{
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Name_Set_End);
				self->state = stateDefault;
				return ut_DONE;
			}
	}

	return ut_BUSY;
}


int TestCaller_countTestCases(TestCaller *self)
{
	return self->numberOfFixtuers;
}

const TestImplement TestCallerImplement =
	{
	(TestNameFunction)			TestCaller_name,
	(TestRunFunction)			TestCaller_run,
	(TestCountTestCasesFunction)TestCaller_countTestCases,
	};


