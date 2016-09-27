//
//  DownloadManager.swift
//  MisisBooks
//
//  Created by Maxim Loskov on 20.03.15.
//  Copyright (c) 2016 Maxim Loskov. All rights reserved.
//

import Foundation

class DownloadManager: NSObject, URLSessionDelegate {
    static let instance = DownloadManager()
    var downloads = [FileInformation]()
    let identifierDownload = "com.maximloskov.MisisBooks"
    var session: Foundation.URLSession!

    class FileInformation: NSObject {
        var downloadComplete: Bool!
        var fileName: String!
        var isDownloading: Bool!
        var destinationUrl: URL!
        var progressBlock: ((_ progressPercentage: Int, _ fileInformation: FileInformation) -> ())!
        var progressPercentage = 0
        var responseBlock: ((_ error: NSError?, _ fileInformation: FileInformation) -> ())!
        var task: URLSessionDownloadTask!
        // let taskResumeData: NSData!
        var source: URL!

        init(fileName: String, source: URL) {
            super.init()

            downloadComplete = false
            self.fileName = fileName
            isDownloading = false
            destinationUrl = nil
            self.source = source
        }
    }

    override init() {
        super.init()

        initSessionDownload()
    }

    class func cancelDownloadTask(_ downloadTask: URLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownload.task.cancel()
        }
    }

    class func download(_ fileName: String, destinationUrl: URL?, sourceUrl: URL,
                        progressBlock: ((_ progressPercentage: Int, _ fileInformation: FileInformation) -> ())?,
                        responseBlock: @escaping (_ error: NSError?, _ fileInformation: FileInformation) -> ())
        -> URLSessionDownloadTask {
            let newDownload = FileInformation(fileName: fileName, source: sourceUrl)
            newDownload.progressBlock = progressBlock
            newDownload.responseBlock = responseBlock

            if let errorDestination = setDestinationDownload(newDownload, destinationUrl: destinationUrl) {
                responseBlock(errorDestination, newDownload)

                return newDownload.task
            }

            newDownload.task = DownloadManager.instance.session.downloadTask(with: newDownload.source)
            newDownload.task.resume()
            newDownload.isDownloading = true
            DownloadManager.instance.downloads.append(newDownload)

            return newDownload.task
    }

    class func getCurrentDownloads() -> [FileInformation] {
        return DownloadManager.instance.downloads
    }

    class func getFileInformationByTaskId(_ id: Int) -> FileInformation! {
        for currentDownload in DownloadManager.instance.downloads {
            if currentDownload.task.taskIdentifier == id {
                return currentDownload
            }
        }

        return nil
    }

    class func pauseDownloadTask(_ downloadTask: URLSessionDownloadTask) {
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

    class func resumeDownloadTask(_ downloadTask: URLSessionDownloadTask) {
        if let selectedDownload = getFileInformationByTaskId(downloadTask.taskIdentifier) {
            if !selectedDownload.isDownloading {
                /*
                selectedDownload.task = Singleton.instance.session.downloadTaskWithResumeData(
                    selectedDownload.taskResumeData
                )
                selectedDownload.taskResumeData = nil
                */
                selectedDownload.isDownloading = true
                selectedDownload.task.resume()
            }
        }
    }

    class func setDestinationDownload(_ currentDownload: FileInformation, destinationUrl: URL?) -> NSError? {
        let fileManager = FileManager.default
        let documentDirectoryUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if destinationUrl == nil {
            currentDownload.destinationUrl = documentDirectoryUrl.appendingPathComponent(currentDownload.fileName)
        } else {
            let url = documentDirectoryUrl.appendingPathComponent(destinationUrl!.path)

            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                currentDownload.destinationUrl = url.appendingPathComponent(currentDownload.fileName)
            } catch let error as NSError {
                return error
            }
        }

        return nil
    }

    // MARK: - Методы NSURLSessionDelegate

    func URLSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURL
        location: URL) {
        if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
            selectedDownloadTask.task.cancel()
            _ = saveDataTaskDownload(selectedDownloadTask, location: location)
            selectedDownloadTask.responseBlock(nil, selectedDownloadTask)
            let index = DownloadManager.instance.downloads.index(of: selectedDownloadTask)
            DownloadManager.instance.downloads.remove(at: index!)
        }
    }

    func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(task.taskIdentifier) {
                // if selectedDownloadTask.taskResumeData == nil {
                selectedDownloadTask.task.cancel()
                selectedDownloadTask.responseBlock(error, selectedDownloadTask)
                let index = DownloadManager.instance.downloads.index(of: selectedDownloadTask)
                DownloadManager.instance.downloads.remove(at: index!)
                // }
            }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        session.getTasksWithCompletionHandler { _ in }
    }

    // MARK: - Методы NSURLSessionDownloadDelegate

    func URLSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite == -1 {
            return
        }

        if let selectedDownloadTask = DownloadManager.getFileInformationByTaskId(downloadTask.taskIdentifier) {
            let progressPercentage = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)

            if selectedDownloadTask.progressPercentage != progressPercentage {
                selectedDownloadTask.progressPercentage = progressPercentage
                selectedDownloadTask.progressBlock?(progressPercentage, selectedDownloadTask)
            }
        }
    }


    private func initSessionDownload() {
        let sessionConfiguration: URLSessionConfiguration

        if #available(iOS 8.0, *) {
            sessionConfiguration = .background(withIdentifier: identifierDownload)
        } else {
            sessionConfiguration = .default
        }

        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.httpMaximumConnectionsPerHost = 10
        session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    private func saveDataTaskDownload(_ currentDownload: FileInformation, location: URL) -> NSError? {
        let fileManager = FileManager.default
        let url = currentDownload.destinationUrl!

        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.replaceItem(at: url, withItemAt: location, backupItemName: nil,
                                            options: .usingNewMetadataOnly, resultingItemURL: nil)
            } catch let error as NSError {
                print(error)
            }
        } else {
            do {
                try fileManager.moveItem(at: location, to: url)
            } catch let error as NSError {
                return error
            }
        }
        
        return nil
    }
}
