//
//  pretty_print.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

func printPrettyJSON(from data: Data) {
  do {
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    if let prettyString = String(data: prettyData, encoding: .utf8) {
      print("📦 Pretty JSON:\n\(prettyString)")
    } else {
      print("⚠️ Failed to convert pretty JSON data to string.")
    }
  } catch {
    print("❌ Failed to pretty print JSON: \(error.localizedDescription)")
  }
}
