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
        
        var yOffset : CGFloat = 20;
        var width = self.view.frame.width
        
        //Overlay Image
        var overlay = UIImageView(frame:CGRectMake(0, yOffset, width, self.view.frame.size.height-yOffset))
        overlay.image = UIImage(named:"overlay.png")
        
        //Black search bar initialized with 'funny'
        self.searchBar = UISearchBar(frame: CGRectMake(0, yOffset, width, 40))
        self.searchBar.delegate = self
        self.searchBar.barStyle = UIBarStyle.Black
        self.searchBar.text = "funny"
        
        yOffset += self.searchBar.frame.height;
        
        //UITableView with keyboard dismiss on drag
        postsTableView = UITableView(frame:CGRectMake(0, yOffset, width-20, self.view.frame.height-yOffset))
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.backgroundColor = UIColor.clearColor()
        postsTableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        
        
        
        //Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("getResultsAndLoadTableView"), forControlEvents: UIControlEvents.ValueChanged)
        postsTableView.addSubview(refreshControl)
        
        //Share card initialized off screen
        var ratio : CGFloat = 402.0 / 566.0
        var height : CGFloat = ratio * (width-50.0)
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
        var subreddit = self.searchBar.text;
        
        println(subreddit)
        
        var validString = validateString(subreddit)
        
        if validString {
            
            var urlAsString = "http://www.reddit.com/r/\(subreddit)/.json"
            var url = NSURL(string:urlAsString)
            
            //Asynchronously load posts
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),{
            
                var data = NSData(contentsOfURL: url)
                if data != nil {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        var jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: nil) as NSDictionary
                        if(jsonObject != nil){
                            var data = jsonObject["data"] as NSDictionary
                            var children = data["children"] as NSArray
                            for object : AnyObject in children {
                                let child = object as NSDictionary
                                let item : NSDictionary = child["data"] as NSDictionary
                                
                                //We have a post, lets create an object and add it to the array of results
                                var title = item["title"] as String
                                var author = item["author"] as String
                                var thumbnailURL = item["thumbnail"] as String
                                var postURL = item["permalink"] as String
            
                                postURL = "www.reddit.com\(postURL)"
                                
                                var post = Post(title: title, author: author, thumbnailURL: thumbnailURL, postURL: postURL)
                                self.results.append(post)
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
                });
            
        }else{
            retrievedNothingAlertWithTitle("Invalid Subreddit Name", message:"Must contain letters, numbers, or '_'.\nMust not start with '_'.\nMust not be longer than 21 characters.")
        }
    }
    
    //Only letters, numbers, '_' as long as '_' is not
    //the first character, and less than or equal to 22 character
    //https://github.com/reddit/reddit/blob/master/r2/r2/lib/validator/validator.py#L526
    func validateString(string : String) -> Bool{
        var pattern = "[A-Za-z0-9][A-za-z0-9_]{2,20}"
        
        var test = NSPredicate(format: "SELF MATCHES %@", pattern)
        return test.evaluateWithObject(string)
        
    }
    
    //Used when the search result returns nothing
    func retrievedNothingAlertWithTitle(title : String, message : String){
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        var alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil)
        
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
        let kCellIdentifier = "Cell";
        
        var post = results[indexPath.row]
        
        var cell = CellView(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kCellIdentifier, parent: self)
        cell.setPost(post)
        
        if cell == nil {
            cell = CellView(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kCellIdentifier, parent: self)
        }

        
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        self.showShareCard()
        var post = results[indexPath.row]
        var shareCard = self.shareCard as ShareCard
        shareCard.setPost(post)
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        // check here, if it is one of the cells, that needs to be resized
        // to the size of the contained UITextView
        var post = results[indexPath.row]
        var title = NSString(string:post.title)
        var maximumLabelSize = CGSizeMake(self.view.frame.size.width-85,9999)

        var textRect : CGRect = title.boundingRectWithSize(maximumLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(12)], context: nil)

    
        return textRect.height + CGFloat(50);
    }
    
    //Make the status bar white
    override func preferredStatusBarStyle() -> UIStatusBarStyle{
        return UIStatusBarStyle.LightContent
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
        
        UIView.animateWithDuration(0.3, delay: 0, options:UIViewAnimationOptions.BeginFromCurrentState,
            animations: {
                UIView.setAnimationCurve(UIViewAnimationCurve.Linear)
                var xOffsetShareCard = (self.view.frame.width - self.shareCard.frame.width)/2.0
                var yOffsetShareCard = (self.view.frame.height - self.shareCard.frame.height)/2.0
                
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
