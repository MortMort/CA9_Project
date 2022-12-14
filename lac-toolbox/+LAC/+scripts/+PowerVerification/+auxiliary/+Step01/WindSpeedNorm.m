function [data, idx] = WindSpeedNorm(data, idx, RhoRef)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author MODFY - 15/05/2019
% Code based on Step01_PrepMeasuredPrep...m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 
% - data: a struct variable which has been obtain by loading the
%          information from the database through the sript dataload
% - idx: a struct variable that contains the name of the sensors needed for
%           the analysis and the corresponding number on the sensor file of 
%           the measurement among other information
% - RhoRef: reference air density
% 
% Output:
% The function returns the updated inputs with the reference normalised
% wind speed computed based pon IEC standards
% with Vnorm = V*(rho_norm/RhoRef)^(1/3)
% - data
% - idx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1} = strcat(num2str(max(size(data.dat1.sensorname))),' WSP norm');
data.dat1.sensorno{max(size(data.dat1.sensorno))+1,1} = num2str(max(size(data.dat1.sensorname)));  
data.dat1.unit{max(size(data.dat1.unit))+1,1} = 'm/s'; 
data.dat1.mean(:,max(size(data.dat1.sensorname))) = data.dat1.mean(:,idx.WSP).*(data.dat1.mean(:,idx.rho)/RhoRef).^(1/3);
idx.WSPnorm = max(size(data.dat1.sensorname));

end