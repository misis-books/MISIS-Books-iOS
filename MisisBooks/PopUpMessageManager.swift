//
//  PopUpMessageManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 29.06.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class PopUpMessageManager: NSObject, PopUpMessageDelegate {
    static let instance = PopUpMessageManager()
    private let bottomPositionSemaphore: DispatchSemaphore
    private let topPositionSemaphore: DispatchSemaphore
    private let navigationBarPositionSemaphore: DispatchSemaphore
    private var popUpMessages: [PopUpMessage]
    private var bannerViews: [UIView]

    override init() {
        topPositionSemaphore = DispatchSemaphore(value: 0)
        topPositionSemaphore.signal()

        bottomPositionSemaphore = DispatchSemaphore(value: 0)
        bottomPositionSemaphore.signal()

        navigationBarPositionSemaphore = DispatchSemaphore(value: 0)
        navigationBarPositionSemaphore.signal()

        bannerViews = [UIView]()
        popUpMessages = [PopUpMessage]()

        super.init()

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(didRotate(_:)),
                                               name: .UIDeviceOrientationDidChange, object: nil)
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func showPopUpMessage(_ popUpMessage: PopUpMessage!, hideAfter delay: TimeInterval) {
        let semaphore: DispatchSemaphore

        switch popUpMessage.position {
        case .top:
            semaphore = topPositionSemaphore
        case .bottom:
            semaphore = bottomPositionSemaphore
        case .underNavigationBar:
            semaphore = navigationBarPositionSemaphore
        }

        DispatchQueue.global(qos: .background).async {
            _ = semaphore.wait(timeout: .distantFuture)

            DispatchQueue.main.async {
                popUpMessage.showPopUpMessage()

                DispatchQueue.main.asyncAfter(deadline: .now()
                    + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        if popUpMessage != nil {
                            self.hidePopUpMessage(popUpMessage)
                        }
                }
            }
        }
    }

    func hidePopUpMessage(_ popUpMessage: PopUpMessage) {
        hidePopUpMessage(popUpMessage, forced: false)
    }

    func hidePopUpMessage(_ popUpMessage: PopUpMessage, forced: Bool) {
        if popUpMessage.isScheduledToHide {
            return
        }

        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(hidePopUpMessage(_:)),
            object: popUpMessage
        )

        if forced {
            popUpMessage.shouldForceHide = true
            popUpMessage.hidePopUpMessage()
        } else {
            popUpMessage.isScheduledToHide = true

            let semaphore: DispatchSemaphore

            switch popUpMessage.position {
            case .top:
                semaphore = topPositionSemaphore
            case .bottom:
                semaphore = bottomPositionSemaphore
            case .underNavigationBar:
                semaphore = navigationBarPositionSemaphore
            }

            DispatchQueue.global(qos: .background).async {
                _ = semaphore.wait(timeout: .distantFuture)

                DispatchQueue.main.async {
                    popUpMessage.hidePopUpMessage()
                }
            }
        }
    }

    func popUpMessageWillShow(_ popUpMessage: PopUpMessage, inView view: UIView) {
        if !bannerViews.contains(view) {
            bannerViews.append(view)
        }

        let bannersToPush = Array(popUpMessages)

        popUpMessages.append(popUpMessage)

        for banner in bannersToPush {
            if banner.position == popUpMessage.position {
                banner.pushPopUpMessage(popUpMessage.frame.size.height, forward: true, delay:
                    popUpMessage.fadeInDuration)
            }
        }
    }

    func popUpMessageDidShow(_ popUpMessage: PopUpMessage, inView view: UIView) {
        let semaphore: DispatchSemaphore

        switch popUpMessage.position {
        case .top:
            semaphore = topPositionSemaphore
        case .bottom:
            semaphore = bottomPositionSemaphore
        case .underNavigationBar:
            semaphore = navigationBarPositionSemaphore
        }

        semaphore.signal()
    }

    func popUpMessageWillHide(_ popUpMessage: PopUpMessage, inView view: UIView) {
        let bannersInSamePosition = popUpMessages.filter() { $0.position == popUpMessage.position }
        let index = bannersInSamePosition.index(of: popUpMessage)

        if index != NSNotFound && index > 0 {
            for banner in bannersInSamePosition[0...index!] {
                banner.pushPopUpMessage(-popUpMessage.frame.size.height, forward: false, delay: 0)
            }
        }
    }

    func popUpMessageDidHide(_ popUpMessage: PopUpMessage, inView view: UIView) {
        let bannersArray = popUpMessages.filter() { $0 != popUpMessage }

        if bannersArray.count == 0 {
            bannerViews = bannerViews.filter() { $0 != view }
        }

        if !popUpMessage.shouldForceHide {
            let semaphore: DispatchSemaphore

            switch popUpMessage.position {
            case .top:
                semaphore = topPositionSemaphore
            case .bottom:
                semaphore = bottomPositionSemaphore
            case .underNavigationBar:
                semaphore = navigationBarPositionSemaphore
            }

            semaphore.signal()
        }
    }

    func hidePopUpMessages() {
        for popUpMessage in popUpMessages {
            hidePopUpMessage(popUpMessage, forced: false)
        }
    }

    func forceHideAllPopUpMessages() {
        for popUpMessage in popUpMessages {
            hidePopUpMessage(popUpMessage, forced: true)
        }
    }

    func didRotate(_ note: Notification) {
        for view in bannerViews {
            let topBanners = popUpMessages.filter() { $0.position == .top }
            var topYCoord: CGFloat = 0

            if topBanners.count > 0 {
                let firstBanner = topBanners[0]
                let nextResponder: AnyObject? = firstBanner.nextAvailableViewController(firstBanner)

                if nextResponder != nil {
                    let vc = nextResponder as! UIViewController

                    if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKind(of: UIScrollView.self)) {
                        topYCoord += vc.topLayoutGuide.length
                    }
                }
            }

            for popUpMessage in Array(topBanners.reversed()) {
                popUpMessage.updateSizeAndSubviewsAnimated(true)
                popUpMessage.updatePositionAfterRotationWithY(topYCoord, animated: true)
                topYCoord += popUpMessage.layer.bounds.size.height
            }

            let bottomBanners = popUpMessages.filter() { $0.position == .bottom }
            var bottomYCoord = view.bounds.size.height
            
            for popUpMessage in Array(bottomBanners.reversed()) {
                popUpMessage.updateSizeAndSubviewsAnimated(true)
                bottomYCoord -= popUpMessage.layer.bounds.size.height
                popUpMessage.updatePositionAfterRotationWithY(bottomYCoord, animated: true)
            }
        }
    }
}
