function Devices = create_devices_parallel(hObject, Model)
%CREATE_DEVICES    erzeugt Ger�teinstanzen f�r Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Ger�teinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Ger�te erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (f�r Statusanzeige).

% Erstellt von:            Franz Zeilinger - 10.08.2011
% Letzte �nderung durch:   Franz Zeilinger - 12.12.2012

% F�r sp�tere �berpr�fung, ob Ger�teinstanzen f�r eine weitere Verwendung
% gebraucht werden k�nnen, die Anzahl der Personen in der Ger�te-Struktur
% speichern:
Devices.Number_User = Model.Number_User;

%Auflistung der verwendeten Ger�te im Modell:
Devices.Elements_Varna = {};  % Variablennamen f�r automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollst�ndige Namen der jeweiligen Ger�te
%     z.B. f�r Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Elements_Eq_Le = {};  % Ausstattungsgrad mit diesem Ger�t
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Ger�te
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die ben�tigt wird - Start

% Vorbereiten der Arrays f�r die Ger�te-Instanzen der Ger�testruktur:
% Wieviele Ger�teklassen werden simuliert? Antwort gibt Device_Assembly_Simulation,
% hier ist eine eins f�r jede aktive Ger�teklasse eingetragen, daher diese Struktur
% in ein Array umwandeln (zuerst Struktur in Zellenarray, dann Zellenarray in Matrix)
% und dann alles aufaddieren:
dev_num = sum(cell2mat(struct2cell(Model.Device_Assembly_Simulation)));
device = cell(dev_num,1);
args = cell(dev_num,1);
% Einen Z�hler initialisieren, der den laufenden Ger�teklassenindex entspricht (wenn
% nicht alle Ger�te ausgew�hlt, entspricht dieser NICHT dem Schleifenindex!)
dev_num = 0;
% Nun �ber alle m�glichen Ger�teklassen iterieren:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Ger�teklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Ger�teklassenindex erh�hen:
		dev_num = dev_num + 1;
		% Funktionen-Handle auf zust�ndige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		device{dev_num} = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{dev_num} = name;
		Devices.Elements_Names{dev_num} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{dev_num} = Model.Devices_Pool{i,3};
		% eine zus�tzliche Zuordnung mitspeichern: diese beschreibt einen
		% Ausstattungsrad mit einem bestimmten Ger�tetyp: bei der Erzeugung der
		% Ger�tinstanzen wird auf diesen Wert R�cksicht genommen, d.h. f�r einen Wert
		% von 50 ergibt sich hier, dass nur 50% der erzeugten Ger�te-Instanzen auch
		% f�r die Simulation �bernommen werden. Per Default wird f�r alle Ger�te der
		% Wert 100 (%) eingetragen, sprich, jede erzeugte Instanz wird auch
		% �bernommen! 
		Devices.Elements_Eq_Le{end+1} = 100;
		% Ein eigenes Argumenten-Array aufbauen f�r parfor-Schleife:
		args{dev_num} = Model.Args.(name);
	end
end

% Falls Ger�tegruppen vorhanden sind, den Austattungsgrad der einzelnen Elemente
% �bernehmen:
if Model.Device_Groups.Present
	% �ber die m�glichen Ger�tegruppen iterieren:
	for i=1:size(Model.Device_Groups_Pool,1)
		% gibt es diese Ger�tegruppe �berhaupt?
		if ~isfield(Model.Device_Groups, Model.Device_Groups_Pool{i,1})
			continue;
		end
		% Mitglieder dieser Gruppe auslesen:
		member = Model.Device_Groups.(Model.Device_Groups_Pool{i,1}).Members;
		% �ber die Mitglieder iterieren:
		for j=1:size(member,1)
			% Zuordnung des Ger�tetyps in den vorhandenen Ger�ten finden:
			idx = find(strcmp(Devices.Elements_Varna, member{j,1}));
			if isempty(idx)
				continue;
			end
			% Austattung entsprechend abspeichern:
			Devices.Elements_Eq_Le{idx} = member{j,end};
		end
	end
end

try
	% Erzeugen der jeweiligen Ger�teinstanzen:
	dev_handles = Devices.Elements_Funha;
	total_number_dev = 0;
	num_user = Model.Number_User;
	equ_level = Devices.Elements_Eq_Le;
	parfor j=1:numel(Devices.Elements_Varna)
		% Funktionen-Handle auf zust�ndige Klasse auslesen
		dev_handle = dev_handles{j};
		for i=1:num_user
			% Austattungsgrad:
			equ_l = equ_level{j};
			% solange der Austattungsgrad positiv, Ger�te generieren:
			while equ_l > 0
				% Ger�teinstanz erzeugen:
				dev = dev_handle(args{j}{:});
				% �berpr�fen, ob Ger�t �berhaupt im Einsatz, sonst verwerfen, dazu
				% eine Zufallszahl zwischen 0 und 100 erzeugen:
				fort = rand()*100;
				if fort <= equ_l;
					% Ger�teinstanz in jeweiligen Array speichern:
					device{j}(end+1) = dev;
					% Anzahl der erzeugten Ger�te aktualisieren:
					total_number_dev = total_number_dev + 1;
				end
				% Reduzieren des Ausstattungsgrades:
				equ_l = equ_l - 100;
			end
		end
	end
catch ME
	% Falls Fehler aufgetreten ist, dies dem User mitteilen, sowie die Fehlermeldung
	% ausgeben: 
	error_titl = 'Fehler beim Erzeugen der Ger�teinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Ger�teinstanzen f�r';...
		'';...
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen k�nnen:
	Devices = [];
	return;
end

% Die erzeugten Ger�teinstanzen im urspr�nglichen Format in die Devices-Strukutr
% �bernehmen:
for i = 1:size(Devices.Elements_Varna,2)
	Devices.(Devices.Elements_Varna{i}) = device{i};
	Devices.Total_Number_Dev = total_number_dev;
end
end
