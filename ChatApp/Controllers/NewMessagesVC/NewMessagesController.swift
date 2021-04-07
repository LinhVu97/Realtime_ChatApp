//
//  NewMessagesController.swift
//  ChatApp
//
//  Created by Vũ Linh on 06/04/2021.
//

import UIKit

class NewMessagesController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(back))
    }
    
    @objc func back() {
        dismiss(animated: true, completion: nil)
    }
}
