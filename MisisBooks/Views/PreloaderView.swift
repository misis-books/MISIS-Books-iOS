//
//  PreloaderView.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 08.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

enum PreloaderViewState {
    case normal
    case pulling
    case loading
}

protocol PreloaderViewDelegate {
    func preloaderViewDataSourceIsLoading() -> Bool!
    func preloaderViewDidTriggerRefresh()
}

class PreloaderView: UIView {
    var label: UILabel!
    private var delegate: PreloaderViewDelegate!
    private var savedText: String?
    private var loadState: PreloaderViewState?
    private var loadingIndicator: UIActivityIndicatorView!
    private var arrowImage: CALayer!

    init(text: String, delegate: PreloaderViewDelegate) {
        self.delegate = delegate

        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))

        let contentColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont(name: "HelveticaNeue-Light", size: 13)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.shadowColor = .white
        label.shadowOffset = CGSize(width: 0, height: -1)
        label.text = text
        label.textAlignment = .center
        label.textColor = contentColor
        addSubview(label)

        arrowImage = CALayer()
        arrowImage.frame = CGRect(x: 10, y: 6, width: 24, height: 20)
        arrowImage.mask = {
            let mask = CALayer()
            mask.frame = self.arrowImage.bounds
            mask.contents = UIImage(named: "Arrow")?.cgImage
            mask.contentsGravity = kCAGravityResizeAspect
            mask.contentsScale = UIScreen.main.scale

            return mask
            }()
        arrowImage.backgroundColor = contentColor.cgColor
        layer.addSublayer(arrowImage)

        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.frame = CGRect(x: 12, y: 8, width: 22, height: 18)
        addSubview(loadingIndicator)

        loadState = .normal
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: UIScreen.main.bounds.size.width, height: 44)
        label.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 34)
    }

    func preloaderViewScrollViewDidScroll(_ scrollView: UIScrollView) {
        if loadState != .loading && scrollView.isDragging {
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64
            let loading = delegate.preloaderViewDataSourceIsLoading()

            if loadState == .pulling && offset < boundery && offset > scrollView.contentSize.height && !loading! {
                setState(.normal)
            } else if loadState == .normal && offset > boundery && !loading! {
                setState(.pulling)
            }
        }
    }

    func preloaderViewScrollViewDidEndDragging(_ scrollView: UIScrollView) {
        if loadState != .loading {
            let offset = scrollView.contentOffset.y + scrollView.frame.size.height
            let boundery = scrollView.contentSize.height + 64
            let loading = delegate.preloaderViewDataSourceIsLoading()

            if offset >= boundery && !loading! {
                delegate.preloaderViewDidTriggerRefresh()
                setState(.loading)
            }
        }
    }

    func preloaderViewDataSourceDidFinishedLoading() {
        setState(.normal)
    }

    private func setState(_ state: PreloaderViewState) {
        label.layer.add({
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

            return animation
            }(), forKey: "animation")

        switch state {
        case .normal:
            label.text = savedText
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()

            if loadState == .pulling {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.2)
                arrowImage.transform = CATransform3DIdentity
                CATransaction.commit()
            }

            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage.isHidden = false
            arrowImage.transform = CATransform3DIdentity
            CATransaction.commit()
        case .pulling:
            savedText = label.text
            label.text = "Отпустите для продолжения"
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()

            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            arrowImage.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 0, 1)
            CATransaction.commit()
        case .loading:
            label.text = "Загрузка результатов..."
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()

            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            arrowImage.isHidden = true
            CATransaction.commit()
        }
        
        loadState = state
    }
}
