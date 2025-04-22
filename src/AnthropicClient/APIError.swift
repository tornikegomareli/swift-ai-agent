//
//  APIError.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Error response from the API
public struct APIError: Codable {
  public let type: String
  public let message: String
}
