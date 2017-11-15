//
//  ViewController.swift
//  Wheel
//
//  Created by Walter Nordström on 2017-11-15.
//  Copyright © 2017 Walter Nordström. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var spinnerView: SpinnerView!
    @IBOutlet weak var spinnerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinnerView.delegate = self
    }
}

extension ViewController: SpinnerViewDelegate {
    func didRotateTo(angle: Int) {
        spinnerLabel.text = "\(angle)"
        spinnerLabel.sizeToFit()
    }
    
    
}
