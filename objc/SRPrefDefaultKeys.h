/*
SRPrefDefaultKeys.h

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

// Appearance
extern NSString*    SRAllowsAnimatedImages;
extern NSString*    SRLoadsSameDomainImagesAutomatically;

extern NSString*    SRDefaultTextEncoding;

// Bookmark
extern NSString*    SRBookmarkBarType;
extern NSString*    SRBookmarkBarUseMultiLine;
extern NSString*    SRBookmarkMenuUsageFlags;

// Download
extern NSString*    SRDownloadPath;
extern NSString*    SRDownloadSaveInDateDirectory;
extern NSString*    SRDownloadItemRemove;
enum {
    SRDownloadItemRemoveByHand = 0, 
    SRDownloadItemRemoveAutomatically, 
    SRDownloadItemRemoveAtTermination, 
};
extern NSString*    SRDownloadNotification;
enum {
    SRDownloadNotificationShowPanel = 0, 
    SRDownloadNotificationNothing, 
};

// General
extern NSString*    SRGeneralNewWindowsOpenWith;
extern NSString*    SRGeneralNewTabsOpenWith;
enum {
    SRGeneralOpenWithEmptyPage = 0, 
    SRGeneralOpenWithBookmark, 
    SRGeneralOpenWithLastPages, 
};
extern NSString*    SRGeneralBookmark;
extern NSString*    SRGeneralHomePage;
extern NSString*    SRGeneralSession;
extern NSString*    SRGeneralLastPages;
extern NSString*    SRGeneralTimeout;
enum {
    SRGeneralTimeoutOneMinute = 0, 
    SRGeneralTimeoutThreeMinute, 
    SRGeneralTimeoutFiveMinute, 
    SRGeneralTimeoutNever, 
};

// Key binding
extern NSString*    SRKeyBindingStartEditing;
extern NSString*    SRKeyBindingEndEditing;

NSArray* SRExceptionActions();

// RSS
extern NSString*    SRRSSShowArticlesNumber;
extern NSString*    SRRSSUpdates;
enum {
    SRRSSUpdatesHour = 10, 
    SRRSSUpdatesDay = 20, 
    SRRSSUpdatesNever = 999, 
};
extern NSString*    SRRSSRemoveArticles;
enum {
    SRRSSRemoveOneDay = 10, 
    SRRSSRemoveOneWeek = 20, 
    SRRSSRemoveOneMonth = 30, 
    SRRSSRemoveNever = 999, 
};

// Security
extern NSString*    SRSecurityEnableJavaScirptStatusMessage;
extern NSString*    SRSecurityCookieRemoveAtTermination;
extern NSString*    SRSecurityAllowAllURLSchemes;
extern NSString*    SRAutoFillUserPass;

// Source
extern NSString*    SRSourceFontName;
extern NSString*    SRSourceFontSize;
extern NSString*    SRSourceFontNameAndSize;
extern NSString*    SRSourceDefaultColor;
extern NSString*    SRSourceBackgroundColor;
extern NSString*    SRSourceTagColor;
extern NSString*    SRSourceCommentColor;
extern NSString*    SRSourceNumberColor;
extern NSString*    SRSourceKeywordColor;
extern NSString*    SRSourceTransparentWindow;
extern NSString*    SRSourceAlpha;

// Tab
extern NSString*    SRTabStyle;
extern NSString*    SRPageDockStyle;
extern NSString*    SRTabSelectNewTabs;
extern NSString*    SRTabTargetLinkUseTab;
extern NSString*    SRTabOpenURLUseTab;
extern NSString*    SRTabDoubleClick;
enum {
    SRTabDoubleClickReload = 0, 
    SRTabDoubleClickClose, 
    SRTabDoubleClickNone, 
};

// Theme
extern NSString*    SRThemeAquaIconNameKey;
extern NSString*    SRThemeMetalIconNameKey;

// Universal access
extern NSString*    SRUniversalAccessScaling;
extern NSString*    SRUniversalAccessScalingEnabled;

extern NSString*    SRUniversalAccessPlaySoundEffect;
extern NSString*    SRUniversalAccessSoundPageLoadDone;
extern NSString*    SRUniversalAccessSoundPageLoadError;
extern NSString*    SRUniversalAccessSoundJavaScriptDialog;
