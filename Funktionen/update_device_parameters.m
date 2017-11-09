function Devices = update_device_parameters (hObject, Devices, Model, Households)
%UPDATE_DEVICE_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

% Erstellt von:            Franz Zeilinger - 29.11.2012
% Letzte �nderung durch:   Franz Zeilinger - 10.12.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
% typ = Households.Act_Type;
% known_devices_varname = Households.Devices.(typ).Devices.Elements_Varna_Known;
% known_devices_number  = Households.Devices.(typ).Devices.Number_created_Known;
% devices_hh = Households.Devices.(typ).Allocation;
% number_pers = Households.Statistics.(typ).Number_Persons;

varnames = Devices.Elements_Varna;

waitbar_start; % Messen der Zeit, die ben�tigt wird - Start
% alle Ger�te mit neuen Einsatzzeiten ausstatten:
for i=1:numel(varnames)
	% vom aktuellen Ger�tetyp Ger�te-Instanzen und Argumentenliste auslesen:
	devs = Devices.(varnames{i});
	args = Model.Args.(varnames{i});
	% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
	% erfolgt ist:
	if waitbar_update (hObject, 5, i, numel(varnames))
		% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
		% aufgetretenen Fehler erkennen k�nnen:
		Devices = [];
		% Ger�teerzeugung abbrechen:
		return;
	end
	for j=1:numel(devs)
		devs(j) = devs(j).update_device_activity(args{:});
	end
	Devices.(varnames{i}) = devs;
end
end
