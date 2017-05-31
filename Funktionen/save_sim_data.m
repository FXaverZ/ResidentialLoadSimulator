function Configuration = save_sim_data (Configuration, Model, Devices, Frequency, Result)
%SAV_SIM_DATA    speichert aller relevanten Simulationsdaten 
%    CONFIGURATION = SAV_SIM_DATA (CONFIGURATION, MODEL, DEVICES, RESULT)
%    speichert die Simulationsdaten. Der Dateiname der Dateien, die von dieser
%    Funktion erzeugt werden ist von der Form: 
%        Simulationszeit - Dateiinhalt - zeitliche Auflösung - Anzahl Personen

%    Franz Zeilinger - 27.06.2011

file = Configuration.Save.Data;
% Speichern der wichtigen Workspacevariablen:
file.Data_Name = [datestr(Result.Sim_date,'HHhMM.SS'),...
	' - Rohdaten - ',Model.Sim_Resolution,' - ',num2str(Model.Number_User)];
try
	save([file.Path,file.Data_Name,'.mat'],'Model','Result','Devices','Frequency');
catch ME
	% Falls Fehler aufgetreten ist, Meldung in Konsole:
	errorstr = strrep(ME.message,'\','\\');
	str = ['--> Ein Fehler ist aufgetreten: ',errorstr];
	fprintf(['\n\t\t\t',str,'\n']);
	% Versuch eine häufigen Fehler auszuschließen:
	str = 'Speichern der Daten ohne DEVICES-Struktur: ';
	fprintf(['\n\t\t',str]);
	save([file.Path,file.Data_Name,' (ohne DEVICES).mat'],'Model','Result','Frequency');
end

% Festlegen des Pfades für die Parameterdateien:
file.Parameter_Name = [ datestr(Result.Sim_date,'HHhMM.SS'),...
	' - Parameterwerte - ',Model.Sim_Resolution,' - ',num2str(Model.Number_User)];

Configuration.Save.Data = file;

% Speichern der Modelparameter:
save_model_parameters(Configuration, Model);

% Erzeugen einer .xls-Datei mit den Simulatinsdaten inkl. Zeitstempel:
time = Result.Time;
resu = Result.Displayable.Power_Class_and_Total_kW;
time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
data = [time', resu'];
titl = [{'Zeit'},{'Gesamtleistung'},Devices.Elements_Names];
% .xls-File schreiben:
if (size(data,1) >= 1048665) || ~Configuration.Options.savas_xls
	fprintf('(ohne .xls-Daten) ');
else
	xls = XLS_Writer();
	xls.write_lines({'Simulationsdaten vom Durchlauf am','','',...
		datestr(Result.Sim_date)});
	xls.write_lines(titl); % Spaltenüberschriften
	xls.write_values('aktive Geräte:');
	xls.next_col;
	xls.write_lines(Result.Running_Devices); %wie viele Geräte aktiv?
	xls.write_values('Durchschn. je Klasse:');
	xls.next_col;
	xls.write_lines(Result.Mean_Power_pP); %durchschn. Leistung je Klasse
	xls.write_lines(data); % Daten
	wshn = datestr(Result.Sim_date,'HHhMM.SS'); % Tabellenblattname
	xls.set_worksheet(wshn);
	if Model.Use_DSM
		wshn = [datestr(Result.Sim_date,'HHhMM.SS'),'+DSM']; % Tabellenblattname
		xls.set_worksheet(wshn);
		titl = [{'Zeit'},{'Netzfrequenz'},{'Gesamtleistung'},Devices.Elements_Names];
		resu = Result.Displayable.DSM_Power_Class_and_Total_kW;
		% Ermitteln der Frequenzdaten, siehe Funktion CREATE_FREQUENCY_DATA!
		if Result.Time_Base < 60
			stepsize = 1;
		else
			stepsize = Result.Time_Base/30;
		end
		% Zeitdaten und Frequenzdaten auslesen
		t_points = Result.Time;
		Freq = Frequency(:,1:stepsize:end);
		% ermitteln der benötigten Frequenzdaten:
		idx = Freq(1,:)>= t_points(1) & Freq(1,:) <= t_points(end);
		Freq = Freq(2,idx);
		% Daten übernehmen:
		data = [time', Freq', resu'];
		xls.next_row;
		xls.write_lines(titl); % Spaltenüberschriften
		xls.write_values('aktive Geräte:');
		xls.next_col(2);
		xls.write_lines(Result.Running_Devices); %wie viele Geräte aktiv?
		xls.write_values('Durchschn. je Klasse:');
		xls.next_col(2);
		xls.write_lines(Result.Mean_Power_pP); %durchschn. Leistung je Klasse
		xls.write_lines(data); % Daten
	end
	xlsn = [file.Path,file.Data_Name,'.xlsx']; % Dateiname .xls-File
	xls.write_output(xlsn);
end
end