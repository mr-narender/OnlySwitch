//
//  GitHubInteractor.swift
//  Modules
//
//  Created by Jacklandrin on 2022/5/24.
//

import Foundation

struct GitHubReleaseState {
    var latestVersion: String = ""
    var downloadURL: String = ""
    var downloadCount: Int = 0
    var isTheNewestVersion: Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let currentVersionSplited = currentVersion.split(separator: ".").compactMap { Int($0) }
        let latestVersionSplited = latestVersion.split(separator: ".").compactMap { Int($0) }
        for index in 0..<(min(currentVersionSplited.count, latestVersionSplited.count)) {
            let currentNumber = currentVersionSplited[index]
            let latestNumber = latestVersionSplited[index]
            if latestNumber > currentNumber {
                return false
            }
            if latestNumber < currentNumber {
                return true
            }
        }
        if latestVersionSplited.count > currentVersionSplited.count { // for example: 1.4.1 vs 1.4
            return false
        }
        return true
    }
    var updateHistoryInfo: String = ""
    var updateHistoryList = [String]()

    mutating func analyzeLastRelease<Model>(model: Model) throws where Model: GitHubReleaseLike {
        self.latestVersion = model.name.replacingOccurrences(of: "release_", with: "")
        if let asset = model.assets.first {
            self.downloadURL = asset.browser_download_url
        } else {
            throw RequestError.analyseModelFailed
        }
    }

    mutating func analyzeReleases<Model>(models: [Model]) where Model: GitHubReleaseLike {
        var count: Int = 0
        var updateInfo: String = ""
        var updateInfoList = [String]()
        for release in models {
            if let assert = release.assets.first {
                count += assert.download_count
            }
            if !release.prerelease {
                let releaseInfo = "\(release.name):\r\n\(release.body)"
                updateInfoList.append(releaseInfo)
                updateInfo += "\(releaseInfo)\r\n---------------------------------\r\n"
            }
        }
        self.downloadCount = count
        self.updateHistoryInfo = updateInfo
        self.updateHistoryList = updateInfoList
    }
}

public protocol GitHubReleaseAssetLike: Decodable, Sendable {
    var browser_download_url: String { get }
    var download_count: Int { get }
}

public protocol GitHubReleaseLike: Decodable, Sendable {
    associatedtype ReleaseAsset: GitHubReleaseAssetLike
    var name: String { get }
    var assets: [ReleaseAsset] { get }
    var prerelease: Bool { get }
    var body: String { get }
}
