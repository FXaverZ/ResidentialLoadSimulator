function handles = add_gernation_plant_to_gui(handles, genera_typ)
%ADD_GERNATION_PLANT_TO_GUI    fügt eine Erzeugungsanlage dem GUI "Access_Tool" hinzu
%   Detaillierte Beschreibung fehlt!

% Franz Zeilinger - 20.12.2011

% Anzahl an Pixel, um die erweitert werden muss:
d_pos = handles.System.Generation.Input_Field_Height;

% Hauptfenster vergrößern:
posi = get(handles.accesstool_main_window,'Position');
posi(4) = posi(4) + d_pos;
set(handles.accesstool_main_window,'Position', posi);
% Die Panels 'Siedlungsstruktur', 'Einstellungen' nach oben verschieben (damit
% sie die gleiche Position behalten:
posi = get(handles.uipanel_structure_settlement,'Position');
posi(2) = posi(2) + d_pos;
set(handles.uipanel_structure_settlement,'Position', posi);
posi = get(handles.uipanel_settings,'Position');
posi(2) = posi(2) + d_pos;
set(handles.uipanel_settings,'Position', posi);
% Das Panel 'Erzeugungsstruktur' vergrößern:
posi = get(handles.uipanel_genera,'Position');
posi(4) = posi(4) + d_pos;
set(handles.uipanel_genera,'Position', posi);
% die Textfelder "Anzahl" und "installierte Leistung" nach oben schieben:
posi = get(handles.text_genera_number,'Position');
posi(2) = posi(2) + d_pos;
set(handles.text_genera_number,'Position', posi);
posi = get(handles.text_genera_installed_power,'Position');
posi(2) = posi(2) + d_pos;
set(handles.text_genera_installed_power,'Position', posi);
switch genera_typ
	case 'Sola'
		% Das Panel 'Photovoltaik' vergrößern:
		posi = get(handles.uipanel_genera_pv,'Position');
		posi(4) = posi(4) + d_pos;
		set(handles.uipanel_genera_pv,'Position', posi);
		% Handle zum aktuellen Panel merken (PV):
		panel_handle = handles.uipanel_genera_pv;
	case 'Wind'
		% Das Panel 'Photovoltaik' verschieben:
		posi = get(handles.uipanel_genera_pv,'Position');
		posi(2) = posi(2) + d_pos;
		set(handles.uipanel_genera_pv,'Position', posi);
		% Das Panel "Kleinwindkraftanlagen" vergrößern:
		posi = get(handles.uipanel_genera_wind,'Position');
		posi(4) = posi(4) + d_pos;
		set(handles.uipanel_genera_wind,'Position', posi);
		% Handle zum aktuellen Panel merken (Wind):
		panel_handle = handles.uipanel_genera_wind;
end
% Die vorherigen Einstellungsbereiche nach oben schieben:
plants = fieldnames(handles.Current_Settings.(genera_typ));
for i=1:size(plants,1)
	tags = get_plant_gui_tags(handles.System.(genera_typ).Tags, i);
	for j=1:size(tags,1)
		posi = get(handles.(tags{j}),'Position');
		posi(2) = posi(2) + d_pos;
		set(handles.(tags{j}),'Position', posi);
	end
end

% Neue Eingabeelemente einfügen:
idx_new_ele = size(plants,1)+1;
new_tags = get_plant_gui_tags(handles.System.(genera_typ).Tags, idx_new_ele);

% Popup-Menü:
posi = get(handles.(tags{1}),'Position'); % Position des ähnlichen Elements
posi(2) = posi(2) - d_pos;
handles.(new_tags{1}) = uicontrol(panel_handle,...
	'Style','popupmenu',...
	'Position',posi,...
	'BackgroundColor', get(handles.(tags{1}),'BackgroundColor'),...
	'String',handles.System.(genera_typ).Typs(:,1),...
	'Callback',{'set_plant_parameters',genera_typ,idx_new_ele,'typ'});

%  Eingabefeld Anzahl:
posi = get(handles.(tags{2}),'Position'); % Position des ähnlichen Elements
posi(2) = posi(2) - d_pos;
handles.(new_tags{2}) = uicontrol(panel_handle,...
	'Style','edit',...
	'Position',posi,...
	'BackgroundColor', get(handles.(tags{2}),'BackgroundColor'),...
	'Callback',{'set_plant_parameters',genera_typ,idx_new_ele,'number'});

%  Eingabefeld installierte Leistung:
posi = get(handles.(tags{3}),'Position'); % Position des ähnlichen Elements
posi(2) = posi(2) - d_pos;
handles.(new_tags{3}) = uicontrol(panel_handle,...
	'Style','edit',...
	'Position',posi,...
	'BackgroundColor', get(handles.(tags{3}),'BackgroundColor'),...
	'Callback',{'set_plant_parameters',genera_typ,idx_new_ele,'installed_power'});

% Textfeld Einheit:
posi = get(handles.(tags{5}),'Position'); % Position des ähnlichen Elements
posi(2) = posi(2) - d_pos;
handles.(new_tags{5}) = uicontrol(panel_handle,...
	'Style','text',...
	'String', get(handles.(tags{5}), 'String'),...
	'Position',posi,...
	'HorizontalAlignment',get(handles.(tags{5}),'HorizontalAlignment'));

% Pushbutton Parameter:
posi = get(handles.(tags{4}),'Position'); % Position des ähnlichen Elements
posi(2) = posi(2) - d_pos;
handles.(new_tags{4}) = uicontrol(panel_handle,...
	'Style','pushbutton',...
	'String',get(handles.(tags{4}),'String'),...
	'Position',posi,...
	'Callback',{'set_plant_parameters',genera_typ,idx_new_ele,'set_parameters'});

% Default-Werte für neue Anlage einstellen:
handles.Current_Settings.(genera_typ).(['Plant_',num2str(idx_new_ele)]) = ...
	handles.System.(genera_typ).Default_Plant;

end

