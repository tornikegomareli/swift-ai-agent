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
  let chat = Agent(apiKey: apiKey)
  await chat.start()
}

if #available(iOS 15.0, macOS 12.0, *) {
  Task {
    await main()
  }
  
  RunLoop.main.run()
} else {
  print("Error: This application requires iOS 15.0+ or macOS 12.0+")
}
