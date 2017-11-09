function [time_idx_new, time,  Time] = workaround_shift_timeidx(num_timepoints, timebase, varargin)
%WORKAROUND_SHIFT_TIMEIDX Summary of this function goes here
%   Detailed explanation goes here
%--------------------------------------------------------------------------
% WORKAROUND
%--------------------------------------------------------------------------
if nargin == 2
	Time.Series_Date_Start = datenum('01.01.2014','dd.mm.yyyy');
	Time.Series_Date_End = datenum('31.12.2014','dd.mm.yyyy');
end

% Shift timeperiod from simulated year 2017 to year 2014
Time.Series_Date_Start = datenum('01.01.2014','dd.mm.yyyy');
Time.Series_Date_End = datenum('31.12.2014','dd.mm.yyyy');
time = Time.Series_Date_Start:timebase/(24*60*60):Time.Series_Date_End+1;
time = time(1:end-1)';

time_idx = (1:num_timepoints)';
time_idx_new = time_idx((3*1440)+1:end);
time_idx_new = [time_idx_new;time_idx(1441:3*1440)];
% now use time_idx_new to rearange simulated load profiles to the new
% simulated year!
%--------------------------------------------------------------------------
% END WORKAROUND
%--------------------------------------------------------------------------
end

