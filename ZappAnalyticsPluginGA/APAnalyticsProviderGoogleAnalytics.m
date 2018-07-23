//
//  APAnalyticsProviderGoogleAnalytics.m
//  Pods
//
//  Created by Alex Zchut on 17/07/2016.
//
//

#import "APAnalyticsProviderGoogleAnalytics.h"
#import <GoogleAnalytics/GAI.h>
#import <GoogleAnalytics/GAIDictionaryBuilder.h>
#import <GoogleAnalytics/GAIFields.h>

@import ZappPlugins;

NSString *const kGaApiKeyParam = @"mobile_app_account_id";
NSString *const kGaCustomDimentionsParam = @"custom_dimensions_enabled";
NSString *const kGaAnonymizeUserIpParam = @"anonymize_user_ip";
NSString *const kGaScreenViewsParam = @"screen_views_enabled";
NSString *const kGaCustomDimentionsPrefix = @"custom_dimension_index_";

@interface APAnalyticsProviderGoogleAnalytics () {
    
}

@property (nonatomic, readwrite) BOOL isGACustomDimensionsEnabled;
@property (nonatomic, readwrite) BOOL isGAScreenViewEnabled;

@end

@implementation APAnalyticsProviderGoogleAnalytics

- (NSString*) getKey {
    return @"google_analytics";
}

- (BOOL)createAnalyticsProviderSettings {
    BOOL retVal = NO;
    
    if ([self.providerProperties isKindOfClass:[NSDictionary class]]) {
        if ([self.providerProperties[kGaApiKeyParam] isKindOfClass:[NSString class]]) {
            [[GAI sharedInstance] trackerWithTrackingId:self.providerProperties[kGaApiKeyParam]];
        }
        
        if ([[self.providerProperties valueForKey:kGaAnonymizeUserIpParam] boolValue]) {
            [[GAI sharedInstance].defaultTracker set:kGAIAnonymizeIp value:@"1"];
        }
        
        if ([[self.providerProperties valueForKey:kGaCustomDimentionsParam] boolValue]) {
            self.isGACustomDimensionsEnabled = YES;
        }
        
        self.isGAScreenViewEnabled = ([[self.providerProperties valueForKey:kGaScreenViewsParam] boolValue]);
        [GAI sharedInstance].trackUncaughtExceptions = NO;
        [GAI sharedInstance].dispatchInterval = 15;
        [GAI sharedInstance].defaultTracker.allowIDFACollection = YES;
        
        
#ifdef DEBUG
        [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
#endif
        retVal = YES;
    }
    
    return retVal;
}

#pragma mark - Track Events
-(void)trackCampaignParamsFromUrl:(NSURL *)url {
    
    NSUInteger index= [self getIndexForUTM:url];
    
    //perform only if there are utm parameters in url
    if (index != NSNotFound) {
        NSString *urlString = [url absoluteString];
        
        // setCampaignParametersFromUrl: parses Google Analytics campaign ("UTM")
        // parameters from a string url into a Map that can be set on a Tracker.
        GAIDictionaryBuilder *hitParams = [[GAIDictionaryBuilder alloc] init];
        
        // Set campaign data on the map, not the tracker directly because it only
        // needs to be sent once.
        [hitParams setCampaignParametersFromUrl:urlString];
        
        // Campaign source is the only required campaign field. If previous call
        // did not set a campaign source, use the hostname as a referrer instead.
        if(![hitParams get:kGAICampaignSource] && [url host].length !=0) {
            // Set campaign data on the map, not the tracker.
            [hitParams set:@"referrer" forKey:kGAICampaignMedium];
            [hitParams set:[url host] forKey:kGAICampaignSource];
        }
        
        NSDictionary *hitParamsDict = [hitParams build];
        
        [[[GAI sharedInstance] defaultTracker] send:[[[GAIDictionaryBuilder createScreenView] setAll:hitParamsDict] build]];
    }
}

- (void)trackEvent:(NSString *)eventName{
    NSString *analyticsString = [self analyticsStringFromDictionary:self.defaultEventProperties];
    NSArray *eventSeparated = [self eventSeparated:eventName];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:[eventSeparated firstObject]
                                                                                        action:[eventSeparated lastObject]
                                                                                         label:analyticsString
                                                                                         value:[NSNumber numberWithInteger:0]] build]];
}

- (void)trackEvent:(NSString *)eventName parameters:(NSDictionary *)parameters {
    [super trackEvent:eventName parameters:parameters];

    parameters = [self combineProperties:parameters shouldIncludeExtraParams:YES];
    NSString *analyticsString = [self analyticsStringFromDictionary:parameters];
    NSArray *eventSeparated = [self eventSeparated:eventName];
    
    //adding the custom dimensions
    NSDictionary *dictCustomDimensions = [self getCustomDimensionsForParameters:parameters];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [self addCustomDimensions:dictCustomDimensions toTracker:tracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:[eventSeparated firstObject]
                                                                                        action:[eventSeparated lastObject]
                                                                                         label:analyticsString
                                                                                         value:[NSNumber numberWithInteger:0]] build]];
    //clearing the custom dimensions
    [self removeCustomDimensions:dictCustomDimensions fromTracker:tracker];
    
}

- (void)trackEvent:(NSString *)eventName timed:(BOOL)timed{
    [self trackEvent:eventName];
}

- (void)trackEvent:(NSString *)eventName parameters:(NSDictionary *)parameters timed:(BOOL)timed{
    [self trackEvent:eventName parameters:parameters];
}

- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label value:(NSInteger)value {
    NSString *analyticsString = [NSString stringWithFormat:@"%@;%@]",label,[self analyticsStringFromDictionary:self.defaultEventProperties]];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:event
                                                                                        action:action
                                                                                         label:analyticsString
                                                                                         value:[NSNumber numberWithInteger:value]] build]];
}

- (void)trackScreenView:(NSString *)screenName parameters:(NSDictionary *)parameters {
    if(self.isGAScreenViewEnabled){
        parameters = [self combineProperties:parameters shouldIncludeExtraParams:NO];

        // This screen name value will remain set on the tracker and sent with
        // hits until it is set to a new value or to nil.
        [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:screenName];
        
        //adding the custom dimensions
        NSDictionary *dictCustomDimensions = [self getCustomDimensionsForParameters:parameters];
        [self addCustomDimensions:dictCustomDimensions toTracker:[[GAI sharedInstance] defaultTracker]];
        
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createScreenView] build]];
        [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:nil];
        
        //clearing the custom dimensions
        [self removeCustomDimensions:dictCustomDimensions fromTracker:[[GAI sharedInstance] defaultTracker]];
    }
}

- (NSDictionary *) combineProperties:(NSDictionary *)properties shouldIncludeExtraParams:(BOOL)shouldIncludeExtraParams {
    //combine with default event properites
    NSDictionary *combinedWithDefaultParameters = [ZPAnalyticsProvider defaultProperties:self.defaultEventProperties
                                                                 combinedWithEventParams:properties
                                                                shouldIncludeExtraParams:shouldIncludeExtraParams];

    //set mutable dictionary
    NSMutableDictionary *combinedDictionary = [NSMutableDictionary dictionaryWithDictionary:combinedWithDefaultParameters];

    return [combinedDictionary copy];
}

#pragma mark - Public

+ (GAI*)gaiSharedInstance{
    return [GAI sharedInstance];
}

#pragma mark Private Methods

- (NSArray *)eventSeparated:(NSString *)eventName {
    NSArray *eventSeparated = [eventName componentsSeparatedByString:@":"];
    if ([eventSeparated count] == 1) {
        eventSeparated = [eventName componentsSeparatedByString:@"-"];
    }
    
    if ([eventSeparated count] > 1) {
        NSString *string = eventSeparated[0];
        
        if([string hasPrefix:@" "]) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:eventSeparated];
            string = [string substringFromIndex:1];
            newArray[0] = string;
            eventSeparated = [newArray copy];
        }
        
        if([string hasSuffix:@" "]) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:eventSeparated];
            string = [string substringToIndex:[string length] - 1];
            newArray[0] = string;
            eventSeparated = [newArray copy];
        }
        
        string = eventSeparated[1];
        
        if([string hasPrefix:@" "]) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:eventSeparated];
            string = [string substringFromIndex:1];
            newArray[1] = string;
            eventSeparated = [newArray copy];
        }
        
        if([string hasSuffix:@" "]) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:eventSeparated];
            string = [string substringToIndex:[string length] - 1];
            newArray[1] = string;
            eventSeparated = [newArray copy];
        }
    }
    
    return eventSeparated;
}

- (NSString *)analyticsStringFromDictionary:(NSDictionary *)dictionary {
    NSString *retVal = @"N/A";
    NSMutableString *newString = nil;
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        newString = [NSMutableString new];
        NSArray * sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
        for (id key in sortedKeys) {
            if ([dictionary[key] isKindOfClass:[NSString class]]) {
                [newString appendString:[NSString stringWithFormat:@"%@=%@;", key, dictionary[key]]];
            }
        }
    }
    
    if ([newString length] > 0) {
        [newString deleteCharactersInRange:NSMakeRange([newString length]-1, 1)];
        retVal = [newString copy];
    }
    
    return retVal;
}

-(NSUInteger) getIndexForUTM:(NSURL*)url {
    NSUInteger index = [[[url queryDictionary] allKeys] indexOfObjectPassingTest:^BOOL(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([key localizedCaseInsensitiveContainsString:@"utm"]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    return index;
}

#pragma mark - Custom dimensions
- (NSDictionary *) getCustomDimensionsForParameters:(NSDictionary *)parameters {
    NSMutableDictionary *dictRetValue = [NSMutableDictionary dictionary];
    //get the list of params for prefix
    NSDictionary *dictRemoteConfigMatchingListOfParams = [self getFirebaseRemoteConfigurationParametersWithPrefix: kGaCustomDimentionsPrefix forEventParameters: parameters];
    
    [dictRemoteConfigMatchingListOfParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL * _Nonnull stop) {
        //get an index
        NSInteger customDimensionIndex = [[key stringByReplacingOccurrencesOfString:kGaCustomDimentionsPrefix withString:@""] integerValue];
        //get custom dimension key for index
        NSString *gaEventKey = [GAIFields customDimensionForIndex:customDimensionIndex];
        
        //if key found add this to return dict
        if (customDimensionIndex > -1 && gaEventKey) {
            [dictRetValue setValue:obj forKey:gaEventKey];
        }
    }];

    return dictRetValue;
}

- (void) addCustomDimensions:(NSDictionary*)dict toTracker:(id<GAITracker>)tracker {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [tracker set:key value:value];
    }];
}

- (void) removeCustomDimensions:(NSDictionary*)dict fromTracker:(id<GAITracker>)tracker {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [tracker set:key value:nil];
    }];
}

@end
