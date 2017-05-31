function Devices = create_devices_for_loadprofiles(hObject, Model, Households)
%CREATE_DEVICES_FOR_LOADPROFILES   Kurzbeschreibung fehlt.
%    Ausf�hrliche Beschreibung fehlt!

%    Franz Zeilinger - 14.09.2011

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

known_devices = Households.Known_Devices_Pool;
number_user = Households.Number_Per_Tot.(typ);

%Auflistung der verwendeten Ger�te im Modell:
Devices.Elements_Varna = {};  % Variablennamen f�r automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollst�ndige Namen der jeweiligen Ger�te 
                              %     z.B. f�r Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Ger�te
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?

% Vorbereiten der Arrays f�r die Ger�te-Instanzen der Ger�testruktur:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Ger�teklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Funktionen-Handle auf zust�ndige Klasse auslesen
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
Devices.Number_Dev = zeros(1,numel(Varna_unkno)); % Anzahl in den einzelnen Ger�tegruppen
Varna_known = {};
number_devices = [];
number_devices_hh = [];
% Erzeugen der Ger�teinstanzen. Zuerst die an Anzahl bekannten Ger�te (welche �ber
% die Haushaltsausstattung definiert worden sind):
% Feststellen, welche bekannten Ger�te simuliert werden:
for i=1:numel(Varna_unkno)
	% ist das aktuelle Ger�t ein bekanntes Ger�t?
	idx = find(strcmpi(known_devices(:,1),Varna_unkno(i)));
	if ~isempty(idx)
		% bekanntes Ger�t gefunden, in Liste speichern:
		Varna_known(end+1) = known_devices(idx,1); %#ok<AGROW>
		% die zugeh�rige Anzahl an Ger�ten ebenfalls speichern:
		number_devices(end+1) = Households.Number_Dev_Tot.(typ)(idx); %#ok<AGROW>
		number_devices_hh(end+1,:) = Households.Number_Devices.(typ)(idx,:); %#ok<AGROW>
	end
end
% Die bekannten Ger�te aus der Liste der unbekannten Ger�te streichen:
for i=1:numel(Varna_known)
	Varna_unkno(strcmpi(Varna_unkno,Varna_known(i)))=[];
end
% diese Listen in der DEVICES-Struktur speichern, f�r sp�tere Berechungen:
Devices.Elements_Varna_Known = Varna_known;
Devices.Number_created_Known = number_devices_hh;
Devices.Elements_Varna_Unknown = Varna_unkno;
num_known = sum(number_devices);
num_total = num_known + numel(Varna_unkno)*number_user;

% Array mit den Indizes der bekannten aktiven Ger�te erstellen:
dev_idx = zeros(numel(Varna_known), max(number_devices));

waitbar_start; % Messen der Zeit, die ben�tigt wird - Start
% Die bekannten Ger�te erzeugen:
for i=1:numel(Varna_known)
	% aktuellen Index in der Devices-Struktur ermitteln:
	idx = strcmpi(Devices.Elements_Varna, Varna_known(i));
	% wieviele Ger�te m�ssen in dieser Ger�teklasse erzeugt werden?
	num_dev = number_devices(i);
	% laufenden Index f�r diese Ger�tegruppe:
	run_idx = 1;
	% Variablenname der aktuellen Ger�teklasse:
	name = Devices.Elements_Varna{idx};
	% Funktionen-Handle auf zust�ndige Klasse auslesen
	dev_handle = Devices.Elements_Funha{idx};
	for j = 1:num_dev
		% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, Devices.Total_Number_Dev, num_total)
			% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
			% aufgetretenen Fehler erkennen k�nnen:
			Devices = [];
			% Ger�teerzeugung abbrechen:
			return;
		end
		% Ger�teinstanz erzeugen:
		dev = dev_handle(Model.Args.(name){:});
		% �berpr�fen, ob Ger�t �berhaupt im Einsatz, sonst verwerfen:
		if dev.Activity
			% aktuellen Ger�teindex in Ger�teinstanz und Ger�teindexarray speichern 
			% und Z�hler erh�hen:
			dev.ID_Index = run_idx;
			dev_idx(i,j)= run_idx;
			run_idx = run_idx + 1;
			% Ger�teinstanz in jeweiligen Array speichern:
			Devices.(name)(end+1) = dev;
			% Anzahl der erzeugten Ger�te aktualisieren:
			Devices.Number_Dev(idx) = Devices.Number_Dev(idx) + 1;
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	end
end

% Das Platzierungsarray der bekannten Ger�te Speichern:
Devices.Index_created_Known = dev_idx;

% die unbekannten Ger�te erzeugen (mit der Anzahl der Personen in den Haushalten):
for i=1:numel(Varna_unkno)
	% aktuellen Index in der Devices-Struktur ermitteln:
	idx = strcmpi(Devices.Elements_Varna, Varna_unkno(i));
	% laufenden Index f�r diese Ger�tegruppe:
	run_idx = 1;
	% Variablenname der aktuellen Ger�teklasse:
	name = Devices.Elements_Varna{idx};
	% Funktionen-Handle auf zust�ndige Klasse auslesen
	dev_handle = Devices.Elements_Funha{idx};
	for j = 1:number_user
		% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, num_known+(i-1)*number_user+j, num_total)
			% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
			% aufgetretenen Fehler erkennen k�nnen:
			Devices = [];
			% Ger�teerzeugung abbrechen:
			return;
		end
		% Ger�teinstanz erzeugen:
		dev = dev_handle(Model.Args.(name){:});
		% �berpr�fen, ob Ger�t �berhaupt im Einsatz, sonst verwerfen:
		if dev.Activity
			% aktuellen Ger�teindex in Ger�teinstanz speichern und Z�hler erh�hen:
			dev.ID_Index = run_idx;
			run_idx = run_idx + 1;
			% Ger�teinstanz in jeweiligen Array speichern:
			Devices.(name)(end+1) = dev;
			% Anzahl der erzeugten Ger�te aktualisieren:
			Devices.Number_Dev(idx) = Devices.Number_Dev(idx) + 1;
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	end
end
end
