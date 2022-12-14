function [data, idx] = AirDensityNorm(data, idx)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODFY - 09/05/2019
% Code extracted from Step01_PrepMeasuredPrep...m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 
% - data: a struct variable which has been obtain by loading the
%          information from the database through the script dataload
% - idx: a struct variable that contains the name of the sensors needed for
%           the analysis and the corresponding number on the sensor file of 
%           the measurement among other information
% Output:
% The function returns the updated inputs with the reference air density 
% computed based pon IEC standards
% - data
% - idx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Temp = data.dat1.mean(:,idx.temp)+273.15;
R0   = 287.05;
Rw   = 461.5;
B10  = data.dat1.mean(:,idx.pres)*100;
Pw   = 0.0000205.*exp(0.0631846.*Temp);

if isfield(idx,'hum') && idx.hum > 0 % If humidity is logged use it, else set it to 50 %
    Theta = data.dat1.mean(:,idx.hum);
else 
    Theta = 50;
end % End find hum

% Reference air density
rho_IEC = 1./Temp.*(B10./R0-(Theta./100.*Pw.*((1./R0)-(1./Rw))));
rho_IEC(rho_IEC <1.15 | rho_IEC >1.35) = 1.225;

%data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1} = strcat(num2str(max(size(data.dat1.sensorname))),' AirDensity_calc');
data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1} = strcat(num2str(max(size(data.dat1.sensorname))+1),' AirDensity_calc'); %SEHIK 19/08/2021 numbering same as for TI before

data.dat1.sensorno{max(size(data.dat1.sensorno))+1,1} = num2str(max(size(data.dat1.sensorname)));  
data.dat1.unit{max(size(data.dat1.unit))+1,1} = 'kg/m^3'; 
data.dat1.mean(:,max(size(data.dat1.sensorname))) = rho_IEC;
idx.rho = max(size(data.dat1.sensorname));

end