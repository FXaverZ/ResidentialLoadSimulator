function handles = adobt_data_for_display(handles)
%ADOBT_DATA_FOR_DISPLAY    aufbereiten der Daten für GUI 'Data_Explorer'
%    HANDLES = ADOBT_DATA_FOR_DISPLAY(HANDLES) fügt der Struktur RESULTS innerhalb
%    der HANDLES Datenstruktur die Struktur DISPLAYABLE hinzu, welche die
%    aufbereiteten Daten für die Darstellung im Daten Explorer enthält. So sind
%    innerhalb dieser Struktur neben den eigentlichen Daten auch die Beschreibung,
%    Einheit, Legendeneinträge und Achsenbeschriftungen vorhanden, auf die der
%    'Data_Explorer' zurückgreift.

% Franz Zeilinger - 04.01.2012

Result = handles.Result;
time_points = max(...
	[size(Result.Households.Data,1)-1, ...
	size(Result.Solar.Data,1)-1,...
	size(Result.Wind.Data,1)-1]);
Result.Time = 0:1/time_points:1;
Result.Time = Result.Time' + datenum('00:00:00');

crv_cnt = 0;
if ~isempty(Result.Households.Data)
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamtwirkleistungsaufnahme Haushalte';
	dspl.(crv_nam).Data = Result.Households.Active_Power_Total/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = 'Gesamtwirkleistung Haushalte';
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamtblindleistungsaufnahme Haushalte';
	dspl.(crv_nam).Data = Result.Households.Reactive_Power_Total/1000;
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = 'Gesamtblindleistung Haushalte';
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kVA]';
	crv_cnt = crv_cnt + 1;
	
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamtwirkleistungsaufnahme pro Phase Haushalte';
	dspl.(crv_nam).Data = Result.Households.Active_Power_Phase/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamtblindleistungsaufnahme pro Phase Haushalte';
	dspl.(crv_nam).Data = Result.Households.Reactive_Power_Phase/1000;
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = [{'Q - L1'},{'Q - L2'},{'Q - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kVA]';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Wirkleistungsaufnahme Einzel-Haushalte';
	num_hh = size(Result.Households.Data,2)/6;
	data = zeros(size(Result.Households.Data,1),num_hh);
	legend = cell(1,num_hh);
	for i = 1:num_hh
		data(:,i) = ...
			Result.Households.Data(:,(i-1)*6+1) + ...
			Result.Households.Data(:,(i-1)*6+3) + ...
			Result.Households.Data(:,(i-1)*6+5,:);
		legend{i} = ['P - Haush. ',num2str(i)];
	end
	dspl.(crv_nam).Data = data/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Blindleistungsaufnahme Einzel-Haushalte';
	for i = 1:num_hh
		data(:,i) = ...
			Result.Households.Data(:,(i-1)*6+2) + ...
			Result.Households.Data(:,(i-1)*6+4) + ...
			Result.Households.Data(:,(i-1)*6+6);
		legend{i} = ['Q - Haush. ',num2str(i)];
	end
	dspl.(crv_nam).Data = data/1000;
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Blindleistungsaufnahme [kVA]';
end

if ~isempty(Result.Solar.Data)
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamteinspeisung PV-Anlagen';
	dspl.(crv_nam).Data = Result.Solar.Active_Power_Total/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = 'P - PV-Anlagen';
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';

	crv_cnt = crv_cnt + 1;	
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Einspeisung PV-Anlagen pro Phase';
	dspl.(crv_nam).Data = Result.Solar.Active_Power_Phase/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';

	crv_cnt = crv_cnt + 1;	
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Einspeisung PV-Anlagen, Einzelanlagen';
	num_plants = size(Result.Solar.Data,2)/6;
	data = zeros(size(Result.Solar.Data,1),num_plants);
	legend = cell(1,num_plants);
	for i=1:num_plants
		data(:,i) = ...
			Result.Solar.Data(:,(i-1)*6+1) + ...
			Result.Solar.Data(:,(i-1)*6+3) + ...
			Result.Solar.Data(:,(i-1)*6+5,:);
		legend{i} = ['P - PV ',num2str(i)]; 
	end
	dspl.(crv_nam).Data = data/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';
end

if ~isempty(Result.Wind.Data)
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Gesamteinspeisung Windkraft-Anlagen';
	dspl.(crv_nam).Data = Result.Wind.Active_Power_Total/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = 'P - Windkraft-Anlagen';
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';

	crv_cnt = crv_cnt + 1;	
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Einspeisung Windkraft-Anlagen pro Phase';
	dspl.(crv_nam).Data = Result.Wind.Active_Power_Phase/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';

	crv_cnt = crv_cnt + 1;	
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = 'Einspeisung Windkraft-Anlagen, Einzelanlagen';
	num_plants = size(Result.Wind.Data,2)/6;
	data = zeros(size(Result.Wind.Data,1),num_plants);
	legend = cell(1,num_plants);
	for i=1:num_plants
		data(:,i) = ...
			Result.Wind.Data(:,(i-1)*6+1) + ...
			Result.Wind.Data(:,(i-1)*6+3) + ...
			Result.Wind.Data(:,(i-1)*6+5,:);
		legend{i} = ['P - Windkraft ',num2str(i)];
	end
	dspl.(crv_nam).Data = data/1000;
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Wirkleistungseinspeisung [kW]';
end

Result.Displayable = dspl;
handles.Result = Result;
end

