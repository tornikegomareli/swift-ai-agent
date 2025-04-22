//
//  ClaudeTerminalChat.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

// Terminal chat application for continuous interaction with Claude
@available(iOS 15.0, macOS 12.0, *)
class Agent {
  private let client: AnthropicClient
  private let model: String
  private let maxTokens: Int
  private var conversation: [Message] = []
  private let promptPrefix = "User: "
  private let responsePrefix = "Claude: "
  
  private let userColor: String
  private let claudeColor: String
  private let tokenInfoColor: String
  private let commandColor: String
  private let errorColor: String
  private let infoColor: String
  
  init(apiKey: String, model: String = "claude-3-7-sonnet-20250219", maxTokens: Int = 1024) {
    self.client = AnthropicClient(apiKey: apiKey)
    self.model = model
    self.maxTokens = maxTokens
    
    self.userColor = TerminalColors.brightGreen
    self.claudeColor = TerminalColors.brightBlue
    self.tokenInfoColor = TerminalColors.yellow
    self.commandColor = TerminalColors.cyan
    self.errorColor = TerminalColors.red
    self.infoColor = TerminalColors.brightWhite
  }
  
  func start() async {
    printColoredBanner()
    printHelp()
    
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
        /// Send the entire conversation to Claude for context
        let response = try await client.createMessage(
          model: model,
          maxTokens: maxTokens,
          messages: conversation
        )
        
        /// Extract and print Claude's response
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
        
      } catch {
        printError(error.localizedDescription)
      }
      
      print("-------------------------------------------")
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
      return false
      
    case "/help":
      printHelp()
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
    printCommand("/help", description: "Show this help message")
  }
}
