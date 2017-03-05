//
//  CoreDataInterface.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/11/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit
import CoreData

/// Our Interface for the Core Data store, all functions relating to creating, updating, or deleting
///   entries in the Core Data store exist here
class CoreDataInterface {
 
   func getContext () -> NSManagedObjectContext {
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      return appDelegate.persistentContainer.viewContext
   }
 
   /**
    Stores a new best seller list name and encoded name in Core Data.
    
    - Parameters:
    - displayName: The display name of the list
    - encodedListName: The encoded name, used as a key and to retrieve list updates from the network
   */
   func storeBestSellerList(displayName : String, encodedListName: String) {
      
      // if the basic list information already exists in the database, no need to store it again
      if(self.listAlreadyExists(encodedListName: encodedListName)) {
         return
      }
      
      let managedContext = getContext()
      
      let entity =  NSEntityDescription.entity(forEntityName: "List", in: managedContext)
      let list = NSManagedObject(entity: entity!, insertInto: managedContext)
      
      list.setValue(displayName, forKey: "displayName")
      list.setValue(encodedListName, forKey: "listNameEncoded")
      
      //save the object
      do {
         try managedContext.save()
            print("saved: \(encodedListName)")
      } catch let error as NSError  {
            print("storeBestSellerList() - Error with save: \(error), \(error.userInfo)")
      } catch {
      }
   }
   
   /**
    Store a Book and it's relationship to the best seller list it falls under into Core Data
    
    - Parameters:
    - encodedListName: The key for the related List this Book object falls under
    - isbn13: The isbn13 value of the book, a unique value to each Book, used as a priamry key
    - title: The title of the book
    - author: The author of the book
    - description: The book's description
    - listRank: the rank of the book on it's given list
    - weeksOnlist: the number of weeks a book has been on it's best seller list
    - amazonLink: a link to the book on Amazon
    - reviewLink: a link to a NY Times review of the book
    - lastModified: a string which designates when the Book's list has last been modified.
    
    */
   func storeBookWithList(encodedListName: String, isbn13: String, title: String, author: String, description: String,
                          listRank: Int, weeksOnList: Int, amazonLink: String, reviewLink: String, lastModified: String) {

      let managedContext = getContext()
      
      var book: NSManagedObject

      let bookFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
      bookFetchRequest.predicate = NSPredicate(format: "%K == %@", "isbn13", isbn13)
      
      do {
         let fetchedResults = try managedContext.fetch(bookFetchRequest)
         
         // if the book already exists, we get it from our fetch request
         if(fetchedResults.count > 0) {
            book = fetchedResults[0] as! NSManagedObject
         } else {
            // book isn't already in the DB, so create a new one
            let bookEntity =  NSEntityDescription.entity(forEntityName: "Book", in: managedContext)
            book = NSManagedObject(entity: bookEntity!, insertInto: managedContext)
         }
         
         // either store or update values for our book
         book.setValue(isbn13, forKey: "isbn13")
         book.setValue(title, forKey: "title")
         book.setValue(author, forKey: "author")
         book.setValue(description, forKey: "bookDescription")
         book.setValue(listRank, forKey: "rank")
         book.setValue(weeksOnList, forKey: "weeksOnList")
         book.setValue(amazonLink, forKey: "amazonURL")
         book.setValue(reviewLink, forKey: "bookReviewURL")
         book.setValue(lastModified, forKey: "lastModified")

         // query for list the book in question falls under to properly store the relationship between the two
         let listFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"List")
         listFetchRequest.predicate = NSPredicate(format: "%K == %@", "listNameEncoded", encodedListName)
         
         // query for the associated best seller list to add the book to the list's set of Books
         let listFetchedResults = try managedContext.fetch(listFetchRequest)
            
         if (listFetchedResults.count > 0) {
            // should only be one list with the encoded name, store the relationship between the book and list
            let list : NSManagedObject = listFetchedResults[0] as! NSManagedObject
               
            let listBooks = list.mutableSetValue(forKey: "books")
            listBooks.add(book)
         }

         try managedContext.save()
         
      } catch {
         print("storeBookWithList() - Error: \(error)")
      }
   }
   
   /**
    Removes books from a list and deletes them from the core data store.  
      Useful when books fall off a best seller list.
    
    - Parameters:
    - encodedListName: The encoded name of the list, used as the primary key for the list object
    - lastModified: a string which designates when the Book's list has last been modified.
    */
   func removeBooksFromBestSellerList(encodedListName: String, lastModified: String) {
      
       let managedContext = getContext()
      
      // first, get the list in question
       let fetchRequest = NSFetchRequest<List>(entityName: "List")
       fetchRequest.predicate = NSPredicate(format: "%K == %@", "listNameEncoded", encodedListName)
       
       do {
         let fetchedResults = try managedContext.fetch(fetchRequest)
       
         if(fetchedResults.count > 0) {
            let list = fetchedResults[0]
            let books = list.books!.allObjects as! [Book]
            
            // if our list exists (which it should), lets go through it's Book set
            if(books.count > 0) {
               for book in books {
                  // if a book's last modified string differs from the list's, it means it no longer exists on
                  //  the list.  so delete the book.
                  if(book.lastModified != lastModified) {
                     managedContext.delete(book)
                  }
               }
            }
         
            try managedContext.save()
         }

      } catch {
         print("removeBooksFromBestSellerList() - Error with remove request: \(error)")
      }
   }
   
   /**
    Check if a book already exists in our Core Data store given it's primary key, the isbn13 value
    
    - Parameters:
    - isbn13: The primary key used for Book objects

    - Returns: a Bool that signals whether the book in question already exists in our Core Data store
    */
   func bookAlreadyExists(isbn13 : String) -> Bool {
      let managedContext = getContext()
      
      // query for object with specified encoded name to prevent unnecessary stores
      let bookFetch = NSFetchRequest<NSFetchRequestResult>(entityName:"Book")
      bookFetch.predicate = NSPredicate(format: "%K == %@", "isbn13", isbn13)
      
      do {
         let fetchedResults = try managedContext.fetch(bookFetch)
         
         if (fetchedResults.count > 0) {
            return true
         } else {
            return false
         }
      } catch {
         print("bookAlreadyExists() - Error with fetch request: \(error)")
      }
      
      return false

   }
   
   /** Retrieves the books for a given best seller list.
    
    - Parameters:
    - encodedListName: The encoded name of the list, used as the primary key for the list object

    - Returns: An array of Book objects that fall under the specified best seller list.
    */
   func fetchBooksForBestSellerList(encodedListName: String) -> [Book] {
      
      var books = [Book]()
      
      let managedContext = getContext()
      let fetchRequest = NSFetchRequest<List>(entityName: "List")
      fetchRequest.predicate = NSPredicate(format: "%K == %@", "listNameEncoded", encodedListName)
      
      do {
         let fetchedResults = try managedContext.fetch(fetchRequest)
         
         if(fetchedResults.count > 0) {
            let list = fetchedResults[0]
            books = list.books!.allObjects as! [Book]
            print(books)
            return books
         }
      } catch {
         print("fetchBooksForBestSellerList() - Error with fetch request: \(error)")
      }
      
      return books
   }
   
   /**
    Check if a list already exists in our Core Data store given it's primary key, the encoded name
    
    - Parameters:
    - encodedListName: The encoded name of the list, used as the primary key for the list object
    - lastModified: a string which designates when the Book's list has last been modified.

    - Returns: a Bool that signals whether the list in question should be updated.
    */
   func listAlreadyExists(encodedListName: String) -> Bool {
      let managedContext = getContext()
      
      // query for object with specified encoded name to prevent unnecessary stores
      let listFetch = NSFetchRequest<NSFetchRequestResult>(entityName:"List")
      listFetch.predicate = NSPredicate(format: "%K == %@", "listNameEncoded", encodedListName)
      
      do {
         let fetchedResults = try managedContext.fetch(listFetch)
         
         if (fetchedResults.count > 0) {
            return true
         } else {
            return false
         }
      } catch {
         print("listAlreadyExists() - Error with fetch request: \(error)")
      }
      
      return false

   }
   
   /** 
    Determine if a list should be updated given it's stored lastModified value compared to what is passed in.
    Useful for preventing unnecessary list updates in the database.
    
    - Parameters:
    - encodedListName: The encoded name of the list, used as the primary key for the list object
    - lastModified: a string which designates when the list has last been modified.

    - Returns: a Bool that signals whether the list in question should be updated
    */
   func shouldUpdateList(encodedListName : String, lastModified: String) -> Bool {
      let managedContext = getContext()
      
      // query for object with specified encoded name to prevent unnecessary stores
      let listFetch = NSFetchRequest<NSFetchRequestResult>(entityName:"List")
      listFetch.predicate = NSPredicate(format: "%K == %@", "listNameEncoded", encodedListName)

      do {
         let fetchedResults = try managedContext.fetch(listFetch)
         
         if (fetchedResults.count > 0) {
            
            // should only be one list with the encoded name.
            let list : NSManagedObject = fetchedResults[0] as! NSManagedObject
            
            // if the optional is nil, the list hasn't been updated yet. so return true
            guard let storedLastModified : String = list.value(forKey: "lastModified") as? String else {
               return true
            }
            
            // if our values don't match, the database copy needs to be updated
            if(lastModified != storedLastModified) {
               return true
            } else {
               return false
            }
         }
         
      } catch {
         print("shouldUpdateList() - Error with fetch request: \(error)")
         return false
      }
      
      // if we get here, something went wrong with the store, so don't update it.
      return false
   }
}
