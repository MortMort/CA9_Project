%BSFILT   Digital butterworth bandstop filter design
%
%   BSFILT calculates coefficients, separated into two second order filters
%          matching the VMP 3500/ VMP 5000 implementation 
%
%   Syntax:  [num1,den1,num2,den2,num,den] = bsfilt(flo,fhi,Ts,kstat,opt)   
%
%   Inputs:  flo      [Hz]  Lower 3dB frequency
%            fhi      [Hz]  Higher 3dB frequency
%            Ts       [s]   Sampling time
%            kstat    [-]   Stationary filter gain (default = 1)
%            opt      [-]   Option: 1 = show bode plot
%
%   Outputs: num1     [-]   Numerator of filter 1
%            den1     [-]   Denumerator of filter 1
%            num2     [-]   Numerator of filter 2
%            den2     [-]   Denumerator of filter 2
%            num      [-]   Numerator of total filter
%            den      [-]   Denumerator of total filter
%
%   Example: flo = 1.5; fhi = 3.3; Ts = 0.1; kstat = 0.9302; 
%            [num1,den1,num2,den2] = bsfilt(flo,fhi,Ts,kstat);
%

% Version history – Responsible THK
% V0 - 01-11-1999 – THK


function [num1,den1,num2,den2,num,den] = bsfilt(flo,fhi,Ts,kstat,opt)

if nargin < 3, error('too few input arguments'), end
if nargin < 4, kstat = 1; end
if nargin < 5, opt = 0; end

[num,den] = butter(2,[flo fhi]*2*Ts,'stop');
bwfilt = kstat * tf(num,den,Ts);

[z,p,k] = zpkdata(bwfilt);

num1 = sqrt(k) * poly(z{1}(1:2)); 
num2 = sqrt(k) * poly(z{1}(3:4)); 
den1 = poly(p{1}(1:2));
den2 = poly(p{1}(3:4));

%check

num1 = round(1e4*num1)/1e4;
num2 = round(1e4*num2)/1e4;
den1 = round(1e4*den1)/1e4;
den2 = round(1e4*den2)/1e4;

if opt == 1
   filt1 = tf(num1,den1,Ts);
   filt2 = tf(num2,den2,Ts);
   filt = filt1*filt2;
   [numc,denc] = tfdata(filt);
   dbodelin(numc{1},denc{1},Ts);
end


