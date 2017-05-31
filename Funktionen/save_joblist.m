function no_error = save_joblist(Configuration, Joblist)
%SAVE_JOBLIST    speichert die aktuelle Jobliste für Simulationsreihe
%    NO_ERROR = SAVE_JOBLIST(CONFIGURATION, JOBLIST) erzeugt ein xls-File mit
%    der Liste von Pfaden zu den abzuarbeitenden Parameterdateien für eine
%    Reihensimulation. Der Speicherort wird in CONFIGURATION definiert (durch
%    aufrufendes GUI). Zusätzlich zu den Pfaden wird zum einfachen Aufrufen der
%    Parameterdateien jeweils ein Link zu dieser abgespeichert.
%    NO_ERROR gibt an, ob das Speichern erfolgreich abgeschlossen wurde
%    (NO_ERROR = true) oder nicht möglich war (NO_ERROR = false).

file = Configuration.Save.Joblist;
no_error = 1;
try
% XLS-Writer erzeugen für das Erzeugen eines xls-Files:
xls = XLS_Writer(); 
xls.write_lines('Auflistung der Parameterdateien für Simulationsdurchlauf:');
xls.next_row;
xls.write_lines({'Lfd.Nr.','Link zu Datei','Pfad der Datei'});
for i=1:size(Joblist,1)
	xls.write_values(num2str(i,'%02u'));
	xls.write_values({['=HYPERLINK("',Joblist{i,1},'"&"',...
		Joblist{i,2},'"&".xls";"LINK")']});
	xls.write_lines([Joblist{i,1},Joblist{i,2},'.xls']);
	if Configuration.Options.use_different_frequency_data
		xls.write_values({'','Frequ_Data:'});
		xls.write_lines([Joblist{i,3},Joblist{i,4}]);
	end	
end
xls.set_worksheet('Joblist');
xlsn = [file.Path,file.List_Name,'.xls']; % Dateiname .xls-File
xls.write_output(xlsn);
catch ME
	error_text = {...
		'Fehler sind beim Speichern der Job-Listendatei aufgetreten:';...
		' ';...
		[' - ',ME.message]};
	error_titl = 'Fehler beim Laden der Parameterdatei';
	errordlg(error_text, error_titl);
	no_error = 0;
end
end