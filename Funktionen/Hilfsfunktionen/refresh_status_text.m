function refresh_status_text(hObject, new_status_text, mode)
%REFRESH_STATUS_TEXT    aktualieriert Status-Text in GUI
%    REFRESH_STATUS_TEXT(HOBJECT, NEW_STATUS_TEXT) aktualisiert den Statustext
%    im GUI von HOBJECT(Name: status_text) mit dem String NEW_STATUS_TEXT.
%
%    REFRESH_STATUS_TEXT(HOBJECT, NEW_STATUS_TEXT, 'Add') fügt dem aktuellen
%    Statustext den String NEW_STATUS_TEXT an.

%    Franz Zeilinger - 11.08.2010

% handles-Struktur aus hObject auslesen:
handles = guidata(hObject);

%    Franz Zeilinger 11.08.2010
if (nargin == 3) && strcmpi(mode, 'add')
	str = get(handles.status_text,'String');
	new_status_text = [str,new_status_text];
end
	
% neuen Statustext ausgeben:
handles.display.status_text = new_status_text;
set(handles.status_text,'String',new_status_text);
drawnow;

end