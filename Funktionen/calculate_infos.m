function Result = calculate_infos (Model, Time, Devices, Result)
%CALCULATE_INFOS    ermitteln interessanter Werte aus Simulationsergnis
%    RESULT = CALCULATE_INFOS(MODEL, TIME, DEVICES, RESULT) berechnet nach der
%    Simulation interessante Daten, die für eine weiterführende Auswertung
%    notwendig sind. Dazu wird auf alle relevanten Strukturen zurückgegriffen
%    (MODEL, TIME, DEVICES uns RESULT) und das Ergebnis der RESULT-Struktur
%    hinzugefügt.

%    Franz Zeilinger - 27.06.2011

Result.Phase_Allocation = zeros(3,1);

% aus den einzelnen Phasenleistungen die Gesamtleistung für jede Gerätekategorie
% ermitteln sowie die Gesamtleistung ermitteln:
Result.Raw_Data.Power_Class = squeeze(sum(Result.Raw_Data.Power,1));
Result.Raw_Data.Power_Phase = squeeze(sum(Result.Raw_Data.Power,2));
Result.Raw_Data.Power_Total = sum(Result.Raw_Data.Power_Class,1);

for i = 1:size(Devices.Elements_Varna,2)
	% Ermittlen, wie viele Geräte eigentlich eingeschaltet waren:
	Result.Running_Devices(i) = ...
		numel(Devices.(Devices.Elements_Varna{i}));
	% Phasenaufteilung ermitteln
	for j = 1:numel(Devices.(Devices.Elements_Varna{i}))
		phase_idx = Devices.(Devices.Elements_Varna{i})(j).Phase_Index;
		Result.Phase_Allocation(phase_idx) = Result.Phase_Allocation(phase_idx) + 1;
	end
	% Durchschnittliche Leistung pro Person im betrachtetetn Zeitraum je
	% Geräteklasse:
	Result.Mean_Power_pP(i) = ...
		mean(Result.Raw_Data.Power_Class(i,:))/Model.Number_User;
end

% Phasenzuordnung normieren:
Result.Phase_Allocation = Result.Phase_Allocation ./ sum(Result.Running_Devices);

% Simulationszeitpunkte mitspeichern:
Result.Time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
Result.Time_Base = Time.Base;

% Bei Simulation von DSM, auch diese Daten verarbeiten:
if Model.Use_DSM
	Result.Raw_Data.DSM_Power_Class = squeeze(sum(Result.Raw_Data.DSM_Power,1));
	Result.Raw_Data.DSM_Power_Phase = squeeze(sum(Result.Raw_Data.DSM_Power,2));
	Result.Raw_Data.DSM_Power_Total = sum(Result.Raw_Data.DSM_Power_Class,1);
	% Umrechnung in kW
	Result.Displayable.DSM_Power_Total_kW = Result.Raw_Data.DSM_Power_Total/1000;
	Result.Displayable.DSM_Power_Class_kW = Result.Raw_Data.DSM_Power_Class/1000;
	Result.Displayable.DSM_Power_Phase_kW = Result.Raw_Data.DSM_Power_Phase/1000;
	Result.Displayable.DSM_Power_Class_and_Total_kW = [...
		Result.Displayable.DSM_Power_Total_kW; Result.Displayable.DSM_Power_Class_kW];
end

% Umrechnung in kW
Result.Displayable.Power_Total_kW = Result.Raw_Data.Power_Total/1000;
Result.Displayable.Power_Class_kW = Result.Raw_Data.Power_Class/1000;
Result.Displayable.Power_Phase_kW = Result.Raw_Data.Power_Phase/1000;
Result.Displayable.Power_Class_and_Total_kW = [Result.Displayable.Power_Total_kW; ...
	Result.Displayable.Power_Class_kW];
end