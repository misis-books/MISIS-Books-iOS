//
//  Database.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 05.04.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import UIKit

class Database {

    static let instance = Database()
    private var database: OpaquePointer? = nil

    init() {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: databasePath()) {
            if !fileManager.createFile(atPath: databasePath(), contents: nil, attributes: nil) {
                return
            }
        }

        if sqlite3_open(databasePath().cString(using: String.Encoding.utf8)!, &database) != SQLITE_OK {
            sqlite3_close(database)
        } else {
            let columns = [
                "`id` INTEGER",
                "`name` VARCHAR",
                "`authors` VARCHAR",
                "`category_id` INTEGER",
                "`file_size` VARCHAR",
                "`big_preview_url` VARCHAR",
                "`small_preview_url` VARCHAR",
                "`download_url` VARCHAR",
                "`list` VARCHAR"
            ]
            let query = "CREATE TABLE IF NOT EXISTS `Books` (" + columns.joined(separator: ", ") + ")"
            sqlite3_exec(database, query.cString(using: String.Encoding.utf8)!, nil, nil, nil)
        }
    }

    deinit {
        sqlite3_close(database)
    }

    func addBook(_ book: Book, toList list: String) {
        var statement: OpaquePointer? = nil
        let columns = [
            "`id`",
            "`name`",
            "`authors`",
            "`category_id`",
            "`file_size`",
            "`big_preview_url`",
            "`small_preview_url`",
            "`download_url`",
            "`list`"
        ]
        let query = "INSERT INTO `Books` (" + columns.joined(separator: ", ") + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"

        if sqlite3_prepare_v2(database, query.cString(using: String.Encoding.utf8)!, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(UnsafeMutablePointer<Int>(bitPattern: -1), to: sqlite3_destructor_type.self)

            sqlite3_bind_int(statement, 1, CInt(book.id))
            sqlite3_bind_text(statement, 2, book.name.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_text(statement, 3, book.authors.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_int(statement, 4, CInt(book.categoryId))
            sqlite3_bind_text(statement, 5, book.fileSize.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_text(statement, 6, book.bigPreviewUrl.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_text(statement, 7, book.smallPreviewUrl.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_text(statement, 8, book.downloadUrl.cString(using: String.Encoding.utf8)!, -1, transient)
            sqlite3_bind_text(statement, 9, list.cString(using: String.Encoding.utf8)!, -1, transient)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Ошибка при выполнении SQL-запроса. Описание: %s", sqlite3_errmsg(database))

                return
            }
        }

        sqlite3_reset(statement)
        sqlite3_finalize(statement)
    }

    func booksForList(_ list: String) -> [Book] {
        var statement: OpaquePointer? = nil
        var books = [Book]()
        let query = "SELECT * FROM `Books` WHERE `list` = '\(list)'"

        if sqlite3_prepare_v2(database, query.cString(using: String.Encoding.utf8)!, -1, &statement, nil)
            != SQLITE_OK {
            print(statement.debugDescription)
            sqlite3_finalize(statement)

            if let error = String(validatingUTF8: sqlite3_errmsg(database)) {
                print("Не удалось подготовить SQL-запрос: \(query), описание ошибки: \(error)")
            }

            return books
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            books.append(
                Book(
                    authors: String(cString: sqlite3_column_text(statement, 2)),
                    bigPreviewUrl: String(cString: sqlite3_column_text(statement, 6)),
                    categoryId: Int(sqlite3_column_int(statement, 3)),
                    downloadUrl: String(cString: sqlite3_column_text(statement, 7)),
                    fileSize: String(cString: sqlite3_column_text(statement, 4)),
                    id: Int(sqlite3_column_int(statement, 0)),
                    isMarkedAsFavorite: nil,
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    smallPreviewUrl: String(cString: sqlite3_column_text(statement, 5))
                )
            )

        }

        sqlite3_finalize(statement)

        return books
    }

    func isBook(_ book: Book, addedToList list: String) -> Bool {
        var statement: OpaquePointer? = nil
        var isBookAdded = false
        let query = "SELECT * FROM `Books` WHERE `id` = \(book.id) AND `list` = '\(list)'"

        if sqlite3_prepare_v2(database, query.cString(using: String.Encoding.utf8)!, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                isBookAdded = true
            }
        }

        sqlite3_reset(statement)
        sqlite3_finalize(statement)

        return isBookAdded
    }

    func deleteAllBooksFromList(_ list: String) {
        let query = "DELETE FROM `Books` WHERE `list` = '\(list)'"
        sqlite3_exec(database, query.cString(using: String.Encoding.utf8)!, nil, nil, nil)
    }

    func deleteBook(_ book: Book, fromList list: String) {
        let query = "DELETE FROM `Books` WHERE `id` = \(book.id) AND `list` = '\(list)'"
        sqlite3_exec(database, query.cString(using: String.Encoding.utf8)!, nil, nil, nil)
    }

    private func databasePath() -> String {
        return URL(string: "database.sqlite", relativeTo: FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0])!.path
    }
    
}
