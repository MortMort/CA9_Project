function T = towerTopPowerProdMeanloads(runFolder,sensors)
% extract tower top loads in DLC 11 and find mean value over all wind speeds
%
% Syntax: T = towerTopPowerProdMeanloads(runFolder)
%         T = towerTopPowerProdMeanloads(runFolder,sensors)
%
% Inputs: runFolder = VTS root simulation folder
%         sensors = cell with tower top sensors. default sensor = {'Vhub','MzTT','MyTT','FxTT','FyTT','FzTT'}
% 
% Output: Tabel with output values
%
% Version History:
% 00: new script by SORSO 11-12-2015
%
% Review
% 00: crossed check with JAVES script by SORSO 11-12-2015
%% asign default sensors
if nargin<2 % default sensors
    sensors = {'Vhub','MzTT','MyTT','FxTT','FyTT','FzTT'};
end
%% read sensor file.
sensOut = LAC.vts.convert(fullfile(runFolder,'INT','sensor'));
for i=1:length(sensors)
    sensNo(i) = find(strncmpi(sensors{i},sensOut.name,length(sensors{i})) == 1);
end
%% read sta data and more...
turbine1 = LAC.vts.stapost(runFolder);
turbine1.read;

%% Find DLC 11
key = '11';
idx = find(strncmpi(key,turbine1.stadat.filenames,length(key)) == 1);
%% calculate hours and total hours
hour = turbine1.stadat.hour(idx);
hourTotal = sum(hour);
%% find mean values for selected load cases and sensors
meanValues = turbine1.stadat.mean(sensNo,idx);
%% Calculate average over all DLC 11s
MeanTotal = meanValues*hour'/hourTotal;
%% generate matlab table
T = table(sensOut.name(sensNo),MeanTotal,sensOut.unit(sensNo),sensOut.description(sensNo),'VariableNames',{'Sensor','Mean','Unit','Description'});
