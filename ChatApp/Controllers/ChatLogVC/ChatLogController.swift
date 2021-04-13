//
//  ChatLogController.swift
//  ChatApp
//
//  Created by Vũ Linh on 08/04/2021.
//

import UIKit
import Firebase
import FirebaseStorage

class ChatLogController: UIViewController {
    @IBOutlet weak var textFieldMess: UITextField!
    @IBOutlet weak var chatLogCollection: UICollectionView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var sendImage: UIImageView!
    
    var bottomConstraint: NSLayoutConstraint?
    
    let cellID = "cell"
    
    var messages = [Messages]()
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessage()
            
            setupKeyboardObserve()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCollectionView()
        textFieldMess.delegate = self
        dissmissKeyBoard()
        
        bottomConstraint = NSLayoutConstraint(item: bottomView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        
        sendImage.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleUploadImage))
        sendImage.addGestureRecognizer(tap)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        chatLogCollection.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        if textFieldMess.text!.isEmpty {
        } else {
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
                let userMessage = Database.database().reference().child("user-messages").child(fromID!).child(toID)
                guard let messageID = childRef.key else {
                    return
                }
                userMessage.updateChildValues([messageID: 1])
                
                // Recipient
                let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toID).child(fromID!)
                recipientUserMessageRef.updateChildValues([messageID: 1])
            })
            
            textFieldMess.text = ""
        }
    }
    
    func observeMessage() {
        guard let uid = Auth.auth().currentUser?.uid, let toID = user?.id else {
            return
        }
        
        let userMessageRef = Database.database().reference().child("user-messages").child(uid).child(toID)
        userMessageRef.observe(.childAdded, with: { snapshot in
            
            let messgeId = snapshot.key
            let messageRef = Database.database().reference().child("message").child(messgeId)
            messageRef.observeSingleEvent(of: .value, with: { snapshot in
               
                guard let dictionary = snapshot.value as? [String: AnyObject] else{
                    return
                }
                let message = Messages()
                message.imageUrl = dictionary["imageUrl"] as? String
                message.setValuesForKeys(dictionary)
                
                if message.chatPartnerid() == self.user?.id {
                    self.messages.append(message)
                }
                
                
                DispatchQueue.main.async {
                    self.chatLogCollection.reloadData()
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
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        chatLogCollection.addGestureRecognizer(tap)
    }
}

extension ChatLogController: UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
        
        setupCell(cell: cell, message: message)
        
        // let's modify bubbleView
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Messages) {
        if let image = self.user?.profileImage {
            cell.profileImage.loadImageUsingCache(profileImageURL: image)
        }
        
        if let messageImage = message.imageUrl {
            cell.messageImageView.loadImageUsingCache(profileImageURL: messageImage)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
        if message.fromID == Auth.auth().currentUser?.uid {
            // Blue bubble
            cell.bubbleView.backgroundColor = .blue
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
            cell.profileImage.isHidden = true
        } else {
            // Gray bubble
            cell.bubbleView.backgroundColor = .lightGray
            cell.textView.textColor = .white
            cell.profileImage.isHidden = false
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            height = CGFloat(imageHeight / imageWidth * 200)
            
        }
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    private func estimateFrameForText(text : String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    // MARK: Setup Keyboard
    func setupKeyboardObserve() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        
        let keyboardFrame = keyboardSize.cgRectValue
        
        let isKeyBoardShowing = notification.name == UIResponder.keyboardWillShowNotification
        
        bottomConstraint?.constant = isKeyBoardShowing ? -keyboardFrame.height: 0

        UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { (completed) in
            self.chatLogCollection.scrollToItem(at: IndexPath(item: self.messages.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: true)
        }
    }
    
    // MARK: Dismiss keyboard
    func dissmissKeyBoard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
      
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: Upload image
    @objc func handleUploadImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromLibrary: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromLibrary = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromLibrary = originalImage
        }
        
        if let selectedImage = selectedImageFromLibrary {
            sendImage.image = selectedImage
            uploadToFirebaseStorageUsingImage(image: selectedImage)
            sendImage.image = UIImage(systemName: "photo.fill")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage) {
        let imageName = UUID().uuidString
        let ref = Storage.storage().reference().child("MessageImage").child(imageName)
        
        if let uploadData = self.sendImage.image?.jpegData(compressionQuality: 0.2) {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    return
                }
                
                ref.downloadURL(completion: { (url, error) in
                    guard let downloadURL = url else {
                        return
                    }
                    
                    let imageUrl = downloadURL.absoluteString
                    self.sendMessageWithImageURL(imageURL: imageUrl, image: image)
                })
            }
        }
    }
    
    private func sendMessageWithImageURL(imageURL: String, image: UIImage) {
        let ref = Database.database().reference().child("message")
        let childRef = ref.childByAutoId()
        let toID = user!.id!
        let fromID = Auth.auth().currentUser?.uid
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"  //"MM-dd-yyyy HH:mm"
        let timestamp = dateFormatter.string(from: NSDate() as Date)
        let values = ["fromID": fromID as Any, "toID": toID, "timestamp": timestamp, "imageUrl": imageURL, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]

        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error)
                return
            }
            
            // Create data user message
            let userMessage = Database.database().reference().child("user-messages").child(fromID!).child(toID)
            guard let messageID = childRef.key else {
                return
            }
            userMessage.updateChildValues([messageID: 1])
            
            // Recipient
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toID).child(fromID!)
            recipientUserMessageRef.updateChildValues([messageID: 1])
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
