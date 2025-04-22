//
//  MessageResponse.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Response from message creation
public struct MessageResponse: Codable {
  public let id: String
  public let type: String
  public let role: String
  public let content: [MessageContent]
  public let model: String
  public let stopReason: String?
  public let usage: Usage
  
  private enum CodingKeys: String, CodingKey {
    case id, type, role, content, model
    case stopReason = "stop_reason"
    case usage
  }
}
