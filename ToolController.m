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

#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSoapCSV.h>
#import <DataBasinKit/DBCSVWriter.h>
#import <DataBasinKit/DBFileWriter.h>
#import <DataBasinKit/DBHTMLWriter.h>
#import <DataBasinKit/DBCSVReader.h>

@implementation ToolController

- (id)init
{
  if ((self = [super init]))
    {
      logger = [[DBTLogger alloc] init];
      [logger setLogLevel:LogDebug];
    }
  return self;
}

- (void)dealloc
{
  [logger release];
  [super dealloc];
}

- (void)setupDB:(NSDictionary *)parameters
{
  NSURL *URL;
  unsigned uint;
  
  db = [[DBSoap alloc] init];
  [db setLogger: logger];

  uint = [[parameters objectForKey:@"UpBatchSize"] intValue];
  if (uint > 0)
    [db setUpBatchSize:uint];

  uint = [[parameters objectForKey:@"DownBatchSize"] intValue];
  if (uint > 0)
    [db setDownBatchSize:uint];

  uint = [[parameters objectForKey:@"MaxSOQLQueryLength"] intValue];
  if (uint > 0)
    [db setMaxSOQLLength:uint];

  [db setEnableFieldTypesDescribeForQuery:[[parameters objectForKey:@"DescribeFieldTypesInQueries"] boolValue]];

  [db setSessionId:[parameters objectForKey:@"sessionID"]];
  
  URL = [[NSURL alloc] initWithString:[parameters objectForKey:@"URL"]];
  [db setServerURL:URL];
  [URL release];

  dbCsv = [[DBSoapCSV alloc] init];
  [dbCsv setDBSoap:db];
}

- (void)executeLogin:(NSDictionary *)parameters
{
  NSLog(@"should login!");
}

- (void)executeQuery:(NSDictionary *)parameters
{
  NSString         *statement;
  NSString         *filePath;
  NSFileHandle     *fileHandle;
  NSFileManager    *fileManager;
  DBFileWriter     *fileWriter;
  NSString         *str;
  NSString         *fileType;
  BOOL             writeFieldsOrdered;
  BOOL             queryAll;
  NSStringEncoding enc;

  NSLog(@"should query!");

  writeFieldsOrdered = [[parameters objectForKey:@"writeFieldsOrdered"] boolValue];
  queryAll = [[parameters objectForKey:@"writeFieldsOrdered"] boolValue];
  statement = [parameters objectForKey:@"statement"];
  filePath = [parameters objectForKey:@"outputFile"];
  fileType = DBFileFormatCSV;
  if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"html"])
    fileType = DBFileFormatHTML;
  else if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"xls"])
    fileType = DBFileFormatXLS;
  
  fileManager = [NSFileManager defaultManager];
  if ([fileManager createFileAtPath:filePath contents:nil attributes:nil] == NO)
    {
      [logger log:LogStandard :@"Could not create File."];
      return;
    }  

  fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
  if (fileHandle == nil)
    {
      [logger log:LogStandard :@"Cannot create File."];
      return;
    }

  fileWriter = nil;
  
  if (fileType == DBFileFormatCSV)
    {
      fileWriter = [[DBCSVWriter alloc] initWithHandle:fileHandle];
/*      [(DBCSVWriter *)fileWriter setLineBreakHandling:[defaults integerForKey:CSVWriteLineBreakHandling]];
      str = [defaults stringForKey:@"CSVWriteQualifier"];
      if (str)
        [(DBCSVWriter *)fileWriter setQualifier:str];
      str = [defaults stringForKey:@"CSVWriteSeparator"];
      if (str)
        [(DBCSVWriter *)fileWriter setSeparator:str]; */
    }
  else if (fileType == DBFileFormatHTML || fileType == DBFileFormatXLS)
    {
      fileWriter = [[DBHTMLWriter alloc] initWithHandle:fileHandle];
      if (fileType == DBFileFormatXLS)
        [fileWriter setFileFormat:DBFileFormatXLS];
      else
        [fileWriter setFileFormat:DBFileFormatHTML];
    }
  [fileWriter setWriteFieldsOrdered:writeFieldsOrdered];
  [fileWriter setLogger:logger];
  
  /*
  enc = [defaults integerForKey: @"StringEncoding"];
  if (enc)
    [fileWriter setStringEncoding:enc]; */
  NSLog(@"fileType is: %@, writer: %@", fileType, fileWriter);
  
  [self setupDB:parameters];
  
  NS_DURING
    [dbCsv query :statement queryAll:queryAll toWriter:fileWriter progressMonitor:nil];
  NS_HANDLER
    if ([[localException name] hasPrefix:@"DB"])
      {
        NSLog(@"%@", [localException description]);
      }
  NS_ENDHANDLER

  [fileWriter release];
  [fileHandle closeFile];
}

- (void)executeUpdate:(NSDictionary *)parameters
{
  NSString       *filePath;
  NSString       *resFilePath;
  DBCSVReader    *reader;
  NSString       *whichObject;
  NSMutableArray *results;
  NSFileManager  *fileManager;
  NSFileHandle   *resFH;
  DBCSVWriter    *resWriter;
  NSString       *str;


  filePath = [parameters objectForKey:@"inputFile"];
  resFilePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"results.csv"];

  [logger log:LogDebug: @"[ToolController executeUpdate] writing results to: %@", resFilePath];

  /*
  updateProgress = [[DBProgress alloc] init];
  [updateProgress setLogger:logger];
  [updateProgress setProgressIndicator: progIndUpdate];
  [updateProgress setRemainingTimeField: fieldRTUpdate];
  [updateProgress reset];
*/

  whichObject = [parameters objectForKey:@"object"];
  [logger log:LogInformative :@"[ToolController executeUpdate] object: %@\n", whichObject];

  results = nil;
  reader = [[DBCSVReader alloc] initWithPath:filePath withLogger:logger];
  /*
  str = [defaults stringForKey:@"CSVReadQualifier"];
  if (str)
    [reader setQualifier:str];
  str = [defaults stringForKey:@"CSVReadSeparator"];
  if (str)
    [reader setSeparator:str]; */
  [reader parseHeaders];

  [self setupDB:parameters];

  [dbCsv setRunAssignmentRules:[[parameters objectForKey:@"RunAssignmentRules"] boolValue]];

  NS_DURING
    results = [dbCsv update:whichObject fromReader:reader progressMonitor:nil];
    [results retain];
  NS_HANDLER
    if ([[localException name] hasPrefix:@"DB"])
      {
        NSLog(@"%@", [localException description]);
      }
    else
      {
        [localException raise];
      }
  NS_ENDHANDLER

  fileManager = [NSFileManager defaultManager];
  if ([fileManager createFileAtPath:resFilePath contents:nil attributes:nil] == NO)
    {
      [logger log:LogStandard :@"Cannot create File."];
    }

  resFH = [NSFileHandle fileHandleForWritingAtPath:resFilePath];
  if (resFH == nil)
    {
      [logger log:LogStandard :@"Cannot open File for writing."];
    }
  else
    {
      if (results != nil && [results count] > 0)
        {
          resWriter = [[DBCSVWriter alloc] initWithHandle:resFH];
          [resWriter setLogger:logger];
//          [resWriter setStringEncoding: [defaults integerForKey: @"StringEncoding"]];
//          str = [defaults stringForKey:@"CSVWriteQualifier"];
          if (str)
            [resWriter setQualifier:str];
//          str = [defaults stringForKey:@"CSVWriteSeparator"];
          if (str)
            [resWriter setSeparator:str];

          [resWriter setFieldNames:[results objectAtIndex: 0] andWriteThem:YES];
          [resWriter writeDataSet: results];

          [resWriter release];
        }
      else
        {
          [logger log:LogStandard :@"[ToolController executeUpdate] No Results"];
        }
    }

  [reader release];
  [whichObject release];
//  [updateProgress release];
//  updateProgress = nil;
  [results release];
}


- (void)executeCommandWithContext:(NSDictionary*)context
{
  NSString *operation;
  
  NSLog(@"executing context: %@", context);
  
  operation = [context objectForKey:@"operation"];
  if (operation == nil)
    [logger log:LogStandard :@"No operation given"];
  else if ([operation isEqualToString:@"login"])
    [self executeLogin:context];
  else if ([operation isEqualToString:@"query"])
    [self executeQuery:context];
  else if ([operation isEqualToString:@"update"])
    [self executeUpdate:context];
  else
    [logger log: LogStandard :@"%@ not recognized as an operation", operation];
}

@end
