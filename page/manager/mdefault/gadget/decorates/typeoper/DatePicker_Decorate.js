/**
* @namespace
* @name DatePicker_Decorate 
* @description  undefined 
*/
define(function(require, exports, module) {
    var FW = require("breeze/framework/js/BreezeFW");
    require("servicegadget/manager/decorates/TypeDecorate");
    FW.register({
        "name": "DatePicker_Decorate",
        "extends": ["TypeDecorate"],
        /**
        *@function
        *@memberOf DatePicker_Decorate
        *@name onCreate$onCreate
        *@description
        */
        "onCreate": function() {},
        "public": {
            /**
            *@function
            *@memberOf DatePicker_Decorate
            *@name public$getTypeDecorateEditData
            *@description
            *@param metadata 描述数据
            *@param data 显示数据
            */
            "getTypeDecorateEditData": function(metadata, data) {
                if (!metadata) {
                    alert("DatePicker_Decorate描述数据不可以为空！");
                    return;
                }
                var _type = this.gadgetName.replace("_Decorate", "");
                data = data ? FW.use("DateTime").formatTimeStamp(data, "yyyy-MM-dd") : null;
                var _data = {
                    metadata: metadata,
                    data: data,
                    appId: this.id
                };
                return this.API.show("DatePicker_Decorate", _data, "_");
            },
            /**
            *@function
            *@memberOf DatePicker_Decorate
            *@name public$getTypeDecorateData
            *@description
            */
            "getTypeDecorateData": function() {
                var query = "div[data-value='" + this.id + "']";
                var inputStr = $(query).find(".datepickerset").val();
                if (inputStr == null || inputStr == "") {
                    return "";
                }
                return FW.use("DateTime").format4(inputStr, "yyyy-MM-dd").getTime();
            },
            /**
            *@function
            *@memberOf DatePicker_Decorate
            *@name public$getTypeDecorateDisplayData
            *@description
            */
            "getTypeDecorateDisplayData": function(data, metadata) {
                if (!metadata) {
                    alert("DatePicker_Decorate描述数据不可以为空！");
                    return;
                }
                var _data = data ? FW.use("DateTime").formatTimeStamp(data, "yyyy-MM-dd") : "";
                return _data;
            },
            /**
            *@function
            *@memberOf DatePicker_Decorate
            *@name public$getTableHeadDisplayData
            *@description
            */
            "getTableHeadDisplayData": function(title, fieldName, id, status) {
                //初始变量
                var result = null;
                //根据状态显示不同的箭头
                var statusStr = "";
                if (status == 1) {
                    statusStr = "<a href='#' onclick=\"var app = FW.getAPP('" + id + "');app.changeListOrderBy('" + fieldName + "');return false;\"><apan class='pull-right glyphicon glyphicon-arrow-up'></span></a>"
                } else if (status == 2) {
                    statusStr = "<a href='#' onclick=\"var app = FW.getAPP('" + id + "');app.changeListOrderBy('" + fieldName + "');return false;\"><apan class='pull-right glyphicon glyphicon-arrow-down'></span></a>"
                }
                //合并结果并返回
                result = "<th> <a href='#' onclick=\"var app = FW.getAPP('" + id + "');app.changeListOrderBy('" + fieldName + "');return false;\">" + title + "</a>" + statusStr + "</th>";
                return result;
            }
        },
        view: {
            'DatePicker_Decorate': require("./resource/DatePicker_Decorate/DatePicker_Decorate.tpl")
        }

    },
    module);
    return FW;
});