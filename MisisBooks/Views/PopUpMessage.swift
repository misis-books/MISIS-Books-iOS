//
//  PopUpMessage.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 29.06.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

let kHidePopUpMessageKey = "hidePopUpMessageKey"
let kShowPopUpMessageKey = "showPopUpMessageKey"
let kMovePopUpMessageKey = "movePopUpMessageKey"

let kForceHideAnimationDuration: CFTimeInterval = 0.1
let kRotationDurationIPad: CFTimeInterval = 0.4
let kRotationDurationIPhone: CFTimeInterval = 0.3

/**
    Перечисление для положений всплывающего сообщения
*/
enum PopUpMessagePosition {
    case Bottom, Top, UnderNavigationBar
}

/**
    Перечисление для состояний всплывающего сообщения
*/
enum PopUpMessageState {
    case Hidden, Hiding, MovingBackward, MovingForward, Showing, Visible
}

/**
    Протокол для всплывающего сообщения
*/
protocol PopUpMessageDelegate {
    func popUpMessageDidHide(popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageDidShow(popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageWillHide(popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageWillShow(popUpMessage: PopUpMessage, inView view: UIView)
    func hidePopUpMessage(popUpMessage: PopUpMessage, forced: Bool)
    func showPopUpMessage(popUpMessage: PopUpMessage!, hideAfter delay: NSTimeInterval)
}

/**
    Класс для представления всплывающего сообщения
*/
class PopUpMessage: UIView {

    // Флаг разрешения на то, чтобы скрыть всплывающее сообщение при нажатии на него
    var allowTapToDismiss = false

    // Прозрачность всплывающего сообщения
    let bannerOpacity: CGFloat = 1

    // Делагат
    var delegate: PopUpMessageDelegate!

    let fadeInDuration: NSTimeInterval = 0.3
    let fadeOutDuration: NSTimeInterval = 0.2
    let hideAnimationDuration: NSTimeInterval = 0.2
    var isScheduledToHide = false
    var parentFrameUponCreation: CGRect!
    var position: PopUpMessagePosition = .UnderNavigationBar
    let secondsToShow: NSTimeInterval = 3.5
    var shouldForceHide = false
    let showAnimationDuration: NSTimeInterval = 0.25

    /// Состояние
    var state: PopUpMessageState!

    /// Поле подзаголовка
    var subtitleLabel: UILabel!

    /// Обработчик нажатия
    var tapHandler: ((popUpMessage: PopUpMessage) -> Void)?

    /// Поле заголовка
    var titleLabel: UILabel!
    
    init(view: UIView?, position: PopUpMessagePosition?, title: String?, subtitle: String?,
        tapHandler: ((popUpMessage: PopUpMessage) -> Void)?) {
            super.init(frame: CGRectZero)
            
            delegate = PopUpMessageManager.instance
            
            titleLabel = UILabel()
            titleLabel.backgroundColor = .clearColor()
            titleLabel.font = UIFont(name: "HelveticaNeue", size: 14)
            titleLabel.numberOfLines = 0
            titleLabel.layer.shadowColor = UIColor.blackColor().CGColor
            titleLabel.layer.shadowOffset = CGSizeMake(0, -1)
            titleLabel.lineBreakMode = .ByTruncatingTail
            titleLabel.text = title == nil ? " " : title
            titleLabel.textColor = .whiteColor()
            addSubview(titleLabel)
            
            subtitleLabel = UILabel()
            subtitleLabel.backgroundColor = .clearColor()
            subtitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
            subtitleLabel.numberOfLines = 0
            subtitleLabel.layer.shadowColor = UIColor.blackColor().CGColor
            subtitleLabel.layer.shadowOffset = CGSizeMake(0, -1)
            subtitleLabel.lineBreakMode = .ByWordWrapping
            subtitleLabel.text = subtitle
            subtitleLabel.textColor = .whiteColor()
            addSubview(subtitleLabel)
            
            alpha = 0
            backgroundColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
            userInteractionEnabled = true
            
            self.position = position == nil ? .Bottom : position!
            state = .Hidden
            allowTapToDismiss = tapHandler != nil ? false : allowTapToDismiss
            self.tapHandler = tapHandler
            
            let viewForShow = view == nil ? UIApplication.sharedApplication().delegate?.window! : view!
            viewForShow!.addSubview(self)
            
            setInitialLayout()
            updateSizeAndSubviewsAnimated(false)
    }
    
    convenience init(title: String, subtitle: String) {
        self.init(view: nil, position: nil, title: title, subtitle: subtitle, tapHandler: nil)
    }
    
    convenience init(view: UIView, position: PopUpMessagePosition, title: String) {
        self.init(view: view, position: position, title: title, subtitle: nil, tapHandler: nil)
    }
    
    convenience init(view: UIView, position: PopUpMessagePosition, title: String, subtitle: String) {
        self.init(view: nil, position: nil, title: title, subtitle: nil, tapHandler: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if state != .Visible {
            return
        }
        
        if tapHandler != nil {
            tapHandler?(popUpMessage: self)
        }
        
        if allowTapToDismiss {
            delegate.hidePopUpMessage(self, forced: false)
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if anim.valueForKey("animation") as! String == kShowPopUpMessageKey && flag {
            delegate.popUpMessageDidShow(self, inView: superview!)
            state = .Visible
        } else if anim.valueForKey("animation") as! String == kHidePopUpMessageKey && flag {
            UIView.animateWithDuration(shouldForceHide ? kForceHideAnimationDuration : fadeOutDuration, delay: 0,
                options: .CurveLinear, animations: {
                    self.alpha = 0
                }, completion: { _ in
                    self.state = .Hidden
                    self.delegate.popUpMessageDidHide(self, inView: self.superview!)
                    NSNotificationCenter.defaultCenter().removeObserver(self)
                    self.removeFromSuperview()
            })
        } else if anim.valueForKey("animation") as? String == kMovePopUpMessageKey && flag {
            state = .Visible
        }
    }
    
    class func popUpMessagesInView(view: UIView) -> [PopUpMessage] {
        return PopUpMessageManager.instance.popUpMessagesInView(view)
    }
    
    class func forceHideAllPopUpMessagesInView(view: UIView) {
        PopUpMessageManager.instance.forceHideAllPopUpMessagesInView(view)
    }
    
    class func hideAllPopUpMessages() {
        PopUpMessageManager.instance.hideAllPopUpMessages()
    }
    
    class func hidePopUpMessagesInView(view: UIView) {
        PopUpMessageManager.instance.hidePopUpMessagesInView(view)
    }
    
    func hidePopUpMessage() {
        delegate.popUpMessageWillHide(self, inView: superview!)
        
        state = .Hiding
        
        if position == .UnderNavigationBar {
            let currentPoint = layer.mask!.position
            let newPoint = CGPointZero
            
            layer.mask!.position = newPoint
            
            let moveMaskDown = CABasicAnimation(keyPath: "position")
            moveMaskDown.fromValue = NSValue(CGPoint: currentPoint)
            moveMaskDown.toValue = NSValue(CGPoint: newPoint)
            moveMaskDown.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
            moveMaskDown.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            
            layer.mask!.addAnimation(moveMaskDown, forKey: "position")
        }
        
        let oldPoint = layer.position
        var yCoord = oldPoint.y
        
        switch position {
        case .Top, .UnderNavigationBar:
            yCoord -= frame.size.height
        case .Bottom:
            yCoord += frame.size.height
        }
        
        let newPoint = CGPointMake(oldPoint.x, yCoord)
        
        layer.position = newPoint
        
        let moveLayer = CABasicAnimation(keyPath: "position")
        moveLayer.fromValue = NSValue(CGPoint: oldPoint)
        moveLayer.toValue = NSValue(CGPoint: newPoint)
        moveLayer.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
        moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        moveLayer.delegate = self
        moveLayer.setValue(kHidePopUpMessageKey, forKey: "animation")
        
        layer.addAnimation(moveLayer, forKey: kHidePopUpMessageKey)
    }
    
    func nextAvailableViewController(view: AnyObject) -> AnyObject? {
        let nextResponder = view.nextResponder()
        
        if nextResponder!.isKindOfClass(UIViewController) {
            return nextResponder
        } else if nextResponder!.isKindOfClass(UIView) {
            return nextAvailableViewController(nextResponder!)
        } else {
            return nil
        }
    }
    
    func pushPopUpMessage(distance: CGFloat, forward: Bool, delay: Double) {
        state = forward ? .MovingForward : .MovingBackward
        
        var distanceToPush = distance
        
        if position == .Bottom {
            distanceToPush *= -1
        }
        
        let activeLayer = isAnimating() ? layer.presentationLayer() as! CALayer : layer
        
        let oldPoint = activeLayer.position
        let newPoint = CGPointMake(oldPoint.x, layer.position.y + distanceToPush)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.layer.position = newPoint
            
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(CGPoint: oldPoint)
            moveLayer.toValue = NSValue(CGPoint: newPoint)
            moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration
            moveLayer.timingFunction = forward ?
                CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) :
                CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            moveLayer.delegate = self
            moveLayer.setValue(kMovePopUpMessageKey, forKey: "animation")
            
            self.layer.addAnimation(moveLayer, forKey: kMovePopUpMessageKey)
        }
    }
    
    func show() {
        delegate.showPopUpMessage(self, hideAfter: secondsToShow)
    }
    
    func showPopUpMessage() {
        if !CGRectEqualToRect(parentFrameUponCreation, superview!.bounds) {
            setInitialLayout()
            updateSizeAndSubviewsAnimated(false)
        }
        
        delegate.popUpMessageWillShow(self, inView: superview!)
        
        state = .Showing
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(fadeInDuration * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            if self.position == .UnderNavigationBar {
                let currentPoint = self.layer.mask!.position
                let newPoint = CGPointMake(0, -self.frame.size.height)
                
                self.layer.mask!.position = newPoint
                
                let moveMaskUp = CABasicAnimation(keyPath: "position")
                moveMaskUp.fromValue = NSValue(CGPoint: currentPoint)
                moveMaskUp.toValue = NSValue(CGPoint: newPoint)
                moveMaskUp.duration = self.showAnimationDuration
                moveMaskUp.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                
                self.layer.mask!.addAnimation(moveMaskUp, forKey: "position")
            }
            
            let oldPoint = self.layer.position
            var yCoord = oldPoint.y
            
            switch self.position {
            case .Top, .UnderNavigationBar:
                yCoord += self.frame.size.height
            case .Bottom:
                yCoord -= self.frame.size.height
            }
            
            let newPoint = CGPointMake(oldPoint.x, yCoord)
            
            self.layer.position = newPoint
            
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(CGPoint: oldPoint)
            moveLayer.toValue = NSValue(CGPoint: newPoint)
            moveLayer.duration = self.showAnimationDuration
            moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            moveLayer.delegate = self
            moveLayer.setValue(kShowPopUpMessageKey, forKey: "animation")
            
            self.layer.addAnimation(moveLayer, forKey: kShowPopUpMessageKey)
        }
        
        UIView.animateWithDuration(fadeInDuration, delay: 0, options: .CurveLinear, animations: {
            self.alpha = self.bannerOpacity
            }, completion: nil)
    }
    
    func updatePositionAfterRotationWithY(yPos: CGFloat, animated: Bool) {
        var positionAnimationDuration = kRotationDurationIPhone
        let activeLayer = isAnimating() ? layer.presentationLayer() as! CALayer : layer
        var currentAnimationKey: String? = nil
        var timingFunction: CAMediaTimingFunction? = nil
        
        if isAnimating() {
            let currentAnimation: CAAnimation!
            
            switch state! {
            case .Showing:
                currentAnimation = layer.animationForKey(kShowPopUpMessageKey)
                currentAnimationKey = kShowPopUpMessageKey
            case .Hiding:
                currentAnimation = layer.animationForKey(kHidePopUpMessageKey)
                currentAnimationKey = kHidePopUpMessageKey
            case .MovingBackward, .MovingForward:
                currentAnimation = layer.animationForKey(kMovePopUpMessageKey)
                currentAnimationKey = kMovePopUpMessageKey
            default:
                return
            }
            
            if currentAnimation != nil {
                let remainingAnimationDuration = currentAnimation.duration - CACurrentMediaTime() + currentAnimation.beginTime
                timingFunction = currentAnimation.timingFunction
                positionAnimationDuration = remainingAnimationDuration
                
                layer.removeAnimationForKey(currentAnimationKey!)
            }
            
        }
        
        var yPosNew = yPos
        
        if state == .Hiding || state == .MovingBackward {
            switch position {
            case .Top, .UnderNavigationBar:
                yPosNew -= layer.bounds.size.height
            case .Bottom:
                yPosNew += layer.bounds.size.height
            }
        }
        
        let oldPos = activeLayer.position
        let newPos = CGPointMake(oldPos.x, yPos)
        layer.position = newPos
        
        if animated {
            let positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = NSValue(CGPoint: oldPos)
            positionAnimation.toValue = NSValue(CGPoint: newPos)
            
            if position == .Bottom {
                positionAnimationDuration = kRotationDurationIPhone
            }
            
            positionAnimation.duration = positionAnimationDuration
            positionAnimation.timingFunction = timingFunction == nil ?
                CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear) : timingFunction
            
            if currentAnimationKey != nil {
                positionAnimation.delegate = self
                positionAnimation.setValue(currentAnimationKey, forKey: "animation")
            }
            
            layer.addAnimation(positionAnimation, forKey: currentAnimationKey)
        }
    }
    
    func updateSizeAndSubviewsAnimated(animated: Bool) {
        let superviewSize = UIScreen.mainScreen().bounds.size
        let maxLabelSize = CGSizeMake(superviewSize.width - 30, CGFloat.max)
        let titleLabelHeight = heightForText(titleLabel.text!, font: titleLabel.font, maxLabelSize: maxLabelSize)
        let subtitleLabelHeight = heightForText(subtitleLabel.text!, font: subtitleLabel.font, maxLabelSize: maxLabelSize)
        let heightForSelf = titleLabelHeight + subtitleLabelHeight + 35
        
        let boundsAnimationDuration = kRotationDurationIPhone
        
        let oldBounds = layer.bounds
        var newBounds = oldBounds
        newBounds.size = CGSizeMake(superviewSize.width, heightForSelf)
        layer.bounds = newBounds
        
        if animated {
            let boundsAnimation = CABasicAnimation(keyPath: "bounds")
            boundsAnimation.fromValue = NSValue(CGRect: oldBounds)
            boundsAnimation.toValue = NSValue(CGRect: newBounds)
            boundsAnimation.duration = boundsAnimationDuration
            layer.addAnimation(boundsAnimation, forKey: "bounds")
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(boundsAnimationDuration)
        }
        
        titleLabel.frame = CGRectMake(15, 15, maxLabelSize.width, titleLabelHeight)
        subtitleLabel.frame = CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y + titleLabel.frame.size.height + 5,
            maxLabelSize.width, subtitleLabelHeight)
        
        if animated {
            UIView.commitAnimations()
        }
    }
    
    // MARK: - Внутренние методы
    
    private func heightForText(text: String, font: UIFont, maxLabelSize: CGSize) -> CGFloat {
        return (text == "" ? CGRectZero : text.boundingRectWithSize(maxLabelSize, options: .UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font], context: nil)).size.height
    }
    
    private func hide() {
        delegate.hidePopUpMessage(self, forced: false)
    }
    
    private func isAnimating() -> Bool {
        switch state! {
        case .Showing, .Hiding, .MovingForward, .MovingBackward:
            return true
        default:
            return false
        }
    }
    
    private func setInitialLayout() {
        layer.anchorPoint = CGPointZero
        
        let superview = self.superview!
        parentFrameUponCreation = superview.bounds
        let isSuperviewKindOfWindow = superview.isKindOfClass(UIWindow)
        
        let maxLabelSize = CGSizeMake(superview.bounds.size.width - 30, CGFloat.max)
        let titleLabelHeight = heightForText(titleLabel.text!, font: titleLabel.font, maxLabelSize: maxLabelSize)
        let subtitleLabelHeight = heightForText(subtitleLabel.text!, font: subtitleLabel.font, maxLabelSize: maxLabelSize)
        let heightForSelf = titleLabelHeight + subtitleLabelHeight + 35
        
        var frame = CGRectMake(0, 0, superview.bounds.size.width, heightForSelf)
        var initialYCoord: CGFloat = 0
        
        switch position {
        case .Top:
            initialYCoord = -heightForSelf
            
            if isSuperviewKindOfWindow {
                initialYCoord += UIApplication.sharedApplication().statusBarFrame.size.height
            }
            
            if let nextResponder: AnyObject = nextAvailableViewController(self) {
                let vc = nextResponder as! UIViewController
                
                if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKindOfClass(UIScrollView)) {
                    initialYCoord += vc.topLayoutGuide.length
                }
            }
        case .Bottom:
            initialYCoord = superview.bounds.size.height
        case .UnderNavigationBar:
            initialYCoord = -heightForSelf + UIApplication.sharedApplication().statusBarFrame.size.height + 44
        }
        
        frame.origin.y = initialYCoord
        self.frame = frame
        
        if position == .UnderNavigationBar {
            let maskLayer = CAShapeLayer()
            let maskRect = CGRectMake(0, frame.size.height, frame.size.width, superview.bounds.size.height)
            maskLayer.path = CGPathCreateWithRect(maskRect, nil)
            layer.mask = maskLayer
            layer.mask!.position = CGPointZero
        }
    }
}
