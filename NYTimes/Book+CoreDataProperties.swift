//
//  Book+CoreDataProperties.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/14/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book");
    }

    @NSManaged public var amazonURL: String?
    @NSManaged public var author: String?
    @NSManaged public var bookDescription: String?
    @NSManaged public var bookReviewURL: String?
    @NSManaged public var isbn13: String?
    @NSManaged public var lastModified: String?
    @NSManaged public var rank: Int32
    @NSManaged public var title: String?
    @NSManaged public var weeksOnList: Int32
    @NSManaged public var list: List?

}
