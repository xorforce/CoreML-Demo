//
//  CameraVC.swift
//  CoreML-Demo
//
//  Created by Bhagat  Singh on 01/12/17.
//  Copyright © 2017 Bhagat  Singh. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState{
    case on
    case off
}


class CameraVC: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureImageView: Rounder_ShadowImageView!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var flashButton: Rounded_ShadowButton!
    @IBOutlet weak var backgroundView: Rounded_ShadowView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var captureSession : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var photoData : Data?
    var currentFlashState : FlashState = .off
    var speechSyntesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechSyntesizer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        activityIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tapGesture.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)

            if (captureSession.canAddInput(input) == true) {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if (captureSession.canAddOutput(cameraOutput)) {
                captureSession.addOutput(cameraOutput!)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewLayer.connection?.videoOrientation = .portrait
            
            cameraView.layer.addSublayer(previewLayer)
            
            cameraView.addGestureRecognizer(tapGesture)
            
            captureSession.startRunning()
            

        }catch{
            debugPrint(error)
        }
        
    }
    
    @objc func didTapCameraView() {
        self.cameraView.isUserInteractionEnabled = false
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if (currentFlashState == .off) {
            settings.flashMode = .off
        
        }else {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    func resultsMethod(request: VNRequest, error:Error?){
        guard let results = request.results as? [VNClassificationObservation] else{return}
        for classification in results{
            if (classification.confidence < 0.5) {
                let unknownMessage = "I'm not sure what this is. Try again."
                self.identificationLabel.text = unknownMessage
                self.confidenceLabel.text = ""
                synthesizeSpeech(fromString: unknownMessage)
                break
            
            }else{
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.identificationLabel.text = identification
                self.confidenceLabel.text = "Confidence : \(confidence)%"
                
                let completeSentence = "This looks like a \(identification). I'm \(confidence) percent sure."
                synthesizeSpeech(fromString: completeSentence)
                
                break
            }
            
        }
    }
    
    func synthesizeSpeech(fromString string:String){
        
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSyntesizer.speak(speechUtterance)
    }
    
    @IBAction func didTapFlashButton(_ sender: Any) {
        
        switch currentFlashState{
        case .on:
            flashButton.setTitle("Flash Off", for: .normal)
            currentFlashState = .off
        
        case .off:
            flashButton.setTitle("Flash On", for: .normal)
            currentFlashState = .on
            
        }
        
    }
    
}

extension CameraVC : AVCapturePhotoCaptureDelegate{
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error{
            debugPrint(error)
        }else{
            
            photoData = photo.fileDataRepresentation()
            
            do{
                
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
                
            }catch{
                debugPrint(error)
            }
            
            
            
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
}

extension CameraVC : AVSpeechSynthesizerDelegate{
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
        
        
    }
}



