<div class="form-group">
	<label class="control-label col-lg-2">${data.metadata.title}</label>
	<div class="col-lg-6" data-value="${data.appId}" data-type="${data.metadata.type}">
		<div class="input-group bootstrap-timepicker">
			<input class="timepickerset form-control" type="text" value="${data.data||''}" data-date-format="hh:ii:ss">
			<span class="input-group-addon add-on"><i class="glyphicon glyphicon glyphicon-time"></i></span>
		</div>
	</div>
</div>