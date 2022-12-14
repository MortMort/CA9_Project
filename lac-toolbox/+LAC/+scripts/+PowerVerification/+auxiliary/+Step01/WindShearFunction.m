function [data, idx] = WindShearFunction(data,idx)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODFY - 09/05/2019
% Code extracted from Step01_PrepMeasuredPrep...m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 
% - data: a struct variable which has been obtain by loading the
%          information from the database through the sript dataload
% - idx: a struct variable that contains the name of the sensors needed for
%           the analysis and the corresponding number on the sensor file of 
%           the measurement among other information
% Output:
% The function returns the updated inputs with the computed wind shear
% computed based pon IEC standards
% - data
% - idx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if ~isfield(idx,'wsh') || length(idx.wsh)== 1
        sprintf('Need at least 2 sensors to calculate wind shear. Set to 0.2')
        WindShear = ones(size(data.dat1.mean)).*0.2;
    elseif length(idx.wsh)== 2
        WindShear = log(data.dat1.mean(:,idx.wsh(1)) ./ data.dat1.mean(:,idx.wsh(2))) / log(idx.wshHeight(1) / idx.wshHeight(2));
    elseif length(idx.wsh)> 2
        Vexp12 = log(data.dat1.mean(:,idx.wsh(1)) ./ data.dat1.mean(:,idx.wsh(2))) / log(idx.wshHeight(1) / idx.wshHeight(2));
        Vexp23 = log(data.dat1.mean(:,idx.wsh(2)) ./ data.dat1.mean(:,idx.wsh(3))) / log(idx.wshHeight(2) / idx.wshHeight(3));
        Vexp13 = log(data.dat1.mean(:,idx.wsh(1)) ./ data.dat1.mean(:,idx.wsh(3))) / log(idx.wshHeight(1) / idx.wshHeight(3));
        WindShear = (Vexp12 + Vexp23 + Vexp13) / 3; 
   end
    
    data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1} = strcat(num2str(max(size(data.dat1.sensorname))),' Wind Shear');
    data.dat1.sensorno{max(size(data.dat1.sensorno))+1,1} = num2str(max(size(data.dat1.sensorname)));  
    data.dat1.unit{max(size(data.dat1.unit))+1,1} = '-';
    data.dat1.mean(:,max(size(data.dat1.sensorname))) = WindShear;
    idx.WShear = max(size(data.dat1.sensorname));
end