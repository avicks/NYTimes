//
//  ListTableViewController.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/14/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit
import CoreData
import ReachabilitySwift

/// Our initial view controller, which will display the NY Times Best Seller Lists.
///   It does so via fetching results from the Core Data cache.  If no
class ListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
   
   var fetchedResultsController : NSFetchedResultsController<List>?
   var reachability : Reachability?
   var didUpdateLists : Bool = false
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.tableView.delegate = self
      
      // used to resize cells if the title label requires extra lines
      self.tableView.estimatedRowHeight = 44
      self.tableView.rowHeight = UITableViewAutomaticDimension
      self.tableView.setNeedsLayout()
      self.tableView.layoutIfNeeded()

      // set up our Reachability object, which handles network connectivity monitoring
      self.setUpReachAbility()
      
      
      // if we have connection, lets update the best seller lists
      if(reachability?.isReachable)! {
         self.getBestSellerLists()
      }

      // initialize our controller which loads data from the cache to display
      self.initializeFetchedResultsController()
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
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
   
         if(!self.didUpdateLists) {
            self.getBestSellerLists()
         }
      } else {
         print("Network not reachable")
      }
   }
   
   /**
    Update our list information via the API.  Once we succeed, refresh the UI.
    
    */
   func getBestSellerLists() {
      let networkInterface = NetworkInterface()
      networkInterface.getBestSellerLists() { success in
         if(success) {
            self.didUpdateLists = true
            self.tableView.reloadData()
         }
      }
      
   }

   // MARK: - NSFetchedResultsController methods
   func getContext () -> NSManagedObjectContext {
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      return appDelegate.persistentContainer.viewContext
   }
   
   /**
    Set up our FetchedController, which displays the data from our Core Data store on the table view.
    
    */
   func initializeFetchedResultsController() {
      let request = NSFetchRequest<List>(entityName: "List")
      let displayNameSort = NSSortDescriptor(key: "displayName", ascending: true)
      request.sortDescriptors = [displayNameSort]
      
      let managedContext = self.getContext()
      
      // initialize the controller with our fetch request for the List data
      fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                            managedObjectContext: managedContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
      fetchedResultsController?.delegate = self
      
      do {
         try fetchedResultsController?.performFetch()
         
         if(fetchedResultsController?.fetchedObjects?.count == 0) {
            if(reachability?.isReachable)! {
               // TO DO: handle lack of data and network connectivity
            } else {
               // TO DO: handle lack of data and network connectivity
            }
         }
         
      } catch {
         fatalError("Failed to initialize FetchedResultsController: \(error)")
      }
   }
   
   func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      tableView.beginUpdates()
   }
   
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      switch type {
      case .insert:
         guard let newIndexPath = newIndexPath else {
            fatalError("ListTableViewController: nil indexpath")
         }
         tableView.insertRows(at: [newIndexPath as IndexPath], with: .fade)
         
      case .update:
         guard let indexPath = indexPath,
            let list = anObject as? List else {
               fatalError("ListTableViewController: not enough data to update a cell")
         }
         let listCell = self.tableView(self.tableView, cellForRowAt: indexPath)
         listCell.configureCell(list: list)
         
      case .delete:
         guard let indexPath = indexPath else {
            fatalError("ListTableViewController: nil indexpath")
         }
         tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
         
      case .move:
         guard let newIndexPath = newIndexPath,
            let indexPath = indexPath else {
               fatalError("ListTableViewController: not enough data to move a cell")
         }
         tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
         tableView.insertRows(at: [newIndexPath as IndexPath], with: .fade)
      }
   }
   
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      tableView.endUpdates()
   }
   
   // MARK: - Table view data source
   override func numberOfSections(in tableView: UITableView) -> Int {
      
      if let fetchedResultsController = fetchedResultsController {
         return fetchedResultsController.sections!.count
      } else {
         return 0
      }
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      guard let fetchedResultsController = fetchedResultsController,
         let sections = fetchedResultsController.sections else {
            return 0
      }
      
      return sections[section].numberOfObjects
   }
   
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> ListTableViewCell {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "listCell") as? ListTableViewCell,
         let list = fetchedResultsController?.object(at: indexPath) else {
            fatalError("Unable to dequeue a cell")
      }
      
      cell.configureCell(list: list)
      
      return cell
   }
   
   // MARK: - Navigation
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
      if(segue.identifier == "bookListSegue") {
         
         // if we select a List, prepare to display it's Books on the next screen
         let booksListViewController : BooksListViewController = segue.destination as! BooksListViewController
         let selectedList = fetchedResultsController?.object(at: self.tableView.indexPathForSelectedRow!)
         
         var bookArray = selectedList?.books!.allObjects as! [Book]
         
         // lets sort the books before we hand them off
         if(bookArray.count > 1) {
            bookArray.sort{ $0.rank < $1.rank }
         }
         
         booksListViewController.listDisplayName = selectedList?.displayName
         booksListViewController.books = bookArray
         booksListViewController.listNameEncoded = selectedList?.listNameEncoded
      }
   }
}
