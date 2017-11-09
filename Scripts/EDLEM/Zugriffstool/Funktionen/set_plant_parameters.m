function set_plant_parameters(hObject, eventdata, ...
	plant_typ, plant_idx, parameter_typ)
%SET_PLANT_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

handles = guidata(hObject);

plant = handles.Settings.(plant_typ).(['Plant_',num2str(plant_idx)]);

switch lower(parameter_typ)
	case 'installed_power'
		plant.Power_Installed = str2double(get(hObject,'String'));
	case 'number'
		plant.Number = round(str2double(get(hObject,'String')));
	case 'typ'
		plant.Typ = get(hObject,'Value');
end

handles.Settings.(plant_typ).(['Plant_',num2str(plant_idx)]) = plant;

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

end

