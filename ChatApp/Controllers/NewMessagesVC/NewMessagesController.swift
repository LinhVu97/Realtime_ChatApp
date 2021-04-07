//
//  NewMessagesController.swift
//  ChatApp
//
//  Created by Vũ Linh on 06/04/2021.
//

import UIKit
import Firebase

class NewMessagesController: UITableViewController {
    let cellID = "cell"
    
    var users = [User]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(back))
        navigationItem.title = "New Message"
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        
        fetchUser()
    }
    
    @objc func back() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Fetch User
    func fetchUser() {
        Database.database().reference().child("users").observe( .childAdded, with: { (userdata) in
            if let dictionary = userdata.value as? [String: AnyObject] {
                let user = User()
                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                // This will crash because of background thread, so lets use dispatch_async to fix
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
        }, withCancel: nil)
    }
    
    // MARK: Tableview Delegate and Datasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: User Cell
class UserCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
