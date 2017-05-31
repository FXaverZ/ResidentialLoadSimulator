function waitbar_start
%WAITBAR_START    startet die Fortschrittsanzeige f�r ein GUI
%    WAITBAR_START startet die Zeitmessung f�r die Fortschrittsanzeige im GUI
%    von HOBJECT. N�here Informationen dazu findet sich in der
%    Dokumentation der Funktion WAITBAR_UPDATE. 
%
%    WAITBAR_START muss zusammen mit den Funktionen WAITBAR_RESET und
%    WAITBAR_UPDATE folgendma�en verwendet werden:
%
%    WAITBAR_START;  %Starten der Zeitmessung f�r Fortschrittsanzeige 
%        any_statements;
%    WAITBAR_UPDATE(hObject), arguments) %Update der Anzeige in hObject
%        any_statements;
%    WAITBAR_RESET(hObject);  %Beenden der Zeitmessung und R�cksetzen der Anzeige
%
%    Franz Zeilinger - 11.08.2009

% Definieren der globalen Variablen f�r Kommunikation der waitbar_-Funktionen:
global WAITBAR_COUNTER;
global WAITBAR_TIC_START;
% Setzen der globalen Variablen auf die Start-Werte:
WAITBAR_COUNTER = 1;
WAITBAR_TIC_START = tic;