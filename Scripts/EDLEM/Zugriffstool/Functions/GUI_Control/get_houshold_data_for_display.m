function Output = get_houshold_data_for_display(handles, typ)
%GET_HOUSHOLD_DATA_FOR_DISPLAY    formatiert Ausgabetext für Haushalte
%   Detaillierte Beschreibung fehlt!

% Franz Zeilinger - 30.11.2011

% Index des aktuellen Haushalts ermitteln:
idx = strcmp(handles.Households.Types(:,1),typ);
% Daten auslesen:
hh_typs = handles.Households.Types;
hh_devs = handles.Households.Device_Distribution.(typ);

% Ausgabe formatieren:
Output = {};
Output{end+1} = ['Informationen für den Haushalt "',...
	hh_typs{idx,4},'":'];
Output{end+1} = ['- - - - - - - - - - - - - - - - - - - - - - - - - - - - ',...
	'- - - - - - - - - '];
Output{end+1} = '';
Output{end+1} = ['Minimale Anzahl an Haushaltsmitgliedern: ',num2str(hh_typs{idx,2})];
Output{end+1} = ['Maximale Anzahl an Haushaltsmitgliedern: ',num2str(hh_typs{idx,3})];
Output{end+1} = '';
Output{end+1} = 'Geräteausstattung (sofern bekannt):';
for i=1:size(hh_devs,1)
	Output{end+1} = ['    ',hh_devs{i,1},': ',num2str(hh_devs{i,2},'%5.2f'),'%']; %#ok<AGROW>
end
Output{end+1} = '';

% Daten zur Anzeige bringen:
h = msgbox(Output,'Detailierte Haushaltsinfos');
% Größe des Fensters anpassen:
pos = get(h,'Position');
pos(4) = round(pos(4)*0.9);
set(h,'Position',pos);
end

