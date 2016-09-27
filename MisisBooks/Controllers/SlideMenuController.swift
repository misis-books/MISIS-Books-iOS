//
//  SlideMenuController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 26.01.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class SlideMenuOption {
    let contentViewOpacity: Float = 0.5
    let menuBezelWidth = UIScreen.main.bounds.width
    let menuViewWidth: CGFloat = 265
    let panFromBezel = true
    var pointOfNoReturnWidth: CGFloat = 20

    init() { }
}

class SlideMenuController: UIViewController {
    enum Action {
        case close
        case open
    }

    struct Panel {
        var action: Action
        var shouldBounce: Bool
        var velocity: CGFloat
    }

    fileprivate var menuContainerView: UIView!
    fileprivate var menuPanGesture: UIPanGestureRecognizer?
    fileprivate var menuTapGetsture: UITapGestureRecognizer?
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
        mainContainerView.backgroundColor = .clear
        mainContainerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.insertSubview(mainContainerView, at: 0)

        opacityView = UIView(frame: view.bounds)
        opacityView.backgroundColor = .white
        opacityView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        opacityView.layer.opacity = 0
        view.insertSubview(opacityView, at: 1)

        var menuFrame = view.bounds
        menuFrame.size.width = options.menuViewWidth
        menuFrame.origin.x = menuMinOrigin()

        let menuOffset: CGFloat = 20
        menuFrame.origin.y = menuFrame.origin.y + menuOffset
        menuFrame.size.height = menuFrame.size.height - menuOffset
        menuContainerView = UIView(frame: menuFrame)

        menuContainerView.backgroundColor = .clear
        menuContainerView.autoresizingMask = .flexibleHeight
        view.insertSubview(menuContainerView, at: 2)

        addMenuGestures()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        closeMenuWithoutAnimation()
        menuContainerView.isHidden = false
        removeMenuGestures()
        addMenuGestures()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge()
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
                menuPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMenuPanGesture(_:)))
                menuPanGesture!.delegate = self
                view.addGestureRecognizer(menuPanGesture!)
            }

            if menuTapGetsture == nil {
                menuTapGetsture = UITapGestureRecognizer(target: self, action: #selector(toggleMenu))
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

        static var frameAtStartOfPan: CGRect = .zero
        static var startPointOfPan: CGPoint = .zero
        static var wasHiddenAtStartOfPan = false
        static var wasOpenAtStartOfPan = false
    }

    func handleMenuPanGesture(_ panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            MenuPanState.frameAtStartOfPan = menuContainerView.frame
            MenuPanState.startPointOfPan = panGesture.location(in: view)
            MenuPanState.wasOpenAtStartOfPan = isMenuOpen()
            MenuPanState.wasHiddenAtStartOfPan = isMenuHidden()

            menuViewController?.beginAppearanceTransition(MenuPanState.wasHiddenAtStartOfPan, animated: true)
            addBorderToView(menuContainerView)
        case .changed:
            menuContainerView.frame = applyTranslation(panGesture.translation(in: panGesture.view!),
                                                       toFrame: MenuPanState.frameAtStartOfPan)
            applyOpacity()
        case .ended:
            menuViewController?.beginAppearanceTransition(!MenuPanState.wasHiddenAtStartOfPan, animated: true)
            let panInfo = panMenuResultInfoForVelocity(panGesture.velocity(in: panGesture.view))

            panInfo.action == .open ? openMenuWithVelocity(panInfo.velocity) : closeMenuWithVelocity(panInfo.velocity)
        default:
            break
        }
    }

    func openMenuWithVelocity(_ velocity: CGFloat) {
        let xOrigin = menuContainerView.frame.origin.x
        let finalXOrigin: CGFloat = 0

        var frame = menuContainerView.frame
        frame.origin.x = finalXOrigin

        let duration = velocity == 0 ? 0.3 : Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity)))

        addBorderToView(menuContainerView)

        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.menuContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
        }) { _ in
            self.mainContainerView.isUserInteractionEnabled = false
        }
    }

    func closeMenuWithVelocity(_ velocity: CGFloat) {
        let xOrigin = menuContainerView.frame.origin.x
        let finalXOrigin = menuMinOrigin()

        var frame = menuContainerView.frame
        frame.origin.x = finalXOrigin

        let duration: Double = velocity == 0 ? 0.3 : Double(fmax(0.1, fmin(1, fabs(xOrigin - finalXOrigin) / velocity)))

        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.menuContainerView.frame = frame
            self.opacityView.layer.opacity = 0
        }) { _ in
            self.removeShadow(self.menuContainerView)
            self.mainContainerView.isUserInteractionEnabled = true
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

    private func panMenuResultInfoForVelocity(_ velocity: CGPoint) -> Panel {
        let leftOrigin = menuContainerView.frame.origin.x
        let pointOfNoReturn = floor(menuMinOrigin()) + options.pointOfNoReturnWidth
        let thresholdVelocity: CGFloat = 1000

        var panInfo = Panel(action: .close, shouldBounce: false, velocity: 0)
        panInfo.action = leftOrigin <= pointOfNoReturn ? .close : .open

        options.pointOfNoReturnWidth = panInfo.action == .open ? options.menuViewWidth - 20 : 20

        if velocity.x >= thresholdVelocity {
            panInfo.action = .open
            panInfo.velocity = velocity.x
        } else if velocity.x <= -thresholdVelocity {
            panInfo.action = .close
            panInfo.velocity = velocity.x
        }

        return panInfo
    }

    private func applyTranslation(_ translation: CGPoint, toFrame: CGRect) -> CGRect {
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
        opacityView.layer.opacity = options.contentViewOpacity
            * Float((menuContainerView.frame.origin.x - menuMinOrigin()) / menuContainerView.frame.size.width)
    }

    private func addBorderToView(_ targetContainerView: UIView) {
        let borderColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        let rightBorder = CALayer()
        rightBorder.backgroundColor = borderColor.cgColor
        rightBorder.frame = CGRect(x: targetContainerView.frame.width, y: 0, width: -0.5,
                                   height: targetContainerView.frame.height)
        targetContainerView.layer.addSublayer(rightBorder)

        let topBorder = CALayer()
        topBorder.backgroundColor = borderColor.cgColor
        topBorder.frame = CGRect(x: 0, y: 0, width: targetContainerView.frame.width, height: 0.5)
        targetContainerView.layer.addSublayer(topBorder)
    }

    private func removeShadow(_ targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = true
        mainContainerView.layer.opacity = 1
    }

    private func setUpViewController(_ taretView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            addChildViewController(viewController)
            viewController.view.frame = taretView.bounds
            taretView.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
        }
    }

    func closeMenuWithoutAnimation() {
        var frame = menuContainerView.frame
        frame.origin.x = menuMinOrigin()
        menuContainerView.frame = frame
        opacityView.layer.opacity = 0
        removeShadow(menuContainerView)
        mainContainerView.isUserInteractionEnabled = true
    }

    private func removeViewController(_ viewController: UIViewController?) {
        if viewController != nil {
            viewController!.willMove(toParentViewController: nil)
            viewController!.view.removeFromSuperview()
            viewController!.removeFromParentViewController()
        }
    }

    func changeMainViewController(to viewController: UIViewController, close: Bool) {
        removeViewController(mainViewController)
        mainViewController = viewController
        setUpViewController(mainContainerView, targetViewController: mainViewController)

        if close {
            closeLeft()
        }
    }

    fileprivate func slideMenuForGestureRecognizer(_ gesture: UIGestureRecognizer, point: CGPoint) -> Bool {
        return isMenuOpen() || options.panFromBezel && isLeftPointContainedWithinBezelRect(point)
    }

    private func isLeftPointContainedWithinBezelRect(_ point: CGPoint) -> Bool {
        let (slice, _) = view.bounds.divided(atDistance: options.menuBezelWidth, from: .minXEdge)

        return slice.contains(point)
    }
}

extension SlideMenuController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: view)
        
        if gestureRecognizer == menuPanGesture {
            return slideMenuForGestureRecognizer(gestureRecognizer, point: point)
        } else if gestureRecognizer == menuTapGetsture {
            return isMenuOpen() && !menuContainerView.frame.contains(point)
        }
        
        return true
    }
}
