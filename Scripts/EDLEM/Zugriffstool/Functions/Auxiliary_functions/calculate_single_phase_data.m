function data_single_phase = calculate_single_phase_data(data_phase)
%CALCULATE_SINGLE_PHASE_DATA    errechnen einphasiger Daten aus dreiphasigen
%    DATA_SINGLE_PHASE = CALCULATE_SINGLE_PHASE_DATA(DATA_PHASE) errechnet aus den
%    dreiphasigen Daten DATA_PHASE einphasige Daten. Dazu werden die jeweiligen
%    Spalten aufaddiert.

% Franz Zeilinger 04.07.2012

% Falls leeres Array übergeben wurde, zurückkehren:
if isempty(data_phase)
	return;
end

% Leerarray in der korrekten Größe erstellen:
data_single_phase = zeros(size(data_phase,1),size(data_phase,2)/3);
% die einzelnen Phasenleistungen aufaddieren:
% Wirkleistung
data_single_phase(:,1:2:end) = ...
	data_phase(:,1:6:end) + ...
	data_phase(:,3:6:end) + ...
	data_phase(:,5:6:end);
% Blindleistung:
data_single_phase(:,2:2:end) = ...
	data_phase(:,2:6:end) + ...
	data_phase(:,4:6:end) + ...
	data_phase(:,6:6:end);
end