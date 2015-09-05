//
//  Database.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 05.04.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import UIKit

/**
    Класс для представления базы данных
*/
class Database {

    /// База данных
    private var database: COpaquePointer = nil

    /**
        Возвращает экземпляр класса

        - returns: Экземпляр класса
    */
    class var instance: Database {

        struct Singleton {
            static let instance = Database()
        }

        return Singleton.instance
    }

    init() {
        let fileManager = NSFileManager.defaultManager()

        if !fileManager.fileExistsAtPath(databasePath()) {
            if !fileManager.createFileAtPath(databasePath(), contents: nil, attributes: nil) {
                return
            }
        }

        if sqlite3_open(databasePath().cStringUsingEncoding(NSUTF8StringEncoding)!, &database) != SQLITE_OK {
            sqlite3_close(database)
        } else {
            let columns = ["`id` INTEGER", "`name` VARCHAR", "`authors` VARCHAR", "`category_id` INTEGER", "`file_size` VARCHAR",
                "`big_preview_url` VARCHAR", "`small_preview_url` VARCHAR", "`download_url` VARCHAR", "`list` VARCHAR"]
            let query = "CREATE TABLE IF NOT EXISTS `Books` (" + ", ".join(columns) + ")"
            sqlite3_exec(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, nil, nil, nil)
        }
    }

    deinit {
        sqlite3_close(database)
    }

    /**
        Добавляет книгу в заданный список

        - parameter book: Книга
        - parameter list: Список
    */
    func addBook(book: Book, toList list: String) {
        var statement: COpaquePointer = nil
        let columns = ["`id`", "`name`", "`authors`", "`category_id`", "`file_size`", "`big_preview_url`", "`small_preview_url`",
            "`download_url`", "`list`"]
        let query = "INSERT INTO `Books` (" + ", ".join(columns) + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"

        if sqlite3_prepare_v2(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(UnsafeMutablePointer<Int>(bitPattern: -1), sqlite3_destructor_type.self)

            sqlite3_bind_int(statement, 1, CInt(book.id))
            sqlite3_bind_text(statement, 2, book.name.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 3, book.authors.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_int(statement, 4, CInt(book.categoryId))
            sqlite3_bind_text(statement, 5, book.fileSize.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 6, book.bigPreviewUrl.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 7, book.smallPreviewUrl.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 8, book.downloadUrl.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 9, list.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Ошибка при выполнении SQL-запроса. Описание: %s", sqlite3_errmsg(database))

                return
            }
        }

        sqlite3_reset(statement)
        sqlite3_finalize(statement)
    }

    /**
        Возвращает книги для заданного списка

        - parameter list: Список

        - returns: Массив книг
    */
    func booksForList(list: String) -> [Book] {
        var statement: COpaquePointer = nil
        var books = [Book]()
        let query = "SELECT * FROM `Books` WHERE `list` = '\(list)'"

        if sqlite3_prepare_v2(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) != SQLITE_OK {
            print(statement.debugDescription)
            sqlite3_finalize(statement)

            if let error = String.fromCString(sqlite3_errmsg(database)) {
                print("Не удалось подготовить SQL-запрос: \(query), описание ошибки: \(error)")
            }

            return books
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            books.append(Book(authors: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 2)))!,
                bigPreviewUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 6)))!,
                categoryId: Int(sqlite3_column_int(statement, 3)),
                downloadUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 7)))!,
                fileSize: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 4)))!,
                id: Int(sqlite3_column_int(statement, 0)),
                isMarkedAsFavorite: nil,
                name: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))!,
                smallPreviewUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 5)))!))
        }

        sqlite3_finalize(statement)

        return books
    }

    /**
        Проверяет, добавлена ли книга в заданный список

        - parameter book: Книга
        - parameter list: Список

        - returns: Флаг наличия книги в заданном списке
    */
    func isBook(book: Book, addedToList list: String) -> Bool {
        var statement: COpaquePointer = nil
        var isBookAdded = false
        let query = "SELECT * FROM `Books` WHERE `id` = \(book.id) AND `list` = '\(list)'"

        if sqlite3_prepare_v2(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                isBookAdded = true
            }
        }

        sqlite3_reset(statement)
        sqlite3_finalize(statement)

        return isBookAdded
    }

    /**
        Удаляет все книги из заданного списка

        - parameter list: Список
    */
    func deleteAllBooksFromList(list: String) {
        let query = "DELETE FROM `Books` WHERE `list` = '\(list)'"
        sqlite3_exec(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, nil, nil, nil)
    }

    /**
        Удаляет книгу из заданного списка

        - parameter book: Книга
        - parameter list: Список
    */
    func deleteBook(book: Book, fromList list: String) {
        let query = "DELETE FROM `Books` WHERE `id` = \(book.id) AND `list` = '\(list)'"
        sqlite3_exec(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, nil, nil, nil)
    }

    // MARK: - Внутренние методы

    /**
        Возвращает полный путь к файлу базы данных из директории документов

        - returns: Полный путь к файлу базы данных
    */
    private func databasePath() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String

        return documentDirectory.stringByAppendingPathComponent("database.sqlite")
    }
}
