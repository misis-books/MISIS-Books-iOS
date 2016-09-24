//
//  CustomTableViewCell.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    var book: Book!
    var nameLabel: UILabel!
    var authorsLabel: UILabel!
    var categoryLabel: CustomLabel!
    var roundProgressView: RoundProgressView!
    var starImage: UIImageView!

    class var reuseId: String {
        return "cell"
    }

    init(book: Book, query: String!) {
        super.init(style: .default, reuseIdentifier: CustomTableViewCell.reuseId)

        configureWithBook(book, query: query)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let nameLabelSize = CustomTableViewCell.getLabelSize(withText: nameLabel.text!, font: nameLabel.font)
        let authorsLabelSize = CustomTableViewCell.getLabelSize(withText: authorsLabel.text!, font: authorsLabel.font)
        let categoryLabelSize = CustomTableViewCell.getLabelSize(withText: categoryLabel.text!, font: categoryLabel.font)

        nameLabel.frame = CGRect(x: 15, y: 8.5, width: nameLabelSize.width, height: nameLabelSize.height)
        authorsLabel.frame = CGRect(x: 15, y: nameLabelSize.height + 11, width: authorsLabelSize.width, height: authorsLabelSize.height)
        categoryLabel.frame = CGRect(x: 15, y: nameLabelSize.height + authorsLabelSize.height + 16.5, width: categoryLabelSize.width + 10,
            height: categoryLabelSize.height + 6)
        roundProgressView.frame = CGRect(x: frame.width - 70, y: nameLabelSize.height + authorsLabelSize.height + 16.5, width: 20, height: 20)
        starImage.frame = CGRect(x: frame.width - 35, y: nameLabelSize.height + authorsLabelSize.height + 16.5, width: 20, height: 20)
    }

    class func getCategoryName(byId categoryId: Int) -> String {
        let categoryNames = ["Все", "Пособия", "Дипломы", "Сборники научных трудов", "Монографии, научные издания",
            "Книги «МИСиС»", "Авторефераты диссертаций", "Разное", "Журналы", "Документы филиалов «МИСиС»", "УМКД"]

        return categoryNames[categoryId]
    }

    class func getFont(byId fontId: Int) -> UIFont {
        let fonts = [
            UIFont(name: "HelveticaNeue-Light", size: 14),
            UIFont(name: "HelveticaNeue-Light", size: 12),
            UIFont(name: "HelveticaNeue", size: 12)
        ]

        return fonts[fontId]!
    }

    class func getHeightForRow(withBook book: Book) -> CGFloat {
        return CustomTableViewCell.getLabelSize(withText: book.name, font: CustomTableViewCell.getFont(byId: 0)).height
            + CustomTableViewCell.getLabelSize(withText: book.authors, font: CustomTableViewCell.getFont(byId: 1)).height
            + CustomTableViewCell.getLabelSize(
                withText: CustomTableViewCell.getCategoryName(byId: book.categoryId - 1),
                font: CustomTableViewCell.getFont(byId: 2)
                ).height + 35.5
    }

    class func getLabelSize(withText text: String, font: UIFont) -> CGSize {
        let mainScreenWidth = UIScreen.main.bounds.size.width
        let size = CGSize(width: mainScreenWidth - 30, height: .greatestFiniteMagnitude)

        return (text == "" ? .zero : text.boundingRect(with: size, options: .usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font], context: nil)).size
    }


    private func getAttributedString(forBookName bookName: NSString, highlightedWords: NSString)
        -> NSMutableAttributedString {
            let normalColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1)
            let highlightColor = UIColor(red: 253 / 255.0, green: 208 / 255.0, blue: 209 / 255.0, alpha: 1)
            let result = NSMutableAttributedString(string: bookName as String)
            result.addAttribute(
                NSForegroundColorAttributeName,
                value: normalColor,
                range: NSMakeRange(0, result.length)
            )

            // Заменить только пробелы: [ ]+, пробелы и табуляцию: [ \\t]+, пробелы, табуляцию и переводы строк: \\s+
            let squashedString = highlightedWords.replacingOccurrences(
                of: "[ ]+",
                with: " ",
                options: .regularExpression,
                range: NSMakeRange(0, highlightedWords.length)
            )

            let trimmedString = squashedString.trimmingCharacters(in: .whitespacesAndNewlines)
            let words = trimmedString.characters.split { $0 == " " }.map { String($0) }
            var foundRange, nextRange: NSRange

            for word in words {
                foundRange = bookName.range(of: word, options: .caseInsensitive)

                while foundRange.location != NSNotFound {
                    result.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: foundRange)
                    nextRange = NSMakeRange(
                        foundRange.location + foundRange.length,
                        bookName.length - foundRange.location - foundRange.length
                    )
                    foundRange = bookName.range(of: word, options: .caseInsensitive, range: nextRange)
                }
            }
            
            return result
    }

    private func configureWithBook(_ book: Book, query: String!) {
        self.book = book

        let categoryColors = [
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

        nameLabel = UILabel()
        nameLabel.font = CustomTableViewCell.getFont(byId: 0)

        if query == nil {
            nameLabel.text = book.name
            nameLabel.textColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1)
        } else {
            nameLabel.attributedText = getAttributedString(
                forBookName: book.name as NSString,
                highlightedWords: query! as NSString
            )
        }

        nameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.numberOfLines = 0
        contentView.addSubview(nameLabel)

        authorsLabel = UILabel()
        authorsLabel.font = CustomTableViewCell.getFont(byId: 1)
        authorsLabel.text = book.authors
        authorsLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 0.75)
        authorsLabel.lineBreakMode = .byWordWrapping
        authorsLabel.numberOfLines = 0
        contentView.addSubview(authorsLabel)

        categoryLabel = CustomLabel()
        categoryLabel.edgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 3)
        categoryLabel.font = CustomTableViewCell.getFont(byId: 2)
        categoryLabel.text = CustomTableViewCell.getCategoryName(byId: book.categoryId - 1)
        categoryLabel.textColor = .white
        categoryLabel.layer.backgroundColor = categoryColors[book.categoryId - 1].cgColor
        categoryLabel.layer.cornerRadius = 2
        categoryLabel.lineBreakMode = .byWordWrapping
        categoryLabel.numberOfLines = 0
        contentView.addSubview(categoryLabel)

        roundProgressView = RoundProgressView()
        contentView.addSubview(roundProgressView)

        starImage = UIImageView(image: UIImage(named: "Favorites")!.withRenderingMode(.alwaysTemplate))
        starImage.tintColor = book.isAddedToFavorites
            ? UIColor(red: 1, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1) : UIColor(white: 0.8, alpha: 1)
        contentView.addSubview(starImage)

        for downloadedBook in ControllerManager.instance.downloadsTableViewController.books {
            if downloadedBook.id == book.id {
                roundProgressView.percent = 100
                break
            }
        }

        if let task = book.getDownloadTask() {
            if let fileInfomation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier),
                let isDownloading = fileInfomation.isDownloading {
                    if !isDownloading {
                        roundProgressView.isWaiting = true
                    }
                    
                    roundProgressView.percent = CGFloat(fileInfomation.progressPercentage)
            }
        }
        
        tag = book.id
    }

}
