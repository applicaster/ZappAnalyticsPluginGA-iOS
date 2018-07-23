//
//  APAnalyticsProviderGoogleAnalytics.h
//  Pods
//
//  Created by Alex Zchut on 17/07/2016.
//
//
@import ZappAnalyticsPluginsSDK;

@class GAI;
@interface APAnalyticsProviderGoogleAnalytics : APAnalyticsProvider

/**
 Returns the sharedInstance of type "GAI *" - declared as id because we can't import this header from an .h file. (it's a static library)
 Google has the weirdest bug that when the sharedInstance method is already being called in one of the modules (libraries) it crashes when calling it again in another library / project. So if you need the Google analytics GAI shared instance call this method in order to get it instead calling directly.
 */
+ (GAI *)gaiSharedInstance;
-(NSUInteger) getIndexForUTM:(NSURL*)url;
-(BOOL) isGACustomDimensionsEnabled;

@end
