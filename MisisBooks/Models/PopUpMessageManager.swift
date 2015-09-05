//
//  PopUpMessageManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 29.06.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для управления всплывающими сообщениями
*/
class PopUpMessageManager: NSObject, PopUpMessageDelegate {

    /// Всплывающие сообщения
    private var popUpBanners: [PopUpMessage]

    /// Виды для всплывающих сообщений
    private var bannerViews: [UIView]

    /// Семафоры
    private let bottomPositionSemaphore: dispatch_semaphore_t
    private let topPositionSemaphore: dispatch_semaphore_t
    private let navigationBarPositionSemaphore: dispatch_semaphore_t

    /**
        Возвращает экземпляр класса

        - returns: Экземпляр класса
    */
    class var instance: PopUpMessageManager {

        struct Singleton {
            static let instance = PopUpMessageManager()
        }

        return Singleton.instance
    }

    override init() {
        topPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(topPositionSemaphore)

        bottomPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(bottomPositionSemaphore)

        navigationBarPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(navigationBarPositionSemaphore)

        bannerViews = [UIView]()
        popUpBanners = [PopUpMessage]()

        super.init()

        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRotate:",
            name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    deinit {
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
    }

    /**
        Показывает всплывающее сообщение на определенное время

        - parameter popUpMessage: Всплывающее сообщение
        - parameter delay: Время, через которое нужно скрыть всплывающее сообщение
    */
    func showPopUpMessage(popUpMessage: PopUpMessage!, hideAfter delay: NSTimeInterval) {
        let semaphore: dispatch_semaphore_t

        switch popUpMessage.position {
        case .Top:
            semaphore = topPositionSemaphore
        case .Bottom:
            semaphore = bottomPositionSemaphore
        case .UnderNavigationBar:
            semaphore = navigationBarPositionSemaphore
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

            dispatch_async(dispatch_get_main_queue()) {
                popUpMessage.showPopUpMessage()

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    if popUpMessage != nil {
                        self.hidePopUpMessage(popUpMessage)
                    }
                }
            }
        }
    }

    /**
        Скрывает всплывающее сообщение

        - parameter popUpMessage: Всплывающее сообщение
    */
    func hidePopUpMessage(popUpMessage: PopUpMessage) {
        hidePopUpMessage(popUpMessage, forced: false)
    }

    /**
        Скрывает всплывающее сообщение с настраиваемой принудительностью скрытия

        - parameter popUpMessage: Всплывающее сообщение
        - parameter forced: Флаг принудительности скрытия
    */
    func hidePopUpMessage(popUpMessage: PopUpMessage, forced: Bool) {
        if popUpMessage.isScheduledToHide {
            return
        }

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "hidePopUpMessage:", object: popUpMessage)

        if forced {
            popUpMessage.shouldForceHide = true
            popUpMessage.hidePopUpMessage()
        } else {
            popUpMessage.isScheduledToHide = true

            let semaphore: dispatch_semaphore_t

            switch popUpMessage.position {
            case .Top:
                semaphore = topPositionSemaphore
            case .Bottom:
                semaphore = bottomPositionSemaphore
            case .UnderNavigationBar:
                semaphore = navigationBarPositionSemaphore
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

                dispatch_async(dispatch_get_main_queue()) {
                    popUpMessage.hidePopUpMessage()
                }
            }
        }
    }

    /**
        Задает вид, в котором необходимо показать всплывающее сообщение

        - parameter popUpMessage: Всплывающее сообщение
        - parameter view: Вид, в котором необходимо показать всплывающее сообщение
    */
    func popUpMessageWillShow(popUpMessage: PopUpMessage, inView view: UIView) {
        if !bannerViews.contains(view) {
            bannerViews.append(view)
        }

        let bannersToPush = Array(popUpBanners)

        popUpBanners.append(popUpMessage)

        for banner in bannersToPush {
            if banner.position == popUpMessage.position {
                banner.pushPopUpMessage(popUpMessage.frame.size.height, forward: true, delay: popUpMessage.fadeInDuration)
            }
        }
    }

    func popUpMessageDidShow(popUpMessage: PopUpMessage, inView view: UIView) {
        let semaphore: dispatch_semaphore_t

        switch popUpMessage.position {
        case .Top:
            semaphore = topPositionSemaphore
        case .Bottom:
            semaphore = bottomPositionSemaphore
        case .UnderNavigationBar:
            semaphore = navigationBarPositionSemaphore
        }

        dispatch_semaphore_signal(semaphore)
    }

    func popUpMessageWillHide(popUpMessage: PopUpMessage, inView view: UIView) {
        let bannersInSamePosition = popUpBanners.filter() { $0.position == popUpMessage.position }
        let index = bannersInSamePosition.indexOf(popUpMessage)

        if index != NSNotFound && index > 0 {
            for banner in bannersInSamePosition[0...index!] {
                banner.pushPopUpMessage(-popUpMessage.frame.size.height, forward: false, delay: 0)
            }
        }
    }

    func popUpMessageDidHide(popUpMessage: PopUpMessage, inView view: UIView) {
        let bannersArray = popUpBanners.filter() { $0 != popUpMessage }

        if bannersArray.count == 0 {
            bannerViews = bannerViews.filter() { $0 != view }
        }

        if !popUpMessage.shouldForceHide {
            let semaphore: dispatch_semaphore_t

            switch popUpMessage.position {
            case .Top:
                semaphore = topPositionSemaphore
            case .Bottom:
                semaphore = bottomPositionSemaphore
            case .UnderNavigationBar:
                semaphore = navigationBarPositionSemaphore
            }

            dispatch_semaphore_signal(semaphore)
        }
    }

    func popUpMessagesInView(view: UIView) -> [PopUpMessage] {
        return popUpBanners
    }

    func hidePopUpMessagesInView(view: UIView) {
        for popUpMessage in popUpMessagesInView(view) {
            hidePopUpMessage(popUpMessage, forced: false)
        }
    }

    func hideAllPopUpMessages() {
        for view in bannerViews {
            hidePopUpMessagesInView(view)
        }
    }

    func forceHideAllPopUpMessagesInView(view: UIView) {
        for popUpMessage in popUpMessagesInView(view) {
            hidePopUpMessage(popUpMessage, forced: true)
        }
    }

    func didRotate(note: NSNotification) {
        for view in bannerViews {
            let topBanners = popUpBanners.filter() { $0.position == .Top }
            var topYCoord: CGFloat = 0

            if topBanners.count > 0 {
                let firstBanner = topBanners[0]
                let nextResponder: AnyObject? = firstBanner.nextAvailableViewController(firstBanner)

                if nextResponder != nil {
                    let vc = nextResponder as! UIViewController

                    if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKindOfClass(UIScrollView)) {
                        topYCoord += vc.topLayoutGuide.length
                    }
                }
            }

            for popUpMessage in Array(topBanners.reverse()) {
                popUpMessage.updateSizeAndSubviewsAnimated(true)
                popUpMessage.updatePositionAfterRotationWithY(topYCoord, animated: true)
                topYCoord += popUpMessage.layer.bounds.size.height
            }

            let bottomBanners = popUpBanners.filter() { $0.position == .Bottom }
            var bottomYCoord = view.bounds.size.height

            for popUpMessage in Array(bottomBanners.reverse()) {
                popUpMessage.updateSizeAndSubviewsAnimated(true)
                bottomYCoord -= popUpMessage.layer.bounds.size.height
                popUpMessage.updatePositionAfterRotationWithY(bottomYCoord, animated: true)
            }
        }
    }
}
