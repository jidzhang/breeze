﻿define(function(require, exports, module) {
	var FW = require("../../breeze/framework/js/BreezeFW");
	var formatJS = require("../../breeze/framework/js/tools/formatJS");
	FW.register(
		{
			name:"cservice",
			onCreate:function(){
				//整理所有的处理逻辑
				var ps=[];
				for (var pname in flows){
					if (flows.hasOwnProperty(pname)){
						ps.push(pname);
					}
				}
				ps.sort();
				
				//线判断参数中是否将包名以及service传入，如果有传入则直接跳转
				//传入的参数说明：service="package.service"
				var allservice = FW.use().getParameter("fileUrl");
				if (allservice != null){
					allservice = allservice.replace(/\//ig,'.').replace('.brz','');
					var allservicearr = allservice.split(".");
					var service = allservicearr.pop();
					var package = allservicearr.join(".");
					var listName = serviceNames[package];
					if (listName != null){
						for ( var i=0;i<listName.length;i++){
						    if (service == listName[i].name){
						    	//去编辑那边
						    	this.API.doServer("GetService","service",{service:allservice},
								function(__code,__data){
									var data = eval("("+__data+")");
									var flow = data.flowName;
									this.showEdit(flow,package,data);
								});
						    	return;
						    }
						}
					}
				}
				
				this.API.show("view_selectFlow",ps);
				// 2016-08-29 15:08 FrankCheng 增加下拉输入框
				$('#v_flows').chosen();				
			},
			public:{
				showEdit:function(__flow,__package,__data){
					    this.param.flow = __flow;
					    var package = __package || "";
						//下面构造填写process部分和service填写不服
						var formDesc = {
							serviceName : {
								title: "serviceName",
								type: "Text",
								valueRange: [{
												checkers:[
													/\w+/
												],
												failTips:'请输入正确业务名称'
											}],
								desc: "serviceName"
							},
							flowName : {
								title:"flow",
								type: "Text",
								desc:"flow的名称"
							},
							toolsMemoDesc0000:{
								title:"备注说明",
								type:"TextArea",
								desc:"对本配置进行一个说明，关键字是toolsMemoDesc0000，字段不要与业务冲突，该字段不参与业务逻辑作用"
							}
						}
						for (var dd in flows[__flow]){
							if (flows[__flow].hasOwnProperty(dd)){
								formDesc[dd] = flows[__flow][dd];
							}
						}
						this.API.show("view_mainform",package);
						if (__data == null){
							__data = {
									flowName:__flow
							}
						}
						FW.use().createForm(formDesc,this.API.find("#myform"),__data);
					}
			},
			FireEvent:{
				showCfg:function(__type){
					var param = FW.use().getParameter("fileUrl");
					if (param != null){
						param = param.replace(/\//ig,'.').replace('.brz','');
					}
					
					var flow = service = null;
					var package = "";
					
					if (__type == 0 && param == null){
						//选择flow后，完全新建情况
						var flow = this.API.find("#v_flows").val();
						this.showEdit(flow);
					}else if(__type == 0 && param != null){
						//选择flow后，新建，但是参数中传入了servicename和flow的名称
						var allservicearr = param.split(".");
						var service = allservicearr.pop();
						var package = allservicearr.join(".");
						var flow = this.API.find("#v_flows").val();
						var defaultData = {
							serviceName:service,
							flowName:flow
						}
						this.showEdit(flow,package,defaultData);
					}
					else {
						service = this.API.find("#v_name").val();
						package = this.API.find("#v_package").val();
						
						this.API.doServer("GetService","service",{service:service},
								function(__code,__data){
							var data = eval("("+__data+")");
							var flow = data.flowName;
							this.showEdit(flow,package,data);
						});
					}					
				},
				showResult:function(){
					var package = this.API.find('#package').val();
					var inData = this.API.find("#myform")[0].getData();
					if (inData.flowName == null){
						inData.flowName = this.param.flow;
					}
					
					var result = FW.use().toJSONString(inData);
					//2014-10-18罗光瑜，格式化
					result = formatJS.js_beautify(result);
					var data = {
						package:package,
						serviceName:inData.serviceName,
						data:result
					}
					this.API.show("view_result",data);
				},
				changePackage:function(){
					var packageName = this.API.find("#v_package").val();
					var list = serviceNames[packageName];
					this.API.show("view_selectPackage",{sall:serviceNames,nameList:list});
					this.API.find("#v_package").val(packageName);
					// 2016-08-29 15:08 FrankCheng 增加下拉输入框
					$('#v_package').chosen();
					$('#v_name').chosen();
				},
				submit:function(){
					var param = {
							data:this.API.find("#textshow").val(),
							servicename:this.API.find("#serviceName").val(),
							package:this.API.find("#package").val()
					};
					this.API.doServer("SetService","service",param,
							function(code,data){
						window.location.reload();
					});
				},
				go2Create:function(){
					//整理所有的处理逻辑
					var ps=[];
					for (var pname in flows){
						if (flows.hasOwnProperty(pname)){
							ps.push(pname);
						}
					}
					this.API.show("view_selectProcess",ps);
				},
				go2Edit:function(){					
					//整理所有的处理逻辑
					var nameList = null;
					console.log(serviceNames);
					for (var name in serviceNames){
						nameList = serviceNames[name];
						break;
					}
					this.API.show("view_selectPackage",{sall:serviceNames,nameList:nameList});
					// 2016-08-29 15:08 FrankCheng 增加下拉输入框
					$('#v_package').chosen();
					$('#v_name').chosen();
				}
			},
			TrigetEvent:{
				showAddContent:function(__type,__nodeId){
					
				}
			}
		}
	);
	return FW;
});
