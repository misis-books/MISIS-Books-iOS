//
//  FilterTableViewController.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit
import CoreGraphics

class FilterTableViewController: UITableViewController {

    private let categoryColors = [
        UIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0, alpha: 1),
        UIColor(red: 74 / 255.0, green: 191 / 255.0, blue: 180 / 255.0, alpha: 1),
        UIColor(red: 253 / 255.0, green: 85 / 255.0, blue: 89 / 255.0, alpha: 1),
        UIColor(red: 184 / 255.0, green: 145 / 255.0, blue: 78 / 255.0, alpha: 1),
        UIColor(red: 179 / 255.0, green: 200 / 255.0, blue: 51 / 255.0, alpha: 1),
        UIColor(red: 155 / 255.0, green: 89 / 255.0, blue: 182 / 255.0, alpha: 1),
        UIColor(red: 1, green: 145 / 255.0, blue: 0, alpha: 1),
        UIColor(red: 46 / 255.0, green: 204 / 255.0, blue: 113 / 255.0, alpha: 1),
        UIColor(red: 69 / 255.0, green: 131 / 255.0, blue: 136 / 255.0, alpha: 1),
        UIColor(red: 136 / 255.0, green: 69 / 255.0, blue: 69 / 255.0, alpha: 1),
        UIColor(red: 96 / 255.0, green: 160 / 255.0, blue: 223 / 255.0, alpha: 1)
    ]
    private let categoryNames = [
        "Все",
        "Пособия",
        "Дипломы",
        "Сборники научных трудов",
        "Монографии, научные издания",
        "Книги «МИСиС»",
        "Авторефераты диссертаций",
        "Разное",
        "Журналы",
        "Документы филиалов «МИСиС»",
        "УМКД"
    ]

    var selectedCategoryId: Int!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Close"),
            style: .plain,
            target: self,
            action: #selector(closeButtonPressed)
        )

        tableView.separatorColor = UIColor(red: 178 / 255.0, green: 178 / 255.0, blue: 178 / 255.0, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        title = "Категории"
    }

    func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

    private func getCircle(withDiameter diameter: CGFloat, color: UIColor) -> UIImage {
        let paddingTop: CGFloat = 2.0
        let imageSize = CGSize(width: diameter, height: diameter + paddingTop)
        let circleSize = CGSize(width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: CGRect(origin: CGPoint(x: 0, y: paddingTop), size: circleSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }

    // MARK: - Методы UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.imageView?.image = getCircle(withDiameter: 14, color: categoryColors[indexPath.row])
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel?.text = categoryNames[indexPath.row]
        cell.textLabel?.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        if indexPath.row == selectedCategoryId - 1 {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }

    // MARK: - Методы UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: IndexPath(row: selectedCategoryId - 1, section: 0))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        ControllerManager.instance.searchTableViewController.changeCategory(indexPath.row + 1)
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

}
