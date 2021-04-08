//
//  ChatLogMessageViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 08/04/2021.
//

import UIKit
import Firebase

class ChatLogMessageViewController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
    }
    
    @objc func back() {
        dismiss(animated: true, completion: nil)
    }
}
