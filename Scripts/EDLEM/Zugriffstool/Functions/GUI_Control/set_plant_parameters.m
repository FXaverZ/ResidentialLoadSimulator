function set_plant_parameters(hObject, eventdata, plant_typ, plant_idx, ...
	parameter_typ)
%SET_PLANT_PARAMETERS    Einstellungen für Erzeugungsanlagen übernehmen
%    SET_PLANT_PARAMETERS(HOBJECT, EVENTDATA, PLANT_TYP, PLANT_IDX, PARAMETER_TYP)
%    ermöglicht das Ändern der Parameter von Erzeugungsanlagen.
%    Dabei wird direkt auf die handles-Struktur des aufrufenden GUI-Objekts zurück-
%    gegriffen (siehe GUIDATA). Über die Angabe des Erzeugertyps (PLANT_TYP), Index 
%    der Anlage in der Datenstruktur (PLANT_IDX) und die Angabe des Parameters, der 
%    geändert werden soll (PARAMETER_TYP), werden die entsprechenden Einstellungen 
%    im GUI übernommen.
%
%    Die Möglichkeiten sind dabei:
%        PLANT_TYP = Art der Erzeugungsanlage 
%            'Sola' ... Solaranlage
%            'Wind' ... Windkraftanlage
%        PARAMETER_TYP = Zu ändernder Parameter (wird mit HOBJECT ausgelesen)
%            'installed_power' ... installierte Leistung 
%            'number'          ... Anzahl an gleichen Analgen
%            'typ'             ... Bauart der Anlage (z.B. 'fix' oder 'tracker')
%            'set_parameters'  ... Aufrufen des Sub-GUIs mit den erweiterten
%                                  Einstellungen
%
%    Der Parameter EVENTDATA wird nicht benötigt, muss aber in der Input-Liste
%    angeführt werden (MATLAB spezifisch)!

% Franz Zeilinger - 30.05.2012

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

