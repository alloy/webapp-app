/*
HMFoundationUtil.h

Author: Makoto Kinoshita

Copyright 2004-2006 The Shiira Project. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted 
provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE SHIIRA PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE SHIIRA PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>

// String
#define UTF8STR(str) \
        [NSString stringWithUTF8String:(str)]
NSString* HMCreateUUID();
NSString* HMTruncateString(
        NSString* string, int trunctedLength, NSLineBreakMode breakMode);

// File operations
BOOL HMCreateFile(
        NSString* filePath);
BOOL HMCreateDirectoryFile(
        NSString* filePath, 
        BOOL directory);
NSString* HMCreateUniqueFileName(
        NSString* fileExtension);
NSString* HMMakeFilePathUnique(
        NSString* dirPath, 
        NSString* baseName, 
        NSString* extension);

NSString* HMApplicationSupportFolder(
        NSString* appName);

NSString* HMRemoveProhibitedCharactersFromPath(
        NSString* path);

NSArray* HMSoundFilePaths();

// URL
BOOL HMIsRSSURL(
        NSURL* url);
BOOL HMIsRSSURLString(
        NSString* URLString);
NSURL* HMSwapSchemeFeedToHttp(
        NSURL* url);
NSString* HMSwapSchemeStringFeedToHttp(
        NSString* urlString);
BOOL HMIsJavaScriptURL(
        NSURL* url);
BOOL HMIsJavaScriptURLString(
        NSString* URLString);

// Sorting
NSArray* HMSortWithKey(
        NSArray* array, NSString* key, BOOL ascending);

// Data size
NSString* HMDataSizeString(
        long long dataSize);
NSString* HMTimeString(
        int time);

// XML
NSString* HMReplaceXMLPhysicalEntitys(
        NSString* string);
NSString* HMRestoreXMLPhysicalEntitys(
        NSString* string);
