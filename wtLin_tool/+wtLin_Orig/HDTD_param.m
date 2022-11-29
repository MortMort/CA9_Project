function [Ki,wcu,Hdtd]=HDTD_param(fDT,GDT_DTD_dB,eta_f,eta_fBW,eta_BW)
%
% syntax:
%   [Ki,wcu,Hdtd]=HDTD_param(fDT,GDT_DTD_dB,eta_f,eta_fBW,eta_BW);
%
% The controller has the transferfunction
%                     2*wc*s    
%  H_DTD(s)= Ki*--------------------
%               s^2 + 2*wc*s + wDT^2
% Ie. no proportional part! 
%   Ki  : integral gain
%   wc  : cut off frequency (sharpness/damping)
%   wDT : Resonant frequency
%   tau : time constant for phase boost
%
% The input are
%   fDT         : resonant frequency in Hz
%   GDT_DTD_dB  : Magnitude of controller transfer function at fDT in dB
%   eta_f       : Uncertainty of fDT. Used to "lift" the amplitude
%                 characteristic.
%   eta_fBW     : Coefficient for the frequency where the gain facor eta_BW 
%                 is specified. eta_fBW is relative to wDT.
%   eta_BW      : Magnitude of controller transfer function at fDT/2 
%                 relative to 10^(GDT_DTD_dB/20)
%
% Last edited   14-08-2006
% By            GEKAN


wdt=2*pi*fDT;
Xdt=10^(GDT_DTD_dB/20);

wcu = ((1-(eta_fBW*eta_fBW))/(2*eta_fBW))*((eta_BW)/(sqrt( 1 - (eta_BW*eta_BW)))) * wdt;
Ki  = Xdt*sqrt(1+  (((1-((1-eta_f)^2) )/(1-eta_f))^2)*((eta_fBW/eta_BW)^2)*( (1-(eta_BW*eta_BW) )/((1-(eta_fBW*eta_fBW))^2) )  );
NDTD=(2*wcu*Ki)*[1 0];
DDTD=[1 (2*wcu) (wdt^2)];
Hdtd=tf(NDTD,DDTD);