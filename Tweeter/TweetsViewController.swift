//
//  TweetsViewController.swift
//  Tweeter
//
//  Created by Bianca Curutan on 10/24/16.
//  Copyright © 2016 Bianca Curutan. All rights reserved.
//

import ReachabilitySwift
import UIKit

class TweetsViewController: UIViewController {
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var reachability: Reachability = Reachability()!
    var tweets: [Tweet] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Reachability
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged), name: ReachabilityChangedNotification, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Error: Could not start reachability notifier")
        }
        
        // For pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onPullToRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)

        TwitterClient.sharedInstance.homeTimeline(success: { (tweets: [Tweet]) -> () in
                self.tweets = tweets
                self.tableView.reloadData()
            
            }, failure: { (error: Error) -> () in
                print("error: \(error.localizedDescription)")
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNetworkError()
        /* TODO TwitterClient.sharedInstance.homeTimeline(success: { (tweets: [Tweet]) -> () in
            self.tweets = tweets
            self.tableView.reloadData()
            
            }, failure: { (error: Error) -> () in
                print("error: \(error.localizedDescription)")
            }
        )*/
    }
    
    // MARK: - IBAction
    @IBAction func onLogoutButton(_ sender: AnyObject) {
        TwitterClient.sharedInstance.logout()
    }
    
    // MARK: - Private Methods
    
    func onPullToRefresh(refreshControl: UIRefreshControl) {
        updateNetworkError()
        TwitterClient.sharedInstance.homeTimeline(success: { (tweets: [Tweet]) -> () in
            self.tweets = tweets
            self.tableView.reloadData()
            refreshControl.endRefreshing()
            
            }, failure: { (error: Error) -> () in
                print("error: \(error.localizedDescription)")
            }
        )
    }
    
    func updateNetworkError() {
        if reachability.isReachable {
            self.errorView.isHidden = true // Hide Network Error message
        } else {
            self.errorView.isHidden = false// Display Network Error message
        }
    }
    
    func reachabilityChanged(notification: NSNotification) {
        let reachability = notification.object as! Reachability
        if reachability.isReachable {
            self.errorView.isHidden = true // Hide Network Error message
        } else {
            self.errorView.isHidden = false // Display Network Error message
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //let navigationController = segue.destination as! UINavigationController TODO
        
        if "detailsSegue" == segue.identifier {
            let cell = sender as! TweetCell
            let indexPath = tableView.indexPath(for: cell)
            let tweet = tweets[indexPath!.row]
            tweet.favorited = cell.favoriteButton.isSelected // TODO this seems hacky
            tweet.retweeted = cell.retweetButton.isSelected // TODO this seems hacky
            let viewController = segue.destination as! TweetDetailsViewController
            viewController.tweet = tweet
            
        } else if "newTweetSegue" == segue.identifier {
            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! NewTweetViewController
            viewController.delegate = self
            viewController.user = User.currentUser
        
        } else if "replySegue" == segue.identifier {
            let replyButton = sender as! UIButton
            let tweet = tweets[replyButton.tag]
            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! NewTweetViewController
            viewController.delegate = self
            viewController.replyTweet = tweet
            viewController.user = User.currentUser
        }
    }
}

// MARK: - UITableViewDataSource

extension TweetsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell", for: indexPath) as! TweetCell
        cell.replyButton.tag = indexPath.row // TODO Fix??
        cell.tweet = tweets[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count 
    }
}

// MARK: - UITableViewDelegate

extension TweetsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row appearance after it has been selected
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NewTweetViewControllerDelegate

extension TweetsViewController: NewTweetViewControllerDelegate {
    
    func newTweetViewController(newTweetViewController: NewTweetViewController, didAddTweet tweet: Tweet) {
        tweets.insert(tweet, at: 0)
        tableView.reloadData()
    }
}
