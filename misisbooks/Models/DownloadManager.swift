//
//  DownloadManager.swift
//  misisbooks
//
//  Created by Maxim Loskov on 20.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

/// Класс для управления загрузками
class DownloadManager : NSObject, NSURLSessionDelegate {
    
    /// Загрузки
    var downloads = [FileInformation]()
    
    /// Сессия
    var session : NSURLSession!
    
    /// Идентификатор загрузки
    let identifierDownload = "com.maximloskov.misisbooks"
    
    /// Путь к директории
    let pathDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as? NSURL
    
    
    class FileInformation : NSObject {
        
        /// Название файла
        var fileName : String!
        
        /// Источник
        var source : NSURL!
        
        /// Задача
        var task : NSURLSessionDownloadTask!
        
        /// Данные задачи
        // var taskResumeData : NSData!
        
        /// Флаг загрузки
        var isDownloading : Bool!
        
        /// Флаг окончания загрузки
        var downloadComplete : Bool!
        
        /// Путь к директории
        var pathDestination : NSURL!
        
        /// Прогресс в процентах
        var progressPercentage = 0
        
        /// Блок прогресса
        var progressBlockCompletion : ((progressPercentage: Int, fileInformation: FileInformation) -> Void)!
        
        /// Блок ответа
        var responseBlockCompletion : ((error: NSError!, fileInformation: FileInformation) -> Void)!
        
        
        /// Инициализирует класс заданными параметрами
        ///
        /// :param: book Книга
        /// :param: fileName Название файла
        /// :param: source Ресурс
        init(fileName: String, source: NSURL) {
            super.init()
            
            self.fileName = fileName
            self.source = source
            pathDestination = nil
            isDownloading = false
            downloadComplete = false
        }
    }
    
    private class Singleton {
        
        class var sharedInstance : DownloadManager {
            
            struct Static {
                static var instance : DownloadManager?
                static var token : dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token) {
                Static.instance = DownloadManager()
                Static.instance?.initSessionDownload()
            }
            
            return Static.instance!
        }
    }
    
    private func initSessionDownload() {
        let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifierDownload)
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 10
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    private func saveDataTaskDownload(currentDownload: FileInformation, location: NSURL) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        let pathData = currentDownload.pathDestination
        var error: NSError? = NSError()
        
        if fileManager.fileExistsAtPath(pathData!.path!) == true {
            if !fileManager.replaceItemAtURL(pathData!, withItemAtURL: location, backupItemName: nil, options: .UsingNewMetadataOnly, resultingItemURL: nil, error: &error) {
                println(error)
            }
        } else if !fileManager.moveItemAtURL(location, toURL: pathData!, error: &error) {
            return error
        }
        
        return nil
    }
    
    class func setDestinationDownload(currentDownload: FileInformation, urlDestination: NSURL?) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        
        if urlDestination == nil {
            currentDownload.pathDestination = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL
            currentDownload.pathDestination = currentDownload.pathDestination?.URLByAppendingPathComponent("\(currentDownload.fileName)")
        } else {
            var error: NSError? = NSError()
            var path = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL
            path = path?.URLByAppendingPathComponent(urlDestination!.path!)
            
            if fileManager.createDirectoryAtURL(path!, withIntermediateDirectories: true, attributes: nil, error: &error) {
                currentDownload.pathDestination = path?.URLByAppendingPathComponent(currentDownload.fileName)
            } else {
                return error
            }
        }
        
        return nil
    }
    
    /// Возвращает текущие загрузки
    ///
    /// :returns: Текущие загрузки
    class func getCurrentDownloads() -> [FileInformation] {
        return Singleton.sharedInstance.downloads
    }
    
    /// MARK: Методы NSURLSessionDelegate
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { (dataTask: [AnyObject]!, uploadTask: [AnyObject]!, downloadTask: [AnyObject]!) -> Void in }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if error != nil {
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                // if selectedDownloadTask.taskResumeData == nil {
                selectedDownloadTask.task.cancel()
                selectedDownloadTask.responseBlockCompletion(error: error, fileInformation: selectedDownloadTask)
                var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
                Singleton.sharedInstance.downloads.removeAtIndex(index!)
                // }
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownloadTask.task.cancel()
            saveDataTaskDownload(selectedDownloadTask, location: location)
            selectedDownloadTask.responseBlockCompletion(error: nil, fileInformation: selectedDownloadTask)
            var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
            Singleton.sharedInstance.downloads.removeAtIndex(index!)
        }
    }
    
    /// MARK: Методы NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            let progressPercentage = Int(progress * 100)
            
            if selectedDownloadTask.progressPercentage != progressPercentage {
                selectedDownloadTask.progressPercentage = progressPercentage
                selectedDownloadTask.progressBlockCompletion?(
                    progressPercentage: progressPercentage,
                    fileInformation: selectedDownloadTask
                )
            }
        }
    }
    
    /// MARK: Методы для управления загрузками
    
    // Возвращает задачу по идентификатору
    class func getFileInformationByTaskId(identifier: Int) -> FileInformation! {
        for currentDownload in Singleton.sharedInstance.downloads {
            if (currentDownload as FileInformation).task.taskIdentifier == identifier {
                return currentDownload
            }
        }
        
        return nil
    }
    
    /// Загружает файл
    ///
    /// :param: fileName Название файла загрузки
    /// :param: sourceUrl URL ресурса
    /// :param: destination Путь к директории назначения
    /// :param: progressBlockCompletion Блок прогресса
    /// :param: responseBlockCompletion Блок ответа
    private class func downloadFile(fileName: String, sourceUrl: NSURL, destination: NSURL?, progressBlockCompletion progressBlock: ((progressPercentage: Int, fileInformation: FileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, fileInformation: FileInformation) -> Void)) -> NSURLSessionDownloadTask {
        var newDownload = FileInformation(fileName: fileName, source: sourceUrl)
        newDownload.progressBlockCompletion = progressBlock
        newDownload.responseBlockCompletion = responseBlock
        
        if let errorDestination = setDestinationDownload(newDownload, urlDestination: destination) {
            responseBlock(error: errorDestination, fileInformation: newDownload)
            
            return newDownload.task
        }
        
        newDownload.task = Singleton.sharedInstance.session.downloadTaskWithURL(newDownload.source, completionHandler: nil)
        newDownload.task.resume()
        newDownload.isDownloading = true
        Singleton.sharedInstance.downloads.append(newDownload)
        
        return newDownload.task
    }
    
    /// Создает новый запрос для загрузки
    ///
    /// :param: fileName Название файла загрузки
    /// :param: downloadSource URL
    /// :param: progressBlockCompletion Блок прогресса
    /// :param: responseBlockCompletion Блок ответа
    class func download(fileName: String, sourceUrl: NSURL, progressBlockCompletion progressBlock:((progressPercentage: Int, fileInformation: FileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, fileInformation: FileInformation) -> Void)) -> NSURLSessionDownloadTask {
        return downloadFile(
            fileName,
            sourceUrl: sourceUrl,
            destination: nil,
            progressBlockCompletion: progressBlock,
            responseBlockCompletion: responseBlock
        )
    }
    
    /// Создает новый запрос для загрузки
    ///
    /// :param: fileName Название файла загрузки
    /// :param: downloadSource URL
    /// :param: pathDestination Путь к директории назначения
    /// :param: progressBlockCompletion Блок прогресса
    /// :param: responseBlockCompletion Блок ответа
    class func download(fileName: String, sourceUrl: NSURL, destination: NSURL, progressBlockCompletion progressBlock: ((progressPercentage: Int, fileInformation: FileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, fileInformation: FileInformation) -> Void)) -> NSURLSessionDownloadTask {
        return downloadFile(
            fileName,
            sourceUrl: sourceUrl,
            destination: destination,
            progressBlockCompletion: progressBlock,
            responseBlockCompletion: responseBlock
        )
    }
    
    /// Приостанавливает загрузку
    ///
    /// :param: Задача загрузки
    class func pauseDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(task.taskIdentifier) {
            selectedDownload.task.suspend()
            selectedDownload.isDownloading = false
            /* task.cancelByProducingResumeData {
                (data: NSData!) -> Void in
                selectedDownload.taskResumeData = data
                selectedDownload.isDownloading = false
            } */
            
            
        }
    }
    
    /// Возобновляет приостановленную загрузку
    ///
    /// :param: Задача загрузки
    class func resumeDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(task.taskIdentifier) {
            if selectedDownload.isDownloading == false {
                // selectedDownload.task = Singleton.sharedInstance.session.downloadTaskWithResumeData(selectedDownload.taskResumeData)
                // selectedDownload.taskResumeData = nil
                selectedDownload.isDownloading = true
                selectedDownload.task.resume()
            }
        }
    }
    
    /// Отменяет загрузку
    ///
    /// :param: Задача загрузки
    class func cancelDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(task.taskIdentifier) {
            selectedDownload.task.cancel()
        }
    }
}
