//
//  ChatLogController.swift
//  ChatApp
//
//  Created by Vũ Linh on 08/04/2021.
//

import UIKit
import Firebase

class ChatLogController: UIViewController {
    @IBOutlet weak var textFieldMess: UITextField!
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textFieldMess.delegate = self
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let ref = Database.database().reference().child("message")
        let childRef = ref.childByAutoId()
        let toID = user!.id!
        let fromID = Auth.auth().currentUser?.uid
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let timestamp = dateFormatter.string(from: NSDate() as Date)
        let values = ["text": textFieldMess.text!,"fromID": fromID as Any, "toID": toID, "timestamp": timestamp] as [String : Any]
        childRef.updateChildValues(values)
        
        textFieldMess.text = ""
    }
}

extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
