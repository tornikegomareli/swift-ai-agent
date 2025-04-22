//
//  Usage.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Token usage information
public struct Usage: Codable {
  public let inputTokens: Int
  public let outputTokens: Int
  
  private enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
  }
}
