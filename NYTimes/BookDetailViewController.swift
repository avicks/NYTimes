//
//  BookDetailViewController.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/16/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit

/// Our view controller that handles display of an individual Book object's information
class BookDetailViewController: UIViewController {

   var bookTitle : String?
   var author : String?
   var bookDescription : String?
   var reviewURL : String?
   var amazonURL : String?
   
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var authorLabel: UILabel!
   @IBOutlet weak var descriptionLabel: UILabel!
   
   @IBOutlet weak var reviewButton: UIButton!
   @IBOutlet weak var purchaseLinkButton: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.titleLabel.text = bookTitle
      self.authorLabel.text = author
      self.descriptionLabel.text = bookDescription
      
      // if the book has an amazon review URL, set up our button that will link the user to the product URL
      if(amazonURL != "") {
         self.setUpPurchaseButton()
      }
      
      // if the book has a review URL, set up our button that will link the user to the review
      if(reviewURL != "") {
         self.setUpReviewButton()
      }
   }
   
   /**
    Display and enable our button that links to the amazon URL associated with this book.
    
    */
   func setUpPurchaseButton() {
      self.purchaseLinkButton.isEnabled = true
      self.purchaseLinkButton.isHidden = false
      self.purchaseLinkButton.addTarget(self, action: #selector(self.purchaseButtonWasClicked), for: .touchUpInside)
   }
   
   /**
    Handle the purchase button being tapped by opening the amazon URL in Safari.
    
    */
   func purchaseButtonWasClicked() {
      UIApplication.shared.open(URL(string: amazonURL!)!, options: [:], completionHandler: nil)
   }
   
   /**
    Display and enable our button that links to the book review URL associated with this book.
    
    */
   func setUpReviewButton() {
      self.reviewButton.isEnabled = true
      self.reviewButton.isHidden = false
      self.reviewButton.addTarget(self, action: #selector(self.reviewButtonWasClicked), for: .touchUpInside)
   }
   
   /**
    Handle the review button being tapped by opening the review URL in Safari.
    
    */
   func reviewButtonWasClicked() {
      UIApplication.shared.open(URL(string: reviewURL!)!, options: [:], completionHandler: nil)

   }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
