//
//  FilterTableViewController.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

protocol FilterTableViewControllerDelegate {
    
    func filterTableViewControllerDidChangeCategory(selectedCategory: Int)
}

class FilterTableViewController : UITableViewController {
    
    /// Делегат
    var delegate : FilterTableViewControllerDelegate!
    
    /// Выбранная категория
    var selectedCategory : Int!
    
    /// Названия категорий
    let categoryNames = ["Все",
        "Пособия",
        "Дипломы",
        "Сборники научных трудов",
        "Монографии, научные издания",
        "Книги «МИСиС»",
        "Авторефераты диссертаций",
        "Разное"]
    
    /// Цвета категорий
    let categoryColors = [UIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0, alpha: 1.0),
        UIColor(red: 74 / 255.0, green: 191 / 255.0, blue: 180 / 255.0, alpha: 1.0),
        UIColor(red: 253 / 255.0, green: 85 / 255.0, blue: 89 / 255.0, alpha: 1.0),
        UIColor(red: 184 / 255.0, green: 145 / 255.0, blue: 78 / 255.0, alpha: 1.0),
        UIColor(red: 179 / 255.0, green: 200 / 255.0, blue: 51 / 255.0, alpha: 1.0),
        UIColor(red: 155 / 255.0, green: 89 / 255.0, blue: 182 / 255.0, alpha: 1.0),
        UIColor(red: 255 / 255.0, green: 145 / 255.0, blue: 0 / 255.0, alpha: 1.0),
        UIColor(red: 46 / 255.0, green: 204 / 255.0, blue: 113 / 255.0, alpha: 1.0)]
    
    
    init(selectedCategory: Int, delegate: FilterTableViewControllerDelegate) {
        super.init(style: UITableViewStyle.Plain)
        
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
        
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "Close"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("closeButtonPressed")), animated: false)
        self.tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView(frame:CGRectZero)
        self.title = "Категории"

    }
    
    /// MARK: - Вспомогательные методы
    
    func closeButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// MARK: - Методы UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
            
            let diameter: CGFloat = 12.0
            let circleLabel = UILabel(frame: CGRectMake(15, 14, diameter, diameter))
            circleLabel.layer.backgroundColor = categoryColors[indexPath.row].CGColor
            circleLabel.layer.cornerRadius = diameter / 2.0
            cell!.contentView.addSubview(circleLabel)
            
            let categoryLabel = UILabel(frame: CGRectMake(39.0, 10.5, 0.0, 0.0))
            categoryLabel.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
            categoryLabel.text = categoryNames[indexPath.row]
            categoryLabel.textColor = UIColor(red: 58 / 255.0, green: 58 / 255.0, blue: 58 / 255.0, alpha: 1.0)
            categoryLabel.sizeToFit()
            cell!.contentView.addSubview(categoryLabel)
        }
        
        if indexPath.row == selectedCategory - 1 {
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        return cell!
    }
    
    /// MARK: - Методы UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedCategory - 1, inSection: 0))?.accessoryType
         = UITableViewCellAccessoryType.None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        delegate.filterTableViewControllerDidChangeCategory(indexPath.row + 1)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
