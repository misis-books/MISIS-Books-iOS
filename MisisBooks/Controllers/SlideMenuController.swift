//
//  SlideMenuController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class SlideMenuOption {

    let contentViewOpacity: Float = 0.5
    let menuBezelWidth = UIScreen.mainScreen().bounds.width
    let menuViewWidth: CGFloat = 265
    let panFromBezel = true
    var pointOfNoReturnWidth: CGFloat = 20
    
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
    
    private var menuContainerView: UIView!
    private var menuPanGesture: UIPanGestureRecognizer?
    private var menuTapGetsture: UITapGestureRecognizer?
    private var menuViewController: UIViewController?
    private var mainContainerView: UIView!
    private var mainViewController: UIViewController?
    private var opacityView: UIView!
    private var options = SlideMenuOption()

    convenience init(mainViewController: UIViewController, menuViewController: UIViewController) {
        self.init()
        
        self.mainViewController = mainViewController
        self.menuViewController = menuViewController

        mainContainerView = UIView(frame: view.bounds)
        mainContainerView.backgroundColor = .clearColor()
        mainContainerView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        view.insertSubview(mainContainerView, atIndex: 0)

        opacityView = UIView(frame: view.bounds)
        opacityView.backgroundColor = .blackColor()
        opacityView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        opacityView.layer.opacity = 0
        view.insertSubview(opacityView, atIndex: 1)

        var menuFrame = view.bounds
        menuFrame.size.width = options.menuViewWidth
        menuFrame.origin.x = menuMinOrigin()

        let menuOffset: CGFloat = 20
        menuFrame.origin.y = menuFrame.origin.y + menuOffset
        menuFrame.size.height = menuFrame.size.height - menuOffset
        menuContainerView = UIView(frame: menuFrame)

        menuContainerView.backgroundColor = .clearColor()
        menuContainerView.autoresizingMask = .FlexibleHeight
        view.insertSubview(menuContainerView, atIndex: 2)

        addMenuGestures()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)

        menuContainerView.hidden = true
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        
        closeMenuWithoutAnimation()
        menuContainerView.hidden = false
        removeMenuGestures()
        addMenuGestures()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
    }
    
    override func viewWillLayoutSubviews() {
        setUpViewController(mainContainerView, targetViewController: mainViewController)
        setUpViewController(menuContainerView, targetViewController: menuViewController)
    }
    
    func openLeft() {
        menuViewController?.beginAppearanceTransition(isMenuHidden(), animated: true)
        openMenuWithVelocity(0)
    }
    
    func closeLeft() {
        closeMenuWithVelocity(0)
    }
    
    func addMenuGestures() {
        if menuViewController != nil {
            if menuPanGesture == nil {
                menuPanGesture = UIPanGestureRecognizer(target: self, action: "handleMenuPanGesture:")
                menuPanGesture!.delegate = self
                view.addGestureRecognizer(menuPanGesture!)
            }
            
            if menuTapGetsture == nil {
                menuTapGetsture = UITapGestureRecognizer(target: self, action: "toggleMenu")
                menuTapGetsture!.delegate = self
                view.addGestureRecognizer(menuTapGetsture!)
            }
        }
    }
    
    func removeMenuGestures() {
        if menuPanGesture != nil {
            view.removeGestureRecognizer(menuPanGesture!)
            menuPanGesture = nil
        }
        
        if menuTapGetsture != nil {
            view.removeGestureRecognizer(menuTapGetsture!)
            menuTapGetsture = nil
        }
    }
    
    struct MenuPanState {
        static var frameAtStartOfPan = CGRectZero
        static var startPointOfPan = CGPointZero
        static var wasHiddenAtStartOfPan = false
        static var wasOpenAtStartOfPan = false
    }
    
    func handleMenuPanGesture(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .Began:
            MenuPanState.frameAtStartOfPan = menuContainerView.frame
            MenuPanState.startPointOfPan = panGesture.locationInView(view)
            MenuPanState.wasOpenAtStartOfPan = isMenuOpen()
            MenuPanState.wasHiddenAtStartOfPan = isMenuHidden()
            
            menuViewController?.beginAppearanceTransition(MenuPanState.wasHiddenAtStartOfPan, animated: true)
            addBorderToView(menuContainerView)
        case .Changed:
            menuContainerView.frame = applyTranslation(panGesture.translationInView(panGesture.view!),
                toFrame: MenuPanState.frameAtStartOfPan)
            applyOpacity()
        case .Ended:
            menuViewController?.beginAppearanceTransition(!MenuPanState.wasHiddenAtStartOfPan, animated: true)
            let panInfo = panMenuResultInfoForVelocity(panGesture.velocityInView(panGesture.view))
            
            panInfo.action == .Open ? openMenuWithVelocity(panInfo.velocity) : closeMenuWithVelocity(panInfo.velocity)
        default:
            break
        }
        
    }
    
    func openMenuWithVelocity(velocity: CGFloat) {
        let xOrigin = menuContainerView.frame.origin.x
        let finalXOrigin: CGFloat = 0
        
        var frame = menuContainerView.frame
        frame.origin.x = finalXOrigin

        let duration = velocity != 0 ? Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity))) : 0.3
        
        addBorderToView(menuContainerView)
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.menuContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            }) { _ in
                self.mainContainerView.userInteractionEnabled = false
        }
    }
    
    func closeMenuWithVelocity(velocity: CGFloat) {
        let xOrigin = menuContainerView.frame.origin.x
        let finalXOrigin = menuMinOrigin()
        
        var frame = menuContainerView.frame
        frame.origin.x = finalXOrigin

        let duration = velocity != 0 ? Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity))) : 0.3
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.menuContainerView.frame = frame
            self.opacityView.layer.opacity = 0
            }) { _ in
                self.removeShadow(self.menuContainerView)
                self.mainContainerView.userInteractionEnabled = true
        }
    }
    
    func toggleMenu() {
        isMenuOpen() ? closeLeft() : openLeft()
    }
    
    func isMenuOpen() -> Bool {
        return menuContainerView.frame.origin.x == 0
    }
    
    func isMenuHidden() -> Bool {
        return menuContainerView.frame.origin.x <= menuMinOrigin()
    }
    
    private func menuMinOrigin() -> CGFloat {
        return -options.menuViewWidth
    }

    private func panMenuResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        let leftOrigin = menuContainerView.frame.origin.x
        let pointOfNoReturn = floor(menuMinOrigin()) + options.pointOfNoReturnWidth
        let thresholdVelocity: CGFloat = 1000
        
        var panInfo = PanInfo(action: .Close, shouldBounce: false, velocity: 0)
        panInfo.action = leftOrigin <= pointOfNoReturn ? .Close : .Open
        
        options.pointOfNoReturnWidth = panInfo.action == .Open ? options.menuViewWidth - 20 : 20
        
        if velocity.x >= thresholdVelocity {
            panInfo.action = .Open
            panInfo.velocity = velocity.x
        } else if velocity.x <= -thresholdVelocity {
            panInfo.action = .Close
            panInfo.velocity = velocity.x
        }
        
        return panInfo
    }
    
    private func applyTranslation(translation: CGPoint, toFrame: CGRect) -> CGRect {
        var newOrigin = toFrame.origin.x
        newOrigin += translation.x
        
        let minOrigin = menuMinOrigin()
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

    private func applyOpacity() {
        opacityView.layer.opacity = options.contentViewOpacity * Float((menuContainerView.frame.origin.x - menuMinOrigin()) /
            menuContainerView.frame.size.width)
    }
    
    private func addBorderToView(targetContainerView: UIView) {
        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1).CGColor
        rightBorder.frame = CGRectMake(targetContainerView.frame.width, 0, -0.5, targetContainerView.frame.height)
        targetContainerView.layer.addSublayer(rightBorder)
    }
    
    private func removeShadow(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = true
        mainContainerView.layer.opacity = 1
    }


    
    private func setUpViewController(taretView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            addChildViewController(viewController)
            viewController.view.frame = taretView.bounds
            taretView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
        }
    }
    
    func closeMenuWithoutAnimation() {
        var frame = menuContainerView.frame
        frame.origin.x = menuMinOrigin()
        menuContainerView.frame = frame
        opacityView.layer.opacity = 0
        removeShadow(menuContainerView)
        mainContainerView.userInteractionEnabled = true
    }

    private func removeViewController(viewController: UIViewController?) {
        if viewController != nil {
            viewController!.willMoveToParentViewController(nil)
            viewController!.view.removeFromSuperview()
            viewController!.removeFromParentViewController()
        }
    }
    
    func changeMainViewController(mainViewController: UIViewController, close: Bool) {
        removeViewController(self.mainViewController)
        self.mainViewController = mainViewController
        setUpViewController(self.mainContainerView, targetViewController: self.mainViewController)

        if close {
            closeLeft()
        }
    }

    private func slideMenuForGestureRecognizer(gesture: UIGestureRecognizer, point: CGPoint) -> Bool {
        return isMenuOpen() || options.panFromBezel && isLeftPointContainedWithinBezelRect(point)
    }

    private func isLeftPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var bezelRect = CGRectZero
        var tempRect = CGRectZero
        let bezelWidth = options.menuBezelWidth

        CGRectDivide(view.bounds, &bezelRect, &tempRect, bezelWidth, .MinXEdge)

        return CGRectContainsPoint(bezelRect, point)
    }

    // MARK: – Методы UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let point = touch.locationInView(view)
        
        if gestureRecognizer == menuPanGesture {
            return slideMenuForGestureRecognizer(gestureRecognizer, point: point)
        } else if gestureRecognizer == menuTapGetsture {
            return isMenuOpen() && !CGRectContainsPoint(menuContainerView.frame, point)
        }
        
        return true
    }
}
