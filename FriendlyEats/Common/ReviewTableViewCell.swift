//
//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase

class ReviewTableViewCell: UITableViewCell {

  @IBOutlet var usernameLabel: UILabel?
  @IBOutlet var reviewContentsLabel: UILabel!
  @IBOutlet var starsView: ImmutableStarsView!
  @IBOutlet weak var yumsLabel: UILabel!
  @IBOutlet weak var userIcon: UIImageView?
  @IBOutlet weak var yumButton: UIButton!
  @IBOutlet weak var restaurantNameLabel: UILabel?

  var review: Review!

  func populate(review: Review) {
    self.review = review
    restaurantNameLabel?.text = review.restaurantName
    usernameLabel?.text = review.userInfo.name
    userIcon?.sd_setImage(with: review.userInfo.photoURL)
    starsView.rating = review.rating
    reviewContentsLabel.text = review.text
    showYumText()
  }

  func showYumText() {
    switch review.yumCount {
    case 0:
      yumsLabel.isHidden = true
    case 1:
      yumsLabel.isHidden = false
      yumsLabel.text = "1 yum"
    default:
      yumsLabel.isHidden = false
      yumsLabel.text = "\(review.yumCount) yums"
    }
  }

  @IBAction func yumWasTapped(_ sender: Any) {
    let reviewReference = Firestore.firestore().collection("reviews").document(review.documentID)
    reviewReference.getDocument { (snapshot, error) in
      if let error = error {
        print("Got an error fetching the document: \(error)")
        return
      }
      guard let snapshot = snapshot else { return }
      guard let review = Review(document: snapshot) else { return }
      print("Right now, this review has \(review.yumCount) yums")
      let newYumCount = review.yumCount + 1
      // The rest of the code will go here!
      guard let currentUser = Auth.auth().currentUser else { return }
      // First we are going to write a simple "Yum" object into our subcollection...
      let newYum = Yum(documentID: currentUser.uid, username: currentUser.displayName ?? "Unknown user")
      let newYumReference = reviewReference.collection("yums").document(newYum.documentID)
      newYumReference.setData(newYum.documentData, completion: { (error) in
        if let error = error {
          print("Got an error adding the new yum document: \(error)")
        } else {
          print("Document set successfully")
          // TODO: Update the yumCount here
          reviewReference.updateData(["yumCount": newYumCount]) { (error) in
            if let error = error {
              print("Got an error updating the review count: \(error)")
            } else {
              print("yumCount incremented successfully")
            }
          }
        }
      })
    }
  }

}
