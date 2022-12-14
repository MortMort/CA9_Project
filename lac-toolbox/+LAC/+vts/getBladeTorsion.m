function getBladeTorsion(loadPath)

%Function getBladeTorsion(loadPath)
% Script to extract the torsion of the blade and create .txt file with the
% results. Is based on the Power curve calculations at one wind speed.
%
% Input:
% loadsPath  - Directory of the Loads folder
%
% Output:
% TorsionTable - .txt file with the radii and corresponding torsion
%                   along the blade
%
% Author: ASKNE, Ashok Kumar Nedumaran
% Dec 2017; Last revision: 28th-December-2017

% Collect the STA file names
staFiles=dir([loadPath 'STA\*.sta']);

% Collect sensor information
sensorInfo = sensreadTL([loadPath,'INT\sensor']);
sensorListAll = [sensorInfo{:,7}];

% Collect radius of each blade cross section
bladeFile = dir([loadPath 'PARTS\BLD']);   % Collect blade file name
bladeFile = bladeFile(~[bladeFile.isdir]); % Remove directory information
bladeInfo = LAC.vts.convert(([bladeFile.folder '\' bladeFile.name]), 'BLD');
bladeCrossSection = bladeInfo.SectionTable.R; % Radius of blade cross section [m]

% Find torsion Sensor Index
torsionSensorList = strsplit_LMT((sprintf('T2%1d \n', 1:length(bladeCrossSection)))); % Generate torsionSensorList
torsionSensorIndex = find(ismember(sensorListAll,torsionSensorList)==1);

% Collect torsion values across blade cross sections
torsionValue = zeros(length(staFiles), length(torsionSensorIndex));  % Preallocate
for istaFiles=1:length(staFiles)
    staData = LAC.vts.convert([loadPath, 'STA\', staFiles(istaFiles).name], 'STA');
    torsionValue(istaFiles,:) = staData.mean(torsionSensorIndex);
end

% Print blade cross section and mean torsion values
printData = [bladeCrossSection transpose(mean(torsionValue))];    % Store data to be printed
fileID = fopen(sprintf('%s\\TorsionTable.txt',loadPath),'w');
fprintf(fileID,'%15s %20s\n','Radius of blade cross section [m]','Torsion [deg]');
fprintf(fileID,'%15.3f %35.5f\r\n',printData');
fclose(fileID);

end