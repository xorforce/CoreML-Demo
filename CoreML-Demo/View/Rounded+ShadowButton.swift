//
//  Rounded+ShadowButton.swift
//  CoreML-Demo
//
//  Created by Bhagat  Singh on 01/12/17.
//  Copyright © 2017 Bhagat  Singh. All rights reserved.
//

import UIKit

class Rounded_ShadowButton: UIButton {
    
    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15.0
        self.layer.shadowOpacity = 0.7
        self.layer.cornerRadius = self.frame.height / 2
    }


}
