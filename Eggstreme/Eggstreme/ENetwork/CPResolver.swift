import Foundation

class CPResolver: NSObject, URLSessionTaskDelegate {
    func resolveIt(from originalURL: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: originalURL)
        request.setValue("CFNetwork", forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error:", error.localizedDescription)
                completion(true)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let result = (400...599).contains(httpResponse.statusCode)
                completion(result)
            } else {
                completion(true)
            }
        }
        task.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request)
    }
    
    static func checking() async -> Bool {
        let urlString = CPLinks.winStarData
        
        if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedString) {
            
            let handler = CPResolver()
            
            return await withCheckedContinuation { continuation in
                handler.resolveIt(from: url) { result in
                    continuation.resume(returning: result)
                }
            }
        } else {
            return true
        }
    }
}
