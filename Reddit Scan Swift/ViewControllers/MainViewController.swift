//
//  MainViewController.swift
//  Reddit Scan Swift
//
//  Created by Hector Rodriguez on 6/3/14.
//  Copyright (c) 2014 Hector Rodriguez. All rights reserved.
//

import UIKit

class MainViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIAlertViewDelegate{
    
    var searchBar : UISearchBar = UISearchBar()
    var results : Post[] = []
    var postsTableView : UITableView = UITableView()
    var shareCard = UIView() 
    var imageCache : NSCache = NSCache()
    var refreshControl : UIRefreshControl = UIRefreshControl()
    var dimmer : UIView = UIView()
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named:"bg.png"))
        
        var yOffset : CGFloat = 20
        let width = self.view.frame.width
        
        //Overlay Image
        let overlay = UIImageView(frame:CGRectMake(0, yOffset, width, self.view.frame.size.height-yOffset))
        overlay.image = UIImage(named:"overlay.png")
        
        //Black search bar initialized with 'funny'
        self.searchBar = UISearchBar(frame: CGRectMake(0, yOffset, width, 40))
        self.searchBar.delegate = self
        self.searchBar.barStyle = .Black
        self.searchBar.text = "funny"
        
        yOffset += self.searchBar.frame.height
        
        //UITableView with keyboard dismiss on drag
        postsTableView = UITableView(frame:CGRectMake(0, yOffset, width-20, self.view.frame.height-yOffset))
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.backgroundColor = UIColor.clearColor()
        postsTableView.keyboardDismissMode = .OnDrag
        
        
        
        //Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("getResultsAndLoadTableView"), forControlEvents: .ValueChanged)
        postsTableView.addSubview(refreshControl)
        
        //Share card initialized off screen
        let ratio : CGFloat = 402.0 / 566.0
        let height : CGFloat = ratio * (width-50.0)
        shareCard = ShareCard(frame: CGRectMake(width, self.view.frame.height, width-50, height), parent: self)
        
        self.view.addSubview(overlay)
        self.view.addSubview(searchBar)
        self.view.addSubview(postsTableView)
        self.view.addSubview(shareCard)
        
        //Initialize results
        self.getResultsAndLoadTableView()
        
    }
    
    func getResultsAndLoadTableView(){
        
        
        results = []
        let subreddit = self.searchBar.text
        
        println(subreddit)
        
        let validString = validateString(subreddit)
        
        if validString {
            
            let urlAsString = "http://www.reddit.com/r/\(subreddit)/.json"
            let url = NSURL(string:urlAsString)
            
            //Asynchronously load posts
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),{
            
                let data = NSData(contentsOfURL: url)
                if data != nil {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: nil) as NSDictionary
                        if(jsonObject != nil){
                            let data = jsonObject["data"] as NSDictionary
                            let children = data["children"] as NSArray
                            for object : AnyObject in children {
                                let child = object as NSDictionary
                                let item : NSDictionary = child["data"] as NSDictionary
                                
                                //We have a post, lets create an object and add it to the array of results
                                let title = item["title"] as String
                                let author = item["author"] as String
                                let thumbnailURL = item["thumbnail"] as String
                                var postURL = item["permalink"] as String
            
                                postURL = "www.reddit.com\(postURL)"
                                
                                let post = Post(title: title, author: author, thumbnailURL: thumbnailURL, postURL: postURL)
                                self.results += post
                            }
                            self.postsTableView.reloadData()
                            self.refreshControl.endRefreshing()
                        }else{
                            dispatch_async(dispatch_get_main_queue(), {
                                self.retrievedNothingAlertWithTitle("Nothing Here", message:"Maybe this isn't a Subreddit, try again.")
                                })
                        }
                        })
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        self.retrievedNothingAlertWithTitle("Nothing Here", message:"Maybe this isn't a Subreddit, try again.")
                        })
                }
                })
            
        }else{
            retrievedNothingAlertWithTitle("Invalid Subreddit Name", message:"Must contain letters, numbers, or '_'.\nMust not start with '_'.\nMust not be longer than 21 characters.")
        }
    }
    
    //Only letters, numbers, '_' as long as '_' is not
    //the first character, and less than or equal to 22 character
    //https://github.com/reddit/reddit/blob/master/r2/r2/lib/validator/validator.py#L526
    func validateString(string : String) -> Bool{
        let pattern = "[A-Za-z0-9][A-za-z0-9_]{2,20}"
        
        let test = NSPredicate(format: "SELF MATCHES %@", pattern)
        return test.evaluateWithObject(string)
        
    }
    
    //Used when the search result returns nothing
    func retrievedNothingAlertWithTitle(title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let alertAction = UIAlertAction(title: "OK", style: .Cancel, handler:nil)
        
        alert.addAction(alertAction)
        self.presentModalViewController(alert, animated: true)
        postsTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let kCellIdentifier = "Cell"
        
        let post = results[indexPath.row]
        
        var cell = CellView(style: .Subtitle, reuseIdentifier: kCellIdentifier, parent: self)
        cell.setPost(post)
        
        if cell == nil {
            cell = CellView(style: .Subtitle, reuseIdentifier: kCellIdentifier, parent: self)
        }

        
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        self.showShareCard()
        let post = results[indexPath.row]
        let shareCard = self.shareCard as ShareCard
        shareCard.setPost(post)
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        // check here, if it is one of the cells, that needs to be resized
        // to the size of the contained UITextView
        let post = results[indexPath.row]
        let title = NSString(string:post.title)
        let maximumLabelSize = CGSizeMake(self.view.frame.size.width-85,9999)

        let textRect : CGRect = title.boundingRectWithSize(maximumLabelSize, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(12)], context: nil)

    
        return textRect.height + CGFloat(50)
    }
    
    //Make the status bar white
    override func preferredStatusBarStyle() -> UIStatusBarStyle{
        return .LightContent
    }
    
    //Handles search button tapped action
    func searchBarSearchButtonClicked(intstanceSearchBar : UISearchBar){
        self.getResultsAndLoadTableView()
        intstanceSearchBar.resignFirstResponder()
    }
    
    //Animate the share card into the view
    func showShareCard(){
        
    self.dimmer = UIView(frame: self.view.frame)
    self.dimmer.backgroundColor = UIColor(patternImage : UIImage(named: "dimmer"))
    self.dimmer.alpha = 0.95
    self.view.addSubview(self.dimmer)
        
    self.view.bringSubviewToFront(self.shareCard)
        
        UIView.animateWithDuration(0.3, delay: 0, options:.BeginFromCurrentState,
            animations: {
                UIView.setAnimationCurve(.Linear)
                let xOffsetShareCard = (self.view.frame.width - self.shareCard.frame.width)/2.0
                let yOffsetShareCard = (self.view.frame.height - self.shareCard.frame.height)/2.0
                
                self.shareCard.frame = CGRectMake(xOffsetShareCard, yOffsetShareCard, self.shareCard.frame.width, self.shareCard.frame.height)

            },
            completion: nil)
    }

    
    /*
    // #pragma mark - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
