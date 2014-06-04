//
//  Post.swift
//  Reddit Scan Swift
//
//  Created by Hector Rodriguez on 6/3/14.
//  Copyright (c) 2014 Hector Rodriguez. All rights reserved.
//

import UIKit

class Post {
    let title : String
    let author : String
    let thumbnailURL : String
    let postURL : String
    
    init(title:String, author : String, thumbnailURL : String, postURL : String){
        self.title = title
        self.author = author
        self.thumbnailURL = thumbnailURL
        self.postURL = postURL
    }
    
}
