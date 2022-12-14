% FFTpeak - Calculates a relative FFT peak level
%
% out = fftpeak(signal,Ts,minF,maxF,minpeak,NFFT)
%
% Calculates a frequency response (FFT) of the input signal and for each
% peak value in the frequency response between minF and maxF it calculates
% the relative peak level by dividing the peak level with the lower level
% between minF and the peak frequency.
% 
% Arguments:
% out: a [2 X] matrix where
% - first  row contains the max relative peak level
% - second row contains frequencies of the identified peaks
%
% signal:    The signal to analyse
% Ts:        Sampling time of 'signal' (s)
% minF,maxF: The frequency interval to analyse (Hz)
% minpeak:   The minimum peak level for adding result to out. If negative,
%            only return one value (largest peak)
% NFFT:      Number of points in FFT

function out = FFTpeak(dat,Ts,minF,maxF,minpeak,NFFT)

if ~exist('NFFT','var') || isempty(NFFT) || strcmp(NFFT,'auto')
    NFFT = round(1024*(0.1/Ts));
end
time = Ts * (0:length(dat)-1);
[f,datFFT]=fftcalc(time,dat,NFFT);


% find indices for local peaks: increase followed by decrease
ix = 1+find((f(2:end-1) >= minF) & (f(2:end-1) <= maxF) ...
    & (datFFT(2:end-1) > datFFT(1:end-2)) & (datFFT(2:end-1) > datFFT(3:end)));

ratio = zeros(size(ix));
for I=1:length(ix)
    ratio(I) = datFFT(ix(I)) / max(1,min(datFFT(1:ix(I))));
end
fpeak = f(ix);
if minpeak < 0
    out = [ratio(ratio == max(ratio));fpeak(ratio == max(ratio))];
else
    out = [ratio(ratio > minpeak);fpeak(ratio > minpeak)];
end

if isempty(out)
    out = [1;0];
end