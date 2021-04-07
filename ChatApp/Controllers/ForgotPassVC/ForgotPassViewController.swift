//
//  ForgotPassViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 05/04/2021.
//

import UIKit
import Firebase

class ForgotPassViewController: UIViewController {
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailText.delegate = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func resetPass(_ sender: UIButton) {
        FirebaseAuth.Auth.auth().sendPasswordReset(withEmail: emailText.text!) { error in
            if let error = error {
                let alert = UIAlertController(title: "Incorrect email", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            self.emailText.text = ""
            let alertReset = UIAlertController(title: "Reset Successfully!", message: "Check your email", preferredStyle: .alert)
            alertReset.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertReset, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension ForgotPassViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if !text.isEmpty{
            resetButton.isUserInteractionEnabled = true
            resetButton.backgroundColor = .systemIndigo
        } else {
            resetButton.isUserInteractionEnabled = false
            resetButton.backgroundColor = .gray
        }
        return true
    }
}
