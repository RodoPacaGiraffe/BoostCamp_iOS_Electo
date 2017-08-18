//
//  SettingViewController.swift
//  Electo
//
//  Created by Alpaca on 2017. 8. 17..
//  Copyright © 2017년 RodoPacaGiraffe. All rights reserved.
//

import UIKit

protocol SettingDelegate: class {
    func groupingChnaged()
}

class SettingViewController: UITableViewController {
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var dataAllowedSwitch: UISwitch!
    
    var settingDelegate: SettingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSwitch()
        setSlider()
        
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch sender.value {
        case Clustering.interval1:
            sender.setValue(GroupingInterval.level1.rawValue, animated: true)
        case Clustering.interval2:
            sender.setValue(GroupingInterval.level2.rawValue, animated: true)
        case Clustering.interval3:
            sender.setValue(GroupingInterval.level3.rawValue, animated: true)
        case Clustering.interval4:
            sender.setValue(GroupingInterval.level4.rawValue, animated: true)
        default:
            sender.setValue(GroupingInterval.level5.rawValue, animated: true)
        }
        
        Constants.timeIntervalBoundary = Double(sender.value)
        print(Constants.timeIntervalBoundary)
        
        UserDefaults.standard.set(Constants.timeIntervalBoundary, forKey: "timeIntervalBoundary")
        UserDefaults.standard.synchronize()
        
        self.settingDelegate?.groupingChnaged()
    }
    
    @IBAction func networkAllowSwitch(_ sender: UISwitch) {
        print(sender.state)
        if sender.isOn {
            let alertController = UIAlertController(title: "", message: "It will use network data", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                Constants.dataAllowed = true
                
                UserDefaults.standard.set(Constants.dataAllowed, forKey: "dataAllowed")
                UserDefaults.standard.synchronize()
            })
            let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: { (action) in
                Constants.dataAllowed = false
                
                UserDefaults.standard.set(Constants.dataAllowed, forKey: "dataAllowed")
                UserDefaults.standard.synchronize()
            })
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            print("on")
            present(alertController, animated: true, completion: nil)
        } else {
            print("off")
            Constants.dataAllowed = false
            UserDefaults.standard.set(Constants.dataAllowed, forKey: "dataAllowed")
            UserDefaults.standard.synchronize()
        }
    }
    
    func setSwitch() {
        let dataAllowed: Bool = UserDefaults.standard.object(forKey: "dataAllowed") as? Bool ?? false
        dataAllowedSwitch.setOn(dataAllowed, animated: false)
    }
    
    func setSlider() {
        let timeIntervalBoundary: Double = UserDefaults.standard
            .object(forKey: "timeIntervalBoundary") as? Double ?? Double(GroupingInterval.level3.rawValue)
        slider.setValue(Float(timeIntervalBoundary), animated: false)
    }
}
