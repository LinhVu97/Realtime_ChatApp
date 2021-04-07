//
//  RegisterViewController.swift
//  ChatApp
//
//  Created by Vũ Linh on 05/04/2021.
//

import UIKit
import Firebase
import FirebaseStorage

class RegisterViewController: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet private var image: UIImageView! {
        didSet {
            image.isUserInteractionEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissKeyboard()

        nameText.delegate = self
        emailText.delegate = self
        passText.delegate = self
    
        // Initialize Tap Gesture Recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeImage))
        image.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: Change Image
    @objc func changeImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: Dissmiss Keyboard
    func dissmissKeyBoard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: Register
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
            
            // MARK: Put image to Storage
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("ProfileImage").child("\(imageName).jpg")
            if let uploadData = self?.image.image?.jpegData(compressionQuality: 0.1) {
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    if error != nil {
                        return
                    }
                    
                    storageRef.downloadURL(completion: { (url, err) in
                        guard let downloadURL = url else {
                            return
                        }
                        let image = downloadURL.absoluteString
                        let values = ["name": name, "email": email, "profileImage" : image]
                        self?.registerUser(uid: userID, values: values as [String : AnyObject])
                    })
                }
            }
        })
    }
    
    private func registerUser(uid: String, values: [String: AnyObject]) {
        var ref: DatabaseReference!
        ref = FirebaseDatabase.Database.database().reference(fromURL: "https://chatapp-7f3ff-default-rtdb.firebaseio.com/")
        let usersReference = ref.child("users").child(uid)
        
        usersReference.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error)
                return
            }
        }
    
        alert(title: "", message: "Success! Now you can login")
    }
    
    // MARK: Back
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

extension RegisterViewController: UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: Text Field Delegate
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
    
    // MARK: Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromLibrary: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromLibrary = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromLibrary = originalImage
        }
        
        if let selectedImage = selectedImageFromLibrary {
            image.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
