//
//  UserDefaultsKeys.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2022/6/7.
//

import Foundation

extension UserDefaults {
    struct Key {
        //General
        static let menubarIcon = "menubarIconKey"
        static let appearanceColumnCount = "appearanceColumnCountKey"
        static let showAds = "showAdsKey"
        //PomodoroTimer
        static let WorkDuration = "WorkDurationKey"
        static let RestDuration = "RestDurationKey"
        static let RestAlert = "RestAlertKey"
        static let WorkAlert = "WorkAlertKey"
        static let AllowNotificationAlert = "AllowNotificationAlertKey"
        static let PTimerCycleCount = "PTimerLoopCountKey"
        //AirPods
        static let AirPodsAddress = "AirPodsAddressKey"
        //Radio
        static let soundWaveEffectDisplay = "soundWaveEffectDisplayKey"
        static let volume = "volumeKey"
        static let hasRunRadio = "hasRunRadioKey"
        static let radioStation = "radioStationKey"
        //Switch
        static let SwitchState = "SwitchStateKey"
        //Shortcuts
        static let shortcutsDic = "shortcutsDicKey"
        //Sort
        static let orderWeight = "orderWeightKey"
        //others
        static let newestVersion = "newestVersionKey"
        static let systemLangPriority = "systemLangPriority"
        static let NSVolume = "NSVolumeKey"
        static let ASVolume = "ASVolumeKey"
        static let MicVolume = "MicVolumeKey"
        static let ScreenSaverInterval = "ScreenSaverIntervalKey"
        static let AppLanguage = "app_lang"
    }
}
