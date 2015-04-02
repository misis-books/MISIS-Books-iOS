//
//  PreloaderView.swift
//  misisbooks
//
//  Created by Maxim Loskov on 08.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

enum PreloaderViewState {
    
    case Normal
    case Pulling
    case Loading
}

protocol PreloaderViewDelegate {
    
    func preloaderViewDataSourceIsLoading() -> Bool!
    func preloaderViewDidTriggerRefresh()
}

/// Класс для представления подгрузчика
class PreloaderView : UIView {
    
    /// Делегат
    var delegate : PreloaderViewDelegate!
    
    /// Текстовое поле
    var label : UILabel!
    
    /// Сохраненный текст
    private var savedText : String?
    
    /// Состояние загрузки
    private var loadState : PreloaderViewState?
    
    /// Индикатор загрузки
    private var loadingIndicator : UIActivityIndicatorView!
    
    /// Изображение стрелки
    private var arrowImage : CALayer!
    
    
    init(text: String, delegate: PreloaderViewDelegate) {
        self.delegate = delegate
        
        super.init(frame: CGRectMake(0.0, 0.0, UIScreen.mainScreen().bounds.size.width, 44.0))
        
        let contentColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        
        label = UILabel(frame: CGRectMake(0.0, 0.0, frame.size.width, 34.0))
        label.backgroundColor = UIColor.clearColor()
        label.font = UIFont(name: "HelveticaNeue-Light", size: 13.0)
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.shadowColor = UIColor.whiteColor()
        label.shadowOffset = CGSizeMake(0.0, -1.0)
        label.text = text
        label.textAlignment = .Center
        label.textColor = contentColor
        addSubview(label)
        
        arrowImage = CALayer()
        arrowImage.frame = CGRectMake(10.0, 6.0, 24.0, 20.0)
        arrowImage.mask = {
            let mask = CALayer()
            mask.frame = self.arrowImage.bounds
            mask.contents = UIImage(named: "Arrow")?.CGImage
            mask.contentsGravity = kCAGravityResizeAspect
            mask.contentsScale = UIScreen.mainScreen().scale
            
            return mask
            }()
        arrowImage.backgroundColor = contentColor.CGColor
        layer.addSublayer(arrowImage)
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingIndicator.frame = CGRectMake(12.0, 8.0, 22.0, 18.0)
        addSubview(loadingIndicator)
        
        loadState = .Normal
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setLoadState(state: PreloaderViewState) {
        label.layer.addAnimation({
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            
            return animation
            }(), forKey: "animation")
        
        switch state {
        case .Normal:
            label.text = savedText
            loadingIndicator.hidden = true
            loadingIndicator.stopAnimating()
            
            if loadState == .Pulling {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.2)
                arrowImage.transform = CATransform3DIdentity
                CATransaction.commit()
            }
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage.hidden = false
            arrowImage.transform = CATransform3DIdentity
            CATransaction.commit()
            break
        case .Pulling:
            savedText = label.text
            label.text = "Отпустите для продолжения"
            loadingIndicator.hidden = true
            loadingIndicator.stopAnimating()
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            arrowImage.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0.0, 0.0, 1.0)
            CATransaction.commit()
            break
        case .Loading:
            label.text = "Загрузка результатов..."
            loadingIndicator.hidden = false
            loadingIndicator.startAnimating()
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage.hidden = true
            CATransaction.commit()
            break
        }
        
        loadState = state
    }
    
    func preloaderViewScrollViewDidScroll(scrollView: UIScrollView) {
        if loadState != .Loading && scrollView.dragging {
            var loading = delegate.preloaderViewDataSourceIsLoading()
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64.0
            
            if loadState == .Pulling && offset < boundery && offset > scrollView.contentSize.height && !loading {
                setLoadState(.Normal)
            } else if loadState == .Normal && offset > boundery && !loading {
                setLoadState(PreloaderViewState.Pulling)
            }
        }
    }
    
    func preloaderViewScrollViewDidEndDragging(scrollView: UIScrollView) {
        if loadState != .Loading {
            var loading = delegate.preloaderViewDataSourceIsLoading()
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64.0
            
            if offset >= boundery && !loading {
                delegate.preloaderViewDidTriggerRefresh()
                setLoadState(.Loading)
            }
        }
    }
    
    func preloaderViewDataSourceDidFinishedLoading() {
        setLoadState(PreloaderViewState.Normal)
    }
}
