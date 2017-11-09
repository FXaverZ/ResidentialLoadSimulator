function Devices = create_devices_for_loadprofiles_parallel(hObject, Model, Households)
%CREATE_DEVICES_FOR_LOADPROFILES   Kurzbeschreibung fehlt.
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 10.12.2012
% Letzte Änderung durch:   Franz Zeilinger - 

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

known_devices = Households.Devices.Pool_Known;
number_user = Households.Statistics.(typ).Number_Per_Tot;

%Vorbereiten von Auflistungen der verwendeten Geräte im Modell:
Devices.Elements_Varna = {};  % Variablennamen für automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollständige Namen der jeweiligen Geräte 
                              %     z.B. für Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Elements_Eq_Le = {};  % Ausstattungsgrad mit diesem Gerät (f. Gerätegruppen)
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Geräte
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?

% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
% Wieviele Geräteklassen werden simuliert? Antwort gibt Device_Assembly_Simulation,
% hier ist eine eins für jede aktive Geräteklasse eingetragen, daher diese Struktur
% in ein Array umwandeln (zuerst Struktur in Zellenarray, dann Zellenarray in Matrix)
% und dann alles aufaddieren:
dev_num = sum(cell2mat(struct2cell(Model.Device_Assembly_Simulation)));
device = cell(dev_num,1);
args = cell(dev_num,1);
% Einen Zähler initialisieren, der den laufenden Geräteklassenindex entspricht (wenn
% nicht alle Geräte ausgewählt, entspricht dieser NICHT dem Schleifenindex!)
dev_num = 0;
% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Geräteklassenindex erhöhen:
		dev_num = dev_num + 1;
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		device{dev_num} = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{dev_num} = name;
		Devices.Elements_Names{dev_num} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{dev_num} = Model.Devices_Pool{i,3};
		Devices.Elements_Eq_Le{dev_num} = 100;
		% Ein eigenes Argumenten-Array aufbauen für parfor-Schleife:
		args{dev_num} = Model.Args.(name);
	end
end

Varna_unkno = Devices.Elements_Varna;
Devices.Number_Dev = zeros(1,numel(Varna_unkno)); % Anzahl in den einzelnen Gerätegruppen
Varna_known = {};
number_devices = [];
number_devices_hh = [];
% Erzeugen der Geräteinstanzen. Zuerst die an Anzahl bekannten Geräte (welche
% über die Haushaltsausstattung definiert worden sind):
% Feststellen, welche bekannten Geräte simuliert werden:
for i=1:numel(Varna_unkno)
	% ist das aktuelle Gerät ein bekanntes Gerät?
	idx = find(strcmpi(known_devices(:,1),Varna_unkno(i)));
	if ~isempty(idx)
		% bekanntes Gerät gefunden, in Liste speichern:
		Varna_known(end+1) = known_devices(idx,1); %#ok<AGROW>
		% die zugehörige Anzahl an Geräten ebenfalls speichern:
		number_devices(end+1) = Households.Devices.(typ).Number_Known_Tot(idx); %#ok<AGROW>
		number_devices_hh(end+1,:) = Households.Devices.(typ).Number_Known(idx,:); %#ok<AGROW>
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

% Falls Gerätegruppen vorhanden sind, den Austattungsgrad der einzelnen Elemente
% übernehmen:
if Model.Device_Groups.Present
	% über die möglichen Gerätegruppen iterieren:
	for i=1:size(Model.Device_Groups_Pool,1)
		% gibt es diese Gerätegruppe überhaupt?
		if ~isfield(Model.Device_Groups, Model.Device_Groups_Pool{i,1})
			continue;
		end
		% Mitglieder dieser Gruppe auslesen:
		member = Model.Device_Groups.(Model.Device_Groups_Pool{i,1}).Members;
		% über die Mitglieder iterieren:
		for j=1:size(member,1)
			% Zuordnung des Gerätetyps in den vorhandenen Geräten finden:
			idx = find(strcmp(Devices.Elements_Varna, member{j,1}));
			if isempty(idx)
				continue;
			end
			% ist dieses Gerät ein bekanntes Gerät: Austattungsgrad wird daher bei
			% den Haushaltsdaten angegeben und die Anzahl an zu erstellenden Geräten
			% ist damit schon bestimmt, Level hier auf 100% belassen:
			if ~isempty(find(strcmp(Varna_known, member{j,1}),1))
				continue;
			end
			% Austattung entsprechend abspeichern:
			Devices.Elements_Eq_Le{idx} = member{j,end};
		end
	end
end

% Hilfsarray erstellen, das anzeigt, ob das aktuelle Gerät eines mit bekannter oder
% unbekannter Geräteausstattung ist...
switch_var_known = cell(numel(Devices.Elements_Varna),2);
for i=1:numel(Devices.Elements_Varna)
	name = Devices.Elements_Varna{i};
	% ist es ein bekanntes Gerät?
	idx = find(strcmpi(Varna_known, name),1);
	if ~isempty(idx)
		switch_var_known{i,1} = 1;
		switch_var_known{i,2} = number_devices(strcmp(Varna_known, name));
	else
		switch_var_known{i,1} = 0;
	end
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start
dev_handles = Devices.Elements_Funha;
equ_levels = Devices.Elements_Eq_Le;
parfor i=1:size(switch_var_known,1)
	% Die bekannten Geräte erzeugen:
	% Funktionen-Handle auf zuständige Klasse auslesen
	dev_h = dev_handles{i};
	% wieviele Geräte müssen in dieser Geräteklasse erzeugt werden?
	switch_var = switch_var_known(i,:);
	if switch_var{1} % überhaupt bekanntes Gerät?	
		for j = 1:switch_var{2}
			% Geräteinstanz erzeugen:
			dev = dev_h(args{i}{:});
			% Geräteinstanz in jeweiligen Array speichern:
			device{i}(end+1) = dev;
		end
	else
		% die unbekannten Geräte erzeugen (mit der Anzahl der Personen in den
		% Haushalten): 
		equ_level = equ_levels{i};
		for j = 1:number_user
			% Geräteinstanz erzeugen:
			dev = dev_h(args{i}{:});
			% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen, dazu
			% eine Zufallszahl zwischen 0 und 100 erzeugen:
			fort = rand()*100;
			if fort <= equ_level
				% Geräteinstanz in jeweiligen Array speichern:
				device{i}(end+1) = dev;
			end
		end
	end
end

% Die erzeugten Geräteinstanzen im ursprünglichen Format in die Devices-Strukutr
% übernehmen:
% Array mit den Indizes der bekannten aktiven Geräte erstellen:
dev_idx = zeros(numel(Varna_known), max(number_devices));
dev_cou = 1;
for i = 1:size(Devices.Elements_Varna,2)
	name = Devices.Elements_Varna{i};
	Devices.(name) = device{i};
	Devices.Number_Dev(i) = numel(device{i});
	% ist es ein bekanntes Gerät?
	idx = find(strcmpi(Varna_known, name),1);
	if ~isempty(idx)
		for j = 1:numel(device{i})
			dev_idx(dev_cou,j) = j;
			dev_cou = dev_cou + 1;
		end
	end
end
Devices.Total_Number_Dev = sum(Devices.Number_Dev);
% Das Platzierungsarray der bekannten Geräte Speichern:
Devices.Index_created_Known = dev_idx;
end
