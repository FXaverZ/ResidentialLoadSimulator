function Model = update_model_overlap (Path, season_1, season_2, Model)
%UPDATE_MODEL_OVERLAP Summary of this function goes here
%   Detailed explanation goes here

% Geräteparameter laden:
Model_1 = load_device_parameter(Path,season_1.parafilemname, Model);
Model_2 = load_device_parameter(Path,season_2.parafilemname, Model);
% Überprüfen, ob beim Laden Fehler aufgetreten sind:
if isempty(Model_1) || isempty(Model_2)
	Model = [];
	return;
end

dev_names = fields(Model.Args);

for i=1:numel(dev_names)
	Args_1 = Model_1.Args.(dev_names{i});
	Args_2 = Model_2.Args.(dev_names{i});
		
	% Suche nach den relavanten Parametern (jene, die in den Parameterfiles zwischen
	% den Jahreszeiten geändert wurden...):
	idx_time_start = find(strcmp(Args_1,'Time_Start'));
	idx_start_prob = find(strcmp(Args_1,'Start_Probability'));
	idx_time_typ_r = find(strcmp(Args_1,'Time_typ_Run'));
	
	% Diese auslesen und überarbeiten:
	if ~isempty(idx_time_start) && ~isempty(idx_start_prob)
		% die Gewichtungsfaktoren:
		d.factor_1 = season_1.factor;
		d.factor_2 = season_2.factor;
		% die eigentlichen Argumente:
		d.tim_sta_1 = Args_1{idx_time_start+1};
		d.tim_sta_2 = Args_2{idx_time_start+1};
		d.tim_sta_dev_1 = Args_1{idx_time_start+2};
		d.tim_sta_dev_2 = Args_2{idx_time_start+2};
		d.sta_pro_1 = Args_1{idx_start_prob+1};
		d.sta_pro_2 = Args_2{idx_start_prob+1};
		% die Startzeiten von Text in Matlabzeit umwandeln (für Möglichkeit des
		% direkten Vergleichs):
		d.tim_sta_ad_1 = datenum(d.tim_sta_1,'HH:MM');
		d.tim_sta_ad_2 = datenum(d.tim_sta_2,'HH:MM');
		
		% Falls noch typische Laufzeiten (Time_typ_Run) )vorhanden sind, diese ebenfalls
		% berücksichtigen, ansonten ein Dummy-Array erstellen:
		if ~isempty(idx_time_typ_r)
			d.tim_tyr_1 = Args_1{idx_time_typ_r+1};
			d.tim_tyr_2 = Args_2{idx_time_typ_r+1};
		else
			d.tim_tyr_1 = zeros(size(d.tim_sta_dev_1));
			d.tim_tyr_2 = zeros(size(d.tim_sta_dev_2));
		end
		
		% bestimmen, welcher Zeitvektor der längste ist, dann entsprechend einen
		% Index zuweisen:
		if numel(d.tim_sta_dev_1) >= numel(d.tim_sta_dev_2)
			idx_long = 1;
			idx_shor = 2;
		else
			idx_long = 2;
			idx_shor = 1;
		end
		
		% Suchen nach gleichen Zeiteinträgen, die Position dieser in beiden
		% Argumentelisten speichern, in Form eines Index-Arrays: Erste Spalte
		% entspricht Eintrag in längeren Zeitvektor, zweite Spalte entspricht Eintrag
		% im kürzeren Zeitvektor:
		idx_equ = [];
		counter = 1;
		while counter <= numel(d.(['tim_sta_ad_',num2str(idx_long)]))
			idx = find(d.(['tim_sta_ad_',num2str(idx_long)])(counter) == d.(['tim_sta_ad_',num2str(idx_shor)]));
			if ~isempty(idx)
				for j=1:numel(idx)
					idx_equ(end+1,1) = counter; %#ok<AGROW>
					idx_equ(end,2)=idx(j);
					counter = counter + 1;
				end
			else
				counter = counter + 1;
			end
		end
		
		% eine Indexliste erstellen (für beide Zeitvektoren:
		ent_long = 1:numel(d.(['tim_sta_ad_',num2str(idx_long)]));
		ent_shor = 1:numel(d.(['tim_sta_ad_',num2str(idx_shor)]));
		
		% neue Argumentenlisten aufbauen:
		tim_sta = [];
		sta_pro = [];
		tim_sta_dev = [];
		tim_tyr = [];
		% Zunächst die gleichen Elemente zusammenführen:
		for j=1:size(idx_equ,1)
			% Startzeiten übernehmen
			tim_sta = [tim_sta;d.(['tim_sta_',num2str(idx_long)])(idx_equ(j,1),:)]; %#ok<AGROW>
			
			% Vektor mir der Streuung der Startzeit aufbauen
			tim_sta_dev_l = d.(['tim_sta_dev_',num2str(idx_long)])(idx_equ(j,1),:);
			tim_sta_dev_s = d.(['tim_sta_dev_',num2str(idx_shor)])(idx_equ(j,2),:);
			stdev = tim_sta_dev_l * d.(['factor_',num2str(idx_long)]) + ...
				tim_sta_dev_s * d.(['factor_',num2str(idx_shor)]);
			tim_sta_dev = [tim_sta_dev; stdev]; %#ok<AGROW>
			
			% die Startwahrscheinlichkeit aus den beiden Werten sowie den geforderten
			% Übergangsfaktoren ermitteln
			sta_pro_l = d.(['sta_pro_',num2str(idx_long)])(idx_equ(j,1),:);
			sta_pro_s = d.(['sta_pro_',num2str(idx_shor)])(idx_equ(j,2),:);
			pro = sta_pro_l * d.(['factor_',num2str(idx_long)]) + ...
				sta_pro_s * d.(['factor_',num2str(idx_shor)]);
			% Startwahrscheinlichkeitsvektor aufbauen
			sta_pro = [sta_pro; pro]; %#ok<AGROW>
			
			% die typische Laufzeit mit Hilfe der Übergangsfaktoren zusammensetzen:
			tim_tyr_l = d.(['tim_tyr_',num2str(idx_long)])(idx_equ(j,1),:);
			tim_tyr_s = d.(['tim_tyr_',num2str(idx_shor)])(idx_equ(j,2),:);
			tyr = tim_tyr_l * d.(['factor_',num2str(idx_long)]) + ...
				tim_tyr_s * d.(['factor_',num2str(idx_shor)]);
			% typischen Laufzeitvektor aufbauen:
			tim_tyr = [tim_tyr; tyr]; %#ok<AGROW>
			
			% die behandelten Einträge aus den Indexlisten löschen, damit sie nicht
			% nochmal bearbeitet werden...
			ent_long(ent_long == idx_equ(j,1))=[];
			ent_shor(ent_shor == idx_equ(j,2))=[];
		end
		
		% die restlichen Werte in die Vektoren eintragen:
		tim_sta = [...
			tim_sta;...
			d.(['tim_sta_',num2str(idx_long)])(ent_long,:);...
			d.(['tim_sta_',num2str(idx_shor)])(ent_shor,:);...
			]; %#ok<AGROW>
		tim_sta_dev = [...
			tim_sta_dev;...
			d.(['tim_sta_dev_',num2str(idx_long)])(ent_long,:);...
			d.(['tim_sta_dev_',num2str(idx_shor)])(ent_shor,:);...
			]; %#ok<AGROW>
		sta_pro = [...
			sta_pro;...
			d.(['sta_pro_',num2str(idx_long)])(ent_long,:)*d.(['factor_',num2str(idx_long)]);...
			d.(['sta_pro_',num2str(idx_shor)])(ent_shor,:)*d.(['factor_',num2str(idx_shor)]);...
			]; %#ok<AGROW>
		tim_tyr = [...
			tim_tyr;...
			d.(['tim_tyr_',num2str(idx_long)])(ent_long,:);...
			d.(['tim_tyr_',num2str(idx_shor)])(ent_shor,:);...
			]; %#ok<AGROW>
		
		% Daten noch sortieren:
		tim_sta_ad = datenum(tim_sta, 'HH:MM');
		[~, IX] = sort(tim_sta_ad);
		
		tim_sta = tim_sta(IX,:);
		tim_sta_dev = tim_sta_dev(IX);
		sta_pro = sta_pro(IX);
		tim_tyr = tim_tyr(IX);
		
		Args = Model.Args.(dev_names{i});
		idx_time_start = find(strcmp(Args,'Time_Start'));
		idx_start_prob = find(strcmp(Args,'Start_Probability'));
		idx_time_typ_r = find(strcmp(Args,'Time_typ_Run'));
		
		Args{idx_time_start+1} = tim_sta;
		Args{idx_time_start+2} = tim_sta_dev;
		Args{idx_start_prob+1} = sta_pro;
		if ~isempty(idx_time_typ_r)
			Args{idx_time_typ_r+1} = tim_tyr;
		end
		
		Model.Args.(dev_names{i}) = Args;
		
	end

end

