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
      [logger log:LogStandard :@"Cannot create File."];
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
	[logger log:LogStandard :@"%@", [localException description]];
      }
  NS_ENDHANDLER

  [fileWriter release];
  [fileHandle closeFile];
}

- (void)executeQueryIdentify:(NSDictionary *)parameters
{
  NSString       *statement;
  NSString       *filePathIn;
  NSString       *filePathOut;
  NSFileHandle   *fileHandleOut;
  NSFileManager  *fileManager;
  DBFileWriter   *fileWriter;
  DBCSVReader    *csvReader;
  NSString       *fileTypeOut;
  BOOL           writeFieldsOrdered;
  BOOL           queryAll;
  int            batchSize;
  NSString       *str;

  writeFieldsOrdered = [[parameters objectForKey:@"writeFieldsOrdered"] boolValue];
  queryAll = [[parameters objectForKey:@"writeFieldsOrdered"] boolValue];
  statement = [parameters objectForKey:@"statement"];
  filePathIn = [parameters objectForKey:@"inputFile"];
  filePathOut = [parameters objectForKey:@"outputFile"];
  fileTypeOut = DBFileFormatCSV;
  if ([[[filePathOut pathExtension] lowercaseString] isEqualToString:@"html"])
    fileTypeOut = DBFileFormatHTML;
  else if ([[[filePathOut pathExtension] lowercaseString] isEqualToString:@"xls"])
    fileTypeOut = DBFileFormatXLS;

  batchSize = [[parameters objectForKey:@"batchSize"] intValue];
  if (batchSize == 0)
    batchSize = -1; // as default we try max

  [logger log:LogDebug :@"[ToolController executeSelectIdentify] batch Size: %d\n", batchSize];

  fileManager = [NSFileManager defaultManager];

  NSLog(@"Input file path: %@", filePathIn);
  csvReader = [[DBCSVReader alloc] initWithPath:filePathIn withLogger:logger];
  /*
  str = [defaults stringForKey:@"CSVReadQualifier"];
  if (str)
    [csvReader setQualifier:str];
  str = [defaults stringForKey:@"CSVReadSeparator"];
  if (str)
  [csvReader setSeparator:str]; */
  [csvReader parseHeaders];

  NSLog(@"Output file path: %@", filePathOut);
  if ([fileManager createFileAtPath:filePathOut contents:nil attributes:nil] == NO)
    {
      [logger log:LogStandard :@"Cannot create File."];
      return;
    }

  fileHandleOut = [NSFileHandle fileHandleForWritingAtPath:filePathOut];
  if (fileHandleOut == nil)
    {
      [logger log:LogStandard :@"Cannot create File."];
      return;
    }

  fileWriter = nil;
  if (fileTypeOut == DBFileFormatCSV)
    {
      fileWriter = [[DBCSVWriter alloc] initWithHandle:fileHandleOut];
      /*
      str = [defaults stringForKey:@"CSVWriteQualifier"];
      if (str)
	[(DBCSVWriter *)fileWriter setQualifier:str];
      str = [defaults stringForKey:@"CSVWriteSeparator"];
      if (str)
	[(DBCSVWriter *)fileWriter setSeparator:str];
	[(DBCSVWriter *)fileWriter setLineBreakHandling:[defaults integerForKey:CSVWriteLineBreakHandling]]; */
    }
  else if (fileTypeOut == DBFileFormatHTML || fileTypeOut == DBFileFormatXLS)
    {
      fileWriter = [[DBHTMLWriter alloc] initWithHandle:fileHandleOut];
      if (fileTypeOut == DBFileFormatXLS)
        [fileWriter setFileFormat:DBFileFormatXLS];
      else
        [fileWriter setFileFormat:DBFileFormatHTML];
    }

  [fileWriter setLogger:logger];
  [fileWriter setWriteFieldsOrdered:writeFieldsOrdered];
  //[fileWriter setStringEncoding: [defaults integerForKey: @"StringEncoding"]];

  /*
  selectIdentProgress = [[DBProgress alloc] init];
  [selectIdentProgress setLogger:logger];
  [selectIdentProgress setProgressIndicator: progIndSelectIdent];
  [selectIdentProgress setRemainingTimeField: fieldRTSelectIdent];
  [selectIdentProgress reset]; */

  [self setupDB:parameters];

  NS_DURING
    [dbCsv queryIdentify :statement queryAll:queryAll fromReader:csvReader toWriter:fileWriter withBatchSize:batchSize progressMonitor:nil];
  NS_HANDLER
    if ([[localException name] hasPrefix:@"DB"])
      {
	[logger log:LogStandard :@"%@", [localException description]];
      }
  NS_ENDHANDLER

  [csvReader release];
  [fileWriter release];
  [fileHandleOut closeFile];

  /*
  [selectIdentProgress release];
  selectIdentProgress = nil;
  [self performSelectorOnMainThread:@selector(resetSelectIdentUI:) withObject:self waitUntilDone:NO];
  */
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
	  /*         [resWriter setStringEncoding: [defaults integerForKey: @"StringEncoding"]];
          str = [defaults stringForKey:@"CSVWriteQualifier"];
          if (str)
            [resWriter setQualifier:str];
         str = [defaults stringForKey:@"CSVWriteSeparator"];
          if (str)
	  [resWriter setSeparator:str]; */

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
  else if ([operation isEqualToString:@"query-identify"])
    [self executeQueryIdentify:context];
  else if ([operation isEqualToString:@"update"])
    [self executeUpdate:context];
  else
    [logger log: LogStandard :@"%@ not recognized as an operation", operation];
}

@end
