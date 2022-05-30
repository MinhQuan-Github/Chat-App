//
//  DatabaseManager.swift
//  ChatApp
//
//  Created by Quan's Macbook on 18/05/2022.
//

import UIKit
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account management

extension DatabaseManager {
    
    ///
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// insert new user to datebase
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        
        database.child(user.safeEmail).setValue([
            "first_Name" : user.firstName,
            "last_Name"  : user.lastName
        ]) { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var userCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name" : user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    userCollection.append(newElement)
                    
                    self.database.child("users").setValue(userCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name" : user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            print(value)
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

// MARK: - Sending messages/ conversation
extension DatabaseManager {
    
    /// create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString  = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                /// conversation array exists for current user
                ///  should not append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            } else {
                /// conversation array does not exist
                /// create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        let messageDate = firstMessage.sentDate
        let dateString  = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUseremail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id" : firstMessage.messageId,
            "name": name,
            "type" : firstMessage.kind.MessageKindString,
            "content": message,
            "date" : dateString,
            "sender_email" : currentUseremail,
            "is_read" : false
        ]
        
        let value:[String : Any] = [
            "message": [
                collectionMessage
            ]
        ]
        
        print("adding convo \(conversationID)")
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to Conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}


struct ChatAppUser {
    let firstName : String
    let lastName  : String
    let emailAddress : String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFilename: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
