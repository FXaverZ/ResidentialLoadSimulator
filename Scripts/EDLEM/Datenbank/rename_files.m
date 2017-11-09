% testfile - alte Simulationsdaten an neue Bezeichnung anpassen:

path_source = 'D:\Projekte\EDLEM\6_Ergebnisse\Lastprofile (sec)';
path_target = 'D:\EDLEM - Datenbank\Quelldaten\Lastprofile (sec)';

weekdays =  ['Workda'; 'Saturd'; 'Sunday'];  % Typen der Wochentage
seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
sep = ' - ';

% Einlesen der Dateinamen im Quellordner:
data_names_source = dir(path_source);
data_names_source = struct2cell(data_names_source);
data_names_source = data_names_source(1,3:end);

for i = 1:size(data_names_source,2)
	% Datum entfernen:
	name = data_names_source{1,i};
	date = name(1:8);
	name = name(12:end);
	% handelt es sich um ein Simulationslog?
	if strncmp(name,'Simulations-Log',15)
		% falls ja, diesen Eintrag überspringen:
		continue;
	end
	% Kennzeichnung als Lastprofil, Auflösung und Dateiendung entfernen:
	name = name(15:end);
	reso = name(1:3);
	name = name(15:end-4);
	if length(name) > 7
		typ = name(1:7);
		idx = name(11:end);
	end
	% Daten laden (data_phase):
	load([path_source,filesep,data_names_source{1,i}]);
	if mod(size(data_phase,2),6) ~= 0
		% Bei manchen Daten ist in erster Splaten noch eine Zeitinformation, diese
		% entfernen!:
		data_phase = data_phase(:,2:end);
	end
	
	% neuen Dateinamen zusammensetzen:
	for j = 1:size(weekdays,1)
		wkd = weekdays(j,:);
		for k = 1:numel(seasons)
			season = seasons{k};
			new_name = [date,sep,season,sep,wkd,sep,typ,sep,reso,sep,idx];
			% neue Datei speichern:
			save([path_target,filesep,new_name,'.mat'],'data_phase');
		end
	end
end