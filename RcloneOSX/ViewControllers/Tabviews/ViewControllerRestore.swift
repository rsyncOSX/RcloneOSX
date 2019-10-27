//
//  ViewControllerRestore.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 09.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

enum Work {
    case localinfoandnumbertosync
    case getremotenumbers
    case setremotenumbers
    case restore
}

class ViewControllerRestore: NSViewController, SetConfigurations, Remoterclonesize, Setcolor, VcMain {

    @IBOutlet weak var restoretable: NSTableView!
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var gotit: NSTextField!

    @IBOutlet weak var transferredNumber: NSTextField!
    @IBOutlet weak var totalNumber: NSTextField!
    @IBOutlet weak var totalNumberSizebytes: NSTextField!
    @IBOutlet weak var restorebutton: NSButton!
    @IBOutlet weak var tmprestore: NSTextField!
    @IBOutlet weak var selecttmptorestore: NSButton!
    @IBOutlet weak var estimatebutton: NSButton!

    var outputprocess: OutputProcess?
    var restorecompleted: Bool = false
    weak var sendprocess: SendProcessreference?
    var diddissappear: Bool = false
    var workqueue: [Work]?
    var index: Int?

    @IBAction func restore(_ sender: NSButton) {
        let answer = Alerts.dialogOKCancel("Do you REALLY want to start a RESTORE ?", text: "Cancel or OK")
        if answer {
            if let index = self.index {
                self.gotit.textColor = setcolor(nsviewcontroller: self, color: .white)
                self.gotit.stringValue = "Executing restore..."
                self.restorebutton.isEnabled = false
                self.outputprocess = OutputProcess()
                globalMainQueue.async(execute: { () -> Void in
                    self.presentAsSheet(self.viewControllerProgress!)
                })
                self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
                switch self.selecttmptorestore.state {
                case .on:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false,
                                    tmprestore: true, updateprogress: self)
                case .off:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false,
                                   tmprestore: true, updateprogress: self)
                default:
                    return
                }
            }
        }
    }

    private func getremotenumbers() {
        if let index = self.index {
            self.outputprocess = OutputProcess()
            self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
            _ = RcloneSize(index: index, outputprocess: self.outputprocess, updateprogress: self)
        }
    }

    private func setremoteinfo() {
        guard self.outputprocess?.getOutput()?.count ?? 0 > 0 else { return }
        let size = self.remoterclonesize(input: self.outputprocess!.getOutput()![0])
        guard size != nil else { return }
        self.totalNumber.stringValue = String(NumberFormatter.localizedString(from: NSNumber(value: size!.count), number: NumberFormatter.Style.decimal))
        self.totalNumberSizebytes.stringValue = String(NumberFormatter.localizedString(from: NSNumber(value: size!.bytes/1024), number: NumberFormatter.Style.decimal))
        self.working.stopAnimation(nil)
        self.restorebutton.isEnabled = true
        self.gotit.textColor = setcolor(nsviewcontroller: self, color: .green)
        self.gotit.stringValue = "Got it..."
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.restoretable.delegate = self
        self.restoretable.dataSource = self
        ViewControllerReference.shared.setvcref(viewcontroller: .vcrestore, nsviewcontroller: self)
        self.sendprocess = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else { return }
        self.restorebutton.isEnabled = false
        self.estimatebutton.isEnabled = false
        self.settmp()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    private func settmp() {
           let setuserconfig: String = NSLocalizedString(" ... set in User configuration ...", comment: "Restore")
           self.tmprestore.stringValue = ViewControllerReference.shared.restorePath ?? setuserconfig
           if (ViewControllerReference.shared.restorePath ?? "").isEmpty == true {
               self.selecttmptorestore.state = .off
           } else {
                self.selecttmptorestore.state = .on
           }
       }

    private func setNumbers(outputprocess: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            let infotask = RemoteinfonumbersOnetask(outputprocess: outputprocess)
            self.transferredNumber.stringValue = infotask.transferredNumber!
        })
    }

    @IBAction func prepareforrestore(_ sender: NSButton) {
        if let index = self.index {
            _ = self.removework()
            self.gotit.textColor = setcolor(nsviewcontroller: self, color: .white)
            self.gotit.stringValue = "Getting info, please wait..."
            self.gotit.isHidden = false
            self.estimatebutton.isEnabled = false
            self.working.startAnimation(nil)
            self.outputprocess = OutputProcess()
            self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
            if ViewControllerReference.shared.restorePath != nil && self.selecttmptorestore.state == .on {
                _ = self.removework()
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: true, updateprogress: self)
            } else {
                self.selecttmptorestore.state = .off
                _ = self.removework()
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: false, updateprogress: self)
            }
        }
    }

    private func removework() -> Work? {
        // Initialize
        guard self.workqueue != nil else {
            self.workqueue = [Work]()
            // self.workqueue?.append(.restore)
            self.workqueue?.append(.setremotenumbers)
            self.workqueue?.append(.getremotenumbers)
            self.workqueue?.append(.localinfoandnumbertosync)
            return nil
        }
        guard self.workqueue!.count > 1 else {
            let work = self.workqueue?[0] ?? .restore
            return work
        }
        let index = self.workqueue!.count - 1
        let work = self.workqueue!.remove(at: index)
        return work
    }

    @IBAction func toggletmprestore(_ sender: NSButton) {
           self.estimatebutton.isEnabled = true
           self.restorebutton.isEnabled = false
       }

       // setting which table row is selected
       func tableViewSelectionDidChange(_ notification: Notification) {
           let myTableViewFromNotification = (notification.object as? NSTableView)!
           let indexes = myTableViewFromNotification.selectedRowIndexes
           if let index = indexes.first {
               self.estimatebutton.isEnabled = true
               self.index = index
           } else {
               self.estimatebutton.isEnabled = false
               self.index = nil
           }
           self.restorebutton.isEnabled = false
       }

    // Progressbar restore
    private func initiateProgressbar() {
        let size = self.remoterclonesize(input: self.outputprocess!.getOutput()![0])
        let calculatedNumberOfFiles = NumberFormatter.localizedString(from: NSNumber(value: size!.count), number: NumberFormatter.Style.none)
        
    }

    private func updateProgressbar(_ value: Double) {
        
    }

}

extension ViewControllerRestore: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configurations?.getConfigurationsSyncandCopy()?.count ?? 0
    }
}

extension ViewControllerRestore: NSTableViewDelegate {

   func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < self.configurations!.getConfigurationsSyncandCopy()!.count  else { return nil }
        let object: NSDictionary = self.configurations!.getConfigurationsSyncandCopy()![row]
        return object[tableColumn!.identifier] as? String
    }
}

extension ViewControllerRestore: UpdateProgress {
    func processTermination() {
        switch self.removework() ?? .setremotenumbers {
        case .getremotenumbers:
            self.setNumbers(outputprocess: self.outputprocess)
            self.getremotenumbers()
        case .setremotenumbers:
            self.setremoteinfo()
        case .restore:
            self.gotit.textColor = setcolor(nsviewcontroller: self, color: .green)
            self.gotit.stringValue = "Restore is completed..."
            self.restorecompleted = true
        case .localinfoandnumbertosync:
            self.setNumbers(outputprocess: self.outputprocess)
            guard ViewControllerReference.shared.restorePath != nil else { return }
            self.selecttmptorestore.isEnabled = true
            self.working.stopAnimation(nil)
            self.restorebutton.isEnabled = true
            self.gotit.textColor = setcolor(nsviewcontroller: self, color: .green)
            self.gotit.stringValue = "Got it..."
        }
    }

    func fileHandler() {
        if self.workqueue?.count == 1 {
            self.updateProgressbar(Double(self.outputprocess!.count()))
        }
    }
}

extension ViewControllerRestore: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
        globalMainQueue.async(execute: { () -> Void in
            self.restoretable.reloadData()
        })
    }
}
