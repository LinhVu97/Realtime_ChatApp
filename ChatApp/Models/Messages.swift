//
//  Messages.swift
//  ChatApp
//
//  Created by Vũ Linh on 08/04/2021.
//

import UIKit
import Firebase

class Messages: NSObject {
    @objc var fromID : String?
    @objc var text: String?
    @objc var timestamp : String?
    @objc var toID : String?
    @objc var imageUrl: String?

    func chatPartnerid() -> String? {
        return fromID == Auth.auth().currentUser?.uid ? toID : fromID
    }
}
