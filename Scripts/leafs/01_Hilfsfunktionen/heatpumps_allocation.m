function [allocation, found] = heatpumps_allocation (ye_to_use, xls_input_id, ye_info, ye_vals, eps_lst, titlestr, estr, graphics_output)
%HOUSEHOLD_ALLOCATION Summary of this function goes here
%   Detailed explanation goes here

deal_with_zeros = 1;

allocation = cell(9,numel(ye_to_use));
found = zeros(numel(ye_to_use),1);
idx_lst = 1:numel(ye_to_use);

for i=1:size(eps_lst,1)
	reduction_factor = 1;
	if i == 1 && graphics_output
		fprintf(['\tBeginning with eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),' in ',num2str(eps_lst(i,2)),' kWh steps: ']);
	else
		if graphics_output
			fprintf(['\tTrying with eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),' in ',num2str(eps_lst(i,2)),' kWh steps: ']);
		end
	end
	for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
		[found, allocation, ye_vals, ye_info] = ...
			search_for_match_simple (eps, ye_to_use, idx_lst, xls_input_id, ...
			found, allocation, ye_vals, ye_info, reduction_factor, deal_with_zeros);
	end
	if i == 1 && graphics_output
		figure;
	end
	f = sum(found);
	if graphics_output
		fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
	end
	
% 	% Simple combination:
% 	if graphics_output
% 	fprintf('\t\tTrying with combinded profiles: ');
% 	end
% 	for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 		[found, allocation, ye_vals, ye_info] = ...
% 			search_for_match_combination_simple (eps, ye_to_use, idx_lst, xls_input_id,...
% 			found, allocation, ye_vals, ye_info, reduction_factor);
% 	end
% 	f = sum(found);
% 	if graphics_output
% 		fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 	end
% 	
% 	% Extended combination to cover high engery consumption:
% 	if graphics_output
% 		fprintf('\t\tTrying with extended combinded profiles: ');
% 	end
% 	for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 		[found, allocation, ye_vals, ye_info] = ...
% 			search_for_match_combination_extended (eps, ye_to_use, idx_lst, xls_input_id,...
% 			found, allocation, ye_vals, ye_info, reduction_factor);
% 	end
% 	f = sum(found);
% 	if graphics_output
% 		fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 	end
	
	% Treat values, smaller than the simulated ones:
	for lst_reductions = eps_lst(i,4):eps_lst(i,5):eps_lst(i,6)
		reduction_factor = lst_reductions/100;
		ye_vals_r = ye_vals * reduction_factor;
		if graphics_output
			fprintf(['\t\t\tTrying with ',num2str(lst_reductions),'%% reduced profiles: ']);
		end
		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
			[found, allocation, ye_vals_r, ye_info] = ...
				search_for_match_simple (eps, ye_to_use, idx_lst, xls_input_id, ...
				found, allocation, ye_vals_r, ye_info, reduction_factor, deal_with_zeros);
		end
		f = sum(found);
		if graphics_output
			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
		end
% 		% Simple combination:
% 		if graphics_output
% 			fprintf('\t\t\tTrying with combinded profiles: ');
% 		end
% 		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 			[found, allocation, ye_vals_r, ye_info] = ...
% 				search_for_match_combination_simple (eps, ye_to_use, idx_lst, xls_input_id,...
% 				found, allocation, ye_vals_r, ye_info, reduction_factor);
% 		end
% 		f = sum(found);
% 		if graphics_output
% 			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 		end
% 		
% 		% Extended combination to cover high engery consumption:
% 		if graphics_output
% 			fprintf('\t\t\tTrying with extended combinded profiles: ');
% 		end
% 		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 			[found, allocation, ye_vals_r, ye_info] = ...
% 				search_for_match_combination_extended (eps, ye_to_use, idx_lst, xls_input_id,...
% 				found, allocation, ye_vals_r, ye_info, reduction_factor);
% 		end
% 		f = sum(found);
% 		if graphics_output
% 			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 		end
		
		ye_vals = ye_vals_r / reduction_factor;

	end
	% Treat values, smaller than the simulated ones:
	if size(eps_lst,2) == 9
	for lst_rize = eps_lst(i,7):eps_lst(i,8):eps_lst(i,9)
		rize_factor = lst_rize/100;
		ye_vals_r = ye_vals * rize_factor;
		if graphics_output
			fprintf(['\t\t\tTrying with ',num2str(lst_rize),'%% rizen profiles: ']);
		end
		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
			[found, allocation, ye_vals_r, ye_info] = ...
				search_for_match_simple (eps, ye_to_use, idx_lst, xls_input_id, ...
				found, allocation, ye_vals_r, ye_info, rize_factor, deal_with_zeros);
		end
		f = sum(found);
		if graphics_output
			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
		end
% 		% Simple combination:
% 		if graphics_output
% 			fprintf('\t\t\tTrying with combinded profiles: ');
% 		end
% 		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 			[found, allocation, ye_vals_r, ye_info] = ...
% 				search_for_match_combination_simple (eps, ye_to_use, idx_lst, xls_input_id,...
% 				found, allocation, ye_vals_r, ye_info, rize_factor);
% 		end
% 		f = sum(found);
% 		if graphics_output
% 			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 		end
% 		
% 		% Extended combination to cover high engery consumption:
% 		if graphics_output
% 			fprintf('\t\t\tTrying with extended combinded profiles: ');
% 		end
% 		for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
% 			[found, allocation, ye_vals_r, ye_info] = ...
% 				search_for_match_combination_extended (eps, ye_to_use, idx_lst, xls_input_id,...
% 				found, allocation, ye_vals_r, ye_info, rize_factor);
% 		end
% 		f = sum(found);
% 		if graphics_output
% 			fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
% 		end
		
		ye_vals = ye_vals_r / rize_factor;

	end
	end
	if graphics_output
		test = cell2mat(allocation(8,:));
		test = sort(test);
		
		subplot(ceil(size(eps_lst,1)/3),3,i);
		plot(test);
		title(['Combined with eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),...
			' in ',num2str(eps_lst(i,2)),' kWh steps'],'FontWeight','normal','FontSize',9);
		ylabel('Error [%]');
		xlabel([num2str(f),' of ',num2str(numel(ye_to_use)),' profiles allocated']);
	end
end
if graphics_output
	suptitle(titlestr);
	% Create textbox
	annotation(gcf,'textbox',...
		[0.00516666666666667 0.884368308351178 0.264476190476191 0.11134903640257],...
		'String',{estr},...
		'FitBoxToText','on','LineStyle','none');
	% pause(0.00001);
	% frame_h = get(handle(gcf),'JavaFrame');
	% set(frame_h,'Maximized',1);
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
end
end

function [found, allocation, ye_vals, ye_info] = ...
	search_for_match_simple (eps, ye_to_use, idx_lst, xls_input_id, found,...
	allocation, ye_vals, ye_info, reduction_factor, deal_with_zeros)
ye_tous = ye_to_use(~logical(found));
id_allo = idx_lst(~logical(found))';
for a = 1:numel(ye_tous)
	act_ye = ye_tous(a);
	if deal_with_zeros && act_ye < eps
		found(id_allo(a)) = 1;
		allocation{1,id_allo(a)} = xls_input_id(id_allo(a));
		allocation{2,id_allo(a)} = 'None';
		allocation{3,id_allo(a)} = 'None';
		allocation{4,id_allo(a)} = 0;
		allocation{5,id_allo(a)} = 0;
		allocation{6,id_allo(a)} = 0;
		allocation{7,id_allo(a)} = act_ye;
		if act_ye == 0
			allocation{8,id_allo(a)} = 0;
		else
			allocation{8,id_allo(a)} = (0-act_ye)*100/act_ye;
		end
		allocation{9,id_allo(a)} = reduction_factor;
		continue;
	end
	f = find((ye_vals >= act_ye - eps) & (ye_vals <= act_ye + eps));
	if ~isempty(f)
		found(id_allo(a)) = 1;
		allocation{1,id_allo(a)} = xls_input_id(id_allo(a));
		allocation{2,id_allo(a)} = ye_info{1,f(1)};
		allocation{3,id_allo(a)} = ye_info{2,f(1)};
		allocation{4,id_allo(a)} = ye_info{3,f(1)};
		allocation{5,id_allo(a)} = ye_info{4,f(1)};
		allocation{6,id_allo(a)} = ye_vals(f(1));
		allocation{7,id_allo(a)} = act_ye;
		allocation{8,id_allo(a)} = (ye_vals(f(1))-act_ye)*100/act_ye;
		allocation{9,id_allo(a)} = reduction_factor;
		% Delete the found profile out of the pool:
		ye_info(:,f(1)) = [];
		ye_vals(f(1)) = [];
	end
end
end

% function [found, allocation, ye_vals, ye_info] = ...
% 	search_for_match_combination_simple (eps, ye_to_use, idx_lst, xls_input_id, found,...
% 	allocation, ye_vals, ye_info, reduction_factor)
% ye_tous = ye_to_use(~logical(found));
% id_allo = idx_lst(~logical(found))';
% for a = 1:numel(ye_tous)
% 	act_ye = ye_tous(a);
% 	ye_min_val = ye_vals(1);
% 	act_ye_srch = act_ye - ye_min_val;
% 	b = 1;
% 	while (ye_min_val < act_ye_srch) && b < numel(ye_vals) && ~found(id_allo(a))
% 		act_ye_srch = act_ye - ye_min_val;
% 		f = find((ye_vals >= act_ye_srch - eps) & (ye_vals <= act_ye_srch + eps));
% 		if ~isempty(f)
% 			found(id_allo(a)) = 1;
% 			allocation{1,id_allo(a)} = xls_input_id(id_allo(a));
% 			allocation{2,id_allo(a)} = {ye_info{1,f(1)},ye_info{1,b}};
% 			allocation{3,id_allo(a)} = {ye_info{2,f(1)},ye_info{2,b}};
% 			allocation{4,id_allo(a)} = {ye_info{3,f(1)},ye_info{3,b}};
% 			allocation{5,id_allo(a)} = {ye_info{4,f(1)},ye_info{4,b}};
% 			allocation{6,id_allo(a)} = ye_vals(f(1)) + ye_min_val;
% 			allocation{7,id_allo(a)} = act_ye;
% 			allocation{8,id_allo(a)} = ((ye_vals(f(1)) + ye_min_val)-act_ye)*100/act_ye;
% 			allocation{9,id_allo(a)} = reduction_factor;
% 			% Delete the found profile out of the pool:
% 			ye_info(:,f(1)) = [];
% 			ye_vals(f(1)) = [];
% 			ye_info(:,b) = [];
% 			ye_vals(b) = [];
% 			continue;
% 		end
% 		b = b + 1;
% 		ye_min_val = ye_vals(b);
% 	end
% end
% end
% 
% function [found, allocation, ye_vals, ye_info] = ...
% 	search_for_match_combination_extended (eps, ye_to_use, idx_lst, xls_input_id,...
% 	found, allocation, ye_vals, ye_info, reduction_factor)
% ye_tous = ye_to_use(~logical(found));
% id_allo = idx_lst(~logical(found))';
% for a = numel(ye_tous):-1:1
% 	act_ye = ye_tous(a);
% 	ye_comb = ye_vals(end);
% 	b = numel(ye_vals);
% 	bt_result = cell(9,0);
% 	bt_f_idxs = [];
% 	while (ye_comb < act_ye) && b > 1 && ~found(id_allo(a))
% 		bt_result{1,end+1} = xls_input_id(id_allo(a)); %#ok<AGROW>
% 		bt_result{2,end} = ye_info{1,b};
% 		bt_result{3,end} = ye_info{2,b};
% 		bt_result{4,end} = ye_info{3,b};
% 		bt_result{5,end} = ye_info{4,b};
% 		bt_result{6,end} = ye_comb;
% 		bt_result{7,end} = act_ye;
% 		bt_result{8,end} = (ye_comb-act_ye)*100/act_ye ;
% 		bt_result{9,end} = ye_info{5,b};
% 		% Mark the found profile, so it can be deleted later out of the pool:
% 		bt_f_idxs = [bt_f_idxs, b]; %#ok<AGROW>
% 		b = b - 1;
% 		ye_comb = ye_comb + ye_vals(b);
% 	end
% 	
% 	if ~isempty(bt_result)
% 		% Now search fo a suitable last household profile to be added to the previous
% 		% found ones, to realise a minimal deviation:
% 		ye_comb = bt_result{6,end};
% 		ye_vals_red = ye_vals;
% 		ye_vals_red(bt_f_idxs) = [];
% 		ye_min_val = ye_vals_red(1);
% 		act_ye_srch = act_ye - ye_comb - ye_min_val;
% 		b = 1;
% 		while (ye_min_val < act_ye_srch) && b < numel(ye_vals_red) && ~found(id_allo(a))
% 			act_ye_srch = act_ye - ye_comb - ye_min_val;
% 			f = find((ye_vals_red >= act_ye_srch - eps) & (ye_vals_red <= act_ye_srch + eps));
% 			if ~isempty(f)
% 				found(id_allo(a)) = 1;
% 				bt_result{1,end+1} = xls_input_id(id_allo(a)); %#ok<AGROW>
% 				bt_result{1,end+1} = xls_input_id(id_allo(a)); %#ok<AGROW>
% 				bt_result{2,end-1} = ye_info{1,f(1)};
% 				bt_result{2,end}   = ye_info{1,b};
% 				bt_result{3,end-1} = ye_info{2,f(1)};
% 				bt_result{3,end}   = ye_info{2,b};
% 				bt_result{4,end-1} = ye_info{3,f(1)};
% 				bt_result{4,end}   = ye_info{3,b};
% 				bt_result{5,end-1} = ye_info{4,f(1)};
% 				bt_result{5,end}   = ye_info{4,b};
% 				bt_result{6,end-1} = ye_comb + ye_info{5,f(1)} + ye_min_val;
% 				bt_result{6,end}   = bt_result{6,end-1};
% 				bt_result{7,end-1} = act_ye;
% 				bt_result{7,end}   = bt_result{7,end-1};
% 				bt_result{8,end-1} = ((ye_comb + ye_info{5,f(1)} + ye_min_val)-act_ye)*100/act_ye ;
% 				bt_result{8,end}   = bt_result{8,end-1};
% 				bt_result{9,end-1} = ye_info{5,f(1)};
% 				bt_result{9,end}   = bt_result{9,end-1};
% 				% Delete the found profile out of the pool:
% 				bt_f_idxs = [bt_f_idxs, f(1), b]; %#ok<AGROW>
% 				continue;
% 			end
% 			b = b + 1;
% 			ye_min_val = ye_vals_red(b);
% 		end
% 		
% 		%Save the allocation:
% 		if found(id_allo(a))
% 			allocation{1,id_allo(a)} = bt_result{1,1};
% 			allocation{2,id_allo(a)} = bt_result(2,:);
% 			allocation{3,id_allo(a)} = bt_result(3,:);
% 			allocation{4,id_allo(a)} = bt_result(4,:);
% 			allocation{5,id_allo(a)} = bt_result(5,:);
% 			allocation{6,id_allo(a)} = bt_result{6,end};
% 			allocation{7,id_allo(a)} = bt_result{7,end};
% 			allocation{8,id_allo(a)} = bt_result{8,end};
% 			allocation{9,id_allo(a)} = reduction_factor;
% 			% Delete the found profile out of the pool:
% 			ye_info(:,bt_f_idxs) = [];
% 			ye_vals(bt_f_idxs) = [];
% 		end
% 	end
% end
% end
