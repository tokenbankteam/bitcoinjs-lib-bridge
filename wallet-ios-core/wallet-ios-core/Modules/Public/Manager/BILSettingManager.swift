//
//  BILSettingManager.swift
//  wallet-ios-core
//
//  Created by 仇弘扬 on 2017/12/27.
//  Copyright © 2017年 BitBill. All rights reserved.
//

import UIKit

extension String {
    static let bil_UserDefaultsKey_isHomeShortcutEnabled    = "bil_isHomeShortcutEnabled"
    static let bil_UserDefaultsKey_isSoundEnabled           = "bil_isSoundEnabled"
    static let bil_UserDefaultsKey_currencyType             = "bil_currencyType"
    static let bil_UserDefaultsKey_currentLanguageType             = "AppleLanguages"
}

enum CurrencyType: Int {
    case cny
    case usd
    
    var symbol: String {
        get {
            switch self {
            case .cny:
                return "¥"
            case .usd:
                return "$"
            }
        }
    }
    
    var symbolName: String {
        get {
            switch self {
            case .cny:
                return "CNY"
            case .usd:
                return "USD"
            }
        }
    }
	
	var name: String {
		get {
			switch self {
			case .cny:
				return .publicCurrencyCNYName
			case .usd:
				return .publicCurrencyUSDName
			}
		}
	}
	
	var localizedName: String { get { return name } }
    
    var rate: Double {
        get {
            switch self {
            case .cny:
                return BILWalletManager.shared.cnyExchangeRate
            case .usd:
                return BILWalletManager.shared.usdExchangeRate
            }
        }
    }
    
}

enum BILLanguageType: String {
    case zh_cn = "zh-Hans-US"
    case en = "en"
    
    var name: String {
        get {
            switch self {
            case .zh_cn:
                return "简体中文"
            case .en:
                return "English"
            }
        }
    }
}

class BILSettingManager: NSObject {
    static var isHomeShortcutEnabled: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: .bil_UserDefaultsKey_isHomeShortcutEnabled)
        }
        get {
            if UserDefaults.standard.object(forKey: .bil_UserDefaultsKey_isHomeShortcutEnabled) == nil
            {
                self.isHomeShortcutEnabled = true
            }
            return UserDefaults.standard.bool(forKey: .bil_UserDefaultsKey_isHomeShortcutEnabled)
        }
    }
    
    static var isSoundEnabled: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: .bil_UserDefaultsKey_isSoundEnabled)
        }
        get {
            if UserDefaults.standard.object(forKey: .bil_UserDefaultsKey_isSoundEnabled) == nil
            {
                self.isSoundEnabled = true
            }
            return UserDefaults.standard.bool(forKey: .bil_UserDefaultsKey_isSoundEnabled)
        }
    }
    
    static var currencyType: CurrencyType {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: .bil_UserDefaultsKey_currencyType)
        }
        get {
            if UserDefaults.standard.object(forKey: .bil_UserDefaultsKey_currencyType) == nil
            {
                self.currencyType = .usd
            }
            return CurrencyType(rawValue: UserDefaults.standard.integer(forKey: .bil_UserDefaultsKey_currencyType)) ?? .usd
        }
    }
    
    static var currentLanguage: BILLanguageType {
        set {
            UserDefaults.standard.set([newValue.rawValue], forKey: .bil_UserDefaultsKey_currentLanguageType)
        }
        get {
            guard let str  = (UserDefaults.standard.array(forKey: .bil_UserDefaultsKey_currentLanguageType) as? [String])?.first else {
                return .en
            }
            return BILLanguageType(rawValue: str) ?? .en
        }
    }
}
