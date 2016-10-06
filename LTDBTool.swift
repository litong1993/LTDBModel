//
//  LTDBTool.swift
//  FMDBDataManager
//
//  Created by 李童 on 16/7/27.
//  Copyright © 2016年 Mr.Li. All rights reserved.
//

import UIKit
private let sharedTool = LTDBTool()
class LTDBTool: NSObject {
    override init() {
        dbQueue = FMDatabaseQueue(path: LTDBTool.dbPath)
        super.init()
    }
    var dbQueue:FMDatabaseQueue
    class var shareInstance:LTDBTool{
        return sharedTool
    }
    class var dbPath:String{
        return self.dbPathWithDirectoryName(nil)
    }
    
    private class func dbPathWithDirectoryName(directoryName:String?)->String{
        if var docsdir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).last{
            let filemanage = NSFileManager.defaultManager()
            if directoryName == nil || directoryName?.isEmpty == true{
                docsdir = docsdir.stringByAppendingString("/LTDB")
            }else{
                docsdir = docsdir.stringByAppendingString("/\(directoryName!)")
            }
            let isDir:ObjCBool = false
            let pointer = UnsafeMutablePointer<ObjCBool>.alloc(1)
            pointer.initialize(isDir)
            let exit = filemanage.fileExistsAtPath(docsdir, isDirectory: pointer)
            if !exit || !isDir{
                try! filemanage.createDirectoryAtPath(docsdir, withIntermediateDirectories: true, attributes: nil)
            }
            let dbpath = docsdir.stringByAppendingString("/ltdb.sqlite")
            return dbpath
        }else{
            return ""
        }
        
    }
    func changeDBWithDirectoryName(directoryName:String)->Bool{
        
        dbQueue = FMDatabaseQueue(path: LTDBTool.dbPathWithDirectoryName(directoryName))
        return true
    }
    func createAllTable(){
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass?>.alloc(Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass?>(allClasses)
        let actualClassCount:Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        for i in 0 ..< actualClassCount {
            if let currentClass: AnyClass = allClasses[Int(i)] {
                if class_getSuperclass(currentClass) == LTDBModel.classForCoder(){
                    (currentClass as! LTDBModel.Type).createTable()
                }
            }
        }
    }

}
