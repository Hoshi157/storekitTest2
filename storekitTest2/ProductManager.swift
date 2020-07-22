//
//  ProductManager.swift
//  storekitTest2
//
//  Created by 福山帆士 on 2020/07/22.
//  Copyright © 2020 福山帆士. All rights reserved.
//

import Foundation
import StoreKit

// escapingがわからない, NSObjectって何？

// 価格情報取得エラー
public enum ProductManagerError: Error {
    
    case emptyProductIdentifiers
    case noVaidProducts
    case notMatchProductIdentifir
    case skError(message: String)
    case unkown
    
    public var localizedDescription: String {
        switch self {
        case .emptyProductIdentifiers:
            return "プロダクトIDが指定されていません"
        case .noVaidProducts:
            return "有効なプロダクトを取得できませんでした"
        case .notMatchProductIdentifir:
            return "指定したプロダクトIDと取得したプロダクトIDが一致しませんでした"
        case .skError( let message):
            return message
        default:
            return "不明なエラー"
        }
    }
}

// 価格情報を取得するためのクラス
final public class ProductManager: NSObject {
    // 保持用
    static private var managers: Set<ProductManager> = Set()
    // 完了通知(複数)
    public typealias Completion = ([SKProduct], Error?) -> Void
    // 完了通知(ひとつ)
    public typealias CompletionForSingle = (SKProduct?, Error?) -> Void
    
    private var completion: Completion
    
    // 価格問い合わせ用オブジェクト(保持用)
    private var productRequest: SKProductsRequest?
    
    // 初期化
     private init(completion: @escaping Completion) {
        self.completion = completion
    }
    
    // 課金アイテム情報を取得(複数)
    class func request(productIdentifiers: [String], completion: @escaping Completion) {
        
        guard !productIdentifiers.isEmpty else {
            completion([], ProductManagerError.emptyProductIdentifiers)
            return
        }
        
        let productManager = ProductManager(completion: completion)
        
        let productRequest = SKProductsRequest(productIdentifiers: Set<String>(productIdentifiers))
        productRequest.delegate = productManager
        productRequest.start() // delegateでcompletionを読んでいるため呼ばなくていい!!(だから @escaping)
        productManager.productRequest = productRequest
        managers.insert(productManager)
    }
    
    // 課金アイテム情報を取得(ひとつ)
    class func request(productIdentifier: String, completion: @escaping CompletionForSingle) {
        
        ProductManager.request(productIdentifiers: [productIdentifier], completion: { (products, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let product = products.first else {
                completion(nil, ProductManagerError.noVaidProducts)
                return
            }
            
            guard product.productIdentifier == productIdentifier else {
                completion(nil, ProductManagerError.notMatchProductIdentifir)
                return
            }
            
            completion(product, nil) // ここで取得
        })
    }
}

// 情報リクエストのdelegate
extension ProductManager: SKProductsRequestDelegate {
    
    // 成功
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let error = !response.products.isEmpty ? nil : ProductManagerError.noVaidProducts
        completion(response.products, error)
    }
    
    // リクエスト失敗
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        completion([], ProductManagerError.skError(message: error.localizedDescription))
        ProductManager.managers.remove(self)
    }
    
    // リクエスト終了時
    public func requestDidFinish(_ request: SKRequest) {
        ProductManager.managers.remove(self) // managersにSKProductを保持しているため削除
    }
    
}

public extension SKProduct {
    // 価格
    var localizedPrice: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = priceLocale
        return numberFormatter.string(from: price)
    }
}
