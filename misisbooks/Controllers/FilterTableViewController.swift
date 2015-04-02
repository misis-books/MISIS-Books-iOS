//
//  FilterTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit
import CoreGraphics

protocol FilterTableViewControllerDelegate {
    
    func filterTableViewControllerDidChangeCategory(selectedCategory: Int)
}

class FilterTableViewController : UITableViewController {
    
    /// Делегат
    var delegate : FilterTableViewControllerDelegate!
    
    /// Выбранная категория
    var selectedCategory : Int!
    
    /// Названия категорий
    let categoryNames = [
        "Все",
        "Пособия",
        "Дипломы",
        "Сборники научных трудов",
        "Монографии, научные издания",
        "Книги «МИСиС»",
        "Авторефераты диссертаций",
        "Разное"
    ]
    
    /// Цвета категорий
    let categoryColors = [
        UIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0, alpha: 1.0),
        UIColor(red: 74 / 255.0, green: 191 / 255.0, blue: 180 / 255.0, alpha: 1.0),
        UIColor(red: 253 / 255.0, green: 85 / 255.0, blue: 89 / 255.0, alpha: 1.0),
        UIColor(red: 184 / 255.0, green: 145 / 255.0, blue: 78 / 255.0, alpha: 1.0),
        UIColor(red: 179 / 255.0, green: 200 / 255.0, blue: 51 / 255.0, alpha: 1.0),
        UIColor(red: 155 / 255.0, green: 89 / 255.0, blue: 182 / 255.0, alpha: 1.0),
        UIColor(red: 255 / 255.0, green: 145 / 255.0, blue: 0 / 255.0, alpha: 1.0),
        UIColor(red: 46 / 255.0, green: 204 / 255.0, blue: 113 / 255.0, alpha: 1.0)
    ]
    
    
    init(selectedCategory: Int, delegate: FilterTableViewControllerDelegate) {
        super.init(style: .Plain)
        
        self.selectedCategory = selectedCategory
        self.delegate = delegate
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Close"),
            style: .Plain,
            target: self,
            action: Selector("closeButtonPressed")
        )
        navigationItem.setRightBarButtonItem(closeBarButtonItem, animated: false)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        tableView.tableFooterView = UIView(frame: CGRectZero)
        title = "Категории"
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Обрабатывает событие, когда нажата кнопка закрытия
    func closeButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Возвращает картинку с кругом (с добавленим отступа сверху)
    ///
    /// :param: diameter Диаметр круга
    /// :param: color Цвет заливки круга
    /// :returns: Картинка с кругом
    func getImageWithCircle(diameter: Double, color: UIColor) -> UIImage {
        let paddingTop = 2.0
        let imageSize = CGSize(width: diameter, height: diameter + paddingTop)
        let circleSize = CGSize(width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        var context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillEllipseInRect(context, CGRect(origin: CGPointMake(0.0, CGFloat(paddingTop)), size: circleSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.imageView?.image = getImageWithCircle(14.0, color: categoryColors[indexPath.row])
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
        cell.textLabel?.text = categoryNames[indexPath.row]
        cell.textLabel?.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        
        if indexPath.row == selectedCategory - 1 {
            cell.accessoryType = .Checkmark
        }
        
        return cell
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedCategory - 1, inSection: 0))
        previousCell?.accessoryType = .None
        
        let nextCell = tableView.cellForRowAtIndexPath(indexPath)
        nextCell?.accessoryType = .Checkmark
        
        delegate.filterTableViewControllerDidChangeCategory(indexPath.row + 1)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
