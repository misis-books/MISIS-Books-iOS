//
//  AlertBannerManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 15.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class AlertBannerManager: NSObject, AlertBannerDelegate {
    
    /// Баннеры
    private var alertBanners: [AlertBanner]
    
    /// Виды для баннеров
    private var bannerViews: [UIView]
    
    /// Семафоры
    private let bottomPositionSemaphore: dispatch_semaphore_t
    private let topPositionSemaphore: dispatch_semaphore_t
    private let navigationBarPositionSemaphore: dispatch_semaphore_t
    
    /// Возвращает экземпляр класса
    ///
    /// :returns: Экземпляр класса
    class var instance: AlertBannerManager {
        
        struct Singleton {
            
            static let instance = AlertBannerManager()
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
        alertBanners = [AlertBanner]()
        
        super.init()
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didRotate:"), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    deinit {
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
    }
    
    func showAlertBanner(alertBanner: AlertBanner!, hideAfter delay: NSTimeInterval) {
        let semaphore: dispatch_semaphore_t
        
        switch alertBanner.position {
        case .Top:
            semaphore = topPositionSemaphore
            break
        case .Bottom:
            semaphore = bottomPositionSemaphore
            break
        case .UnderNavigationBar:
            semaphore = navigationBarPositionSemaphore
            break
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            
            dispatch_async(dispatch_get_main_queue()) {
                alertBanner.showAlertBanner()
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    if alertBanner != nil {
                        self.hideAlertBanner(alertBanner)
                    }
                }
            }
        }
    }
    
    func hideAlertBanner(alertBanner: AlertBanner) {
        hideAlertBanner(alertBanner, forced: false)
    }
    
    func hideAlertBanner(alertBanner: AlertBanner, forced: Bool) {
        if alertBanner.isScheduledToHide {
            return
        }
        
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: Selector("hideAlertBanner:"), object: alertBanner)
        
        if forced {
            alertBanner.shouldForceHide = true
            alertBanner.hideAlertBanner()
        } else {
            alertBanner.isScheduledToHide = true
            
            let semaphore: dispatch_semaphore_t
            
            switch alertBanner.position {
            case .Top:
                semaphore = topPositionSemaphore
                break
            case .Bottom:
                semaphore = bottomPositionSemaphore
                break
            case .UnderNavigationBar:
                semaphore = navigationBarPositionSemaphore
                break
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                
                dispatch_async(dispatch_get_main_queue()) {
                    alertBanner.hideAlertBanner()
                }
            }
        }
    }
    
    func alertBannerWillShow(alertBanner: AlertBanner, inView view: UIView) {
        if !contains(bannerViews, view) {
            bannerViews.append(view)
        }
        
        let bannersToPush = Array(alertBanners)
        
        alertBanners.append(alertBanner)
        
        for banner in bannersToPush {
            if banner.position == alertBanner.position {
                banner.pushAlertBanner(alertBanner.frame.size.height, forward: true, delay: alertBanner.fadeInDuration)
            }
        }
    }
    
    func alertBannerDidShow(alertBanner: AlertBanner, inView view: UIView) {
        let semaphore: dispatch_semaphore_t
        
        switch alertBanner.position {
        case .Top:
            semaphore = topPositionSemaphore
            break
        case .Bottom:
            semaphore = bottomPositionSemaphore
            break
        case .UnderNavigationBar:
            semaphore = navigationBarPositionSemaphore
            break
        }
        
        dispatch_semaphore_signal(semaphore)
    }
    
    func alertBannerWillHide(alertBanner: AlertBanner, inView view: UIView) {
        let bannersInSamePosition = alertBanners.filter() { $0.position == alertBanner.position }
        let index = find(bannersInSamePosition, alertBanner)
        
        if index != NSNotFound && index > 0 {
            for banner in bannersInSamePosition[0...index!] {
                banner.pushAlertBanner(-alertBanner.frame.size.height, forward: false, delay: 0)
            }
        }
    }
    
    func alertBannerDidHide(alertBanner: AlertBanner, inView view: UIView) {
        let bannersArray = alertBanners.filter() { $0 != alertBanner }
        
        if bannersArray.count == 0 {
            bannerViews = bannerViews.filter() { $0 != view }
        }
        
        if !alertBanner.shouldForceHide {
            let semaphore: dispatch_semaphore_t
            
            switch alertBanner.position {
            case .Top:
                semaphore = topPositionSemaphore
                break
            case .Bottom:
                semaphore = bottomPositionSemaphore
                break
            case .UnderNavigationBar:
                semaphore = navigationBarPositionSemaphore
                break
            }
            
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    func alertBannersInView(view: UIView) -> [AlertBanner] {
        return alertBanners
    }
    
    func hideAlertBannersInView(view: UIView) {
        for alertBanner in alertBannersInView(view) {
            hideAlertBanner(alertBanner, forced: false)
        }
    }
    
    func hideAllAlertBanners() {
        for view in bannerViews {
            hideAlertBannersInView(view)
        }
    }
    
    func forceHideAllAlertBannersInView(view: UIView) {
        for alertBanner in alertBannersInView(view) {
            hideAlertBanner(alertBanner, forced: true)
        }
    }
    
    func didRotate(note: NSNotification) {
        for view in bannerViews {
            let topBanners = alertBanners.filter() { $0.position == .Top }
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
            
            for alertBanner in reverse(topBanners) {
                alertBanner.updateSizeAndSubviewsAnimated(true)
                alertBanner.updatePositionAfterRotationWithY(topYCoord, animated: true)
                topYCoord += alertBanner.layer.bounds.size.height
            }
            
            let bottomBanners = alertBanners.filter() { $0.position == .Bottom }
            var bottomYCoord = view.bounds.size.height
            
            for alertBanner in reverse(bottomBanners) {
                alertBanner.updateSizeAndSubviewsAnimated(true)
                bottomYCoord -= alertBanner.layer.bounds.size.height
                alertBanner.updatePositionAfterRotationWithY(bottomYCoord, animated: true)
            }
        }
    }
}
