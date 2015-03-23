//
//  Database.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import Foundation

/// Класс для представления базы данных
class Database {
    
    /// Название файла базы данных
    let databaseName = "Database.sqlite"
    
    /// База данных
    private let database : COpaquePointer = nil
    
    
    /// Возвращает экземпляр класса базы данных
    ///
    /// :returns: Экземпляр класса базы данных
    class var instance : Database {
        
        struct Singleton {
            static let instance = Database()
        }
        
        return Singleton.instance
    }
    
    /// Возвращает полный путь к файлу базы данных из директории документов
    ///
    /// :returns: Полный путь к файлу базы данных из директории документов
    private func databasePath() -> String {
        return NSHomeDirectory().stringByAppendingFormat("/Documents/" + databaseName) // NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0].stringByAppendingPathComponent(databaseName)
    }
    
    /// Проверяет существование файлы базы данных в директории документов, и если он отсутствует, копирует его туда
    ///
    /// :returns: Истина, если файл существует в директории документов, или ложь, если файл скопировать не удалось
    private func copyDatabaseFile() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(databasePath()) {
            if let sourceDatabasePath = NSBundle.mainBundle().pathForResource(databaseName, ofType: nil) {
                // FIXME: копирует файл, даже если он отстутствует в онсовной директории. Конечный получается пустым, из-за чего невозможно выполнить запрос. Ошибка наблюдается в том случае, если приложение не содержит файл Database.sqlite.
                if !(fileManager.copyItemAtPath(sourceDatabasePath, toPath: databasePath(), error: nil)) {
                    return false
                }
            }
        }
        // println(fm.attributesOfItemAtPath(databasePath(), error: nil)?.debugDescription)
        
        return true
    }
    
    /// Инициализирует класс
    required init() {
        if copyDatabaseFile() { // если файл базы данных уже скопирован в директорию документов
            if sqlite3_open(databasePath().cStringUsingEncoding(NSUTF8StringEncoding)!, &database) != SQLITE_OK {
                sqlite3_close(database)
            }
        }
    }
    
    /// Деинициализирует класс
    deinit {
        sqlite3_close(database)
    }
    
    /// Возвращает массив книг для заданного списка
    ///
    /// :param: list Список
    /// :returns: Массив книг
    func booksForList(list: String) -> [Book] {
        var statement : COpaquePointer = nil
        var books = [Book]()
        let query = "SELECT * FROM `Books` WHERE `list` = '\(list)'"
        
        if sqlite3_prepare_v2(self.database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) != SQLITE_OK {
            println(statement.debugDescription)
            sqlite3_finalize(statement)
            if let error = String.fromCString(sqlite3_errmsg(self.database)) {
                println("База данных - не удалось подготовить SQL-запрос: \(query), описание ошибки: \(error)")
            }
            
            return books
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            books.append(Book(bookId: Int(sqlite3_column_int(statement, 0)),
                name: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))!,
                authors: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 6)))!,
                category: Int(sqlite3_column_int(statement, 7)),
                fileSize: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))!,
                smallPhotoUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 5)))!,
                bigPhotoUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 4)))!,
                downloadUrl: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 2)))!
                ))
        }
        
        sqlite3_finalize(statement)
        
        return books
    }
    
    /// Проверяет, добавлена ли книга в заданный список
    ///
    /// :param: bookId Идентификатор книги
    /// :param: list Список
    /// :returns: Истина, если книга добавлена, или ложь, если нет
    func isBookWithId(bookId: NSInteger, addedToList list: String) -> Bool {
        var statement : COpaquePointer = nil
        var isBookAdded = false
        let query = "SELECT * FROM `Books` WHERE `id` = \(bookId) AND `list` = '\(list)'"
        
        if sqlite3_prepare_v2(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                isBookAdded = true
            }
        }
        
        sqlite3_reset(statement)
        sqlite3_finalize(statement)
        
        return isBookAdded
    }
    
    /// Добавляет книгу в заданный список.
    ///
    /// :param: book Книга
    /// :param: list Список
    func addBook(book: Book, toList list: String) {
        var statement : COpaquePointer = nil
        let query = "INSERT INTO `Books` (`id`, `name`, `download_url`, `file_size`, `photo_big`, `photo_small`, `authors`, `category`, `list`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        
        if sqlite3_prepare_v2(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &statement, nil) == SQLITE_OK {
            let transientPointer = COpaquePointer(UnsafeMutablePointer<Int>(bitPattern: -1))
            let transient = CFunctionPointer<((UnsafeMutablePointer<()>) -> Void)>(transientPointer)
            
            sqlite3_bind_int(statement, 1, CInt(book.bookId!))
            sqlite3_bind_text(statement, 2, book.name!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 3, book.downloadUrl!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 4, book.fileSize!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 5, book.bigPhotoUrl!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 6, book.smallPhotoUrl!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_text(statement, 7, book.authors!.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            sqlite3_bind_int(statement, 8, CInt(book.category!))
            sqlite3_bind_text(statement, 9, list.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                // NSAssert1(0, "Ошибка при добавлении утвержедения. Описание: '%s'", sqlite3_errmsg(self.database))
            }
        }
        
        sqlite3_reset(statement)
        sqlite3_finalize(statement)
    }
    
    /// Удаляет книгу по индентификатору из заданного списка
    ///
    /// :param: bookId Идентификатор книги
    /// :param: list Список
    func deleteBookWithId(bookId: Int, fromList list: String) {
        let query = "DELETE FROM `Books` WHERE `id` = \(bookId) AND `list` = '\(list)'"
        
        sqlite3_exec(database, query.cStringUsingEncoding(NSUTF8StringEncoding)!, nil, nil, nil)
    }
}
