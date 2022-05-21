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
    public func insertUser(with user: ChatAppUser) {
        
        database.child(user.safeEmail).setValue([
            "first_Name" : user.firstName,
            "last_Name"  : user.lastName
        ])
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
}
