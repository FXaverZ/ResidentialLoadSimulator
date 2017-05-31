function total_time = waitbar_reset(hObject)
%WAITBAR_RESET    zur�cksetzen der Fortschrittsanzeige eines GUI
%    TOTAL_TIME = WAITBAR_RESET (HOBJECT) setzt die Fortschrittsanzeige im GUI
%    von HOBJECT zur�ck. N�here Informationen dazu findet sich in der
%    Dokumentation der Funktion WAITBAR_UPDATE. 
%    TOTAL_TIME ist jene Zeit, die vom Aufruf von WAITBAR_START bis bis zum
%    Aufruf dieser Funktion vergangen ist in Sekunden.
%
%    WAITBAR_RESET muss zusammen mit den Funktionen WAITBAR_START und
%    WAITBAR_UPDATE folgendma�en verwendet werden:
%
%    WAITBAR_START;  %Starten der Zeitmessung f�r Fortschrittsanzeige 
%        any_statements;
%    WAITBAR_UPDATE(hObject), arguments) %Update der Anzeige in hObject
%        any_statements;
%    WAITBAR_RESET(hObject);  %Beenden der Zeitmessung und R�cksetzen der Anzeige
%
%    Franz Zeilinger - 04.08.2011

% Definieren der globalen Variablen f�r Kommunikation der waitbar_-Funktionen:
global WAITBAR_TIC_START;

% Falls diese Funktion vor erstmaligen Ausf�hren von WAITBAR_RESET aufgerufen
% wird, nichts unternehmen, ansonsten normale Funktion:
if ~isempty(WAITBAR_TIC_START)
	total_time = toc(WAITBAR_TIC_START);
	
	WAITBAR_TIC_START = [];
	handles = guidata(hObject);
	set(handles.Waitbar_status_text,'String',' ');
	pos = get(handles.Wait_bar_color,'Position');
	pos(3) = 0.05;
	set(handles.Wait_bar_color,'Position',pos);
	drawnow;
else
	total_time = [];
end