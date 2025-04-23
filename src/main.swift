//
//  main.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

@available(iOS 15.0, macOS 12.0, *)
func main() async {
  let apiKey = "your-api-key"

  let readFileTool = createReadFileTool()
  let listFilesTool = createListFilesTool()
  let findAndReadFile = createFindAndReadFileTool()
  let editFileTool = createEditFileTool()
  let createFileTool = createCreateFileTool()

  let agent = Agent(
    apiKey: apiKey,
    tools: [readFileTool, listFilesTool, findAndReadFile, editFileTool, createFileTool]
  )

  await agent.start()
}

if #available(iOS 15.0, macOS 12.0, *) {
  Task {
    await main()
  }

  RunLoop.main.run()
} else {
  print("Error: This application requires iOS 15.0+ or macOS 12.0+")
}
