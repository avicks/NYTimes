//
//  ListTableViewCell.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/15/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import UIKit

/// Our custom table cell for the NYTimes Best Seller Lists
class ListTableViewCell: UITableViewCell {

   @IBOutlet weak var displayNameLabel: UILabel!
   
   /**
    Configure a cell for display.
    
    - Parameters:
    - list: The list object associated with this given cell
    */
   func configureCell(list: List) {
      displayNameLabel.text = list.displayName
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
