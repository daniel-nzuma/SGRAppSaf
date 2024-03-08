//
//  ViewController.swift
//  SGRAppSaf
//
//  Created by Daniel Nzuma on 08/03/2024.
//

import UIKit
import Alamofire
import CoreData



class ViewController: UIViewController {
    
    let BASE_URL = "http://localhost:8088/api/v1/"
    var stationsList = [TrainStationsModel]()
    var stationsIDAndCountDictionary = [Int:Int]()
    var stationsIDAndNameDictionary = [Int:String]()
    
    @IBOutlet weak var bookingsLabel: UILabel!
    var trainsStations = [TrainStations]()
    var moc:NSManagedObjectContext!
    let appDelegate = UIApplication.shared.delegate as? AppDelegate

    var bookingsList = [BookingsModel]() {
        didSet{
            self.computeStationCount()
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        moc = appDelegate?.persistentContainer.viewContext

        getTrainStations()
        
    }
    
    private func getTrainStations()
    {

        AF.request(BASE_URL.appending("stations"))
            .validate() // Optional: Validate the response
            .responseDecodable(of: [TrainStationsModel].self) { response in
                switch response.result {
                case .success(let result):
                    self.stationsList = result
                    self.getBookings()
                case .failure(let error):
                    print("Error: \(error)")
                    self.loadDBData()
                }
            }
            
    }
    
    private func getBookings()
    {

        AF.request(BASE_URL.appending("trains/bookings"))
            .validate() // Optional: Validate the response
            .responseDecodable(of: [BookingsModel].self) { response in
                switch response.result {
                case .success(let result):
                    self.bookingsList = result
                case .failure(let error):
                    // Handle the error
                    print("Error: \(error)")
                    self.loadDBData()
                }
            }
            
    }
    
    private func computeStationCount()
    {
        for station in stationsList
        {
            stationsIDAndCountDictionary[station.id] = 0
            stationsIDAndNameDictionary[station.id] = station.stationName
        }
            
//            for b in bookingsList
//            {
//                var stationIDAndCountDictionary = [Int:Int]()
//                if(stationIDAndCountDictionary[b.startStation] != nil){
//                    stationIDAndCountDictionary[b.startStation] = (stationIDAndCountDictionary[b.startStation] ?? 0) + 1;
//                }
//                else{
//                    stationIDAndCountDictionary[b.startStation]  = 0;
//                }
//            }
//            var startStation = 0
//            var exitStation = 1
//
//            while(startStation < exitStation)
//            {
//                var currentBookingCount = stationsIDAndCountDictionary[startStation]
//                stationsIDAndCountDictionary[startStation] = (currentBookingCount ?? 0) + 1; //
//                startStation += 1;
//            }
//
//        //
        
        
        for booking in bookingsList
        {
            var startStation = booking.startStation
            var exitStation = booking.exitStation

            while(startStation < exitStation)
            {
                var currentBookingCount = stationsIDAndCountDictionary[startStation]
                stationsIDAndCountDictionary[startStation] = (currentBookingCount ?? 0) + 1; //
                startStation += 1;
            }
        }
        
        persistDataToDB()
    }
    
    private func persistDataToDB()
    {
          
          for (key, value) in stationsIDAndCountDictionary {
              let station = TrainStations(context: moc)
              
              station.stationID = Int16(key)
              station.stationName = stationsIDAndNameDictionary[key]
              station.stationBookings = String(value)
                
              appDelegate?.saveContext()
          }
          

        loadDBData()
        
    }
    
    private func loadDBData(){
      
        let fetchStationBookings:NSFetchRequest<TrainStations> = TrainStations.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "stationID", ascending: true)  //sort by station id

       // fetchStationBookings.sortDescriptors = [NSSortDecriptor(key: "", ascending: true)]
        fetchStationBookings.sortDescriptors = [sortDescriptor]

       do 
       {
           try trainsStations = moc.fetch(fetchStationBookings)
       }
       catch {
           print("Could not load data")
       }
        var bookings = ""
        for t in trainsStations {
            //print(t.stationBookings! + (t.stationName ?? ""))
            bookings.append(t.stationBookings ?? "");
        }
        
        bookingsLabel.text = bookings
    
    }



}

