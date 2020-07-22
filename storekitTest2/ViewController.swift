//
//  ViewController.swift
//  storekitTest2
//
//  Created by 福山帆士 on 2020/07/22.
//  Copyright © 2020 福山帆士. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let purchaseButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        button.setTitle("課金する", for: .normal)
        button.addTarget(self, action: #selector(purchaseButtonPressed), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        purchaseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(purchaseButton)
        
        let purchaseButtonConstraints = [
            purchaseButton.heightAnchor.constraint(equalToConstant: 50),
            purchaseButton.widthAnchor.constraint(equalToConstant: 200),
            purchaseButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            purchaseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        
        NSLayoutConstraint.activate(purchaseButtonConstraints)
        
        
    }
    
    @objc func purchaseButtonPressed() {
        
    }


}

