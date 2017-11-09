function handles = adobt_data_for_display(handles)
%ADOBT_DATA_FOR_DISPLAY    aufbereiten der Daten für GUI "Datenexplorer"

Result = handles.Result;
time_points = size(Result.Households.Data,1)-1;
Result.Time = 0:1/time_points:1;
Result.Time = Result.Time' + datenum('00:00:00');

% Anzeigbare Zwischenergebnisse:
dspl.Curve_1.Title = 'Gesamtwirkleistungsaufnahme Haushalte';
dspl.Curve_1.Data = Result.Households.Acvtive_Power_Total/1000;
dspl.Curve_1.Unit = 'kW';
dspl.Curve_1.Legend = 'Gesamtwirkleistung Haushalte';
dspl.Curve_1.Y_Label = 'Wirkleistungsaufnahme [kW]';

dspl.Curve_2.Title = 'Gesamtblindleistungsaufnahme Haushalte';
dspl.Curve_2.Data = Result.Households.Reactive_Power_Total/1000;
dspl.Curve_2.Unit = 'kVA';
dspl.Curve_2.Legend = 'Gesamtblindleistung Haushalte';
dspl.Curve_2.Y_Label = 'Wirkleistungsaufnahme [kVA]';

dspl.Curve_3.Title = 'Gesamtwirkleistungsaufnahme pro Phase Haushalte';
dspl.Curve_3.Data = Result.Households.Active_Power_Phase/1000;
dspl.Curve_3.Unit = 'kW';
dspl.Curve_3.Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
dspl.Curve_3.Y_Label = 'Wirkleistungsaufnahme [kW]';

dspl.Curve_4.Title = 'Gesamtblindleistungsaufnahme pro Phase Haushalte';
dspl.Curve_4.Data = Result.Households.Reactive_Power_Phase/1000;
dspl.Curve_4.Unit = 'kVA';
dspl.Curve_4.Legend = [{'Q - L1'},{'Q - L2'},{'Q - L3'}];
dspl.Curve_4.Y_Label = 'Wirkleistungsaufnahme [kVA]';

dspl.Curve_5.Title = 'Wirkleistungsaufnahme Einzel-Haushalte';
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
dspl.Curve_5.Data = data/1000;
dspl.Curve_5.Unit = 'kW';
dspl.Curve_5.Legend = legend;
dspl.Curve_5.Y_Label = 'Wirkleistungsaufnahme [kW]';

dspl.Curve_6.Title = 'Blindleistungsaufnahme Einzel-Haushalte';
for i = 1:num_hh
	data(:,i) = ...
		Result.Households.Data(:,(i-1)*6+2) + ...
		Result.Households.Data(:,(i-1)*6+4) + ...
		Result.Households.Data(:,(i-1)*6+6);
	legend{i} = ['Q - Haush. ',num2str(i)];
end
dspl.Curve_6.Data = data/1000;
dspl.Curve_6.Unit = 'kVA';
dspl.Curve_6.Legend = legend;
dspl.Curve_6.Y_Label = 'Blindleistungsaufnahme [kVA]';

% dspl.Curve_7.Title = 'Gesamteinspeisung PV-Anlagen';
% dspl.Curve_7.Data = Result.Solar.Acvtive_Power_Total/1000;
% dspl.Curve_7.Unit = 'kW';
% dspl.Curve_7.Legend = 'P - PV-Anlagen';
% dspl.Curve_7.Y_Label = 'Wirkleistungseinspeisung [kW]';
% 
% dspl.Curve_8.Title = 'Einspeisung PV-Anlagen pro Phase';
% dspl.Curve_8.Data = Result.Solar.Active_Power_Phase/1000;
% dspl.Curve_8.Unit = 'kW';
% dspl.Curve_8.Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
% dspl.Curve_8.Y_Label = 'Wirkleistungseinspeisung [kW]';
% 
% dspl.Curve_9.Title = 'Gesamteinspeisung Windkraft-Anlagen';
% dspl.Curve_9.Data = Result.Wind.Acvtive_Power_Total/1000;
% dspl.Curve_9.Unit = 'kW';
% dspl.Curve_9.Legend = 'P - Windkraft-Anlagen';
% dspl.Curve_9.Y_Label = 'Wirkleistungseinspeisung [kW]';
% 
% dspl.Curve_10.Title = 'Einspeisung Windkraft-Anlagen pro Phase';
% dspl.Curve_10.Data = Result.Wind.Active_Power_Phase/1000;
% dspl.Curve_10.Unit = 'kW';
% dspl.Curve_10.Legend = [{'P - L1'},{'P - L2'},{'P - L3'}];
% dspl.Curve_10.Y_Label = 'Wirkleistungseinspeisung [kW]';

Result.Displayable = dspl;
handles.Result = Result;
end

