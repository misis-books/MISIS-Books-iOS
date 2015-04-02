//
//  Book.swift
//  misisbooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2014 Maxim Loskov. All rights reserved.
//

import Foundation

/// Класс для представления книги
class Book {
    
    /// Идентификатор книги
    var bookId : Int
    
    /// Название книги
    var name : String
    
    /// Автор (авторы) книги
    var authors : String?
    
    /// Категория книги
    var category : Int?
    
    /// Размер файла книги
    var fileSize : String?
    
    /// Адрес маленького изображения книги
    var smallPhotoUrl : String?
    
    /// Адрес большого изображения книги
    var bigPhotoUrl : String?
    
    /// Адрес для загрузки книги
    var downloadUrl : String?
    
    
    /// Инициализирует класс заданными параметрами
    ///
    /// :param: bookId Идентификатор книги
    /// :param: name Название книги
    /// :param: authors Автор (авторы) книги
    /// :param: category Категория книги
    /// :param: fileSize Размер файла книги
    /// :param: smallPhotoUrl Адрес маленького изображения книги
    /// :param: bigPhotoUrl Адрес большого изображения книги
    /// :param: downloadUrl Адрес для загрузки книги
    init(bookId: Int, name: String, authors: String, category: Int, fileSize: String, smallPhotoUrl: String, bigPhotoUrl: String, downloadUrl: String) {
        self.bookId = bookId
        self.name = name
        self.authors = authors
        self.category = category
        self.fileSize = fileSize
        self.smallPhotoUrl = smallPhotoUrl
        self.bigPhotoUrl = bigPhotoUrl
        self.downloadUrl = downloadUrl
    }
    
    /// MARK: - Вспомогательные методы
    
    /// Определяет, добавлена ли книга в избранное
    ///
    /// :returns: Флаг наличия книги в избранном
    func isAddedToFavorites() -> Bool {
        return Database.sharedInstance.isBookWithId(bookId, addedToList: "Favorites")
    }
    
    /// Определяет, добавлена ли книга в загрузки
    ///
    /// :returns: Флаг наличия книги в загрузках
    func isAddedToDownloads() -> Bool {
        return Database.sharedInstance.isBookWithId(bookId, addedToList: "Downloads")
    }
    
    /// Определяет, существует ли книга в текущих загрузках
    ///
    /// :returns: Флаг наличия книги в текущих загрузках
    func isExistsInCurrentDownloads() -> Bool {
        let currentDownloads = DownloadManager.getCurrentDownloads()
        
        for currentDownload in currentDownloads {
            if currentDownload.fileName == "\(bookId).pdf" {
                return true
            }
        }
        
        return false
    }
    
    /// Определяет, загружается ли книга в данный момент
    ///
    /// :returns: Флаг состояния загрузки книги в данный момент
    func isDownloading() -> Bool! {
        let currentDownloads = DownloadManager.getCurrentDownloads()
        
        for currentDownload in currentDownloads {
            if currentDownload.fileName == "\(bookId).pdf" {
                return currentDownload.isDownloading
            }
        }
        
        return nil
    }
    
    /// Возвращает задание загрузки
    ///
    /// :returns: Задание загрузки
    func getDownloadTask() -> NSURLSessionDownloadTask! {
        let currentDownloads = DownloadManager.getCurrentDownloads()
        
        for currentDownload in currentDownloads {
            if currentDownload.fileName == "\(bookId).pdf" {
                return currentDownload.task
            }
        }
        
        return nil
    }
}
