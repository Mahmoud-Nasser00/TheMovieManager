//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {

    // MARK:- IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!

    // MARK:- Variables
    var movie: Movie!

    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }

    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }

    // MARK:- app life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = movie.title

        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        if let poster = movie.posterPath {
            TMDBClient.downloudPosterPath(posterPath: poster ) { (data, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }

    // MARK:- IBActions
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.addToWatchList(mediaId: movie.id, watchList: !isWatchlist, completion: handleAddTowatchListResponse(success: error:))
    }

    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markAsFavourit(mediaId: movie.id, favourit: !isFavorite, completion: handleMarkFavouritResponse(success: error:))
    }

    // MARK:- Helper Functions
    private func handleAddTowatchListResponse(success: Bool, error: Error?) {
        if success {
            switch isWatchlist {
            case true:
                MovieModel.watchlist = MovieModel.watchlist.filter { (movie) -> Bool in
                    movie != self.movie
                }
            case false:
                MovieModel.watchlist.append(movie)
            }
            DispatchQueue.main.async {
                self.toggleBarButton(self.watchlistBarButtonItem, enabled: self.isWatchlist)
            }

        }
    }

    private func handleMarkFavouritResponse(success: Bool, error: Error?) {
        if success {
            switch isFavorite {
            case true:
                MovieModel.favorites = MovieModel.favorites.filter { (movie) -> Bool in
                    movie != self.movie
                }
            case false:
                MovieModel.favorites.append(movie)
            }
            DispatchQueue.main.async {
                self.toggleBarButton(self.watchlistBarButtonItem, enabled: self.isFavorite)
            }

        }
    }

    private func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }


}
