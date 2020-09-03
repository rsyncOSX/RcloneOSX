//
//  Dateandtime.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

struct Dateandtime {
    // Calculate seconds from now to startdate
    private func seconds(_ startdate: Date, enddate: Date?) -> Double {
        if enddate == nil {
            return startdate.timeIntervalSinceNow
        } else {
            return enddate!.timeIntervalSince(startdate)
        }
    }

    // Calculation of time to a spesific date
    // Used in view of all tasks
    func timeString(_ startdate: Date, enddate: Date?) -> String {
        var result: String?
        let seconds: Double = self.seconds(startdate, enddate: enddate)
        let (hr, minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        // hr, min, 60 * secf
        if hr == 0, min == 0 {
            result = String(format: "%.0f", 60 * secf) + " secs"
        } else if hr == 0, min < 60 {
            result = String(format: "%.0f", min) + " mins " + String(format: "%.0f", 60 * secf) + " secs"
        } else if hr < 25 {
            result = String(format: "%.0f", hr) + " hours " + String(format: "%.0f", min) + " mins"
        } else {
            result = String(format: "%.0f", hr / 24) + " days"
        }
        if secf <= 0 {
            result = " ... working ... "
        }
        return result!
    }

    // Calculation of time to a spesific date
    // Used in view of all tasks
    func timeString(_ seconds: Double) -> String {
        var result: String?
        let (hr, minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        // hr, min, 60 * secf
        if hr == 0, min == 0 {
            result = String(format: "%.0f", 60 * secf) + "s"
        } else if hr == 0, min < 60 {
            result = String(format: "%.0f", min) + "m " + String(format: "%.0f", 60 * secf) + "s"
        } else if hr < 25 {
            result = String(format: "%.0f", hr) + "h " + String(format: "%.0f", min) + "m"
        } else {
            result = String(format: "%.0f", hr / 24) + "d"
        }
        return result ?? ""
    }

    // Setting date format
    func setDateformat() -> DateFormatter {
        let dateformatter = DateFormatter()
        // We are forcing en_US format of date strings
        dateformatter.locale = Locale(identifier: "en_US")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter
    }
}

extension Date {
    func shortlocalized_string_from_date() -> String {
        // MM-dd-yyyy HH:mm
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "MM-dd-yyyy:HH:mm"
        return dateformatter.string(from: self)
    }
}
