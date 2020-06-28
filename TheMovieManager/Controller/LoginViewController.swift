//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    // MARK:- IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let tag = "LoginVC "

    // MARK:- App life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        emailTextField.text = ""
        passwordTextField.text = ""
    }

    //MARK:- IBActions
    @IBAction func loginTapped(_ sender: UIButton) {
        setLoggingIn(logging: true)
        TMDBClient.getRequestToken(completion: handleGetRequestToken(success: error:))
    }

    @IBAction func loginViaWebsiteTapped() {
        setLoggingIn(logging: true)
        TMDBClient.getRequestToken { (success, error) in
            if success {
                let url = TMDBClient.Endpoints.webAuth.url
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }

            }
        }
//        performSegue(withIdentifier: "completeLogin", sender: nil)
    }

    //MARK:-  Helper Functions
    private func handleGetRequestToken(success: Bool, error: Error?) {
        if success {
            print(tag + "request token : \(TMDBClient.Auth.requestToken)")
            DispatchQueue.main.async {
                TMDBClient.login(userName: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLogin(success: error:))
            }
        } else {
            print(tag + "error : \(String(describing: error)))")
        }
    }

    private func handleLogin(success: Bool, error: Error?) {
        if success {
            print(tag + "login request token \(TMDBClient.Auth.requestToken)")
            TMDBClient.createSessionId(completion: HandleSessionIdResponse(success: error:))
        } else {
            print(tag + "error : \(String(describing: error)))")
        }
    }

    func HandleSessionIdResponse(success: Bool, error: Error?) {
        if success {
            setLoggingIn(logging: false)
            print(tag + "session ID :  \(TMDBClient.Auth.sessionId)")
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
            }
        } else {
            print(tag + "handle session response error \(String(describing: error))")
        }
    }
    
    private func setLoggingIn(logging:Bool){
        if logging{
            activityIndicator.startAnimating()
        } else {
            activityIndicator.startAnimating()
        }
        emailTextField.isEnabled = !logging
        passwordTextField.isEnabled = !logging
        loginButton.isEnabled = !logging
        loginViaWebsiteButton.isEnabled = !logging
    }

}
