//
//  LightControlViewController.swift
//  HueControlAR
//
//  Created by Sarang Borude on 5/21/19.
//  Copyright © 2019 Sarang Borude. All rights reserved.
//

import UIKit
import ChromaColorPicker
import SceneKit

protocol LightColorChangeHandler: class {
    func lightColorChanged(lightColor: LightColor, lightName: String, lightNode: SCNNode)
}

class LightControlViewController: UIViewController {
    
    var colorPicker: ChromaColorPicker?
    weak var delegate: LightColorChangeHandler?
    var lightName: String?
    var lightNode: SCNNode?
    var previousColor = UIColor.black
    var setColor = UIColor.white

    @IBOutlet weak var colorPickerContainerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func addColorPicker() {
        colorPicker = ChromaColorPicker(frame: colorPickerContainerView.frame)
        guard let colorPicker = colorPicker else { return }
        colorPicker.delegate = self
        colorPicker.padding = 5
        colorPicker.stroke = 3
        colorPicker.hexLabel.isHidden = true
        colorPicker.addTarget(self, action: #selector(colorValueChanged), for: .editingDidEnd)
        
        view.addSubview(colorPicker)
    }
}

extension LightControlViewController: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        let tempColor = previousColor
        previousColor = colorPicker.currentColor
        colorPicker.adjustToColor(tempColor)
        var lightColor = UIColor.black.lightColor
        if previousColor == UIColor.black {
            colorPicker.adjustToColor(setColor)
            lightColor = setColor.lightColor
        } else {
            colorPicker.adjustToColor(UIColor.black)
        }
        
        guard let lightName = self.lightName,
            let lightNode = self.lightNode else { return }
        delegate?.lightColorChanged(lightColor: lightColor, lightName: lightName, lightNode: lightNode)
    
    }
    
    @objc func colorValueChanged() {
        print("Color Value Changed!!!!!!!!!!!!!!!!")
        guard let colorPicker = colorPicker else { return }
        
        let lightColor = colorPicker.currentColor.lightColor
        setColor = colorPicker.currentColor
        print("lightColor: \(lightColor)")
        guard let lightName = self.lightName,
            let lightNode = self.lightNode else { return }
        delegate?.lightColorChanged(lightColor: lightColor, lightName: lightName, lightNode: lightNode)
    }
}
