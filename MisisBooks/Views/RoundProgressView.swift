//
//  RoundProgressView.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 07.04.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit
import CoreGraphics

class RoundProgressView: UIView {
    var isWaiting = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var percent: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private let mainColor = UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        if percent == 0 {
            return
        }

        let context = UIGraphicsGetCurrentContext()
        let padding: CGFloat = 2
        let progressRect = CGRect(x: rect.minX + padding / 2, y: rect.minY + padding / 2,
                                  width: rect.size.width - padding, height: rect.size.height - padding)

        let progressBackgroundPath = UIBezierPath(ovalIn: progressRect)
        UIColor(white: 0.8, alpha: 1).setStroke()
        progressBackgroundPath.lineWidth = 0.8
        progressBackgroundPath.stroke()

        let startAngle = CGFloat(-90 * M_PI / 180)
        let progressPath = UIBezierPath()
        progressPath.addArc(
            withCenter: CGPoint(x: progressRect.midX, y: progressRect.midY),
            radius: progressRect.width / 2,
            startAngle: startAngle,
            endAngle: (CGFloat(270 * M_PI / 180) - startAngle) * percent / 100 + startAngle,
            clockwise: true
        )
        mainColor.setStroke()
        progressPath.lineWidth = 0.8
        progressPath.lineCapStyle = .round
        progressPath.stroke()

        if percent == 100 {
            let circlePath = UIBezierPath(
                ovalIn: CGRect(x: rect.minX + rect.size.width / 4,
                               y: rect.minY + rect.size.height / 4,
                               width: rect.size.width / 2,
                               height: rect.size.height / 2)
            )
            mainColor.setStroke()
            circlePath.lineWidth = 0.8
            circlePath.stroke()

            return
        } else if isWaiting {
            drawPausePath(toContext: context!, rect: rect)

            return
        }

        let titleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.size.width, height: rect.size.height)
        let title = "\(Int(percent))"
        let titleStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        titleStyle.alignment = .center
        let titleFontAttributes = [
            NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 11)!,
            NSForegroundColorAttributeName: mainColor,
            NSParagraphStyleAttributeName: titleStyle
        ]
        let titleHeight = title.boundingRect(with: CGSize(width: titleRect.width, height: titleRect.height),
                                             options: .usesLineFragmentOrigin, attributes: titleFontAttributes,
                                             context: nil).height
        context?.saveGState()
        context?.clip(to: titleRect)
        title.draw(
            in: CGRect(x: titleRect.minX,
                       y: titleRect.minY + (titleRect.height - titleHeight) / 2,
                       width: titleRect.width,
                       height: titleHeight),
            withAttributes: titleFontAttributes
        )
        context?.restoreGState()
    }

    private func drawPausePath(toContext context: CGContext, rect: CGRect) {
        context.translateBy(x: rect.width / 4, y: rect.height / 4)
        context.scaleBy(x: 0.5, y: 0.5)
        context.setFillColor(mainColor.cgColor)
        context.move(to: CGPoint(x: rect.width / 4, y: rect.height / 4))
        context.addLine(to: CGPoint(x: rect.width / 4, y: rect.height * 3 / 4))
        context.addLine(to: CGPoint(x: rect.width * 2 / 5, y: rect.height * 3 / 4))
        context.addLine(to: CGPoint(x: rect.width * 2 / 5, y: rect.height / 4))
        context.addLine(to: CGPoint(x: rect.width / 4, y: rect.height / 4))
        context.fillPath()
        context.move(to: CGPoint(x: rect.width * 3 / 4, y: rect.height / 4))
        context.addLine(to: CGPoint(x: rect.width * 3 / 4, y: rect.height * 3 / 4))
        context.addLine(to: CGPoint(x: rect.width * 3 / 5, y: rect.height * 3 / 4))
        context.addLine(to: CGPoint(x: rect.width * 3 / 5, y: rect.height / 4))
        context.addLine(to: CGPoint(x: rect.width * 3 / 4, y: rect.height / 4))
        context.fillPath()
    }
}
