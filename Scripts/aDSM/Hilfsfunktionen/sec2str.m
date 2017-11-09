function str = sec2str(t)
%SEC2STR    ermittelt Zeitstring aus Zeitspanne
%    STR = SEC2STR(T) ermittelt aus einer Zeitspanne T in Sekunden einen String der
%    Form 'HHh MMmin SS.SSSsec' und gibt diesen zurück. Je nach Lände der
%    Zeitspanne werden keine Angaben zu HH und MM gemacht bzw. die Genauigkeit
%    der Zahlendarstellung angepasst.

% Erstellt von:            Franz Zeilinger - 11.08.2010
% Letzte Änderung durch:   Franz Zeilinger - 27.02.2013

sec_lin = datenum('1900-01-01 00:00:01')-datenum('1900-01-01 00:00:00');
date = datenum('1900-01-01 00:00:00')+t*sec_lin;
[~,~,~,h,min,sec] = datevec(date);
if (h > 0)
	str = [num2str(h),'h ',...
		num2str(min),' min ',num2str(floor(sec)),' sec'];
elseif (h <= 0) && (min > 0)
	str = [num2str(min),' min ',num2str(floor(sec)),' sec'];
else
	str = [num2str(sec,'%3.1f'),' sec'];
end
		