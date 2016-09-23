//
//  Book.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 01.12.14.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import Foundation

class Book {

    let authors: String
    let bigPreviewUrl: String
    let categoryId: Int
    let downloadUrl: String
    let fileSize: String
    let id: Int
    var isMarkedAsFavorite: Bool!
    let name: String
    let smallPreviewUrl: String

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

    func getDownloadTask() -> URLSessionDownloadTask! {
        for currentDownload in DownloadManager.getCurrentDownloads() {
            if currentDownload.fileName == "\(id).pdf" {
                return currentDownload.task
            }
        }

        return nil
    }

    func isAddedToDownloads() -> Bool {
        return Database.instance.isBook(self, addedToList: "downloads")
    }

    func isAddedToFavorites() -> Bool {
        if isMarkedAsFavorite != nil {
            return isMarkedAsFavorite!
        }

        return Database.instance.isBook(self, addedToList: "favorites")
    }

    func isDownloading() -> Bool! {
        for currentDownload in DownloadManager.getCurrentDownloads() {
            if currentDownload.fileName == "\(id).pdf" {
                return currentDownload.isDownloading
            }
        }

        return nil
    }

    func isExistsInCurrentDownloads() -> Bool {
        for downloadableBook in ControllerManager.instance.downloadsTableViewController.downloadableBooks {
            if downloadableBook.id == id {
                return true
            }
        }

        return false
    }

    func localUrl() -> URL {
        return (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL).appendingPathComponent("\(id).pdf")
    }

}
