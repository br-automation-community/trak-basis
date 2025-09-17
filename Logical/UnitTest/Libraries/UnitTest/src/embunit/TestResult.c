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
 * $Id: TestResult.c,v 1.4 2004/02/10 16:19:29 arms22 Exp $
 */
#include "src/utOther.h"
#include "include/Test.h"
#include "include/TestListener.h"
#include "include/TestResult.h"

/*
 * Author: 		B&R
 * Modified: 	October   09, 2012
*/
void TestResult_init(TestResult *self,TestListner *listner)
{
	if(!self)
		return;

	self->runCount = 0;
	self->failureCount = 0;
	self->passedCount = 0;
	self->summarizedCount = 0;
	self->abortCount = 0;
	self->suceessedTestCount = 0;
	self->skippedTestCount = 0;
	self->infoCount = 0;
	self->listener = listner;

}

void TestResult_startTest(TestResult *self,Test *test)
{
	if(!self)
		return;
	self->runCount++;

	if (self->listener)
	{
		TestListener_doLog(self->listener, test, 0, 0, 0, utProf_Ev_Name_Test_Start);
		TestListner_startTest(self->listener, test);
	}
}

void TestResult_endTest(TestResult *self,Test *test)
{
	if(!self)
		return;

	if (self->listener)
	{
		TestListener_doLog(self->listener, test, 0, 0, 0, utProf_Ev_Name_Test_End);
		TestListner_endTest(self->listener, test);
	}
}


void TestResult_skipTest(TestResult *self,Test *test)
{
	if(!self)
		return;
	self->runCount++;
	if (self->listener)
	{
		TestListener_doLog(self->listener, test, 0, 0, 0, utProf_Ev_Skipped);
		TestListner_skippedTest(self->listener, test);
	}
}


/*
 * Author: 		B&R
 * Modified: 	October   09, 2012
*/
void TestResult_addFailure(TestResult *self,Test *test,const char *msg,unsigned long line,const char *file)
{
	if(!self)
		return;
	self->summarizedCount++;
	self->failureCount++;
	if (self->listener)
	{
		TestListener_doLog(self->listener, test, msg, line, file, utProf_Ev_MsgFail);
		TestListner_addFailure(self->listener, test, msg, line, file);
	}
}

/*
 * Author: 		B&R
 * Added: 		October   09, 2012
*/
void TestResult_addPassed(TestResult *self,Test *test,const char *msg,unsigned long line,const char *file)
{
	if(!self )
		return;

	self->summarizedCount++;
	self->passedCount++;
	/*! \note changed: add passed wird nun auch aufgerufen --> interessant für Json*/
	if (self->listener)
	{
		TestListener_doLog(self->listener, test, msg, line, file, utProf_Ev_MsgPass);
		TestListner_addPassed(self->listener, test, msg, line, file);
	}
}

/*
 * Author: 		B&R
 * Added: 		October   23, 2012
*/
void TestResult_addInfo(TestResult *self,Test *test,const char *msg,unsigned long line,const char *file)
{
	if(!self )
		return;
	self->infoCount++;

	if (self->listener)
	{
		TestListener_doLog(self->listener, test, msg, line, file, utProf_Ev_MsgInfo);
		TestListner_addInfo(self->listener, test, msg, line, file);
	}
}


void TestResult_addAbort(TestResult *self,Test *test,const char *msg,unsigned long line,const char *file)
{
	if(!self )
		return;
	self->abortCount++;
	if (self->listener)
	{
		TestListener_doLog(self->listener, test, msg, line, file, utProf_Ev_MsgAbort);
		TestListner_addAbort(self->listener, test, msg, line, file);
	}
}

