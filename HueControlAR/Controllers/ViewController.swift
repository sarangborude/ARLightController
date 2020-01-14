//
//  ViewController.swift
//  HueControlAR
//
//  Created by Sarang Borude on 5/12/19.
//  Copyright © 2019 Sarang Borude. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import SwiftyJSON

enum AppState {
    case scanRoomAndSaveLights
    case relocalizing
    case controlLights
}


class ViewController: UIViewController, ARSCNViewDelegate {
    
    var appState: AppState = .scanRoomAndSaveLights
    
    var lights = [String: Light]()
    
    var lightColor = LightColor(hue: 8402, saturation: 140, brightness: 254, color: UIColor.white)
    
    let hueAPIToken = "<Your api key here>"
    let baseURLString = "https://<IP of your philips hue hub>/api/"
    
    let testURL = "http://<ip of your philips hue hub>/api/<your api key>/lights/3/state"
    
    var sphereCount = 0
    
    var isColorPickerActive = false
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var activateLightControlButton: UIButton!
    @IBOutlet weak var pickColorButton: UIButton!
    @IBOutlet weak var setColorButton: UIButton!
    @IBOutlet weak var colorPickerImage: UIImageView!
    @IBOutlet weak var colorPickerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickColorButton.isHidden = true
        setColorButton.isHidden = true
        colorPickerImage.isHidden = true
        colorPickerButton.isHidden = true
        activateLightControlButton.layer.cornerRadius = 8
        pickColorButton.layer.cornerRadius = 8
        setColorButton.layer.cornerRadius = 8
        colorPickerButton.layer.cornerRadius = 8
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //sceneView.debugOptions = [.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: - IBActions
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        //let lightStatus = sender.isOn ? 1 : 0
        var body = [
            "on" : sender.isOn
        ]
        
        Alamofire.request(testURL, method: .put, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                guard let value = response.result.value else { return }
                let hueResponse = JSON(value)
                print(hueResponse)
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    @IBAction func sceneViewTapped(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        switch appState {
        case .scanRoomAndSaveLights:
            if sphereCount <= 3 {
                guard let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else { return }
                guard let anchor = hitResult.anchor as? ARPlaneAnchor else { return }
                guard let anchorNode = sceneView.node(for: anchor) else { return }
                let orientation = anchorNode.worldOrientation
                let transform = hitResult.worldTransform
                let position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                let planeNode = createPlaneNode(position: position, orientation: orientation)
                sphereCount += 1
                planeNode.name = String(sphereCount)
                let viewController = createLightControlControllerFor(lightName: String(sphereCount), lightNode: planeNode)
                sceneView.scene.rootNode.addChildNode(planeNode)
                //sphereNode.name = String(sphereCount)
                //sceneView.scene.rootNode.addChildNode(sphereNode)
                let light = Light(name: String(sphereCount), state: true, color: lightColor, controller: viewController)
                lights[String(sphereCount)] = light
            }
            
        case .controlLights:
            for result in sceneView.hitTest(location) {
                guard let lightName = result.node.name else { continue }
                setLightStatusFor(lightName: lightName, node: result.node)
                return
            }
        default:
            break
        }
    }
    
    @IBAction func activateLightControl(_ sender: UIButton) {
        appState = AppState.controlLights
        suspendARPlaneDetection()
        hideARPlaneNodes()
        activateLightControlButton.isHidden = true
        colorPickerButton.isHidden = false
    }
    
    @IBAction func pickColorTapped(_ sender: UIButton) {
        print("pickColorTapped")
        guard let frame = sceneView.session.currentFrame else {
            print("Cannot get frame")
            return }
        do {
            let sampler = try CapturedImageSampler(frame: frame)
            let width = sceneView.bounds.width
            let height = sceneView.bounds.height
            guard let color = sampler.getColor(atX: (width/2)/width, y: (height/2)/height) else {
                print("Cannot get color")
                return }
            colorPickerImage.tintColor = color
            let lightColor = color.lightColor
            self.lightColor = lightColor
            print("lightColor: \(lightColor)")
        } catch {
            print(error)
        }
    }
    
    @IBAction func setColorTapped(_ sender: Any) {
        let viewCenter = CGPoint(x: sceneView.bounds.width / 2, y: sceneView.bounds.height / 2)
        for result in sceneView.hitTest(viewCenter) {
            guard let lightName = result.node.name else { continue }
            setLightColorFor(lightName: lightName, node: result.node, color: self.lightColor)
            return
        }
    }
    
    
    @IBAction func colorPickerTapped(_ sender: Any) {
        
        setColorButton.isHidden = !setColorButton.isHidden
        pickColorButton.isHidden = !pickColorButton.isHidden
        colorPickerImage.isHidden = !colorPickerImage.isHidden
        
        if isColorPickerActive {
            colorPickerButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            colorPickerButton.imageView?.tintColor = UIColor.black
        } else {
            colorPickerButton.backgroundColor = UIColor.cyan.withAlphaComponent(0.8)
            colorPickerButton.imageView?.tintColor = UIColor.white
        }
        isColorPickerActive = !isColorPickerActive
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch(camera.trackingState) {
        case .normal:
            print("Camera Tracking Normal")
        case .notAvailable:
            print("Camera Tracking Not Available")
        case .limited(let reason):
            print("Camera Tracking Limited: \(reason)")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("Adding plane Anchor")
        let planeNode = createARPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
        
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("Updating plane Anchor")
        updateARPlaneNode(planeNode: node.childNodes[0], planeAnchor: planeAnchor)
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("Removing Plane Anchor")
        removeARPlaneNode(node: node)
    }
    
    func createARPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.yellow.withAlphaComponent(0.4)
        planeGeometry.materials = [planeMaterial]
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        return planeNode
    }
    
    func updateARPlaneNode(planeNode: SCNNode, planeAnchor: ARPlaneAnchor) {
        guard let planeGeometry = planeNode.geometry as? SCNPlane else { return }
        planeGeometry.width = CGFloat(planeAnchor.extent.x)
        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
    
    func suspendARPlaneDetection() {
        guard let config = sceneView.session.configuration as? ARWorldTrackingConfiguration else { return }
        config.planeDetection = []
        sceneView.session.run(config)
    }
    
    func hideARPlaneNodes() {
        for anchor in (self.sceneView.session.currentFrame?.anchors)! {
            if let node = self.sceneView.node(for: anchor) {
                for child in node.childNodes {
                    child.removeFromParentNode()
                    sceneView.session.remove(anchor: anchor)
                    //let material = child.geometry?.materials.first!
                    //material?.colorBufferWriteMask = []
                }
            }
        }
    }
    
    func removeARPlaneNode(node: SCNNode) {
        for childNode in node.childNodes {
            childNode.removeFromParentNode()
        }
    }

    func createPlaneNode(position: SCNVector3, orientation: SCNQuaternion) -> SCNNode {
        let planeGeometry = SCNPlane(width: 0.4, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        material.specular.contents = UIColor.white
        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(position.x, position.y, position.z + 0.05)
        planeNode.eulerAngles.y = .pi * orientation.y //Why this works?
        
        return planeNode
    }
    
    func createLightControlControllerFor(lightName: String, lightNode: SCNNode) -> LightControlViewController {
        let lightControlViewController = UIStoryboard(name: "LightControl", bundle: nil).instantiateInitialViewController() as! LightControlViewController
        DispatchQueue.main.async {
            lightControlViewController.delegate = self
            lightControlViewController.lightName = lightName
            lightControlViewController.lightNode = lightNode
            lightControlViewController.willMove(toParent: self)
            self.addChild(lightControlViewController)
            lightControlViewController.view.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
            self.view.addSubview(lightControlViewController.view)
            self.show(viewController: lightControlViewController, on: lightNode)
        }
        return lightControlViewController
    }
    
    private func show(viewController: LightControlViewController, on node: SCNNode) {
        let material = SCNMaterial()
        
        //material.isDoubleSided = true
        //material.cullMode = .front
        viewController.view.isOpaque = false
        material.diffuse.contents = viewController.view
        node.geometry?.materials = [material]
        viewController.view.backgroundColor = UIColor.clear
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            viewController.addColorPicker()
        }
    }
    
    //MARK: - Networking
    func setLightStatusFor(lightName: String, node: SCNNode) {
        
        guard var light = lights[lightName],
            //        let geometry = node.geometry as? SCNSphere else { return }
            let geometry = node.geometry as? SCNPlane else { return }
        let newState = !light.state
        let shrinkAction = SCNAction.scale(to: 0.5, duration: 0.1)
        let growAction = SCNAction.scale(to: 1.0, duration: 0.1)
        let completionAction = SCNAction.customAction(duration: 0.01) { (_, _) in
            if newState == false {
                geometry.firstMaterial?.transparency = 0.2
            } else {
                geometry.firstMaterial?.transparency = 1.0
            }
        }
        let sequence = SCNAction.sequence([shrinkAction, growAction, completionAction])
        node.runAction(sequence)
        
        
        light.state = newState
        lights.updateValue(light, forKey: lightName)
        let body = [
            "on" : newState
        ]
        let url = "\(baseURLString)/\(hueAPIToken)/lights/\(lightName)/state"
        Alamofire.request(url, method: .put, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                guard let value = response.result.value else { return }
                let hueResponse = JSON(value)
                print(hueResponse)
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    func setLightColorFor(lightName: String, node: SCNNode, color: LightColor) {
        
        guard var light = lights[lightName],
            //let geometry = node.geometry as? SCNSphere else { return }
            let geometry = node.geometry as? SCNPlane else { return }
        light.controller.colorPicker?.adjustToColor(color.color)
        light.color = color
        lights.updateValue(light, forKey: lightName)
        let body: [String: Any] = [
            "on": true,
            "hue": color.hue,
            "sat": color.saturation,
            "bri": color.brightness
        ]
        let url = "\(baseURLString)/\(hueAPIToken)/lights/\(lightName)/state"
        Alamofire.request(url, method: .put, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                guard let value = response.result.value else { return }
                let hueResponse = JSON(value)
                print(hueResponse)
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

extension ViewController: LightColorChangeHandler {
    func lightColorChanged(lightColor: LightColor, lightName: String, lightNode: SCNNode) {
        setLightColorFor(lightName: lightName, node: lightNode, color: lightColor)
    }
}
