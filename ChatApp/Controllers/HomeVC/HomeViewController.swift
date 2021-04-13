//
//  HomeViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 05/04/2021.
//

import UIKit
import Firebase

class HomeViewController: UITableViewController {
    let auth = FirebaseAuth.Auth.auth()
    let cellID = "cell"
    
    var messages = [Messages]()
    var dictionaryMessage = [String: Messages]()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(handleNewMessage))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        
        checkIfUserLoggedIn()
        
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    // MARK: Check user login
    func checkIfUserLoggedIn() {
        
        if auth.currentUser?.uid == nil {
            perform(#selector(logout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetUpNavBarTitle()
        }
    }
    
    func fetchUserAndSetUpNavBarTitle() {
        guard let uid = auth.currentUser?.uid else {
            return
        }
        
        var ref: DatabaseReference!
        ref = FirebaseDatabase.Database.database().reference()
        ref.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in

            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let user = User()
                user.setValuesForKeys(dictionary)
                
                self.setupNavbarWithUser(user: user)
            }

        }) { (error) in
            print(error.localizedDescription)
        }
    
    }
    
    // MARK: Setup Navbar
    func setupNavbarWithUser(user: User) {
        messages.removeAll()
        dictionaryMessage.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageURL = user.profileImage {
            profileImageView.loadImageUsingCache(profileImageURL: profileImageURL)
        }
        
        titleView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        let name = UILabel()
        titleView.addSubview(name)
        name.text = user.name
        name.translatesAutoresizingMaskIntoConstraints = false
        name.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        name.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        name.rightAnchor.constraint(equalTo: titleView.rightAnchor).isActive = true
        name.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
    }
    
    func showChatController(user: User) {
        let chatLogController = ChatLogController()
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    // MARK: Add New message
    @objc func handleNewMessage() {
        let vc = NewMessagesController()
        vc.messagesController = self // ??? Can hoi ly do
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func logout() {
        do {
            try auth.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginViewController()
        loginController.modalPresentationStyle = .fullScreen
        present(loginController, animated: true, completion: nil)
    }
    
    // MARK: Tableview Delegate and Datasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        
        guard let chatPartnerID = message.chatPartnerid() else {
            return 
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerID)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User()
            user.id = chatPartnerID
            user.setValuesForKeys(dictionary)
            
            self.showChatController(user: user)
        }, withCancel: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: Observe Message
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { snapshot in
            let userID = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userID).observe(.childAdded, with: { snapshot in
                let messageId = snapshot.key
                let messageReference = Database.database().reference().child("message").child(messageId)
                messageReference.observeSingleEvent(of: .value, with: { snapshot1 in
                    if let dictionary = snapshot1.value as? [String: AnyObject] {
                        let message = Messages()
                        message.setValuesForKeys(dictionary)
                        self.messages.append(message)
                        
                        if let chatPartnerID = message.chatPartnerid() {
                            self.dictionaryMessage[chatPartnerID] = message
                            
                            self.messages = Array(self.dictionaryMessage.values)
                        }
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
                    }
                }, withCancel: nil)
            })
        }, withCancel: nil)
        
        ref.observe(.childRemoved) { (snapshot) in
            self.dictionaryMessage.removeValue(forKey: snapshot.key)
            self.handleReloadTable()
        }
    }
    
    @objc func handleReloadTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = messages[indexPath.row]
        
        if let chatPartnerID = message.chatPartnerid() {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerID).removeValue { (error, ref) in
                if error != nil {
                    return
                }
                
                self.dictionaryMessage.removeValue(forKey: chatPartnerID)
                self.handleReloadTable()
                
                self.messages.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
    }
}
