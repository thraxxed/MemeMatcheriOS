//
//  SecondViewController.swift
//  MemeMatcher
//
//  Created by Seth Little on 2/17/18.
//  Copyright © 2018 Seth Little. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var memeImage: UIImageView!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var userProfileButton: UIButton!
    @IBOutlet weak var userChatButton: UIButton!
    
    var memes = [Meme]()
    
    var memeIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "heavyrainbackground")!)
        
        memeImage.layer.borderWidth = 1.5
        memeImage.layer.borderColor = UIColor.white.cgColor
        
        dislikeButton.setImage(UIImage(named: "dislikeButton"), for: .normal)
        
        likeButton.setImage(UIImage(named: "likeButton"), for: .normal)
        
        userProfileButton.setImage(UIImage(named: "userProfile"), for: .normal)
        
        userChatButton.setImage(UIImage(named: "userChatButton"), for: .normal)
        
        
        print(MemeMatcher.currentUser.username)
        
        // Do any additional setup after loading the view, typically from a nib.
        getMemes(for: 1) { (result) in
            switch result {
            case .success(let memes):
                self.memes = memes
                print(self.memes)
                
                let url = URL(string: self.memes[self.memeIndex].image_url)
                
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    DispatchQueue.main.async {
                        self.memeImage.image = UIImage(data: data!)
                    }
                }

            case .failure(let error):
                print(error )
                fatalError("error: \(error.localizedDescription)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    struct Meme: Codable {
        let id: Int
        let image_url: String
    }
    
    struct Like: Codable {
        let meme_id: Int
        let user_id: Int
        let liked: Bool
        
        init(meme_id: Int, user_id: Int, liked: Bool) {
            self.meme_id = meme_id
            self.user_id = user_id
            self.liked = liked
        }
        
    }
    
    
    enum Result<Value> {
        case success(Value)
        case failure(Error)
    }
    
    func getMemes(for id: Int, completion: ((Result<[Meme]>) -> Void)?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "meme-matcher.herokuapp.com"
        urlComponents.path = "/api/memes"
        
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let error = responseError {
                    completion?(.failure(error))
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()
                    do {
                        let memes = try decoder.decode([Meme].self, from: jsonData)
                        completion?(.success(memes))
                    } catch {
                        completion?(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                    completion?(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func likeMeme(like: Like, completion:((Error?) -> Void)?){
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "meme-matcher.herokuapp.com"
        urlComponents.path = "/api/likes"
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(like)
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            completion?(error)
        }
        
        // Create and run a URLSession data task with our JSON encoded POST request
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                completion?(responseError!)
                return
            }
        }
        task.resume()
    }
    
    func loadMemeImage() {
        memeIndex += 1
        if (memeIndex >= self.memes.count) {
            return
        }
        let url = URL(string: self.memes[self.memeIndex].image_url)
        
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!)
            DispatchQueue.main.async {
                self.memeImage.image = UIImage(data: data!)
            }
        }
    }
    
    //Mark: Actions
    
    func sendLike(liked: Bool) {
        let postLike = Like(meme_id: self.memes[self.memeIndex].id,
                            user_id: MemeMatcher.currentUser.id,
                            liked: liked)
        likeMeme(like: postLike) { (error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        loadMemeImage()
    }
    
    @IBAction func swipeRight(_ sender: UISwipeGestureRecognizer) {
        print("we swiped right")
        sendLike(liked: true)
    }
    
    @IBAction func swipeLeft(_ sender: UISwipeGestureRecognizer) {
        print("we swiped left")
        sendLike(liked: false)
    }
    
    
    @IBAction func heartMeme(_ sender: UIButton) {
        print("we clicked heart")
        sendLike(liked: true)
    }
    
    @IBAction func dislikeMeme(_ sender: UIButton) {
        print("we clicked x")
        sendLike(liked: false)
    }
    
    
    // Functions to download images after API call
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.memeImage.image = UIImage(data: data)
            }
        }
    }
}

