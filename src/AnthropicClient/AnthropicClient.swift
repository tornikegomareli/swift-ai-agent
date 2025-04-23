///
/// A simple client for interacting with the Anthropic API with tools support
///
/// This client provides methods to send messages to the Anthropic Claude API
/// and supports the tools API for agent capabilities.
///
/// Created by Tornike Gomareli on 23.04.25.
///

import Foundation

/// A simple client for interacting with the Anthropic API with tools support
final public class AnthropicClient: Sendable {
  /// The API key used for authenticating with Anthropic's API
  private let apiKey: String
  /// The base URL for Anthropic's API
  private let baseURL = "https://api.anthropic.com/v1"
  /// The API version to use in requests
  private let apiVersion = "2023-06-01"
  
  /// Initialize the Anthropic client
  /// - Parameter apiKey: Your Anthropic API key
  public init(apiKey: String) {
    self.apiKey = apiKey
  }
  
  /// Create a message with Claude
  /// - Parameters:
  ///   - model: The Claude model to use (e.g. "claude-3-7-sonnet-20250219")
  ///   - maxTokens: Maximum number of tokens to generate
  ///   - messages: Array of message objects representing the conversation
  ///   - tools: Optional array of tools that Claude can use
  ///   - completion: Callback with result containing either the response or an error
  public func createMessage(
    model: String,
    maxTokens: Int,
    messages: [Message],
    tools: [Tool]? = nil,
    completion: @escaping @Sendable (Result<MessageResponse, Error>) -> Void
  ) {
    let endpoint = "\(baseURL)/messages"
    
    guard let url = URL(string: endpoint) else {
      completion(.failure(NSError(domain: "AnthropicClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
      return
    }
    
    let request = MessageRequest(model: model, maxTokens: maxTokens, messages: messages, tools: tools)
    
    guard let jsonData = try? JSONEncoder().encode(request) else {
      completion(.failure(NSError(domain: "AnthropicClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])))
      return
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = jsonData
    urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
    
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "AnthropicClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
        do {
          let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
          completion(.failure(NSError(domain: "AnthropicAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])))
        } catch {
          completion(.failure(NSError(domain: "AnthropicAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown API error"])))
        }
        return
      }
      
      do {
        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        completion(.success(messageResponse))
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  /// Create a message with Claude using async/await (iOS 15+/macOS 12+)
  /// - Parameters:
  ///   - model: The Claude model to use (e.g. "claude-3-7-sonnet-20250219")
  ///   - maxTokens: Maximum number of tokens to generate
  ///   - messages: Array of message objects representing the conversation
  ///   - tools: Optional array of tools that Claude can use
  /// - Returns: The message response
  @available(iOS 15.0, macOS 12.0, *)
  public func createMessage(
    model: String,
    maxTokens: Int,
    messages: [Message],
    tools: [Tool]? = nil
  ) async throws -> MessageResponse {
    let endpoint = "\(baseURL)/messages"
    
    guard let url = URL(string: endpoint) else {
      throw NSError(domain: "AnthropicClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    let request = MessageRequest(model: model, maxTokens: maxTokens, messages: messages, tools: tools)
    let jsonData = try JSONEncoder().encode(request)
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = jsonData
    urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
      let errorResponse = try JSONDecoder().decode(APIError.self, from: data)
      throw NSError(domain: "AnthropicAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])
    }
    
    // Uncomment for debugging: printPrettyJSON(from: data)
    return try JSONDecoder().decode(MessageResponse.self, from: data)
  }
}
