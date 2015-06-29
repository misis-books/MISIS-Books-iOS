//
//  PreloaderView.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 08.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

enum PreloaderViewState {
    case Normal, Pulling, Loading
}

protocol PreloaderViewDelegate {
    func preloaderViewDataSourceIsLoading() -> Bool!
    func preloaderViewDidTriggerRefresh()
}

/**
    Класс для представления вида-подгрузчика
*/
class PreloaderView: UIView {
    
    /// Делегат
    private var delegate: PreloaderViewDelegate!
    
    /// Текстовое поле
    var label: UILabel!
    
    /// Сохраненный текст
    private var savedText: String?
    
    /// Состояние загрузки
    private var loadState: PreloaderViewState?
    
    /// Индикатор загрузки
    private var loadingIndicator: UIActivityIndicatorView!
    
    /// Изображение стрелки
    private var arrowImage: CALayer!
    
    init(text: String, delegate: PreloaderViewDelegate) {
        self.delegate = delegate
        
        super.init(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
        
        let contentColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        
        label = UILabel()
        label.backgroundColor = .clearColor()
        label.font = UIFont(name: "HelveticaNeue-Light", size: 13)
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.shadowColor = .whiteColor()
        label.shadowOffset = CGSizeMake(0, -1)
        label.text = text
        label.textAlignment = .Center
        label.textColor = contentColor
        addSubview(label)
        
        arrowImage = CALayer()
        arrowImage.frame = CGRectMake(10, 6, 24, 20)
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
        loadingIndicator.frame = CGRectMake(12, 8, 22, 18)
        addSubview(loadingIndicator)
        
        loadState = .Normal
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frame = CGRectMake(frame.origin.x, frame.origin.y, UIScreen.mainScreen().bounds.size.width, 44)
        label.frame = CGRectMake(0, 0, frame.size.width, 34)
    }
    
    func preloaderViewScrollViewDidScroll(scrollView: UIScrollView) {
        if loadState != .Loading && scrollView.dragging {
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64
            let loading = delegate.preloaderViewDataSourceIsLoading()
            
            if loadState == .Pulling && offset < boundery && offset > scrollView.contentSize.height && !loading {
                setLoadState(.Normal)
            } else if loadState == .Normal && offset > boundery && !loading {
                setLoadState(.Pulling)
            }
        }
    }
    
    func preloaderViewScrollViewDidEndDragging(scrollView: UIScrollView) {
        if loadState != .Loading {
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64
            let loading = delegate.preloaderViewDataSourceIsLoading()
            
            if offset >= boundery && !loading {
                delegate.preloaderViewDidTriggerRefresh()
                setLoadState(.Loading)
            }
        }
    }
    
    func preloaderViewDataSourceDidFinishedLoading() {
        setLoadState(.Normal)
    }
    
    private func setLoadState(state: PreloaderViewState) {
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
        case .Pulling:
            savedText = label.text
            label.text = "Отпустите для продолжения"
            loadingIndicator.hidden = true
            loadingIndicator.stopAnimating()
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            arrowImage.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 0, 1)
            CATransaction.commit()
        case .Loading:
            label.text = "Загрузка результатов..."
            loadingIndicator.hidden = false
            loadingIndicator.startAnimating()
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage.hidden = true
            CATransaction.commit()
        }
        
        loadState = state
    }
}
