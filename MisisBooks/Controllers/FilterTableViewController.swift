//
//  FilterTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit
import CoreGraphics

/**
    Класс для представления контроллера фильтра
*/
class FilterTableViewController: UITableViewController {
    
    /// Цвета категорий
    private let categoryColors = [UIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0, alpha: 1),
        UIColor(red: 74 / 255.0, green: 191 / 255.0, blue: 180 / 255.0, alpha: 1),
        UIColor(red: 253 / 255.0, green: 85 / 255.0, blue: 89 / 255.0, alpha: 1),
        UIColor(red: 184 / 255.0, green: 145 / 255.0, blue: 78 / 255.0, alpha: 1),
        UIColor(red: 179 / 255.0, green: 200 / 255.0, blue: 51 / 255.0, alpha: 1),
        UIColor(red: 155 / 255.0, green: 89 / 255.0, blue: 182 / 255.0, alpha: 1),
        UIColor(red: 255 / 255.0, green: 145 / 255.0, blue: 0 / 255.0, alpha: 1),
        UIColor(red: 46 / 255.0, green: 204 / 255.0, blue: 113 / 255.0, alpha: 1)]
    
    /// Названия категорий
    private let categoryNames = ["Все", "Пособия", "Дипломы", "Сборники научных трудов", "Монографии, научные издания",
        "Книги «МИСиС»", "Авторефераты диссертаций", "Разное"]
    
    /// Идентификатор выбранной категории
    private var selectedCategoryId: Int!
    
    init(selectedCategoryId: Int) {
        super.init(style: .Plain)
        
        self.selectedCategoryId = selectedCategoryId
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close"), style: .Plain, target: self,
            action: Selector("closeButtonPressed"))
        navigationItem.setRightBarButtonItem(closeBarButtonItem, animated: false)
        
        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        title = "Категории"
    }
    
    /**
        Обрабатывает событие, когда нажата кнопка закрытия
    */
    func closeButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Внутренние методы
    
    /**
        Возвращает картинку с кругом (с добавленим отступа сверху)

        - parameter diameter: Диаметр круга
        - parameter color: Цвет заливки круга

        - returns: Картинка с кругом
    */
    private func imageWithCircle(diameter: CGFloat, color: UIColor) -> UIImage {
        let paddingTop: CGFloat = 2.0
        let imageSize = CGSizeMake(diameter, diameter + paddingTop)
        let circleSize = CGSizeMake(diameter, diameter)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillEllipseInRect(context, CGRect(origin: CGPointMake(0, paddingTop), size: circleSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.imageView?.image = imageWithCircle(14, color: categoryColors[indexPath.row])
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel?.text = categoryNames[indexPath.row]
        cell.textLabel?.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)
        
        if indexPath.row == selectedCategoryId - 1 {
            cell.accessoryType = .Checkmark
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    // MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedCategoryId - 1, inSection: 0))?.accessoryType = .None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        ControllerManager.instance.searchTableViewController.changeCategory(indexPath.row + 1)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
}
