//
//  FacebookNetworking.swift
//  DSFacebookImagePicker
//
//  Created by Home on 2014-10-13.
//  Copyright (c) 2014 Sanche. All rights reserved.
//

import UIKit

class FacebookNetworking: NSObject {
  
  
  class func getAlbumList(completionHandler:([PhotoAlbum]?, NSError?)->()){
    //attempt log in
    if(!isLoggedIn()){
      logIn({ (session, error) -> Void in
        if error != nil{
          completionHandler(nil, error)
        } else {
          self.getAlbumList(completionHandler)
        }
      })
      return
    }
    FBRequestConnection.startWithGraphPath("me/albums?limit=1000", {connection, result, error in
      
      if let json = result as? NSDictionary{
        var albumList = [PhotoAlbum]()
        
        for thisAlbumDict in json.objectForKey("data") as NSArray{
          let newAlbum = PhotoAlbum(json:thisAlbumDict as NSDictionary)
          albumList.append(newAlbum)
        }
        
        completionHandler(albumList, error)
        
      } else {
        completionHandler(nil, error)
      }
    })
  }
  
  
  class func getImagesFromAlbumID(albumID:String, photoCount:Int=100, completionHandler:([Photo]?, NSError?)->()){
    //attempt log in
    if(!isLoggedIn()){
      logIn({ (session, error) -> Void in
        if error != nil{
          completionHandler(nil, error)
        } else {
          self.getImagesFromAlbumID(albumID, photoCount:photoCount, completionHandler:completionHandler)
        }
      })
      return
    }
    FBRequestConnection.startWithGraphPath("\(albumID)/photos?limit=\(photoCount)", {connection, result, error in
      
      if let json = result as? NSDictionary{
        
        /*
        if let nextString = json["paging"]!["next"] as String?{
          let nextUrl = NSURL(string: nextString)
          println(nextUrl)
          let nextJson = NSDictionary(contentsOfURL:nextUrl)
          
        }*/
        
        var photoList = [Photo]()
        
        for thisPhotoDict in json["data"] as NSArray {
          let newPhoto = Photo(json:thisPhotoDict as NSDictionary)
          photoList.append(newPhoto)
        }
        
        completionHandler(photoList, error)
        
      } else {
        completionHandler(nil, error)
      }
    })
  }
  
  
  
  class func missingPermissions() -> [String]?{
    
    var permissions : [String] = [String]()
    
    let currentPermissions : [String] = FBSession.activeSession().permissions as [String]
    
    let requiredPerimissions = ["user_photos"]
    
    for thisPermission in requiredPerimissions{
      if(!contains(currentPermissions, thisPermission)){
        permissions.append(thisPermission)
      }
    }
    if(permissions.isEmpty){
      return nil
    } else {
      println(permissions)
      return permissions
    }
  }
  
  class func isLoggedIn() -> Bool{
    let session = FBSession.activeSession()
    if(!session.isOpen){
      return false
    } else if missingPermissions() != nil{
      return false
    } else {
      return true
    }
  }
  
  class func logIn(handler:FBSessionRequestPermissionResultHandler){
    
    let session = FBSession.activeSession()
    
    if(session.isOpen){
      if let permissions = missingPermissions(){
        FBSession.activeSession().requestNewReadPermissions(permissions, handler)
      }
    } else {
      FBSession.openActiveSessionWithReadPermissions(missingPermissions(), allowLoginUI:true, completionHandler: { session, state, error in
        handler(session, error)
      })
    }
  }
  
  class func findBestImageURL(imageOptionsArray:NSArray, minImageSize:Int=100) -> NSURL?{
    let sortDescriptor = NSSortDescriptor(key:"height", ascending: true)
    let sortedArray = imageOptionsArray.sortedArrayUsingDescriptors([sortDescriptor]) as [NSDictionary]
    
    for thisDict in sortedArray{
      let height = thisDict["height"] as Int
      if(height > minImageSize){
        let URLString = thisDict["source"] as String
        return NSURL(string:URLString)
      }
    }
    return nil
  }
  
  
  
}
