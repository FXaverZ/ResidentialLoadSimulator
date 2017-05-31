function waitbar_start
%WAITBAR_START    startet die Fortschrittsanzeige für ein GUI
%    WAITBAR_START startet die Zeitmessung für die Fortschrittsanzeige im GUI
%    von HOBJECT. Nähere Informationen dazu findet sich in der
%    Dokumentation der Funktion WAITBAR_UPDATE. 
%
%    WAITBAR_START muss zusammen mit den Funktionen WAITBAR_RESET und
%    WAITBAR_UPDATE folgendmaßen verwendet werden:
%
%    WAITBAR_START;  %Starten der Zeitmessung für Fortschrittsanzeige 
%        any_statements;
%    WAITBAR_UPDATE(hObject), arguments) %Update der Anzeige in hObject
%        any_statements;
%    WAITBAR_RESET(hObject);  %Beenden der Zeitmessung und Rücksetzen der Anzeige
%
%    Franz Zeilinger - 11.08.2009

% Definieren der globalen Variablen für Kommunikation der waitbar_-Funktionen:
global WAITBAR_COUNTER;
global WAITBAR_TIC_START;
% Setzen der globalen Variablen auf die Start-Werte:
WAITBAR_COUNTER = 1;
WAITBAR_TIC_START = tic;