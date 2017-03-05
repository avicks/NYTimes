//
//  List+CoreDataProperties.swift
//  NYTimes
//
//  Created by Alex Vickers on 11/14/16.
//  Copyright © 2016 skciva. All rights reserved.
//

import Foundation
import CoreData


extension List {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<List> {
        return NSFetchRequest<List>(entityName: "List");
    }

    @NSManaged public var displayName: String?
    @NSManaged public var lastModified: String?
    @NSManaged public var listNameEncoded: String?
    @NSManaged public var books: NSSet?

}

// MARK: Generated accessors for books
extension List {

    @objc(addBooksObject:)
    @NSManaged public func addToBooks(_ value: Book)

    @objc(removeBooksObject:)
    @NSManaged public func removeFromBooks(_ value: Book)

    @objc(addBooks:)
    @NSManaged public func addToBooks(_ values: NSSet)

    @objc(removeBooks:)
    @NSManaged public func removeFromBooks(_ values: NSSet)

}
