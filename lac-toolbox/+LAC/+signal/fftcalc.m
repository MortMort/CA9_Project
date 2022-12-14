function [f,FFTY,fres,TsAvg,NoOfFFTs,NFFT]=fftcalc(t,y,NFFT); 
%FFTCALC
%  Internal VDAT function for performing frequency analysis (FFT)
%
%  Syntax:  [f,FFTY,fres,TsAvg,NoOfFFTs]=fftcalc(t,y,NFFT);
%
%  Inputs:	
%
%         t     : time vector 
%
%         y     : data vector
%
%         NFFT  : The FFT carried out is a NFFT-point FFT 
%
%  Outputs:
%
%         f     : frequency vector
%
%         FFTY  : FFT values vector
%
%         fres  : frequency resolution
%           
%         TsAvg : sample reate calculated from the time vector
% 
%         NoOfFFTs : Number of FFT's which are calculated and averaged into FFTY
%
%  Example: 
%
%  See also:
%
%   Vestas Wind Systems A/S
%   PBC	15th of January 2002
%

% IMPROVEMENTS TO BE MADE IN THE FUTURE
% * 020206 Check whether the frequency vector is generated correctly.
% * 020708 make error check/input format check on the y-data which must be a 1xn vector where n is the number of samples

Ts=(t(end)-t(1))/(length(t)-1); % average sample time
TsAvg=Ts;
Fs=1/Ts;
NoOfFFTs=ceil(length(y)/NFFT); % no. of FFT's to be made

if size(y,1)>size(y,2) % assure the vector format is correct
    y=y';
end
    % first do FFT's where all samples are present
if NoOfFFTs > 1
    for n=1:NoOfFFTs-1
        %PartFFTY(n,:)= (abs(fft( y(1+(n-1)*NFFT:n*NFFT), NFFT ))/NFFT)^2; % NEW
        PartFFTY(n,:)= abs(fft( y(1+(n-1)*NFFT:n*NFFT), NFFT ))/NFFT;
        %PartPSDY(n,:)= psd(y(1+(n-1)*NFFT:n*NFFT), NFFT )/NFFT;
    end
end

NoSamplesLastFFT=length(y)-(NoOfFFTs-1)*NFFT;     % no of points in last FFT (less than or equal to NFFT)

% make sure the last FFT is made on a signal with mean-value of 0
LastMeanVal=mean(y(1+(NoOfFFTs-1)*NFFT:end));
PartFFTY(NoOfFFTs,:)= abs(fft( y(1+(NoOfFFTs-1)*NFFT:end) - LastMeanVal , NFFT )) / NoSamplesLastFFT; 
PartFFTY(NoOfFFTs,1)=abs(LastMeanVal);  % amplitude spectum can only contain positive values

% weigthing of the FFT results
if NoOfFFTs > 1
    FFTY=2.0*(NFFT*(NoOfFFTs-1)/length(y)* mean(PartFFTY(1:NoOfFFTs-1,:),1) + ...
        NoSamplesLastFFT/length(y) * PartFFTY(NoOfFFTs,:) );   
else
    FFTY=2.0*PartFFTY;
end
%FFTY(1)=FFTY(1)/2; 
%PBC140129 the above line is replaced with the below in order
%to use autoscale better on the FFT plots (i.e. the first FFT value (0Hz/
%DC) value is now always set to 0 
FFTY(1)=0;

fmin=Fs/(NFFT-1);
f=0:fmin:(NFFT-1)*fmin;
% throw away everything above fs/2
I=find(f<Fs/2); 
FFTY=FFTY(I);
f=f(I);

fres=fmin;

