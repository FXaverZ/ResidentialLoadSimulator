function handles = adobt_data_for_display(handles)
%ADOBT_DATA_FOR_DISPLAY    aufbereiten der Daten für GUI 'Data_Explorer'
%    HANDLES = ADOBT_DATA_FOR_DISPLAY(HANDLES) fügt der Struktur RESULTS innerhalb
%    der HANDLES Datenstruktur die Struktur DISPLAYABLE hinzu, welche die
%    aufbereiteten Daten für die Darstellung im Daten Explorer enthält. So sind
%    innerhalb dieser Struktur neben den eigentlichen Daten auch die Beschreibung,
%    Einheit, Legendeneinträge und Achsenbeschriftungen vorhanden, auf die der
%    'Data_Explorer' zurückgreift.

% Erstellt von:            Franz Zeilinger - 03.07.2012
% Letzte Änderung durch:   Franz Zeilinger - 16.08.2012

Result = handles.Result;

data_typs = {...
	'Sample', 'Sample-Werte';...
	'Mean',   'Mittelwerte';...
	};
% Zeitskalen erstellen:
time_res = handles.System.time_resolutions{...
	handles.Current_Settings.Data_Extract.Time_Resolution,2};
time_ser_dur = handles.Current_Settings.Data_Extract.Time_Series.Duration;
date_start = handles.Current_Settings.Data_Extract.Time_Series.Date_Start;

if handles.Current_Settings.Data_Extract.get_Time_Series
	Result.Time_Sample = 0:time_res/86400:time_ser_dur;
	Result.Time_Sample = Result.Time_Sample + datenum(date_start,'dd.mm.yyyy');
else
	Result.Time_Sample = 0:time_res/86400:1;
	Result.Time_Sample = Result.Time_Sample' + datenum('00:00:00');
end

Result.Time_Mean = Result.Time_Sample(2:end);
Result.Time_Min = Result.Time_Mean;

crv_cnt = 0;
dspl = [];
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                                 H A U S H A L T E
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
for i=1:size(data_typs,1)
	if ~isempty(Result.Households.(['Data_',data_typs{i,1}]))
		% Anzeigbare Kurven definieren:
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme Haushalte (',...
			data_typs{i,2},')'];
% 		dspl.(crv_nam).Pop_up_Title = ['P Ges. Haushalte (',...
% 			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = 'P_{HH Ges.}';
		dspl.(crv_nam).Y_Label = 'P_{Ges} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme Haushalte (',...
			data_typs{i,2},')'];
% 		dspl.(crv_nam).Pop_up_Title = ['Q Ges. Haushalte (',...
% 			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','Q',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kVA';
		dspl.(crv_nam).Legend = 'Q_{Ges}';
		dspl.(crv_nam).Y_Label = 'Q_{HH Ges} [kVA]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme pro Phase Haushalte (',...
			data_typs{i,2},')'];
% 		dspl.(crv_nam).Pop_up_Title = ['P Ges. pro Phase Haushalte (',...
% 			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','P_Phase',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = [{'P_{L1}'},{'P_{L2}'},{'P_{L3}'}];
		dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme pro Phase Haushalte (',...
			data_typs{i,2},')'];
% 		dspl.(crv_nam).Pop_up_Title = ['Q Ges. pro Phase Haushalte (',...
% 			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','Q_Phase',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kVA';
		dspl.(crv_nam).Legend = [{'Q_{L1}'},{'Q_{L2}'},{'Q_{L3}'}];
		dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kVA]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme, Einzelhaushalte (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		num_hh = size(Result.Households.(['Data_',data_typs{i,1}]),2)/6;
		legend = cell(1,num_hh);
		for j=1:num_hh
			legend{j} = ['P - Haushalt ',num2str(j)];
		end
		dspl.(crv_nam).Legend = legend;
		dspl.(crv_nam).Y_Label = 'P_{Aufnahme} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme, Einzelhaushalte (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
		dspl.(crv_nam).Data_fun_args = {'Households','Q',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kVA';
		num_hh = size(Result.Households.(['Data_',data_typs{i,1}]),2)/6;
		legend = cell(1,num_hh);
		for j=1:num_hh
			legend{j} = ['Q - Haushalt ',num2str(j)];
		end
		dspl.(crv_nam).Legend = legend;
		dspl.(crv_nam).Y_Label = 'Q_{Aufnahme} [kVA]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
	end
end

if ~isempty(Result.Households.Data_Min)
	% Anzeigbare Kurven definieren:
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme Haushalte (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{Ges} HH Min'},{'P_{Ges} HH Max'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme Haushalte (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','Min_Max'};
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = [{'Q_{Ges} HH Min'},{'Q_{Ges} HH Max'}];
	dspl.(crv_nam).Y_Label = 'Blindleistungsaufnahme [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme pro Phase Haushalte (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P_Phase','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{min} - L1'},{'P_{max} - L1'},{'P_{min} - L2'},...
		{'P_{max} - L2'},{'P_{min} - L3'},{'P_{max} - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme pro Phase Haushalte (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q_Phase','Min_Max'};
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = [{'Q_{min} - L1'},{'Q_{max} - L1'},{'Q_{min} - L2'},...
		{'Q_{max} - L2'},{'Q_{min} - L3'},{'Q_{max} - L3'}];
	dspl.(crv_nam).Y_Label = 'Blindleistungsaufnahme [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme, Einzelhaushalte (',...
		'Minimalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','Min'};
	dspl.(crv_nam).Unit = 'kW';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['P_{Min} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Aufnahme} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme, Einzelhaushalte (',...
		'Minimalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','Min'};
	dspl.(crv_nam).Unit = 'kVA';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['Q_{Min} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Q_{Aufnahme} [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme, Einzelhaushalte (',...
		'Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','Max'};
	dspl.(crv_nam).Unit = 'kW';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['P_{Max} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Aufnahme} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme, Einzelhaushalte (',...
		'Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','Max'};
	dspl.(crv_nam).Unit = 'kVA';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['Q_{Max} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Q_{Aufnahme} [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
end

if ~isempty(Result.Households.Data_05P_Quantil)
	% Anzeigbare Kurven definieren:
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme Haushalte (',...
		'5%- und 95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','05q_95q'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{Ges} HH 5% Quantil'},{'P_{Ges} HH 95% Quantil'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme Haushalte (',...
		'5%- und 95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','05q_95q'};
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = [{'Q_{Ges} HH 5% Quantil'},{'Q_{Ges} HH 95% Quantil'}];
	dspl.(crv_nam).Y_Label = 'Blindleistungsaufnahme [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme pro Phase Haushalte (',...
		'5%- und 95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P_Phase','05q_95q'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{5% Qu.} - L1'},{'P_{95% Qu.} - L1'},...
		{'P_{5% Qu.} - L2'},{'P_{95% Qu.} - L2'},{'P_{5% Qu.} - L3'},...
		{'P_{95% Qu.} - L3'}];
	dspl.(crv_nam).Y_Label = 'Wirkleistungsaufnahme [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme pro Phase Haushalte (',...
		'5%- und 95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q_Phase','05q_95q'};
	dspl.(crv_nam).Unit = 'kVA';
	dspl.(crv_nam).Legend = [{'Q_{5% Qu.} - L1'},{'Q_{95% Qu.} - L1'},{'Q_{5% Qu.} - L2'},...
		{'Q_{95% Qu.} - L2'},{'Q_{5% Qu.} - L3'},{'Q_{95% Qu.} - L3'}];
	dspl.(crv_nam).Y_Label = 'Blindleistungsaufnahme [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme, Einzelhaushalte (',...
		'5%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','05q'};
	dspl.(crv_nam).Unit = 'kW';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['P_{5% Qu.} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Aufnahme} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme, Einzelhaushalte (',...
		'5%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','05q'};
	dspl.(crv_nam).Unit = 'kVA';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['Q_{5% Qu.} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Q_{Aufnahme} [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtwirkleistungsaufnahme, Einzelhaushalte (',...
		'95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','P','95q'};
	dspl.(crv_nam).Unit = 'kW';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['P_{95% Qu.} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Aufnahme} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamtblindleistungsaufnahme, Einzelhaushalte (',...
		'95%-Quantil-Werte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Households','Q','95q'};
	dspl.(crv_nam).Unit = 'kVA';
	num_hh = size(Result.Households.Data_Min,2)/6;
	legend = cell(1,num_hh);
	for j=1:num_hh
		legend{j} = ['Q_{95% Qu.} - Haushalt ',num2str(j)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'Q_{Aufnahme} [kVA]';
	dspl.(crv_nam).Time = 'Time_Min';
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                              P V  -  A N L A G E N
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
for i=1:size(data_typs,1)
	if ~isempty(Result.Solar.(['Data_',data_typs{i,1}]))
		% Anzeigbare Kurven definieren:
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamteinspeisung PV-Anlagen (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Solar','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = 'P_{PV Ges.}';
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Einspeisung PV-Anlagen pro Phase (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Solar','P_Phase',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = [{'P_{L1}'},{'P_{L2}'},{'P_{L3}'}];
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Einspeisung PV-Anlagen, Einzelanlagen (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
		dspl.(crv_nam).Data_fun_args = {'Solar','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		num_plants = size(Result.Solar.(['Data_',data_typs{i,1}]),2)/6;
		legend = cell(1,num_plants);
		for j=1:num_plants
			legend{j} = ['P_{PV} - Anlage ',num2str(j)];
		end
		dspl.(crv_nam).Legend = legend;
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
	end
end
if ~isempty(Result.Solar.Data_Min)
	% Anzeigbare Kurven definieren:
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamteinspeisung PV-Anlagen (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Solar','P','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{Ges} PV Min'},{'P_{Ges} PV Max'}];
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung PV-Anlagen pro Phase (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Solar','P_Phase','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{min} - L1'},{'P_{max} - L1'},{'P_{min} - L2'},...
		{'P_{max} - L2'},{'P_{min} - L3'},{'P_{max} - L3'}];
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung PV-Anlagen, Einzelanlagen (',...
		'Minimalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'solar','P','Min'};
	dspl.(crv_nam).Unit = 'kW';
	num_plants = size(Result.Solar.Data_Min,2)/6;
	legend = cell(1,num_plants);
	for i=1:num_plants
		legend{i} = ['P_{PV} - Anlage ',num2str(i)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung PV-Anlagen, Einzelanlagen (',...
		'Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Solar','P','Max'};
	dspl.(crv_nam).Unit = 'kW';
	num_plants = size(Result.Solar.Data_Min,2)/6;
	legend = cell(1,num_plants);
	for i=1:num_plants
		legend{i} = ['P_{PV} - Anlage ',num2str(i)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                      K L E I N W I N D K R A F T A N L A G E N
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
for i=1:size(data_typs,1)
	if ~isempty(Result.Wind.(['Data_',data_typs{i,1}]))
		% Anzeigbare Kurven definieren:
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Gesamteinspeisung Windkraft-Anlagen (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Wind','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = 'P_{PV Ges.}';
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Einspeisung Windkraft-Anlagen pro Phase (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_total_kW;
		dspl.(crv_nam).Data_fun_args = {'Wind','P_Phase',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		dspl.(crv_nam).Legend = [{'P_{L1}'},{'P_{L2}'},{'P_{L3}'}];
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
		
		crv_cnt = crv_cnt + 1;
		crv_nam = ['Curve_',num2str(crv_cnt)];
		dspl.(crv_nam).Title = ['Einspeisung Windkraft-Anlagen, Einzelanlagen (',...
			data_typs{i,2},')'];
		dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
		dspl.(crv_nam).Data_fun_args = {'Wind','P',data_typs{i,1}};
		dspl.(crv_nam).Unit = 'kW';
		num_plants = size(Result.Wind.(['Data_',data_typs{i,1}]),2)/6;
		legend = cell(1,num_plants);
		for j=1:num_plants
			legend{j} = ['P_{Windkraft} - Anlage ',num2str(j)];
		end
		dspl.(crv_nam).Legend = legend;
		dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
		dspl.(crv_nam).Time = ['Time_',data_typs{i,1}];
	end
end

if ~isempty(Result.Wind.Data_Min)
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Gesamteinspeisung Windkraft-Anlagen (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Wind','P','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{Ges} PV Min'},{'P_{Ges} PV Max'}];
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	dspl.(crv_nam).Time_Resolution = handles.System.time_resolutions(...
			handles.Current_Settings.Data_Extract.Time_Resolution,:);
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung Windkraft-Anlagen pro Phase (',...
		'Minimal und Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_total_kW;
	dspl.(crv_nam).Data_fun_args = {'Wind','P_Phase','Min_Max'};
	dspl.(crv_nam).Unit = 'kW';
	dspl.(crv_nam).Legend = [{'P_{min} - L1'},{'P_{max} - L1'},{'P_{min} - L2'},...
		{'P_{max} - L2'},{'P_{min} - L3'},{'P_{max} - L3'}];
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	dspl.(crv_nam).Time_Resolution = handles.System.time_resolutions(...
			handles.Current_Settings.Data_Extract.Time_Resolution,:);
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung Windkraft-Anlagen, Einzelanlagen (',...
		'Minimalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Wind','P','Min'};
	dspl.(crv_nam).Unit = 'kW';
	num_plants = size(Result.Wind.Data_Min,2)/6;
	legend = cell(1,num_plants);
	for i=1:num_plants
		legend{i} = ['P_{Windkraft} - Anlage ',num2str(i)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	dspl.(crv_nam).Time_Resolution = handles.System.time_resolutions(...
			handles.Current_Settings.Data_Extract.Time_Resolution,:);
	
	crv_cnt = crv_cnt + 1;
	crv_nam = ['Curve_',num2str(crv_cnt)];
	dspl.(crv_nam).Title = ['Einspeisung Windkraft-Anlagen, Einzelanlagen (',...
		'Maximalwerte',')'];
	dspl.(crv_nam).Data_fun = @get_power_single_curves_kW;
	dspl.(crv_nam).Data_fun_args = {'Wind','P','Max'};
	dspl.(crv_nam).Unit = 'kW';
	num_plants = size(Result.Wind.Data_Min,2)/6;
	legend = cell(1,num_plants);
	for i=1:num_plants
		legend{i} = ['P_{Windkraft} - Anlage ',num2str(i)];
	end
	dspl.(crv_nam).Legend = legend;
	dspl.(crv_nam).Y_Label = 'P_{Einspeisung} [kW]';
	dspl.(crv_nam).Time = 'Time_Min';
	dspl.(crv_nam).Time_Resolution = handles.System.time_resolutions(...
			handles.Current_Settings.Data_Extract.Time_Resolution,:);
end

Result.Displayable = dspl;
handles.Result = Result;
end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = % 
%                       H I L F S F U N K T I O N E N                               %
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = % 
function output_data = get_power_total_kW(res_struct, power_type, data_typ)
data = [];

switch lower(data_typ)
	case 'sample'
		data = res_struct.Data_Sample/1000;
	case 'mean'
		data = res_struct.Data_Mean/1000;
	case 'min_max'
		data_min = res_struct.Data_Min/1000;
		data_max = res_struct.Data_Max/1000;
	case '05q_95q'
		data_min = res_struct.Data_05P_Quantil/1000;
		data_max = res_struct.Data_95P_Quantil/1000;
end

switch lower(power_type)
	case 'p'
		if ~isempty(data)
			output_data = sum(data(:,1:2:end),2);
		else
			output_data = [sum(data_min(:,1:2:end),2),sum(data_max(:,1:2:end),2)];
		end
	case 'q'
		if ~isempty(data)
			output_data = sum(data(:,2:2:end),2);
		else
			output_data = [sum(data_min(:,2:2:end),2),sum(data_max(:,2:2:end),2)];
		end
	case 'p_phase'
		if ~isempty(data)
			output_data = [...
				sum(data(:,1:6:end),2),...
				sum(data(:,3:6:end),2),...
				sum(data(:,5:6:end),2)];
		else
			output_data = [...
				sum(data_min(:,1:6:end),2),...
				sum(data_max(:,1:6:end),2),...
				sum(data_min(:,3:6:end),2),...
				sum(data_max(:,3:6:end),2),...
				sum(data_min(:,5:6:end),2),...
				sum(data_min(:,5:6:end),2)...
				];
		end
	case 'q_phase'
		if ~isempty(data)
			output_data = [...
				sum(data(:,2:6:end),2),...
				sum(data(:,4:6:end),2),...
				sum(data(:,6:6:end),2)];
		else
			output_data = [...
				sum(data_min(:,2:6:end),2),...
				sum(data_max(:,2:6:end),2),...
				sum(data_min(:,4:6:end),2),...
				sum(data_max(:,4:6:end),2),...
				sum(data_min(:,6:6:end),2),...
				sum(data_min(:,6:6:end),2)...
				];
		end
		
end
end

function output_data = get_power_single_curves_kW(res_struct, power_type, data_typ)

switch lower(data_typ)
	case 'sample'
		data = res_struct.Data_Sample/1000;
	case 'mean'
		data = res_struct.Data_Mean/1000;
	case 'min'
		data = res_struct.Data_Min/1000;
	case 'max'
		data = res_struct.Data_Max/1000;
	case '05q'
		data = res_struct.Data_05P_Quantil/1000;
	case '95q'
		data = res_struct.Data_95P_Quantil/1000;
end

num_elements = size(data,2)/6;
output_data = zeros(size(data,1),num_elements);

switch lower(power_type)
	case 'p'
		for i=1:num_elements
			output_data(:,i) = ...
				data(:,(i-1)*6+1) + ...
				data(:,(i-1)*6+3) + ...
				data(:,(i-1)*6+5,:);
		end
	case 'q'
		for i=1:num_elements
			output_data(:,i) = ...
				data(:,(i-1)*6+2) + ...
				data(:,(i-1)*6+4) + ...
				data(:,(i-1)*6+6,:);
		end
end
end
