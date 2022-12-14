function [Xbin, SensorList] = CtComputation(Xbin, SensorList, WSPnorm_sens_no, dat_name, RhoRef, AreaSwept, HHeight, Tilt, MxH_sens_height)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author MODFY - 15/05/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Target: Power Performance Verification
%
% Aim: The function is computing the Power Coefficient
%      From IEC 61400-12
%         Ct = T/(0.5*rho*Area*V^2)
%         where T is the total thrust load at hub height within a bin
%         rho is the reference air density
%         Area is the swept area by the wt rotor
%         V is the wind speed normalised within a bin
% 
% Inputs: 
% - Xbin: a structure variable that contains the bin label based on a
%       parameter, the ws binning and the average data within a bin among
%       other information
% - SensorList: a struct variable that is output from Step02. It contains:
%               - SensorList.sens
%               - SensorList.sensorname 
%               - SensorList.VTS.sens
% - WSPnorm_sens_no: windspeed sensor number to calculate the Ct
% - dat_name: vector of char. It contains the extension name in which to
%       update Xbin
% - RhoRef: is the reference air density, is an external input from user
% - AreaSwept: is the swept area of the wind turbine rotor
% - HHight 
% - Tilt
% - MxH_sens_name
% - MxH_sens_height
% 
% Output:
% The function returns Xbin updated with the computed average values 
% within the ws bin in accordance to each Xbin bin. 
% Xbin.dat(i) is a double variable int of size (WSbin_length, number_of_sensor). 
% Therefore a row correspond to a bin j of WSbin and a column to the
% average value within the bin for the sensor k.
% The raw data also contains the Ct values (Xbin.dati.data.mean)
%     Example: 
%     Xbin = TI_bin with TI_bin.name = [0-5, 5-10, 10-15] [%]
%     Xbin_length = 3
%     WSbin.name = [1.25-1.75, 1.75-2.25, 2.25-2.75, 2.75-3.25, 3.25-3.75]
%     WSbin_length = 5
%     number_of_sensor = 3
%     Xbin updated will contain Xbin.dat1, Xbin.dat2, Xbin.dat3
%     Xbin.dat1 = double(5,3)
%     Xbin.dat1(1,:) = [sensor1_average, sensor2_average, sensor3_average]
%     and sensor 3 corresponds to Ct data
%  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the sensor corresponding to the power sensor and wsp normalised

MxH_sens_no = find(contains(SensorList.sensorname(:,2), 'Mx'));


% update the sensor list with the Ct coefficient
sensorname_size = size(SensorList.sensorname);
name_ext = SensorList.sensorname{WSPnorm_sens_no,1};
name_ext = name_ext(1:end-5);
SensorList.sensorname(sensorname_size(1)+1,1) = {strcat('Thrust Coefficient as f. of ', name_ext, '(-)')};
SensorList.sensorname(sensorname_size(1)+1,2) = {'Ct'};
SensorList.sens = [SensorList.sens; sensorname_size(1)+1 0];
SensorList.toplot = [SensorList.toplot sensorname_size(1)+1];

Ct_sens_no = max(size(SensorList.sens));

% Computing Ct based on IEC 61400-12
for i=1:length(Xbin.index)
    temp2 = strcat(dat_name,string(i));
        %%%if using matlab < 2017b
        temp2 = char(temp2);
    
    % calculating for the bin mean average
	moment_arm=HHeight-MxH_sens_height;
	
	T= abs(Xbin.(temp2).mean(:,MxH_sens_no)*10^3/moment_arm/cos(pi/180*Tilt)); % Thrust load converted to [N]
    Vn = Xbin.(temp2).mean(:,WSPnorm_sens_no);
    Ct = T./(0.5*RhoRef*AreaSwept*(Vn.^2));
    Ct(isnan(Ct))=0;
    Xbin.(temp2).mean(:,Ct_sens_no) = Ct;
    
    % calculating fro the raw data
    T = abs(Xbin.(temp2).data.mean(:,MxH_sens_no)*10^3/moment_arm/cos(pi/180*Tilt)); % Thrust load converted to [N]
    Vn = Xbin.(temp2).data.mean(:,WSPnorm_sens_no);
    Ct = T./(0.5*RhoRef*AreaSwept*(Vn.^2));
    Ct(isnan(Ct))=0;
    Xbin.(temp2).data.mean(:,Ct_sens_no) = Ct;    
end
    

end