//
//  Flickr.swift
//  VirtualTourist
//
//  Created by pk on 2/25/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation

public class Flickr {
    
    enum Exception : Error {
        case ResponseJsonError
        case ResponseStatNotOK
    }
    
    static let REST_API_URL = "https://api.flickr.com/services/rest/"
    
    //https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
    static let PHOTO_URL_FORMAT = "https://farm%@.staticflickr.com/%@/%@_%@_t.jpg"
    
    static let shared = Flickr(apiKey: Bundle.main.object(forInfoDictionaryKey: "FlickrAPI") as! String)
    
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func executeRequest(request: NSMutableURLRequest, onData: @escaping ((Data)-> Data), callback: @escaping (Error?, [String: Any]?)->Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil {
                print(">>>Request Error - \(error)")
                callback(error, nil)
                return
            }
            
            var cbJson: [String: Any]! = nil
            var cbError: Error! = nil
            do {
                if let js = try JSONSerialization.jsonObject(with: onData(data!)) as? [String: Any] {
                    cbJson = js
                } else {
                    cbError = Exception.ResponseJsonError
                }
            } catch {
                print(">>>Parse Response Error - \(error)")
                cbError = error
            }
            callback(cbError, cbJson)
            
        }
        task.resume()
    }
    
    func newRequest(apiMethod: String, query: [String: Any]?) -> NSMutableURLRequest {
        let urlComponents = NSURLComponents(string: Flickr.REST_API_URL)!
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "method", value: apiMethod))
        queryItems.append(URLQueryItem(name: "format", value: "json"))
        queryItems.append(URLQueryItem(name: "api_key", value: self.apiKey))
        queryItems.append(URLQueryItem(name: "per_page", value: "100"))
        
        if let query = query {
            for (key, val) in query {
                queryItems.append(URLQueryItem(name: key, value: String(describing: val)))
            }
        }
        
        urlComponents.queryItems = queryItems
        return NSMutableURLRequest(url: urlComponents.url!)
    }

    
    func callRestApi(apiMethod: String, query: [String: Any]?, callback: @escaping (Error?, [String: Any]?)->Void) {
        let request = newRequest(apiMethod: apiMethod, query: query)
        executeRequest(request: request, onData: { data -> Data in
            return data.subdata(in: Range(uncheckedBounds: (14, data.count - 1)))
            
        }) { error, json in
            if error == nil && json!["stat"] as? String != "ok" {
                callback(Exception.ResponseStatNotOK, json)
            } else {
                callback(error, json)
            }
        }
    }
    
    static func getPhotoUrl(photo: [String: Any]) -> String {
        return String(
            format: Flickr.PHOTO_URL_FORMAT,
            String(photo["farm"] as? Int ?? 0),
            photo["server"] as? String ?? "",
            photo["id"] as? String ?? "",
            photo["secret"] as? String ?? ""
        )
    }
    
    func getPhotosByGeo(latitude: Double, longitude: Double, callback: @escaping (Error?, [[String: Any]]?)->Void) {
        callRestApi(
            apiMethod: "flickr.photos.search",
            query: [
                "lat": latitude,
                "lon": longitude,
                "content_type": 1
            ]
        ) { error, json in
            var photoList = [[String: Any]]()
            if error == nil {
                if let photos = json!["photos"] as? [String: Any], let _photoList = photos["photo"] as? [[String: Any]] {
                    for p in _photoList {
                        photoList.append([
                            "title" : p["title"] as? String ?? "",
                            "url": Flickr.getPhotoUrl(photo: p)
                        ])
                    }
                }
            }
            callback(error, photoList)
        }
    }
    
}
