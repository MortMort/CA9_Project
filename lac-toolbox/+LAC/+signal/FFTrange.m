% FFTrange - Calculates the max frequency content at specified freq ranges
%
% peak = FFTrange(signal,Ts,freqRange,NFFT)
% 
% Calculates the maximum frequency content of 'signal' in frequency bins
% specified by 'freqRange'. It outputs a vector of peak levels with one
% value for each frequency bin.
% 
% Arguments:
% signal:    Signal to process
% Ts:        Sampling time of 'signal'
% freqRange: Vector of edges for the frequency ranges to analyse. 
%            e.g. [2 3 5] means that two frequency ranges will be analysed.
%            One from 2-3 Hz and one from 3-5 Hz.
% NFFT:      Number of points in FFT (optional)
%            Default value scales with sampling time as in VDAT.
%
% See also fftcalc

function res = FFTrange(dat,Ts,frange,NFFT)
    
if ~exist('NFFT','var') || isempty(NFFT) || strcmp(NFFT,'auto')
    NFFT = round(1024*(0.1/Ts));
end
time = Ts * (0:length(dat)-1);

[f,datFFT]=fftcalc(time,dat,NFFT); 

for I=1:length(frange)-1
    ix1 = max(1,find(f>frange(I),1,'first')-1);
    ix2 = min(length(datFFT),find(f<frange(I+1),1,'last')+1);
    if isempty(ix1), ix1 = 1; end
    if isempty(ix2), ix2 = length(datFFT); end
    res(I) = max(abs(datFFT(ix1:ix2)));
end