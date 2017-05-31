function Devices = create_devices_for_loadprofiles(hObject, Model, Households)
%CREATE_DEVICES_FOR_LOADPROFILES   Kurzbeschreibung fehlt.
%    Ausführliche Beschreibung fehlt!

%    Franz Zeilinger - 14.09.2011

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

known_devices = Households.Known_Devices_Pool;
number_user = Households.Number_Per_Tot.(typ);

%Auflistung der verwendeten Geräte im Modell:
Devices.Elements_Varna = {};  % Variablennamen für automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollständige Namen der jeweiligen Geräte 
                              %     z.B. für Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Geräte
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?

% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		Devices.(name) = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{end+1} = name;
		Devices.Elements_Names{end+1} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{end+1} = Model.Devices_Pool{i,3};
	end
end

Varna_unkno = Devices.Elements_Varna;
Devices.Number_Dev = zeros(1,numel(Varna_unkno)); % Anzahl in den einzelnen Gerätegruppen
Varna_known = {};
number_devices = [];
number_devices_hh = [];
% Erzeugen der Geräteinstanzen. Zuerst die an Anzahl bekannten Geräte (welche über
% die Haushaltsausstattung definiert worden sind):
% Feststellen, welche bekannten Geräte simuliert werden:
for i=1:numel(Varna_unkno)
	% ist das aktuelle Gerät ein bekanntes Gerät?
	idx = find(strcmpi(known_devices(:,1),Varna_unkno(i)));
	if ~isempty(idx)
		% bekanntes Gerät gefunden, in Liste speichern:
		Varna_known(end+1) = known_devices(idx,1); %#ok<AGROW>
		% die zugehörige Anzahl an Geräten ebenfalls speichern:
		number_devices(end+1) = Households.Number_Dev_Tot.(typ)(idx); %#ok<AGROW>
		number_devices_hh(end+1,:) = Households.Number_Devices.(typ)(idx,:); %#ok<AGROW>
	end
end
% Die bekannten Geräte aus der Liste der unbekannten Geräte streichen:
for i=1:numel(Varna_known)
	Varna_unkno(strcmpi(Varna_unkno,Varna_known(i)))=[];
end
% diese Listen in der DEVICES-Struktur speichern, für spätere Berechungen:
Devices.Elements_Varna_Known = Varna_known;
Devices.Number_created_Known = number_devices_hh;
Devices.Elements_Varna_Unknown = Varna_unkno;
num_known = sum(number_devices);
num_total = num_known + numel(Varna_unkno)*number_user;

% Array mit den Indizes der bekannten aktiven Geräte erstellen:
dev_idx = zeros(numel(Varna_known), max(number_devices));

waitbar_start; % Messen der Zeit, die benötigt wird - Start
% Die bekannten Geräte erzeugen:
for i=1:numel(Varna_known)
	% aktuellen Index in der Devices-Struktur ermitteln:
	idx = strcmpi(Devices.Elements_Varna, Varna_known(i));
	% wieviele Geräte müssen in dieser Geräteklasse erzeugt werden?
	num_dev = number_devices(i);
	% laufenden Index für diese Gerätegruppe:
	run_idx = 1;
	% Variablenname der aktuellen Geräteklasse:
	name = Devices.Elements_Varna{idx};
	% Funktionen-Handle auf zuständige Klasse auslesen
	dev_handle = Devices.Elements_Funha{idx};
	for j = 1:num_dev
		% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, Devices.Total_Number_Dev, num_total)
			% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
			% aufgetretenen Fehler erkennen können:
			Devices = [];
			% Geräteerzeugung abbrechen:
			return;
		end
		% Geräteinstanz erzeugen:
		dev = dev_handle(Model.Args.(name){:});
		% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen:
		if dev.Activity
			% aktuellen Geräteindex in Geräteinstanz und Geräteindexarray speichern 
			% und Zähler erhöhen:
			dev.ID_Index = run_idx;
			dev_idx(i,j)= run_idx;
			run_idx = run_idx + 1;
			% Geräteinstanz in jeweiligen Array speichern:
			Devices.(name)(end+1) = dev;
			% Anzahl der erzeugten Geräte aktualisieren:
			Devices.Number_Dev(idx) = Devices.Number_Dev(idx) + 1;
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	end
end

% Das Platzierungsarray der bekannten Geräte Speichern:
Devices.Index_created_Known = dev_idx;

% die unbekannten Geräte erzeugen (mit der Anzahl der Personen in den Haushalten):
for i=1:numel(Varna_unkno)
	% aktuellen Index in der Devices-Struktur ermitteln:
	idx = strcmpi(Devices.Elements_Varna, Varna_unkno(i));
	% laufenden Index für diese Gerätegruppe:
	run_idx = 1;
	% Variablenname der aktuellen Geräteklasse:
	name = Devices.Elements_Varna{idx};
	% Funktionen-Handle auf zuständige Klasse auslesen
	dev_handle = Devices.Elements_Funha{idx};
	for j = 1:number_user
		% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, num_known+(i-1)*number_user+j, num_total)
			% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
			% aufgetretenen Fehler erkennen können:
			Devices = [];
			% Geräteerzeugung abbrechen:
			return;
		end
		% Geräteinstanz erzeugen:
		dev = dev_handle(Model.Args.(name){:});
		% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen:
		if dev.Activity
			% aktuellen Geräteindex in Geräteinstanz speichern und Zähler erhöhen:
			dev.ID_Index = run_idx;
			run_idx = run_idx + 1;
			% Geräteinstanz in jeweiligen Array speichern:
			Devices.(name)(end+1) = dev;
			% Anzahl der erzeugten Geräte aktualisieren:
			Devices.Number_Dev(idx) = Devices.Number_Dev(idx) + 1;
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	end
end
end
