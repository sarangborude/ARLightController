//
//  CGFloat+Map.swift
//  HueControlAR
//
//  Created by Sarang Borude on 5/21/19.
//  Copyright © 2019 Sarang Borude. All rights reserved.
//

import UIKit


extension CGFloat {
    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }
}
