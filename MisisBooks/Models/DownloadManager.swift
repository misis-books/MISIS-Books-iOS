//
//  DownloadManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 20.03.15.
//  Copyright (c) 2015 Maxim Loskov. All rights reserved.
//

import Foundation

/// Класс для управления загрузками
class DownloadManager: NSObject, NSURLSessionDelegate {
    
    /// Загрузки
    var downloads = [FileInformation]()
    
    /// Идентификатор загрузки
    let identifierDownload = "com.maximloskov.misisbooks"
    
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
        
        /// Путь к директории
        var pathDestination: NSURL!
        
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
        
        /// Инициализирует класс заданными параметрами
        ///
        /// :param: fileName Название файла
        /// :param: source Ресурс
        init(fileName: String, source: NSURL) {
            super.init()
            
            downloadComplete = false
            self.fileName = fileName
            isDownloading = false
            pathDestination = nil
            self.source = source
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
    
    /// Инициализирует загрузку
    ///
    /// :param: fileName Название файла
    /// :param: destination Директория назначения
    /// :param: sourceUrl URL ресурса
    /// :param: progressBlock Блок прогресса
    /// :param: responseBlock Блок ответа
    class func download(fileName: String, destination: NSURL?, sourceUrl: NSURL,
        progressBlock: ((progressPercentage: Int, fileInformation: FileInformation) -> Void)?,
        responseBlock: (error: NSError!, fileInformation: FileInformation) -> Void) -> NSURLSessionDownloadTask {
            let newDownload = FileInformation(fileName: fileName, source: sourceUrl)
            newDownload.progressBlock = progressBlock
            newDownload.responseBlock = responseBlock
            
            if let errorDestination = setDestinationDownload(newDownload, urlDestination: destination) {
                responseBlock(error: errorDestination, fileInformation: newDownload)
                
                return newDownload.task
            }
            
            newDownload.task = DownloadManager.instance.session.downloadTaskWithURL(newDownload.source, completionHandler: nil)
            newDownload.task.resume()
            newDownload.isDownloading = true
            DownloadManager.instance.downloads.append(newDownload)
            
            return newDownload.task
    }
    
    /// Возвращает текущие загрузки
    ///
    /// :returns: Текущие загрузки
    class func getCurrentDownloads() -> [FileInformation] {
        
        return DownloadManager.instance.downloads
    }
    
    /// Возвращает задачу или nil по идентификатору
    ///
    /// :param: id Идентификатор задачи
    /// :returns: Задача или nil
    class func getFileInformationByTaskId(id: Int) -> FileInformation! {
        for currentDownload in DownloadManager.instance.downloads {
            if currentDownload.task.taskIdentifier == id {
                return currentDownload
            }
        }
        
        return nil
    }
    
    /// Приостанавливает загрузку
    ///
    /// :param: Задача загрузки
    class func pauseDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(task.taskIdentifier) {
            selectedDownload.task.suspend()
            selectedDownload.isDownloading = false
            /* task.cancelByProducingResumeData { data in
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
                // selectedDownload.task = Singleton.instance.session.downloadTaskWithResumeData(selectedDownload.taskResumeData)
                // selectedDownload.taskResumeData = nil
                selectedDownload.isDownloading = true
                selectedDownload.task.resume()
            }
        }
    }
    
    /// Устанавливает директорию назначения
    ///
    /// :param: currentDownload Текущая загрузка
    /// :param: urlDestination Директория назначения
    class func setDestinationDownload(currentDownload: FileInformation, urlDestination: NSURL?) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        
        if urlDestination == nil {
            let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL
            currentDownload.pathDestination = urls!.URLByAppendingPathComponent("\(currentDownload.fileName)")
        } else {
            var error: NSError?
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
    
    /// MARK: Методы NSURLSessionDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownloadTask.task.cancel()
            saveDataTaskDownload(selectedDownloadTask, location: location)
            selectedDownloadTask.responseBlock(error: nil, fileInformation: selectedDownloadTask)
            let index = find(DownloadManager.instance.downloads, selectedDownloadTask)
            DownloadManager.instance.downloads.removeAtIndex(index!)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                // if selectedDownloadTask.taskResumeData == nil {
                selectedDownloadTask.task.cancel()
                selectedDownloadTask.responseBlock(error: error, fileInformation: selectedDownloadTask)
                let index = find(DownloadManager.instance.downloads, selectedDownloadTask)
                DownloadManager.instance.downloads.removeAtIndex(index!)
                // }
            }
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { dataTask, uploadTask, downloadTask -> Void in }
    }
    
    /// MARK: Методы NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            if totalBytesExpectedToWrite == -1 {
                return
            }
            
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
                let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let progressPercentage = Int(progress * 100)
                
                if selectedDownloadTask.progressPercentage != progressPercentage {
                    selectedDownloadTask.progressPercentage = progressPercentage
                    selectedDownloadTask.progressBlock?(
                        progressPercentage: progressPercentage,
                        fileInformation: selectedDownloadTask
                    )
                }
            }
    }
    
    /// MARK: - Внутренние методы
    
    private func initSessionDownload() {
        let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifierDownload)
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 10
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    private func saveDataTaskDownload(currentDownload: FileInformation, location: NSURL) -> NSError? {
        let fileManager = NSFileManager.defaultManager()
        let url = currentDownload.pathDestination
        var error: NSError?
        
        if fileManager.fileExistsAtPath(url!.path!) == true {
            if !fileManager.replaceItemAtURL(url!, withItemAtURL: location, backupItemName: nil, options: .UsingNewMetadataOnly, resultingItemURL: nil, error: &error) {
                println(error)
            }
        } else if !fileManager.moveItemAtURL(location, toURL: url!, error: &error) {
            return error
        }
        
        return nil
    }
}
