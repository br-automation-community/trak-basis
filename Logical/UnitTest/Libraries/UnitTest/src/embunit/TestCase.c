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
 * $Id: TestCase.c,v 1.6 2004/02/10 16:19:29 arms22 Exp $
 */
#include "src/utOther.h"
#include "include/Test.h"
#include "include/TestCase.h"
#include "include/TestResult.h"

#include "include/TestListener.h"
#include "src/embunit/profiling.h"

TestResult *result_;
TestCase *self_;

const char *TestCase_name(TestCase *self)
{
	return self->name;
}

void TestCase_run(TestCase *self,TestResult *result)
{
	switch(self->state)
	{
		case stateStart:
		{
			TestResult_startTest(result, (Test *)self);
			self->state = stateSetup;
		}
		case stateSetup:
		{
			if (self->setUp)
			{
				TestResult 	*wr = result_;	/*push*/
				TestCase *ws = self_;	/*push*/

				result_ 	= result;
				self_ 		= self;
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestSetup_Start);
				switch(self->setUp())
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
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestSetup_End);
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
			if( self->runTest )
			{
				TestResult 	*wr = result_;	/*push*/
				TestCase *ws = self_;	/*push*/

				result_ 	= result;
				self_ 		= self;

				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestCase_Start);
				switch(self->runTest())
				{
					case ut_BUSY:
						break;
					case ut_DONE:
						self->state = stateTearDown;
						break;
					case ut_ABORT:
						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Abort);
						self->state = stateTearDown;
						self->abort = 1;
						break;
				}
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestCase_End);
				result_ 	= wr;	/*pop*/
				self_ 		= ws;	/*pop*/

				/* avoid extra cycle for test cases without test teardowns */
				if (self->tearDown && stateTearDown == self->state )
				{
					break;
				}
				/* do not go through next case while in this state ! */
				else if ( stateTearDown != self->state)
				{
					break;
				}
			}
			else
			{
				/*No testcase ??*/

				self->state = stateTearDown;
			}

		}
		case stateTearDown:
		{
			if (self->tearDown)
			{
				TestResult 	*wr = result_;	/*push*/
				TestCase *ws = self_;	/*push*/

				result_ 	= result;
				self_ 		= self;
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestTearDown_Start);
				switch(self->tearDown())
				{
					case ut_BUSY:
						break;
					case ut_DONE:
						self->state = stateEnd;
						break;
					case ut_ABORT:
						self->state = stateEnd;

						TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_Abort);
						self->abort = 1;
						break;
				}
				TestListener_doLog(result->listener, self, 0,0,0,utProf_Ev_TestTearDown_End);

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
		{
			TestResult_endTest(result, (Test *)self);
			self->state = stateDefault;
		}
		case stateDefault :
		default :
		{
			self->state = stateDefault;
			/*TestDone - informational*/
		}
	}


}

int TestCase_countTestCases(TestCase *self)
{
	return 1;
}

const TestImplement TestCaseImplement =
{
	(TestNameFunction)			TestCase_name,
	(TestRunFunction)			TestCase_run,
	(TestCountTestCasesFunction)TestCase_countTestCases,
};

void addFailure(const char *msg, unsigned long line, const char *file)
{
	TestResult_addFailure(result_, (Test *)self_, (char *)msg, line, (char *)file);
}


/*
 * Author: 		B&R
 * Added: 		October   09, 2012
*/
void addPassed(const char *msg, unsigned long line, const char *file)
{
	TestResult_addPassed(result_, (Test *)self_, (char *)msg, line, (char *)file);
}

/*
 * Author: 		B&R
 * Added: 		October   23, 2012
*/
void addInfo(const char *msg, unsigned long line, const char *file)
{
	TestResult_addInfo(result_, (Test *)self_, (char *)msg, line, (char *)file);
}

void addAbort(const char *msg, unsigned long line, const char *file)
{
	TestResult_addAbort(result_, (Test *)self_, (char *)msg, line, (char *)file);
}


