

import UIKit
import SDWebImage
import CoreData
import Reachability
import FloatRatingView

class MovieTableViewController: UITableViewController, AddMovieProtocol{

    var movieArray = [Movie]()
    var genraArray = [String]()
    var movieAddedArray = [NSManagedObject]()
    
    
    
    //declare this property where it won't go out of scope relative to your listener
    let reachability = try! Reachability()
    
    
    let context : NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        genraArray = ["Action", "Drama", "Sci-Fi", "Thriller", "Adventure", "History", "Animation", "Comedy", "Family", "Horror", "Crime"]

        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        ConnectToApi()
        fetchFromCoreData()
        
        do{
            try reachability.startNotifier()

        }catch{
            print("sdfghjkl  dfghjk erty ")
        }
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    func addMovieDelegation(movie: Movie) {
       // movieArray.append(movie)
        
        saveToCoreData(movieData: movie)
        fetchFromCoreData()
        
        self.tableView.reloadData()
    }
    
    
    @IBAction func addMovie(_ sender: Any) {
        
        let addMovie = self.storyboard?.instantiateViewController(identifier: "add_ movie") as! AddMovieViewController
        
        addMovie.addProtocol = self;
        
        addMovie.genra = genraArray
        
        self.present(addMovie, animated: true, completion: nil)

    }
    
    
    @IBAction func showImageCollection(_ sender: Any) {
        
        let imageCollection = self.storyboard?.instantiateViewController(identifier: "image_collection") as! MovieImageCollectionViewController
        
        if reachability.connection == .unavailable{
            
            imageCollection.movieAddedArr = movieAddedArray
            
        }else{
            
            imageCollection.movieArr = movieArray
            
        }
        
        self.navigationController?.pushViewController(imageCollection, animated: true)
        
        
    }
    
    
}




// core data
extension MovieTableViewController{
    
    
    func saveToCoreData(movieData : Movie) {
        
        let entity = NSEntityDescription.entity(forEntityName: "MovieData", in: context)
        let movie = NSManagedObject(entity: entity!, insertInto: context)
        
        movie.setValue(movieData.title, forKey: "movieTitle")
        movie.setValue(movieData.rating, forKey: "movieRate")
        movie.setValue(movieData.releaseYear, forKey: "movieRelease")
        
        
        if movieData.image != nil{
            movie.setValue(movieData.image, forKey: "movieImage")
        }else{
            movie.setValue(movieData.imageData, forKey: "movieImgeData")
        }
        
        movie.setValue(movieData.genre, forKey: "movieGenra")
        
        
        do{
            try context.save()
            
            print("data saved")
            
        }catch let error as NSError{
            print(error)
        }
        
    }
    
    
    func fetchFromCoreData(){
        
        let fetchRequest = NSFetchRequest<MovieData>(entityName: "MovieData") // select * from MovieData
        
        do{
//            var moviesManagedObject = [MovieData]()
//            moviesManagedObject = try context.fetch(fetchRequest)
            movieAddedArray = try context.fetch(fetchRequest)
            print(movieAddedArray)
//            for index in 0..<moviesManagedObject.count {
//
//                movieArray.append(Movie(title: moviesManagedObject[index].movieTitle!, imgData: moviesManagedObject[index].movieImgeData!, rate: moviesManagedObject[index].movieRate, releaseYear: Int(moviesManagedObject[index].movieRelease), genra: moviesManagedObject[index].movieGenra!))
//            }
            

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }catch let error as NSError{
            print(error)
        }
        
        
    }
    
        
}


// connect to api
extension MovieTableViewController{
    
    func ConnectToApi() {

        // #1 url
        let url = URL(string: "https://api.androidhive.info/json/movies.json")

        // #2 request
        let request = URLRequest(url: url!)

        // #3 session
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // #4 task
        let task = session.dataTask(with: request) { [self] (data, response, error) in

            // #6 exception handler
            do{

                let decoder = JSONDecoder()
                let jesonArray = try decoder.decode([Movie].self, from: data!)
                self.movieArray = jesonArray

                DispatchQueue.main.async {

                    self.tableView.reloadData()

                }

            }catch{
                print(error)
            }

        }

        // #5 start task
        task.resume()
    }




}





// Table view data source
extension MovieTableViewController{
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        var numberOfRows = 0
        
        if reachability.connection == .wifi || reachability.connection == .cellular{

            numberOfRows = movieArray.count

        }else{

            numberOfRows = movieAddedArray.count
            
        }
        
        return numberOfRows
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MovieTableViewCell

        
        cell.ratingView.contentMode = UIView.ContentMode.scaleAspectFit
        cell.ratingView.type = .floatRatings
        
        
        cell.imageView?.startAnimating()
        cell.ratingView.maxRating = 10
        cell.ratingView.editable = false
        
        if reachability.connection == .wifi || reachability.connection == .cellular{


            cell.ratingView.rating = movieArray[indexPath.row].rating 

            cell.movieName.text = movieArray[indexPath.row].title
            if movieArray[indexPath.row].imageData != nil{
                        // convert data to image

                cell.movieImage.image = UIImage(data: movieArray[indexPath.row].imageData!)

            }else{

                cell.movieImage.sd_setImage(with: URL(string: movieArray[indexPath.row].image ?? ""), placeholderImage: UIImage(named: "placeholder.png"))
            }
            cell.movieGenra.text = movieArray[indexPath.row].genre.joined(separator: " | ")

        }else{
            
            cell.movieName.text = movieAddedArray[indexPath.row].value(forKey: "movieTitle") as? String
            cell.movieImage.image = UIImage(data: movieAddedArray[indexPath.row].value(forKey: "movieImgeData") as! Data)
            cell.movieGenra.text = (movieAddedArray[indexPath.row].value(forKey: "movieGenra") as! [String]).joined(separator: " | ")
            cell.ratingView.rating = movieAddedArray[indexPath.row].value(forKey: "movieRate") as! Double
        }
        

        
        //movieTitle    movieRate   movieRelease    movieImgeData   movieGenra

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let showView = self.storyboard?.instantiateViewController(identifier: "show_data") as! ViewController
        
        
        if reachability.connection == .unavailable{
            showView.imageData = movieAddedArray[indexPath.row].value(forKey: "movieImgeData") as? Data
            showView.rate = movieAddedArray[indexPath.row].value(forKey: "movieRate") as? Double
            showView.name = movieAddedArray[indexPath.row].value(forKey: "movieTitle") as? String
            showView.genra = movieAddedArray[indexPath.row].value(forKey: "movieGenra") as? [String]
            showView.releaseYear = movieAddedArray[indexPath.row].value(forKey: "movieRelease") as? Int
            
        }else{
            
            showView.image = movieArray[indexPath.row].image
            showView.rate = movieArray[indexPath.row].rating
            showView.name = movieArray[indexPath.row].title
            showView.genra = movieArray[indexPath.row].genre
            showView.releaseYear = movieArray[indexPath.row].releaseYear
        }
    
        
        
        
        self.present(showView, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
                
            
            if reachability.connection == .unavailable{
                
                //remove from core data
                context.delete(movieAddedArray[indexPath.row])
                
                // remove from array
                movieAddedArray.remove(at: indexPath.row)
                
                // save changes
                do{
                    
                    try context.save()
                    print("data removed")
                    
                    
                }catch let error as NSError{
                    print(error)
                }
                
                // remove from table
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        
            
        
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }


}

