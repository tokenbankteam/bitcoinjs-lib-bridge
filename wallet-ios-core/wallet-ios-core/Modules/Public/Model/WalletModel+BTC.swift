//
//  WalletModel+BTC.swift
//  wallet-ios-core
//
//  Created by 仇弘扬 on 2017/12/5.
//  Copyright © 2017年 BitBill. All rights reserved.
//

import Foundation
import SwiftyJSON
import DateToolsSwift

let BTC_SATOSHI: Int64 = 100000000

func BTCFormatString(btc: Int64) -> String {
    if btc == 0 {
        return "0.00"
    }
    let str = String(btc % BTC_SATOSHI)
    let d = Double(btc) / Double(BTC_SATOSHI)
    if str.count > 2 {
        return "\(d)"
    }
    var count = 0
    for char in str.reversed() {
        if char == "0" {
            count += 1
        }
        else
        {
            break
        }
    }
    return String(format: "%.\(8 - count)f", d)
}

extension WalletModel {
    
    static func fetch(by addresses: [String], isAll: Bool = true) -> WalletModel? {
        for wallet in BILWalletManager.shared.wallets {
            if wallet.contain(btcAddresses: addresses, isAll: isAll) {
                return wallet
            }
        }
        return nil
    }
    
    func contain(btcAddress: String) -> Bool {
        guard let set = addresses else { return false }
        let count = set.filter({
            ($0 as? BTCWalletAddressModel)?.address == btcAddress
        }).count
        return count > 0
    }
    
    func contain(btcAddresses: [String], isAll: Bool = true) -> Bool {
        var count = 0
        for address in btcAddresses {
            if contain(btcAddress: address) {
                count += 1
            }
            if !isAll, count >= 1 {
                return true
            }
        }
        return count > 0 && count == btcAddresses.count
    }
	
	func randomAddress() -> BTCWalletAddressModel {
		let count = addresses!.count
		return addresses![Int(arc4random()) % count] as! BTCWalletAddressModel
	}
    
    func lastBTCAddress(success: @escaping (String) -> Void, failure: @escaping (String) -> Void) {
        guard let xpub = mainExtPublicKey else {
            failure(.publicWalletIDError)
            return
        }
        let index = lastAddressIndex
        if index == (addresses?.count)! - 1 {
            guard let address = (addresses?.lastObject as? BTCWalletAddressModel)?.address else {
                failure(.publicWalletGetAddressError)
                return
            }
            success(address)
        }
        else
        {
            BitcoinJSBridge.shared.getAddress(xpub: xpub, index: Int(index), success: { (address) in
                if let add = address as? String {
                    let addModel = bil_btc_wallet_addressManager.newModelIfNeeded(key: "address", value: add)
                    addModel.address = add
                    addModel.index = index
                    addModel.satoshi = 0
                    self.addToAddresses(addModel)
                    success(add)
                } else {
                    failure(.publicWalletGetAddressError)
                }
            }) { (error) in
                failure(error.localizedDescription)
            }
        }
    }
    
    func refreshAddressToSever(index: Int64, success: @escaping ([BTCWalletAddressModel]) -> Void, failure: @escaping (String) -> Void) {
        guard let extPub = mainExtPublicKey else {
            failure(.publicWalletExtKeyError)
            return
        }
        
        guard index > lastAddressIndex else {
            failure("index 小于或等于当前地址，不需要刷新")
            return
        }

        BILNetworkManager.request(request: .refreshAddress(extendedKeyHash: extPub.md5(), index: index), success: { (result) in
            debugPrint(result)
            let json = JSON(result)
            let serverIndex = json["indexNo"].int64Value
            var localIndex = self.lastAddressIndex
            if localIndex > serverIndex {
                localIndex = serverIndex
            }
            self.lastAddressIndex = serverIndex
            if index > serverIndex {
                failure(.publicWalletNoMoreAddress)
                return
            }
            self.generateAddresses(from: localIndex, to: self.lastAddressIndex, success: success, failure: { (msg, code) in
                failure(msg)
            })
        }, failure: { (msg, code) in
            debugPrint(msg)
            failure(msg)
        })
    }
	
    func getNewBTCAddress(success: @escaping (String) -> Void, failure: @escaping (String) -> Void) {
        let tempIndex = lastAddressIndex + 1
        refreshAddressToSever(index: tempIndex, success: { (models) in
            guard let address = models.last?.address else {
                failure(.publicWalletGenerateAddressError)
                return
            }
            success(address)
        }, failure: failure)
	}
    
    func generateAddresses(from: Int64, to: Int64, success: @escaping ([BTCWalletAddressModel]) -> Void, failure: @escaping (_ message: String, _ code: Int) -> Void) {
        guard from <= to else {
            failure(.publicWalletIndexError, -1)
            return
        }
		let beginDate = Date()
        BitcoinJSBridge.shared.getAddresses(xpub: mainExtPublicKey!, fromIndex: from, toIndex: to, success: { (result) in
            debugPrint(result)
            guard let array = result as? [String] else {
                failure(.publicWalletGenerateAddressError, -1)
                return
            }
            var models = [BTCWalletAddressModel]()
            for address in array {
                let tx = bil_btc_wallet_addressManager.newModelIfNeeded(key: "address", value: address)
                tx.address = address
                tx.satoshi = 0
                self.addToAddresses(tx)
                models.append(tx)
            }
            self.lastAddressIndex = to
            do {
                try BILWalletManager.shared.saveWallets()
                success(models)
				let endDate = Date()
				debugPrint("生成 \(to - from + 1) 个地址，用时：\(endDate.seconds(from: beginDate))s")
            } catch {
                failure(error.localizedDescription, -2)
            }
        }) { (error) in
            debugPrint(error)
            failure(error.localizedDescription, -2)
        }
    }
	
	func updateUTXOAtLocal() {
		for add in btc_addressModels {
			add.satoshi = 0
		}
		for tx in btc_transactionArray {
			debugPrint("------")
			if tx.height == -1 {
				continue
			}
			for add in tx.inputAddressModels {
				if let wAdd = bil_btc_wallet_addressManager.fetch(key: "address", value: add.address!) {
					debugPrint("add: \(add.address!) - \(add.satoshi)")
					wAdd.satoshi -= add.satoshi
					wAdd.isUsed = true
				}
			}
			for add in tx.outputAddressModels {
				if let wAdd = bil_btc_wallet_addressManager.fetch(key: "address", value: add.address!) {
					debugPrint("add: \(add.address!) + \(add.satoshi)")
					wAdd.satoshi += add.satoshi
					wAdd.isUsed = true
				}
			}
		}
		do {
			try BILWalletManager.shared.saveWallets()
            NotificationCenter.default.post(name: .localUTXODidChanged, object: nil)
		} catch {
			debugPrint("保存本地 UTXO 数据失败")
		}
	}
	
	var btc_addressModels: [BTCWalletAddressModel] {
		get {
			return self.addresses?.array as! [BTCWalletAddressModel]
		}
	}
	
    var btc_transactionArray: [BTCTransactionModel] {
        get {
            return btcTransactions!.sortedArray(comparator: { (lhs, rhs) -> ComparisonResult in
                let l = lhs as! BTCTransactionModel
                let r = rhs as! BTCTransactionModel
                return r.createdDate!.compare(l.createdDate!)
            }) as! [BTCTransactionModel]
        }
    }
    
    var btc_balanceString: String {
        get {
            return BTCFormatString(btc: btcBalance)
        }
    }
    var btc_unconfirm_balanceString: String {
        get {
            return BTCFormatString(btc: btcUnconfirmBalance)
        }
    }
    var btc_currencyString: String {
        get {
            return getCurrency(btcValue: btcBalance)
        }
    }
}
