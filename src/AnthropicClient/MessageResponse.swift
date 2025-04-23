///
/// Response from message creation
///
/// Represents the response from Claude after processing a message.
/// Contains the generated content, token usage, and other metadata.
///
/// Created by Tornike Gomareli on 23.04.25.
///

/// Response from message creation
public struct MessageResponse: Codable {
  /// Unique identifier for the message
  let id: String
  /// Type of the message
  let type: String
  /// Role of the message sender (always "assistant" for responses)
  let role: String
  /// Array of content blocks in the response
  let content: [MessageContent]
  /// The model that generated the response
  let model: String
  /// Reason why the model stopped generating
  let stopReason: String?
  /// Token usage information for this response
  let usage: Usage
  
  /// Coding keys for JSON serialization/deserialization
  enum CodingKeys: String, CodingKey {
    case id, type, role, content, model
    case stopReason = "stop_reason"
    case usage
  }
  
  /// Returns true if the response contains tool calls
  var hasToolCalls: Bool {
    return content.contains { $0.type == .toolCall && $0.toolCall != nil }
  }
  
  /// Returns an array of tool calls from the response
  var toolCalls: [ToolCall] {
    return content.compactMap { $0.type == .toolCall ? $0.toolCall : nil }
  }
}
