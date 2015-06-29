//
//  CustomTableViewCell.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления настраиваемой ячейки таблицы
*/
class CustomTableViewCell: UITableViewCell {
    
    /// Книга
    var book: Book!
    
    /// Поле для названия книги
    var nameLabel: UILabel!
    
    /// Поле для автора (авторов) книги
    var authorsLabel: UILabel!
    
    /// Поле для категории книги
    var categoryLabel: CustomLabel!
    
    /// Круговой индикатор процесса загрузки
    var roundProgressView: RoundProgressView!
    
    /// Картинка звезды
    var starImage: UIImageView!
    
    /**
        Возвращает идентификатор для повторного использования

        - returns: Идентификатор для повторного использования
    */
    class var reuseId: String {
        return "cell"
    }
    
    init(book: Book, query: String!) {
        super.init(style: .Default, reuseIdentifier: CustomTableViewCell.reuseId)
        
        configure(book: book, query: query)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let nameLabelSize = CustomTableViewCell.labelSizeWithText(nameLabel.text!, font: nameLabel.font)
        let authorsLabelSize = CustomTableViewCell.labelSizeWithText(authorsLabel.text!, font: authorsLabel.font)
        let categoryLabelSize = CustomTableViewCell.labelSizeWithText(categoryLabel.text!, font: categoryLabel.font)
        
        nameLabel.frame = CGRectMake(15, 8.5, nameLabelSize.width, nameLabelSize.height)
        authorsLabel.frame = CGRectMake(15, nameLabelSize.height + 11, authorsLabelSize.width, authorsLabelSize.height)
        categoryLabel.frame = CGRectMake(15, nameLabelSize.height + authorsLabelSize.height + 16.5, categoryLabelSize.width + 10,
            categoryLabelSize.height + 6)
        roundProgressView.frame = CGRectMake(frame.width - 70, nameLabelSize.height + authorsLabelSize.height + 16.5, 20, 20)
        starImage.frame = CGRectMake(frame.width - 35, nameLabelSize.height + authorsLabelSize.height + 16.5, 20, 20)
    }
    
    /**
        Возвращает название категории по ее идетификатору

        - parameter fontId: Идентификатор шрифта

        - returns: Название категории
    */
    class func categoryName(categoryId: Int) -> String {
        let categoryNames = ["Все", "Пособия", "Дипломы", "Сборники научных трудов", "Монографии, научные издания",
            "Книги «МИСиС»", "Авторефераты диссертаций", "Разное"]
        
        return categoryNames[categoryId]
    }
    
    /**
        Возвращает шрифт по его идетификатору

        - parameter fontId: Идентификатор шрифта

        - returns: Шрифт
    */
    class func font(fontId: Int) -> UIFont {
        let fonts = [UIFont(name: "HelveticaNeue-Light", size: 14)!, UIFont(name: "HelveticaNeue-Light", size: 12)!,
            UIFont(name: "HelveticaNeue", size: 12)!]
        
        return fonts[fontId]
    }
    
    /**
        Возвращает размер ячейки таблицы для заданной книги

        - parameter book: Книга

        - returns: Размер ячейки таблицы
    */
    class func heightForRowWithBook(book: Book) -> CGFloat {
        return CustomTableViewCell.labelSizeWithText(book.name, font: CustomTableViewCell.font(0)).height +
            CustomTableViewCell.labelSizeWithText(book.authors, font: CustomTableViewCell.font(1)).height +
            CustomTableViewCell.labelSizeWithText(CustomTableViewCell.categoryName(book.categoryId - 1),
                font: CustomTableViewCell.font(2)).height + 35.5
    }
    
    /**
        Возвращает размер поля, находящегося в ячейке таблицы, для заданного текста и шрифта

        - parameter text: Текст
        - parameter font: Шрифт

        - returns: Размер поля
    */
    class func labelSizeWithText(text: String, font: UIFont) -> CGSize {
        let mainScreenWidth = UIScreen.mainScreen().bounds.size.width
        let size = CGSizeMake(mainScreenWidth - 30, CGFloat.max)
        
        return (text == "" ? CGRectZero : text.boundingRectWithSize(size, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)).size
    }
    
    // MARK: - Внутренние методы
    
    /**
        Возвращает строку для названия книги с подсвеченными словами, входящими в запрос

        - parameter bookName: Название книги
        - parameter highlightedWords: Слова, которые требуется подсветить (разделены пробелом)
        - returns: Строка для названия книги с подсвеченными словами
    */
    private func attributedStringForBookName(bookName: NSString, highlightedWords: NSString) -> NSMutableAttributedString {
        let normalColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1)
        let highlightColor = UIColor(red: 253 / 255.0, green: 208 / 255.0, blue: 209 / 255.0, alpha: 1)
        let result = NSMutableAttributedString(string: bookName as String)
        result.addAttribute(NSForegroundColorAttributeName, value: normalColor, range: NSMakeRange(0, result.length))
        
        /*
            Заменить только пробелы: [ ]+
            Заменить пробелы и табуляцию: [ \\t]+
            Заменить пробелы, табуляцию и переводы строк: \\s+
        */
        let squashedString = highlightedWords.stringByReplacingOccurrencesOfString("[ ]+", withString: " ",
            options: .RegularExpressionSearch, range: NSMakeRange(0, highlightedWords.length))
        
        let trimmedString = squashedString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let words = split(trimmedString.characters) { $0 == " " }.map { String($0) }
        var foundRange, nextRange: NSRange
        
        for word in words {
            foundRange = bookName.rangeOfString(word, options: .CaseInsensitiveSearch)
            
            while foundRange.location != NSNotFound {
                result.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: foundRange)
                nextRange = NSMakeRange(foundRange.location + foundRange.length,
                    bookName.length - foundRange.location - foundRange.length)
                foundRange = bookName.rangeOfString(word, options: .CaseInsensitiveSearch, range: nextRange)
            }
        }
        
        return result
    }
    
    /**
        Конфигурирует ячейку таблицы

        :params: book Книга
        :params: query Запрос
    */
    private func configure(book book: Book, query: String!) {
        self.book = book
        
        let categoryColors = [UIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0, alpha: 1),
            UIColor(red: 74 / 255.0, green: 191 / 255.0, blue: 180 / 255.0, alpha: 1),
            UIColor(red: 253 / 255.0, green: 85 / 255.0, blue: 89 / 255.0, alpha: 1),
            UIColor(red: 184 / 255.0, green: 145 / 255.0, blue: 78 / 255.0, alpha: 1),
            UIColor(red: 179 / 255.0, green: 200 / 255.0, blue: 51 / 255.0, alpha: 1),
            UIColor(red: 155 / 255.0, green: 89 / 255.0, blue: 182 / 255.0, alpha: 1),
            UIColor(red: 255 / 255.0, green: 145 / 255.0, blue: 0 / 255.0, alpha: 1),
            UIColor(red: 46 / 255.0, green: 204 / 255.0, blue: 113 / 255.0, alpha: 1)]
        
        nameLabel = UILabel()
        nameLabel.font = CustomTableViewCell.font(0)
        
        if query == nil {
            nameLabel.text = book.name
            nameLabel.textColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1)
        } else {
            nameLabel.attributedText = attributedStringForBookName(book.name, highlightedWords: query!)
        }
        
        nameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1)
        nameLabel.lineBreakMode = .ByWordWrapping
        nameLabel.numberOfLines = 0
        contentView.addSubview(nameLabel)
        
        authorsLabel = UILabel()
        authorsLabel.font = CustomTableViewCell.font(1)
        authorsLabel.text = book.authors
        authorsLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 0.75)
        authorsLabel.lineBreakMode = .ByWordWrapping
        authorsLabel.numberOfLines = 0
        contentView.addSubview(authorsLabel)
        
        categoryLabel = CustomLabel()
        categoryLabel.topInset = 3
        categoryLabel.rightInset = 3
        categoryLabel.bottomInset = 5
        categoryLabel.leftInset = 5
        categoryLabel.font = CustomTableViewCell.font(2)
        categoryLabel.text = CustomTableViewCell.categoryName(book.categoryId - 1)
        categoryLabel.textColor = .whiteColor()
        categoryLabel.layer.backgroundColor = categoryColors[book.categoryId - 1].CGColor
        categoryLabel.layer.cornerRadius = 2
        categoryLabel.lineBreakMode = .ByWordWrapping
        categoryLabel.numberOfLines = 0
        contentView.addSubview(categoryLabel)
        
        roundProgressView = RoundProgressView()
        roundProgressView.tag = 4
        contentView.addSubview(roundProgressView)
        
        starImage = UIImageView(image: UIImage(named: "Favorites")!.imageWithRenderingMode(.AlwaysTemplate))
        starImage.tintColor = book.isAddedToFavorites() ?
            UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1) : UIColor(white: 0.8, alpha: 1)
        contentView.addSubview(starImage)
        
        for downloadedBook in ControllerManager.instance.downloadsTableViewController.books {
            if downloadedBook.id == book.id {
                roundProgressView.percent = 100
                break
            }
        }
        
        if let task = book.getDownloadTask() {
            if let fileInfomation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier),
                isDownloading = fileInfomation.isDownloading {
                    if !isDownloading {
                        roundProgressView.isWaiting = true
                    }
                    
                    roundProgressView.percent = CGFloat(fileInfomation.progressPercentage)
            }
        }
        
        tag = book.id
    }
}
