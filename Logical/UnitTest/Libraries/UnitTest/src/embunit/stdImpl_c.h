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
 * $Id: stdImpl.c,v 1.3 2004/02/10 16:15:25 arms22 Exp $
 */

#include "UtMgr.h"


static char *stdimpl_strcpy(char *dst, const char *src)
{
	char *start = dst;
	char c;
	do
	{
		c = *src;
		*dst = c;
		src++;
		dst++;
	}
	while (c);
	return start;
}
/* currently not used */
#if 0
/*
 * Author: 		B&R
 * Added: 		December 20, 2012
 */
static char *stdimpl_strrchr(char *src, const char chr)
{
	char *pos = 0;
	char c;
	do
	{
		c = *src;
		if(chr == c)
		{
			pos = src;
		}
		src++;
	}
	while (c);
	return pos;
}
/*
 * Author: 		B&R
 * Added: 		December 20, 2012
 */
static char *stdimpl_memcpy(char *dst, const char *src, unsigned long len)
{
	char *start = dst;
	char c;
	unsigned long i = 0;
	for(i= 0; i<len; i++)
	{
		c = *src;
		*dst = c;
		src++;
		dst++;
	}
	return start;
}
#endif

static char *stdimpl_strcat(char *dst, const char *src)
{
	char *start = dst;
	char c;
	do
	{
		c = *dst;
		dst++;
	}
	while (c);
	dst--;
	do
	{
		c = *src;
		*dst = c;
		src++;
		dst++;
	}
	while (c);
	return start;
}

static char *stdimpl_strncat(char *dst, const char *src,unsigned int count)
{
	char *start = dst;
	char c;
	do
	{
		c = *dst;
		dst++;
	}
	while (c);
	dst--;
	if (count)
	{
		do
		{
			c = *src;
			*dst = c;
			src++;
			dst++;
			count--;
		}
		while (c && count);
		*dst = '\0';
	}
	return start;
}


static int stdimpl_strlen(const char *str)
{
	const char *estr = str;
	char c;
	do
	{
		c = *estr;
		estr++;
	}
	while (c);
	return ((int)(estr - str - 1));
}

static int stdimpl_strcmp(const char *s1, const char *s2)
{
	char c1,c2;
	do
	{
		c1 = *s1++;
		c2 = *s2++;
	}
	while ((c1) && (c2) && (c1==c2));
	return c1 - c2;
}



static char *_xtoa(unsigned long v,char *string, int r, int is_neg)
{
	char *start = string;
	char buf[33],*p;

	p = buf;

	do
	{
		*p++ = "0123456789abcdef"[(v % r) & 0xf];
	}
	while (v /= r);

	if (is_neg)
	{
		*p++ = '-';
	}

	do
	{
		*string++ = *--p;
	}
	while (buf != p);

	*string = '\0';

	return start;
}

static char *stdimpl_itoa(int v,char *string,int r)
{
	if ((r == 10) && (v < 0))
	{
		return _xtoa((unsigned long)(-v), string, r, 1);
	}
	return _xtoa((unsigned long)(v), string, r, 0);
}


/*
 * Author: 		B&R
 * Added: 		August 21, 2012
 * Modified: 	October 09, 2012
 */
static char *stdimpl_Wstrncat(char *dst, const unsigned short *src,unsigned int count)
{
	char *start = dst;

	unsigned short c;

	do
	{
		c = *dst;
		dst++;
	}
	while (c);
	dst--;
	if (count)
	{
		do
		{
			c = *src;

			dst += 	stdimpl_strlen(stdimpl_itoa(c, dst, 10));
			*dst = ' ';
			dst++;
			src++;
			count--;
		}
		while (c && count);
		*dst = '\0';
	}
	return start;
}


/*
 * Author: 		B&R
 * Added: 		August 21, 2012
 * Modified: 	October 09, 2012
 */
static int stdimpl_Wstrlen(const unsigned short *str)
{
	const unsigned short *estr = str;
	unsigned short c;
	do
	{
		c = *estr;
		estr++;
	}
	while (c);
	return ((int)(estr - str - 1));
}

/*
 * Author: 		B&R
 * Added: 		August 21, 2012
 * Modified: 	October 09, 2012
 */
static int stdimpl_Wstrcmp(const unsigned short *s1, const unsigned short *s2)
{
	unsigned short c1,c2;
	do
	{
		c1 = *s1++;
		c2 = *s2++;
	}
	while ((c1) && (c2) && (c1==c2));
	return c1 - c2;
}


static char *stdimpl_ftoa(float v,char *string, unsigned long len)
{
	/*iec_double2str(v, sizeof(float), string, len);*/
	return	(char *)UtMgrHelperFtoa(v, sizeof(float),(unsigned long) string, len);

}


static char *stdimpl_dtoa(double v,char *string, unsigned long len)
{
	/*iec_double2str(v, sizeof(double), string, len);*/
	return	(char *)UtMgrHelperFtoa(v, sizeof(double), (unsigned long) string, len);

}

static char stdimpl_memcmp(const void *s1, const void *s2, unsigned long len)
{
	char c1,c2;
	unsigned long i = 0;
	for(i = 0; i < len; i++)
	{
		c1 = *(char *)s1++;
		c2 = *(char *)s2++;
		if(c1 != c2)
			return c1 - c2;
	}
	return c1 - c2;
}

