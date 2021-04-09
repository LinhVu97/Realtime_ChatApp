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
    @IBOutlet weak var chatLogCollection: UICollectionView!
    
    let cellID = "cell"
    
    var messages = [Messages]()
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCollectionView()
        textFieldMess.delegate = self
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let ref = Database.database().reference().child("message")
        let childRef = ref.childByAutoId()
        let toID = user!.id!
        let fromID = Auth.auth().currentUser?.uid
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"  //"MM-dd-yyyy HH:mm"
        let timestamp = dateFormatter.string(from: NSDate() as Date)
        let values = ["text": textFieldMess.text!,"fromID": fromID as Any, "toID": toID, "timestamp": timestamp] as [String : Any]

        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error)
                return
            }
            
            // Create data user message
            let userMessage = Database.database().reference().child("user-messages").child(fromID!)
            guard let messageID = childRef.key else {
                return
            }
            userMessage.updateChildValues([messageID: 1])
            
            // Recipient
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toID)
            recipientUserMessageRef.updateChildValues([messageID: 1])
        })
        
        textFieldMess.text = ""
    }
    
    func observeMessage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userMessageRef = Database.database().reference().child("user-messages").child(uid)
        userMessageRef.observe(.childAdded, with: { snapshot in
            
            let messgeId = snapshot.key
            let messageRef = Database.database().reference().child("message").child(messgeId)
            messageRef.observeSingleEvent(of: .value, with: { snapshot in
               
                guard let dictionary = snapshot.value as? [String: AnyObject] else{
                    return
                }
                let message = Messages()
                message.setValuesForKeys(dictionary)
                
                if message.chatPartnerid() == self.user?.id {
                    self.messages.append(message)
                }
                
                
                DispatchQueue.main.async {
                    self.chatLogCollection.reloadData()
                    print(self.messages)
                    self.chatLogCollection.scrollToItem(at: IndexPath(item: self.messages.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)
                }
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    func setUpCollectionView() {
        chatLogCollection.dataSource = self
        chatLogCollection.delegate = self
        chatLogCollection.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 50, right: 0)
        chatLogCollection.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 50, right: 0)
        chatLogCollection.alwaysBounceVertical = true
        chatLogCollection.backgroundColor = .white
        chatLogCollection.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellID)
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        chatLogCollection.addGestureRecognizer(tap)
    }
}

extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ChatLogController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = chatLogCollection.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        return cell
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}
