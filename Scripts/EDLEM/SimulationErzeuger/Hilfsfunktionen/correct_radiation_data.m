function rad_data_corr = correct_radiation_data(rad_data)
%CORRECT_RADIATION_DATA    Find inconstancy in curves and try to correct them

% empty result
rad_data_corr = [];

first_order_diff = abs(rad_data(1:end-1))-abs(rad_data(2:end));
first_order_diff = sign(first_order_diff);
% figure;plot(first_order_diff);
curve_direction_change = first_order_diff(1:end-1)-first_order_diff(2:end);
% figure;plot(curve_direction_change);
curve_direction_up = curve_direction_change > 1;
% figure;plot(curve_direction_up);
curve_direction_down = curve_direction_change < -1;
% figure;plot(curve_direction_down);
immedeate_direction_changes = ([0;curve_direction_down(1:end-1)] & curve_direction_up) |...
	([curve_direction_down(2:end);0] & curve_direction_up);
immedeate_direction_changes = [0;immedeate_direction_changes;0];
% x=1:1:numel(immedeate_direction_changes);
% figure;plotyy(x, rad_data, x, immedeate_direction_changes,'plot','stem');
idx = find(immedeate_direction_changes==1);
if ~isempty(idx)
	rad_data_corr = rad_data;
	for m=1:numel(idx)
		rad_data_corr(idx(m)) = (rad_data_corr(idx(m)-1)+rad_data_corr(idx(m)+1))/2;
	end
% 	figure;plot(rad_data,'LineWidth',2);hold;plot(rad_data_corr,'r');hold off;
end

end

