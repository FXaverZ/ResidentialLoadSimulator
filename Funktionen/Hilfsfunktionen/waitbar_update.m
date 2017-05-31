function abort = waitbar_update (hObject, time_update, act_pos, end_pos)
%WAITBAR_UPDATE    Anzeigen einer Fortschrittsanzeige für ein GUI
%    ABORT = WAITBAR_UPDATE (HOBJECT, TIME_UPDATE, ACT_POS, END_POS)
%    sorgt für das Fortschreiten eines farbigen Balkens (Name:
%    Wait_bar_color in Abhängikeit vom ursprünglichen (weißen) Balken
%    Waitbar_white) im aufrufenden GUI HOBJECT. Weiters wird ein Statustext im
%    Balken mit der vorrausichtlich verbleibenden Zeit angezeigt (Name:
%    Waitbar_status_text). Zusätzlich wird in die Konsole ein Text mit der
%    vorraussichtlichen Gesamtdauer ausgegeben.
%    TIME_UPDATE gibt die Zeit in Sekunden an, die zwischen zwei
%    Aktualisierungen verstreichen soll, ACT_POS gibt den aktuellen Stand in der
%    Berechnung an, der 100% erreicht wenn ACT_POS = END_POS.
%    WAITBAR_UPDATE muss zusammen mit den Funktionen WAITBAR_START und
%    WAITBAR_RESET folgendmaßen verwendet werden:
%
%    WAITBAR_START;  %Starten der Zeitmessung für Fortschrittsanzeige 
%        any_statements;
%    WAITBAR_UPDATE(hObject), arguments) %Update der Anzeige in hObject
%        any_statements;
%    WAITBAR_RESET(hObject);  %Beenden der Zeitmessung und Rücksetzen der Anzeige

%    Franz Zeilinger - 11.08.2009

% Definieren der globalen Variablen für Kommunikation der waitbar_-Funktionen:
global WAITBAR_COUNTER;
global WAITBAR_TIC_START;

abort = 0;
time = toc(WAITBAR_TIC_START);

if time > time_update*WAITBAR_COUNTER
	drawnow;
	handles = guidata(hObject);
	% Wurde Abbruch durch User gewünscht?
	if handles.system.cancel_simulation
		waitbar_reset(hObject);
		abort = 1;
		return;
	end
	% Fortschritt berechnen:
	progress = act_pos/end_pos;
	% Restliche Zeit ermitteln:
	sec_remain = time/progress - time;
	if WAITBAR_COUNTER <= 1
		% Anzeigen der vorraussichtlichen Dauer:
		str = [' (Dauer ca. ',sec2str(sec_remain + time),') '];
		refresh_status_text(hObject,str,'Add');
		fprintf(str);
	end
	% Ausgabe der Restdauer in Statusanzeige:
	string = [num2str(progress*100,'%4.1f'),...
		' % erledigt, ca. ', sec2str(sec_remain),' Restdauer'];
	set(handles.Waitbar_status_text,'String',string);
	% Balkenlänge anpassen:
	pos = get(handles.Waitbar_white,'Position');
	pos(3) = progress*pos(3);
	set(handles.Wait_bar_color,'Position',pos);
	drawnow;
	while (WAITBAR_COUNTER*time_update < time)
		WAITBAR_COUNTER = WAITBAR_COUNTER + 1;
	end
end
end