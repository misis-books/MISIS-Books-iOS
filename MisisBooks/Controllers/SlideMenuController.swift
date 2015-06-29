//
//  SlideMenuController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class SlideMenuOption {
    
    let animationDuration: NSTimeInterval = 0.3
    let contentViewOpacity: Float = 0.5
    let contentViewScale: CGFloat = 1
    let hideStatusBar = false
    let leftBezelWidth = UIScreen.mainScreen().bounds.width
    let leftViewWidth: CGFloat = 265
    let panFromBezel = true
    var pointOfNoReturnWidth: CGFloat = 20
    let rightBezelWidth: CGFloat = 0
    let rightPanFromBezel = true
    let rightViewWidth: CGFloat = 265
    let shadowOffset = CGSizeZero
    let shadowOpacity: Float = 0.6
    let shadowRadius: CGFloat = 0
    
    init() { }
}

class SlideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    enum SlideAction {
        case Close, Open
    }
    
    struct PanInfo {
        var action: SlideAction
        var shouldBounce: Bool
        var velocity: CGFloat
    }
    
    private var leftContainerView: UIView!
    private var leftPanGesture: UIPanGestureRecognizer?
    private var leftTapGetsture: UITapGestureRecognizer?
    private var leftViewController: UIViewController?
    private var mainContainerView: UIView!
    private var mainViewController: UIViewController?
    private var opacityView: UIView!
    private var options = SlideMenuOption()
    private var rightContainerView: UIView!
    private var rightPanGesture: UIPanGestureRecognizer?
    private var rightTapGesture: UITapGestureRecognizer?
    private var rightViewController: UIViewController?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController) {
        self.init()
        
        self.mainViewController = mainViewController
        leftViewController = leftMenuViewController
        initView()
    }
    
    convenience init(mainViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        
        self.mainViewController = mainViewController
        rightViewController = rightMenuViewController
        initView()
    }
    
    convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController,
        rightMenuViewController: UIViewController) {
            self.init()
            
            self.mainViewController = mainViewController
            leftViewController = leftMenuViewController
            rightViewController = rightMenuViewController
            
            initView()
    }
    
    func initView() {
        mainContainerView = UIView(frame: view.bounds)
        mainContainerView.backgroundColor = .clearColor()
        mainContainerView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        view.insertSubview(mainContainerView, atIndex: 0)
        
        var opacityframe = view.bounds
        let opacityOffset: CGFloat = 0
        opacityframe.origin.y = opacityframe.origin.y + opacityOffset
        opacityframe.size.height = opacityframe.size.height - opacityOffset
        opacityView = UIView(frame: opacityframe)
        opacityView.backgroundColor = .blackColor()
        opacityView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        opacityView.layer.opacity = 0
        view.insertSubview(opacityView, atIndex: 1)
        
        var leftFrame = view.bounds
        leftFrame.size.width = options.leftViewWidth
        leftFrame.origin.x = leftMinOrigin()
        let leftOffset: CGFloat = 20
        leftFrame.origin.y = leftFrame.origin.y + leftOffset
        leftFrame.size.height = leftFrame.size.height - leftOffset
        leftContainerView = UIView(frame: leftFrame)
        leftContainerView.backgroundColor = .clearColor()
        leftContainerView.autoresizingMask = .FlexibleHeight
        view.insertSubview(leftContainerView, atIndex: 2)
        
        var rightFrame = view.bounds
        rightFrame.size.width = options.rightViewWidth
        rightFrame.origin.x = rightMinOrigin()
        let rightOffset: CGFloat = 0
        rightFrame.origin.y = rightFrame.origin.y + rightOffset
        rightFrame.size.height = rightFrame.size.height - rightOffset
        rightContainerView = UIView(frame: rightFrame)
        rightContainerView.backgroundColor = .clearColor()
        rightContainerView.autoresizingMask = .FlexibleHeight
        view.insertSubview(rightContainerView, atIndex: 3)
        
        addLeftGestures()
        addRightGestures()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        mainContainerView.transform = CGAffineTransformMakeScale(1, 1)
        leftContainerView.hidden = true
        rightContainerView.hidden = true
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        
        closeLeftNonAnimation()
        closeRightNonAnimation()
        leftContainerView.hidden = false
        rightContainerView.hidden = false
        
        removeLeftGestures()
        removeRightGestures()
        addLeftGestures()
        addRightGestures()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
    }
    
    override func viewWillLayoutSubviews() {
        setUpViewController(mainContainerView, targetViewController: mainViewController)
        setUpViewController(leftContainerView, targetViewController: leftViewController)
        setUpViewController(rightContainerView, targetViewController: rightViewController)
    }
    
    func openLeft() {
        setOpenWindowLevel()
        leftViewController?.beginAppearanceTransition(isLeftHidden(), animated: true)
        openLeftWithVelocity(0)
    }
    
    func openRight() {
        setOpenWindowLevel()
        rightViewController?.beginAppearanceTransition(isRightHidden(), animated: true)
        openRightWithVelocity(0)
    }
    
    func closeLeft() {
        closeLeftWithVelocity(0)
        setCloseWindowLevel()
    }
    
    func closeRight() {
        closeRightWithVelocity(0)
        setCloseWindowLevel()
    }
    
    func addLeftGestures() {
        if leftViewController != nil {
            if leftPanGesture == nil {
                leftPanGesture = UIPanGestureRecognizer(target: self, action: "handleLeftPanGesture:")
                leftPanGesture!.delegate = self
                view.addGestureRecognizer(leftPanGesture!)
            }
            
            if leftTapGetsture == nil {
                leftTapGetsture = UITapGestureRecognizer(target: self, action: "toggleLeft")
                leftTapGetsture!.delegate = self
                view.addGestureRecognizer(leftTapGetsture!)
            }
        }
    }
    
    func addRightGestures() {
        if rightViewController != nil {
            if rightPanGesture == nil {
                rightPanGesture = UIPanGestureRecognizer(target: self, action: "handleRightPanGesture:")
                rightPanGesture!.delegate = self
                view.addGestureRecognizer(rightPanGesture!)
            }
            
            if rightTapGesture == nil {
                rightTapGesture = UITapGestureRecognizer(target: self, action: "toggleRight")
                rightTapGesture!.delegate = self
                view.addGestureRecognizer(rightTapGesture!)
            }
        }
    }
    
    func removeLeftGestures() {
        if leftPanGesture != nil {
            view.removeGestureRecognizer(leftPanGesture!)
            leftPanGesture = nil
        }
        
        if leftTapGetsture != nil {
            view.removeGestureRecognizer(leftTapGetsture!)
            leftTapGetsture = nil
        }
    }
    
    func removeRightGestures() {
        if rightPanGesture != nil {
            view.removeGestureRecognizer(rightPanGesture!)
            rightPanGesture = nil
        }
        
        if rightTapGesture != nil {
            view.removeGestureRecognizer(rightTapGesture!)
            rightTapGesture = nil
        }
    }
    
    func isTagetViewController() -> Bool {
        return true
    }
    
    struct LeftPanState {
        
        static var frameAtStartOfPan = CGRectZero
        static var startPointOfPan = CGPointZero
        static var wasHiddenAtStartOfPan = false
        static var wasOpenAtStartOfPan = false
    }
    
    func handleLeftPanGesture(panGesture: UIPanGestureRecognizer) {
        if !isTagetViewController() || isRightOpen() {
            return
        }
        
        switch panGesture.state {
        case .Began:
            LeftPanState.frameAtStartOfPan = leftContainerView.frame
            LeftPanState.startPointOfPan = panGesture.locationInView(view)
            LeftPanState.wasOpenAtStartOfPan = isLeftOpen()
            LeftPanState.wasHiddenAtStartOfPan = isLeftHidden()
            
            leftViewController?.beginAppearanceTransition(LeftPanState.wasHiddenAtStartOfPan, animated: true)
            addShadowToView(leftContainerView)
            setOpenWindowLevel()
        case .Changed:
            let translation = panGesture.translationInView(panGesture.view!)
            leftContainerView.frame = applyLeftTranslation(translation, toFrame: LeftPanState.frameAtStartOfPan)
            applyLeftOpacity()
            applyLeftContentViewScale()
        case .Ended:
            leftViewController?.beginAppearanceTransition(!LeftPanState.wasHiddenAtStartOfPan, animated: true)
            let panInfo = panLeftResultInfoForVelocity(panGesture.velocityInView(panGesture.view))
            
            if panInfo.action == .Open {
                openLeftWithVelocity(panInfo.velocity)
            } else {
                closeLeftWithVelocity(panInfo.velocity)
                setCloseWindowLevel()
            }
        default:
            break
        }
        
    }
    
    struct rightPanState {
        static var frameAtStartOfPan = CGRectZero
        static var startPointOfPan = CGPointZero
        static var wasHiddenAtStartOfPan = false
        static var wasOpenAtStartOfPan = false
    }
    
    func handleRightPanGesture(panGesture: UIPanGestureRecognizer) {
        if !isTagetViewController() || isLeftOpen() {
            return
        }
        
        switch panGesture.state {
        case .Began:
            rightPanState.frameAtStartOfPan = rightContainerView.frame
            rightPanState.startPointOfPan = panGesture.locationInView(view)
            rightPanState.wasOpenAtStartOfPan = isRightOpen()
            rightPanState.wasHiddenAtStartOfPan = isRightHidden()
            
            rightViewController?.beginAppearanceTransition(rightPanState.wasHiddenAtStartOfPan, animated: true)
            addShadowToView(rightContainerView)
            setOpenWindowLevel()
        case .Changed:
            let translation = panGesture.translationInView(panGesture.view!)
            rightContainerView.frame = applyRightTranslation(translation, toFrame: rightPanState.frameAtStartOfPan)
            applyRightOpacity()
            applyRightContentViewScale()
        case .Ended:
            rightViewController?.beginAppearanceTransition(!rightPanState.wasHiddenAtStartOfPan, animated: true)
            let panInfo = panRightResultInfoForVelocity(panGesture.velocityInView(panGesture.view))
            
            if panInfo.action == .Open {
                openRightWithVelocity(panInfo.velocity)
            } else {
                closeRightWithVelocity(panInfo.velocity)
                setCloseWindowLevel()
            }
        default:
            break
        }
    }
    
    func openLeftWithVelocity(velocity: CGFloat) {
        let xOrigin = leftContainerView.frame.origin.x
        let finalXOrigin: CGFloat = 0
        
        var frame = leftContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration = options.animationDuration
        
        if velocity != 0 {
            duration = Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity)))
        }
        
        addShadowToView(leftContainerView)
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale,
                self.options.contentViewScale)
            }) { _ in
                self.disableContentInteraction()
        }
    }
    
    func openRightWithVelocity(velocity: CGFloat) {
        let xOrigin = rightContainerView.frame.origin.x
        let finalXOrigin = CGRectGetWidth(view.bounds) - rightContainerView.frame.size.width
        
        var frame = rightContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration = options.animationDuration
        
        if velocity != 0 {
            duration = Double(fmax(0.1, fmin(1, fabs(xOrigin - CGRectGetWidth(view.bounds)) / velocity)))
        }
        
        addShadowToView(rightContainerView)
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale,
                self.options.contentViewScale)
            }) { _ in
                self.disableContentInteraction()
        }
    }
    
    func closeLeftWithVelocity(velocity: CGFloat) {
        let xOrigin = leftContainerView.frame.origin.x
        let finalXOrigin = leftMinOrigin()
        
        var frame = leftContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration = options.animationDuration
        
        if velocity != 0 {
            duration = Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity)))
        }
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = 0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1, 1)
            }) { _ in
                self.removeShadow(self.leftContainerView)
                self.enableContentInteraction()
        }
    }
    
    func closeRightWithVelocity(velocity: CGFloat) {
        let xOrigin = rightContainerView.frame.origin.x
        let finalXOrigin = CGRectGetWidth(view.bounds)
        
        var frame = rightContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration = options.animationDuration
        
        if velocity != 0 {
            duration = Double(fmax(0.1, fmin(1, fabs(xOrigin - CGRectGetWidth(view.bounds)) / velocity)))
        }
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = 0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1, 1)
            }) { _ in
                self.removeShadow(self.rightContainerView)
                self.enableContentInteraction()
        }
    }
    
    func toggleLeft() {
        if isLeftOpen() {
            closeLeft()
            setCloseWindowLevel()
        } else {
            openLeft()
        }
    }
    
    func isLeftOpen() -> Bool {
        return leftContainerView.frame.origin.x == 0
    }
    
    func isLeftHidden() -> Bool {
        return leftContainerView.frame.origin.x <= leftMinOrigin()
    }
    
    func toggleRight() {
        if isRightOpen() {
            closeRight()
            setCloseWindowLevel()
        } else {
            openRight()
        }
    }
    
    func isRightOpen() -> Bool {
        return rightContainerView.frame.origin.x == CGRectGetWidth(view.bounds) - rightContainerView.frame.size.width
    }
    
    func isRightHidden() -> Bool {
        return rightContainerView.frame.origin.x >= CGRectGetWidth(view.bounds)
    }
    
    func changeMainViewController(mainViewController: UIViewController, close: Bool) {
        removeViewController(self.mainViewController)
        self.mainViewController = mainViewController
        setUpViewController(self.mainContainerView, targetViewController: self.mainViewController)
        
        if close {
            closeLeft()
            closeRight()
        }
    }
    
    func changeLeftViewController(leftViewController: UIViewController, closeLeft: Bool) {
        removeViewController(leftViewController)
        self.leftViewController = leftViewController
        setUpViewController(leftContainerView, targetViewController: leftViewController)
        
        if closeLeft {
            self.closeLeft()
        }
    }
    
    func changeRightViewController(rightViewController: UIViewController, closeRight: Bool) {
        removeViewController(rightViewController)
        self.rightViewController = rightViewController
        setUpViewController(rightContainerView, targetViewController: rightViewController)
        
        if closeRight {
            self.closeRight()
        }
    }
    
    private func leftMinOrigin() -> CGFloat {
        return -options.leftViewWidth
    }
    
    private func rightMinOrigin() -> CGFloat {
        return CGRectGetWidth(view.bounds)
    }
    
    private func panLeftResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        let leftOrigin = leftContainerView.frame.origin.x
        let pointOfNoReturn = floor(leftMinOrigin()) + options.pointOfNoReturnWidth
        let thresholdVelocity: CGFloat = 1000
        
        var panInfo = PanInfo(action: .Close, shouldBounce: false, velocity: 0)
        panInfo.action = leftOrigin <= pointOfNoReturn ? .Close : .Open
        
        options.pointOfNoReturnWidth = panInfo.action == .Open ? options.leftViewWidth - 20 : 20
        
        if velocity.x >= thresholdVelocity {
            panInfo.action = .Open
            panInfo.velocity = velocity.x
        } else if velocity.x <= -thresholdVelocity {
            panInfo.action = .Close
            panInfo.velocity = velocity.x
        }
        
        return panInfo
    }
    
    private func panRightResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        let rightOrigin = rightContainerView.frame.origin.x
        let pointOfNoReturn = floor(CGRectGetWidth(view.bounds)) - options.pointOfNoReturnWidth
        let thresholdVelocity: CGFloat = -1000
        
        var panInfo = PanInfo(action: .Close, shouldBounce: false, velocity: 0)
        panInfo.action = rightOrigin >= pointOfNoReturn ? .Close : .Open
        
        if velocity.x <= thresholdVelocity {
            panInfo.action = .Open
            panInfo.velocity = velocity.x
        } else if velocity.x >= -thresholdVelocity {
            panInfo.action = .Close
            panInfo.velocity = velocity.x
        }
        
        return panInfo
    }
    
    private func applyLeftTranslation(translation: CGPoint, toFrame: CGRect) -> CGRect {
        var newOrigin = toFrame.origin.x
        newOrigin += translation.x
        
        let minOrigin = leftMinOrigin()
        let maxOrigin: CGFloat = 0
        var newFrame = toFrame
        
        if newOrigin < minOrigin {
            newOrigin = minOrigin
        } else if newOrigin > maxOrigin {
            newOrigin = maxOrigin
        }
        
        newFrame.origin.x = newOrigin
        
        return newFrame
    }
    
    private func applyRightTranslation(translation: CGPoint, toFrame: CGRect) -> CGRect {
        var newOrigin = toFrame.origin.x
        newOrigin += translation.x
        
        let minOrigin = rightMinOrigin()
        let maxOrigin = rightMinOrigin() - rightContainerView.frame.size.width
        var newFrame = toFrame
        
        if newOrigin > minOrigin {
            newOrigin = minOrigin
        } else if newOrigin < maxOrigin {
            newOrigin = maxOrigin
        }
        
        newFrame.origin.x = newOrigin
        
        return newFrame
    }
    
    private func getOpenedLeftRatio() -> CGFloat {
        return (leftContainerView.frame.origin.x - leftMinOrigin()) / leftContainerView.frame.size.width
    }
    
    private func getOpenedRightRatio() -> CGFloat {
        return -(rightContainerView.frame.origin.x - CGRectGetWidth(view.bounds)) / rightContainerView.frame.size.width
    }
    
    private func applyLeftOpacity() {
        opacityView.layer.opacity = options.contentViewOpacity * Float(getOpenedLeftRatio())
    }
    
    private func applyRightOpacity() {
        opacityView.layer.opacity = options.contentViewOpacity * Float(getOpenedRightRatio())
    }
    
    private func applyLeftContentViewScale() {
        let scale = 1 - (1 - options.contentViewScale) * getOpenedLeftRatio()
        mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func applyRightContentViewScale() {
        let scale = 1 - (1 - options.contentViewScale) * getOpenedRightRatio()
        mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func addShadowToView(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = false
        targetContainerView.layer.shadowOffset = options.shadowOffset
        targetContainerView.layer.shadowOpacity = options.shadowOpacity
        targetContainerView.layer.shadowRadius = options.shadowRadius
        targetContainerView.layer.shadowPath = UIBezierPath(rect: targetContainerView.bounds).CGPath
        
        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).CGColor
        // rightBorder.borderWidth = 0.5
        rightBorder.frame = CGRectMake(CGRectGetWidth(targetContainerView.frame), 0, -0.5,
            CGRectGetHeight(targetContainerView.frame))
        targetContainerView.layer.addSublayer(rightBorder)
        // targetContainerView.layer.borderColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).CGColor
        // targetContainerView.layer.borderWidth = 0.5
    }
    
    private func removeShadow(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = true
        mainContainerView.layer.opacity = 1
    }
    
    private func disableContentInteraction() {
        mainContainerView.userInteractionEnabled = false
    }
    
    private func enableContentInteraction() {
        mainContainerView.userInteractionEnabled = true
    }
    
    private func setOpenWindowLevel() {
        if options.hideStatusBar {
            dispatch_async(dispatch_get_main_queue()) {
                if let window = UIApplication.sharedApplication().keyWindow {
                    window.windowLevel = UIWindowLevelStatusBar + 1
                }
            }
        }
    }
    
    private func setCloseWindowLevel() {
        if options.hideStatusBar {
            dispatch_async(dispatch_get_main_queue()) {
                if let window = UIApplication.sharedApplication().keyWindow {
                    window.windowLevel = UIWindowLevelNormal
                }
            }
        }
    }
    
    private func setUpViewController(taretView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            addChildViewController(viewController)
            viewController.view.frame = taretView.bounds
            
            // UIView.transitionWithView(taretView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
            taretView.addSubview(viewController.view)
            // }, completion: nil)
            viewController.didMoveToParentViewController(self)
        }
    }
    
    private func removeViewController(viewController: UIViewController?) {
        if viewController != nil {
            viewController!.willMoveToParentViewController(nil)
            viewController!.view.removeFromSuperview()
            viewController!.removeFromParentViewController()
        }
    }
    
    func closeLeftNonAnimation() {
        setCloseWindowLevel()
        var frame = leftContainerView.frame
        frame.origin.x = leftMinOrigin()
        leftContainerView.frame = frame
        opacityView.layer.opacity = 0
        mainContainerView.transform = CGAffineTransformMakeScale(1, 1)
        removeShadow(leftContainerView)
        enableContentInteraction()
    }
    
    func closeRightNonAnimation() {
        setCloseWindowLevel()
        var frame = rightContainerView.frame
        frame.origin.x = CGRectGetWidth(view.bounds)
        rightContainerView.frame = frame
        opacityView.layer.opacity = 0
        mainContainerView.transform = CGAffineTransformMakeScale(1, 1)
        removeShadow(rightContainerView)
        enableContentInteraction()
    }
    
    // MARK: – Методы UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let point = touch.locationInView(view)
        
        if gestureRecognizer == leftPanGesture {
            return slideLeftForGestureRecognizer(gestureRecognizer, point: point)
        } else if gestureRecognizer == rightPanGesture {
            return slideRightViewForGestureRecognizer(gestureRecognizer, withTouchPoint: point)
        } else if gestureRecognizer == leftTapGetsture {
            return isLeftOpen() && !isPointContainedWithinLeftRect(point)
        } else if gestureRecognizer == rightTapGesture {
            return isRightOpen() && !isPointContainedWithinRightRect(point)
        }
        
        return true
    }
    
    private func slideLeftForGestureRecognizer(gesture: UIGestureRecognizer, point: CGPoint) -> Bool {
        return isLeftOpen() || options.panFromBezel && isLeftPointContainedWithinBezelRect(point)
    }
    
    private func isLeftPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var leftBezelRect = CGRectZero
        var tempRect = CGRectZero
        let bezelWidth = options.leftBezelWidth
        
        CGRectDivide(view.bounds, &leftBezelRect, &tempRect, bezelWidth, .MinXEdge)
        
        return CGRectContainsPoint(leftBezelRect, point)
    }
    
    private func isPointContainedWithinLeftRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(leftContainerView.frame, point)
    }
    
    private func slideRightViewForGestureRecognizer(gesture: UIGestureRecognizer, withTouchPoint point: CGPoint) -> Bool {
        return isRightOpen() || options.rightPanFromBezel && isRightPointContainedWithinBezelRect(point)
    }
    
    private func isRightPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var rightBezelRect = CGRectZero
        var tempRect = CGRectZero
        let bezelWidth = CGRectGetWidth(view.bounds) - options.rightBezelWidth
        
        CGRectDivide(view.bounds, &tempRect, &rightBezelRect, bezelWidth, .MinXEdge)
        
        return CGRectContainsPoint(rightBezelRect, point)
    }
    
    private func isPointContainedWithinRightRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(rightContainerView.frame, point)
    }
}
