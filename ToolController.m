/*
   Project: DataBasinTool

   Copyright (C) 2021 Free Software Foundation

   Author: Riccardo Mottola

   Created: 2021-05-06 01:37:15 +0200 by multix

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

#import "ToolController.h"
#import "DBTLogger.h"

@implementation ToolController

- (id)init
{
  if ((self = [super init]))
    {
      logger = [[DBTLogger alloc] init];
    }
  return self;
}

- (void)dealloc
{
  [logger release];
  [super dealloc];
}

- (void)executeLogin
{
  NSLog(@"should login!");
}

- (void)executeQuery
{
  NSLog(@"should query!");
}


- (void)executeCommandWithContext:(NSDictionary*)context
{
  NSString *command;
  
  NSLog(@"executing context: %@", context);
  
  command = [context objectForKey:@"command"];
  if (command == nil)
    [logger log:LogStandard :@"No command given"];
  else if ([command isEqualToString:@"login"])
    [self executeLogin];
  else if ([command isEqualToString:@"query"])
    [self executeQuery];
  else
    [logger log: LogStandard :@"%@ not recognized as a command", command];
}

@end
