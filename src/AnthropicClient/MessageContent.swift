//
//  MessageContent.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Message content types
public struct MessageContent: Codable {
  public let type: String
  public let text: String?
}
