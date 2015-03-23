//
//  SlideMenuController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit


class SlideMenuOption {
    
    let leftViewWidth = CGFloat(265.0)
    let leftBezelWidth = UIScreen.mainScreen().bounds.width
    let contentViewScale = CGFloat(1.0) // 0.96
    let contentViewOpacity = CGFloat(0.5)
    let shadowOpacity = CGFloat(0.6) // 0.6
    let shadowRadius = CGFloat(0.0) // 4.0
    let shadowOffset = CGSizeMake(0.0, 0.0) // CGSizeMake(0.0, 2.0)
    let panFromBezel = true
    let animationDuration = CGFloat(0.3)
    let rightViewWidth = CGFloat(265.0)
    let rightBezelWidth = CGFloat(0.0) // UIScreen.mainScreen().bounds.width / 2
    let rightPanFromBezel = true
    let hideStatusBar = false
    var pointOfNoReturnWidth = CGFloat(20.0)
    
    init() { }
}


class SlideMenuController : UIViewController, UIGestureRecognizerDelegate {
    
    enum SlideAction {
        case Open
        case Close
    }
    
    struct PanInfo {
        var action : SlideAction
        var shouldBounce : Bool
        var velocity : CGFloat
    }
    
    var opacityView = UIView()
    var mainContainerView = UIView()
    var leftContainerView = UIView()
    var rightContainerView =  UIView()
    var mainViewController : UIViewController?
    var leftViewController : UIViewController?
    var leftPanGesture : UIPanGestureRecognizer?
    var leftTapGetsture : UITapGestureRecognizer?
    var rightViewController : UIViewController?
    var rightPanGesture : UIPanGestureRecognizer?
    var rightTapGesture : UITapGestureRecognizer?
    var options = SlideMenuOption()
    
    
    override init() {
        super.init()
    }
    
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
    
    convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController, rightMenuViewController: UIViewController) {
        
        self.init()
        
        self.mainViewController = mainViewController
        leftViewController = leftMenuViewController
        rightViewController = rightMenuViewController
        
        initView()
    }
    
    deinit { }
    
    func initView() {
        mainContainerView = UIView(frame: self.view.bounds)
        mainContainerView.backgroundColor = UIColor.clearColor()
        mainContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        self.view.insertSubview(mainContainerView, atIndex: 0)
        
        var opacityframe: CGRect = self.view.bounds
        var opacityOffset: CGFloat = 0
        opacityframe.origin.y = opacityframe.origin.y + opacityOffset
        opacityframe.size.height = opacityframe.size.height - opacityOffset
        opacityView = UIView(frame: opacityframe)
        opacityView.backgroundColor = UIColor.blackColor()
        opacityView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        opacityView.layer.opacity = 0.0
        self.view.insertSubview(opacityView, atIndex: 1)
        
        var leftFrame: CGRect = self.view.bounds
        leftFrame.size.width = options.leftViewWidth
        leftFrame.origin.x = leftMinOrigin()
        var leftOffset: CGFloat = 20.0
        leftFrame.origin.y = leftFrame.origin.y + leftOffset
        leftFrame.size.height = leftFrame.size.height - leftOffset
        leftContainerView = UIView(frame: leftFrame)
        leftContainerView.backgroundColor = UIColor.clearColor()
        leftContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.insertSubview(leftContainerView, atIndex: 2)
        
        var rightFrame: CGRect = self.view.bounds
        rightFrame.size.width = options.rightViewWidth
        rightFrame.origin.x = rightMinOrigin()
        var rightOffset: CGFloat = 0.0
        rightFrame.origin.y = rightFrame.origin.y + rightOffset
        rightFrame.size.height = rightFrame.size.height - rightOffset
        rightContainerView = UIView(frame: rightFrame)
        rightContainerView.backgroundColor = UIColor.clearColor()
        rightContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.insertSubview(rightContainerView, atIndex: 3)
        
        
        self.addLeftGestures()
        self.addRightGestures()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
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
        self.addLeftGestures()
        self.addRightGestures()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.None
    }
    
    override func viewWillLayoutSubviews() {
        setUpViewController(self.mainContainerView, targetViewController: self.mainViewController)
        setUpViewController(leftContainerView, targetViewController: leftViewController)
        setUpViewController(rightContainerView, targetViewController: rightViewController)
    }
    
    func openLeft() {
        setOpenWindowLevel()
        leftViewController?.beginAppearanceTransition(isLeftHidden(), animated: true)
        openLeftWithVelocity(0.0)
    }
    
    func openRight() {
        setOpenWindowLevel()
        rightViewController?.beginAppearanceTransition(isRightHidden(), animated: true)
        openRightWithVelocity(0.0)
    }
    
    func closeLeft() {
        closeLeftWithVelocity(0.0)
        setCloseWindowLevel()
    }
    
    func closeRight() {
        closeRightWithVelocity(0.0)
        setCloseWindowLevel()
    }
    
    
    func addLeftGestures() {
        if leftViewController != nil {
            if leftPanGesture == nil {
                leftPanGesture = UIPanGestureRecognizer(target: self, action: "handleLeftPanGesture:")
                leftPanGesture!.delegate = self
                self.view.addGestureRecognizer(leftPanGesture!)
            }
            
            if leftTapGetsture == nil {
                leftTapGetsture = UITapGestureRecognizer(target: self, action: "toggleLeft")
                leftTapGetsture!.delegate = self
                self.view.addGestureRecognizer(leftTapGetsture!)
            }
        }
    }
    
    func addRightGestures() {
        if rightViewController != nil {
            if rightPanGesture == nil {
                rightPanGesture = UIPanGestureRecognizer(target: self, action: "handleRightPanGesture:")
                rightPanGesture!.delegate = self
                self.view.addGestureRecognizer(rightPanGesture!)
            }
            
            if rightTapGesture == nil {
                rightTapGesture = UITapGestureRecognizer(target: self, action: "toggleRight")
                rightTapGesture!.delegate = self
                self.view.addGestureRecognizer(rightTapGesture!)
            }
        }
    }
    
    func removeLeftGestures() {
        if leftPanGesture != nil {
            self.view.removeGestureRecognizer(leftPanGesture!)
            leftPanGesture = nil
        }
        
        if leftTapGetsture != nil {
            self.view.removeGestureRecognizer(leftTapGetsture!)
            leftTapGetsture = nil
        }
    }
    
    func removeRightGestures() {
        if rightPanGesture != nil {
            self.view.removeGestureRecognizer(rightPanGesture!)
            rightPanGesture = nil
        }
        
        if rightTapGesture != nil {
            self.view.removeGestureRecognizer(rightTapGesture!)
            rightTapGesture = nil
        }
    }
    
    func isTagetViewController() -> Bool {
        // Function to determine the target ViewController
        // Please to override it if necessary
        return true
    }
    
    struct LeftPanState {
        static var frameAtStartOfPan = CGRectZero
        static var startPointOfPan = CGPointZero
        static var wasOpenAtStartOfPan = false
        static var wasHiddenAtStartOfPan = false
    }
    
    func handleLeftPanGesture(panGesture: UIPanGestureRecognizer) {
        
        if !isTagetViewController() {
            return
        } else if isRightOpen() {
            return
        }
        
        switch panGesture.state {
        case UIGestureRecognizerState.Began:
            LeftPanState.frameAtStartOfPan = leftContainerView.frame
            LeftPanState.startPointOfPan = panGesture.locationInView(self.view)
            LeftPanState.wasOpenAtStartOfPan = isLeftOpen()
            LeftPanState.wasHiddenAtStartOfPan = isLeftHidden()
            
            leftViewController?.beginAppearanceTransition(LeftPanState.wasHiddenAtStartOfPan, animated: true)
            addShadowToView(leftContainerView)
            setOpenWindowLevel()
        case UIGestureRecognizerState.Changed:
            var translation = panGesture.translationInView(panGesture.view!)
            leftContainerView.frame = self.applyLeftTranslation(translation, toFrame: LeftPanState.frameAtStartOfPan)
            self.applyLeftOpacity()
            self.applyLeftContentViewScale()
        case UIGestureRecognizerState.Ended:
            leftViewController?.beginAppearanceTransition(!LeftPanState.wasHiddenAtStartOfPan, animated: true)
            var velocity = panGesture.velocityInView(panGesture.view)
            var panInfo = panLeftResultInfoForVelocity(velocity)
            
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
        static var wasOpenAtStartOfPan = false
        static var wasHiddenAtStartOfPan = false
    }
    
    func handleRightPanGesture(panGesture: UIPanGestureRecognizer) {
        
        if !isTagetViewController() {
            return
        } else if isLeftOpen() {
            return
        }
        
        switch panGesture.state {
        case UIGestureRecognizerState.Began:
            rightPanState.frameAtStartOfPan = rightContainerView.frame
            rightPanState.startPointOfPan = panGesture.locationInView(self.view)
            rightPanState.wasOpenAtStartOfPan =  isRightOpen()
            rightPanState.wasHiddenAtStartOfPan = isRightHidden()
            
            rightViewController?.beginAppearanceTransition(rightPanState.wasHiddenAtStartOfPan, animated: true)
            addShadowToView(rightContainerView)
            setOpenWindowLevel()
        case UIGestureRecognizerState.Changed:
            var translation = panGesture.translationInView(panGesture.view!)
            rightContainerView.frame = self.applyRightTranslation(translation, toFrame: rightPanState.frameAtStartOfPan)
            applyRightOpacity()
            applyRightContentViewScale()
            
        case UIGestureRecognizerState.Ended:
            rightViewController?.beginAppearanceTransition(!rightPanState.wasHiddenAtStartOfPan, animated: true)
            var velocity = panGesture.velocityInView(panGesture.view)
            var panInfo = self.panRightResultInfoForVelocity(velocity)
            
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
        var xOrigin : CGFloat = leftContainerView.frame.origin.x
        var finalXOrigin : CGFloat = 0.0
        
        var frame = leftContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration: NSTimeInterval = Double(options.animationDuration)
        
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - finalXOrigin) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        addShadowToView(leftContainerView)
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale, self.options.contentViewScale)
            }) { (Bool) -> Void in
                self.disableContentInteraction()
        }
    }
    
    func openRightWithVelocity(velocity: CGFloat) {
        var xOrigin : CGFloat = rightContainerView.frame.origin.x
        
        //	CGFloat finalXOrigin = options.rightViewOverlapWidth
        var finalXOrigin : CGFloat = CGRectGetWidth(self.view.bounds) - rightContainerView.frame.size.width
        
        var frame = rightContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration : NSTimeInterval = Double(options.animationDuration)
        
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - CGRectGetWidth(self.view.bounds)) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        addShadowToView(rightContainerView)
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale, self.options.contentViewScale)
            }) { (Bool) -> Void in
                self.disableContentInteraction()
        }
    }
    
    func closeLeftWithVelocity(velocity: CGFloat) {
        var xOrigin = leftContainerView.frame.origin.x
        var finalXOrigin = leftMinOrigin()
        
        var frame = leftContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration: NSTimeInterval = Double(options.animationDuration)
        
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - finalXOrigin) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = 0.0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (Bool) -> Void in
                self.removeShadow(self.leftContainerView)
                self.enableContentInteraction()
        }
    }
    
    
    func closeRightWithVelocity(velocity: CGFloat) {
        var xOrigin = rightContainerView.frame.origin.x
        var finalXOrigin = CGRectGetWidth(self.view.bounds)
        
        var frame = rightContainerView.frame
        frame.origin.x = finalXOrigin
        
        var duration: NSTimeInterval = Double(options.animationDuration)
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - CGRectGetWidth(self.view.bounds)) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = 0.0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (Bool) -> Void in
                self.removeShadow(self.rightContainerView)
                self.enableContentInteraction()
        }
    }
    
    
    func toggleLeft() {
        if isLeftOpen() {
            closeLeft()
            setCloseWindowLevel()
        } else {
            self.openLeft()
        }
    }
    
    func isLeftOpen() -> Bool {
        return leftContainerView.frame.origin.x == 0.0
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
        return rightContainerView.frame.origin.x == CGRectGetWidth(self.view.bounds) - rightContainerView.frame.size.width
    }
    
    func isRightHidden() -> Bool {
        return rightContainerView.frame.origin.x >= CGRectGetWidth(self.view.bounds)
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
        return  -options.leftViewWidth
    }
    
    private func rightMinOrigin() -> CGFloat {
        return CGRectGetWidth(self.view.bounds)
    }
    
    
    private func panLeftResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        var thresholdVelocity = CGFloat(1000.0)
        var leftOrigin = leftContainerView.frame.origin.x
        var pointOfNoReturn = CGFloat(floor(leftMinOrigin())) + options.pointOfNoReturnWidth
        
        var panInfo: PanInfo = PanInfo(action: .Close, shouldBounce: false, velocity: 0.0)
        panInfo.action = leftOrigin <= pointOfNoReturn ? .Close : .Open
        
        options.pointOfNoReturnWidth = panInfo.action == .Open ? options.leftViewWidth - 20.0 : 20.0
        
        if velocity.x >= thresholdVelocity {
            panInfo.action = .Open
            panInfo.velocity = velocity.x
        } else if velocity.x <= (-1.0 * thresholdVelocity) {
            panInfo.action = .Close
            panInfo.velocity = velocity.x
        }
        
        
        return panInfo
    }
    
    private func panRightResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        
        var thresholdVelocity = CGFloat(-1000.0)
        var pointOfNoReturn = CGFloat(floor(CGRectGetWidth(self.view.bounds)) - options.pointOfNoReturnWidth)
        var rightOrigin = rightContainerView.frame.origin.x
        
        var panInfo : PanInfo = PanInfo(action: .Close, shouldBounce: false, velocity: 0.0)
        
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
        
        var newOrigin : CGFloat = toFrame.origin.x
        newOrigin += translation.x
        
        var minOrigin: CGFloat = leftMinOrigin()
        var maxOrigin: CGFloat = 0.0
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
        
        var  newOrigin : CGFloat = toFrame.origin.x
        newOrigin += translation.x
        
        var minOrigin: CGFloat = rightMinOrigin()
        //        var maxOrigin: CGFloat = options.rightViewOverlapWidth
        var maxOrigin: CGFloat = rightMinOrigin() - rightContainerView.frame.size.width
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
        
        var width = leftContainerView.frame.size.width
        var currentPosition: CGFloat = leftContainerView.frame.origin.x - leftMinOrigin()
        return currentPosition / width
    }
    
    private func getOpenedRightRatio() -> CGFloat {
        let width = rightContainerView.frame.size.width
        let currentPosition = rightContainerView.frame.origin.x
        return -(currentPosition - CGRectGetWidth(self.view.bounds)) / width
    }
    
    private func applyLeftOpacity() {
        let openedLeftRatio = getOpenedLeftRatio()
        let opacity: CGFloat = options.contentViewOpacity * openedLeftRatio
        opacityView.layer.opacity = Float(opacity)
    }
    
    
    private func applyRightOpacity() {
        let openedRightRatio = getOpenedRightRatio()
        let opacity = options.contentViewOpacity * openedRightRatio
        opacityView.layer.opacity = Float(opacity)
    }
    
    private func applyLeftContentViewScale() {
        let openedLeftRatio = getOpenedLeftRatio()
        let scale : CGFloat = 1.0 - ((1.0 - options.contentViewScale) * openedLeftRatio)
        mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func applyRightContentViewScale() {
        let openedRightRatio = getOpenedRightRatio()
        let scale : CGFloat = 1.0 - ((1.0 - options.contentViewScale) * openedRightRatio)
        mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func addShadowToView(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = false
        targetContainerView.layer.shadowOffset = options.shadowOffset
        targetContainerView.layer.shadowOpacity = Float(options.shadowOpacity)
        targetContainerView.layer.shadowRadius = options.shadowRadius
        targetContainerView.layer.shadowPath = UIBezierPath(rect: targetContainerView.bounds).CGPath
        
        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0).CGColor
        // rightBorder.borderWidth = 0.5
        rightBorder.frame = CGRectMake(CGRectGetWidth(targetContainerView.frame), 0.0, -0.5, CGRectGetHeight(targetContainerView.frame))
        targetContainerView.layer.addSublayer(rightBorder)
        //targetContainerView.layer.borderColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0).CGColor
        //targetContainerView.layer.borderWidth = 0.5
    }
    
    private func removeShadow(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = true
        mainContainerView.layer.opacity = 1.0
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
            
            self.addChildViewController(viewController)
            viewController.view.frame = taretView.bounds
            
            // UIView.transitionWithView(taretView, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {

                taretView.addSubview(viewController.view)
                
            // }, completion: nil)
            viewController.didMoveToParentViewController(self)
        }
    }
    
    
    private func removeViewController(viewController: UIViewController?) {
        if let _viewController = viewController {
            _viewController.willMoveToParentViewController(nil)
            _viewController.view.removeFromSuperview()
            _viewController.removeFromParentViewController()
        }
    }
    
    func closeLeftNonAnimation() {
        setCloseWindowLevel()
        var xOrigin = leftContainerView.frame.origin.x
        var finalXOrigin = leftMinOrigin()
        var frame = leftContainerView.frame
        frame.origin.x = finalXOrigin
        leftContainerView.frame = frame
        opacityView.layer.opacity = 0.0
        mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
        removeShadow(leftContainerView)
        enableContentInteraction()
    }
    
    func closeRightNonAnimation() {
        setCloseWindowLevel()
        var finalXOrigin = CGRectGetWidth(self.view.bounds)
        var frame = rightContainerView.frame
        frame.origin.x = finalXOrigin
        rightContainerView.frame = frame
        opacityView.layer.opacity = 0.0
        mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
        removeShadow(rightContainerView)
        enableContentInteraction()
    }
    
    /// MARK: – Методы UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let point = touch.locationInView(self.view)
        
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
    
    private func slideLeftForGestureRecognizer( gesture: UIGestureRecognizer, point:CGPoint) -> Bool{
        var slide = isLeftOpen()
        slide |= options.panFromBezel && self.isLeftPointContainedWithinBezelRect(point)
        return slide
    }
    
    private func isLeftPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var leftBezelRect = CGRectZero
        var tempRect = CGRectZero
        var bezelWidth = options.leftBezelWidth
        
        CGRectDivide(self.view.bounds, &leftBezelRect, &tempRect, bezelWidth, CGRectEdge.MinXEdge)
        
        return CGRectContainsPoint(leftBezelRect, point)
    }
    
    private func isPointContainedWithinLeftRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(leftContainerView.frame, point)
    }
    
    
    
    private func slideRightViewForGestureRecognizer(gesture: UIGestureRecognizer, withTouchPoint point: CGPoint) -> Bool {
        var slide = isRightOpen()
        slide |= options.rightPanFromBezel && self.isRightPointContainedWithinBezelRect(point)
        
        return slide
    }
    
    private func isRightPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var rightBezelRect: CGRect = CGRectZero
        var tempRect: CGRect = CGRectZero
        // CGFloat bezelWidth = rightContainerView.frame.size.width
        var bezelWidth: CGFloat = CGRectGetWidth(self.view.bounds) - options.rightBezelWidth
        
        CGRectDivide(self.view.bounds, &tempRect, &rightBezelRect, bezelWidth, CGRectEdge.MinXEdge)
        
        return CGRectContainsPoint(rightBezelRect, point)
    }
    
    private func isPointContainedWithinRightRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(rightContainerView.frame, point)
    }
}