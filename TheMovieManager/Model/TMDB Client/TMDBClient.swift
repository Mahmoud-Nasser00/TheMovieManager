//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {

    static let tag = "TMDBClient "
    static let apiKey = "e54b76494ff48d6999c9e6837d3c6ce1"

    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }

    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let posterBase = "https://image.tmdb.org/t/p/w500"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let redirectParam = "?redirect_to=themoviemanager:authenticate"

        case getWatchlist
        case getRequestToken
        case login
        case sessionId
        case webAuth
        case logout
        case getFavouritMovies
        case searchMovies(String)
        case addToWatchList
        case markAsFavourit
        case posterImageUrl(String)

        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .sessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/\(Auth.requestToken)" + Endpoints.redirectParam
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavouritMovies: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .searchMovies(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .addToWatchList: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .markAsFavourit: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .posterImageUrl(let posterPath): return Endpoints.posterBase + posterPath
            }
        }

        var url: URL {
            return URL(string: stringValue)!
        }
    }

    class func downloudPosterPath(posterPath: String, completion: @escaping(Data?, Error?) -> Void) {
        let url = Endpoints.posterImageUrl(posterPath).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { completion(nil, error);return }
            completion(data, nil)
        }
        task.resume()
    }

    class func markAsFavourit(mediaId: Int, favourit: Bool, completion: @escaping(Bool, Error?) -> Void) {
        let body = MarkFavourit(mediaType: "Movies", mediaId: mediaId, favourit: favourit)
        taskForPostRequest(url: Endpoints.markAsFavourit.url, body: body, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completion(false, error)
            }
        }
    }

    class func addToWatchList(mediaId: Int, watchList: Bool, completion: @escaping(Bool, Error?) -> Void) {
        let Body = MarkWatchList(mediaType: "movie", mediaId: mediaId, watchList: watchList)
        taskForPostRequest(url: Endpoints.addToWatchList.url, body: Body, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                print(tag, response.statusCode, response.statusMessage)
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                print(tag, error as Any)
                completion(false, error)
            }
        }
    }

    class func searchMovies(query: String, completion: @escaping([Movie], Error?) -> Void)->URLSessionDataTask {
        print(tag, "search movies url : \(Endpoints.searchMovies(query).url)")
        let task = taskForGetRequest(url: Endpoints.searchMovies(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
        return task
    }

    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        print(tag + "get watch list url : \(Endpoints.getWatchlist.url)")
        
        let task = taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], nil)
            }
        }
    }

    class func getFavouritMovies(completion: @escaping([Movie], Error?) -> Void) {

        let task = taskForGetRequest(url: Endpoints.getFavouritMovies.url, response: MovieResults.self) { (moviesResults, error) in
            if let moviesResults = moviesResults {
                completion(moviesResults.results, nil)
            } else {
                completion([], error)
            }
        }
    }

    class func logout(completion: @escaping(Bool, Error?) -> Void) {
        var requestURl = URLRequest(url: Endpoints.logout.url)
        requestURl.httpMethod = "DELETE"
        requestURl.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyData = LogoutRequest(sessionId: Auth.sessionId)
        requestURl.httpBody = try! JSONEncoder().encode(bodyData)

        let task = URLSession.shared.dataTask(with: requestURl) { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completion(true, nil)
        }
        task.resume()
    }

    class func createSessionId(completion: @escaping (Bool, Error?) -> Void) {
        let sessionIdObject = PostSession(requestToken: Auth.requestToken)

        taskForPostRequest(url: Endpoints.sessionId.url, body: sessionIdObject, responseType: SessionResponse.self) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }

    class func login(userName: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        let loginUrl = Endpoints.login.url
        print(tag, "login url : \(loginUrl)")
        let loginBody = LoginRequest(username: userName, password: password, requestToken: Auth.requestToken)


        taskForPostRequest(url: Endpoints.login.url, body: loginBody, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }

    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }



    private class func taskForPostRequest<ResponseType:Decodable , RequestType:Encodable>(url: URL, body: RequestType, responseType: ResponseType.Type, completion: @escaping(ResponseType?, Error?) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try! JSONEncoder().encode(body)

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse, error) in
            guard let data = data else { completion(nil, error);return }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()

    }

    private class func taskForGetRequest<ResponseType:Codable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { completion(nil, error) ; return }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        return task
    }



}


// private func getRequestTask<ResponseType:Codable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
//        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
//            guard let data = data else { completion(nil, error); return }
//            self.decodeDataTostruct(data: data, structType: responseType) { (response, error) in
//                guard let response = response else { completion(nil, error);return }
//                completion(response,nil)
//            }
//
//        }
//        task.resume()
//    }
//
//    private func decodeDataTostruct<Struct:Codable>(data: Data, structType: Struct.Type, completion: @escaping (Struct?, Error?) -> Void) {
//        do {
//            let decoder = JSONDecoder()
//            let response: Struct
//            response = try decoder.decode(Struct.self, from: data)
//            completion(response, nil)
//        } catch {
//            completion(nil, error)
//        }
//    }
