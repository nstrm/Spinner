//
//  SpinnerView.swift
//  Wheel
//
//  Created by Walter Nordström on 2017-11-15.
//  Copyright © 2017 Walter Nordström. All rights reserved.
//

import UIKit

@IBDesignable
class SpinnerView: UIView{
    @IBInspectable var canSpin: Bool = true
    @IBInspectable var allowNegativeValues: Bool = false
    @IBInspectable var handleColor: UIColor = UIColor.green {
        didSet {
            handleView.backgroundColor = handleColor
        }
    }
    
    var handleView: UIView!
    var totalRadians: CGFloat = 0.0
    var totalDegrees: Int {
       return Int(totalRadians/CGFloat.pi*180)
    }
    var delegate: SpinnerViewDelegate?
    
    private var decelerationDisplayLink: CADisplayLink? = nil
    
    // Constants
    private let kDecelerationVelocityMultiplier: CGFloat = 0.95
    private let kSpeedToSnap: CGFloat = 0.1
    private let kSpeedToDecelerate: CGFloat = 2.0
    private let kPreferredFramesPerSecond: Int = 60
    
    private var startTrackingTime: CFTimeInterval!
    private var endTrackingTime: CFTimeInterval!
    private var previousTouchRadians: CGFloat!
    private var currentTouchRadians: CGFloat!
    private var startTouchRadians: CGFloat!
    private var currentDecelerationVelocity: CGFloat!
    
    private var decelerating = false
    
    var velocity: CGFloat {
        if endTrackingTime != startTrackingTime {
            return rotationAngle / CGFloat(endTrackingTime - startTrackingTime)
        }
        return 0.0
    }
    
    var rotationAngle: CGFloat {
        var angle = currentTouchRadians - previousTouchRadians
        
        if angle > CGFloat.pi {
            angle -= 2*CGFloat.pi
        }
        
        if angle < -CGFloat.pi {
            angle += 2*CGFloat.pi
        }
        return angle
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    private func initView() {
        handleView = UIView()
        handleView.backgroundColor = handleColor
        handleView.clipsToBounds = true
        handleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(handleView)
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            handleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            handleView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.2),
            handleView.widthAnchor.constraint(equalTo: handleView.heightAnchor)
            ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        handleView.layer.cornerRadius = handleView.bounds.height/2
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if canSpin, let touch = touches.first{
            if decelerating {
                endDeceleration()
            }
            
            startTrackingTime = CACurrentMediaTime()
            endTrackingTime = startTrackingTime
            
            startTouchRadians = radiansForTouch(touch: touch)
            currentTouchRadians = startTouchRadians
            previousTouchRadians = startTouchRadians
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if canSpin, let touch = touches.first{
            startTrackingTime = endTrackingTime
            endTrackingTime = CACurrentMediaTime()
            previousTouchRadians = currentTouchRadians
            rotateFromTouch(touch: touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard abs(velocity) > kSpeedToDecelerate else { return }
        
        if canSpin, let touch = touches.first{
            rotateFromTouch(touch: touch)
        }
        
        beginDeceleration()
    }
    
    private func rotateFromTouch(touch: UITouch) {
        currentTouchRadians = radiansForTouch(touch: touch)
        
        rotateByAngle(angle: -rotationAngle)
        self.delegate?.didRotateTo(angle: totalDegrees)
    }
    
    private func radiansForTouch(touch: UITouch) -> CGFloat {
        let position = touch.location(in: self.superview)
        let target = self.center
        var angle = atan2(target.y - position.y, position.x - target.x )
        
        angle = angle < 0 ? angle + 2*CGFloat.pi : angle
        return angle
    }
    
    private func rotateByAngle(angle: CGFloat) {
        let rotation = CGAffineTransform(rotationAngle: angle)
        self.transform = self.transform.concatenating(rotation)
        updateRotationCounter(addedAngle: angle)
    }
    
    private func updateRotationCounter(addedAngle: CGFloat) {
        let newValue = totalRadians + addedAngle
        
        if !allowNegativeValues {
            totalRadians = max(newValue,0)
        } else {
            totalRadians = newValue
        }
    }
    
    private func beginDeceleration() {
        currentDecelerationVelocity = velocity
        if currentDecelerationVelocity != 0 {
            decelerating = true
            decelerationDisplayLink?.invalidate()
            decelerationDisplayLink = CADisplayLink(target: self, selector: #selector(decelerationStep))
            if #available(iOS 10.0, *) {
                decelerationDisplayLink?.preferredFramesPerSecond = kPreferredFramesPerSecond
            }
            decelerationDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        }
    }
    
    @objc
    func decelerationStep() {
        let newVelocity: CGFloat = currentDecelerationVelocity * kDecelerationVelocityMultiplier
        let radiansToRotate: CGFloat = currentDecelerationVelocity / CGFloat(kPreferredFramesPerSecond)
        
        //If the spinwheel has slowed down to under the minimum speed, end the deceleration
        if abs(newVelocity) < kSpeedToSnap {
            endDeceleration()
        }
            //else continue decelerating the SpinWheel
        else {
            currentDecelerationVelocity = newVelocity
            rotateByAngle(angle: -radiansToRotate)
            self.delegate?.didRotateTo(angle: totalDegrees)
        }
    }
    
    private func endDeceleration() {
        decelerating = false
        decelerationDisplayLink?.invalidate()
    }
}

protocol SpinnerViewDelegate{
    func didRotateTo(angle: Int)
}
