//
//  LazyRestaurantTableViewDataSource.swift
//  FriendlyEats
//
//  Created by Fumiya Yamanaka on 2019/03/31.
//  Copyright © 2019 Firebase. All rights reserved.
//

import UIKit
import Firebase

@objc class LazyRestaurantTableViewDataSource: NSObject, UITableViewDataSource {

  private var isFetchingUpdates = false
  private var restaurants: [Restaurant] = []
  private var documents: [QueryDocumentSnapshot] = []
  private let updateHandler: () -> ()
  private let query: Query

  public init(query: Query, updateHandler: @escaping () -> ()) {
    self.query = query
    self.updateHandler = updateHandler
  }

  public func fetchNext() {
    // 1. Add these four lines here
    if isFetchingUpdates {
      return
    }
    isFetchingUpdates = true
    let nextQuery: Query
    if let lastDocument = documents.last {
      nextQuery = query.start(afterDocument: lastDocument).limit(to: 50)
    } else {
      nextQuery = query.limit(to: 50)
    }

    nextQuery.getDocuments { (querySnapshot, error) in
      guard let snapshot = querySnapshot else {
        // 2. Add this line next
        self.isFetchingUpdates = false
        print("Error fetching next documents: \(error!)")
        return
      }

      let newRestaurants = snapshot.documents.map { doc -> Restaurant in
        guard let restaurant = Restaurant(document: doc) else {
          fatalError("Error serializing restaurant with document snapshot: \(doc)")
        }
        return restaurant
      }

      self.restaurants += newRestaurants
      self.documents += snapshot.documents
      self.updateHandler()

      // 3. Add this line at the end
      self.isFetchingUpdates = false
    }
  }

  /// Returns the restaurant after the given index.
  public subscript(index: Int) -> Restaurant {
    return restaurants[index]
  }

  /// The number of items in the data source.
  public var count: Int {
    return restaurants.count
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell",
                                             for: indexPath) as! RestaurantTableViewCell
    let restaurant = restaurants[indexPath.row]
    cell.populate(restaurant: restaurant)
    return cell
  }

}
