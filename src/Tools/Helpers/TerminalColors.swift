//
//  TerminalColors.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

struct TerminalColors {
  static let reset = "\u{001B}[0m"
  
  static let black = "\u{001B}[30m"
  static let red = "\u{001B}[31m"
  static let green = "\u{001B}[32m"
  static let yellow = "\u{001B}[33m"
  static let blue = "\u{001B}[34m"
  static let magenta = "\u{001B}[35m"
  static let cyan = "\u{001B}[36m"
  static let white = "\u{001B}[37m"
  
  static let brightRed = "\u{001B}[91m"
  static let brightGreen = "\u{001B}[92m"
  static let brightYellow = "\u{001B}[93m"
  static let brightBlue = "\u{001B}[94m"
  static let brightMagenta = "\u{001B}[95m"
  static let brightCyan = "\u{001B}[96m"
  static let brightWhite = "\u{001B}[97m"
  
  static let bgBlack = "\u{001B}[40m"
  static let bgRed = "\u{001B}[41m"
  static let bgGreen = "\u{001B}[42m"
  static let bgYellow = "\u{001B}[43m"
  static let bgBlue = "\u{001B}[44m"
  static let bgMagenta = "\u{001B}[45m"
  static let bgCyan = "\u{001B}[46m"
  static let bgWhite = "\u{001B}[47m"
  
  static let bold = "\u{001B}[1m"
  static let underline = "\u{001B}[4m"
  static let italic = "\u{001B}[3m"
}
