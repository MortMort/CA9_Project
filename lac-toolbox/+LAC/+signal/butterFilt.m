% butterFilt - Filter signal using Butterworth filter
%
% SignalOut = butterFilt(order,Freq,SignalIn,Ts,type)
% SignalOut = butterFilt(order,Freq,SignalIn,Ts)
% 
% Filters the input signal 'SignalIn' using a Butterworth filter. The
% filter coefficients are generated using the 'butter' command.
%
% The filter is initialized by filtering the Signal from end to start
%
% Arguments:
% order:    Filter order
% Freq:     Filter cutoff frequency (Hz)
% SignalIn: The signal to be filtered
% Ts:       Sampling time of SignalIn
% type:     Type of filter ('high','low','stop')
%           Optional argument with default value 'low'
% 
% See also butter

function out = butterFilt(order,Freq,Signal,Ts,type)

if exist('type','var')
    [filtB,filtA] = butter(order,2*Ts*Freq,type);
else
    [filtB,filtA] = butter(order,2*Ts*Freq);
end
Signal2 = [Signal(end:-1:1); Signal(1:end)];

out = filter(filtB,filtA,Signal2);
out = out(end-length(Signal)+1:end);