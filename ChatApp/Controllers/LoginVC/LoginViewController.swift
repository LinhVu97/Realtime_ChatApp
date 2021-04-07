//
//  LoginViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 05/04/2021.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissKeyboard()
        
        emailText.delegate = self
        passText.delegate = self
    }
    
    @IBAction func loginButton(_ sender: UIButton) {
        emailText.resignFirstResponder()
        passText.resignFirstResponder()
        
        guard let email = emailText.text, !email.isEmpty,
              let password = passText.text, !password.isEmpty, password.count >= 6 else {
            alertError(title: "Woops", message: "Email or Password incorrect")
            return
        }
        
        // MARK: Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {   
                strongSelf.alertError(title: "Woops", message: "Email or Password incorrect")
                print("Login Error")
                return
            }
            
//            strongSelf.dismiss(animated: true, completion: nil)
            let vc = HomeViewController()
            let navi = UINavigationController(rootViewController: vc)
            navi.modalPresentationStyle = .fullScreen
            strongSelf.present(navi, animated: true, completion: nil)
        })
    }
    
    @IBAction func register(_ sender: UIButton) {
        let vc = RegisterViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func forgotPass(_ sender: UIButton) {
        let vc = ForgotPassViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: Alert
    func alertError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func dissmissKeyBoard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        if !text.isEmpty{
            loginButton.isUserInteractionEnabled = true
            loginButton.backgroundColor = .systemIndigo
        } else {
            loginButton.isUserInteractionEnabled = false
            loginButton.backgroundColor = .gray
        }
        return true
    }
}
