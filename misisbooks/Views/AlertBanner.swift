//
//  AlertBanner.swift
//  misisbooks
//
//  Created by Maxim Loskov on 15.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

let kShowAlertBannerKey = "showAlertBannerKey"
let kHideAlertBannerKey = "hideAlertBannerKey"
let kMoveAlertBannerKey = "moveAlertBannerKey"

let kMargin = CGFloat(15.0)
let kNavigationBarHeightDefault = CGFloat(44.0)
let kNavigationBarHeightiOS7Landscape = CGFloat(32.0)

let kRotationDurationIphone = CFTimeInterval(0.3)
let kRotationDurationIPad = CFTimeInterval(0.4)

let kForceHideAnimationDuration = CFTimeInterval(0.1)

func AL_SINGLELINE_TEXT_HEIGHT(text: NSString, font: UIFont) -> CGFloat {
    return text.length > 0 ? text.sizeWithAttributes([NSFontAttributeName: font]).height : 0.0
}

func AL_MULTILINE_TEXT_HEIGHT(text: NSString, font: UIFont, maxSize: CGSize, mode: NSLineBreakMode) -> CGFloat {
    return text.length > 0 ? text.boundingRectWithSize(maxSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: nil, context: nil).size.height : 0.0
}

enum AlertBannerPosition : Int {
    
    case Top = 0
    case Bottom
    case UnderNavBar
}

enum AlertBannerState {
    
    case Showing
    case Hiding
    case MovingForward
    case MovingBackward
    case Visible
    case Hidden
}

protocol AlertBannerDelegate {
    
    func showAlertBanner(alertBanner: AlertBanner, hideAfter delay: NSTimeInterval)
    func hideAlertBanner(alertBanner: AlertBanner, forced: Bool)
    func alertBannerWillShow(alertBanner: AlertBanner, inView view: UIView)
    func alertBannerDidShow(alertBanner: AlertBanner, inView view: UIView)
    func alertBannerWillHide(alertBanner: AlertBanner, inView view: UIView)
    func alertBannerDidHide(alertBanner: AlertBanner, inView view: UIView)
}

class AlertBanner : UIView {
    var delegate : AlertBannerDelegate!
    
    var position = AlertBannerPosition.UnderNavBar
    var state : AlertBannerState!
    
    var fadeOutDuration = NSTimeInterval(0.2)
    var showAnimationDuration = NSTimeInterval(0.25)
    var hideAnimationDuration = NSTimeInterval(0.2)
    var isScheduledToHide = false
    var bannerOpacity = CGFloat(1.0)
    var secondsToShow = NSTimeInterval(3.5)
    var allowTapToDismiss = false
    var shouldForceHide = false
    
    var showShadow = true
    var fadeInDuration = NSTimeInterval(0.3)
    
    // var isAnimating : Bool
    var titleLabel : UILabel!
    var subtitleLabel : UILabel!
    var parentFrameUponCreation : CGRect!
    var tappedBlock : ((alertBanner: AlertBanner) -> Void)?
    
    init(view: UIView?, position: AlertBannerPosition?, title: String?, subtitle: String?, tappedBlock: ((alertBanner: AlertBanner) -> Void)?) {
        super.init(frame: CGRectZero)
        
        delegate = AlertBannerManager.sharedManager
        
        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 14.0)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Left
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        titleLabel.layer.shadowColor = UIColor.blackColor().CGColor
        titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0)
        
        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12.0)
        subtitleLabel.textColor = UIColor.whiteColor()
        subtitleLabel.textAlignment = NSTextAlignment.Left
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        subtitleLabel.layer.shadowColor = UIColor.blackColor().CGColor
        subtitleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0)
        
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        
        self.backgroundColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
        self.userInteractionEnabled = true
        self.alpha = 0.0
        self.layer.shadowOpacity = 0.5
        // self.tag = Int(arc4random_uniform(UInt32(SHRT_MAX)))
        
        setShowShadow(false)
        
        titleLabel.text = title == nil ? " " : title
        subtitleLabel.text = subtitle
        self.position = position == nil ? AlertBannerPosition.Bottom : position!
        state = AlertBannerState.Hidden
        
        allowTapToDismiss = tappedBlock != nil ? false : allowTapToDismiss
        self.tappedBlock = tappedBlock
        
        let viewForShow = view == nil ? UIApplication.sharedApplication().delegate?.window! : view!
        viewForShow!.addSubview(self)
        
        setInitialLayout()
        updateSizeAndSubviewsAnimated(false)
    }
    
    convenience init(view: UIView, position: AlertBannerPosition, title: String, subtitle: String) {
        self.init(view: nil, position: nil, title: title, subtitle: nil, tappedBlock: nil)
    }
    
    convenience init(view: UIView, position: AlertBannerPosition, title: String) {
        self.init(view: view, position: position, title: title, subtitle: nil, tappedBlock: nil)
    }
    
    convenience init(title: String, subtitle: String) {
        self.init(view: nil, position: nil, title: title, subtitle: subtitle, tappedBlock: nil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setShowShadow(showShadow: Bool) {
        self.showShadow = showShadow
        
        let oldShadowRadius = self.layer.shadowRadius
        var newShadowRadius : CGFloat
        
        if showShadow {
            newShadowRadius = 3.0
            self.layer.shadowColor = UIColor.blackColor().CGColor
            self.layer.shadowOffset = CGSizeMake(0.0, position == AlertBannerPosition.Bottom ? -1.0 : 1.0)
            let shadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin * 2.0, self.bounds.size.height)
            self.layer.shadowPath = UIBezierPath(rect: shadowPath).CGPath
            
            fadeInDuration = 0.15
        } else {
            newShadowRadius = 0.0
            self.layer.shadowRadius = 0.0
            self.layer.shadowOffset = CGSizeZero
            
            //if on iOS7, keep fade in duration at a value greater than 0 so it doesn't instantly appear behind the translucent nav bar
            fadeInDuration = position == AlertBannerPosition.Top ? 0.15 : 0.0
        }
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.mainScreen().scale
        self.layer.shadowRadius = newShadowRadius
        
        let fadeShadow = CABasicAnimation(keyPath: "shadowRadius")
        fadeShadow.fromValue = oldShadowRadius
        fadeShadow.toValue = newShadowRadius
        fadeShadow.duration = fadeOutDuration
        self.layer.addAnimation(fadeShadow, forKey: "shadowRadius")
    }
    
    func isAnimating() -> Bool {
        return state == AlertBannerState.Showing ||
            state == AlertBannerState.Hiding ||
            state == AlertBannerState.MovingForward ||
            state == AlertBannerState.MovingBackward
    }
    
    class func alertBannersInView(view: UIView) -> NSArray {
        return AlertBannerManager.sharedManager.alertBannersInView(view)
    }
    
    class func hideAllAlertBanners() {
        AlertBannerManager.sharedManager.hideAllAlertBanners()
    }
    
    class func hideAlertBannersInView(view: UIView) {
        AlertBannerManager.sharedManager.hideAlertBannersInView(view)
    }
    
    class func forceHideAllAlertBannersInView(view: UIView) {
        AlertBannerManager.sharedManager.forceHideAllAlertBannersInView(view)
    }
    
    func show() {
        delegate.showAlertBanner(self, hideAfter: secondsToShow)
    }
    
    func hide() {
        delegate.hideAlertBanner(self, forced: false)
    }
    
    func showAlertBanner() {
        if !CGRectEqualToRect(parentFrameUponCreation, self.superview!.bounds) {
            //if view size changed since this banner was created, reset layout
            setInitialLayout()
            updateSizeAndSubviewsAnimated(false)
        }
        
        delegate.alertBannerWillShow(self, inView: self.superview!)
        
        state = AlertBannerState.Showing
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(fadeInDuration * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            if self.position == AlertBannerPosition.UnderNavBar {
                let currentPoint = self.layer.mask.position
                let newPoint = CGPointMake(0.0, -self.frame.size.height)
                
                self.layer.mask.position = newPoint
                
                let moveMaskUp = CABasicAnimation(keyPath: "position")
                moveMaskUp.fromValue = NSValue(CGPoint: currentPoint)
                moveMaskUp.toValue = NSValue(CGPoint: newPoint)
                moveMaskUp.duration = self.showAnimationDuration
                moveMaskUp.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                
                self.layer.mask.addAnimation(moveMaskUp, forKey: "position")
            }
            
            let oldPoint = self.layer.position
            var yCoord = oldPoint.y
            
            switch self.position {
            case AlertBannerPosition.Top, AlertBannerPosition.UnderNavBar:
                yCoord += self.frame.size.height
                break
            case AlertBannerPosition.Bottom:
                yCoord -= self.frame.size.height
                break
            }
            
            let newPoint = CGPointMake(oldPoint.x, yCoord)
            
            self.layer.position = newPoint
            
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(CGPoint: oldPoint)
            moveLayer.toValue = NSValue(CGPoint: newPoint)
            moveLayer.duration = self.showAnimationDuration
            moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            moveLayer.delegate = self
            moveLayer.setValue(kShowAlertBannerKey, forKey: "anim")
            
            self.layer.addAnimation(moveLayer, forKey: kShowAlertBannerKey)
        }
        
        UIView.animateWithDuration(fadeInDuration, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { self.alpha = self.bannerOpacity }, completion: nil)
    }
    
    func hideAlertBanner() {
        delegate.alertBannerWillHide(self, inView: self.superview!)
        
        state = AlertBannerState.Hiding
        
        if position == AlertBannerPosition.UnderNavBar {
            let currentPoint = self.layer.mask.position
            let newPoint = CGPointZero
            
            self.layer.mask.position = newPoint
            
            let moveMaskDown = CABasicAnimation(keyPath: "position")
            moveMaskDown.fromValue = NSValue(CGPoint: currentPoint)
            moveMaskDown.toValue = NSValue(CGPoint: newPoint)
            moveMaskDown.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
            moveMaskDown.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            
            self.layer.mask.addAnimation(moveMaskDown, forKey: "position")
        }
        
        let oldPoint = self.layer.position
        var yCoord = oldPoint.y
        
        switch position {
        case AlertBannerPosition.Top, AlertBannerPosition.UnderNavBar:
            yCoord -= self.frame.size.height
            break
        case AlertBannerPosition.Bottom:
            yCoord += self.frame.size.height
            break
        }
        
        let newPoint = CGPointMake(oldPoint.x, yCoord)
        
        self.layer.position = newPoint
        
        let moveLayer = CABasicAnimation(keyPath: "position")
        moveLayer.fromValue = NSValue(CGPoint: oldPoint)
        moveLayer.toValue = NSValue(CGPoint: newPoint)
        moveLayer.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
        moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        moveLayer.delegate = self
        moveLayer.setValue(kHideAlertBannerKey, forKey: "anim")
        
        self.layer.addAnimation(moveLayer, forKey: kHideAlertBannerKey)
    }
    
    func pushAlertBanner(distance: CGFloat, forward: Bool, delay: Double) {
        state = forward ? AlertBannerState.MovingForward : AlertBannerState.MovingBackward
        
        var distanceToPush = distance
        
        if position == AlertBannerPosition.Bottom {
            distanceToPush *= -1
        }
        
        let activeLayer = isAnimating() ? self.layer.presentationLayer() as CALayer : self.layer
        
        let oldPoint = activeLayer.position
        let newPoint = CGPointMake(oldPoint.x, (self.layer.position.y - oldPoint.y) + oldPoint.y + distanceToPush)
        
        let delayInSeconds = delay
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.layer.position = newPoint
            
            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(CGPoint: oldPoint)
            moveLayer.toValue = NSValue(CGPoint: newPoint)
            moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration
            moveLayer.timingFunction = forward ? CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) : CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            moveLayer.delegate = self
            moveLayer.setValue(kMoveAlertBannerKey, forKey: "anim")
            
            self.layer.addAnimation(moveLayer, forKey: kMoveAlertBannerKey)
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event:UIEvent) {
        if state != AlertBannerState.Visible {
            return
        }
        
        if tappedBlock != nil {
            tappedBlock?(alertBanner: self)
        }
        
        if allowTapToDismiss {
            delegate.hideAlertBanner(self, forced: false)
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if anim.valueForKey("anim") as String? == kShowAlertBannerKey && flag {
            delegate.alertBannerDidShow(self, inView: self.superview!)
            state = AlertBannerState.Visible
        } else if anim.valueForKey("anim") as String? == kHideAlertBannerKey && flag {
            UIView.animateWithDuration(shouldForceHide ? kForceHideAnimationDuration : fadeOutDuration, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { self.alpha = 0.0 }, completion: { _ in
                    self.state = AlertBannerState.Hidden
                    self.delegate.alertBannerDidHide(self, inView: self.superview!)
                    NSNotificationCenter.defaultCenter().removeObserver(self)
                    self.removeFromSuperview()
            })
        } else if anim.valueForKey("anim") as? String == kMoveAlertBannerKey && flag {
            state = AlertBannerState.Visible
        }
    }
    
    func setInitialLayout() {
        self.layer.anchorPoint = CGPointMake(0.0, 0.0)
        
        let superview = self.superview!
        parentFrameUponCreation = superview.bounds
        let isSuperviewKindOfWindow = superview.isKindOfClass(UIWindow)
        
        let maxLabelSize = CGSizeMake(superview.bounds.size.width - kMargin * 3, CGFloat.max)
        let titleLabelHeight = AL_SINGLELINE_TEXT_HEIGHT(titleLabel.text!, titleLabel.font)
        let subtitleLabelHeight = AL_MULTILINE_TEXT_HEIGHT(subtitleLabel.text!, subtitleLabel.font, maxLabelSize, subtitleLabel.lineBreakMode)
        let heightForSelf = CGFloat(titleLabelHeight + subtitleLabelHeight + (subtitleLabel.text == nil || titleLabel.text == nil ? kMargin * 2 : kMargin * 2.5))
        
        var frame = CGRectMake(0.0, 0.0, superview.bounds.size.width, heightForSelf)
        var initialYCoord = CGFloat(0.0)
        switch position {
        case AlertBannerPosition.Top:
            initialYCoord = -heightForSelf
            
            if isSuperviewKindOfWindow {
                initialYCoord += UIApplication.sharedApplication().statusBarFrame.size.height
            }
            
            if let nextResponder: AnyObject = nextAvailableViewController(self) {
                let vc = nextResponder as UIViewController
                if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKindOfClass(UIScrollView)) {
                    initialYCoord += vc.topLayoutGuide.length
                }
            }
            break
        case AlertBannerPosition.Bottom:
            initialYCoord = superview.bounds.size.height
            break
        case AlertBannerPosition.UnderNavBar:
            initialYCoord = -heightForSelf + kNavigationBarHeightDefault + UIApplication.sharedApplication().statusBarFrame.size.height
            break
        }
        
        frame.origin.y = initialYCoord
        self.frame = frame
        
        if position == AlertBannerPosition.UnderNavBar {
            let maskLayer = CAShapeLayer()
            let maskRect = CGRectMake(0.0, frame.size.height, frame.size.width, superview.bounds.size.height) // Нужно дать маске достаточную высоту, чтобы не обрезать тень
            maskLayer.path = CGPathCreateWithRect(maskRect, nil)
            self.layer.mask = maskLayer
            self.layer.mask.position = CGPointZero
        }
    }
    
    func updateSizeAndSubviewsAnimated(animated: Bool) {
        let maxLabelSize = CGSizeMake(self.superview!.bounds.size.width - kMargin * 3.0, CGFloat.max)
        let titleLabelHeight = AL_SINGLELINE_TEXT_HEIGHT(titleLabel.text!, titleLabel.font)
        let subtitleLabelHeight = AL_MULTILINE_TEXT_HEIGHT(subtitleLabel.text!, subtitleLabel.font, maxLabelSize, subtitleLabel.lineBreakMode)
        let heightForSelf = CGFloat(titleLabelHeight + subtitleLabelHeight + (subtitleLabel.text == nil || titleLabel.text == nil ? kMargin * 2.0 : kMargin * 2.5))
        
        let boundsAnimationDuration = CFTimeInterval(kRotationDurationIphone)
        
        let oldBounds = self.layer.bounds
        var newBounds = oldBounds
        newBounds.size = CGSizeMake(self.superview!.frame.size.width, heightForSelf)
        self.layer.bounds = newBounds
        
        if animated {
            let boundsAnimation = CABasicAnimation(keyPath: "bounds")
            boundsAnimation.fromValue = NSValue(CGRect: oldBounds)
            boundsAnimation.toValue = NSValue(CGRect: newBounds)
            boundsAnimation.duration = boundsAnimationDuration
            self.layer.addAnimation(boundsAnimation, forKey: "bounds")
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(boundsAnimationDuration)
        }
        
        titleLabel.frame = CGRectMake(kMargin, kMargin, maxLabelSize.width, titleLabelHeight)
        subtitleLabel.frame = CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y + titleLabel.frame.size.height + (titleLabel.text == nil ? 0.0 : kMargin / 2.0), maxLabelSize.width, subtitleLabelHeight)
        
        if animated {
            UIView.commitAnimations()
        }
        
        if showShadow {
            let oldShadowPath = CGPathGetPathBoundingBox(self.layer.shadowPath)
            let newShadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin * 2.0, self.bounds.size.height)
            self.layer.shadowPath = UIBezierPath(rect: newShadowPath).CGPath
            
            if animated {
                let shadowAnimation = CABasicAnimation(keyPath: "shadowPath")
                shadowAnimation.fromValue = UIBezierPath(rect: oldShadowPath).CGPath
                shadowAnimation.toValue = UIBezierPath(rect: newShadowPath).CGPath
                shadowAnimation.duration = boundsAnimationDuration
                self.layer.addAnimation(shadowAnimation, forKey: "shadowPath")
            }
        }
    }
    
    func updatePositionAfterRotationWithY(yPos: CGFloat, animated: Bool) {
        var positionAnimationDuration = kRotationDurationIphone
        let activeLayer = isAnimating() ? self.layer.presentationLayer() as CALayer : self.layer
        var currentAnimationKey : String? = nil
        var timingFunction : CAMediaTimingFunction? = nil
        
        if isAnimating() {
            var currentAnimation : CABasicAnimation
            
            switch state! {
            case AlertBannerState.Showing:
                currentAnimation = self.layer.animationForKey(kShowAlertBannerKey) as CABasicAnimation
                currentAnimationKey = kShowAlertBannerKey
                break
            case AlertBannerState.Hiding:
                currentAnimation = self.layer.animationForKey(kHideAlertBannerKey) as CABasicAnimation
                currentAnimationKey = kHideAlertBannerKey
                break
            case AlertBannerState.MovingBackward, AlertBannerState.MovingForward:
                currentAnimation = self.layer.animationForKey(kMoveAlertBannerKey) as CABasicAnimation
                currentAnimationKey = kMoveAlertBannerKey
                break
            default:
                return
            }
            
            let remainingAnimationDuration = CFTimeInterval(currentAnimation.duration - CACurrentMediaTime() + currentAnimation.beginTime)
            timingFunction = currentAnimation.timingFunction
            positionAnimationDuration = remainingAnimationDuration
            
            self.layer.removeAnimationForKey(currentAnimationKey)
        }
        
        var yPosNew = yPos
        
        if state == AlertBannerState.Hiding || state == AlertBannerState.MovingBackward {
            switch position {
            case AlertBannerPosition.Top, AlertBannerPosition.UnderNavBar:
                yPosNew -= self.layer.bounds.size.height
                break
            case AlertBannerPosition.Bottom:
                yPosNew += self.layer.bounds.size.height
                break
            }
        }
        
        let oldPos = activeLayer.position
        let newPos = CGPointMake(oldPos.x, yPos)
        self.layer.position = newPos
        
        if animated {
            let positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = NSValue(CGPoint: oldPos)
            positionAnimation.toValue = NSValue(CGPoint: newPos)
            
            if position == AlertBannerPosition.Bottom {
                positionAnimationDuration = kRotationDurationIphone
            }
            
            positionAnimation.duration = positionAnimationDuration
            positionAnimation.timingFunction = timingFunction == nil ? CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear) : timingFunction
            
            if currentAnimationKey != nil {
                //hijack the old animation's key value
                positionAnimation.delegate = self
                positionAnimation.setValue(currentAnimationKey, forKey: "anim")
            }
            
            self.layer.addAnimation(positionAnimation, forKey: currentAnimationKey)
        }
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
}
