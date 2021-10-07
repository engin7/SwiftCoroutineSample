//
//  ViewController.swift
//  SwiftCoroutineSample
//
//  Created by Engin KUK on 7.10.2021.
//

import UIKit
import SwiftCoroutine

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func callFuturePressed(_ sender: Any) {
        executeFuture()
    }
    @IBOutlet weak var label: UILabel!
    
    
    let imageURL = URL(string: "https://i.ibb.co/2P7sVL4/205585.jpg")!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        executeCoroutine()
        indicator.startAnimating()
        executeChannel()
    }
  
    /// 1- usage of await() inside a coroutine to wrap asynchronous calls.
    ///
    
    func executeCoroutine() {
         
        //execute coroutine on the main thread
        DispatchQueue.main.startCoroutine {

            //await URLSessionDataTask response without blocking the thread
            let (data, _, _) = try Coroutine.await { callback in
                URLSession.shared.dataTask(with: self.imageURL, completionHandler: callback).resume()
            }

            guard let image = UIImage(data: data!) else { return }
            self.imageView.image = image
            self.indicator.stopAnimating()
        }
    }
  
    /// 2- Futures and Promises
    ///
    
    
//    CoFuture and its subclass CoPromise are the implementation of the Future/Promise approach. They allow to launch asynchronous tasks and immediately returnCoFuture with its future results. The available result can be observed by the whenComplete() callback or by await() inside a coroutine without blocking a thread.
    
    func someAsyncFunc(completionHandler: @escaping (Int) -> Void)  {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completionHandler(75)
        }
    }
    
    //wraps some async func with CoFuture
    func makeIntFuture() -> CoFuture<Int> {
        let promise = CoPromise<Int>()
        someAsyncFunc { int in
            promise.success(int)
        }
        return promise
    }

    func executeFuture() {
        // It allows to start multiple tasks in parallel and synchronize them later with await().

        //create CoFuture<Int> that takes 2 sec. from the example above
        let future1: CoFuture<Int> = makeIntFuture()

        //execute coroutine on the global queue and returns CoFuture<Int> with future result
        let future2: CoFuture<Int> = DispatchQueue.global().coroutineFuture {
            try Coroutine.delay(.seconds(3)) //some work that takes 3 sec.
            return 24
        }

        //execute coroutine on the main thread
        DispatchQueue.main.startCoroutine {
            let sum: Int = try future1.await() + future2.await() //will await for 3 sec.
            self.label.text = "Sum is \(sum)"
        }
    }
   
    
    /// 3- Channels
    ///
    
    // Futures and promises provide a convenient way to transfer a single value between coroutines. [Channels] provide a way to transfer a stream of values. Conceptually, a channel is similar to a queue that allows to suspend a coroutine on receive if it is empty, or on send if it is full.
    
    // Usage:
    // To create channels, use the CoChannel class.

    //create a channel with a buffer which can store only one element
    
    func executeChannel() {
        
        let channel = CoChannel<Int>(capacity: 1)

        DispatchQueue.global().startCoroutine {
            for i in 0..<9 {
                //imitate some work
                try Coroutine.delay(.seconds(1))
                //sends a value to the channel and suspends coroutine if its buffer is full
                try channel.awaitSend(i)
            }

            //close channel when all values are sent
            channel.close()
        }

        DispatchQueue.global().startCoroutine {
            //receives values until closed and suspends a coroutine if it's empty
            for i in channel.makeIterator() {
                print("Receive", i)
            }

            print("Done")
        }

    }
   
    
    
    

}

