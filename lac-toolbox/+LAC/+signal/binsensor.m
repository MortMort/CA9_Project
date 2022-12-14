function [binB,binA,stdB] = binsensor(rawA,rawB,dt,binA,avgtime,option)
%TOWERFRQ - Calculate gravity correction on tower frequency from EIG-file
%Function to read VTS eig-file and correct the tower frequency for gravity
%influence. The function writes an outputfile and also calculates 1P margin
%and margin to minimum 3P rotor frequency.
%
% Syntax:  [frq] = towerfrq(inputpath)
%
% Inputs:
%   rawA       - Raw signal of sensor A, used for binning.
%   rawB       - Raw signal, which is binned with sensor A.
%   dt         - Time step in sensor signal, used for defining avgtime
%   binA       - Bin definition, i.e. [0:15:360]
%   avgtime    - Avg time used for smoothening sensor A and B
%   option     - Choose 'mean' or 'amplitude'
%   
%
% Outputs:
%   binB         - The mean value of sensor B binned with sensor A.
%   binA         - The bins, mirror of the input.
%   stdB         - The std variation of sensor B in the sensor A bins.
%
% Example: 
%    [gen,xdat,ydat] = LAC.timetrace.int.readint(intfile,1,[],[],[]) ;
%    
%    [binload,binazi,stdAzi] = binsensor(azimuthsensor,loadsensor,0.01,[0:10:360],5,'mean')
%
% NOTE: This function can only be used as guidance.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: 

% Author: MAARD, Martin Brødsgaard
% January 2016; 
% V00 - Initial version

nt=floor(avgtime/dt); % Number of time steps in segment

sensorA.reshaped   = reshape(rawA(1:end-mod(size(rawA,1),nt)),nt,[]);
sensorB.reshaped   = reshape(rawB(1:end-mod(size(rawB,1),nt)),nt,[]);

sensorA.segmented  = mean(sensorA.reshaped,1); % mean rotor speed for each of the 5s segment

switch option
    case 'mean'    
        sensorB.segmented = mean(sensorB.reshaped,1); % Edgewise amplitude for Blade 1, for each of the 5s segment
    case 'amplitude'
        sensorB.segmented = max(sensorB.reshaped,[],1) - min(sensorB.reshaped,[],1); % Edgewise amplitude for Blade 1, for each of the 5s segment        
end

[sensorA.N,sensorA.idx] = histc(sensorA.segmented,binA);
for i=1:length(binA)
    binB(i,1) = mean(sensorB.segmented(sensorA.idx==i));
    stdB(i,1) = std(sensorB.segmented(sensorA.idx==i));
end

end
