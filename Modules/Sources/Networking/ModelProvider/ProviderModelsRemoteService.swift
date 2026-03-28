//
//  ProviderModelsRemoteService.swift
//  Modules
//
//  Created by Codex on 28.03.26.
//

import Foundation

public actor ProviderModelsRemoteService {
    private let modelsURL = URL(string: "https://raw.githubusercontent.com/jacklandrin/OnlySwitch/main/OnlySwitch/Resource/models.json")!
    private let session: URLSession
    private var cachedResponse: ProviderModelsResponse?

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func models(for provider: RemoteModelProviderKey) async throws -> [String] {
        let response = try await loadResponse()
        return response.models(for: provider)
    }

    private func loadResponse() async throws -> ProviderModelsResponse {
        if let cachedResponse {
            return cachedResponse
        }

        do {
            var request = URLRequest(url: modelsURL)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = ["Accept": "application/json"]
            let (data, _) = try await session.data(for: request)
            let decoded = try JSONDecoder().decode(ProviderModelsResponse.self, from: data)
            cachedResponse = decoded
            return decoded
        } catch {
            let local = try loadLocalResponse()
            cachedResponse = local
            return local
        }
    }

    private func loadLocalResponse() throws -> ProviderModelsResponse {
        guard let localURL = Bundle.main.url(forResource: "models", withExtension: "json") else {
            throw RequestError.invalidURL
        }
        let data = try Data(contentsOf: localURL)
        return try JSONDecoder().decode(ProviderModelsResponse.self, from: data)
    }
}
