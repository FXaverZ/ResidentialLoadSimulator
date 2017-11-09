% BDEWProfil.m
% Autor: Christoph Lehner <e0925823@student.tuwien.ac.at>
% Erstellungsdatum: 2014-09-15
% Datum der letzten Revision:

function  [t, P] = BDEWProfil_2014( data, DynFaktor, type )
% data... Matrix - Daten aus dem sheet des Standardlastprofils
% DynFaktor... Vektor - Dynamisierungsfaktoren

% Zeitschritt im Profil berechnen
deltaTime = round((data(2,1)-data(1,1))*24*60);
% days gibt an, welche Spalten aus den Daten des Excel-files
% zum Profil zusammengefasst werden sollen
days = dayType;
% Modelljahr 2014 erstellen!!!! 1.Jänner = Mittwoch, 31.12.14 = Mittwoch
days = days(3:end);
days(end+1) = 4;

% Anzahl der Zeitschritte im Jahr
n = floor(365 * 24 * 60 / deltaTime);


% Zeitschritte im Jahr
t = zeros(n,1);
% Leistung zu den Zeitschritten
P = zeros(n,1);

% Zeitschritte berechnen
for i=1:n
	t(i,1) = i*deltaTime;
end

% Das Profil berechnen
if strcmp('H0',type)
	for j=1:365
		% Ueber 365 Tage
		m = size(data,1);
		for k=(1+(j-1)*m):(m*j)
			% Ein Tag wird aus data zusammen mit dem Dynamisierungsfaktor
			% in P gespeichert
			P(k) = data(k-(j-1)*m,days(j))*DynFaktor(j);
		end
	end
elseif strcmp('G7',type)
		for j=1:365
		% Ueber 365 Tage
		m = size(data,1);
		for k=(1+(j-1)*m):(m*j)
			% Ein Tag wird aus data zusammen mit dem Dynamisierungsfaktor
			% in P gespeichert
			P(k) = data(k-(j-1)*m,days(j));
		end
	end
elseif strcmp('B1',type)
	idxs = data(97:end,:);
	data = data(1:96,:);
	m = size(data,1);
	for j=1:365
		idx = find(j == idxs);
		[~,col_data] = ind2sub(size(idxs),idx);
		for k=(1+(j-1)*m):(m*j)
			% Ein Tag wird aus data zusammen mit dem Dynamisierungsfaktor
			% in P gespeichert
			P(k) = data(k-(j-1)*m,col_data);
		end
	end
else
	for j=1:365
		% Ueber 365 Tage
		m = size(data,1);
		for k=(1+(j-1)*m):(m*j)
			% Ein Tag wird aus data zusammen mit dem Dynamisierungsfaktor
			% in P gespeichert
			P(k) = data(k-(j-1)*m,days(j))*DynFaktor(j);
		end
	end
end

P = 10^6 * P / ((sum(P)*deltaTime)*24);

end

