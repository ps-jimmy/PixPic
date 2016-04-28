//
//  EffectEditorView.swift
//  P-effect
//
//  Created by anna on 1/27/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import UIKit

class StickerEditorView: UIView {
    
    private var touchStart: CGPoint?
    private var previousPoint: CGPoint?
    private var deltaAngle: CGFloat?
    
    private var resizingControl: StickerEditorViewControl!
    private var deleteControl: StickerEditorViewControl!
    private var borderView: BorderView!
    
    init(image: UIImage) {
        let stickerImageView = UIImageView(image: image)
        super.init(frame: stickerImageView.frame)
        
        setupContentView(stickerImageView)
        setupDefaultAttributes()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupDefaultAttributes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupDefaultAttributes()
    }
    
    func switchControls(toState state: Bool) {
        resizingControl.hidden = !state
        deleteControl.hidden = !state
        borderView.hidden = !state
    }
    
    private func setupDefaultAttributes() {
        borderView = BorderView(frame: bounds)
        addSubview(borderView)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        deleteControl = StickerEditorViewControl(image: UIImage(named: "delete_control"), gestureRecognizer: singleTap)
        addSubview(deleteControl)
        
        let panResizeGesture = UIPanGestureRecognizer(target: self, action: #selector(resizeTranslate(_:)))
        resizingControl = StickerEditorViewControl(image: UIImage(named: "resize_control"), gestureRecognizer: panResizeGesture)
        addSubview(resizingControl)
        
        updateControlsPosition()
        
        deltaAngle = atan2(frame.origin.y + frame.height - center.y, frame.origin.x + frame.width - center.x)
    }
    
    private func setupContentView(content: UIView) {
        let contentView = UIView(frame: content.frame)
        contentView.backgroundColor = UIColor.clearColor()
        contentView.addSubview(content)
        contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(contentView)
        
        for subview in contentView.subviews {
            subview.frame = CGRectMake(0, 0, contentView.frame.width, contentView.frame.height)
            subview.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        }
    }
    
    @objc private func singleTap(recognizer: UIPanGestureRecognizer) {
        let close = recognizer.view
        if let close = close {
            close.superview?.removeFromSuperview()
        }
    }
    
    @objc private func resizeTranslate(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Began {
            enableTranslucency(true)
            previousPoint = recognizer.locationInView(self)
            setNeedsDisplay()
            
        } else if recognizer.state == .Changed {
            resizeView(recognizer)
            rotateViewWithAngle(angle: deltaAngle, recognizer: recognizer)
            
        } else if recognizer.state == .Ended {
            enableTranslucency(false)
            previousPoint = recognizer.locationInView(self)
            setNeedsDisplay()
        }
        updateControlsPosition()
    }
    
    private func resizeView(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.locationInView(self)
        guard let previousPoint = previousPoint else {
            return
        }
        let diagonal = sqrt(pow(point.x, 2) + pow(point.y, 2))
        let previousDiagonal = sqrt(pow(previousPoint.x, 2) + pow(previousPoint.y, 2))
        let totalRatio = pow(diagonal / previousDiagonal , 2)

        bounds = CGRectMake(0, 0, bounds.size.width * totalRatio, bounds.size.height * totalRatio)
        self.previousPoint = recognizer.locationInView(self)
    }
    
    private func updateControlsPosition() {
        let offset = Constants.StickerEditor.UserResizableViewGlobalOffset
        borderView.frame = CGRectMake(-offset, -offset, bounds.size.width + offset * 2, bounds.size.height + offset * 2)
        
        deleteControl.center = CGPointMake(borderView.frame.origin.x, borderView.frame.origin.y)
        resizingControl.center = CGPointMake(borderView.frame.origin.x + borderView.frame.size.width,
                                             borderView.frame.origin.y + borderView.frame.size.height)
    }
    
    private func rotateViewWithAngle(angle deltaAngle: CGFloat?, recognizer: UIPanGestureRecognizer) {
        let angle = atan2(recognizer.locationInView(superview).y - center.y,
                          recognizer.locationInView(superview).x - center.x)
        
        if let deltaAngle = deltaAngle {
            let angleDiff = deltaAngle - angle
            transform = CGAffineTransformMakeRotation(-angleDiff)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        enableTranslucency(true)
        
        let touch = touches.first
        if let touch = touch {
            touchStart = touch.locationInView(superview)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchLocation = touches.first?.locationInView(self)
        if CGRectContainsPoint(resizingControl.frame, touchLocation!) {
            return
        }
        
        let touch = touches.first?.locationInView(superview)
        translateUsingTouchLocation(touch!)
        touchStart = touch
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        enableTranslucency(false)
    }
    
    private func translateUsingTouchLocation(touchPoint: CGPoint) {
        if let touchStart = touchStart {
            center = CGPointMake(center.x + touchPoint.x - touchStart.x, center.y + touchPoint.y - touchStart.y)
        }
    }
    
    private func enableTranslucency(state: Bool) {
        if state == true {
            alpha = 0.65
        } else {
            alpha = 1
        }
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if CGRectContainsPoint(resizingControl.frame, point) ||
            CGRectContainsPoint(deleteControl.frame, point) ||
            CGRectContainsPoint(bounds, point) {
            for subview in subviews.reverse() {
                let convertedPoint = subview.convertPoint(point, fromView: self)
                let hitTestView = subview.hitTest(convertedPoint, withEvent: event)
                if hitTestView != nil {
                    return hitTestView
                }
            }
            return self;
        }
        return nil;
    }
    
}