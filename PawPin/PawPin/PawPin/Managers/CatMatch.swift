//
//  CatMatch.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation

struct CatMatch {
    let report: CatReport
    let score: Int
    
    // Shows match quality as text
    var label: String {
        switch score {
        case 80...100: return "Very likely match 🟢"
        case 60...79:  return "Possible match 🟡"
        case 50...59:  return "Low match 🔴"
        default:       return "No match"
        }
    }
    
    // Shows score as percentage text
    var percentageText: String {
        return "\(score)% Match"
    }
}
