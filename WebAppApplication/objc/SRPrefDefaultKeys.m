/*
SRIconManager.m

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

#import "SRPrefDefaultKeys.h"

// Appearance
NSString*   SRAllowsAnimatedImages = @"allowsAnimatedImages";
NSString*   SRLoadsSameDomainImages = @"loadsSameDomainImagesAutomatically";

NSString*   SRDefaultTextEncoding = @"defaultTextEncoding";

// General
NSString*   SRGeneralNewWindowsOpenWith = @"generalNewWindowsOpenWith";
NSString*   SRGeneralNewTabsOpenWith = @"generalNewTabsOpenWith";
NSString*   SRGeneralBookmark = @"generalBookmark";
NSString*   SRGeneralHomePage = @"generalHomePage";
NSString*   SRGeneralSession = @"generalSession";
NSString*   SRGeneralLastPages = @"generalLastPages";
NSString*   SRGeneralTimeout = @"generalTimeout";

// Bookmark
NSString*   SRBookmarkBarType = @"bookmarkBarType";
NSString*   SRBookmarkBarUseMultiLine = @"bookmarkBarUseMultiLine";
NSString*   SRBookmarkMenuUsageFlags = @"bookmarkUsageFlags";

// Download
NSString*   SRDownloadPath = @"downloadPath";
NSString*   SRDownloadSaveInDateDirectory = @"downloadSaveInDateDirectory";
NSString*   SRDownloadItemRemove = @"downloadItemRemove";
NSString*   SRDownloadNotification = @"downloadNotification";

// Key binding
NSString*   SRKeyBindingStartEditing = @"SRKeyBindingStartEditing";
NSString*   SRKeyBindingEndEditing = @"SRKeyBindingEndEditing";

NSArray* SRExceptionActions()
{
    static NSArray* _exceptionActions = nil;
    
    if (!_exceptionActions) {
        _exceptionActions = [[NSArray arrayWithObjects:
                @"closeWindowAction:", 
                @"closeTabAction:", 
                @"orderFrontCharacterPalette:", 
                @"openHistoryItemAction:", 
                @"openBookmarkAction:", 
                @"arrangeInFront:", 
                @"alternateArrangeInFront:", 
                @"makeKeyAndOrderFront:", 
                nil] retain];
    }
    
    return _exceptionActions;
}

// RSS
NSString*   SRRSSShowArticlesNumber = @"rssShowArticlesNumber";
NSString*   SRRSSUpdates = @"rssUpdates";
NSString*   SRRSSRemoveArticles = @"rssRemoveArticles";

// Security
NSString*   SRSecurityEnableJavaScirptStatusMessage = @"enableJavaScirptStatusMessage";
NSString*   SRSecurityCookieRemoveAtTermination = @"cookieRemoveAtTermination";
NSString*   SRSecurityAllowAllURLSchemes = @"securityAllowAllURLSchemes";
NSString*   SRAutoFillUserPass = @"autoFillUserPass";

// Source
NSString*   SRSourceFontName = @"sourceFontName";
NSString*   SRSourceFontSize = @"sourceFontSize";
NSString*   SRSourceFontNameAndSize = @"sourceFontNameAndSize";
NSString*   SRSourceDefaultColor = @"sourceDefaultColor";
NSString*   SRSourceBackgroundColor = @"sourceBackgroundColor";
NSString*   SRSourceTagColor = @"sourceTagColor";
NSString*   SRSourceCommentColor = @"sourceCommentColor";
NSString*   SRSourceNumberColor = @"sourceNumberColor";
NSString*   SRSourceKeywordColor = @"sourceKeywordColor";
NSString*   SRSourceTransparentWindow = @"sourceTransparent";
NSString*   SRSourceAlpha = @"sourceAlpha";

// Tab
NSString*   SRTabStyle = @"tabStyle";
NSString*   SRPageDockStyle = @"pageDockStyle";
NSString*   SRTabSelectNewTabs = @"tabSelectNewTabs";
NSString*   SRTabTargetLinkUseTab = @"tabTargetLinkUseTab";
NSString*   SRTabOpenURLUseTab = @"tabOpenURLUseTab";
NSString*   SRTabDoubleClick = @"tabDoubleClick";

// Theme
NSString*   SRThemeAquaIconNameKey = @"SRThemeAquaIconNameKey";
NSString*   SRThemeMetalIconNameKey = @"SRThemeMetalIconNameKey";

// Universal access
NSString*   SRUniversalAccessScaling = @"scaling";
NSString*   SRUniversalAccessScalingEnabled = @"scalingEnabled";

NSString*   SRUniversalAccessPlaySoundEffect = @"playSoundEffect";
NSString*   SRUniversalAccessSoundPageLoadDone = @"soundPageLoadDone";
NSString*   SRUniversalAccessSoundPageLoadError = @"soundPageLoadError";
NSString*   SRUniversalAccessSoundJavaScriptDialog = @"soundJavaScriptDialog";
