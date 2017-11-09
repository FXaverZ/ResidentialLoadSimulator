function out = vary_parameter(mean, sigma, varargin)
%VARY_PARAMETER    führt verschiedene Parametervariationen & Auswahlen durch
%    OUT = VARY_PARAMETER(MEAN, SIGMA) sorgt für eine Normalverteilung um den
%    Mittelwert MEAN mit der Standardabweichung SIGMA.
%    MEAN kann ein [N,M]-Array sein, mit N Einträgen von M verschiedenen
%    Parametern. SIGMA muss in diesem Fall ein [1,M]-Vektor sein, der für jeden
%    der M Parameter die Standardabweichung definiert.
%    Im Fall eines MEAN-Arrays der Form [N,1] kann Sigma ein Einzelwert sein
%    (der die Standardverteilung für alle N Einträge darstellt) oder ebenfalls
%    ein [N,1]-Array, welches verschiedene Standarabweichungen zu den korrespon-
%    dierenden Werten von MEAN angibt.
%    SIGMA muss in % angegeben werden!
%
%    OUT = VARY_PARAMETER(VALUE, 'Uniform_Distr') sorgt für eine Variierung des
%    Wertes VALUE gemäß einer Gleichverteilung im Bereich 0 bis VALUE
%
%    OUT = VARY_PARAMETER(MEAN, SIGMA, 'Uniform_Distr') sorgt für eine
%    Variierung des Wertes MEAN gemäß einer Gleichverteilung im Bereich
%    MEAN*(1-SIGMA) bis MEAN(1+SIGMA). SIGMA wird in Prozent des
%    Mittelwerts übergeben.
%
%    OUT = VARY_PARAMETER(TIME, SIGMA, 'Time') sorgt für eine Variierung des
%    Zeitpunktes TIME (angegeben in Minuten) um SIGMA Minuten.
%
%    OUT = VARY_PARAMETER(LIST, PROBABILITY, 'List') sorgt für eine zufällige
%    Auswahl eines Eintrages aus einer [N,1]-Liste LIST. Die [N,1]-Liste
%    PROBABILITY gibt die jeweilige Wahrscheinlichkeitsdichte der einzelnen
%    Listenwerte an (die Gesamtsumme aller Einträge von PROBABILITY muss somit
%    100% ergeben)

%    Franz Zeilinger - 29.10.2010

if nargin == 3 && strcmpi(varargin{1},'list')
	% Eintrag muss aus einer Liste ausgewählt werden
	list = mean;
	proba = sigma/100; % Umrechnen von %
	sum_proba = sum(proba,1);
	% Überprüfen, ob die Eingangsvariablen stimmen:
	if (numel(list) == numel(proba)) && (abs(sum_proba-1) <= 1e-3)
		% Umrechnen der angegebenen Wahrscheinlichkeitsdichte in eine
		% kummulative Verteilungsfunktion:
		for i = 1:numel(proba)-1
			proba(i+1,1) = proba(i,1) + proba(i+1,1);
		end
		% Wahrscheinlichkeitsbereich definieren
		proba1 = [0; proba(1:end-1)];
		proba = [proba1, proba];
		fort = rand();
		% Ermitteln, in welchen Bereich Zufallszahl (zw. 0 und 1) fällt:
		idx = proba(:,1) < fort & fort <= proba(:,2);
		if fort == 0
			% falls Zufallszahl 0, 1. Bereich wählen:
			idx = 1;
		end
		% Je nach Listentyp Eintrag zurückgeben:
		if iscell(list)
			out = list{idx};
		else
			out = list(idx);
		end
		return;
	else
		error('DSM_Device:paramlist', ['Fehler bei Parameter',...
			'variierung: fehlende bzw. ungültige Einträge für ',...
			'Auswahl eines Listeneintrages (z.B. bei Verteilung)!']);
	end
end

if nargin == 3 && strcmpi(varargin{1},'uniform_distr')
	% Wert zwischen -1 und +1 erzeugen gem. einer Gleichverteilung:
	fort = 2*(rand()-0.5);
	out = mean+(mean*sigma/100*fort);
end

% Falls in SIGMA der String 'Uniform_Distr' steht, eine Gleichverteilung
% durchführen:
if ischar(sigma) && strcmpi(sigma, 'uniform_distr')
	% Wert zwischen 0 und 1 erzeugen gem. einer Gleichverteilung:
	fort = rand();
	out = fort*mean;
	return;
end

% Falls SIGMA-Vektor nicht zu MEAN-Array passt, SIGMA anpassen:
if size(sigma,1) ~= size(mean,1)
	sig = repmat(sigma(1,:), [size(mean,1),1]);
else
	sig = sigma;
end
if size(sig,2) ~= size(mean,2)
	sig = repmat(sig, [1,floor(size(mean,2)/size(sig,2))]);
end

% Jeweilige Varriierung durchführen:
if nargin == 2
	out = normrnd(mean, abs(mean.*sig/100));
elseif nargin == 3 && strcmpi(varargin{1},'time')
	out = mean + normrnd(0,sig);
end
end