function [data, idx] = TICalc(data, idx)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODFY - 15/05/2019
% Code extracted from step01_PrepMeasuredPrep...m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 
% - data: a struct variable which has been obtain by loading the
%          information from the database through the sript dataload
% - idx: a struct variable that contains the name of the sensors needed for
%           the analysis and the corresponding number on the sensor file of 
%           the measurement among other information
% 
% Output:
% The function returns the updated inputs with the Turbulence Intensity
% - data
% - idx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

turb = data.dat1.std(:, idx.WSP) ./ data.dat1.mean(:, idx.WSP);
data.dat1.sensorname{max(size(data.dat1.sensorname))+1, 1} = strcat(num2str(max(size(data.dat1.sensorname)+1)), ' Turb_calc');
data.dat1.sensorno{max(size(data.dat1.sensorno))+1, 1} = num2str(max(size(data.dat1.sensorname)));  
data.dat1.unit{max(size(data.dat1.unit))+1, 1} = '-';
data.dat1.mean(:, max(size(data.dat1.sensorname))) = turb(:, 1);
idx.turb = max(size(data.dat1.sensorname));

end