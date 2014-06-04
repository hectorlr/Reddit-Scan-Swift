//
//  SharedCard.swift
//  Reddit Scan Swift
//
//  Created by Hector Rodriguez on 6/3/14.
//  Copyright (c) 2014 Hector Rodriguez. All rights reserved.
//

import UIKit
import MessageUI

class ShareCard: UIView, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    let parent : MainViewController
    var postTitle : String?
    var postURL  : String?
    
    init(frame: CGRect, parent : MainViewController) {
        self.parent = parent
        super.init(frame: frame)
        
    }
    
    
    func setPost (post : Post){
        
        self.postTitle = post.title
        self.postURL = post.postURL
        //Set the background image and resize the view to match the dimensions of the image
        let background = UIImage(named:"shareCard.png")
        let backgroundView = UIImageView(image: background)
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, backgroundView.frame.size.width, backgroundView.frame.size.height)
        
        //Add an invisible button over the top right corner to close the view
        let closeButton = UIButton(frame: CGRectMake(self.frame.size.width-30, 0, 30, 30))
        closeButton.backgroundColor = UIColor.clearColor()
        closeButton.addTarget(self, action:Selector("closeButtonTapped"), forControlEvents: .TouchUpInside)
        
        var yOffset : CGFloat = 70
        
        //Add a button using the provided image for emailing the post
        let emailButton = UIButton(frame: CGRectMake(0, yOffset, self.frame.size.width, 50))
        emailButton.setImage(UIImage(named:"email.png"), forState: .Normal)
        emailButton.addTarget(self, action:Selector("emailButtonTapped"), forControlEvents: .TouchUpInside)
        
        yOffset+=emailButton.frame.size.height+15
        
        //Add a button using the provided image for sending an sms message using the post
        let smsButton = UIButton(frame: CGRectMake(0, yOffset, self.frame.size.width, 50))
        smsButton.setImage(UIImage(named:"sms.png"), forState: .Normal)
        smsButton.addTarget(self, action:Selector("smsButtonTapped"), forControlEvents: .TouchUpInside)
        
        self.addSubview(closeButton)
        self.addSubview(backgroundView)
        self.addSubview(emailButton)
        self.addSubview(smsButton)
    }
    
    //Hide the view using animation
    func closeButtonTapped(){
        
        UIView.animateWithDuration(0, delay: 0, options:.BeginFromCurrentState,
            animations: {
                UIView.setAnimationCurve(.Linear)
                self.frame=CGRectMake(self.parent.view.frame.size.width, self.parent.view.frame.size.height, self.frame.size.width, self.frame.size.height)
            },
            completion: {
                _ in
                self.parent.dimmer.removeFromSuperview()
            })
        
        
    }
    
    //When the sms button is tapped, create a message and show the view
    func smsButtonTapped(){
        
        if !MFMessageComposeViewController.canSendText() {
            
            let alert = UIAlertController(title: "Error", message: "Your device doesn't support SMS!", preferredStyle: UIAlertControllerStyle.Alert)
            
            let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil)
            
            alert.addAction(alertAction)
            self.parent.presentModalViewController(alert, animated: true)
            
            return
        }
        
        let message = "Check out this epic Reddit post: \(self.postTitle)\n\n\(self.postURL)"
        
        let messageController = MFMessageComposeViewController(nibName: nil, bundle: nil)
        messageController.messageComposeDelegate = self
        messageController.body = message
        
        self.closeButtonTapped()
        // Present message view controller on screen
        parent.presentViewController(messageController, animated:true, completion:nil)
    }
    
    //Handle the return from the sms window
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult){
        switch result.value {
        case MessageComposeResultFailed.value:
            
            let alert = UIAlertController(title: "Error", message: "Failed to send SMS!", preferredStyle: .Alert)
            
            let alertAction = UIAlertAction(title: "OK", style: .Cancel, handler:nil)
            
            alert.addAction(alertAction)
            self.parent.presentModalViewController(alert, animated: true)
            
        case MessageComposeResultCancelled.value:
            println("Message cancelled")
            
        case MessageComposeResultSent.value:
            println("Message sent")
            
        default:
            println("Message default")
        }
        
        
        parent.dismissViewControllerAnimated(true, completion:nil)
    }
    
    //When the email button is tapped, create an email and show the email view
    func emailButtonTapped() {
        // Email Subject
        let emailTitle = "Check out this epic Reddit post!"
        // Email Content
        let messageBody = "\(self.postTitle)\n\n\(self.postURL)"
        
        let mc = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML:false)
        
        self.closeButtonTapped()
        
        // Present mail view controller on screen
        self.parent.presentViewController(mc, animated:true, completion:nil)
        
    }
    
    //Handle the return from the email view
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!){
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail cancelled")
            
        case MFMailComposeResultSaved.value:
            println("Mail saved")
            
        case MFMailComposeResultSent.value:
            println("Mail sent")
            
        case MFMailComposeResultFailed.value:
            println("Mail sent failure: \(error.localizedDescription)")
            
        default:
            println("Message default")
        }
        
        // Close the Mail Interface
        self.parent.dismissViewControllerAnimated(true, completion:nil)
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
    // Drawing code
    }
    */
    
}
