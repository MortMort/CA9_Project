function [frq, n]=towerfrqtd(folder,filename,sensor,offset,flag_plot)
%TOWERFRQTD - Calculates frequency of a sensor from the zero-crossing
%The function uses a sensor signal to count the zero-crossings and
%estimate the frequency on e.g. the tower, based on the tower bottom
%moment. By default the function will use a shutdown loadcase and estimate
%on the tower bottom moment.
%
% Syntax:  [frq, n]=LAC.timetrace.towerfrqtd(folder,filename,sensor,offset,flag_plot)
%
% Inputs:
%    folder    - path to timetraces
%    filename  - name of timetrace
%    sensor    - sensor to evaluate zero-crossing
%    offset    - offset on sensor-signal to tune zero-crossing (optional)
%    flag_plot - plot zero-crossings (optional)
%
% Outputs:
%    frq       - estimated frequency
%    n         - number of zero-crossings
%
% Example: 
%    [frq,n] = towerfrqtd('X:\3MW\V1123000.119\iec3a.1540.004\LOADS\INT')
%    [frq,n] = towerfrqtd('X:\3MW\V1123000.119\iec3a.1540.004\LOADS\INT','51REMBVrp')
%    [frq,n] = towerfrqtd('X:\3MW\V1123000.119\iec3a.1540.004\LOADS\INT','51REMBVrp',0)
%    [frq,n] = towerfrqtd('X:\3MW\V1123000.119\iec3a.1540.004\LOADS\INT','51REMBVrp',0,1)
%
% Other m-files required: vdat, LAC.dir
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.towerfrq

% Author: MAARD, Martin Brødsgaard
% 2014; Last revision: 28-July-2015
if nargin<2
    files     = LAC.dir(fullfile(folder,'51REMBVrp*'));
    filename = files(1).name;
end
if nargin<3
    sensor = 'Mxt0';
end
if nargin<4
    offset = 0;
end
if nargin<5
    flag_plot=0;
end

% Extracting data
fprintf('Using %s for estimating frequency \n',filename)
filepath = fullfile(folder,filename);
data     = vdat('convert',filepath);
sensno   = strcmp(cellstr(data.GenInfo.SensorSym),sensor);
if sum(sensno)==0
    disp('Sensor not available')
    return
end

% Estimating zero crossing
n_minus = 0;
neg     = find(data.Ydata(:,sensno)<=offset);
pos     = find(data.Ydata(:,sensno)>offset);
cross   = intersect(neg+1,pos);
time    = data.Xdata(cross(end-n_minus))-data.Xdata(cross(3));
n       = length(cross)-(3+n_minus);
frq     = n/time;

% Plot data
if flag_plot==1
   figure; set(gcf,'color','white'); set(gcf, 'Position', [250 75 800 600])
   plot(data.Xdata,data.Ydata(:,sensno)); hold on; grid on;
   plot(data.Xdata(cross(3:end-n_minus)),data.Ydata(cross(3:end-n_minus),sensno),'or')
   xlabel('Time [s]'); ylabel(['Sensor: ' sensor])
   text(0.5*max(data.Xdata),0.75*max(data.Ydata(:,sensno)),['Number of oscillations: ' num2str(n)])
   text(0.5*max(data.Xdata),0.5*max(data.Ydata(:,sensno)),['Tower frequency: ' num2str(frq)])
    
end
