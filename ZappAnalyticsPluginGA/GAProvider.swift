//
//  GAProvider.swift
//  ZappAnalyticsPluginGA
//
//  Created by Simon Borkin on 10/21/18.
//

import Foundation

import ZappAnalyticsPluginsSDK
import GoogleAnalyticsSwift

public typealias GAProviderParams = [String: NSObject]

@objc open class GAProvider: ZPAnalyticsProvider {
    struct PluginKeys {
        static let trackingId = "mobile_app_account_id"
        static let anonymizeUserIp = "anonymize_user_ip"
        static let enableCustomDimensions = "custom_dimensions_enabled"
        static let enableScreenViews = "screen_views_enabled"
    }
    
    struct Consts {
        static let customDimentionsPrefix = "custom_dimension_index_"
    }
    
    var isGACustomDimensionsEnabled = false
    var isGAScreenViewEnabled = false

    public var combinedInitialParams: GAProviderParams {
        get {
            return self.baseProperties.merge(self.defaultEventProperties)
        }
    }
    
    public required init(configurationJSON:NSDictionary?) {
        super.init()
        self.configurationJSON = configurationJSON
    }
    
    public required init() {
        super.init()
    }
    
    override open func getKey() -> String {
        return "google_analytics"
    }
    
    override open func configureProvider() -> Bool {
        guard
            let gai = GAI.sharedInstance(),
            let trackingId = self.providerProperties[PluginKeys.trackingId] as? String,
            let tracker = gai.tracker(withTrackingId: trackingId) else {
            return false
        }
        
        if let shouldAnonymizeUserIp = self.providerProperties[PluginKeys.anonymizeUserIp] as? String, shouldAnonymizeUserIp.boolValue() {
            tracker.set(kGAIAnonymizeIp, value: "1")
        }
        
        if let enableCustomDimensions = self.providerProperties[PluginKeys.enableCustomDimensions] as? String, enableCustomDimensions.boolValue() {
            self.isGACustomDimensionsEnabled = true
        }

        if let enableScreenViews = self.providerProperties[PluginKeys.enableScreenViews] as? String, enableScreenViews.boolValue() {
            self.isGAScreenViewEnabled = true
        }
        
        gai.trackUncaughtExceptions = false
        gai.dispatchInterval = 15
        gai.logger.logLevel = .verbose;

        tracker.allowIDFACollection = true

        return true
    }
    
    override open func trackCampaignParamsFromUrl(_ url: NSURL) {
        guard
            self.indexForUTM(utm: url) != nil,
            let tracker = GAI.sharedInstance()?.defaultTracker,
            let gaiParamsBuilder = GAIDictionaryBuilder.createScreenView() else {
            return
        }
        
        gaiParamsBuilder.setCampaignParametersFromUrl(url.absoluteString)
        if gaiParamsBuilder.get(kGAICampaignSource) == nil, let host = url.host, host.count > 0 {
            gaiParamsBuilder.set("referrer", forKey: kGAICampaignMedium)
            gaiParamsBuilder.set(host, forKey: kGAICampaignSource)
        }
        
        guard let params = gaiParamsBuilder.build() as? [AnyHashable : Any] else {
            return
        }
        
        tracker.send(params)
    }
    
    override open func trackEvent(_ eventName: String) {
        guard let tracker = GAI.sharedInstance()?.defaultTracker else {
            return
        }
        
        let events = self.separatedEvents(forEventString: eventName)
        let analyticsString = self.analyticsString(fromParams: self.combinedInitialParams)

        guard
            let gaiParamsBuilder = GAIDictionaryBuilder.createEvent(withCategory: events.first, action: events.last, label: analyticsString, value: 0),
            let params = gaiParamsBuilder.build() as? [AnyHashable : Any] else {
            return
        }
        
        tracker.send(params)
    }
    
    override open func trackEvent(_ eventName: String, parameters: [String: NSObject]) {
        guard let tracker = GAI.sharedInstance()?.defaultTracker else {
            return
        }
        
        let combinedParams = ZPAnalyticsProvider.defaultProperties(self.combinedInitialParams, combinedWithEventParams: parameters, shouldIncludeExtraParams: true)
        let events = self.separatedEvents(forEventString: eventName)
        let analyticsString = self.analyticsString(fromParams: combinedParams)

        guard
            let gaiParamsBuilder = GAIDictionaryBuilder.createEvent(withCategory: events.first, action: events.last, label: analyticsString, value: 0),
            let params = gaiParamsBuilder.build() as? [AnyHashable : Any] else {
                return
        }
        
        let convertedCustomDimensions = self.convertedCustomDimensions(forParams: combinedParams)
        self.add(convertedCustomDimensions, toTracker: tracker)
        
        tracker.send(params)
        
        self.remove(convertedCustomDimensions, fromTracker: tracker)
    }
    
    override open func trackEvent(_ eventName: String, timed: Bool) {
        self.trackEvent(eventName)
    }
    
    override open func trackEvent(_ eventName: String, parameters: [String : NSObject], timed: Bool) {
        self.trackEvent(eventName, parameters: parameters)
    }
    
    override open func trackEvent(_ eventName: String, action: String, label: String, value: Int) {
        guard let tracker = GAI.sharedInstance()?.defaultTracker else {
            return
        }
        
        guard
            let gaiParamsBuilder = GAIDictionaryBuilder.createEvent(withCategory: eventName, action: action, label: label, value: NSNumber(integerLiteral: value)),
            let params = gaiParamsBuilder.build() as? [AnyHashable : Any] else {
                return
        }
        
        tracker.send(params)
    }
    
    override open func trackScreenView(_ screenName: String, parameters: [String : NSObject]) {
        guard
            self.isGAScreenViewEnabled,
            let tracker = GAI.sharedInstance()?.defaultTracker,
            let gaiParamsBuilder = GAIDictionaryBuilder.createScreenView() else {
            return
        }
        
        let combinedParams = ZPAnalyticsProvider.defaultProperties(self.combinedInitialParams, combinedWithEventParams: parameters, shouldIncludeExtraParams: false)
        let convertedCustomDimensions = self.convertedCustomDimensions(forParams: combinedParams)

        guard let params = gaiParamsBuilder.build() as? [AnyHashable : Any] else {
            return
        }
        
        tracker.set(kGAIScreenName, value: screenName)
        self.add(convertedCustomDimensions, toTracker: tracker)
        
        tracker.send(params)
        
        tracker.set(kGAIScreenName, value: nil)
        self.remove(convertedCustomDimensions, fromTracker: tracker)
    }
    
    fileprivate func separatedEvents(forEventString value: String) -> [String] {
        var result: [String]?
        
        var eventSeparated = value.components(separatedBy: ":")
        if eventSeparated.count == 1 {
            result = value.components(separatedBy: "-")
        }
        else {
            for (index, eventValue) in eventSeparated.prefix(2).enumerated() {
                eventSeparated[index] = eventValue.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return result ?? [String]()
    }
    
    fileprivate func analyticsString(fromParams params: GAProviderParams) -> String {
        var mergedParams = ""
        
        let sortedParams = Array(params.keys).sorted()
        for (index, paramName) in sortedParams.enumerated() {
            if let paramValue = params[paramName] {
                mergedParams = mergedParams.appendingFormat("%@=%@", paramName, String(describing: paramValue))
                if index < sortedParams.count - 1 {
                    mergedParams += ";"
                }
            }
        }
        
        return mergedParams.count > 0 ? mergedParams : ""
    }
    
    fileprivate func indexForUTM(utm: NSURL) -> UInt? {
        var result: UInt? = nil
        
        if let allQueryKeys = utm.queryDictionary()?.keys {
            for (index, queryKey) in allQueryKeys.enumerated() {
                if let queryKey = queryKey as? String, queryKey.localizedCaseInsensitiveCompare("utm") == .orderedSame {
                    result = UInt(index)
                    break
                }
            }
        }
        
        return result
    }
    
    fileprivate func convertedCustomDimensions(forParams params: GAProviderParams) -> GAProviderParams {
        var result = GAProviderParams()
        
        let remoteParams = ZPAnalyticsProvider.getFirebaseRemoteConfigurationParameters(prefix: Consts.customDimentionsPrefix, baseProperties: params, eventProperties: [:])
        for (name, remoteValue) in remoteParams {
            if  let index = Int(name.replacingOccurrences(of: Consts.customDimentionsPrefix, with: "")), index > -1,
                let customDimension = GAIFields.customDimension(for: UInt(index)) {
                
                result[customDimension] = remoteValue
            }
        }
        
        return result
    }
    
    fileprivate func add(_ convertedCustomDimensions: GAProviderParams, toTracker tracker: GAITracker) {
        for (name, value) in convertedCustomDimensions {
            if let value = value as? String {
                tracker.set(name, value: value)
            }
        }
    }
    
    fileprivate func remove(_ convertedCustomDimensions: GAProviderParams, fromTracker tracker: GAITracker) {
        for name in convertedCustomDimensions.keys {
            tracker.set(name, value: nil)
        }
    }
    
    public func customDimensions(forParams params: GAProviderParams) -> GAProviderParams {
        var result = GAProviderParams()
        
        let remoteParams = ZPAnalyticsProvider.getFirebaseRemoteConfigurationParameters(prefix: Consts.customDimentionsPrefix, baseProperties: params, eventProperties: [: ])
        for (name, remoteValue) in remoteParams {
            if let index = Int(name.replacingOccurrences(of: Consts.customDimentionsPrefix, with: "")), index > -1 {
                result[String(index)] = remoteValue
            }
        }
        
        return result
    }

    public func add(customDimensions: GAProviderParams) {
        guard let tracker = GAI.sharedInstance()?.defaultTracker else {
            return
        }
        
         for (dimensionIndex, value) in customDimensions {
            if let dimensionIndex = UInt(dimensionIndex), let value = value as? String {
                let gaiParam = GAIFields.customDimension(for: dimensionIndex)
                tracker.set(gaiParam, value: value)
            }
        }
    }
    
    public func remove(customDimensions: GAProviderParams) {
        guard let tracker = GAI.sharedInstance()?.defaultTracker else {
            return
        }
        
        for dimensionIndex in customDimensions.keys {
            if let dimensionIndex = UInt(dimensionIndex) {
                let gaiParam = GAIFields.customDimension(for: dimensionIndex)
                tracker.set(gaiParam, value: nil)
            }
        }
    }
    
    public func clientId() -> String? {
        return GAI.sharedInstance()?.defaultTracker.get(kGAIClientId)
    }
    
    public static func gaiSharedInstance() -> Any? {
        return GAI.sharedInstance()
    }

}
