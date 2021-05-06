/*
   Project: DataBasinTool

   Copyright (C) 2021 Free Software Foundation

   Author: Riccardo Mottola

   Created: 2021-05-06 01:17:07 +0200 by multix

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _DBTLOGGER_H_
#define _DBTLOGGER_H_

#import <Foundation/Foundation.h>

#import <DataBasinKit/DBLoggerProtocol.h>

@interface DBTLogger : NSObject<DBLoggerProtocol>
{
  DBLogLevel logLevel;
}

@end

#endif // _DBTLOGGER_H_

