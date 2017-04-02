//
//  PinCommon.swift
//  VirtualTourist
//
//  Created by pk on 3/10/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import CoreData

class PinCommon {
    
    let dataStack: CoreDataStack
    
    init(dataStack: CoreDataStack) {
        self.dataStack = dataStack
    }
    
    func fetchPhotosForPin(pin: Pin, pageNum: Int, numPerPage: Int) {
        if pin.state == Pin.State.Deleted.rawValue { return }
        
        pin.state = Pin.State.LinksLoading.rawValue
        pin.stateDate = NSDate()
        
        var pageNum = pageNum
        if pageNum <= 0 {
            pageNum = 1
            let totalPages = (min(Int(pin.totalPhotos), 4000) +  numPerPage - 1) / numPerPage
            if totalPages > 0 {
                pageNum = Int(arc4random_uniform(UInt32(totalPages))) + 1
            }
        }
        print(">fetching photos: page number[\(pageNum)]")
        
        Flickr.shared.getPhotosByGeo(latitude: pin.latitude, longitude: pin.longitude, numPerPage: numPerPage, pageNum: pageNum) { (error, total, photos) in
            DispatchQueue.main.async {
                if pin.state == Pin.State.Deleted.rawValue { return }
                
                if error != nil {
                    pin.totalPhotos = 0
                    pin.state = Pin.State.Created.rawValue
                } else {
                    self.addPhotosForPin(pin: pin, photos: photos!)
                    pin.totalPhotos = Int32(total)
                    pin.state = Pin.State.LinksLoaded.rawValue
                }
                
                try! self.dataStack.context.save()
            }
        }
    }
    
    func reloadIncompletedPhotosForPin(pin: Pin) {
        var urlList = [String]()
        var ctxList = [Any]()
        for photo in pin.photos! {
            if let photo = photo as? Photo,
                photo.state == Photo.State.Loading.rawValue && photo.stateDate!.timeIntervalSinceNow < -30.0
            {
                photo.stateDate = NSDate()
                urlList.append(photo.url!)
                ctxList.append(photo.objectID)
            }
        }
        
        if !urlList.isEmpty {
            PhotoDownloader.shared.download(
                urlList: urlList,
                ctxList: ctxList,
                onComplete: onCompleted
            )
            print(">>Reload Incompleted Photos - count:\(urlList.count)")
        }

    }
    
    func addPhotosForPin(pin: Pin, photos: [[String: Any]]) {
        var urlList = [String]()
        var ctxList = [Any]()
        for p in photos {
            let photo = Photo(context: dataStack.context)
            photo.title = p["title"] as? String
            photo.url = p["url"] as? String
            photo.id = p["id"] as? String
            photo.state = Photo.State.Loading.rawValue
            photo.stateDate = NSDate()
            pin.addToPhotos(photo)
            
            urlList.append(photo.url!)
            ctxList.append(photo.objectID)
        }
        
        if !urlList.isEmpty {
            PhotoDownloader.shared.download(
                urlList: urlList,
                ctxList: ctxList,
                onComplete: onCompleted
            )
            print(">>Add download - count:\(urlList.count)")
        }
    }
    
    func onCompleted(_ data: Data?, _ ctx: Any) -> Void {
        DispatchQueue.main.async {
            let photo = self.dataStack.context.object(with: ctx as! NSManagedObjectID) as! Photo
            if photo.id != nil {
                photo.state = Photo.State.Loaded.rawValue
                if let imageData = data as NSData? {
                    photo.setImage(imageData: imageData)
                } else {
                    photo.delete()
                }
            }
        }
        
    }

}
