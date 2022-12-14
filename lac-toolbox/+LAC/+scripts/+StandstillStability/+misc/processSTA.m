function processSTA(turbName,simfolder,outfolder,forceRereadSta)
% Process statistics (STA) files from the VTS directory.

if nargin < 4 % read stapost file if it exists
    forceRereadSta = 0;
end

%DATA EXTRACTION
VTS_STA = LAC.vts.stapost(simfolder);
VTS_STA.read(forceRereadSta);

% Find senstor numbers
sens_edg(1) = find(strcmpi('My11r',VTS_STA.stadat.sensor)); %Blade 1 root edgewise bending moment sensors, My11r
sens_edg(2) = find(strcmpi('My21r',VTS_STA.stadat.sensor)); %Blade 2 root edgewise bending moment sensors, My21r
sens_edg(3) = find(strcmpi('My31r',VTS_STA.stadat.sensor)); %Blade 2 root edgewise bending moment sensors, My21r
wsSens = strcmpi('Vhub',VTS_STA.stadat.sensor);  %Wind speed sensor, Vhub
wdSens = strcmpi('Wdir',VTS_STA.stadat.sensor); %Wind direction sensor, Wdir
azSens = strcmpi('PSI',VTS_STA.stadat.sensor); %Azimuth sensors, PSI


fnames=VTS_STA.stadat.filenames;
WS.mean=VTS_STA.stadat.mean(wsSens,:);
WD.mean=VTS_STA.stadat.mean(wdSens,:);
AZ.mean=VTS_STA.stadat.mean(azSens,:);
AZ.range=VTS_STA.stadat.max(azSens,:)-VTS_STA.stadat.min(azSens,:);
My1.range=VTS_STA.stadat.max(sens_edg(1),:)-VTS_STA.stadat.min(sens_edg(1),:);
My2.range=VTS_STA.stadat.max(sens_edg(2),:)-VTS_STA.stadat.min(sens_edg(2),:);
My3.range=VTS_STA.stadat.max(sens_edg(3),:)-VTS_STA.stadat.min(sens_edg(3),:);

save([outfolder '/' turbName '_Loads_PP.mat'],'fnames','WS','WD','AZ','My1','My2','My3')

sensorList = VTS_STA.stadat.sensor;
save('sensorList.mat', 'sensorList')
