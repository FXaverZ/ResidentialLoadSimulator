function New_Devices = pick_devices (Model, Devices)
%PICK_DEVICES    wählt aus vorhandenen Geräteinstanzen die für Simulation nötigen aus
%    NEW_DEVICES = PICK_DEVICES (MODEL, DEVICES) erzeugt aus der bereits
%    vorhandenen Gerätestruktur DEVICES eine neue Gerätestruktur NEW_DEVICES,
%    die nur jene Geräte enthält, die für die Simulation, die in MODEL definiert
%    ist, notwendig sind. 
%    
%    Es empfiehlt sich, die ursprüngliche Gerätestruktur für die Dauer der
%    Simulation zu speichern und nach der Simulation die neue Struktur mit der
%    alten zu überschreiben, da diese Funktion immer eine Untermenge der
%    verfügbaren Geräte zurückgibt, für zukünftige Simulationen aber eventuell
%    die anderen Geräteklassen benötigt werden!

%    Franz Zeilinger - 17.08.2010

% Falls in vorhergehender Funktion Fehler aufgetreten ist:
if isempty (Devices)
	New_Devices = [];
	return;
end

% Zurücksetzen aller zu verändernden Felder:
New_Devices.Elements_Varna = {}; %Variablenname für automatisches Abarbeiten
New_Devices.Elements_Names = {}; %Für Legendenbeschriftung
New_Devices.Elements_Funha = {}; %Handles auf Klassenfunktionen 
New_Devices.Total_Number_Dev = 0; %Gesamtanzahl aller beteiligten Geräte
% Kopieren sonstiger wichtiger Parameter:
New_Devices.DSM_included = Devices.DSM_included;
New_Devices.Number_User = Devices.Number_User;

% Übernehmen der notwendigen Geräteklassen:
for i=1:size(Model.Elements_Pool,1)
	name = Model.Elements_Pool{i,1};
	if Model.Device_Assembly.(name)
		New_Devices.(name) = Devices.(name);
		New_Devices.Elements_Varna{end+1} = name;
		New_Devices.Elements_Names{end+1} = Model.Elements_Pool{i,2};
		New_Devices.Elements_Funha{end+1} = Model.Elements_Pool{i,3};
		New_Devices.Total_Number_Dev = New_Devices.Total_Number_Dev + ...
			numel(Devices.(name));
	end
end