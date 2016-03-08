//
//  Book.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

/**
    Класс для представления книги
*/
class Book {

    /// Автор (авторы) книги
    let authors: String

    /// URL большого изображения книги
    let bigPreviewUrl: String

    /// Идентификатор категории книги
    let categoryId: Int

    /// URL файла книги
    let downloadUrl: String

    /// Размер файла книги
    let fileSize: String

    /// Идентификатор книги
    let id: Int

    /// Флаг наличия книги в избранном
    var isMarkedAsFavorite: Bool!

    /// Название книги
    let name: String

    /// URL маленького изображения книги
    let smallPreviewUrl: String

    /**
        Инициализирует класс заданными параметрами

        - parameter authors: Автор (авторы) книги
        - parameter bigPhotoUrl: URL большого изображения книги
        - parameter categoryId: Идентификатор категории книги
        - parameter downloadUrl: URL файла книги
        - parameter fileSize: Размер файла книги
        - parameter id: Идентификатор книги
        - parameter isMarkedAsFavorite: Флаг наличия книги в избранном
        - parameter name: Название книги
        - parameter smallPhotoUrl: URL маленького изображения книги
    */
    init(authors: String, bigPreviewUrl: String, categoryId: Int, downloadUrl: String, fileSize: String, id: Int,
        isMarkedAsFavorite: Bool!, name: String, smallPreviewUrl: String) {
            self.authors = authors
            self.bigPreviewUrl = bigPreviewUrl
            self.downloadUrl = downloadUrl
            self.categoryId = categoryId
            self.fileSize = fileSize
            self.id = id
            self.isMarkedAsFavorite = isMarkedAsFavorite
            self.name = name
            self.smallPreviewUrl = smallPreviewUrl
    }

    /**
        Возвращает задание загрузки или nil

        - returns: Задание загрузки или nil
    */
    func getDownloadTask() -> NSURLSessionDownloadTask! {
        for currentDownload in DownloadManager.getCurrentDownloads() {
            if currentDownload.fileName == "\(id).pdf" {
                return currentDownload.task
            }
        }

        return nil
    }

    /**
        Определяет, добавлена ли книга в загрузки

        - returns: Флаг наличия книги в загрузках
    */
    func isAddedToDownloads() -> Bool {
        return Database.instance.isBook(self, addedToList: "downloads")
    }

    /**
        Определяет, добавлена ли книга в избранное

        - returns: Флаг наличия книги в избранном
    */
    func isAddedToFavorites() -> Bool {
        if isMarkedAsFavorite != nil {
            return isMarkedAsFavorite!
        }

        return Database.instance.isBook(self, addedToList: "favorites")
    }

    /**
        Определяет, загружается ли книга в данный момент. При отсутствии в текущих загрузках возвращает nil

        - returns: Флаг состояния загрузки книги в данный момент или nil
    */
    func isDownloading() -> Bool! {
        for currentDownload in DownloadManager.getCurrentDownloads() {
            if currentDownload.fileName == "\(id).pdf" {
                return currentDownload.isDownloading
            }
        }

        return nil
    }

    /**
        Определяет, существует ли книга в текущих загрузках

        - returns: Флаг наличия книги в текущих загрузках
    */
    func isExistsInCurrentDownloads() -> Bool {
        for downloadableBook in ControllerManager.instance.downloadsTableViewController.downloadableBooks {
            if downloadableBook.id == id {
                return true
            }
        }

        return false
    }

    /**
        Возвращает локальный URL книги

        - returns: Локальный URL книги
    */
    func localUrl() -> NSURL {
        return (NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as
            NSURL).URLByAppendingPathComponent("\(id).pdf")
    }
}
