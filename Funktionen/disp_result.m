function disp_result(Model, Devices, Frequency, Result)
%DISP_RESULT    zeigt die Ergebnisse der Simulation
%    DISP_RESULT(MODEL, DEVICES, TIME, FREQUENCY, RESULT) zeigt die Ergebnisse der
%    Simulation (Struktur RESULT) fertig formatiert an.

% Franz Zeilinger - 14.06.2011

time = Result.Time;
% Create figure
figure1 = figure;
% Create axes
axes1 = axes('Parent',figure1);
% 	'XTickLabel',['00:00';'06:00';'12:00';'18:00';'00:00'],...
% 	'XTick',[7.342e+005 7.342e+005 7.342e+005 7.342e+005 7.342e+005]);
box('on');
hold('all');

% Zeitdaten und Frequenzdaten auslesen
if Result.Time_Base < 60
	stepsize = 1;
else
	stepsize = Result.Time_Base/30;
end
t_points = Result.Time;
Freq = Frequency(:,1:stepsize:end);
% Ermitteln der Frequenzdaten für Anzeige, siehe Funktion CREATE_FREQUENCY_DATA!
idx = Freq(1,:)>= t_points(1) & Freq(1,:) <= t_points(end);
Freq = Freq(2,idx);

data = Result.Displayable.Power_Class_and_Total_kW;

[AX,H1,H2] = plotyy (time, data , time, Freq, 'plot');
if Model.Use_DSM
	DSM_data = Result.Displayable.DSM_Power_Class_and_Total_kW;
	H3 = plot(time, DSM_data);
	color = get(H1, 'Color');
	for i=1:numel(H3)
		set(H3(i),'Color',color{i});
	end
	set(H1,'LineStyle',':');
end

no_val = false;

set(get(AX(1),'Ylabel'),'String','Aufgenommene Leistung [kW]');
if Model.Use_DSM && (max(DSM_data(1,:)) >= ...
		max(data(1,:)))
	if max(DSM_data(1,:)) > 1
		axis([-Inf, Inf, 0, ...
			(11/4)*ceil(max(DSM_data(1,:))/2.5)]);
	elseif max(DSM_data(1,:)) < 1 && ...
			max(DSM_data(1,:)) > 0
		axis([-Inf, Inf, 0, ...
			(11/40)*ceil(max(DSM_data(1,:))/0.25)]);
	else
		axis([-Inf, Inf, -0.1, 0.1]);
		no_val = true;
	end
else
	if max(data(1,:)) > 1
		axis([-Inf, Inf, 0, ...
			(11/4)*ceil(max(data(1,:))/2.5)]);
	elseif max(data(1,:)) < 1 && ...
			max(data(1,:)) > 0
	axis([-Inf, Inf, 0, ...
		(11/40)*ceil(max(data(1,:))/0.25)]);
	else
		axis([-Inf, Inf, -0.1, 0.1]);
		no_val = true;
	end
end

if no_val
	ylimits = get(AX(1),'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
	set(AX(1),'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
		ylimits(1):yinc:ylimits(2));
	
	set(get(AX(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	axis(AX(2),[-Inf, Inf, 47, 52]);
	ylimits = get(AX(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
	set(AX(2),'YTick',ylimits(1):yinc:ylimits(2),'XColor','b','YColor','b');
	set(H2,'LineStyle','--','Color','b');
else
	ylimits = get(AX(1),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(AX(1),'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
		ylimits(1):yinc:ylimits(2));
	
	set(get(AX(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	axis(AX(2),[-Inf, Inf, 46.5, 52]);
	ylimits = get(AX(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(AX(2),'YTick',ylimits(1):yinc:ylimits(2),'XColor','b','YColor','b');
	set(H2,'LineStyle','--','Color','b');
end

timeticks = time(1):1/24:time(end);

set(gca,'XTick',timeticks,'XGrid','on');
datetick('x','HH:MM','keepticks')
xlabel(AX(1),'Uhrzeit');
set(AX(2),'XTick',[]);

if Model.Number_User > 1
	titlestr = ['Simulationsergebnis: durchschnittlicher Verbrauch von ',...
		num2str(Model.Number_User),' Personen (',datestr(Result.Sim_date,...
		'yy.mm.dd - HHhMM.SS'),')'];
else
	titlestr = ['Simulationsergebnis: durchschnittlicher Verbrauch',...
		' einer Person (',datestr(Result.Sim_date,'yy.mm.dd - HHhMM.SS'),')'];
end

title(titlestr,'FontWeight','bold')

% Legende erstellen:
legend1 = legend(axes1,'show');
set(legend1,'Location','Best','String',[{'Gesamtleistung'},...
	Devices.Elements_Names]);

% Aufteilung auf die einzelnen Phasen darstellen:
% Create figure
figure2 = figure;
% Create axes
axes2 = axes('Parent',figure2);
box('on');
hold('all');
[AX2,H4,H5] = plotyy (time, Result.Displayable.Power_Phase_kW, time, Freq, 'plot');
if Model.Use_DSM
	color = get(H4, 'Color');
	set(H4,'LineStyle',':');
	H6 = plot(time, Result.Displayable.DSM_Power_Phase_kW);
	for i=1:numel(H6)
		set(H6(i),'Color',color{i});
	end
end

no_val = false;

set(get(AX2(1),'Ylabel'),'String','Aufgenommene Leistung [kW]');
if Model.Use_DSM && (max(Result.Displayable.DSM_Power_Phase_kW(1,:)) >= ...
		max(Result.Displayable.Power_Phase_kW(1,:)))
	if max(Result.Displayable.DSM_Power_Phase_kW(1,:)) > 1
		axis([-Inf, Inf, 0, ...
			(11/4)*ceil(max(Result.Displayable.DSM_Power_Phase_kW(1,:))/2.5)]);
	elseif max(Result.Displayable.DSM_Power_Phase_kW(1,:)) < 1 && ...
			max(Result.Displayable.DSM_Power_Phase_kW(1,:)) > 0
		axis([-Inf, Inf, 0, ...
			(11/40)*ceil(max(Result.Displayable.DSM_Power_Phase_kW(1,:))/0.25)]);
	else
		axis([-Inf, Inf, -0.1, 0.1]);
		no_val = true;
	end
else
	if max(Result.Displayable.Power_Class_kW(1,:)) > 1
		axis([-Inf, Inf, 0, ...
			(11/4)*ceil(max(Result.Displayable.Power_Class_kW(1,:))/2.5)]);
	elseif max(Result.Displayable.Power_Class_kW(1,:)) < 1 && ...
			max(Result.Displayable.Power_Class_kW(1,:)) > 0
	axis([-Inf, Inf, 0, ...
		(11/40)*ceil(max(Result.Displayable.Power_Class_kW(1,:))/0.25)]);
	else
		axis([-Inf, Inf, -0.1, 0.1]);
		no_val = true;
	end
end

if no_val
	ylimits = get(AX2(1),'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
	set(AX2(1),'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
		ylimits(1):yinc:ylimits(2));
	
	set(get(AX2(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	axis(AX2(2),[-Inf, Inf, 47, 52]);
	ylimits = get(AX2(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
	set(AX2(2),'YTick',ylimits(1):yinc:ylimits(2),'XColor','b','YColor','b');
	set(H5,'LineStyle','--','Color','b');
else
	ylimits = get(AX2(1),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(AX2(1),'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
		ylimits(1):yinc:ylimits(2));
	
	set(get(AX2(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	axis(AX2(2),[-Inf, Inf, 46.5, 52]);
	ylimits = get(AX2(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(AX2(2),'YTick',ylimits(1):yinc:ylimits(2),'XColor','b','YColor','b');
	set(H5,'LineStyle','--','Color','b');
end

set(gca,'XTick',timeticks,'XGrid','on');
datetick('x','HH:MM','keepticks')
xlabel(AX2(1),'Uhrzeit');
set(AX2(2),'XTick',[]);

if Model.Number_User > 1
	titlestr = ['Simulationsergebnis: durchschnittlicher Verbrauch von ',...
		num2str(Model.Number_User),' Personen - Phasenleistungen (', ...
		datestr(Result.Sim_date, 'yy.mm.dd - HHhMM.SS'),')'];
else
	titlestr = ['Simulationsergebnis: durchschnittlicher Verbrauch',...
		' einer Person - Phasenleistungen (',datestr(Result.Sim_date,...
		'yy.mm.dd - HHhMM.SS'),')'];
end

title(titlestr,'FontWeight','bold')

% Legende erstellen:
legend1 = legend(axes2,'show');
set(legend1,'Location','Best','String',[{'L1'},{'L2'},{'L3'}]);
end
