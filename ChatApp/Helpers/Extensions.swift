//
//  Extensions.swift
//  ChatApp
//
//  Created by Vũ Linh on 08/04/2021.
//

import UIKit

extension UIImageView {
    
    func loadImageUsingCache(profileImageURL: String) {
        let url = URL(string: profileImageURL)!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }

            if let error = error {
                print(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}
