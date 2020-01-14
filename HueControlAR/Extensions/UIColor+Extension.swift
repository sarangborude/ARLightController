//
//  UIColor+Extension.swift
//  HueControlAR
//
//  Created by Sarang Borude on 5/15/19.
//  Copyright © 2019 Sarang Borude. All rights reserved.
//

import UIKit

public extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
    
    var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b, a)
    }
    
    internal var lightColor: LightColor {
        var h: Int = 0
        var s: Int = 0
        var b: Int = 0
        let hsbaColorValue = self.hsba
        h = Int(hsbaColorValue.hue.map(from: 0.0...1.0, to: 0.0...65535.0))
        s = Int(hsbaColorValue.saturation.map(from: 0.0...1.0, to: 0.0...254.0))
        b = Int(hsbaColorValue.brightness.map(from: 0.0...1.0, to: 0.0...254.0))
        return LightColor(hue: h, saturation: s, brightness: b, color: self)
    }
}
