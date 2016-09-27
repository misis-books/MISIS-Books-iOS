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
        cell.imageView?.image = getCircle(withDiameter: 14, color: Constants.Categories.colors[indexPath.row])
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        cell.textLabel?.text = Constants.Categories.names[indexPath.row]
        cell.textLabel?.textColor = UIColor(red: 53 / 255.0, green: 57 / 255.0, blue: 66 / 255.0, alpha: 1)

        if indexPath.row == selectedCategoryId - 1 {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.Categories.names.count
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
