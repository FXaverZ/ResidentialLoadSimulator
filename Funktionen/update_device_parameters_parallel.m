function Devices = update_device_parameters_parallel (hObject, Devices, Model, Households)
%UPDATE_DEVICE_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

% Erstellt von:            Franz Zeilinger - 29.11.2012
% Letzte Änderung durch:   

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
% devices_hh = Households.Devices.(typ).Allocation;
number_pers = Households.Statistics.(typ).Number_Persons;
number_hh = Households.Statistics.(typ).Number;

device = cell(numel(Devices.Elements_Varna),1);
args = device;
switch_var = zeros(numel(Devices.Elements_Varna),1);
devices_number = zeros(numel(Devices.Elements_Varna),size(...
	Households.Devices.(typ).Devices.Number_created_Known,2));
% vorbereiten der Arrays für paralleles abarbeiten:
for i=1:numel(Devices.Elements_Varna)
	name = Devices.Elements_Varna{i};
	args{i} = Model.Args.(name);
	device{i} = Devices.(name);
	% ist es ein bekanntes Gerät?
	idx = find(strcmpi(Households.Devices.(typ).Devices.Elements_Varna_Known, ...
		name),1);
	if ~isempty(idx)
		switch_var(i) = 1;
		devices_number(strcmpi(Devices.Elements_Varna, name),:) = ...
			Households.Devices.(typ).Devices.Number_created_Known(idx,:);
	end
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start
% alle Geräte mit neuen Einsatzzeiten ausstatten:
parfor i=1:numel(Devices.Elements_Varna)
	% vom aktuellen Gerätetyp Geräte-Instanzen und Argumentenliste auslesen:
	devs = device{i};
	arg = args{i};
	% Anpassen der Startwahrscheinlichkeit, falls es sich um ein Gerät handelt,
	% von dem ein Ausstattungsgrad vorhanden war:
	if switch_var(i)
		% Laufindex zurücksetzen:
		run_idx = 1;
		% Wo befinden sich die Startwahrscheinlichkeiten in der Argumentenliste?
% 		idx = find(strcmp('Start_Probability',arg));
% 		% dies Auslesen:
% 		proba = arg{idx+1};
% 		% über alle Haushalte:
		for j=1:number_hh
% 			% Wieviele Personen leben in diesem Haushalt:
% 			persons = number_pers(j); %#ok<PFBNS>
% 			% Wieviele Geräte hat der Haushalt?
			num_dev = devices_number(i,j);
% 			% neue Einsatzwahrscheinlichkeit für Geräte in diesem Haushalt:
% 			proba_new = proba * persons;
% 			% Auf 100% setzen, falls überschritten:
% 			proba_new(proba_new > 100) = 100;
% 			% wieder in Argumentenliste eintragen:
% 			arg{idx+1} = proba_new;
% 			% nun die entsprechenden Geräte anpassen:
			for k=1:num_dev
				devs(run_idx) = devs(run_idx).update_device_activity(arg{:});
				run_idx = run_idx + 1;
			end
		end
	else
		% bei Geräten ohne bekannten Ausstattungsrad erfolgt Ermittlung über die
		% Anzahl an verfügbaren Instanzen, die erzeugt wurden (Geräteeinsatz pro
		% Person * Anzahl Personen im Haushalt... ). Also nur mehr für alle
		% verfügbaren Geräte neue Einsatzzeiten ermitteln lassen:
		for j=1:numel(devs)
			devs(j) = devs(j).update_device_activity(arg{:});
		end
	end
	device{i} = devs;
end

% Die erzeugten Geräteinstanzen im ursprünglichen Format in die Devices-Strukutr
% übernehmen:
for i = 1:size(Devices.Elements_Varna,2)
	Devices.(Devices.Elements_Varna{i}) = device{i};
end
end
