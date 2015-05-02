//
//  RoundProgressView.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 07.04.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit
import CoreGraphics

class RoundProgressView: UIView {
    
    /// Флаг, показывающий, приостановлена ли загрузка
    var isWaiting = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Процент
    var percent: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Основной цвет
    private let mainColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clearColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        if percent == 0 {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        let padding: CGFloat = 2
        let progressRect = CGRect(x: CGRectGetMinX(rect) + padding / 2, y: CGRectGetMinY(rect) + padding / 2,
            width: rect.size.width - padding, height: rect.size.height - padding)
        
        let progressBackgroundPath = UIBezierPath(ovalInRect: progressRect)
        UIColor(white: 0.8, alpha: 1).setStroke()
        progressBackgroundPath.lineWidth = 0.8
        progressBackgroundPath.stroke()
        
        let startAngle = CGFloat(-90 * M_PI / 180)
        let progressPath = UIBezierPath()
        progressPath.addArcWithCenter(CGPoint(x: CGRectGetMidX(progressRect), y: CGRectGetMidY(progressRect)),
            radius: CGRectGetWidth(progressRect) / 2, startAngle: startAngle,
            endAngle: (CGFloat(270 * M_PI / 180) - startAngle) * percent / 100 + startAngle, clockwise: true)
        mainColor.setStroke()
        progressPath.lineWidth = 0.8
        progressPath.lineCapStyle = kCGLineCapRound
        progressPath.stroke()
        
        if percent == 100 {
            let circlePath = UIBezierPath(ovalInRect: CGRect(x: CGRectGetMinX(rect) + rect.size.width / 4,
                y: CGRectGetMinY(rect) + rect.size.height / 4, width: rect.size.width / 2, height: rect.size.height / 2))
            mainColor.setStroke()
            circlePath.lineWidth = 0.8
            circlePath.stroke()
            
            return
        } else if isWaiting {
            drawPausePathToContext(context, rect: rect)
            
            return
        }
        
        let titleRect = CGRect(x: CGRectGetMinX(rect), y: CGRectGetMinY(rect), width: rect.size.width, height: rect.size.height)
        let title = "\(Int(percent))"
        let titleStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        titleStyle.alignment = .Center
        let titleFontAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 11)!,
            NSForegroundColorAttributeName: mainColor,
            NSParagraphStyleAttributeName: titleStyle]
        let titleHeight = title.boundingRectWithSize(CGSize(width: titleRect.width, height: titleRect.height),
            options: .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil).height
        CGContextSaveGState(context)
        CGContextClipToRect(context, titleRect)
        title.drawInRect(CGRect(x: CGRectGetMinX(titleRect),
            y: CGRectGetMinY(titleRect) + (CGRectGetHeight(titleRect) - titleHeight) / 2, width: CGRectGetWidth(titleRect),
            height: titleHeight), withAttributes: titleFontAttributes)
        CGContextRestoreGState(context)
    }
    
    private func drawPausePathToContext(context: CGContextRef, rect: CGRect) {
        CGContextTranslateCTM(context, rect.width / 4, rect.height / 4)
        CGContextScaleCTM(context, 0.5, 0.5)
        CGContextSetFillColorWithColor(context, mainColor.CGColor)
        CGContextMoveToPoint(context, rect.width / 4, rect.height / 4)
        CGContextAddLineToPoint(context, rect.width / 4, rect.height * 3 / 4)
        CGContextAddLineToPoint(context, rect.width * 2 / 5, rect.height * 3 / 4)
        CGContextAddLineToPoint(context, rect.width * 2 / 5, rect.height / 4)
        CGContextAddLineToPoint(context, rect.width / 4, rect.height / 4)
        CGContextFillPath(context)
        CGContextMoveToPoint(context, rect.width * 3 / 4, rect.height / 4)
        CGContextAddLineToPoint(context, rect.width * 3 / 4, rect.height * 3 / 4)
        CGContextAddLineToPoint(context, rect.width * 3 / 5, rect.height * 3 / 4)
        CGContextAddLineToPoint(context, rect.width * 3 / 5, rect.height / 4)
        CGContextAddLineToPoint(context, rect.width * 3 / 4, rect.height / 4)
        CGContextFillPath(context)
    }
}
