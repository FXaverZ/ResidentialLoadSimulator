% Dieses Script gibt den Inhalt der Datenbank aus (quantitative Angaben zu den
% Datensätzen):

% Franz Zeilinger - 13.02.2011

setti.name_database = 'EDLEM_Datenbank_neu';

% Ordner, in dem die Datenbank gespeichert ist:
files.target.path = [pwd,filesep,setti.name_database];

% Ist bereits eine Datenbank vorhanden?
setti.add_data_mode = false;
try
	load([files.target.path,filesep,setti.name_database,'.mat']);
	user_response = questdlg('Anzahl der Datenbankelemente auslesen?',...
		'Behandlung vorhandener Datenbank',...
		'Ja', 'Nein', 'Abbrechen','Ja');
	switch user_response
		case 'Ja'
			setti.add_data_mode = true;
		case 'Nein'
			setti.add_data_mode = false;
		otherwise
			return;
	end
	drawnow;
catch ME
end

if ~setti.add_data_mode
	return;
end

fprintf('\n\n+----------------------+\n');
fprintf('| Haushaltslastprofile |\n');
fprintf('+----------------------+');
% Die Zählerstrukturen auslesen und Ausgabe an Konsole:
% for i = 1:numel(setti.seasons)
% 	season = setti.seasons{i};
% 	for j = 1:numel(setti.weekdays)
% 		weekday = setti.weekdays{j};
		for k = 1:numel(setti.households)
			househ = setti.households{k};
			% Zählerstände einlesen
			counter_datasets_total = ...
				setti.counter_hh.datasets_total.(househ);
			counter_idx_file = ...
				setti.counter_hh.idx_file.(househ);
			% Ausgabe in Konsole:
			fprintf(['\n ',...%season,files.sep,weekday,files.sep,...
				househ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
		end
% 	end
% end

fprintf('\n+----------------------+\n');
fprintf('| PV-Einspeise-Profile |\n');
fprintf('+----------------------+');
for i = 1:numel(setti.seasons)
	season = setti.seasons{i};
	counter_idx_file = setti.counter_pv.idx_file.(season);
	counter_datasets_total = setti.counter_pv.datasets_total.(season);
	fprintf(['\n',season,files.sep,...
		'Solar',files.sep,'Cloud_Factor',files.sep,...
		num2str(counter_idx_file,'%03.0f'),': ',...
		num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
end

fprintf('\n+-----------------------------+\n');
fprintf('| Windkraft-Einspeise-Profile |\n');
fprintf('+-----------------------------+');
for i = 1:numel(setti.seasons)
	season = setti.seasons{i};
	counter_idx_file = setti.counter_wi.idx_file.(season);
	counter_datasets_total = setti.counter_wi.datasets_total.(season);
	fprintf(['\n',season,files.sep,...
		'Wind',files.sep,'Speed',files.sep,...
		num2str(counter_idx_file,'%03.0f'),': ',...
		num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
end
fprintf('\n-------------------------------\n');