//
//  AlertBannerManager.swift
//  misisbooks
//
//  Created by Maxim Loskov on 15.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

class AlertBannerManager : NSObject, AlertBannerDelegate {
    
    var topPositionSemaphore : dispatch_semaphore_t
    var bottomPositionSemaphore : dispatch_semaphore_t
    var navBarPositionSemaphore : dispatch_semaphore_t
    var bannerViews : NSMutableArray
    var alertBanners : NSMutableArray
    
    
    override init() {
        topPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(topPositionSemaphore)
        
        bottomPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(bottomPositionSemaphore)
        
        navBarPositionSemaphore = dispatch_semaphore_create(0)
        dispatch_semaphore_signal(navBarPositionSemaphore)
        
        bannerViews = NSMutableArray()
        alertBanners = NSMutableArray()
        
        super.init()
        
        // TODO: Вместо этого использовать UIApplicationDidChangeStatusBarOrientationNotification
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didRotate:"), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    /// Возвращает экземпляр класса
    ///
    /// :returns: Экземпляр класса
    class var sharedInstance : AlertBannerManager {
        
        struct Singleton {
            static let sharedInstance = AlertBannerManager()
        }
        
        return Singleton.sharedInstance
    }
    
    func showAlertBanner(alertBanner: AlertBanner, hideAfter delay: NSTimeInterval) {
        var semaphore : dispatch_semaphore_t
        
        switch alertBanner.position {
        case .Top:
            semaphore = topPositionSemaphore
            break
        case .Bottom:
            semaphore = bottomPositionSemaphore
            break
        case .UnderNavBar:
            semaphore = navBarPositionSemaphore
            break
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue()) {
                alertBanner.showAlertBanner()
                
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.hideAlertBanner(alertBanner)
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
            
            var semaphore : dispatch_semaphore_t
            
            switch alertBanner.position {
            case .Top:
                semaphore = topPositionSemaphore
                break
            case .Bottom:
                semaphore = bottomPositionSemaphore
                break
            case .UnderNavBar:
                semaphore = navBarPositionSemaphore
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
        if !bannerViews.containsObject(view) {
            bannerViews.addObject(view)
        }
        
        let bannersToPush = Array(alertBanners)
        var bannersArray = alertBanners
        
        bannersArray.addObject(alertBanner)
        let bannersInSamePosition = bannersArray.filteredArrayUsingPredicate(NSPredicate(format: "SELF.position == %i", alertBanner.position.rawValue)!)
        
        alertBanner.showShadow = !(bannersInSamePosition.count > 1)
        
        for banner in bannersToPush {
            if (banner as AlertBanner).position == alertBanner.position {
                (banner as AlertBanner).pushAlertBanner(alertBanner.frame.size.height, forward: true, delay: alertBanner.fadeInDuration)
            }
        }
    }
    
    func alertBannerDidShow(alertBanner: AlertBanner, inView view: UIView) {
        var semaphore : dispatch_semaphore_t
        
        switch alertBanner.position {
        case .Top:
            semaphore = topPositionSemaphore
            break
        case .Bottom:
            semaphore = bottomPositionSemaphore
            break
        case .UnderNavBar:
            semaphore = navBarPositionSemaphore
            break
        }
        
        dispatch_semaphore_signal(semaphore)
    }
    
    func alertBannerWillHide(alertBanner: AlertBanner, inView view: UIView) {
        let bannersArray = alertBanners
        let bannersInSamePosition = bannersArray.filteredArrayUsingPredicate(NSPredicate(format: "SELF.position == %i", alertBanner.position.rawValue)!) as NSArray
        let index = bannersInSamePosition.indexOfObject(alertBanner)
        
        if index != NSNotFound && index > 0 {
            let bannersToPush = Array(bannersInSamePosition.subarrayWithRange(NSMakeRange(0, index))) as [AlertBanner]
            
            for banner in bannersToPush {
                banner.pushAlertBanner(-alertBanner.frame.size.height, forward: false, delay: 0.0)
            }
        } else if index == 0 {
            if bannersInSamePosition.count > 1 {
                let nextAlertBanner = bannersInSamePosition.objectAtIndex(1) as AlertBanner
                nextAlertBanner.setShowShadow(true)
            }
            
            alertBanner.setShowShadow(false)
        }
    }
    
    func alertBannerDidHide(alertBanner: AlertBanner, inView view: UIView) {
        var bannersArray = alertBanners
        bannersArray.removeObject(alertBanner)
        
        if bannersArray.count == 0 {
            bannerViews.removeObject(view)
        }
        
        if !alertBanner.shouldForceHide {
            var semaphore : dispatch_semaphore_t
            
            switch alertBanner.position {
            case .Top:
                semaphore = topPositionSemaphore
                break
            case .Bottom:
                semaphore = bottomPositionSemaphore
                break
            case .UnderNavBar:
                semaphore = navBarPositionSemaphore
                break
            }
            
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    func alertBannersInView(view: UIView) -> NSArray {
        return NSArray(array: alertBanners)
    }
    
    func hideAlertBannersInView(view: UIView) {
        for alertBanner in alertBannersInView(view) {
            hideAlertBanner(alertBanner as AlertBanner, forced: false)
        }
    }
    
    func hideAllAlertBanners() {
        for view in bannerViews {
            hideAlertBannersInView(view as UIView)
        }
    }
    
    func forceHideAllAlertBannersInView(view: UIView) {
        for alertBanner in alertBannersInView(view) {
            hideAlertBanner(alertBanner as AlertBanner, forced: true)
        }
    }
    
    func didRotate(note: NSNotification) {
        for view in bannerViews {
            let topBanners = alertBanners.filteredArrayUsingPredicate(NSPredicate(format: "SELF.position == %i", AlertBannerPosition.Top.rawValue)!) as NSArray
            var topYCoord = CGFloat(0.0)
            
            if topBanners.count > 0 {
                let firstBanner = topBanners.objectAtIndex(0) as AlertBanner
                let nextResponder: AnyObject? = firstBanner.nextAvailableViewController(firstBanner)
                if nextResponder != nil {
                    let vc = nextResponder as UIViewController
                    if !(vc.automaticallyAdjustsScrollViewInsets && vc.view.isKindOfClass(UIScrollView)) {
                        topYCoord += vc.topLayoutGuide.length
                    }
                }
            }
            
            for alertBanner in topBanners.reverseObjectEnumerator().allObjects {
                (alertBanner as AlertBanner).updateSizeAndSubviewsAnimated(true)
                (alertBanner as AlertBanner).updatePositionAfterRotationWithY(topYCoord, animated: true)
                topYCoord += alertBanner.layer.bounds.size.height
            }
            
            let bottomBanners = alertBanners.filteredArrayUsingPredicate(NSPredicate(format: "SELF.position == %i", AlertBannerPosition.Bottom.rawValue)!) as NSArray
            var bottomYCoord = view.bounds.size.height
            
            for alertBanner in bottomBanners.reverseObjectEnumerator().allObjects {
                alertBanner.updateSizeAndSubviewsAnimated(true)
                bottomYCoord -= alertBanner.layer.bounds.size.height
                alertBanner.updatePositionAfterRotationWithY(bottomYCoord, animated: true)
            }
            
            // TODO: Поворот для UIWindow
        }
    }
    
    deinit {
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
    }
}
