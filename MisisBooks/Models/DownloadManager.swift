//
//  DownloadManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 20.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

/**
    Класс для управления загрузками
*/
class DownloadManager: NSObject, NSURLSessionDelegate {

    /// Загрузки
    var downloads = [FileInformation]()

    /// Идентификатор загрузки
    let identifierDownload = "com.maximloskov.MisisBooks"

    /// Сессия
    var session: NSURLSession!

    class var instance: DownloadManager {

        struct Singleton {
            static var instance: DownloadManager?
            static var token: dispatch_once_t = 0
        }

        dispatch_once(&Singleton.token) {
            Singleton.instance = DownloadManager()
            Singleton.instance?.initSessionDownload()
        }

        return Singleton.instance!
    }

    class FileInformation: NSObject {

        /// Флаг окончания загрузки
        var downloadComplete: Bool!

        /// Название файла
        var fileName: String!

        /// Флаг загрузки
        var isDownloading: Bool!

        /// URL назначения
        var destinationUrl: NSURL!

        /// Блок процесса
        var progressBlock: ((progressPercentage: Int, fileInformation: FileInformation) -> Void)!

        /// Прогресс в процентах
        var progressPercentage = 0

        /// Блок ответа
        var responseBlock: ((error: NSError!, fileInformation: FileInformation) -> Void)!

        /// Задача
        var task: NSURLSessionDownloadTask!

        /// Данные приостановленной задачи
        // let taskResumeData: NSData!

        /// Источник
        var source: NSURL!

        /**
            Инициализирует класс заданными параметрами

            - parameter fileName: Название файла
            - parameter source: Ресурс
        */
        init(fileName: String, source: NSURL) {
            super.init()

            downloadComplete = false
            self.fileName = fileName
            isDownloading = false
            destinationUrl = nil
            self.source = source
        }
    }

    /**
        Отменяет задачу загрузки

        - parameter downloadTask: Задача загрузки
    */
    class func cancelDownloadTask(downloadTask: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownload.task.cancel()
        }
    }

    /**
        Инициализирует задачу загрузки

        - parameter fileName: Название файла
        - parameter destinationUrl: URL назначения
        - parameter sourceUrl: URL ресурса
        - parameter progressBlock: Блок обработки процесса загрузки
        - parameter responseBlock: Блок обработки ответа
    */
    class func download(fileName: String, destinationUrl: NSURL?, sourceUrl: NSURL,
        progressBlock: ((progressPercentage: Int, fileInformation: FileInformation) -> Void)?,
        responseBlock: (error: NSError!, fileInformation: FileInformation) -> Void) -> NSURLSessionDownloadTask {
            let newDownload = FileInformation(fileName: fileName, source: sourceUrl)
            newDownload.progressBlock = progressBlock
            newDownload.responseBlock = responseBlock

            if let errorDestination = setDestinationDownload(newDownload, destinationUrl: destinationUrl) {
                responseBlock(error: errorDestination, fileInformation: newDownload)

                return newDownload.task
            }

            newDownload.task = DownloadManager.instance.session.downloadTaskWithURL(newDownload.source)
            newDownload.task.resume()
            newDownload.isDownloading = true
            DownloadManager.instance.downloads.append(newDownload)

            return newDownload.task
    }

    /**
        Возвращает текущие загрузки

        - returns: Текущие загрузки
    */
    class func getCurrentDownloads() -> [FileInformation] {
        return DownloadManager.instance.downloads
    }

    /**
        Возвращает загрузку по идентификатору или nil

        - parameter id: Идентификатор загрузки

        - returns: Загрузка или nil
    */
    class func getFileInformationByTaskId(id: Int) -> FileInformation! {
        for currentDownload in DownloadManager.instance.downloads {
            if currentDownload.task.taskIdentifier == id {
                return currentDownload
            }
        }

        return nil
    }

    /**
        Приостанавливает задачу загрузки

        - parameter downloadTask: Задача загрузки
    */
    class func pauseDownloadTask(downloadTask: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownload.task.suspend()
            selectedDownload.isDownloading = false
            /*
                task.cancelByProducingResumeData { data in
                    selectedDownload.taskResumeData = data
                    selectedDownload.isDownloading = false
                }
            */
        }
    }

    /**
        Возобновляет приостановленную задачу загрузки

        - parameter task: Задача загрузки
    */
    class func resumeDownloadTask(downloadTask: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(downloadTask.taskIdentifier) {
            if !selectedDownload.isDownloading {
                /*
                    selectedDownload.task = Singleton.instance.session.downloadTaskWithResumeData(
                        selectedDownload.taskResumeData)
                    selectedDownload.taskResumeData = nil
                */
                selectedDownload.isDownloading = true
                selectedDownload.task.resume()
            }
        }
    }

    /**
        Устанавливает директорию назначения и возвращает возможную ошибку, иначе nil

        - parameter currentDownload: Текущая загрузка
        - parameter destinationUrl: URL назначения

        - returns Возможная ошибка, иначе nil
    */
    class func setDestinationDownload(currentDownload: FileInformation, destinationUrl: NSURL?) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        let documentDirectoryUrl = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as
            NSURL

        if destinationUrl == nil {
            currentDownload.destinationUrl = documentDirectoryUrl
                .URLByAppendingPathComponent("\(currentDownload.fileName)")
        } else {
            let url = documentDirectoryUrl.URLByAppendingPathComponent(destinationUrl!.path!)

            do {
                try fileManager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
                currentDownload.destinationUrl = url.URLByAppendingPathComponent(currentDownload.fileName)
            } catch let error as NSError {
                return error
            }
        }

        return nil
    }

    // MARK: - Методы NSURLSessionDelegate

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL
        location: NSURL) {
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
                selectedDownloadTask.task.cancel()
                saveDataTaskDownload(selectedDownloadTask, location: location)
                selectedDownloadTask.responseBlock(error: nil, fileInformation: selectedDownloadTask)
                let index = DownloadManager.instance.downloads.indexOf(selectedDownloadTask)
                DownloadManager.instance.downloads.removeAtIndex(index!)
            }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                // if selectedDownloadTask.taskResumeData == nil {
                selectedDownloadTask.task.cancel()
                selectedDownloadTask.responseBlock(error: error, fileInformation: selectedDownloadTask)
                let index = DownloadManager.instance.downloads.indexOf(selectedDownloadTask)
                DownloadManager.instance.downloads.removeAtIndex(index!)
                // }
            }
        }
    }

    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { _ in }
    }

    // MARK: - Методы NSURLSessionDownloadDelegate

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            if totalBytesExpectedToWrite == -1 {
                return
            }

            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
                let progressPercentage = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)

                if selectedDownloadTask.progressPercentage != progressPercentage {
                    selectedDownloadTask.progressPercentage = progressPercentage
                    selectedDownloadTask.progressBlock?(progressPercentage: progressPercentage, fileInformation:
                        selectedDownloadTask)
                }
            }
    }

    // MARK: - Внутренние методы

    private func initSessionDownload() {
        let sessionConfiguration: NSURLSessionConfiguration

        if #available(iOS 8.0, *) {
            sessionConfiguration = .backgroundSessionConfigurationWithIdentifier(identifierDownload)
        } else {
            sessionConfiguration = .defaultSessionConfiguration()
        }

        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 10
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    private func saveDataTaskDownload(currentDownload: FileInformation, location: NSURL) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        let url = currentDownload.destinationUrl

        if fileManager.fileExistsAtPath(url!.path!) {
            do {
                try fileManager.replaceItemAtURL(url!, withItemAtURL: location, backupItemName: nil, options:
                    .UsingNewMetadataOnly, resultingItemURL: nil)
            } catch let error as NSError {
                print(error)
            }
        } else {
            do {
                try fileManager.moveItemAtURL(location, toURL: url!)
            } catch let error as NSError {
                return error
            }
        }
        
        return nil
    }
}
