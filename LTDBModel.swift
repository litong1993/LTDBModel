//
//  LTDBModel.swift
//  FMDBDataManager
//
//  Created by 李童 on 16/7/27.
//  Copyright © 2016年 Mr.Li. All rights reserved.
//

import UIKit
func swift_object_getClass(anyclass:AnyClass)->String{
    let name = NSStringFromClass(anyclass).componentsSeparatedByString(".").last
    return name!
}
enum LTDBModelDataType:String {
    case NSString = "NSString"
    case NSNumber = "NSNumber"
    case NSDate = "NSDate"
    case NSData = "NSData"
    case UIImage = "UIImage"
}
enum SqliteDataType:String{
    /// 用来保存整形数字
    case INTEGER = "INTEGER"
    /// 用来保存浮点数字
    case REAL = "REAL"
    /// 用来保存文字类型
    case TEXT = "TEXT"
    /// 用来保存时间类型
    case DATE = "DATE"
    /// 完全根据它的输入存储，可以用来保存二进制类型，例如图片等数据
    case BLOB = "BLOB"
}
class LTDBModel: NSObject {
    override class func initialize(){
        if class_getSuperclass(self) == LTDBModel.classForCoder(){
            self.createTable()
        }
    }
    required override init() {
        super.init()
    }
    //MARK: 获取类信息
    /**
     获取本类的所有属性名和对应的数据类型
     
     - returns: [属性名：数据类型]
     */
    class func propertyAndType()->[String:LTDBModelDataType]{
        var dic:[String:LTDBModelDataType] = [:]
        var propertyNum:UInt32 = 0
        let propertyList = class_copyPropertyList(self, &propertyNum)
        for index in 0..<numericCast(propertyNum){
            let property:objc_property_t = propertyList[index]
            if let parName = String(UTF8String: property_getName(property)){
                if let parType = (String(UTF8String: property_getAttributes(property))){
                    switch parType {
                    case let parType where parType.containsString(LTDBModelDataType.NSString.rawValue) :
                        dic[parName] = LTDBModelDataType.NSString
                    case let parType where parType.containsString(LTDBModelDataType.NSNumber.rawValue) :
                        dic[parName] = LTDBModelDataType.NSNumber
                    case let parType where parType.containsString(LTDBModelDataType.NSDate.rawValue) :
                        dic[parName] = LTDBModelDataType.NSDate
                    case let parType where parType.containsString(LTDBModelDataType.NSData.rawValue) :
                        dic[parName] = LTDBModelDataType.NSData
                    case let parType where parType.containsString(LTDBModelDataType.UIImage.rawValue) :
                        dic[parName] = LTDBModelDataType.UIImage
                    default:
                        dic[parName] = LTDBModelDataType.NSData
                    }
                }
            }
        }
        free(propertyList)
        return dic
    }
    /**
     根据属性名和属性信息得到对应的列名和列的类型信息
     
     - returns: [列名：类型]
     */
    class func columeAndType()->[String:String]{
        var dic:[String:String] = [:]
        var propertyNum:UInt32 = 0
        let propertyList = class_copyPropertyList(self, &propertyNum)
        for index in 0..<numericCast(propertyNum){
            let property:objc_property_t = propertyList[index]
            if let parName = String(UTF8String: property_getName(property)){
                //print("parName:",parName)
                if self.removeColumn().contains(parName){
                    continue
                }
                if let parType = (String(UTF8String: property_getAttributes(property))){
                    //print("parType:",parType)
                    switch parType {
                    case let parType where parType.containsString("NSString") :
                        dic[parName] = SqliteDataType.TEXT.rawValue
                    case let parType where parType.containsString("NSNumber") :
                        if let par = self.describeColumnDict()[parName] where par.isAutoincrement == true {
                            dic[parName] = SqliteDataType.INTEGER.rawValue
                        }else{
                            dic[parName] = SqliteDataType.REAL.rawValue
                        }
                    case let parType where parType.containsString("NSDate") :
                        dic[parName] = SqliteDataType.DATE.rawValue
                    case let parType where parType.containsString("NSData") :
                        dic[parName] = SqliteDataType.BLOB.rawValue
                    default:
                        dic[parName] = SqliteDataType.BLOB.rawValue
                    }
                }
            }
        }
        free(propertyList)
        return dic
    }
    /**
     获取所有的列名
     
     - returns: [列名]
     */
    class func allColume()->[String]{
        var allColume:[String] = []
        for (colume,_) in self.columeAndType(){
            allColume.append(colume)
        }
        return allColume
    }
    /**
     获取所有的类型
     
     - returns: [类型]
     */
    class func allType()->[String]{
        var allType:[String] = []
        for (_,type) in self.columeAndType(){
            allType.append(type)
        }
        return allType
    }
    /**
     获得主键
     
     - returns: 可为空
     */
    class func getPK()->String?{
        for (key,value) in self.describeColumnDict(){
            if value.isPrimaryKey == true{
                return key
            }
        }
        return nil
    }
    //MARK:子类须重写
    /**
     对字段加修饰属性   具体请参考LKDBColumnDes类
     
     - returns: [属性名：属性修饰]
     */
    class func describeColumnDict()->[String:LTDBColumnDes]{
        return [:]
    }
    /**
     不需要存储的字段
     
     - returns: [属性名]
     */
    class func removeColumn()->[String]{
        return []
    }
    //MARK:表操作
    /**
     是否存在表
     
     - returns: <#return value description#>
     */
    class func isExistInTable()->Bool{
        var res = false
        let tableName = swift_object_getClass(self)
        LTDBTool.shareInstance.dbQueue.inDatabase { (db:FMDatabase!) in
            res = db.tableExists(tableName)
        }
        return res
    }
    /**
     创建表格
     
     - returns: <#return value description#>
     */
    class func createTable()->Bool{
        //类名 [属性名:属性类型]
        let tableName = swift_object_getClass(self)
        var columeAndTypeStr:[String] = []
        for (colume,type) in self.columeAndType(){
            if let par = self.describeColumnDict()[colume]{
                columeAndTypeStr.append("\(colume) \(type) \(par.columnAttribute)")
            }else{
                columeAndTypeStr.append("\(colume) \(type)")
            }
            
        }
        let sql = "CREATE TABLE IF NOT EXISTS \(tableName)(\(columeAndTypeStr.joinWithSeparator(",")));"
        //print(sql)
        return self.fmdbUpdate(sql)
    }
    //MARK:单数据操作
    /**
     根据主键保存或者更新，如果没有主键，则直接保存，如果有主键，先查询，如果有数据，则更新，无数据则保存
     
     - returns: <#return value description#>
     */
    func saveOrupdate()->Bool{
        if let pk = self.dynamicType.getPK(){
            if let _ = self.dynamicType.findByPK(self.valueForKey(pk)){
                return self.update()
            }else{
                return self.save()
            }
        }else{
            return self.save()
        }
    }
    /**
     保存单个对象
     
     - returns: <#return value description#>
     */
    func save()->Bool{
        let tableName = self.dynamicType
        let allColumn = self.dynamicType.allColume()
        
        var insertClunmn:[String] = []
        var insertValues:[AnyObject] = []
        for column in allColumn{
            if let value = self.valueForKey(column){
                insertClunmn.append(column)
                if let img = value as? UIImage{
                    if let imgData = UIImagePNGRepresentation(img){
                        insertValues.append(imgData)
                    }
                }else{
                    insertValues.append(value)
                }
            }
        }
        let values = insertClunmn.map { (item) -> String in
            return "?"
        }
        //print(insertClunmn)
        let sql = "INSERT INTO \(tableName) (\(insertClunmn.joinWithSeparator(","))) VALUES (\(values.joinWithSeparator(",")));"
        //print(sql,insertValues)
        return self.dynamicType.fmdbUpdate(sql, values: insertValues)
    }
    /**
     删除对象
     
     - returns: <#return value description#>
     */
    func delete()->Bool{
        if let pk = self.dynamicType.getPK(){
            if let type = self.dynamicType.columeAndType()[pk]{
                if let pkValue = self.valueForKey(pk){
                    var formate:String = ""
                    if type == SqliteDataType.TEXT.rawValue{
                        formate = "WHERE  \(pk) = '\(pkValue)'"
                    }else{
                        formate = "WHERE  \(pk) = \(pkValue)"
                    }
                    return self.dynamicType.deleteObjc(formate)
                }
                
            }
        }
        return false
    }
    /**
     更新单条数据
     
     - returns: <#return value description#>
     */
    func update()->Bool{
        if let pk = self.dynamicType.getPK(){
            if let pkValue = self.valueForKey(pk){
                let tableName = self.dynamicType
                let allColumn = self.dynamicType.allColume()
                
                var updateClunmn:[String] = []
                var updateValues:[AnyObject] = []
                for column in allColumn{
                    if let value = self.valueForKey(column){
                        updateClunmn.append(column)
                        if let img = value as? UIImage{
                            if let imgData = UIImagePNGRepresentation(img){
                                updateValues.append(imgData)
                            }
                        }else{
                            updateValues.append(value)
                        }
                    }
                }
                
                let values = updateClunmn.map { (item) -> String in
                    return "\(item) = ?"
                }
                
                updateValues.append(pkValue)
                let sql = "UPDATE \(tableName) SET \(values.joinWithSeparator(", ")) WHERE \(pk) = ?;"
                //print(sql,"And",updateValues)
                return self.dynamicType.fmdbUpdate(sql, values: updateValues)
                
            }else{
                return false
            }
        }else{
            return false
        }
        
    }
    /**
     根据条件查询第一条数据
     
     - parameter formate: 查询条件，如果为空，则查询全部
     
     - returns: <#return value description#>
     */
    class func findFirst(formate:String = "")->LTDBModel?{
        return self.find(formate).first
    }
    /**
     根据主键查询数据
     
     - parameter pkValue: 主键值
     
     - returns: <#return value description#>
     */
    class func findByPK(pkValue:AnyObject?)->LTDBModel?{
        if pkValue == nil{
            return nil
        }
        if let pk = self.getPK(){
            if let type = self.columeAndType()[pk]{
                var formate:String = ""
                if type == SqliteDataType.TEXT.rawValue{
                    formate = "WHERE  \(pk) = '\(pkValue!)'"
                }else{
                    formate = "WHERE  \(pk) = \(pkValue!)"
                }
                return self.findFirst(formate)
            }
        }
        return nil
    }
    //MARK:多数据操作
    /**
     保存数组对象
     
     - parameter array: LTDBModel 的子类数组
     
     - returns: <#return value description#>
     */
    class func saveObjc(array:[LTDBModel])->Bool{
        for model in array{
            if !model.save() {
                return false
            }
        }
        return true
    }
    /**
     保存或更新数组对象
     
     - parameter array: LTDBModel 的子类数组
     
     - returns: <#return value description#>
     */
    class func saveOrUpateObjc(array:[LTDBModel])->Bool{
        for model in array{
            if !model.saveOrupdate() {
                return false
            }
        }
        return true
    }

    /**
     查找全部数据
     
     - returns: <#return value description#>
     */
    class func findAll()->[LTDBModel]{
        return self.find()
    }
    
    /**
     根据条件查询数据
     
     - parameter formate: 查询条件，如果为空，则查询全部
     
     - returns: <#return value description#>
     */
    class func find(formate:String = "")->[LTDBModel]{
        let tableName = swift_object_getClass(self)
        let sql = "SELECT * FROM \(tableName) \(formate)"
        //print(sql)
        return self.fmdbQuery(sql)
    }
    
    /**
     删除全部数据
     
     - returns: <#return value description#>
     */
    class func deleteAll()->Bool{
        let tableName = swift_object_getClass(self)
        let sql = "DELETE FROM \(tableName)"
        //print(sql)
        return self.fmdbUpdate(sql)
    }
    /**
     根据条件删除数据
     
     - parameter formate: 条件
     
     - returns: <#return value description#>
     */
    class func deleteObjc(formate:String = "")->Bool{
        let tableName = swift_object_getClass(self)
        let sql = "DELETE FROM \(tableName) \(formate)"
        //print(sql)
        return self.fmdbUpdate(sql)
    }
    /**
     根据主键删除数据
     
     - parameter pkValue: 主键值
     
     - returns: <#return value description#>
     */
    class func deleteByPK(pkValue:AnyObject)->Bool{
        if let pk = self.getPK(){
            if let type = self.columeAndType()[pk]{
                var formate:String = ""
                if type == SqliteDataType.TEXT.rawValue{
                    formate = "WHERE  \(pk) = '\(pkValue)'"
                }else{
                    formate = "WHERE  \(pk) = \(pkValue)"
                }
                return self.deleteObjc(formate)
            }
        }
        return false
    }
    
    class func fmdbUpdate(sql:String,values:[AnyObject]? = [])->Bool{
        let lkDB = LTDBTool.shareInstance
        var res = false
        lkDB.dbQueue.inDatabase { (db:FMDatabase!) in
            do{
                try db.executeUpdate(sql, values: values)
                res = true
            }catch let error as NSError{
                print(error.localizedDescription)
                res = false
            }
        }
        return res
    }
    class func fmdbQuery(sql:String,values:[AnyObject]? = [])->[LTDBModel]{
        let lkDB = LTDBTool.shareInstance
        var objc:[LTDBModel] = []
        lkDB.dbQueue.inDatabase { (db:FMDatabase!) in
            do{
                let re = try db.executeQuery(sql, values: values)
                
                while re.next(){
                    let model = self.init()
                    for i in 0..<self.allColume().count{
                        
                        let columeName = self.allColume()[i]
                        
                        if let columeType = self.propertyAndType()[columeName]{
                            switch columeType {
                            case .NSString :
                                model.setValue(re.stringForColumn(columeName), forKey: columeName)
                            case .NSNumber :
                                model.setValue(NSNumber(longLong: re.longLongIntForColumn(columeName)), forKey: columeName)
                            case .NSDate :
                                model.setValue(re.dateForColumn(columeName), forKey: columeName)
                            case .NSData :
                                model.setValue(re.dataForColumn(columeName), forKey: columeName)
                            case .UIImage :
                                //model.setValue(re.dataForColumn(columeName), forKey: columeName)
                                let imgData = re.dataForColumn(columeName)
                                if imgData == nil{
                                    model.setValue(imgData, forKey: columeName)
                                }else{
                                    let img = UIImage(data: imgData)
                                    model.setValue(img, forKey: columeName)
                                }
                                
                            }
                            
                        }
                    }
                    objc.append(model)
                }
                
            }catch let error as NSError{
                print(error.localizedDescription)
                
            }

        }
        return objc
    }
    
}
