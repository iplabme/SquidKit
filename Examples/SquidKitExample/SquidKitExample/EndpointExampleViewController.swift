//
//  EndpointTestTableViewController.swift
//  SquidKitExample
//
//  Created by Mike Leavy on 8/29/14.
//  Copyright (c) 2014 SquidKit. All rights reserved.
//

import UIKit
import SquidKit

class EnpointTableItem: TableItem {
    var endpoint:JSONResponseEndpoint!
    
    init(_ endpoint:JSONResponseEndpoint) {
        self.endpoint = endpoint
        
        super.init(endpoint.url())
        
        self.reuseIdentifier = "endpointCellIdentifier"
        self.selectBlock = {[unowned self] (item:TableItem, indexPath:NSIndexPath, actionsTarget:TableActions?) -> () in
            if let aTable = actionsTarget {
                aTable.deselect(indexPath)
            }
            self.endpoint.connect {(JSON, status) -> Void in
                switch status {
                case .OK:
                    Log.print("Everything worked")
                case .HTTPError(let code, let message):
                    Log.print("\(code): \(message)")
                case .NotConnectedError:
                    Log.message("maybe turn on the internets")
                case .HostConnectionError:
                    Log.message("can't find that host")
                case .ResourceUnavailableError:
                    Log.message("can't find what you're looking for")
                case .UnknownError(let error):
                    Log.print(error)
                default:
                    break
                }
            }
        }
    }
    
    override func titleForIndexPath(_ indexPath: IndexPath) -> String? {
        return self.endpoint.url()
    }
}

class EndpointExampleViewController: TableItemBackedTableViewController {

    var hostMapManager:HostMapManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // want to reset the cached host mappings? uncomment this:
        //HostMapManager.sharedInstance.hostMapCache?.removeAll()
        
        // load the host map file
        hostMapManager = HostMapManager(cacheStore: Preferences())
        hostMapManager.loadConfigurationMapFromResourceFile("HostMap.json")
        
        // want to set all configurations to their "prerelease" values? uncomment this:
        //HostMapManager.sharedInstance.setPrereleaseConfigurations()
        
        // want to set all configurations to thier "release" values? uncomment this:
        //HostMapManager.sharedInstance.setReleaseConfigurations()
        
        // otherwise, you'll proably want to just live with the cached settings, especially during
        // the course of the client and server development period
        
        
        // This is just here to print out the configurations that we've loaded
        for hostMap in hostMapManager.hostMaps {
            Log.print(hostMap.releaseKey)
            Log.print(hostMap.prereleaseKey)
            for key in hostMap.mappedPairs.keys {
                Log.print(key)
                Log.print(hostMap.mappedPairs[key]!.description)
            }
        }

        // Here we build the table view model. Using the "TableItem" model in this case isn't optimal, since we already have a real model
        // (i.e. the HostMaps that are in the HostMapManager). However, this simplifies getting the table view controller up and running...
        let configurationSection = TableSection("Configuration")
        let configurationItem = TableItem("Configure", reuseIdentifier:"configCellIdentifier", selectBlock: {[weak self] (item:TableItem, indexPath:IndexPath, actionsTarget:TableActions?) -> () in
            let configurationViewController:HostConfigurationTableViewController = HostConfigurationTableViewController(style: .Grouped)
            if let strongSelf = self {
                configurationViewController.hostMapManager = strongSelf.hostMapManager
                strongSelf.navigationController!.pushViewController(configurationViewController, animated: true)
            }
            
        })
        configurationSection.append(configurationItem)
        self.model.append(configurationSection)
        
        let endpointsSection = TableSection("Endpoints")
        let endpoint1 = EnpointTableItem(TestEndpoint())
        let endpoint2 = EnpointTableItem(NHTSATestEndpoint())
        endpointsSection.append(endpoint1)
        endpointsSection.append(endpoint2)
        self.model.append(endpointsSection)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let tableItem = self.model[indexPath]!
        
        let cell = tableView.dequeueReusableCellWithIdentifier(tableItem.reuseIdentifier!, forIndexPath: indexPath) 

        if let title = tableItem.titleForIndexPath(indexPath) {
            cell.textLabel!.text = title
        }
        else {
            cell.textLabel!.text = tableItem.title
        }

        return cell
    }
}

extension Endpoint : EndpointLoggable {
    public func log<T>(_ output:@autoclosure () -> T?) {
        Log.print(output)
    }
    
    public var requestLogging:EndpointLogging {
        get {
            return .Verbose
        }
    }
    
    public var responseLogging:EndpointLogging {
        get {
            return .Verbose
        }
    }
}

extension Preferences : HostMapCacheStorable {
    public func setEntry(_ entry:[String: AnyObject], key:String) {
        self.setPreference(entry, key: key)
    }
    
    public func getEntry(_ key:String) -> [String: AnyObject]? {
        return self.preference(key) as? [String: AnyObject]
    }
    
    public func remove(_ key:String) {
        self.remove(key)
    }
}


