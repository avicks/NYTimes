//
//  BookTableViewCell.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/15/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit

/// Our custom table view cell for a best seller list Book entry
class BookTableViewCell: UITableViewCell {

   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var weeksOnListLabel: UILabel!
   @IBOutlet weak var rankLabel: UILabel!
   
   /**
    Configure a cell for display.
    
    - Parameters:
    - book: The Book object associated with this given cell
    */
   func configureCell(book : Book) {
      titleLabel.text = book.title
      weeksOnListLabel.text = "\(book.weeksOnList)"
      rankLabel.text = "\(book.rank)"
   }
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
