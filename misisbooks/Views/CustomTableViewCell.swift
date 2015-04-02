//
//  CustomTableViewCell.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления настраиваемой ячейки таблицы
class CustomTableViewCell : UITableViewCell {
    
    /// Книга
    var book : Book!
    
    /// Поле для названия книги
    var nameLabel : UILabel!
    
    /// Поле для автора (авторов) книги
    var authorsLabel : UILabel!
    
    /// Поле для категории книги
    var categoryLabel : CustomLabel!
    
    
    init(book: Book, query: NSString!) {
        super.init(style: .Default, reuseIdentifier: CustomTableViewCell.reuseIdentifier)
        
        configureWithBook(book, query: query)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// Возвращает идентификатор для повторного использования
    ///
    /// :returns: Идентификатор для повторного использования
    class var reuseIdentifier : String {
        return "cell"
    }
    
    /// Возвращает название категории по идетификатору
    ///
    /// :param: fontId Идентификатор шрифта
    /// :returns: Названия категорий
    class func getCategoryName(categoryId: Int) -> String {
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
    
        return categoryNames[categoryId]
    }
    
    /// Возвращает шрифт, соответсвующий идентификатору
    ///
    /// :param: fontId Идентификатор шрифта
    /// :returns: Шрифт
    class func getFont(fontId: Int) -> UIFont {
        let fonts = [
            UIFont(name: "HelveticaNeue-Light", size: 14.0)!,
            UIFont(name: "HelveticaNeue-Light", size: 12.0)!,
            UIFont(name: "HelveticaNeue", size: 12.0)!
        ]
        
        return fonts[fontId]
    }
    
    /// Конфигурирует ячейку таблицы
    ///
    /// :params: book Книга
    /// :params: query Запрос
    func configureWithBook(book: Book, query: NSString!) {
        self.book = book
        
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
        
        let nameLabelText = book.name
        let nameLabelFont = CustomTableViewCell.getFont(0)
        let nameLabelSize = CustomTableViewCell.labelSizeWithText(nameLabelText, font: nameLabelFont)
        nameLabel = UILabel(frame: CGRectMake(15.0, 8.5, nameLabelSize.width, nameLabelSize.height))
        nameLabel.font = nameLabelFont
        
        if query == nil {
            nameLabel.text = nameLabelText
            nameLabel.textColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1.0)
        } else {
            nameLabel.attributedText = attributedStringForBookName(nameLabelText, highlightedWords:query!)
        }
        
        nameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
        nameLabel.lineBreakMode = .ByWordWrapping
        nameLabel.numberOfLines = 0
        nameLabel.tag = 1
        contentView.addSubview(nameLabel)
        
        let authorsLabelText = book.authors!
        let authorsLabelFont = CustomTableViewCell.getFont(1)
        let authorsLabelSize = CustomTableViewCell.labelSizeWithText(authorsLabelText, font: authorsLabelFont)
        authorsLabel = UILabel(frame: CGRectMake(15.0, 11.0 + nameLabelSize.height, authorsLabelSize.width, authorsLabelSize.height))
        authorsLabel.font = authorsLabelFont
        authorsLabel.text = authorsLabelText
        authorsLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 0.75)
        authorsLabel.lineBreakMode = .ByWordWrapping
        authorsLabel.numberOfLines = 0
        authorsLabel.tag = 2
        contentView.addSubview(authorsLabel)
        
        let categoryLabelText = CustomTableViewCell.getCategoryName(book.category! - 1)
        let categoryLabelFont = CustomTableViewCell.getFont(2)
        let categoryLabelSize = CustomTableViewCell.labelSizeWithText(categoryLabelText, font: categoryLabelFont)
        categoryLabel = CustomLabel(frame: CGRectMake(15.0, 16.5 + nameLabelSize.height + authorsLabelSize.height, 10.0 + categoryLabelSize.width, 6.0 + categoryLabelSize.height))
        categoryLabel.topInset = 3.0
        categoryLabel.rightInset = 3.0
        categoryLabel.bottomInset = 5.0
        categoryLabel.leftInset = 5.0
        categoryLabel.font = categoryLabelFont
        categoryLabel.text = categoryLabelText
        categoryLabel.textColor = UIColor.whiteColor()
        categoryLabel.layer.backgroundColor = categoryColors[book.category! - 1].CGColor
        categoryLabel.layer.cornerRadius = 2.0
        categoryLabel.lineBreakMode = .ByWordWrapping
        categoryLabel.numberOfLines = 0
        categoryLabel.tag = 3
        contentView.addSubview(categoryLabel)
        
        let infoLabel = UILabel(frame: CGRectMake(0.0, 16.5 + nameLabelSize.height + authorsLabelSize.height, UIScreen.mainScreen().bounds.size.width - 15.0, 20.0))
        infoLabel.font = CustomTableViewCell.getFont(2)
        
        let books = ControllerManager.sharedInstance.downloadsTableViewController.books
        for var i = 0; i < books.count; ++i {
            if books[i].bookId == book.bookId {
                infoLabel.text = "Загружено"
                break
            }
        }
        
        infoLabel.textAlignment = .Right
        infoLabel.textColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0)
        infoLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        infoLabel.numberOfLines = 0
        infoLabel.tag = 4
        contentView.addSubview(infoLabel)
        
        let progressView = UIProgressView(frame: CGRectMake(15.0, 32.5 + nameLabelSize.height + authorsLabelSize.height + categoryLabelSize.height, UIScreen.mainScreen().bounds.size.width - 15.0, 2.0))
        progressView.progressViewStyle = .Bar
        progressView.tintColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0)
        progressView.tag = 5
        contentView.addSubview(progressView)
        
        if let task = book.getDownloadTask() {
            if let fileInfomation = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                if let isDownloading = fileInfomation.isDownloading {
                    if isDownloading {
                        infoLabel.text = "Загрузка: \(fileInfomation.progressPercentage)%"
                    } else {
                        infoLabel.text = "Пауза: \(fileInfomation.progressPercentage)%"
                    }
                    
                    progressView.setProgress(Float(fileInfomation.progressPercentage) / 100, animated: false)
                }
            }
        }
        
        tag = book.bookId
    }
    
    /// Возвращает размер поля, находящегося в ячейке таблицы, для заданного текста и шрифта
    ///
    /// :param: text Текст
    /// :param: font Шрифт
    /// :returns: Размер поля
    class func labelSizeWithText(text: String, font: UIFont) -> CGSize {
        let mainScreenWidth = UIScreen.mainScreen().bounds.size.width
        let size = CGSizeMake(mainScreenWidth - CGFloat(30.0), CGFloat.max)
        
        return (text == "" ? CGRectZero : text.boundingRectWithSize(size, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)).size
    }
    
    /// Возвращает размер ячейки таблицы для заданной книги
    ///
    /// :param: book Книга
    /// :returns: Размер ячейки таблицы
    class func heightForRowWithBook(book: Book) -> CGFloat {
        return 35.5 +
            CustomTableViewCell.labelSizeWithText(book.name, font: CustomTableViewCell.getFont(0)).height +
            CustomTableViewCell.labelSizeWithText(book.authors!, font: CustomTableViewCell.getFont(1)).height +
            CustomTableViewCell.labelSizeWithText(CustomTableViewCell.getCategoryName(book.category! - 1), font: CustomTableViewCell.getFont(2)).height
    }
    
    /// Возвращает строку для названия книги с подсвеченными словами, входящими в запрос
    ///
    /// :param: bookName Название книги
    /// :param: highlightedWords Слова, которые требуется подсветить (разделены пробелом)
    /// :returns: Строка для названия книги с подсвеченными словами
    func attributedStringForBookName(bookName: NSString, highlightedWords: NSString) -> NSMutableAttributedString {
        let normalColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1.0)
        let highlightColor = UIColor(red: 253 / 255.0, green: 208 / 255.0, blue: 209 / 255.0, alpha: 1.0)
        var result = NSMutableAttributedString(string: bookName)
        result.addAttribute(NSForegroundColorAttributeName, value: normalColor, range: NSMakeRange(0, result.length))
        
        // Заменить только пробелы: [ ]+
        // Заменить пробелы и табуляцию: [ \\t]+
        // Заменить пробелы, табуляцию и переводы строк: \\s+
        let squashedString = highlightedWords.stringByReplacingOccurrencesOfString("[ ]+", withString: " ", options: .RegularExpressionSearch, range: NSMakeRange(0, highlightedWords.length))
        
        let trimmedString = squashedString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var word : NSString
        let wordsArray = trimmedString.componentsSeparatedByString(" ")
        var foundRange, nextRange: NSRange
        
        for var i = 0; i < wordsArray.count; ++i {
            word = wordsArray[i] as NSString
            foundRange = bookName.rangeOfString(word, options: .CaseInsensitiveSearch)
            
            while foundRange.location != NSNotFound {
                result.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: foundRange)
                nextRange = NSMakeRange(foundRange.location + foundRange.length, bookName.length - foundRange.location - foundRange.length)
                foundRange = bookName.rangeOfString(word, options: .CaseInsensitiveSearch, range: nextRange)
            }
        }
        
        return result
    }
}
