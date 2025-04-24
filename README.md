# Swift AI Agent

A command-line interface (CLI) tool for interacting with the Anthropic Claude API, featuring a robust agent system with tool capabilities.


Project is running inside terminal application and allows you to chat with Claude and enable it to perform actions in your environment using tools. It demonstrates how to build an agent system with the ability to use tools to interact with the local file system.

## Motivation

This project was created to understand how AI agents work and to explore the architecture of agent systems. The goal was to build a simple but functional agent system in Swift that can interact with the Claude API and execute tools based on Claude's decisions.

Key learning objectives:
- Understanding how to structure an agent system
- Implementing tool definitions and execution flows
- Managing conversation context between the agent and the AI

## Functionality

- Interactive terminal-based chat with Claude LLM
- Tool execution capabilities:
  - Read files
  - List files and directories
  - Find and read files
  - Edit existing files
  - Create new files
- Conversation management with slash commands:
  - `/exit` - Exit the application
  - `/clear` - Clear conversation history
  - `/tools` - List available tools
  - `/help` - Show help message

## Requirements

- macOS 13.0+
- Swift 6.0+
- Anthropic API key

## Getting Started

1. Clone the repository
2. Open the project in Xcode or your favorite editor
3. Replace `"your-api-key"` in `main.swift` with your actual Anthropic API key
4. Build and run the project:

```bash
swift build
swift run
```

## Architecture

The project is organized into several components:

### Agent System

- `Agent.swift`: Core agent implementation with conversation loop and tool handling
- `ToolDefinition`: Structure to define tools with implementation functions

### Anthropic API Client

- `AnthropicClient.swift`: Client for the Anthropic API with tools support
- Various model files (`Message.swift`, `MessageContent.swift`, etc.) for API types

### Tools

- `read_file_tool.swift`: Tool for reading files
- `list_files_tool.swift`: Tool for listing files in a directory
- `find_and_read_file.swift`: Tool for finding and reading files
- `edit_file_tool.swift`: Tool for editing existing files
- `create_new_file_tool.swift`: Tool for creating new files
- `find_file_in_directory.swift`: File system search utilities

## Usage

After starting the application, you can chat with Claude just as you would in a regular interface. Claude can use the available tools to help you with file-related tasks.

Examples:

- "Could you read the 'Package.swift' file for me?"
- "Please list all the files in the current directory."
- "Find and show me all .swift files in the project."
- "Create a new file called 'test.txt' with 'Hello, world!' as its content."

## Some future Improvements

- Add support for more tools (e.g., network requests, system information)
- Implement streaming responses for better UX
- Add authentication management for the API key
- Support for multiple conversation sessions
- Ask permission for changing or creating file

## License

This project is available under the MIT License. See the LICENSE file for more information.
