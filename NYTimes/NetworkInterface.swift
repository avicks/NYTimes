//
//  NetworkInterface.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/11/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/// Our interface for all network calls to retrieve list and book data 
class NetworkInterface {
   
   private let baseURL : String = "https://api.nytimes.com/svc/books/v3/lists/"
   private let apiKey : String = ""
   
   /**
    Retrieves all best seller lists.  First, we get the basic information for each list.  We then store
    the lists, and finally retrieve the books for the lists.
    
    - Parameters:
    - completionBlock: A boolean value which signals if the function completed successfully
    */
   func getBestSellerLists(completionBlock: @escaping (Bool) -> ()) {
      
      let url = baseURL + "names.json?api-key=" + apiKey
      
      Alamofire.request(url)
         .responseJSON { response in
            
            guard response.result.isSuccess else {
               print("getBestSellerLists() - Request failed: \(response.result.error)")
               return completionBlock(false)
            }
            
            guard let responseJSON = response.result.value else {
               print("getBestSellerLists() - Invalid JSON response.")
               return completionBlock(false)
            }
            
            let json = JSON(responseJSON)
            
            let listResults : [JSON]
            if(json["results"].null != nil) {
               listResults = [JSON].init()
            } else {
               listResults = json["results"].array!
            }
            
            print("json results- \(listResults)")
            
            // once we have the best seller list information, store it
            self.storeBestSellerLists(listData: listResults)

            completionBlock(true)
            return
         }
   }
   
   /**
    Retrieve the books for a given best seller list.  Once we get them, store them.
    
    - Parameters:
    - encodedListName: The encoded name, used as a key and to retrieve list updates from the network
    - completionBlock: A boolean value which signals if the function completed successfully
    */
   func getBooksInBestSellerList(encodedListName: String, completionBlock: @escaping (Bool) -> ()) {
      let url = baseURL + "/.json?api-key=" + apiKey + "&list-name=" + encodedListName
      
      Alamofire.request(url)
         .responseJSON { response in
            guard response.result.isSuccess else {
               print("getBooksInBestSellerList(), list \(encodedListName) - Request failed: \(response.result.error)")
               return completionBlock(false)
            }
            
            guard let responseJSON = response.result.value else {
               print("getBooksInBestSellerList(), list \(encodedListName) - Invalid JSON response.")
               return completionBlock(false)
            }
            
            let json = JSON(responseJSON)
            
            let lastModified : String
            if(json["last_modified"].null != nil) {
               lastModified = ""
            } else {
               lastModified = json["last_modified"].string!
            }
            
            let listResults : [JSON]
            if(json["results"].null != nil) {
               listResults = [JSON].init()
            } else {
               listResults = json["results"].array!
            }
            
            
            self.storeBooksForBestSellerList(encodedListName: encodedListName,
                                             lastModified: lastModified,
                                             listData: listResults)
            completionBlock(true)
            return
      }
   }
   
   /**
    Pass the basic best seller list information along to the Core Data cache.
    
    - Parameters:
    - listData: The list's information, specifically it's encoded name and display name
    */
   func storeBestSellerLists(listData: [JSON]) {
      for json in listData {
         
         let displayName : String
         if(json["display_name"].null != nil) {
            displayName = ""
         } else {
            displayName = json["display_name"].string!
         }
         
         let encodedName : String
         if(json["list_name_encoded"].null != nil) {
            encodedName = ""
         } else {
            encodedName = json["list_name_encoded"].string!

         }

         let coreDataInterface = CoreDataInterface()
         coreDataInterface.storeBestSellerList(displayName: displayName, encodedListName: encodedName)
         
         self.getBooksInBestSellerList(encodedListName: encodedName) { (success) in
            if(success) {
               print("\(encodedName) books stored")
            } else {
               print("\(encodedName) failed to store books")
            }
         }
      }
   }
   
   /**
    Pass the books for a given best seller list to the Core Data database for storage.
    
    - Parameters:
    - encodedListName: The encoded name, used as a key and to retrieve list updates from the network
    - lastModified: A value that signals when the list has last been updated
    - listData: The data containing our list's books
    */
   func storeBooksForBestSellerList(encodedListName : String, lastModified: String, listData: [JSON]) {
      
      let coreDataInterface = CoreDataInterface()
      
      // check if our list has been updated since the last local update
      if(coreDataInterface.shouldUpdateList(encodedListName: encodedListName, lastModified: lastModified)) {

         for json in listData {
            // make sure none of our data is null...
            let isbn13 : String
            if(json["book_details"][0]["primary_isbn13"].null != nil) {
               isbn13 = ""
            } else {
               isbn13 = json["book_details"][0]["primary_isbn13"].string!
            }
            
            let author : String
            if(json["book_details"][0]["author"].null != nil) {
               author = ""
            } else {
               author = json["book_details"][0]["author"].string!
            }
            
            let title : String
            if(json["book_details"][0]["title"].null != nil) {
               title = ""
            } else {
               title = json["book_details"][0]["title"].string!

            }

            let description : String
            if(json["book_details"][0]["description"].null != nil) {
               description = ""
            } else {
               description = json["book_details"][0]["description"].string!
            }
            
            let amazonURL : String
            if(json["amazon_product_url"].null != nil) {
               amazonURL = ""
            } else {
               amazonURL = json["amazon_product_url"].string!
            }
            
            let reviewURL : String
            if(json["reviews"][0]["book_review_link"].null != nil) {
               reviewURL = ""
            } else {
               reviewURL = json["reviews"][0]["book_review_link"].string!
            }
            
            let rank : Int
            if(json["rank"].null != nil) {
               rank = 999
            } else {
               rank = json["rank"].int!
            }
            
            let weeksOnList : Int
            if(json["weeks_on_list"].null != nil) {
               weeksOnList = 0
            } else {
               weeksOnList = json["weeks_on_list"].int!
            }
            
            // store the books in the cache
            coreDataInterface.storeBookWithList(encodedListName: encodedListName, isbn13: isbn13, title: title, author: author, description: description, listRank: rank, weeksOnList: weeksOnList, amazonLink: amazonURL, reviewLink: reviewURL, lastModified: lastModified)
         }
         
         // after storing new books / updating old ones, remove ones which were not updated (as that means they no longer
         //  exist on the list)
         coreDataInterface.removeBooksFromBestSellerList(encodedListName: encodedListName, lastModified: lastModified)
      }
   }
}
