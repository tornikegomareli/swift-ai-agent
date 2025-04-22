//
//  ClaudeTerminalChat.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Function signature for tool implementation
public typealias ToolFunction = (Dictionary<String, Any>) throws -> String

/// Tool definition with implementation
public struct ToolDefinition {
  /// The tool metadata
  let tool: Tool
  
  /// The function that implements the tool
  let function: ToolFunction
  
  /// Create a new tool definition
  /// - Parameters:
  ///   - name: Name of the tool
  ///   - description: Description of what the tool does
  ///   - inputSchema: JSON Schema for the tool input
  ///   - function: Implementation of the tool
  public init(name: String, description: String, inputSchema: ToolInputSchema, function: @escaping ToolFunction) {
    self.tool = Tool(name: name, description: description, inputSchema: inputSchema)
    self.function = function
  }
}

@available(iOS 15.0, macOS 12.0, *)
class Agent {
  private let client: AnthropicClient
  private let model: String
  private let maxTokens: Int
  private var conversation: [Message] = []
  private let promptPrefix = "User: "
  private let responsePrefix = "Claude: "
  private let tools: [ToolDefinition]
  
  private let userColor: String
  private let claudeColor: String
  private let tokenInfoColor: String
  private let commandColor: String
  private let errorColor: String
  private let infoColor: String
  private let toolColor: String
  
  init(apiKey: String,
       model: String = "claude-3-7-sonnet-20250219",
       maxTokens: Int = 1024,
       tools: [ToolDefinition] = []) {
    self.client = AnthropicClient(apiKey: apiKey)
    self.model = model
    self.maxTokens = maxTokens
    self.tools = tools
    
    self.userColor = TerminalColors.brightGreen
    self.claudeColor = TerminalColors.brightBlue
    self.tokenInfoColor = TerminalColors.yellow
    self.commandColor = TerminalColors.cyan
    self.errorColor = TerminalColors.red
    self.infoColor = TerminalColors.brightWhite
    self.toolColor = TerminalColors.magenta
  }
  
  func start() async {
    printColoredBanner()
    printHelp()
    
    if !tools.isEmpty {
      printInfo("Available tools: \(tools.map { $0.tool.name }.joined(separator: ", "))")
    }
    
    printDivider()
    
    while true {
      printUserPrompt()
      guard let input = readLine(), input.lowercased() != "exit" else {
        print("Goodbye!")
        break
      }
      
      if processCommand(input) {
        continue
      }
      
      /// Add user message to conversation history
      let userMessage = Message(role: .user, content: input)
      conversation.append(userMessage)
      
      do {
        // Extract just the tool definitions (without the implementation functions)
        let toolDefinitions = tools.map { $0.tool }
        
        /// Send the entire conversation to Claude for context
        let response = try await client.createMessage(
          model: model,
          maxTokens: maxTokens,
          messages: conversation,
          tools: toolDefinitions.isEmpty ? nil : toolDefinitions
        )
        
        // Check if Claude is making tool calls
        if response.hasToolCalls {
          await handleToolCalls(response)
        } else {
          /// Extract and print Claude's regular text response
          if let firstContent = response.content.first,
             let text = firstContent.text {
            printClaudeResponse(text)
            
            /// Add Claude's response to conversation history
            let assistantMessage = Message(role: .assistant, content: text)
            conversation.append(assistantMessage)
            
            printTokenInfo(response.usage.inputTokens, response.usage.outputTokens)
          } else {
            printError("Could not extract text from response")
          }
        }
      } catch {
        printError(error.localizedDescription)
      }
      
      printDivider()
    }
  }
  
  /// Handle tool calls from Claude
  private func handleToolCalls(_ response: MessageResponse) async {
    // Display that Claude is using tools
    printInfo("Claude is using tools...")
    
    // Create a message to store in conversation history
    var toolResponseContents: [String] = []
    
    // Process each tool call
    for toolCall in response.toolCalls {
      // Find the tool implementation
      guard let toolDef = tools.first(where: { $0.tool.name == toolCall.name }) else {
        printError("Tool not found: \(toolCall.name)")
        continue
      }
      
      // Print tool usage
      print("\(toolColor)Tool Call: \(toolCall.name)\(TerminalColors.reset)")
      print("\(toolColor)Input: \(toolCall.input)\(TerminalColors.reset)")
      
      do {
        // Execute the tool
        let result = try toolDef.function(toolCall.input)
        
        // Print the result
        print("\(toolColor)Result: \(result)\(TerminalColors.reset)")
        
        // Add to conversation as a tool response
        let toolResponseText = "Tool '\(toolCall.name)' returned: \(result)"
        toolResponseContents.append(toolResponseText)
        
        // Create a tool result message
        // In a real implementation, you would send this back to Claude
        // But for simplicity in this example, we'll just add it to the conversation
      } catch {
        printError("Tool execution error: \(error.localizedDescription)")
        toolResponseContents.append("Tool '\(toolCall.name)' error: \(error.localizedDescription)")
      }
    }
    
    // Add Claude's response with tool calls to the conversation
    let assistantMessage = Message(role: .assistant, content: "I need to use some tools to help you.")
    conversation.append(assistantMessage)
    
    // Add tool results to the conversation
    let toolResultsMessage = Message(role: .user, content: toolResponseContents.joined(separator: "\n"))
    conversation.append(toolResultsMessage)
    
    // Now get Claude's follow-up response with the tool results
    do {
      let followUpResponse = try await client.createMessage(
        model: model,
        maxTokens: maxTokens,
        messages: conversation
      )
      
      // Extract and print Claude's text response after tool use
      if let firstContent = followUpResponse.content.first,
         let text = firstContent.text {
        printClaudeResponse(text)
        
        // Add Claude's final response to conversation history
        let finalMessage = Message(role: .assistant, content: text)
        conversation.append(finalMessage)
        
        printTokenInfo(followUpResponse.usage.inputTokens, followUpResponse.usage.outputTokens)
      } else {
        printError("Could not extract text from response after tool use")
      }
    } catch {
      printError("Error getting follow-up response: \(error.localizedDescription)")
    }
  }
  
  private func processCommand(_ input: String) -> Bool {
    let command = input.lowercased()
    
    switch command {
    case "/exit":
      printInfo("Goodbye!")
      return true
    case "/save":
      // TODO: save conversation
      return true
    case "/load":
      // TODO: load conversation
      return true
    case "/clear":
      clearConversation()
      return true
      
    case "/help":
      printHelp()
      return true
      
    case "/tools":
      listTools()
      return true
      
    default:
      if command.hasPrefix("/") {
        printError("Unknown command: \(command)")
        printInfo("Type /help for available commands")
        return true
      }
      return false
    }
  }
  
  private func listTools() {
    if tools.isEmpty {
      printInfo("No tools available")
      return
    }
    
    printInfo("Available tools:")
    for toolDef in tools {
      let tool = toolDef.tool
      print("  \(toolColor)\(tool.name)\(TerminalColors.reset) - \(tool.description ?? "No description")")
    }
  }
  
  private func clearConversation() {
    conversation = []
    printInfo("Conversation cleared")
  }
  
  private func printUserPrompt() {
    print("\(userColor)User: \(TerminalColors.reset)", terminator: "")
  }
  
  private func printClaudeResponse(_ text: String) {
    print("\(claudeColor)Claude: \(TerminalColors.reset)", terminator: " ")
    print(text)
  }
  
  private func printTokenInfo(_ inputTokens: Int, _ outputTokens: Int) {
    print("\(tokenInfoColor)(Input tokens: \(inputTokens), Output tokens: \(outputTokens))\(TerminalColors.reset)")
  }
  
  private func printError(_ message: String) {
    print("\(errorColor)Error: \(message)\(TerminalColors.reset)")
  }
  
  private func printInfo(_ message: String) {
    print("\(infoColor)\(message)\(TerminalColors.reset)")
  }
  
  private func printCommand(_ command: String, description: String) {
    print("  \(commandColor)\(command)\(TerminalColors.reset) - \(description)")
  }
  
  private func printDivider() {
    print("\(infoColor)-------------------------------------------\(TerminalColors.reset)")
  }
  
  private func printColoredBanner() {
    print("\(TerminalColors.bold)\(claudeColor)🤖 Swift AI Agent \(TerminalColors.reset)")
    print("\(infoColor)Model: \(model)")
  }
  
  private func printHelp() {
    print("\(infoColor)Available commands:\(TerminalColors.reset)")
    printCommand("/exit", description: "Quit the application")
    printCommand("/save", description: "Save the conversation")
    printCommand("/load", description: "Load the previously saved conversation")
    printCommand("/clear", description: "Clear the conversation history")
    printCommand("/tools", description: "List available tools")
    printCommand("/help", description: "Show this help message")
  }
}
