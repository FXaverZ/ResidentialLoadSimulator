function Configuration = save_summary_data_for_device_profiles (Configuration, ...
	Summary, Households, Devices, Model, Time) 
%SAVE_SUMMARY_DATA_FOR_DEVICE_PROFILES Summary of this function goes here
%   Detailed explanation goes here

% Erstellt von:            Franz Zeilinger - 04.12.2012
% Letzte Änderung durch:   Franz Zeilinger - 18.12.2012

% benötigte Daten laden:
file = Configuration.Save.Data;
% Dateinamen erstellen:
date = datestr(Households.Result.Sim_date,'HH_MM.SS');
sep = Model.Seperator;
file.Summary_Name = [date,sep,'Summary'];

% Zeitvektor für Excel-File erstellen:
time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
time = time' - datenum('30-Dec-1899');

% aus den Daten ein Excel-File erstellen:
xls = XLS_Writer();
seasons = Model.Seasons;
weekdays = Model.Weekdays;
for i=1:numel(seasons)
	ssn = seasons{i};
	for j=1:size(weekdays,1)
		wkd = weekdays{j,:};
		if ~isfield(Summary, ssn) || ~isfield (Summary.(ssn), wkd)
			continue;
		end
		% Wenn Einträge existent, Daten laden:
		num_days = Summary.(ssn).(wkd).Number_Days;
		num_user = Summary.Devices.Power.(ssn).(wkd).Number_User;
		dev_data = Summary.Devices.Power.(ssn).(wkd);
		dev_data = rmfield(dev_data, 'Number_User');
		% Anzahl an Nutzern anpassen (da in der Funktion
		% UPDATE_SUMMARY_FOR_DEVICE_PROFILES bei jedem Durchlauf und gleichen
		% Tagestyp die jeweilige Bewohneranzahl zur bisherigen addiert wird, muss für
		% die echte Anzahl an unabhängigen Benutzern diese Zahl durch die Anzahl an
		% simulierte Tagen dividiert werden!):
		num_user = num_user / num_days;
		Summary.Devices.Power.(ssn).(wkd).Number_User = num_user;
		% Neues Tabellenblatt anlegen:
		xls.set_worksheet([ssn,'_',wkd]);
		xls.next_row;
		% Die Namen für die Spaltenüberschrift auslesen:
		names = fieldnames(dev_data);
		% Datenstruktur umwandeln:
		dev_data =  cell2mat(struct2cell(dev_data));
		% auf einen Nutzer und einen Tag normieren:
		dev_data = dev_data' / (num_user * num_days);
		% Überschriften:
		xls.write_lines({'Zeit',names{:}}); %#ok<CCAT>
		xls.next_row(2);
		xls.write_values([time,dev_data]);
	end
end
xls.write_output([file.Path,file.Summary_Name,'.xlsx']);

% schließlich die Rohdaten speichern:
file.Summary_Name = [date,sep,'Summary'];
save([file.Path,file.Summary_Name,'.mat'],...
	'Model','Summary','Time');


end

