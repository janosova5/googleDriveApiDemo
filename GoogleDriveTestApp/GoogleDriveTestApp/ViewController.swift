//
//  ViewController.swift
//  GoogleDriveTestApp
//
//  Created by ljanosova on 5.2.19.
//  Copyright © 2019 ljanosova. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class ViewController: UIViewController {

    @IBOutlet weak var uploadImageView: UIImageView!
    @IBOutlet weak var imageIdLabel: UILabel!
    
    fileprivate let service = GTLRDriveService()
    fileprivate var manager: FileManagerService?
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager = FileManagerService.init(service)
        setupGoogleSignIn()
        GIDSignIn.sharedInstance()?.signInSilently()
        imagePicker.delegate = self
    }
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDriveFile]
    }
    
    private func uploadPhoto(_ filePath: String) {
        let path = filePath.replacingOccurrences(of: "file://", with: "")
        print(path)
        manager?.uploadFile("iPhone", filePath: path, MIMEType: "image/jpeg") { (fileID, error) in
            self.imageIdLabel.text = fileID
        
            self.manager?.download(fileID ?? "", onCompleted: { (data, error) in
                
                if let data = data {
                    self.uploadImageView.image = UIImage(data: data)
                }
            })
        }
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        setupGoogleSignIn()
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    @IBAction func uploadFileTapped(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - GIDSignInDelegate
extension ViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            service.authorizer = nil
        } else {
            service.authorizer = user.authentication.fetcherAuthorizer()
        }
    }
}

extension ViewController: GIDSignInUIDelegate {
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imageURL = info[.imageURL] as? URL
        dismiss(animated: true) { [weak self] in
            self?.uploadPhoto(imageURL?.absoluteString ?? "")
        }
    }
}

