% lowPassExpFilter - Emulates the CommonLib low pass filter functionality
% 
% sigOut = lowPassExpFilter(sigIn,tau,Ts)
% sigOut = lowPassExpFilter(sigIn,tau,Ts,init_time)
% sigOut = lowPassExpFitler(sigIn,tau,Ts,init_time,reset,resetval)
%
% Function to emulate the Simulink function CalMean_ExpDecay in CommonLib.
% It low pass filters the signal 'sigIn' using a first order filter with
% time constant given by 'tau'.
%
% Optional functionality is included in relation to initializing the filter
% and resetting the filter.
%
% Arguments:
% sigIn:     Time domain signal to filter
% tau:       Time constant for filtering (s)
% Ts:        Sampling time of 'sigIn'
% init_time: Specifies that the average value for the first 'init_time'
%            seconds is used for initializing the filter.
%            Optional: If not specified the first sample is used.
% reset:     A boolean vector with same length as 'sigIn' specifying for
%            each sample if the filter is to be reset.
%            Optional: If not specified the signal will not be reset.
% resetval:  A vector with same length as 'reset' and 'sigIn' specifying
%            the value to reset to when 'reset == true'
% 

function y = lowPassExpFilter(x,tau,dt,init_time,reset,resetval)

A = exp(-dt/tau);
B = 1.0 - A;

if nargin > 3
    y_init = A*mean(x(1:init_time/dt));  % found empirically
else
    y_init = A*x(1);
end

y = filter(B, [1,-A], x , y_init);

if ~exist('reset','var')
    return;
end

% update filter output at reset points
if length(resetval) == 1
    resetval = resetval * ones(size(reset));
end
y(reset > 0.5) = resetval(reset > 0.5);

% find reset points for filter
if length(resetval) == 1
    resetval = resetval * ones(size(reset));
end
filterstop  = find(diff(reset) > 0);
filterstart = find(diff(reset) < 0)+1;
if isempty(filterstart), return; end
if ~isempty(filterstop) && filterstop(1) < filterstart(1)
    filterstop = filterstop(2:end);
end
if reset(end) < 0.5
    filterstop(end+1) = length(reset);
end

% run filter for each filter section
for I=1:length(filterstart)
    y(filterstart(I):filterstop(I)) = ...
        filter(B,[1,-A],x(filterstart(I):filterstop(I)),...
        A*resetval(filterstart(end)));
end

end
