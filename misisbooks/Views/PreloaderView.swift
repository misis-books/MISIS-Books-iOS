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

/// Класс для представления вида подгрузчика
class PreloaderView : UIView {
    
    /// Делегат
    var delegate : PreloaderViewDelegate!
    
    /// Текстовое поле
    var textLabel : UILabel!
    
    /// Индикатор загрузки
    var loadingIndicator : UIActivityIndicatorView!
    
    /// Сохраненный текст
    var savedText : String?
    
    /// Состояние загрузки
    private var loadState : PreloaderViewState?
    
    /// Изображение стрелки
    private var arrowImage : CALayer!
    
    
    override init(frame: CGRect) {
        super.init(frame: CGRectMake(0.0, 0.0, frame.size.width, 44.0))
        
        textLabel = UILabel(frame: CGRectMake(0.0, 0.0, frame.size.width, 34.0))
        textLabel.backgroundColor = UIColor.clearColor()
        textLabel.font = UIFont(name: "HelveticaNeue-Light", size: 13.0)
        textLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        textLabel.numberOfLines = 0
        textLabel.shadowColor = UIColor.whiteColor()
        textLabel.shadowOffset = CGSizeMake(0.0, -1.0)
        textLabel.textAlignment = NSTextAlignment.Center
        textLabel.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        self.addSubview(textLabel)
        
        arrowImage = CALayer()
        arrowImage.frame = CGRectMake(10.0, 6.0, 24.0, 20.0)
        arrowImage.contents = UIImage(named: "Arrow")?.CGImage
        arrowImage.contentsGravity = kCAGravityResizeAspect
        arrowImage.contentsScale = UIScreen.mainScreen().scale
        self.layer.addSublayer(arrowImage)
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        loadingIndicator.frame = CGRectMake(12.0, 8.0, 22.0, 18.0)
        self.addSubview(loadingIndicator)
        
        loadState = PreloaderViewState.Normal
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setLoadState(state: PreloaderViewState) {
        if state == PreloaderViewState.Normal {
            textLabel?.text = savedText
            loadingIndicator?.hidden = true
            loadingIndicator?.stopAnimating()
            
            if loadState == PreloaderViewState.Pulling {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.18)
                arrowImage?.transform = CATransform3DIdentity
                CATransaction.commit()
            }
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage?.hidden = false
            arrowImage?.transform = CATransform3DIdentity
            CATransaction.commit()
        } else if state == PreloaderViewState.Pulling {
            savedText = textLabel?.text
            textLabel?.text = "Отпустите для продолжения"
            loadingIndicator?.hidden = true
            loadingIndicator?.stopAnimating()
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            arrowImage?.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0.0, 0.0, 1.0)
            CATransaction.commit()
        } else if state == PreloaderViewState.Loading {
            textLabel?.text = "Загрузка результатов..."
            loadingIndicator?.hidden = false
            loadingIndicator?.startAnimating()
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage?.hidden = true
            CATransaction.commit()
        }
        
        loadState = state
    }
    
    func preloaderViewScrollViewDidScroll(scrollView: UIScrollView) {
        if loadState != PreloaderViewState.Loading && scrollView.dragging {
            var loading = delegate.preloaderViewDataSourceIsLoading()
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64.0
            
            if loadState == PreloaderViewState.Pulling && offset < boundery && offset > scrollView.contentSize.height && !loading {
                setLoadState(PreloaderViewState.Normal)
            } else if loadState == PreloaderViewState.Normal && offset > boundery && !loading {
                setLoadState(PreloaderViewState.Pulling)
            }
        }
    }
    
    func preloaderViewScrollViewDidEndDragging(scrollView: UIScrollView) {
        if loadState != PreloaderViewState.Loading {
            var loading = delegate.preloaderViewDataSourceIsLoading()
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64.0
            
            if offset >= boundery && !loading {
                delegate.preloaderViewDidTriggerRefresh()
                setLoadState(PreloaderViewState.Loading)
            }
        }
    }
    
    func preloaderViewDataSourceDidFinishedLoading() {
        setLoadState(PreloaderViewState.Normal)
    }
}