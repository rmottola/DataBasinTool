/*
   Project: DataBasinTool

   Author: multix

   Created: 2021-05-04 02:39:34 +0200 by multix
*/

#import <Foundation/Foundation.h>

#import "ToolController.h"

void parseParametersFile(NSString *filePath, NSMutableDictionary *pDict)
{
  NSDictionary *readDict;
  
  NSLog(@"opening %@", filePath);
  readDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
  if (readDict == nil)
    {
      NSLog(@"Error reading parameter file");
      exit(-1);
    }
  NSLog(@"read: %@", readDict);
  [pDict addEntriesFromDictionary: readDict];
}

int
main(int argc, const char *argv[])
{
  NSMutableDictionary *argumentsDict;
  int i;
  ToolController *toolController;
  id pool = [[NSAutoreleasePool alloc] init];
  
  // command parameters dictionary
  // set by file or overriden by command arguments
  NSMutableDictionary *operationDict;
  
  // Parameters settable by arguments
  NSString *parametersFile;
  NSString *inputFileName;
  NSString *outputFileName;
  NSString *operation;
  NSString *token;
  int      upBatchSize;
  int      downBatchSize;
  
  // final context dictionary
  NSMutableDictionary *contextDict;
  
  // something is very wrong
  if (argc < 1)
    exit(-1);

  argumentsDict = [[NSMutableDictionary alloc] init];
  i=1;
  while (i < argc)
    {
      const char *command;
      const char *argument;
      
      command = argv[i];
      if (i+1 < argc)
        {
          NSString *commandStr;
          NSString *argumentStr;
          
          argument = argv[i+1];
          commandStr = [NSString stringWithCString:command];
          argumentStr = [NSString stringWithCString:argument];
          [argumentsDict setObject:argumentStr forKey:commandStr];
        }
      
      i += 2;
    }
  NSLog(@"parsed parameters are: %@", argumentsDict);
  
  operationDict = [[NSMutableDictionary alloc] init];
  
  parametersFile = [argumentsDict objectForKey:@"-pf"];
  if (parametersFile)
    parseParametersFile(parametersFile, operationDict);
  
  contextDict = [[NSMutableDictionary alloc] init];
  [contextDict addEntriesFromDictionary: operationDict];
  
  toolController = [[ToolController alloc] init];
  [toolController executeCommandWithContext:contextDict];
  [toolController release];
  
  [pool release];

  return 0;
}

