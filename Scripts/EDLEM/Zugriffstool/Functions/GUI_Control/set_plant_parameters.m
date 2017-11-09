function set_plant_parameters(hObject, eventdata, plant_typ, plant_idx, ...
	parameter_typ)
%SET_PLANT_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

handles = guidata(hObject);

plant = handles.Current_Settings.(plant_typ).(['Plant_',num2str(plant_idx)]);

switch lower(parameter_typ)
	case 'installed_power'
		switch plant_typ
			case 'Sola'
				plant.Power_Installed = str2double(get(hObject,'String'));
				plant.Size_Collector = ...
					plant.Rel_Size_Collector * plant.Power_Installed;
			case 'Wind'
				% Änderung der installierten Leistung hat eine entsprechende Änderung
				% des Rotordurchmessers zur Folge, diese ermitteln:
				new_power = str2double(get(hObject,'String'))*1000;
				old_power = plant.Power_Installed;
				old_size = plant.Size_Rotor;
				
				new_size = sqrt(new_power/old_power)*old_size;
				
				plant.Power_Installed = new_power;
				plant.Size_Rotor = new_size;
		end
	case 'number'
		plant.Number = round(str2double(get(hObject,'String')));
	case 'typ'
		plant.Typ = get(hObject,'Value');
		switch plant_typ
			case 'Wind'
				if plant.Typ > 1
					% Im Fall einer Windenergieanlage die Werte der ausgewählten 
					% Anlage übernehmen:
					parameters = get_wind_turbine_parameters(plant.Typ-1);
					plant.Power_Installed = parameters{4};
					plant.v_nominal = parameters{5};
					plant.v_start = parameters{6};
					plant.v_cut_off = parameters{7};
					plant.Typ_Rotor = parameters{2};
					plant.Size_Rotor = parameters{3};
					plant.c_p =  parameters{8};
				end
		end
	case 'set_parameters'
		switch plant_typ
			case 'Sola'
				plant = Configuration_PV_Parameters(handles,'Parameters',plant);
			case 'Wind'
				plant = Configuration_Wind_Parameters(handles,'Parameters',plant);
		end
end

handles.Current_Settings.(plant_typ).(['Plant_',num2str(plant_idx)]) = plant;

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

end

