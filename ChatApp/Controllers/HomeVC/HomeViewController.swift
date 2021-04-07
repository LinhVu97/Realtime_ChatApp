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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserLoggedIn()
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
                self.navigationItem.title = dictionary["name"] as? String
            }

        }) { (error) in
            print(error.localizedDescription)
        }
    
    }
    
    // MARK: Add New message
    @objc func handleNewMessage() {
        let vc = NewMessagesController()
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
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
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
        cell.textLabel?.text = "HOw"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Tap")
    }
}
