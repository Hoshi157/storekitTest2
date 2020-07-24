//
//  PurchaseManager.swift
//  storekitTest2
//
//  Created by 福山帆士 on 2020/07/22.
//  Copyright © 2020 福山帆士. All rights reserved.
//

import Foundation
import StoreKit

// 課金エラー
struct PurchaseManegerErrors: OptionSet, Error {
    public var rawValue: Int
    static let connotMakePayments = PurchaseManegerErrors(rawValue: 1 << 0)
    static let purchasing         = PurchaseManegerErrors(rawValue: 1 << 1)
    static let restoreing         = PurchaseManegerErrors(rawValue: 1 << 2)
    
    public var localizedDescription: String {
        var message = ""
        
        if self.contains(.connotMakePayments) {
            message += "設定で購入が無効になっています"
        }
        
        if self.contains(.purchasing) {
            message += "課金処理中です"
        }
        
        if self.contains(.restoreing) {
            message += "リストア中です"
        }
        return message
    }
}

// 課金するためのクラス
open class PurchaseManager: NSObject {
    
    public static var shared = PurchaseManager()
    
    weak var delegate: PurchaseManagerDelegate?
    
    private var productIdentifir: String?
    private var isRestore: Bool = false
    
    // 課金開始
    public func purchase(product: SKProduct) {
        
        var errors: PurchaseManegerErrors = []
        
        // 課金可能かどうか
        if SKPaymentQueue.canMakePayments() == false {
            errors.insert(.connotMakePayments)
        }
        
        // 課金処理中
        if productIdentifir != nil {
            errors.insert(.purchasing)
        }
        
        // リストア中
        if isRestore == true {
            errors.insert(.restoreing)
        }
        
        guard errors.isEmpty else {
            delegate?.purchaseManager(self, didFaidTransactinWithError: errors)
            return
        }
        
        // 未処理のトランザクションがあればそれを利用
        let transactions = SKPaymentQueue.default().transactions
        for transaction in transactions {
            if transaction.transactionState == .purchased { continue } // トランザクションの課金処理が終わってたら次のトランザクションへ
            
            // 引数に指定したProductと未処理のtransactionのIdentifirが同じであれば処理する(一度購入処理をしたが(userが)何らかの理由で処理が中断してしまっていた)
            if transaction.payment.productIdentifier == product.productIdentifier {
                guard let window = UIApplication.shared.delegate?.window else { return }
                let ac = UIAlertController(title: nil, message: "\(product.localizedTitle)は購入処理が中断されていました。\nこのまま無料でダウンロードできます", preferredStyle: .alert)
                let action = UIAlertAction(title: "続行", style: .default, handler: { [weak self] (action: UIAlertAction) in
                    if let strongSelf = self { // self = PurchaseManager
                        strongSelf.productIdentifir = product.productIdentifier
                        strongSelf.completeTransaction(transaction)
                    }
                })
                ac.addAction(action)
                DispatchQueue.main.async {
                    window?.rootViewController?.present(ac, animated: true)
                    return
                }
            }
        }
        
        // 課金処理開始
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
        productIdentifir = product.productIdentifier
        
    }
    
    // リストア開始
    public func restore() {
        if isRestore == false {
            isRestore = true
            SKPaymentQueue.default().restoreCompletedTransactions()
        }else {
            delegate?.purchaseManager(self, didFaidTransactinWithError: PurchaseManegerErrors.restoreing)
        }
    }
    
    // 課金終了処理
    private func completeTransaction(_ transaction: SKPaymentTransaction) {
        
        if transaction.payment.productIdentifier == self.productIdentifir {
            // 課金終了
            delegate?.purchaseManager(self, didFinishTransaction: transaction, decitionHandler: { (complete) in
                if complete == true {
                    // トランザクション終了
                    SKPaymentQueue.default().finishTransaction(transaction)
                }
            })
            productIdentifir = nil
        }else {
            // 課金終了(以前中断された課金処理)
            delegate?.purchaseManager(self, didFinishUntreatedTransaction: transaction, decitionHandler: { (complete) in
                if complete == true {
                    SKPaymentQueue.default().finishTransaction(transaction)
                }
            })
        }
    }
    
    // 課金失敗
    private func faildTransaction(_ transaction: SKPaymentTransaction) {
        delegate?.purchaseManager(self, didFaidTransactinWithError: transaction.error)
        productIdentifir = nil
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restoreTransaction(_ transaction: SKPaymentTransaction) {
        delegate?.purchaseManager(self, didFinishTransaction: transaction, decitionHandler: { (complete) in
            if complete == true {
                // トランザクション終了
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        })
    }
    
    private func deferredTransaction(_ transaction: SKPaymentTransaction) {
        // 承認待ち
        delegate?.purchaseManagerDidDiferred(self)
        productIdentifir = nil
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    
    // トランザクションの課金状態が更新されるたびに呼ばれる
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                // 課金中
                break
            case .purchased:
                // 課金完了
                completeTransaction(transaction)
                break
            case .failed:
                // 課金失敗
                faildTransaction(transaction)
                break
            case .restored:
                // リストア
                restoreTransaction(transaction)
                break
            case .deferred:
                //承認待ち
                deferredTransaction(transaction)
                break
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // リストア失敗時
        delegate?.purchaseManager(self, didFaidTransactinWithError: error)
        isRestore = false
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // リストア完了時
        delegate?.purchaseManagerDidFinishRestore(self)
        isRestore = false
    }
    
    
    
}


protocol PurchaseManagerDelegate: NSObjectProtocol {
    
    // 課金完了
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishTransaction transaction: SKPaymentTransaction, decitionHandler: (_ complete: Bool) -> Void)
    
    // 課金完了(中断していたもの)
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishUntreatedTransaction transaction: SKPaymentTransaction, decitionHandler: (_ complete: Bool) -> Void)
    
    // リストア完了
    func purchaseManagerDidFinishRestore(_ purchaseManager: PurchaseManager)
    
    // 課金失敗
    func purchaseManager(_ purchaseManager: PurchaseManager, didFaidTransactinWithError error: Error?)
    
    // 承認待ち
    func purchaseManagerDidDiferred(_ purchaseManager: PurchaseManager)
}

extension PurchaseManagerDelegate {
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishTransaction transaction: SKPaymentTransaction, decitionHandler: (_ complete: Bool) -> Void) {
        decitionHandler(false)
    }
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFinishUntreatedTransaction transaction: SKPaymentTransaction, decitionHandler: (_ complete: Bool) -> Void) {
        decitionHandler(false)
    }
    
    func purchaseManagerDidFinishRestore(_ purchaseManager: PurchaseManager) {}
    
    func purchaseManager(_ purchaseManager: PurchaseManager, didFaidTransactinWithError error: Error?) {}
    
    func purchaseManagerDidDiferred(_ purchaseManager: PurchaseManager) {}
}
