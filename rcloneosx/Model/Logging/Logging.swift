//
//  Logging.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

class Logging {
    
    var outputprocess: OutputProcess?
    var log: String?
    var filename: String?
    var fileURL: URL?
    
    private func write() {
        do {
            try self.log!.write(to: self.fileURL!, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError  {
            print(error)
        }
    }
    
    private func read() {
        do {
            self.log = try String(contentsOf: self.fileURL!, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print(error)
        }
        
    }
    
    private func logg() {
        self.read()
        self.log = self.log ?? "" + self.outputprocess!.getOutput()!.joined(separator: "\n")
        self.write()
    }
    
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    init(outputprocess: OutputProcess?) {
        self.outputprocess = outputprocess
        self.filename = "rclonelog"
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.fileURL = DocumentDirURL.appendingPathComponent(self.filename!).appendingPathExtension("txt")
        self.logg()
    }
}
