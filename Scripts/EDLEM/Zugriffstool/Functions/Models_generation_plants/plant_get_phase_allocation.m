function [phase_idx, power_factor] = plant_get_phase_allocation(plant)
%PLANT_GET_PHASE_ALLOCATION    determines the phase(s) a plant is connected to
%   PLANT_GET_PHASE_ALLOCATION gets from the input structure PLANT the phase allocation
%   mode (plant.Phase_Allocation_Mode) and makes an allocation of the phase(s) the
%   generation plant will be connected. Output are the phase indexes PHASE_IDX for
%   handling in three phase power matrizes and the power distribution factor POWER_FACTOR,
%   who is telling the calling code, if the overall power is distributed over different
%   phases (therfore the overall power has to be divided by the POWER_FACTOR).

% Created by:        Franz Zeilinger - 10.01.2018
% Last changes by:   

if strcmpi(plant.Phase_Allocation_Mode,'auto')
		if plant.Power_Installed < plant.Max_Power_4_Single_Phase
			% Einphasig:
			phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
			power_factor = 1;
		else
			% Dreiphasig:
			phase_idx = [1,2,3];
			power_factor = 3;
		end
	elseif strcmpi(plant.Phase_Allocation_Mode,'1pha')
		% Einphasig:
		phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
		power_factor = 1;
	elseif strcmpi(plant.Phase_Allocation_Mode,'3pha')
		% Dreiphasig:
		phase_idx = [1,2,3];
		power_factor = 3;
	end

end

