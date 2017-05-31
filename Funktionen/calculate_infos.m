function Result = calculate_infos (Model, Time, Devices, Result)
%CALCULATE_INFOS    ermitteln interessanter Werte aus Simulationsergnis
%    RESULT = CALCULATE_INFOS(MODEL, TIME, DEVICES, RESULT) berechnet nach der
%    Simulation interessante Daten, die für eine weiterführende Auswertung
%    notwendig sind. Dazu wird auf alle relevanten Strukturen zurückgegriffen
%    (MODEL, TIME, DEVICES uns RESULT), das Ergebnis der RESULT-Struktur
%    hinzugefügt.

%    Franz Zeilinger - 06.09.2010

for i = 1:size(Devices.Elements_Varna,2)
	% Ermittlen, wie viele Geräte eigentlich eingeschaltet waren:
	Result.Running_dev(i) = ...
		numel(Devices.(Devices.Elements_Varna{i}));
	% Durchschnittliche Leistung pro Person im betrachtetetn Zeitraum je
	% Geräteklasse:
	Result.Mean_Power_pP(i) = ...
		mean(Result.Power(i,:))/Model.Number_User;
end

% Simulationszeitpunkte mitspeichern:
Result.Time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
Result.Time_Base = Time.Base;

% Gesamtleistung aus Einzelleistungen errechnen:
Result.Aggr_Power = sum(Result.Power,1);
Result.Aggr_Power = [Result.Aggr_Power; Result.Power];
if Model.Use_DSM
	Result.Aggr_Power_DSM = sum(Result.Power_DSM,1);
	Result.Aggr_Power_DSM = [Result.Aggr_Power_DSM; Result.Power_DSM];
	% Umrechnung in kW
	Result.Aggr_Power_DSM_kW = Result.Aggr_Power_DSM/1000;
end

% Umrechnung in kW
Result.Aggr_Power_kW = Result.Aggr_Power/1000;
end