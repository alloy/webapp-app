/*
SRAutoFillManager.m

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

#import "SRAutoFillManager.h"

#import "SRPrefDefaultKeys.h"

// File names
NSString*   SRFormContentsFileName = @"FormContents.plist";

@implementation SRAutoFillManager

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (SRAutoFillManager*)sharedInstance
{
    static SRAutoFillManager*   _sharedInstance = nil;
    if (!_sharedInstance) {
        _sharedInstance = [[SRAutoFillManager alloc] init];
        
        // Load forms
        [_sharedInstance loadForms];
    }
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _formContents = [[NSMutableDictionary dictionary] retain];
    
    return self;
}

//--------------------------------------------------------------//
#pragma mark -- Form contents --
//--------------------------------------------------------------//

- (NSDictionary*)formContents
{
    return _formContents;
}

//--------------------------------------------------------------//
#pragma mark -- Fill forms --
//--------------------------------------------------------------//

- (DOMHTMLInputElement*)_inputElmentFromElements:(NSArray*)elements ofName:(NSString*)name
{
    NSEnumerator*           enumerator;
    DOMHTMLInputElement*    element;
    enumerator = [elements objectEnumerator];
    while (element = [enumerator nextObject]) {
        if ([name isEqualToString:[element name]]) {
            return element;
        }
    }
    
    return nil;
}

- (void)_fillFormsByKeychainWithWebFrame:(WebFrame*)webFrame 
        textInputNodes:(NSArray*)textInputNodes 
        passInputNodes:(NSArray*)passInputNodes
{
    // Get server name
    NSURL*      URL;
    NSString*   serverName;
    NSString*   path;
    NSString*   scheme;
    URL = [[[webFrame dataSource] request] URL];
    serverName = [URL host];
    if (!serverName || [serverName length] == 0) {
        return;
    }
    path = [URL path];
    if (!path) {
        path = @"";
    }
    scheme = [URL scheme];
    
    // Check in form contents
    NSString*       key;
    NSDictionary*   formContent;
    key = [NSString stringWithFormat:@"%@://%@%@", scheme, serverName, path];
    formContent = [_formContents objectForKey:key];
    if (!formContent) {
        return;
    }
    
    // Get info from dict
    SecProtocolType protocolType;
    NSArray*        textInputNodeDicts;
    NSArray*        passInputNodeDicts;
    protocolType = [[formContent objectForKey:@"protocol"] longValue];
    textInputNodeDicts = [formContent objectForKey:@"textInputNodeDicts"];
    passInputNodeDicts = [formContent objectForKey:@"passInputNodeDicts"];
    if (!textInputNodeDicts || !passInputNodeDicts) {
        return;
    }
    
    // Fill text nodes
    NSEnumerator*   enumerator;
    NSDictionary*   dict;
    enumerator = [textInputNodeDicts objectEnumerator];
    while (dict = [enumerator nextObject]) {
        NSString*   textInputNodeName;
        NSString*   value;
        textInputNodeName = [dict objectForKey:@"textInputNodeName"];
        value = [dict objectForKey:@"value"];
        if (!textInputNodeName || !value) {
            continue;
        }
        
        // Get text input node
        DOMHTMLInputElement*    textInputNode;
        textInputNode = [self _inputElmentFromElements:textInputNodes ofName:textInputNodeName];
        if (!textInputNode) {
            continue;
        }
        
        // Fill form
        [textInputNode setValue:value];
    }
    
    // Fill password nodes
    enumerator = [passInputNodeDicts objectEnumerator];
    while (dict = [enumerator nextObject]) {
        NSString*   passInputNodeName;
        NSString*   accountName;
        passInputNodeName = [dict objectForKey:@"passInputNodeName"];
        accountName = [dict objectForKey:@"accountName"];
        if (!passInputNodeName || !accountName) {
            continue;
        }
        
        // Get pass input node
        DOMHTMLInputElement*    passInputNode;
        passInputNode = [self _inputElmentFromElements:passInputNodes ofName:passInputNodeName];
        if (!passInputNode) {
            continue;
        }
        
        // Get password
        OSStatus            status;
        UInt32              passLength;
        void*               pass;
        SecKeychainItemRef  keychainItem;
        status = SecKeychainFindInternetPassword(
                NULL, 
                strlen([serverName UTF8String]), 
                [serverName UTF8String], 
                0, 
                NULL, 
                strlen([accountName UTF8String]), 
                [accountName UTF8String], 
                strlen([path UTF8String]), 
                [path UTF8String], 
                0, 
                protocolType, 
                kSecAuthenticationTypeHTMLForm, 
                &passLength, 
                &pass, 
                &keychainItem);
        if (status != noErr) {
            continue;
        }
        
        // Fill form
        if (pass && passLength > 0) {
            NSString*   passString;
            passString = [[NSString alloc] 
                    initWithBytes:pass length:passLength encoding:NSUTF8StringEncoding];
            if (passString) {
                [passInputNode setValue:passString];
                [passString release];
            }
        }
    }
}

- (void)_fillFormsWithWebFrame:(WebFrame*)webFrame
{
    // Get form nodes
    DOMDocument*    document;
    DOMNodeList*    formNodeList;
    document = [webFrame DOMDocument];
    formNodeList = [document getElementsByTagName:@"FORM"];
    
    int i;
    for (i = 0; i < [formNodeList length]; i++) {
        DOMHTMLFormElement* formNode;
        formNode = (DOMHTMLFormElement*)[formNodeList item:i];
        
        // Get input nodes
        DOMNodeList*    inputNodeList;
        inputNodeList = [formNode getElementsByTagName:@"INPUT"];
        
        // Collect text and password input node
        NSMutableArray* textInputNodes;
        NSMutableArray* passInputNodes;
        textInputNodes = [NSMutableArray array];
        passInputNodes = [NSMutableArray array];
        
        int j;
        for (j = 0; j < [inputNodeList length]; j++) {
            DOMHTMLInputElement*    inputNode;
            inputNode = (DOMHTMLInputElement*)[inputNodeList item:j];
            
            NSString*   type;
            type = [inputNode type];
            
            if ([type isEqualToString:@"text"]) {
                [textInputNodes addObject:inputNode];
            }
            if ([type isEqualToString:@"password"]) {
                [passInputNodes addObject:inputNode];
            }
        }
        
        // If it has password, use keychain
        if ([textInputNodes count] > 0 && [passInputNodes count] > 0) {
            [self _fillFormsByKeychainWithWebFrame:webFrame 
                    textInputNodes:textInputNodes 
                    passInputNodes:passInputNodes];
        }
        
#if 0
        // Fill form contents
        if ([textInputNodes count] > 0) {
            //[self _registerFormsWithWebFrame:webFrame 
            //        textInputNodes:textInputNodes passInputNodes:passInputNodes];
        }
#endif
    }
    
    // Register for child frames
    NSArray*        childFrames;
    NSEnumerator*   enumerator;
    WebFrame*       childFrame;
    childFrames = [webFrame childFrames];
    enumerator = [childFrames objectEnumerator];
    while (childFrame = [enumerator nextObject]) {
        [self _fillFormsWithWebFrame:childFrame];
    }
}

- (void)fillFormsWithWebView:(WebView*)webView
{
    // Check preference
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SRAutoFillUserPass]) {
        return;
    }
    
    [self _fillFormsWithWebFrame:[webView mainFrame]];
}

//--------------------------------------------------------------//
#pragma mark -- Register form contents --
//--------------------------------------------------------------//

- (void)_registerFormsToKeychainWithWebFrame:(WebFrame*)webFrame 
        textInputNodes:(NSArray*)textInputNodes 
        passInputNodes:(NSArray*)passInputNodes
{
    // Check arguments
    if ([textInputNodes count] == 0 || [passInputNodes count] == 0) {
        return;
    }
    
    // Get server name and path
    NSURL*      URL;
    NSString*   serverName;
    NSString*   path;
    URL = [[[webFrame dataSource] request] URL];
    serverName = [URL host];
    path = [URL path];
    if (!serverName || [serverName length] == 0) {
        return;
    }
    
    // Get first account name
    NSString*   accountName;
    accountName = [[textInputNodes objectAtIndex:0] value];
    if (!accountName || [accountName length] == 0) {
        return;
    }
    
    // Get protocol type
    NSString*       scheme;
    SecProtocolType protocolType;
    scheme = [URL scheme];
    if ([scheme isEqualToString:@"http"]) {
        protocolType = kSecProtocolTypeHTTP;
    }
    else if ([scheme isEqualToString:@"https"]) {
        protocolType = kSecProtocolTypeHTTPS;
    }
    else if ([scheme isEqualToString:@"ftp"]) {
        protocolType = kSecProtocolTypeFTP;
    }
    else {
        protocolType = kSecProtocolTypeHTTP;
    }
    
    // Register passwords
    int i;
    for (i = 0; i < [passInputNodes count]; i++) {
        // Get password
        NSString*   password;
        password = [[passInputNodes objectAtIndex:i] value];
        if (!password || [password length] == 0) {
            continue;
        }
        
        // Decide account name
        NSString*   accName;
        accName = accountName;
        if (i > 0) {
            accName = [NSString stringWithFormat:@"%@%d", accountName, i];
        }
        
        // First, find it
        OSStatus            status;
        UInt32              passLength;
        void*               pass;
        SecKeychainItemRef  keychainItem;
        status = SecKeychainFindInternetPassword(
                NULL, 
                strlen([serverName UTF8String]), 
                [serverName UTF8String], 
                0, 
                NULL, 
                strlen([accName UTF8String]), 
                [accName UTF8String], 
                strlen([path UTF8String]), 
                [path UTF8String], 
                0, 
                protocolType, 
                kSecAuthenticationTypeHTMLForm, 
                &passLength, 
                &pass, 
                &keychainItem);
        if (status == noErr) {
            // Check password
            if (strncmp(pass, [password UTF8String], passLength) == 0) {
                continue;
            }
            
            // Delete old password
            status = SecKeychainItemDelete(keychainItem);
            if (status != noErr) {
                // Error
                NSLog(@"Failed to SecKeychainItemDelete, %d", status);
            }
            CFRelease(keychainItem);
        }
        
        // Register to keychain
        status = SecKeychainAddInternetPassword(
                NULL, 
                strlen([serverName UTF8String]), 
                [serverName UTF8String], 
                0, 
                NULL, 
                strlen([accName UTF8String]), 
                [accName UTF8String], 
                strlen([path UTF8String]), 
                [path UTF8String], 
                0, 
                protocolType, 
                kSecAuthenticationTypeHTMLForm, 
                strlen([password UTF8String]), 
                [password UTF8String], 
                NULL);
        if (status != noErr) {
            // Error
            NSLog(@"Failed to SecKeychainAddInternetPassword, %d", status);
        }
    }
    
    // Register to form contents dict
    NSString*   key;
    key = [NSString stringWithFormat:@"%@://%@%@", scheme, serverName, path];
    
    NSMutableArray* textInputNodeDicts;
    textInputNodeDicts = [NSMutableArray array];
    for (i = 0; i < [textInputNodes count]; i++) {
        DOMHTMLInputElement*    textInputNode;
        textInputNode = [textInputNodes objectAtIndex:i];
        
        NSString*   name;
        NSString*   value;
        name = [textInputNode name];
        value = [textInputNode value];
        if (!name) {
            name = @"";
        }
        if (!value) {
            value = @"";
        }
        
        [textInputNodeDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                name, @"textInputNodeName", value, @"value", nil]];
    }
    
    NSMutableArray* passInputNodeDicts;
    passInputNodeDicts = [NSMutableArray array];
    for (i = 0; i < [passInputNodes count]; i++) {
        DOMHTMLInputElement*    passInputNode;
        passInputNode = [passInputNodes objectAtIndex:i];
        
        NSString*   name;
        NSString*   accName;
        name = [passInputNode name];
        if (!name) {
            name = @"";
        }
        accName = accountName;
        if (i > 0) {
            accName = [NSString stringWithFormat:@"%@%d", accountName, i];
        }
        
        [passInputNodeDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                name, @"passInputNodeName", accName, @"accountName", nil]];
    }
    
    NSDictionary*   dict;
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithLong:protocolType], @"protocol", 
            passInputNodeDicts, @"passInputNodeDicts", 
            textInputNodeDicts, @"textInputNodeDicts", 
            nil];
    
    [_formContents setObject:dict forKey:key];
    
    // Save form
    [self saveForms];
}

- (void)_registerFormsWithWebFrame:(WebFrame*)webFrame 
        textInputNodes:(NSArray*)textInputNodes 
        passInputNodes:(NSArray*)passInputNodes
{
    // Check arguments
    if ([textInputNodes count] == 0) {
        return;
    }
    
    // Get URL string
    NSString*   URLString;
    URLString = [[[[webFrame dataSource] request] URL] absoluteString];
    if (!URLString) {
        return;
    }
    
    // Create form contents dict
    NSMutableDictionary*    contentsDict;
    contentsDict = [NSMutableDictionary dictionary];
    
    [contentsDict setObject:URLString forKey:@"URL"];
    
    // For text input nodes
    NSMutableArray*         array;
    NSEnumerator*           enumerator;
    DOMHTMLInputElement*    inputNode;
    array = [NSMutableArray array];
    enumerator = [textInputNodes objectEnumerator];
    while (inputNode = [enumerator nextObject]) {
        NSString*   name;
        NSString*   value;
        name = [inputNode name];
        value = [inputNode value];
        if (name && [name length] > 0 && value && [value length] > 0) {
            NSMutableDictionary*    dict;
            dict = [NSMutableDictionary dictionary];
            
            [dict setObject:@"text" forKey:@"type"];
            [dict setObject:name forKey:@"name"];
            [dict setObject:value forKey:@"value"];
            
            [array addObject:dict];
        }
    }
    
    if ([array count] > 0) {
        [contentsDict setObject:array forKey:@"textInputNodes"];
    }
    
    // For password input nodes
    array = [NSMutableArray array];
    enumerator = [textInputNodes objectEnumerator];
    while (inputNode = [enumerator nextObject]) {
        NSString*   name;
        name = [inputNode name];
        if (name) {
            NSMutableDictionary*    dict;
            dict = [NSMutableDictionary dictionary];
            
            [dict setObject:@"pass" forKey:@"type"];
            [dict setObject:name forKey:@"name"];
            
            [array addObject:dict];
        }
    }
    
    if ([array count] > 0) {
        [contentsDict setObject:array forKey:@"passInputNodes"];
    }
}

- (void)_registerFormsWithWebFrame:(WebFrame*)webFrame
{
    // Get form nodes
    DOMDocument*    document;
    DOMNodeList*    formNodeList;
    document = [webFrame DOMDocument];
    formNodeList = [document getElementsByTagName:@"FORM"];
    
    int i;
    for (i = 0; i < [formNodeList length]; i++) {
        DOMHTMLFormElement* formNode;
        formNode = (DOMHTMLFormElement*)[formNodeList item:i];
        
        // Get input nodes
        DOMNodeList*    inputNodeList;
        inputNodeList = [formNode getElementsByTagName:@"input"];
        
        // Collect text and password input node
        NSMutableArray* textInputNodes;
        NSMutableArray* passInputNodes;
        textInputNodes = [NSMutableArray array];
        passInputNodes = [NSMutableArray array];
        
        int j;
        for (j = 0; j < [inputNodeList length]; j++) {
            DOMHTMLInputElement*    inputNode;
            inputNode = (DOMHTMLInputElement*)[inputNodeList item:j];
            
            NSString*   type;
            type = [inputNode type];
            
            if ([type isEqualToString:@"text"]) {
                [textInputNodes addObject:inputNode];
            }
            if ([type isEqualToString:@"password"]) {
                [passInputNodes addObject:inputNode];
            }
        }
        
        // If it has password, use keychain
        if ([textInputNodes count] > 0 && [passInputNodes count] > 0) {
            [self _registerFormsToKeychainWithWebFrame:webFrame 
                    textInputNodes:textInputNodes 
                    passInputNodes:passInputNodes];
        }
        
#if 0
        // Register form contents
        if ([textInputNodes count] > 0) {
            [self _registerFormsWithWebFrame:webFrame 
                    textInputNodes:textInputNodes passInputNodes:passInputNodes];
        }
#endif
    }
    
    // Register for child frames
    NSArray*        childFrames;
    NSEnumerator*   enumerator;
    WebFrame*       childFrame;
    childFrames = [webFrame childFrames];
    enumerator = [childFrames objectEnumerator];
    while (childFrame = [enumerator nextObject]) {
        [self _registerFormsWithWebFrame:childFrame];
    }
}

- (void)registerFormsWithWebView:(WebView*)webView
{
    // Check preference
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SRAutoFillUserPass]) {
        return;
    }
    
    [self _registerFormsWithWebFrame:[webView mainFrame]];
}

//--------------------------------------------------------------//
#pragma mark -- Persistence --
//--------------------------------------------------------------//

- (void)loadABMappings
{
}

- (NSString*)formContentsPath
{
    // Create path ~/Library/Application Support/Shiira/FormContents.plist
    NSString*	formContentsPath;
    formContentsPath = [HMApplicationSupportFolder(@"Shiira") 
            stringByAppendingPathComponent:SRFormContentsFileName];
    if (!formContentsPath) {
        return nil;
    }
    
    return formContentsPath;
}

- (void)loadForms
{
    // Get form contents path
    NSString*	formContentsPath;
    formContentsPath = [self formContentsPath];
    
    // Check existense
    NSFileManager*	fileMgr;
    fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:formContentsPath]) {
        return;
    }
    
    // Load form contents
    NSData* data;
    data = [NSData dataWithContentsOfFile:formContentsPath];
    if (data) {
        NSMutableDictionary*    formContents;
        formContents = [NSPropertyListSerialization propertyListFromData:data 
                mutabilityOption:NSPropertyListMutableContainersAndLeaves 
                format:NULL 
                errorDescription:NULL];
        if (formContents) {
            [_formContents release];
            _formContents = [formContents retain];
        }
    }
}

- (void)saveForms
{
    // Get form contents path
    NSString*	formContentsPath;
    formContentsPath = [self formContentsPath];
    
    // Check existense
    NSFileManager*	fileMgr;
    fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:formContentsPath]) {
        // Create file
        HMCreateFile(formContentsPath);
    }
    
    // Save form contents
    NSData* data;
    data = [NSPropertyListSerialization dataFromPropertyList:_formContents 
            format:NSPropertyListBinaryFormat_v1_0 
            errorDescription:NULL];
    if (!data) {
        // Error
        return;
    }
    [data writeToFile:formContentsPath atomically:YES];
}

@end
