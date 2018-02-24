//
//  ChatView.swift
//  MemeMatcher
//
//  Created by Hyun Chu on 2/22/18.
//  Copyright © 2018 Seth Little. All rights reserved.
//

import UIKit



class ChatView: UIViewController {
    
    
    var messages = [Message]()
    
    //MARK: Properties
    
    @IBOutlet weak var sendChatButton: UIButton!
    
    @IBOutlet weak var messageInputField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch messages
        getMessages(for: 1) { (result) in
            switch result {
            case .success(let messages):
                self.messages = messages
                print(self.messages)
            case .failure(let error):
                print(error )
                fatalError("error: \(error.localizedDescription)")
            }
        }
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    struct Message: Codable {
        let id: Int
        let author_id: Int
        let receiver_id: Int
    }
    
    enum Result<Value> {
        case success(Value)
        case failure(Error)
    }
    
    func getMessages(for id: Int, completion: ((Result<[Message]>) -> Void)?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "meme-matcher.herokuapp.com"
        urlComponents.path = "/api/messages"
        
        urlComponents.queryItems = [URLQueryItem(name: "id", value: "\(MemeMatcher.currentMatch)")]
        
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
                        let messages = try decoder.decode([Message].self, from: jsonData)
                        completion?(.success(messages))
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
    
    //MARK: Actions
    
    @IBAction func postMessage(_ sender: UITapGestureRecognizer) {
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
