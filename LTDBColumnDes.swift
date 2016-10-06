//
//  LTDBColumnDes.swift
//  FMDBDataManager
//
//  Created by 李童 on 16/7/29.
//  Copyright © 2016年 Mr.Li. All rights reserved.
//

import UIKit
private let NOTModify = "" //无任何修饰
private let DBPrimaryKey:String   = "primary key" //设置主键
private let AUTOINCREMENT:String = "AUTOINCREMENT" //自增长
private let NOTNULL:String = "NOT NULL" //非空
private let UNIQUE:String = "UNIQUE" //约束
/*
enum SqliteDataType:String{
    /// 用来保存整形
    case INTEGER = "INTEGER"
    /// 用来保存浮点
    case REAL = "REAL"
    /// 用来保存文字类型
    case TEXT = "TEXT"
    /// 用来保存bool型
    case BOOL = "BOOLEAN"
}
 */
class LTDBColumnDes: NSObject {
    /// 是否为主键
    var isPrimaryKey:Bool = false
    /// 是否为自增长
    var isAutoincrement:Bool = false
    /// 是否可为空
    var isNotNull:Bool = true
    /// 是否唯一
    var isUnique:Bool = false
    /// 约束
    var check:String = ""
    /// 默认值
    var defaultValue:String = ""
    /// 需要保存到数据库的值
    override init() {
    }
    convenience init(isPrimaryKey:Bool,isAutoincrement:Bool,isNotNull:Bool,isUnique:Bool,check:String,defaultValue:String) {
        self.init()
        self.isPrimaryKey = isPrimaryKey
        self.isAutoincrement = isAutoincrement
        self.isNotNull = isNotNull
        self.isUnique = isUnique
        self.check = check
        self.defaultValue = defaultValue
    }
    lazy var columnAttribute:String = { [unowned self] in
        var attributeArr:[String] = []
        if self.isPrimaryKey{ attributeArr.append(DBPrimaryKey)}
        if self.isAutoincrement{ attributeArr.append(AUTOINCREMENT)}
        if self.isNotNull == true { attributeArr.append(NOTNULL)}
        if self.isUnique{ attributeArr.append(UNIQUE)}
        if self.check.isEmpty == false { attributeArr.append("CHECK(\(self.check))")}
        if self.defaultValue.isEmpty == false { attributeArr.append("DEFAULT \(self.defaultValue)")}
        var attributeStr = attributeArr.joinWithSeparator(" ")
        return attributeStr
    }()
}
