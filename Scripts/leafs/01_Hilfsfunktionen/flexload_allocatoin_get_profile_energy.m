function [Energy_information, Energy_values] = flexload_allocatoin_get_profile_energy(input_simdata, sep, input_selector, timebase, ontime)
%FLEXLOAD_ALLOCATOIN_GET_PROFILE_ENERGY Summary of this function goes here
%   Detailed explanation goes here

% retrieve the information of the simulated profiles:
content = dir(input_simdata.path);
content = struct2cell(content);
content = content(1,3:end);

Energy_information = {};
Energy_values = [];
time_idx_new = [];
for a=1:numel(content)
	% actual path
	path = content{a};
	% get the files in this subdirectory:
	files = dir([input_simdata.path,filesep,path]);
	files = struct2cell(files);
	files = files(1,3:end);
	% load the model data:
	for b=1:numel(files)
		filename = files{b};
		name_parts = regexp(filename, sep, 'split');
		if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat')
			%loadin of the model settings:
			load([input_simdata.path,filesep,path,filesep,filename]);
			break;
		end
	end
	% search for the summaries:
	simtimeid = [];
	for b=1:numel(files)
		filename = files{b};
		name_parts = regexp(filename, sep, 'split');
		switch lower(input_selector)
			case 'as simulated'
				if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Powers_Year');
					simtimeid = name_parts{2};
					break;
				end
			case 'without flexible loads'
				if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Powers_Year_FlexSep');
					simtimeid = name_parts{2};
					break;
				end
			otherwise
				error('Not supported!!!');
		end
	end
	
	num_runs = Model.Number_Runs;
	hh_names = Model.Households(:,1);
	
	for b=1:numel(hh_names)
		act_hh = hh_names{b};
		switch lower(input_selector)
			case 'as simulated'
				load([input_simdata.path,filesep,path,filesep,'Summary',sep,simtimeid,sep,'Powers_Year',sep,act_hh,'.mat'])
			case 'without flexible loads'
				load([input_simdata.path,filesep,path,filesep,'Summary',sep,simtimeid,sep,'Powers_Year_FlexSep',sep,act_hh,'.mat']);
				Power = Power_InFlex;
				clear Power_InFlex Power_Flex Dev_4Flex_Output
		end
		if isempty(time_idx_new)
			time_idx_new = workaround_shift_timeidx(size(Power,1),timebase);
		end
		Power = Power(time_idx_new,:);
		
		num_hh = Model.Households{strcmp(Model.Households(:,1),act_hh),5};
		for c=1:num_runs
			for d=1:num_hh
				Energy_information{1,end+1} = path;  %#ok<AGROW>
				Energy_information{2,end} = act_hh;
				Energy_information{3,end} = c;
				Energy_information{4,end} = d;
				energy = sum(sum(Power(logical(ontime),((c-1)*num_hh+d-1)*3+(1:3))))*timebase/(1000*60*60);
				Energy_information{5,end} = energy;
				Energy_values(end+1) = energy; %#ok<AGROW>
			end
		end
	end
end
 [Energy_values,IX] = sort(Energy_values);
 Energy_information = Energy_information(:,IX);

