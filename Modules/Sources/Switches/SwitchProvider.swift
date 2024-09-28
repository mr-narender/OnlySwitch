//
//  SwitchProtocal.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2021/11/30.
//

import Foundation
import Combine

/// protocol for every switch
public protocol SwitchProvider:AnyObject {
    var type:SwitchType {get}
    var delegate:SwitchDelegate? {get set}
    func currentStatus() -> Bool
    func currentInfo() -> String
    func operateSwitch(isOn:Bool) async throws
    func isVisible() -> Bool
}


public protocol SwitchDelegate:AnyObject {

    /// switch need to update itself for UI
    func shouldRefreshIfNeed(aSwitch:SwitchProvider)
}

/// for async operations
public extension SwitchProvider {
    @MainActor
    func currentStatusAsync() async -> Bool {
        return currentStatus()
    }

    @MainActor
    func currentInfoAsync() async -> String {
        return currentInfo()
    }
}
