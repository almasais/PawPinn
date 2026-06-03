//
//  CameraViewController.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//


class CameraViewController: UIViewController {
    
    let matcher = CatMatcher()
    
    // When user takes photo
    func photoTaken(photo: UIImage) {
        
        showLoadingSpinner("Analyzing cat...")
        
        // Get all lost reports from Firebase
        DatabaseManager.shared.getLostReports { reports in
            
            // Find matches using Gemini AI
            self.matcher.findMatches(
                photo: photo,
                allReports: reports
            ) { matches in
                
                self.hideLoadingSpinner()
                
                if matches.isEmpty {
                    self.showNoMatchesAlert()
                } else {
                    self.showMatchResults(matches)
                }
            }
        }
    }
}