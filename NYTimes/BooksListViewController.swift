//
//  BooksListViewController.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/16/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit
import ReachabilitySwift

/// Our view controller to handle displaying a specific best seller list
class BooksListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var listDisplayName : String?
   var listNameEncoded : String?
   var books : [Book]?
   var reachability : Reachability?
   var didUpdateBooks : Bool = false
   
   @IBOutlet weak var sortBySegmentedControl: UISegmentedControl!
   @IBOutlet weak var booksTableView: UITableView!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.title = listDisplayName
      
      self.setUpReachAbility()
      
      self.booksTableView.delegate = self
      self.booksTableView.dataSource = self
      
      // used to resize cells if the title label requires extra lines
      self.booksTableView.estimatedRowHeight = 80
      self.booksTableView.rowHeight = UITableViewAutomaticDimension
      self.booksTableView.setNeedsLayout()
      self.booksTableView.layoutIfNeeded()
      
      // set up our segment control which handles how a user wishes to sort the list
      self.sortBySegmentedControl.addTarget(self, action: #selector(BooksListViewController.sortBooks),
                                            for: .valueChanged)
      
      // if the list did not supply it's books, go get them
      if(self.books?.count == 0) {
         self.getBooksInList()
      }
   }
   
   /**
    Set up our Reachability object to handle network connectivity monitoring.
    If the network reachbility changes, we'll handle it via a notification.
    
    */
   func setUpReachAbility() {
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      self.reachability = appDelegate.reachability
      
      NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
      
   }
   
   /**
    If network connectivity changes, we handle it here.  Useful when we lack recent data yet and the app
    allows connectivity for the first time.
    
    - Parameters:
    - note: The NSnotification which triggered the function to be called
    */
   func reachabilityChanged(note: NSNotification) {
      
      let reachability = note.object as! Reachability
      
      if(reachability.isReachable) {
         print("Network is reachable")
         
         // if we haven't already retrieved our books, lets go get them
         if(!self.didUpdateBooks && self.books?.count == 0) {
            self.getBooksInList()
         }
      } else {
         print("Network not reachable")
      }
   }
   
   
   /**
    Retrieve the most recent book information for our list.
    
    */
   func getBooksInList() {
      let networkInterface = NetworkInterface()
      
      guard let listNameEncoded = self.listNameEncoded else {
         print("uh oh..we don't have a list name?")
         return
      }
      
      // retrieve the most best seller list book data from the API
      networkInterface.getBooksInBestSellerList(encodedListName: listNameEncoded) { (success) in
         if(success) {
            self.didUpdateBooks = true
            
            // if we succeeded, fetch the books from the database and refresh the UI to reflect the changes.
            let coreDataInterface = CoreDataInterface()
            self.books = coreDataInterface.fetchBooksForBestSellerList(encodedListName: self.listNameEncoded!)
            self.sortBooks()
            self.booksTableView.reloadData()
         }
      }
   }
   
   /**
    Handle how we should sort the books before displaying them.
    
    */
   func sortBooks() {
      if(sortBySegmentedControl.selectedSegmentIndex == 0) {
         self.sortByRank()
         self.booksTableView.reloadData()
      } else {
         self.sortByWeeksOnList()
         self.booksTableView.reloadData()
      }
      
   }
   
   /**
    Sort our books given their rank in the list.
    
    */
   func sortByRank() {
      self.books?.sort{ $0.rank < $1.rank }
   }
   
   /**
    Sort our books given the amount of weeks they've been on the list.
    
    */
   func sortByWeeksOnList() {
      self.books?.sort{ $0.weeksOnList > $1.weeksOnList }
   }
   
   // MARK: - Table view data source
   func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if let books = self.books {
         return books.count
      } else {
         return 0
      }
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell") as? BookTableViewCell,
         let book = books?[indexPath.row] else {
            fatalError("Unable to dequeue a cell")
      }
      
      cell.configureCell(book: book)
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      // when a cell is selected, make sure the cell doesn't stay selected after the segue
      tableView.deselectRow(at: indexPath, animated: true)
   }
   
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
      // prepare to display the book information on the next view
      if(segue.identifier == "bookDetailSegue") {
         let bookDetailViewController = segue.destination as! BookDetailViewController
         
         let selectedBook = self.books?[(self.booksTableView.indexPathForSelectedRow?.row)!]
         
         bookDetailViewController.bookTitle = selectedBook?.title
         bookDetailViewController.author = selectedBook?.author
         bookDetailViewController.amazonURL = selectedBook?.amazonURL
         bookDetailViewController.reviewURL = selectedBook?.bookReviewURL
         bookDetailViewController.bookDescription = selectedBook?.bookDescription
         
      }
      
      
   }
   
}
