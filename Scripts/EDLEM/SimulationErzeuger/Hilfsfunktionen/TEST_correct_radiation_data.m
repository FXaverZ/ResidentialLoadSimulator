% Test with normal plain curve:
Teststr = 'No correction needed: ';
x=0:0.1:2*pi;
rad_dat = sin(x)';
% figure;plot(rad_dat);
rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Test failed!\n\n']);
	return;
else
	fprintf([Teststr,'Test passed!\n\n']);
end

% Test with one spike in plain curve 
Teststr = 'One correction needed: ';
x=0:0.1:pi;
rad_dat = sin(x)';
rad_dat(10) = rad_dat(10)*0.3;
% figure;plot(rad_dat);

rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Test passed!\n\n']);
	figure;plot(rad_dat,'LineWidth',2);hold('on');plot(rad_dat_corr,'r');hold('off');
else
	fprintf([Teststr,'Test failed!\n\n']);
	return;
end

% Test with three independent spikes in plain curve 
Teststr = 'Three corrections needed: ';
x=0:0.1:2*pi;
rad_dat = abs(sin(x)');
idx_spike = [10,20,43];
rad_dat(idx_spike) = rad_dat(idx_spike)*0.3;
% figure;plot(rad_dat);

rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Check Diagramm!\n\n']);
	figure;plot(rad_dat,'LineWidth',2);hold('on');plot(rad_dat_corr,'r');hold('off');
else
	fprintf([Teststr,'Test failed!\n\n']);
	return;
end

% Test with three independent spikes in plain curve, curve has also negative values 
Teststr = 'One correction in negative curve part needed: ';
x=0:0.1:2*pi;
rad_dat = sin(x)';
idx_spike = 43;
rad_dat(idx_spike) = rad_dat(idx_spike)*0.3;
% figure;plot(rad_dat);

rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Check Diagramm!\n\n']);
	figure;plot(rad_dat,'LineWidth',2);hold('on');plot(rad_dat_corr,'r');hold('off');
else
	fprintf([Teststr,'Test failed!\n\n']);
	return;
end

% Test with three independent spikes in plain curve, curve has also negative values 
Teststr = 'Three corrections needed, positive and negative: ';
x=0:0.1:2*pi;
rad_dat = sin(x)';
idx_spike = [10,20,43];
rad_dat(idx_spike) = rad_dat(idx_spike)*0.3;
% figure;plot(rad_dat);

rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Check Diagramm!\n\n']);
	figure;plot(rad_dat,'LineWidth',2);hold('on');plot(rad_dat_corr,'r');hold('off');
else
	fprintf([Teststr,'Test failed!\n\n']);
	return;
end

% Test with spikes, one longer than one timepoint in plain curve, curve has also negative values 
Teststr = 'Three corrections needed, positive and negative with long spike: ';
x=0:0.1:2*pi;
rad_dat = sin(x)';
idx_spike = [10,11,12,20,43];
rad_dat(idx_spike) = rad_dat(idx_spike)*0.3;
% figure;plot(rad_dat);

rad_dat_corr = correct_radiation_data(rad_dat);
if ~isempty(rad_dat_corr)
	fprintf([Teststr,'Check Diagramm!\n\n']);
	figure;plot(rad_dat,'LineWidth',2);hold('on');plot(rad_dat_corr,'r');hold('off');
else
	fprintf([Teststr,'Test failed!\n\n']);
	return;
end