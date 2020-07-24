//
//  ViewController.swift
//  storekitTest2
//
//  Created by 福山帆士 on 2020/07/22.
//  Copyright © 2020 福山帆士. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    
    private var productIdentifiers = ["productIdentifiers1"]
    
    private let purchaseButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        button.setTitle("課金する", for: .normal)
        button.addTarget(self, action: #selector(purchaseButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private var priceText: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        textField.textAlignment = .center
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        purchaseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(purchaseButton)
        
        priceText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(priceText)
        
        let purchaseButtonConstraints = [
            purchaseButton.heightAnchor.constraint(equalToConstant: 50),
            purchaseButton.widthAnchor.constraint(equalToConstant: 200),
            purchaseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            purchaseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        
        NSLayoutConstraint.activate(purchaseButtonConstraints)
        
        let priceTextConstraints = [
            priceText.heightAnchor.constraint(equalToConstant: 50),
            priceText.widthAnchor.constraint(equalToConstant: 150),
            priceText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            priceText.topAnchor.constraint(equalTo: view.topAnchor, constant: 50)
        ]
        
        NSLayoutConstraint.activate(priceTextConstraints)
        
        displayToTextOfPrice()
        
    }
    
    @objc func purchaseButtonPressed() {
        
        purchase(productIdentifier: productIdentifiers.first!)
        
    }
    
    func displayToTextOfPrice() {
        ProductManager.request(productIdentifiers: productIdentifiers, completion: { [weak self] (products: [SKProduct], error: Error?) in
            
            guard error != nil else {
                return
            }
            
            for product in products {
                let priceString = product.localizedPrice
                DispatchQueue.main.async {
                    self?.priceText.text = priceString
                }
            }
        })
    }
    
    private func purchase(productIdentifier: String) {
        
        // デリゲート設定
        PurchaseManager.shared.delegate = self
        
        // プロダクト情報を取得
        ProductManager.request(productIdentifier: productIdentifier, completion: { [weak self] (product: SKProduct?, error: Error?) in
            guard error == nil, let product = product else {
                self?.purchaseManager(PurchaseManager.shared, didFaidTransactinWithError: error)
                return
            }
            
            // 課金処理開始
            PurchaseManager.shared.purchase(product: product)
        })
    }
    
    private func startRestore() {
        // デリゲート設定
        PurchaseManager.shared.delegate = self
        
        // リストア開始
        PurchaseManager.shared.restore()
    }


}

extension ViewController: PurchaseManagerDelegate {
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishTransaction transaction: SKPaymentTransaction, decitionHandler: (Bool) -> Void) {
        
        let ac = UIAlertController(title: "purchase finish", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
        
        
        
        
        decitionHandler(true)
    }
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishUntreatedTransaction transaction: SKPaymentTransaction, decitionHandler: (Bool) -> Void) {
        let ac = UIAlertController(title: "purchase untreated finish", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
        
        decitionHandler(true)
    }
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFaidTransactinWithError error: Error?) {
        let ac = UIAlertController(title: "error", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }
    
    func purchaseManagerDidFinishRestore(_ purchaseManager: PurchaseManager) {
        
        let ac = UIAlertController(title: "did finish restore", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }
    
    func purchaseManagerDidDiferred(_ purchaseManager: PurchaseManager) {
        let ac = UIAlertController(title: "did diferred", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }
    
}

