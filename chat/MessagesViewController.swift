//
//  MessagesViewController.swift
//  ClearKeep
//
//  Created by Nguyen Viet Thang on 7/23/15.
//  Copyright © 2015 ck. All rights reserved.
//

import Foundation
import UIKit

class MessagesViewController: JSQMessagesViewController {
    
    static var theDetail : MessagesViewController?
    var master: MasterViewController?
    var peer: Contact?
    var messages : NSMutableArray = NSMutableArray()
    var images = []
    var outgoingBubbleImageData : JSQMessagesBubbleImage?
    var incomingBubbleImageData : JSQMessagesBubbleImage?
    static var lastChat : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        guard let creds = Login.loadCredentials() else {
            print("missing creds in keychain")
            return
        }
        
        //set username
        senderId = creds.username
        senderDisplayName = creds.username
        
        //self.showLoadEarlierMessagesHeader = true;
        MessagesViewController.theDetail = self
        self.inputToolbar?.contentView?.leftBarButtonItem = nil
        
        let bubbleFactory : JSQMessagesBubbleImageFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageData = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        incomingBubbleImageData = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        
        automaticallyScrollsToMostRecentMessage = true
        navigationController?.navigationBar.topItem?.title = (peer?.username)!
        
        Rest.sharedInstance.load((peer?.username)!, callback: {
            if let loaded = $0 {
                MessagesViewController.lastChat = loaded;
                dispatch_async(dispatch_get_main_queue(),{
                    
                    let dataArr : [String] = loaded.componentsSeparatedByString("\n");
                    var count = 1
                    
                    while (count < dataArr.count) {
                        
                        let messageValue = dataArr[count]
                        let messageValueArr : [String] = messageValue.componentsSeparatedByString(":");
                        
                        var sender : String = "";
                        var text : String = "";
                        if (messageValueArr.count > 1) {
                            sender = messageValueArr[0]
                            text = messageValueArr[1]
                        }
                        
                        let mess = JSQMessage(senderId: sender, displayName: sender, text: text);
                        self.messages.addObject(mess);
                        
                        count = count + 1
                    }
                    
                    self.finishReceivingMessageAnimated(true)
                    HttpHelper.dismissProgress()
                })
            }
        })
        
        HttpHelper.showProgress()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        sendMessage(text)
    }
    
    func incoming(userInfo: [NSObject : AnyObject]) {
        let from = userInfo["from"] as! String
        if from == self.peer?.username {
            
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            let messageReceive = userInfo["message"] as! String
            
            let message = JSQMessage(senderId: from, displayName: from, text: messageReceive);
            self.messages.addObject(message);
            MessagesViewController.lastChat = MessagesViewController.lastChat + "\n" + from + ": " + messageReceive;
            Rest.sharedInstance.store((peer?.username)!, value: MessagesViewController.lastChat)
            
            finishSendingMessageAnimated(true)
            
        }
    }
    
    func sendMessage(text: String) {
        Rest.sharedInstance.send((peer?.username)!, message: text, callback: {
            if !$0 {
                print("error sending " + $1)
                let alertView : UIAlertView = UIAlertView(title: "Error Send..", message: "Error send text! please try agin", delegate: self, cancelButtonTitle: "OK");
                alertView.show();
            }
        })
        
        Rest.sharedInstance.store((peer?.username)!, value: text)
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        self.messages.addObject(message);
        
        MessagesViewController.lastChat = MessagesViewController.lastChat + "\n" + senderId + ": " + text
        Rest.sharedInstance.store((peer?.username)!, value: MessagesViewController.lastChat)

        finishSendingMessageAnimated(true)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.messages.count)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
 
        let message : JSQMessageData = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
        if (message.senderId() == self.senderId) {
            return outgoingBubbleImageData;
        }
        
        return incomingBubbleImageData;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message : JSQMessageData = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
        
        if message.senderId() == senderId {
            return JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "demo_avatar_jobs")!, diameter: 200)
        } else {
            return JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "demo_avatar_cook")!, diameter: 200)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message : JSQMessageData = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
        
        if message.senderId() == senderId {
            cell.textView!.textColor = UIColor.blackColor()
        } else {
            cell.textView!.textColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message : JSQMessageData = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
        
        // Sent by me, skip
        if message.senderId() == senderId {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
            if previousMessage.senderId() == message.senderId() {
                return nil;
            }
        }
        
        return NSAttributedString(string:message.senderId())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
        
        // Sent by me, skip
        if message.senderId() == senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = self.messages.objectAtIndex(indexPath.item) as! JSQMessageData
            if previousMessage.senderId() == message.senderId() {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
}
