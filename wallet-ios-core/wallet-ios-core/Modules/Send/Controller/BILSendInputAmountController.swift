//
//  BILSendInputAmountController.swift
//  wallet-ios-core
//
//  Created by 仇弘扬 on 2017/12/12.
//  Copyright © 2017年 BitBill. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class BILSendInputAmountController: BILBaseViewController, UITextFieldDelegate {
    
    let chooseWalletSegue = "BILInputToChooseWalletSegue"
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cnyLabel: BILExchangeRateLabel!
    @IBOutlet weak var coinNameLabel: UILabel!
    @IBOutlet weak var nextButtonBottomSpace: NSLayoutConstraint!
	@IBOutlet weak var sendAllItem: UIBarButtonItem!
	@IBOutlet weak var nextButton: BILGradientButton!
	
    var sendModel: BILSendModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        // Do any additional setup after loading the view.
        coinNameLabel.text = sendModel?.coinType.name
        amountTextField.becomeFirstResponder()
    }
	
	override func languageDidChanged() {
		super.languageDidChanged()
		title = "Send amount".bil_ui_localized
		sendAllItem.title = "Total balance".bil_ui_localized
		nextButton.setTitle("Next".bil_ui_localized, for: .normal)
	}
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc internal func keyboardWillShow(_ notification : Notification?) {
        guard let info = notification?.userInfo else { return }
        var animationCurve = UIViewAnimationOptions.curveEaseOut
        if let curve = info[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
            animationCurve = UIViewAnimationOptions(rawValue: curve)
        }
        
        var animationDuration = 0.25
        //  Getting keyboard animation duration
        if let duration = info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            //Saving animation duration
            if duration != 0.0 {
                animationDuration = duration
            }
        }
        
        if let kbFrame = info[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.nextButtonBottomSpace.constant = kbFrame.height + 30
            }, completion: { (finished) in
                
            })
        }
        
    }
    
    @objc internal func keyboardWillHide(_ notification : Notification?) {
        guard let info = notification?.userInfo else { return }
        var animationCurve = UIViewAnimationOptions.curveEaseOut
        if let curve = info[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
            animationCurve = UIViewAnimationOptions(rawValue: curve)
        }
        
        var animationDuration = 0.25
        //  Getting keyboard animation duration
        if let duration = info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            //Saving animation duration
            if duration != 0.0 {
                animationDuration = duration
            }
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.nextButtonBottomSpace.constant = 30
        }, completion: { (finished) in
            
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard var text = textField.text else { return true }
		
        let rangeLocation =  text.index(text.startIndex, offsetBy: range.location)
        if range.length == 0 {
            text.insert(contentsOf: string, at:rangeLocation)
        } else {
            let upperLocation = text.index(rangeLocation, offsetBy: range.length)
            text.removeSubrange(rangeLocation..<upperLocation)
        }
		
		if text.count == 0 {
			cnyLabel.btcValue = 0
		}
        
        if text.count > 30 {
            return false
        }
        
        if let coinAmount = Double(text) {
            cnyLabel.btcValue = coinAmount
        }
        
        if text.contains(".") {
            let array = text.components(separatedBy: ".")
            if array.count > 2 {
                return false
            }
            let decimalPlace = array[1]
            return decimalPlace.count <= "\(BTC_SATOSHI)".count - 1
        }
        
        return true
    }
    
    
    
    @IBAction func sendAllBalance(_ sender: Any) {
        sendModel?.isSendAll = true
        performSegue(withIdentifier: chooseWalletSegue, sender: nil)
    }
    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == chooseWalletSegue {
            guard let amount = amountTextField.text, !(amount.isEmpty) else {
                showTipAlert(title: .sendAmountCheckTipTitle, msg: .sendAmountCheckTipMessageEmpty)
                return false
            }
            guard let amountD = Double(amount), amountD > 0 else {
                showTipAlert(title: .sendAmountCheckTipTitle, msg: .sendAmountCheckTipMessageZero)
                return false
            }
			sendModel?.isSendAll = false
			sendModel?.wallet = nil
            sendModel?.amount = amount
        }
        return true
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == chooseWalletSegue {
            let cont = segue.destination as! BILSendChooseWalletController
            cont.sendModel = sendModel
        }
    }

}
