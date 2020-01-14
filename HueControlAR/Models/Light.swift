//
//  Light.swift
//  HueControlAR
//
//  Created by Sarang Borude on 5/14/19.
//  Copyright © 2019 Sarang Borude. All rights reserved.
//

import Foundation
import ChromaColorPicker

struct Light {
    var name: String
    var state: Bool
    var color: LightColor
    var controller: LightControlViewController
}
