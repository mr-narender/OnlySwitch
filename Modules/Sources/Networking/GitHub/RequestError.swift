//
//  RequestError.swift
//  Modules
//
//  Created by Jacklandrin on 2022/5/19.
//

import Foundation

public enum RequestError: Error {
    case failed
    case notReachable
    case invalidURL
    case analyseModelFailed
}
