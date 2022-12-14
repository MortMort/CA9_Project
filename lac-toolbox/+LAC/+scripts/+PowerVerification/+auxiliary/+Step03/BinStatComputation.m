function [Xbin] = BinStatComputation(data,Xbin,dat_name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author MODFY - 15/05/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Target: Power Performance Verification
%
% Aim: The function is computing the average value of the measurement
% within a bin
% 
% Inputs: 
% - data: is struct variable data or Simdata which has been obtain by loading the
%          information from the database or Simulation. It contains, men,
%          min, max and std of the datasets
% - Xbin: a structure variable that contains the bin label based on a
%       parameter, the ws binning and the index of the data that should be
%       within that bin
% - dat_name: vector of char. It contains the extension name in which to
%       update Xbin
% 
% Output:
% The function returns Xbin updated with the computed average values 
% within the ws bin in accordance to each Xbin bin. 
% Xbin.dat(i) is a double variable int of size (WSbin_length, number_of_sensor). 
% Therefore a row correspond to a bin j of WSbin and a column to the
% average value within the bin for the sensor k.
%     Example: 
%     Xbin = TI_bin with TI_bin.name = [0-5, 5-10, 10-15] [%]
%     Xbin_length = 3
%     WSbin.name = [1.25-1.75, 1.75-2.25, 2.25-2.75, 2.75-3.25, 3.25-3.75]
%     WSbin_length = 5
%     number_of_sensor = 3
%     no_index = 100; corresponds to all the datasets which are within Xbin1
%     Xbin updated will contain Xbin.dat1, Xbin.dat2, Xbin.dat3
%     Xbin.dat1 = struct variable
%     Xbin.dat1.mean = double(WSbin_length, number_of_sensor) = [sensor1_average_of_the_mean, sensor2_average_of_the_mean, sensor3_average_of_the_mean]
%     Xbin.dat1.min = double(WSbin_length, number_of_sensor) = [sensor1_min_of_the_mean, sensor2_min_of_the_mean, sensor3_min_of_the_mean]
%     Xbin.dat1.max = double(WSbin_length, number_of_sensor) = [sensor1_max_of_the_mean, sensor2_max_of_the_mean, sensor3_max_of_the_mean]
%     Xbin.dat1.data: struct variable that contains the raw data to be considered within the Xbin
%                   Xbin.dat1.data.mean = double(no_index, number_of_sensor)
%                   Xbin.dat1.data.min = double(no_index, number_of_sensor)
%                   Xbin.dat1.data.max = double(no_index, number_of_sensor)
%                   Xbin.dat1.data.std = double(no_index, number_of_sensor)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Xbin_length = length(Xbin.index);
WSbin_length = length(Xbin.bin1);
number_of_sensor_mean = length(data.mean(1,:));
number_of_sensor_max = length(data.max(1,:));

data_output={};

for i = 1:Xbin_length
    temp1 = strcat('bin',string(i));
    temp2 = strcat(dat_name,string(i));
    %%%if using matlab < 2017b
    temp1 = char(temp1);
    temp2 = char(temp2);
    all_index= []; % index pointing to all data that are within the Xbin
    
    for j=1:WSbin_length

        if isempty(Xbin.(temp1){j})
            Xbin.(temp2).max(j,:) = zeros(1,number_of_sensor_max);
            Xbin.(temp2).mean(j,:) = zeros(1,number_of_sensor_mean);
            Xbin.(temp2).min(j,:) = zeros(1,number_of_sensor_max);
            Xbin.(temp2).std(j,:) = zeros(1,number_of_sensor_max);
        elseif length(Xbin.(temp1){j})==1
            index_temp = Xbin.(temp1){1,j};
            Xbin.(temp2).max(j,:)  = (data.max(index_temp,:));
            Xbin.(temp2).mean(j,:)  = (data.mean(index_temp,:));
            Xbin.(temp2).min(j,:)  = (data.min(index_temp,:));
            Xbin.(temp2).std(j,:)  = (data.std(index_temp,:));
            all_index = [all_index; index_temp];
        else
            index_temp = Xbin.(temp1){1,j};
            Xbin.(temp2).max(j,:)  = mean(data.max(index_temp,:));
            Xbin.(temp2).mean(j,:)  = mean(data.mean(index_temp,:));
            Xbin.(temp2).min(j,:)  = mean(data.min(index_temp,:));
            Xbin.(temp2).std(j,:)  = mean(data.std(index_temp,:));
            all_index = [all_index; index_temp];
        end
        
        Xbin.(temp2).data.mean = data.mean(all_index,:);
        Xbin.(temp2).data.min = data.min(all_index,:);
        Xbin.(temp2).data.max = data.max(all_index,:);
        Xbin.(temp2).data.std = data.std(all_index,:);
        Xbin.(temp2).data.name = data.filedescription(all_index,:);
    end

end


end