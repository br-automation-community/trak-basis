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
 * $Id: AssertImpl.c,v 1.5 2004/02/10 16:15:25 arms22 Exp $
 */


#include "include/AssertImpl.h"


#include "src/embunit/stdImpl_c.h"

#define FALSE 0
#define TRUE  1

/*
 * Note: Less than 255,  a char is used as counter
*/
#define ASSERT_STRING_BUFFER_MAX	200
#define ASSERT_NUMBER_BUFFER_MAX	100

BOOL assertCondition(BOOL condition, const char *message, unsigned  long line, const char *file)
{
	if (condition)
	{
		addPassed("", line, file);
		return TRUE;
	}
	else
	{
		addFailure(message, line, file);
		return FALSE;
	}
}

BOOL assertImplementationInt(int expected, int actual, unsigned  long line, const char *file)
{

	if (expected == actual)
	{
		addPassed("", line, file);
		return TRUE;
	}
	else
	{
		char buffer[ASSERT_NUMBER_BUFFER_MAX];	/*"exp -2147483647 was -2147483647"*/
		char numbuf[12];	/*32bit int decimal maximum column is 11 (-2147483647~2147483647)*/

		stdimpl_strcpy(buffer, "exp ");

		{
			stdimpl_itoa(expected, numbuf, 10);
			stdimpl_strncat(buffer, numbuf, 11);
		}

		stdimpl_strcat(buffer, " was ");

		{
			stdimpl_itoa(actual, numbuf, 10);	
			stdimpl_strncat(buffer, numbuf, 11);
		}

		addFailure(buffer, line, file);
		return FALSE;
	}
}

BOOL assertImplementationMem(void *expected, void  *actual, unsigned long  size, unsigned  long line, const char *file)
{
	signed short compare = 0;
	char buffer[ASSERT_STRING_BUFFER_MAX];
	if(expected && actual && size)
	{

		compare = stdimpl_memcmp(expected,actual,size);
		if (0 == compare)
		{
			addPassed("", line, file);
			return TRUE;
		}
		else
		{

			char numbuf[12];	/*32bit int decimal maximum column is 11 (-2147483647~2147483647)*/

			stdimpl_strcpy(buffer, "Result of memory comparison was ");

			{
				stdimpl_itoa(compare, numbuf, 10);
				stdimpl_strncat(buffer, numbuf, 11);
			}

			addFailure(buffer, line, file);
			return FALSE;
		}

	}
	else
	{
		if(!size)
		{
			stdimpl_strcpy(buffer, "Invalid size for comparison ");
			addFailure(buffer, line, file);
			return FALSE;
		}
		else if (!actual)
		{
			stdimpl_strcpy(buffer, "acutal value was a nullpointer ");
			addFailure(buffer, line, file);
			return FALSE;
		}
		else /*(!expected)*/
		{
			stdimpl_strcpy(buffer, "expected value was a nullpointer ");
			addFailure(buffer, line, file);
			return FALSE;
		}
	}
}

BOOL assertImplementationCStr(const char *expected, const char *actual, unsigned  long line, const char *file)
{
	if (expected && actual && (stdimpl_strcmp(expected,actual)==0) )
	{
		addPassed("", line, file);
		return TRUE;
	}
	else
	{
		char buffer[ASSERT_STRING_BUFFER_MAX];
#define exp_act_limit ((ASSERT_STRING_BUFFER_MAX- 15 - 1)/2)/*	"exp'' was''" = 11 byte	*/
		int el;
		int al;

		if (expected)
		{
			el = stdimpl_strlen(expected);
		}
		else
		{
			el = 4;
			expected = "null";
		}

		if (actual)
		{
			al = stdimpl_strlen(actual);
		}
		else
		{
			al = 4;
			actual = "null";
		}
		if (el > exp_act_limit)
		{
			if (al > exp_act_limit)
			{
				al = exp_act_limit;
				el = exp_act_limit;
			}
			else
			{
				int w = exp_act_limit + (exp_act_limit - al);
				if (el > w)
				{
					el = w;
				}
			}
		}
		else
		{
			int w = exp_act_limit + (exp_act_limit - el);
			if (al > w)
			{
				al = w;
			}
		}
		stdimpl_strcpy(buffer, "exp \"");
		stdimpl_strncat(buffer, expected, el);
		stdimpl_strcat(buffer, "\" was \"");
		stdimpl_strncat(buffer, actual, al);
		stdimpl_strcat(buffer, "\"");

		addFailure(buffer, line, file);
		return FALSE;
	}
#undef exp_act_limit
}



/*
 * Author: 		B&R
 * Added: 		September 04, 2012
 *
 */
BOOL assertImplementationDoublesWithin(const double delta,
	const double expected,
	const double actual,
	unsigned long line, const char *file)
{
	char buffer[ASSERT_NUMBER_BUFFER_MAX];	/*"exp -2147483647 was -2147483647"*/
	char numbuf[22];	/*32bit int decimal maximum column is 11 (-2147483647~2147483647)*/

	double diff = actual - expected;
	double pos_delta = delta;

	if (diff < 0)
	{
		diff = 0.0f - diff;
	}
	if (pos_delta < 0)
	{
		pos_delta = 0.0f - pos_delta;
	}

	if (pos_delta < diff)
	{
		stdimpl_strcpy(buffer, "exp ");
		stdimpl_dtoa(expected, &numbuf[0], sizeof(numbuf));
		stdimpl_strncat(buffer, numbuf, 11);

		stdimpl_strcat(buffer, " was ");
		stdimpl_dtoa(actual, &numbuf[0], sizeof(numbuf));
		stdimpl_strncat(buffer, numbuf, 11);

		addFailure(buffer, line, file);
		return FALSE;
	}
	else
	{
		addPassed("", line, file);
		return TRUE;
	}
}


/*
 * Author: 		B&R
 * Added: 		September 04, 2012
 *
 */
BOOL assertImplementationFloatsWithin(const float delta,
	const float expected,
	const float actual,
	unsigned long line, const char *file)
{
	char buffer[ASSERT_NUMBER_BUFFER_MAX];	/*"exp -2147483647 was -2147483647"*/
	char numbuf[22];	/*32bit int decimal maximum column is 11 (-2147483647~2147483647)*/

	float diff = actual - expected;
	float pos_delta = delta;

	if (diff < 0)
	{
		diff = 0.0f - diff;
	}
	if (pos_delta < 0)
	{
		pos_delta = 0.0f - pos_delta;
	}

	if (pos_delta < diff)
	{
		stdimpl_strcpy(buffer, "exp ");
		stdimpl_ftoa(expected, &numbuf[0], sizeof(numbuf));
		stdimpl_strncat(buffer, numbuf, 11);

		stdimpl_strcat(buffer, " was ");
		stdimpl_ftoa(actual, &numbuf[0], sizeof(numbuf));
		stdimpl_strncat(buffer, numbuf, 11);

		addFailure(buffer, line, file);
		return FALSE;
	}
	else
	{
		addPassed("", line, file);
		return TRUE;
	}
}

/*
 * Author: 		B&R
 * Added: 		August 21, 2012
 * Modified: 	October 09, 2012
 *
 * Prints dezimal value of the WSTRING characters
 */
BOOL assertImplementationWStr(const unsigned short *expected, const unsigned short *actual, unsigned long line, const char *file)
{
	if (expected && actual && (stdimpl_Wstrcmp(expected,actual)==0))
	{
		addPassed("", line, file);
		return TRUE;
	}
	else
	{

		char buffer[ASSERT_STRING_BUFFER_MAX*2];

#define exp_act_limit ((ASSERT_STRING_BUFFER_MAX- 15 - 1)/2 / sizeof(unsigned short))/*	"exp'' was''" = 11 byte	*/
#define MAX_LEN 6 /* "65535 " */
		int el;
		int al;

		if (expected)
		{
			el = MAX_LEN * (sizeof(unsigned short) * stdimpl_Wstrlen(expected));
		}
		else
		{
			el = 4;
			/* will be append later */
		}

		if (actual)
		{
			al = MAX_LEN * (sizeof(unsigned short) * stdimpl_Wstrlen(actual));
		}
		else
		{
			al = 4;
			/* will be append later */
		}
		if (el > exp_act_limit)
		{
			if (al > exp_act_limit)
			{
				al = exp_act_limit;
				el = exp_act_limit;
			}
			else
			{
				int w = exp_act_limit + (exp_act_limit - al);
				if (el > w)
				{
					el = w;
				}
			}
		}
		else
		{
			int w = exp_act_limit + (exp_act_limit - el);
			if (al > w)
			{
				al = w;
			}
		}
		stdimpl_strcpy(buffer, "exp \"");
		if(expected)
			stdimpl_Wstrncat(buffer, expected, el/(sizeof(unsigned short)) );
		else
			stdimpl_strcat(buffer, "null");
		stdimpl_strcat(buffer, "\" was \"");
		if(actual)
			stdimpl_Wstrncat(buffer, actual, al/(sizeof(unsigned short)) );
		else
			stdimpl_strcat(buffer, "null");
		stdimpl_strcat(buffer, "\"");

		addFailure(buffer, line, file);
		return FALSE;
	}
#undef exp_act_limit
}
