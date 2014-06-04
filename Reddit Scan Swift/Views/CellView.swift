//
//  CellView.swift
//  Reddit Scan Swift
//
//  Created by Hector Rodriguez on 6/3/14.
//  Copyright (c) 2014 Hector Rodriguez. All rights reserved.
//

import UIKit
import ObjectiveC

class CellView: UITableViewCell {
    
    var parent = UIViewController()

    init(style: UITableViewCellStyle, reuseIdentifier: String, parent : MainViewController) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.parent = parent
        self.backgroundColor = UIColor.clearColor()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPost (post : Post){
        var yOffset : CGFloat = 5
        var xOffset : CGFloat = 20
        
        //Image associated with post
        var thumbnailView = UIImageView(frame:CGRectMake(xOffset, yOffset, 50, 50))
        
        //Get image from either cache or asynchronously
        setImage(post.thumbnailURL, thumbnailView:thumbnailView)
        
        xOffset += thumbnailView.frame.size.width + 5
        var width = self.frame.size.width - xOffset
        
        //Add the lable for the author using the provided font
        var authorLabel = UILabel(frame:CGRectMake(xOffset, yOffset, width, 22))
        authorLabel.text = post.author
        authorLabel.textColor = UIColor(red:54.0/255.0, green:145.0/255.0, blue:255.0/255.0, alpha:1)
        authorLabel.font = UIFont(name: "bebasneue", size: 22)
        yOffset += authorLabel.frame.size.height+5
        
        //Set the size for the title frame
        var maximumLabelSize = CGSizeMake(width-15,9999)
        var title = NSString(string:post.title)
        
        var textRect : CGRect = title.boundingRectWithSize(maximumLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(12)], context: nil)
        
        //Add the title
        var titleLabel = UILabel(frame:CGRectMake(xOffset, yOffset, textRect.width, textRect.height))
        titleLabel.text = post.title
        titleLabel.font = UIFont.systemFontOfSize(12)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleLabel.numberOfLines = 0
        
        self.addSubview(thumbnailView)
        self.addSubview(authorLabel)
        self.addSubview(titleLabel)
    }

    //Pull the images from a cache if possible.
    //If not, asynchronously load image and store it in cache
    func setImage(url : String, thumbnailView : UIImageView){
        var parent = self.parent as MainViewController
        if parent.imageCache.objectForKey(url) != nil{
            var thumbnail = parent.imageCache.objectForKey(url) as UIImage
            thumbnailView.image = thumbnail
    
    
            //Shadow is added to the UIImageView
            var shadowPath = UIBezierPath(rect: thumbnailView.bounds)
            thumbnailView.layer.masksToBounds = false
            thumbnailView.layer.shadowColor = UIColor.blackColor().CGColor
            thumbnailView.layer.shadowOffset = CGSizeMake(0, 5)
            thumbnailView.layer.shadowOpacity = 0.5
            thumbnailView.layer.shadowPath = shadowPath.CGPath
        }else{
            //Asynchronously load images
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),{
    
                var data = NSData(contentsOfURL: NSURL(string:url))
    
                dispatch_async(dispatch_get_main_queue(), {
                    var thumbnail = UIImage(data: data)
                    if thumbnail != nil {
                        parent.imageCache.setObject(thumbnail, forKey: url)
                        thumbnailView.image = thumbnail
                    }
                    })
                })
        }
    }

}
