function Result = postprocess_results (Model, Time, Devices, Result)
%POSTPROCESS_RESULTS    ermitteln interessanter Werte aus Simulationsergnis
%    RESULT = POSTPROCESS_RESULTS(MODEL, TIME, DEVICES, RESULT) berechnet nach der
%    Simulation interessante Daten, die f�r eine weiterf�hrende Auswertung
%    notwendig sind. Dazu wird auf alle relevanten Strukturen zur�ckgegriffen
%    (MODEL, TIME, DEVICES und RESULT) und das Ergebnis der RESULT-Struktur
%    hinzugef�gt.

%    Franz Zeilinger - 23.08.2011

% aus den einzelnen Phasenleistungen die Gesamtleistung f�r jede Ger�tekategorie
% ermitteln sowie die Gesamtleistung ermitteln:
pwr_dev = reshape(squeeze(sum(Result.Raw_Data.Power,1)),...
	numel(Devices.Elements_Varna),[]); % reshape notwendig, falls nur ein Ger�t 
                                       % simuliert wurde!
Result.Raw_Data.Power_Devices = pwr_dev;
Result.Raw_Data.Power_Phase = squeeze(sum(Result.Raw_Data.Power,2));
Result.Raw_Data.Power_Total = sum(Result.Raw_Data.Power_Phase,1);
% Bei Simulation von DSM, auch diese Daten verarbeiten:
if Model.Use_DSM
	Result.Raw_Data.DSM_Power_Devices = squeeze(sum(Result.Raw_Data.DSM_Power,1));
	Result.Raw_Data.DSM_Power_Phase = squeeze(sum(Result.Raw_Data.DSM_Power,2));
	Result.Raw_Data.DSM_Power_Total = sum(Result.Raw_Data.DSM_Power_Devices,1);
end

% Verschiedene weitere Informationen ermitteln:
devices = Devices.Elements_Varna; % Variablennamen der simulierten Ger�te
Result.Content.Devices = [devices', Devices.Elements_Names'];
Result.Phase_Allocation = zeros(3,1);
for i = 1:size(Result.Content.Devices,1)
	% Ermittlen, wie viele Ger�te eigentlich eingeschaltet waren:
	Result.Running_Devices(i) = ...
		numel(Devices.(Result.Content.Devices{i,1}));
	% Phasenaufteilung ermitteln
	for j = 1:numel(Devices.(Result.Content.Devices{i,1}))
		phase_idx = Devices.(Result.Content.Devices{i,1})(j).Phase_Index;
		Result.Phase_Allocation(phase_idx) = Result.Phase_Allocation(phase_idx) + 1;
	end
	% Durchschnittliche Leistung pro Person im betrachtetetn Zeitraum je Ger�teart:
	Result.Mean_Power_pP_Devices(i) = ...
		mean(Result.Raw_Data.Power_Devices(i,:))/Model.Number_User;
end
% Phasenzuordnung normieren:
Result.Phase_Allocation = Result.Phase_Allocation ./ sum(Result.Running_Devices);

% aus dem Zwischenergebnis die Leistungen der Ger�te und Ger�tegruppen, welche durch
% das GUI vorgegeben sind (n�mlich in Model.Device_Assembly_Pool) ermitteln:
% aktuelle Ger�te(gruppen)zusammenstellung:
assembly = ...
	Model.Device_Assembly_Pool(logical(struct2array(Model.Device_Assembly)),:);
% das Ergebnisarray: Zeilenanzahl = Anzahl der ausgew�hlten Ger�te(gruppen) im GUI,
% Spaltenanzahl = Anzahl der Zeitschritte der Simulation:;
result = zeros([size(assembly,1), Time.Number_Steps]);
if Model.Use_DSM
	dsm_result = zeros([size(assembly,1), Time.Number_Steps]);
end
Result.Running_Devices_in_Class = zeros(1,size(assembly,1));
for i = 1:size(assembly,1)
	% �berpr�fen, ob der aktuelle Eintrag eine Ger�tegruppe ist:
	if isempty(find(strcmp(assembly(i,1), Model.Device_Groups_Pool(:,1)), 1))
		% es liegt keine Ger�tegruppe vor, die Daten f�r das aktuelle Ger�t kopieren:
		result(i,:) = Result.Raw_Data.Power_Devices(strcmp(assembly{i,1}, devices),:);
		Result.Running_Devices_in_Class(i) = ...
			Result.Running_Devices(strcmp(assembly{i,1}, devices));
		if Model.Use_DSM
			dsm_result(i,:) = ...
				Result.Raw_Data.DSM_Power_Devices(strcmp(assembly{i,1}, devices),:);
		end
	else
		% wenn Ger�tegruppe gefunden, alle entsprechenden Daten zusammenf�hren:
		members = Model.Device_Groups.(assembly{i,1}).Members(:,1);
		for j = 1:numel(members)
			idx = strcmp(members(j),devices);
			result(i,:) = result(i,:) + Result.Raw_Data.Power_Devices(idx,:);
			Result.Running_Devices_in_Class(i) = ...
				Result.Running_Devices_in_Class(i) + Result.Running_Devices(idx);
			if Model.Use_DSM
				dsm_result(i,:) = dsm_result(i,:) + ...
					Result.Raw_Data.DSM_Power_Devices(idx,:);
			end
		end
	end
end
Result.Raw_Data.Power_Class = result;
if Model.Use_DSM
	Result.Raw_Data.DSM_Power_Class = dsm_result;
end
Result.Content.Classes = assembly;


% Durchschnittliche Leistung pro Person im betrachtetetn Zeitraum je Ger�teklasse:
for i = 1:size(Result.Content.Classes,1)
	Result.Mean_Power_pP_Class(i) = ...
		mean(Result.Raw_Data.Power_Class(i,:))/Model.Number_User;
end

% Simulationszeitpunkte mitspeichern:
Result.Time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
Result.Time_Base = Time.Base;

% Umrechnung in kW, Legendeneintr�ge und Titel erstellen:
% --- Gesamtleistungsaufnahme:
dspl.Power_Total_kW.Title = 'Gesamtleistungsaufnahme';
dspl.Power_Total_kW.Data = Result.Raw_Data.Power_Total/1000;
dspl.Power_Total_kW.Unit = 'kW';
dspl.Power_Total_kW.Legend = 'Gesamtleistung';
% --- Leistungsaufnahme der einzelnen Ger�tearten:
dspl.Power_Devices_kW.Title = ['Leistungsaufnahme der einzelnen',...
	' Ger�tearten'];
dspl.Power_Devices_kW.Data = Result.Raw_Data.Power_Devices/1000;
dspl.Power_Devices_kW.Unit = 'kW';
dspl.Power_Devices_kW.Legend = Devices.Elements_Names;
% --- Leistungsaufnahme der einzelnen Phasen:
dspl.Power_Phase_kW.Title = 'Leistungsaufnahme der einzelnen Phasen';
dspl.Power_Phase_kW.Data = Result.Raw_Data.Power_Phase/1000;
dspl.Power_Phase_kW.Unit = 'kW';
dspl.Power_Phase_kW.Legend = [{'L1'},{'L2'},{'L3'}];
% --- Leistungsaufnahme der einzelnen Ger�teklassen:
dspl.Power_Class_kW.Title = 'Leistungsaufnahme der einzelnen Ger�teklassen';
dspl.Power_Class_kW.Data = Result.Raw_Data.Power_Class/1000;
dspl.Power_Class_kW.Unit = 'kW';
dspl.Power_Class_kW.Legend = assembly(:,2)';
% --- Gesamtleistung und Leistungsaufnahme der einzelnen Ger�tearten:
dspl.Power_Devices_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und aufgeteilt',...
	' auf die Ger�tearten'];
dspl.Power_Devices_and_Total_kW.Data = [dspl.Power_Total_kW.Data; ...
	dspl.Power_Devices_kW.Data];
dspl.Power_Devices_and_Total_kW.Unit = 'kW';
dspl.Power_Devices_and_Total_kW.Legend = [{'Gesamtleistung'}, Devices.Elements_Names];
% --- Gesamtleistung und Leistungsaufnahme der einzelnen Phasen:
dspl.Power_Phase_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und aufgeteilt ',...
	'auf die Phasen'];
dspl.Power_Phase_and_Total_kW.Data = [dspl.Power_Total_kW.Data;...
	dspl.Power_Phase_kW.Data];
dspl.Power_Phase_and_Total_kW.Unit = 'kW';
dspl.Power_Phase_and_Total_kW.Legend = [{'Gesamtleistung'},{'L1'},{'L2'},{'L3'}];
% --- Gesamtleistung und Leistungsaufnahme der Ger�teklassen:
dspl.Power_Class_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und aufgeteilt ',...
	'auf die Ger�teklassen'];
dspl.Power_Class_and_Total_kW.Data = [dspl.Power_Total_kW.Data;...
	dspl.Power_Class_kW.Data];
dspl.Power_Class_and_Total_kW.Unit = 'kW';
dspl.Power_Class_and_Total_kW.Legend = [{'Gesamtleistung'}, assembly(:,2)'];

if Model.Use_DSM
	% --- Gesamtleistungsaufnahme mit Einsatz von DSM:
	dspl.DSM_Power_Total_kW.Title = 'Gesamtleistungsaufnahme mit Einsatz von DSM';
	dspl.DSM_Power_Total_kW.Data = Result.Raw_Data.DSM_Power_Total/1000;
	dspl.DSM_Power_Total_kW.Unit = 'kW';
	dspl.DSM_Power_Total_kW.Legend = 'Gesamtleistung (mit DSM)'; 
	% --- Leistungsaufnahme der einzelnen Ger�tearten mit Einsatz von DSM:
	dspl.DSM_Power_Devices_kW.Title = ['Leistungsaufnahme der einzelnen ',...
		'Ger�tearten mit Einsatz von DSM'];
	dspl.DSM_Power_Devices_kW.Data = Result.Raw_Data.DSM_Power_Devices/1000;
	dspl.DSM_Power_Devices_kW.Unit = 'kW';
	dspl.DSM_Power_Devices_kW.Legend = dspl.Power_Devices_kW.Legend;
	% --- Leistungsaufnahme der einzelnen Phasen mit Einsatz von DSM:
	dspl.DSM_Power_Phase_kW.Title = ['Leistungsaufnahme der einzelnen ',...
		'Phasen mit Einsatz von DSM'];
	dspl.DSM_Power_Phase_kW.Data = Result.Raw_Data.DSM_Power_Phase/1000;
	dspl.DSM_Power_Phase_kW.Unit = 'kW';
	dspl.DSM_Power_Phase_kW.Legend = dspl.Power_Phase_kW.Legend;
	% --- Leistungsaufnahme der einzelnen Ger�teklassen mit Einsatz von DSM:
	dspl.DSM_Power_Class_kW.Title = ['Leistungsaufnahme der einzelnen ',...
		'Ger�teklassen mit Einsatz von DSM'];
	dspl.DSM_Power_Class_kW.Data = Result.Raw_Data.DSM_Power_Class/1000;
	dspl.DSM_Power_Class_kW.Unit = 'kW';
	dspl.DSM_Power_Class_kW.Legend = dspl.Power_Class_kW.Legend;
	% --- Gesamtleistung und Leistungsaufnahme d. einz. Ger�tear. mit Eins. von DSM:
	dspl.DSM_Power_Devices_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und ',...
		'aufgeteilt auf die Ger�tearten mit Einsatz von DSM'];
	dspl.DSM_Power_Devices_and_Total_kW.Data = [dspl.DSM_Power_Total_kW.Data; ...
		dspl.DSM_Power_Devices_kW.Data];
	dspl.DSM_Power_Devices_and_Total_kW.Unit = 'kW';
	dspl.DSM_Power_Devices_and_Total_kW.Legend = dspl.Power_Devices_and_Total_kW.Legend;
	% --- Gesamtleistung und Leistungsaufnahme der einz. Phasen mit Einsatz von DSM:
	dspl.DSM_Power_Phase_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und ',...
		'aufgeteilt auf die Phasen mit Einsatz von DSM'];
	dspl.DSM_Power_Phase_and_Total_kW.Data = [dspl.DSM_Power_Total_kW.Data; ...
		dspl.DSM_Power_Phase_kW.Data];
	dspl.DSM_Power_Phase_and_Total_kW.Unit = 'kW';
	dspl.DSM_Power_Phase_and_Total_kW.Legend = dspl.Power_Devices_and_Total_kW.Legend;
	% --- Gesamtleistung und Leistungsaufnahme der Ger�teklassen mit Einsatz von DSM:
	dspl.DSM_Power_Class_and_Total_kW.Title = ['Leistungsaufnahme Gesamt und ',...
		'aufgeteilt auf die Ger�teklassen mit Einsatz von DSM'];
	dspl.DSM_Power_Class_and_Total_kW.Data = [dspl.DSM_Power_Total_kW.Data; ...
		dspl.DSM_Power_Class_kW.Data];
	dspl.DSM_Power_Class_and_Total_kW.Unit = 'kW';
	dspl.DSM_Power_Class_and_Total_kW.Legend = dspl.Power_Class_and_Total_kW.Legend;
end
Result.Displayable = dspl;
end