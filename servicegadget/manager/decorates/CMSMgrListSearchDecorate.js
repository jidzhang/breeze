/**
* @namespace
* @name CMSMgrListSearchDecorate 
* @description  undefined 
*/
define(function(require, exports, module) {
    var FW = require("breeze/framework/js/BreezeFW");
    require("../CMSMgrDecorate");
    FW.register({
        "name": "CMSMgrListSearchDecorate",
        "extends": ["CMSMgrDecorate"],
        /**
        *@function
        *@memberOf CMSMgrListSearchDecorate
        *@name onCreate$onCreate
        *@description
        */
        "onCreate": function() {
            //toDO
        },
        "private": {
            /**
            *@function
            *@memberOf CMSMgrListSearchDecorate
            *@name private$processingData
            *@description 重载父类方法，处理列表中的一些数据
            *@param data 传入的数据
            */
            "processingData": function(data) {
                return {
                    metadata: data.metadata
                };
            }
        }
    },module);
    return FW;
});