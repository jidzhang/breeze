


		<div class="panel panel-default">
			<div class="panel-body">
				<div id="wizard" role="application" class="wizard">
					<div class="steps clearfix">
						<ul class="nav nav-pills">
							<!--$for(var i=0;i<data.cfgList.length;i++){-->
							<li role="presentation" class="active">
								<a href="javascript:void(0);" aria-controls="wizard-p-0" onclick="FireEvent.changeInfo('${data.cfgList[i].sig}',this)">
									<span class="number"></span>${data.cfgList[i].name}
								</a>
							</li>
							<!--$}-->
						</ul>
					</div>
					<!--$for (var n in data.cfgData){-->
					<textarea style="display:none" info-id="${n}" name="${data.appId}.${n}" class="col-lg-12">${data.cfgData[n]}</textarea>
					<!--$}-->			
				</div>
			</div>
		</div>

