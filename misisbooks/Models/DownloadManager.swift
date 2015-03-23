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
    var downloads = [DownloadFileInformation]()
    
    /// Сессия
    var session : NSURLSession!
    
    /// Идентификатор загрузки
    let identifierDownload = "com.maximloskov.misisbooks"
    
    /// Путь к директории
    let pathDirectory = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as? NSURL
    
    
    class DownloadFileInformation : NSObject {
        
        /// Название файла
        var fileName : String!
        
        /// Источник
        var source : NSURL!
        
        /// Задача
        var task : NSURLSessionDownloadTask!
        
        /// Данные задачи
        var taskResumeData : NSData!
        
        /// Флаг загрузки
        var isDownloading : Bool!
        
        /// Флаг окончания загрузки
        var downloadComplete : Bool!
        
        /// Путь к директории
        var pathDestination : NSURL!
        
        /// Блок прогресса
        var progressBlockCompletion : ((bytesWritten: Int64, bytesExpectedToWrite: Int64, downloadFileInformation: DownloadFileInformation) -> Void)!
        
        /// Блок ответа
        var responseBlockCompletion : ((error: NSError!, downloadFileInformation: DownloadFileInformation) -> Void)!
        
        
        /// Инициализирует класс заданными параметрами
        ///
        /// :param: book Книга
        /// :param: fileName Название файла
        /// :param: source Ресурс
        init(fileName: String, source: NSURL) {
            super.init()
            
            self.fileName = fileName
            self.source = source
            self.pathDestination = nil
            self.isDownloading = false
            self.downloadComplete = false
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
    
    private func saveDataTaskDownload(currentDownload: DownloadFileInformation, location: NSURL) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        let pathData = currentDownload.pathDestination
        var error: NSError? = NSError()
        
        if fileManager.fileExistsAtPath(pathData!.path!) == true {
            if fileManager.replaceItemAtURL(pathData!, withItemAtURL: location, backupItemName: nil, options: NSFileManagerItemReplacementOptions.UsingNewMetadataOnly, resultingItemURL: nil, error: &error) == false {
                println(error)
            }
        } else if fileManager.moveItemAtURL(location, toURL: pathData!, error: &error) == false {
            return error
        }
        
        return nil
    }
    
    class func setDestinationDownload(currentDownload: DownloadFileInformation, urlDestination: NSURL?) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        
        if urlDestination == nil {
            currentDownload.pathDestination = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)[0] as? NSURL
            currentDownload.pathDestination = currentDownload.pathDestination?.URLByAppendingPathComponent("\(currentDownload.fileName)")
        } else {
            var error: NSError? = NSError()
            var path = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)[0] as? NSURL
            path = path?.URLByAppendingPathComponent(urlDestination!.path!)
            
            if fileManager.createDirectoryAtURL(path!, withIntermediateDirectories: true, attributes: nil, error: &error) == true {
                currentDownload.pathDestination = path?.URLByAppendingPathComponent(currentDownload.fileName)
            } else {
                return error
            }
        }
        
        return nil
    }
    
    /// MARK: Методы NSURLSessionDelegate
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { (dataTask: [AnyObject]!, uploadTask: [AnyObject]!, downloadTask: [AnyObject]!) -> Void in }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            if let selectedDownloadTask = DownloadManager.getTaskByIdentifier(task.taskIdentifier) {
                selectedDownloadTask.task.cancel()
                selectedDownloadTask.responseBlockCompletion(error: error, downloadFileInformation: selectedDownloadTask)
                var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
                Singleton.sharedInstance.downloads.removeAtIndex(index!)
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let selectedDownloadTask = DownloadManager.getTaskByIdentifier(downloadTask.taskIdentifier) {
            selectedDownloadTask.task.cancel()
            saveDataTaskDownload(selectedDownloadTask, location: location)
            selectedDownloadTask.responseBlockCompletion(error: nil, downloadFileInformation: selectedDownloadTask)
            var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
            Singleton.sharedInstance.downloads.removeAtIndex(index!)
        }
    }
    
    /// MARK: Методы NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let selectedDownloadTask = DownloadManager.getTaskByIdentifier(downloadTask.taskIdentifier) {
            selectedDownloadTask.progressBlockCompletion?(bytesWritten: totalBytesWritten,
                bytesExpectedToWrite: totalBytesExpectedToWrite, downloadFileInformation: selectedDownloadTask)
        }
    }
    
    /// MARK: Методы для управления загрузками
    
    // Возвращает задачу по идентификатору
    private class func getTaskByIdentifier(identifier: Int) -> DownloadFileInformation! {
        var selectedDownload: DownloadFileInformation! = nil
        
        for currentDownload in Singleton.sharedInstance.downloads {
            if (currentDownload as DownloadFileInformation).task.taskIdentifier == identifier {
                selectedDownload = currentDownload
                return selectedDownload
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
    private class func downloadFile(fileName: String, sourceUrl: NSURL, destination: NSURL?, progressBlockCompletion progressBlock: ((bytesWritten: Int64, bytesExpectedToWrite: Int64, downloadFileInformation: DownloadFileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, downloadFileInformation: DownloadFileInformation) -> Void)) -> NSURLSessionDownloadTask {
        var newDownload = DownloadFileInformation(fileName: fileName, source: sourceUrl)
        newDownload.progressBlockCompletion = progressBlock
        newDownload.responseBlockCompletion = responseBlock
        
        if let errorDestination = setDestinationDownload(newDownload, urlDestination: destination) {
            responseBlock(error: errorDestination, downloadFileInformation: newDownload)
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
    class func download(fileName: String, sourceUrl: NSURL, progressBlockCompletion progressBlock:((bytesWritten: Int64, bytesExpectedToWrite: Int64, downloadFileInformation: DownloadFileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, downloadFileInformation: DownloadFileInformation) -> Void)) -> NSURLSessionDownloadTask {
        return downloadFile(fileName, sourceUrl: sourceUrl, destination: nil, progressBlockCompletion: progressBlock, responseBlockCompletion: responseBlock)
    }
    
    /// Создает новый запрос для загрузки
    ///
    /// :param: fileName Название файла загрузки
    /// :param: downloadSource URL
    /// :param: pathDestination Путь к директории назначения
    /// :param: progressBlockCompletion Блок прогресса
    /// :param: responseBlockCompletion Блок ответа
    class func download(fileName: String, sourceUrl: NSURL, destination: NSURL, progressBlockCompletion progressBlock: ((bytesWritten: Int64, bytesExpectedToWrite: Int64, downloadFileInformation: DownloadFileInformation) -> Void)?, responseBlockCompletion responseBlock: ((error: NSError!, downloadFileInformation: DownloadFileInformation) -> Void)) -> NSURLSessionDownloadTask {
        return downloadFile(fileName, sourceUrl: sourceUrl, destination: destination, progressBlockCompletion: progressBlock, responseBlockCompletion: responseBlock)
    }
    
    /// Приостанавливает загрузку
    ///
    /// :param: Задача загрузки
    class func pauseDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = self.getTaskByIdentifier(task.taskIdentifier) {
            //selectedDownload.downloadTask.suspend()
            selectedDownload.isDownloading = false
            task.cancelByProducingResumeData { (data: NSData!) -> Void in
                selectedDownload.taskResumeData = data
                selectedDownload.isDownloading = false
            }
        }
    }
    
    /// Возобновляет приостановленную загрузку
    ///
    /// :param: Задача загрузки
    class func resumeDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getTaskByIdentifier(task.taskIdentifier) {
            if selectedDownload.isDownloading == false {
                selectedDownload.task = Singleton.sharedInstance.session.downloadTaskWithResumeData(selectedDownload.taskResumeData)
                selectedDownload.isDownloading = true
                selectedDownload.task.resume()
            }
        }
    }
    
    /// Отменяет загрузку
    ///
    /// :param: Задача загрузки
    class func cancelDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getTaskByIdentifier(task.taskIdentifier) {
            selectedDownload.task.cancel()
        }
    }
}