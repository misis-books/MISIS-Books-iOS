//
//  CustomTableViewCell.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import UIKit

/// Класс для представления ячейки таблицы с настраиваемыми параметрами
class CustomTableViewCell : UITableViewCell {
    
    /// Книга
    var book : Book!
    
    /// Поле для названия книги
    var nameLabel : UILabel!
    
    /// Поле для автора (авторов) книги
    var authorsLabel : UILabel!
    
    /// Поле для категории книги
    var categoryLabel : CustomUILabel!
    
    
    init(book: Book, query: NSString!) {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: CustomTableViewCell.reuseIdentifier)
        
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
        return "bookCell"
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
    
    /// Настраивает ячейку таблицы для заданных параметров
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
        
        let nameLabelText = book.name!
        let nameLabelFont = CustomTableViewCell.getFont(0)
        let nameLabelSize = CustomTableViewCell.labelSizeWithText(nameLabelText, font: nameLabelFont)
        nameLabel = UILabel(frame: CGRectMake(15.0, 8.5, nameLabelSize.width, nameLabelSize.height))
        nameLabel.font = nameLabelFont
        
        if query == nil {
            nameLabel.text = nameLabelText
            nameLabel.textColor = UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1.0)
        } else {
            nameLabel.attributedText = self.attributedStringForBookName(nameLabelText, highlightedWords:query!)
        }
        
        nameLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 1.0)
        nameLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        nameLabel.numberOfLines = 0
        nameLabel.tag = 1
        self.contentView.addSubview(nameLabel)
        
        let authorsLabelText = book.authors!
        let authorsLabelFont = CustomTableViewCell.getFont(1)
        let authorsLabelSize = CustomTableViewCell.labelSizeWithText(authorsLabelText, font: authorsLabelFont)
        authorsLabel = UILabel(frame: CGRectMake(15.0, 11.0 + nameLabelSize.height, authorsLabelSize.width, authorsLabelSize.height))
        authorsLabel.font = authorsLabelFont
        authorsLabel.text = authorsLabelText
        authorsLabel.textColor = UIColor(red: 79 / 255.0, green: 97 / 255.0, blue: 115 / 255.0, alpha: 0.75)
        authorsLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        authorsLabel.numberOfLines = 0
        authorsLabel.tag = 2
        self.contentView.addSubview(authorsLabel)
        
        let categoryLabelText = CustomTableViewCell.getCategoryName(book.category! - 1)
        let categoryLabelFont = CustomTableViewCell.getFont(2)
        let categoryLabelSize = CustomTableViewCell.labelSizeWithText(categoryLabelText, font: categoryLabelFont)
        categoryLabel = CustomUILabel(frame: CGRectMake(15.0, 16.5 + nameLabelSize.height + authorsLabelSize.height, 10.0 + categoryLabelSize.width, 6.0 + categoryLabelSize.height))
        categoryLabel.topInset = 3.0
        categoryLabel.rightInset = 3.0
        categoryLabel.bottomInset = 5.0
        categoryLabel.leftInset = 5.0
        categoryLabel.font = categoryLabelFont
        categoryLabel.text = categoryLabelText
        categoryLabel.textColor = UIColor.whiteColor()
        categoryLabel.layer.backgroundColor = categoryColors[book.category! - 1].CGColor
        categoryLabel.layer.cornerRadius = 2.0
        categoryLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        categoryLabel.numberOfLines = 0
        categoryLabel.tag = 3
        self.contentView.addSubview(categoryLabel)
        
        // let rnd = randomInt(0, max: 100)
        
        let infoLabel = UILabel(frame: CGRectMake(0.0, 16.5 + nameLabelSize.height + authorsLabelSize.height, UIScreen.mainScreen().bounds.size.width - 15.0, 20.0))
        infoLabel.font = CustomTableViewCell.getFont(2)
        
        let books = ControllerManager.instance.downloadsTableViewController.books
        for var i = 0; i < books.count; ++i {
            if books[i].bookId == book.bookId { // Если идентификатор книги совпал с требуемым
                infoLabel.text = "Загружено"
                break
            }
        }
        
        infoLabel.textAlignment = NSTextAlignment.Right
        infoLabel.textColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0)
        infoLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        infoLabel.numberOfLines = 0
        infoLabel.tag = 4
        self.contentView.addSubview(infoLabel)
        
        let progressView = UIProgressView(frame: CGRectMake(15.0, 32.5 + nameLabelSize.height + authorsLabelSize.height + categoryLabelSize.height, UIScreen.mainScreen().bounds.size.width - 15.0, 2.0))
        progressView.progressViewStyle = UIProgressViewStyle.Bar
        progressView.tintColor = UIColor(red: 255 / 255.0, green: 70 / 255.0, blue: 70 / 255.0, alpha: 1.0)
        // progressBar.setProgress(Float(rnd) / 100.0, animated: true)
        progressView.tag = 5
        self.contentView.addSubview(progressView)
        
        self.tag = book.bookId!
        
        // self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
    
    func randomInt(min: Int, max: Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    /// Возвращает размер поля, находящегося в ячейке таблицы, для заданного текста и шрифта
    ///
    /// :param: text Текст
    /// :param: font Шрифт
    /// :returns: Размер поля
    class func labelSizeWithText(text: String, font: UIFont) -> CGSize {
        return text == "" ? CGRectZero.size : text.boundingRectWithSize(CGSizeMake(UIScreen.mainScreen().bounds.size.width - CGFloat(30.0), 1000.0), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size
    }
    
    /// Возвращает размер ячейки таблицы для заданной книги
    ///
    /// :param: book Книга
    /// :returns: Размер ячейки таблицы
    class func heightForRowWithBook(book: Book) -> CGFloat {
        return 35.5 +
            CustomTableViewCell.labelSizeWithText(book.name!, font: CustomTableViewCell.getFont(0)).height +
            CustomTableViewCell.labelSizeWithText(book.authors!, font: CustomTableViewCell.getFont(1)).height +
            CustomTableViewCell.labelSizeWithText(CustomTableViewCell.getCategoryName(book.category! - 1), font: CustomTableViewCell.getFont(2)).height
    }
    
    /// Возвращает строку для названия книги с подсвеченными словами, входящими в запрос
    ///
    /// :param: bookName Название книги
    /// :param: highlightedWords Слова, которые требуется подсветить (разделены пробелом)
    /// :returns: Строка для названия книги с подсвеченными словами
    func attributedStringForBookName(bookName: NSString, highlightedWords: NSString) -> NSMutableAttributedString {
        var result = NSMutableAttributedString(string: bookName)
        
        result.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 59 / 255.0, green: 77 / 255.0, blue: 95 / 255.0, alpha: 1.0), range: NSMakeRange(0, result.length))
        
        // Заменить только пробелы: [ ]+
        // Заменить пробелы и табуляцию: [ \\t]+
        // Заменить пробелы, табуляцию и переводы строк: \\s+
        let squashedString = highlightedWords.stringByReplacingOccurrencesOfString("[ ]+", withString: " ", options: NSStringCompareOptions.RegularExpressionSearch, range: NSMakeRange(0, highlightedWords.length))
        let trimmedString = squashedString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var word : NSString
        let wordsArray = trimmedString.componentsSeparatedByString(" ")
        var foundRange, nextRange: NSRange
        
        for var i = 0; i < wordsArray.count; ++i {
            word = wordsArray[i] as NSString
            foundRange = bookName.rangeOfString(word, options: NSStringCompareOptions.CaseInsensitiveSearch)
            
            while foundRange.location != NSNotFound {
                result.addAttribute(NSBackgroundColorAttributeName, value: UIColor(red: 253 / 255.0, green: 208 / 255.0, blue: 209 / 255.0, alpha: 1.0), range: foundRange)
                nextRange = NSMakeRange(foundRange.location + foundRange.length, bookName.length - foundRange.location - foundRange.length)
                foundRange = bookName.rangeOfString(word, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nextRange)
            }
        }
        
        return result
    }
}
