% Jahresprofil.m
% Autor: Christoph Lehner <e0925823@student.tuwien.ac.at>
% Erstellungsdatum: 2014-09-01
% Datum der letzten Revision: 2014-10-23

classdef Jahresprofil
	
	properties (GetAccess='private', SetAccess='private')
		Zeit; % Zeit im alten Profil
		Last; % Last im alten Profil
		Aufloesung; % Aufloesung des alten Profils
		ZeitNeu; % Zeit im neu berechneten Profil
		LastNeu; % Last im neu berechneten Profil
		AufloesungNeu; % Aufloesung des neuen Profils
		Jahresverbrauch;
	end
	
	methods
		
		%% Constructor
		function obj = Jahresprofil(t, P, tSteps)
			obj.Zeit = t;
			obj.Last = P;
			obj.Aufloesung = (t(2)-t(1));
			obj.ZeitNeu = tSteps;
			obj.AufloesungNeu = (tSteps(2)-tSteps(1));
			obj.LastNeu = zeros(size(tSteps,1),1);
			obj.Jahresverbrauch = 0;
		end
		%% Set Methoden
		function obj = setZeit(obj,t)
			obj.Zeit = t;
		end
		
		function obj = setLast(obj,P)
			obj.Last = P;
		end
		
		function obj = setLastNeu(obj,P)
			obj.LastNeu = P;
		end
		
		function obj = setZeitNeu(obj,t)
			obj.ZeitNeu = t;
		end
		
		function obj = addLast(obj,P,E)
			
			obj.Last = obj.Last + 10^3 * P * E / (sum(abs(P))*(obj.Aufloesung)/60);
			
			% Die Aufloesungen des neuen und alten Profils sind gleich
			if obj.AufloesungNeu == obj.Aufloesung
				obj.LastNeu = obj.LastNeu + 10^3 * P * E / (sum(abs(P))*(obj.Aufloesung)/60);
			end
			
			% Das Profil P wird interpoliert
			if ((obj.AufloesungNeu >= 1) && (obj.AufloesungNeu < obj.Aufloesung))
				obj.LastNeu = obj.LastNeu + E/1000*obj.Interpol( P, obj.Zeit, obj.ZeitNeu );
			end
			
			% Das Profil P wird extrapoliert
			if ((obj.AufloesungNeu > obj.Aufloesung) && (obj.AufloesungNeu <= 60))
				obj.LastNeu = obj.LastNeu + E/1000 * obj.Extrapol( P, obj.Zeit, obj.ZeitNeu );
			end
			
			obj.Jahresverbrauch = obj.Jahresverbrauch + E;
		end
		%% Get Methoden
		function t = getZeit(obj)
			t = obj.Zeit;
		end
		
		function L = getLast(obj)
			L = obj.Last;
		end
		
		function t = getZeitNeu(obj)
			t = obj.ZeitNeu;
		end
		
		function L = getLastNeu(obj)
			L = obj.LastNeu;
		end
		
		function [ t, L ] = getProfil(obj)
			t = obj.Zeit;
			L = obj.Last;
		end
		
		function [ t, L ] = getProfilNeu(obj)
			t = obj.ZeitNeu;
			L = obj.LastNeu;
		end
		
		function tstr = getZeitStr(obj)
			n = length(obj.Zeit);
			tstr = cell(n,1);
			for i=1:n
				tstr(i) = cellstr(datestr(time(i),'HH:MM'));
			end
		end
		%% Methoden zur Berechnung
		function obj = calcProfil(obj)
			
			if obj.AufloesungNeu == obj.Aufloesung
				obj.LastNeu = obj.Last;
			end
			
			if ((obj.AufloesungNeu >= 1) && (obj.AufloesungNeu < obj.Aufloesung))
				obj.LastNeu = Interpol( obj.Last, obj.Zeit, obj.ZeitNeu );
			end
			
			if ((obj.AufloesungNeu > obj.Aufloesung) && (obj.AufloesungNeu <= 60))
				obj.LastNeu = Extrapol( obj.Last, obj.Zeit, obj.ZeitNeu );
			end
			
			if obj.Jahresverbrauch ~= 0
				obj.LastNeu = obj.LastNeu * obj.Jahresverbrauch/1000;
			end
		end
	end
	
	methods (Hidden)
		function [ p ] = Interpol(~, Profil, T, t )
			% Profil... altes Profil
			% p... interpoliertes Profil
			% T... Zeitschritte im alten Profil
			% t... Zeitschritte im neuen Profil
			
% 			p = spline(T,Profil,t);
			p = interp1([0;T],[Profil(end);Profil],t);
			% Das Profil wird auf 1000kWh normiert
			p = 10^6 * p / (sum(abs(p))*(t(2)-t(1))/60);
		end
		
		function [ p ] = Extrapol(~, profile, T, t )
			% profile... altes Profil
			% p... interpoliertes Profil
			% T... Zeitschritte im alten Profil
			% t... Zeitschritte im neuen Profil
			
			n = size(t,1);
			p = zeros(n,1);
			%deltaTime = T(2) - T(1);
			deltaNewTime = t(2) - t(1);
			i = 1;
			
			if ( T(end) < t(end) )
				
				for j=1:(n-1)
					num = 0;
					k = 0;
					
					% Berechnung wie viele Zeitschritte des alten Profils in einem
					% Zeitintervall des neuen Profils voerliegen
					while ((k+i) <= size(profile,1) ) &&( T(k+i) <= t(j) )
						num = num + 1;
						k = k + 1;
					end
					
					% Der erste Punkt des Profil wird extrapoliert
					if ( i == 1 )
						p(j) = profile(i)*T(1);
						
						if ( num > 1 )
							for m=2:num
								p(j) = p(j) + profile(m)*(T(m)-T(m-1));
							end
							p(j) = p(j) + profile(m+1)*(t(j)-T(m));
							i = i + m;
						else
							p(j) = p(j) + profile(2)*(t(j)-T(1));
							i = 2;
						end
						
					else
						p(j) = profile(i)*(T(i)-t(j-1));
						if ( num > 1 )
							
							for m=(i+1):(num+i-1)
								p(j) = p(j) + profile(m)*(T(m)-T(m-1));
							end
							m = m + 1;
							if ( t(j) ~= T(m-1) )
								p(j) = p(j) + profile(m)*(t(j)-T(m-1));
							end
							i =  m;
						else
							p(j) = p(j) + profile(i+1)*(t(j)-T(i));
							i = i + 1;
						end
						
					end
				end
				
				p(end) = p(end-1) + (p(end-1) - p(end-2));
			else
				for j=1:n
					num = 0;
					k = 0;
					
					% Berechnung wie viele Zeitschritte des alten Profils in einem
					% Zeitschritt des neuen Profils voerliegen
					while ((k+i) <= size(profile,1) ) &&( T(k+i) <= t(j) )
						num = num + 1;
						k = k + 1;
					end
					
					% Der erste Punkt des Profil wird extrapoliert
					if ( i == 1 )
						p(j) = profile(i)*T(1);
						
						if ( num > 1 )
							for m=2:num
								p(j) = p(j) + profile(m)*(T(m)-T(m-1));
							end
							p(j) = p(j) + profile(m+1)*(t(j)-T(m));
							i = i + m;
						else
							p(j) = p(j) + profile(2)*(t(j)-T(1));
							i = 2;
						end
						
					else
						p(j) = profile(i)*(T(i)-t(j-1));
						if ( num > 1 )
							
							for m=(i+1):(num+i-1)
								p(j) = p(j) + profile(m)*(T(m)-T(m-1));
							end
							m = m + 1;
							if ( t(j) ~= T(m-1) )
								p(j) = p(j) + profile(m)*(t(j)-T(m-1));
							end
							i =  m;
						else
							p(j) = p(j) + profile(i+1)*(t(j)-T(i));
							i = i + 1;
						end
					end
				end
			end
			
			p = p / deltaNewTime;
			% Das Profil wird auf 1000kWh normiert
			p = 10^6 * p / (sum(abs(p))*(t(2)-t(1))/60);
		end
	end
end


