function [Fex datbootsort]=bootExProb(Pwsp,ndat,dat)
% Emprical distribution by bootstrapping.
%**********************************************************
% Emprical distribution by bootstrapping. SORSO @ Vestas 29-12-2009
%**********************************************************
%
% [Fex datbootsort]=bootExProb(Pwsp,ndat,dat)
%
% input:
% Pwsp = Probabilty of a Wind speed bin. read from frequency file
% ndat = number of extracted extreme value in each wind speed bin.
% dat  = extreme value matrix.
%
%
% Decription Build extreme values according to a Weibull Distribution by
% means of the boot strapping method. The exceedence probability
% is estimated by means of the median rank method.

Nbinend=10;                     % number of seeds in the last bin;
Ntot=Nbinend/Pwsp(end);         % Number of sim in population
Nbin=round(Ntot*Pwsp);
Ntotr=sum(Nbin);
datboot=zeros(Ntotr,1);
iplace=1;
nwsp=length(Pwsp);
for i=1:nwsp
    iboots=randi([1 ndat],1,Nbin(i));
    datboot(iplace:iplace+Nbin(i)-1)=dat(iboots,i);
    iplace=iplace+Nbin(i);
end
datbootsort=sort(datboot);
% exceedence probability by the median rank method
Fex=1-((1:Ntotr)-0.3)/(Ntotr+0.4); 
end