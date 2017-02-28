//
//  PhotoDownloader.swift
//  VirtualTourist
//
//  Created by pk on 2/25/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation

//Thread-Safe
class PhotoDownloader {
    static let shared = PhotoDownloader(numConcurrentTasks: 3)
    
    private struct DownloadItem {
        let url: String
        let ctx: Any
        let onCompleted: (_: Data?, _: Any) -> Void
        
        init(url: String, ctx: Any, onCompleted: @escaping (_: Data?, _: Any) -> Void) {
            self.url = url
            self.ctx = ctx
            self.onCompleted = onCompleted
        }
    }
    
    let numConcurrentTasks: Int
    private var curConcurrentTasks: Int = 0
    private var list = [DownloadItem]()
    
    init(numConcurrentTasks: Int) {
        self.numConcurrentTasks = numConcurrentTasks
    }
    
    func download(url: String, ctx: Any, onComplete: @escaping (_: Data?, _: Any) -> Void) {
        let downloadItem = DownloadItem(url: url, ctx: ctx, onCompleted: onComplete)
        
        DispatchQueue.main.async {
            self.appendTask(downloadItem: downloadItem)
            self.dispatchTask()
        }
    }
    
    func download(urlList: [String], ctxList: [Any], onComplete: @escaping (_: Data?, _: Any) -> Void) {
        DispatchQueue.main.async {
            let lastIndex = urlList.count - 1
            for i in 0...lastIndex {
                let downloadItem = DownloadItem(url: urlList[i], ctx: ctxList[i], onCompleted: onComplete)
                self.appendTask(downloadItem: downloadItem)
            }
            self.dispatchTask()
        }
    }
    
    private func appendTask(downloadItem: DownloadItem) {
        list.append(downloadItem)
    }
    
    private func dispatchTask() {
        if curConcurrentTasks < numConcurrentTasks && list.count > 0 {
            curConcurrentTasks += 1
            let downloadItem = list.remove(at: 0)
            //print("->>>> download \(downloadItem.url)")
            self.executeTask(downloadItem: downloadItem)
        }
    }
    
    private func executeTask(downloadItem: DownloadItem) {
        let req = URLRequest(url: URL(string: downloadItem.url)!)
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            self.onCompleted(downloadItem: downloadItem, data: data)
        }.resume()
    }
    
    private func onCompleted(downloadItem: DownloadItem, data: Data?) {
        DispatchQueue.main.async {
            //print("->>>> completed \(downloadItem.url)")
            self.curConcurrentTasks -= 1
            self.dispatchTask()
        }
        downloadItem.onCompleted(data, downloadItem.ctx)
    }
    
}
