//
//  RegisterViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 05/04/2021.
//

import UIKit
import FirebaseAuth
import Firebase

class RegisterViewController: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameText.delegate = self
        emailText.delegate = self
        passText.delegate = self
    }

    @IBAction func registerButton(_ sender: UIButton) {
        nameText.resignFirstResponder()
        emailText.resignFirstResponder()
        passText.resignFirstResponder()
        
        guard let name = nameText.text, !name.isEmpty,
              let email = emailText.text, !email.isEmpty,
              let password = passText.text, !password.isEmpty, password.count >= 6 else {
            alert(title: "Woops", message: "Please enter all field infomation")
            return
        }
        
        // MARK: Firebase register
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                strongSelf.alert(title: "Woops", message: "Wrong email or password")
                print("Create Error")
                return
            }
            
            // MARK: Reference, Successfully authenticated user
            guard let userID = authResult?.user.uid else {
                return
            }
 
            var ref: DatabaseReference!
            ref = FirebaseDatabase.Database.database().reference(fromURL: "https://chatapp-7f3ff-default-rtdb.firebaseio.com/")
            let usersReference = ref.child("users").child(userID)
            let values = ["name": name, "email": email]
            usersReference.updateChildValues(values) { (error, ref) in
                if error != nil {
                    print(error)
                    return
                }
                
                strongSelf.dismiss(animated: true, completion: nil)
            }
        
            strongSelf.alert(title: "", message: "Success! Now you can login")
            strongSelf.nameText.text = ""
            strongSelf.emailText.text = ""
            strongSelf.passText.text = ""
        })
    }
    
    @IBAction func backLogin(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Alert
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        if !text.isEmpty{
            registerButton.isUserInteractionEnabled = true
            registerButton.backgroundColor = .systemIndigo
        } else {
            registerButton.isUserInteractionEnabled = false
            registerButton.backgroundColor = .gray
        }
        return true
    }
}
