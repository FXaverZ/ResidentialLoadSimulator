function data_output = rearrange_data (data_phase, options, system)

time_res = system.time_resolutions{options.Time_Resolution,2};
data_points = round((size(data_phase,1)-1)/time_res);

data_mean = reshape(data_phase(1:end-1,:),time_res,size(data_phase,2),[]);
data_min = squeeze(min(data_mean))';
data_max = squeeze(max(data_mean))';
data_mean = squeeze(mean(data_mean))';
data_sample = data_phase(1:time_res:end-1,:);

data_output = [data_sample, data_mean, data_min, data_max];
