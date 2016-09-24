//
//  PopUpMessage.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 29.06.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

enum PopUpMessagePosition {

    case bottom
    case top
    case underNavigationBar

}

enum PopUpMessageState {

    case hidden
    case hiding
    case movingBackward
    case movingForward
    case showing
    case visible

}

protocol PopUpMessageDelegate {

    func popUpMessageDidHide(_ popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageDidShow(_ popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageWillHide(_ popUpMessage: PopUpMessage, inView view: UIView)
    func popUpMessageWillShow(_ popUpMessage: PopUpMessage, inView view: UIView)
    func hidePopUpMessage(_ popUpMessage: PopUpMessage, forced: Bool)
    func showPopUpMessage(_ popUpMessage: PopUpMessage!, hideAfter delay: TimeInterval)

}

class PopUpMessage: UIView, CAAnimationDelegate {

    var allowTapToDismiss = false
    let bannerOpacity: CGFloat = 1
    var delegate: PopUpMessageDelegate!
    let fadeInDuration: TimeInterval = 0.3
    let fadeOutDuration: TimeInterval = 0.2
    let hideAnimationDuration: TimeInterval = 0.2
    var isScheduledToHide = false
    var parentFrameUponCreation: CGRect!
    var position: PopUpMessagePosition = .underNavigationBar
    let secondsToShow: TimeInterval = 3.5
    var shouldForceHide = false
    let showAnimationDuration: TimeInterval = 0.25
    let kHidePopUpMessageKey = "hidePopUpMessageKey"
    let kShowPopUpMessageKey = "showPopUpMessageKey"
    let kMovePopUpMessageKey = "movePopUpMessageKey"
    let kForceHideAnimationDuration: CFTimeInterval = 0.1
    let kRotationDurationIPad: CFTimeInterval = 0.4
    let kRotationDurationIPhone: CFTimeInterval = 0.3
    var state: PopUpMessageState!
    var subtitleLabel: UILabel!
    var tapHandler: ((_ popUpMessage: PopUpMessage) -> ())?

    /// Поле заголовка
    var titleLabel: UILabel!

    init(view: UIView?, position: PopUpMessagePosition?, title: String?, subtitle: String?,
         tapHandler: ((_ popUpMessage: PopUpMessage) -> ())?) {
        super.init(frame: .zero)

        delegate = PopUpMessageManager.instance

        titleLabel = UILabel()
        titleLabel.backgroundColor = .clear
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        titleLabel.numberOfLines = 0
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.text = title == nil ? " " : title
        titleLabel.textColor = .white
        addSubview(titleLabel)

        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.layer.shadowColor = UIColor.black.cgColor
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: -1)
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .white
        addSubview(subtitleLabel)

        alpha = 0
        backgroundColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        isUserInteractionEnabled = true

        self.position = position == nil ? .bottom : position!
        state = .hidden
        allowTapToDismiss = tapHandler != nil ? false : allowTapToDismiss
        self.tapHandler = tapHandler

        let viewForShow = view == nil ? UIApplication.shared.delegate?.window! : view!
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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state != .visible {
            return
        }

        if tapHandler != nil {
            tapHandler?(self)
        }

        if allowTapToDismiss {
            delegate.hidePopUpMessage(self, forced: false)
        }
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim.value(forKey: "animation") as! String == kShowPopUpMessageKey && flag {
            delegate.popUpMessageDidShow(self, inView: superview!)
            state = .visible
        } else if anim.value(forKey: "animation") as! String == kHidePopUpMessageKey && flag {
            UIView.animate(withDuration: shouldForceHide ? kForceHideAnimationDuration : fadeOutDuration, delay: 0,
                options: .curveLinear, animations: {
                    self.alpha = 0
                }, completion: { _ in
                    self.state = .hidden
                    self.delegate.popUpMessageDidHide(self, inView: self.superview!)
                    NotificationCenter.default.removeObserver(self)
                    self.removeFromSuperview()
            })
        } else if anim.value(forKey: "animation") as? String == kMovePopUpMessageKey && flag {
            state = .visible
        }
    }

    func hidePopUpMessage() {
        delegate.popUpMessageWillHide(self, inView: superview!)

        state = .hiding

        if position == .underNavigationBar {
            let currentPoint = layer.mask!.position
            let newPoint: CGPoint = .zero

            layer.mask!.position = newPoint

            let moveMaskDown = CABasicAnimation(keyPath: "position")
            moveMaskDown.fromValue = NSValue(cgPoint: currentPoint)
            moveMaskDown.toValue = NSValue(cgPoint: newPoint)
            moveMaskDown.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
            moveMaskDown.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)

            layer.mask!.add(moveMaskDown, forKey: "position")
        }

        let oldPoint = layer.position
        var yCoord = oldPoint.y

        switch position {
        case .top, .underNavigationBar:
            yCoord -= frame.size.height
        case .bottom:
            yCoord += frame.size.height
        }

        let newPoint = CGPoint(x: oldPoint.x, y: yCoord)

        layer.position = newPoint

        let moveLayer = CABasicAnimation(keyPath: "position")
        moveLayer.fromValue = NSValue(cgPoint: oldPoint)
        moveLayer.toValue = NSValue(cgPoint: newPoint)
        moveLayer.duration = shouldForceHide ? kForceHideAnimationDuration : hideAnimationDuration
        moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        moveLayer.delegate = self
        moveLayer.setValue(kHidePopUpMessageKey, forKey: "animation")

        layer.add(moveLayer, forKey: kHidePopUpMessageKey)
    }

    func nextAvailableViewController(_ view: AnyObject) -> AnyObject? {
        let nextResponder = view.next

        if (nextResponder!?.isKind(of: UIViewController.self))! {
            return nextResponder!
        } else if (nextResponder!?.isKind(of: UIView.self))! {
            return nextAvailableViewController(nextResponder!!)
        } else {
            return nil
        }
    }

    func pushPopUpMessage(_ distance: CGFloat, forward: Bool, delay: Double) {
        state = forward ? .movingForward : .movingBackward

        var distanceToPush = distance

        if position == .bottom {
            distanceToPush *= -1
        }

        let activeLayer = isAnimating() ? layer.presentation()! as CALayer : layer

        let oldPoint = activeLayer.position
        let newPoint = CGPoint(x: oldPoint.x, y: layer.position.y + distanceToPush)

        DispatchQueue.main.asyncAfter(deadline: .now()
            + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.layer.position = newPoint

                let moveLayer = CABasicAnimation(keyPath: "position")
                moveLayer.fromValue = NSValue(cgPoint: oldPoint)
                moveLayer.toValue = NSValue(cgPoint: newPoint)
                moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration
                moveLayer.timingFunction = forward ? CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) :
                    CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                moveLayer.delegate = self
                moveLayer.setValue(self.kMovePopUpMessageKey, forKey: "animation")

                self.layer.add(moveLayer, forKey: self.kMovePopUpMessageKey)
        }
    }

    func show() {
        delegate.showPopUpMessage(self, hideAfter: secondsToShow)
    }

    func showPopUpMessage() {
        if !parentFrameUponCreation.equalTo(superview!.bounds) {
            setInitialLayout()
            updateSizeAndSubviewsAnimated(false)
        }

        delegate.popUpMessageWillShow(self, inView: superview!)

        state = .showing

        let deadline: DispatchTime = .now()
            + Double(Int64(fadeInDuration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            if self.position == .underNavigationBar {
                let currentPoint = self.layer.mask!.position
                let newPoint = CGPoint(x: 0, y: -self.frame.size.height)

                self.layer.mask!.position = newPoint

                let moveMaskUp = CABasicAnimation(keyPath: "position")
                moveMaskUp.fromValue = NSValue(cgPoint: currentPoint)
                moveMaskUp.toValue = NSValue(cgPoint: newPoint)
                moveMaskUp.duration = self.showAnimationDuration
                moveMaskUp.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

                self.layer.mask!.add(moveMaskUp, forKey: "position")
            }

            let oldPoint = self.layer.position
            var yCoord = oldPoint.y

            switch self.position {
            case .top, .underNavigationBar:
                yCoord += self.frame.size.height
            case .bottom:
                yCoord -= self.frame.size.height
            }

            let newPoint = CGPoint(x: oldPoint.x, y: yCoord)

            self.layer.position = newPoint

            let moveLayer = CABasicAnimation(keyPath: "position")
            moveLayer.fromValue = NSValue(cgPoint: oldPoint)
            moveLayer.toValue = NSValue(cgPoint: newPoint)
            moveLayer.duration = self.showAnimationDuration
            moveLayer.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            moveLayer.delegate = self
            moveLayer.setValue(self.kShowPopUpMessageKey, forKey: "animation")

            self.layer.add(moveLayer, forKey: self.kShowPopUpMessageKey)
        }

        UIView.animate(withDuration: fadeInDuration, delay: 0, options: .curveLinear, animations: {
            self.alpha = self.bannerOpacity
            }, completion: nil)
    }

    func updatePositionAfterRotationWithY(_ yPos: CGFloat, animated: Bool) {
        var positionAnimationDuration = kRotationDurationIPhone
        let activeLayer = isAnimating() ? layer.presentation()! as CALayer : layer
        var currentAnimationKey: String? = nil
        var timingFunction: CAMediaTimingFunction? = nil

        if isAnimating() {
            let currentAnimation: CAAnimation!

            switch state! {
            case .showing:
                currentAnimation = layer.animation(forKey: kShowPopUpMessageKey)
                currentAnimationKey = kShowPopUpMessageKey
            case .hiding:
                currentAnimation = layer.animation(forKey: kHidePopUpMessageKey)
                currentAnimationKey = kHidePopUpMessageKey
            case .movingBackward, .movingForward:
                currentAnimation = layer.animation(forKey: kMovePopUpMessageKey)
                currentAnimationKey = kMovePopUpMessageKey
            default:
                return
            }

            if currentAnimation != nil {
                let remainingAnimationDuration = currentAnimation.duration - CACurrentMediaTime() +
                    currentAnimation.beginTime
                timingFunction = currentAnimation.timingFunction
                positionAnimationDuration = remainingAnimationDuration
                layer.removeAnimation(forKey: currentAnimationKey!)
            }

        }

        var yPosNew = yPos

        if state == .hiding || state == .movingBackward {
            switch position {
            case .top, .underNavigationBar:
                yPosNew -= layer.bounds.size.height
            case .bottom:
                yPosNew += layer.bounds.size.height
            }
        }

        let oldPos = activeLayer.position
        let newPos = CGPoint(x: oldPos.x, y: yPos)
        layer.position = newPos

        if animated {
            let positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = NSValue(cgPoint: oldPos)
            positionAnimation.toValue = NSValue(cgPoint: newPos)

            if position == .bottom {
                positionAnimationDuration = kRotationDurationIPhone
            }

            positionAnimation.duration = positionAnimationDuration
            positionAnimation.timingFunction = timingFunction == nil ?
                CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear) : timingFunction

            if currentAnimationKey != nil {
                positionAnimation.delegate = self
                positionAnimation.setValue(currentAnimationKey, forKey: "animation")
            }

            layer.add(positionAnimation, forKey: currentAnimationKey)
        }
    }

    func updateSizeAndSubviewsAnimated(_ animated: Bool) {
        let superviewSize = UIScreen.main.bounds.size
        let maxLabelSize = CGSize(width: superviewSize.width - 30, height: .greatestFiniteMagnitude)
        let titleLabelHeight = heightForText(titleLabel.text!, font: titleLabel.font, maxLabelSize: maxLabelSize)
        let subtitleLabelHeight = heightForText(subtitleLabel.text!, font: subtitleLabel.font, maxLabelSize:
            maxLabelSize)
        let heightForSelf = titleLabelHeight + subtitleLabelHeight + 35

        let boundsAnimationDuration = kRotationDurationIPhone

        let oldBounds = layer.bounds
        var newBounds = oldBounds
        newBounds.size = CGSize(width: superviewSize.width, height: heightForSelf)
        layer.bounds = newBounds

        if animated {
            let boundsAnimation = CABasicAnimation(keyPath: "bounds")
            boundsAnimation.fromValue = NSValue(cgRect: oldBounds)
            boundsAnimation.toValue = NSValue(cgRect: newBounds)
            boundsAnimation.duration = boundsAnimationDuration
            layer.add(boundsAnimation, forKey: "bounds")

            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(boundsAnimationDuration)
        }

        titleLabel.frame = CGRect(x: 15, y: 15, width: maxLabelSize.width, height: titleLabelHeight)
        subtitleLabel.frame = CGRect(
            x: titleLabel.frame.origin.x,
            y: titleLabel.frame.origin.y + titleLabel.frame.size.height + 5,
            width: maxLabelSize.width,
            height: subtitleLabelHeight
        )

        if animated {
            UIView.commitAnimations()
        }
    }


    private func heightForText(_ text: String, font: UIFont, maxLabelSize: CGSize) -> CGFloat {
        return (text == "" ? .zero : text.boundingRect(with: maxLabelSize, options: .usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font], context: nil)).size.height
    }

    private func hide() {
        delegate.hidePopUpMessage(self, forced: false)
    }

    private func isAnimating() -> Bool {
        switch state! {
        case .showing, .hiding, .movingForward, .movingBackward:
            return true
        default:
            return false
        }
    }

    private func setInitialLayout() {
        layer.anchorPoint = .zero

        let superview = self.superview!
        parentFrameUponCreation = superview.bounds
        let isSuperviewKindOfWindow = superview.isKind(of: UIWindow.self)

        let maxLabelSize = CGSize(width: superview.bounds.size.width - 30, height: .greatestFiniteMagnitude)
        let titleLabelHeight = heightForText(titleLabel.text!, font: titleLabel.font, maxLabelSize: maxLabelSize)
        let subtitleLabelHeight = heightForText(subtitleLabel.text!, font: subtitleLabel.font, maxLabelSize:
            maxLabelSize)
        let heightForSelf = titleLabelHeight + subtitleLabelHeight + 35

        var frame = CGRect(x: 0, y: 0, width: superview.bounds.size.width, height: heightForSelf)
        var initialYCoord: CGFloat = 0

        switch position {
        case .top:
            initialYCoord = -heightForSelf

            if isSuperviewKindOfWindow {
                initialYCoord += UIApplication.shared.statusBarFrame.size.height
            }

            if let nextResponder: AnyObject = nextAvailableViewController(self) {
                let vc = nextResponder as! UIViewController

                if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKind(of: UIScrollView.self)) {
                    initialYCoord += vc.topLayoutGuide.length
                }
            }
        case .bottom:
            initialYCoord = superview.bounds.size.height
        case .underNavigationBar:
            initialYCoord = -heightForSelf + UIApplication.shared.statusBarFrame.size.height + 44
        }
        
        frame.origin.y = initialYCoord
        self.frame = frame
        
        if position == .underNavigationBar {
            let maskLayer = CAShapeLayer()
            let maskRect = CGRect(
                x: 0,
                y: frame.size.height,
                width: frame.size.width,
                height: superview.bounds.size.height
            )
            maskLayer.path = CGPath(rect: maskRect, transform: nil)
            layer.mask = maskLayer
            layer.mask!.position = .zero
        }
    }

}
