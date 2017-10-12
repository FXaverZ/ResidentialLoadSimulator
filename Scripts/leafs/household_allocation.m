function [allocation, found] = household_allocation (ye_to_use, xls_input_id, ye_info, ye_vals, eps_lst, titlestr, estr)
%HOUSEHOLD_ALLOCATION Summary of this function goes here
%   Detailed explanation goes here

allocation = cell(8,numel(ye_to_use));
found = zeros(1,numel(ye_to_use));
idx_lst = 1:numel(ye_to_use);

for i=1:size(eps_lst,1)
	if i == 1
		fprintf(['\tBeginning with eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),' in ',num2str(eps_lst(i,2)),' kWh steps: ']);
	else
		fprintf(['\tTrying with eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),' in ',num2str(eps_lst(i,2)),' kWh steps: ']);
	end
	for eps = eps_lst(i,1):eps_lst(i,2):eps_lst(i,3)
		ye_tous = ye_to_use(~logical(found));
		id_allo = idx_lst(~logical(found))';
		for a = 1:numel(ye_tous)
			act_ye = ye_tous(a);
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
				% Delete the found profile out of the pool:
				ye_info(:,f(1)) = [];
				ye_vals(f(1)) = [];
			end
		end
	end
	if i == 1
		figure;
	end
	f = sum(found);
	fprintf([num2str(f),' profiles of ',num2str(numel(ye_to_use)),' allocated.\n']);
	test = cell2mat(allocation(8,:));
	test = sort(test);
	subplot(ceil(size(eps_lst,1)/3),3,i);
	plot(test);
	title(['eps from ',num2str(eps_lst(i,1)),' to ',num2str(eps_lst(i,3)),...
		' in ',num2str(eps_lst(i,2)),' kWh steps'],'FontWeight','normal','FontSize',9);
	ylabel('Error [%]');
	xlabel([num2str(f),' of ',num2str(numel(ye_to_use)),' profiles allocated']);
end
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

