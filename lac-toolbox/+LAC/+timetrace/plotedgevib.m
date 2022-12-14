function plotedgevib(filename,filetype)
% filename=...
% 'H:\3mw\MK2A\Investigations\669\DIBt2012_007\INT\1114b012.int';


%% Read data


%  timetrace = vdat('convert',filename);
if exist('vdat','var')==0
    [timetrace.GenInfo,timetrace.Xdata,timetrace.Ydata] = LAC.timetrace.int.readint(filename,1,[],[],[]);    
end

if nargin==2 && strcmp(filetype,'vax')
    defaultSensors = {'RotorAzimuthAngle(deg)', 'BladeALoadRootEdge(kN*m)', 'BladeCLoadRootEdge(kN*m)', 'BladeBLoadRootEdge(kN*m)', 'RotorTachoSpeed(rpm)', 'WindSpeed(m/s)'};
elseif nargin==2 && strcmp(filetype,'vts')
    defaultSensors = {'PSI', 'My11r', 'My21r', 'My31r', 'Omega', 'Vhub'};    
else
    defaultSensors = {'PSI', 'My11r', 'My21r', 'My31r', 'Omega', 'Vhub'};
end

sensor = LAC.vts.convert(fullfile(fileparts(filename),'sensor'),'SENSOR');
for j = 1:length(sensor.name)
                sensorList{j,1} = sprintf('''%s''%40s %s',sensor.name{j},sensor.description{j},sensor.unit{j});
end

sensorNames    = {'Azimuth', 'My1', 'My2', 'My3', 'Omega', 'Vhub'};
for iSensor = 1:length(sensorNames)

    [index.(sensorNames{iSensor}), status] = listdlg('PromptString',sprintf('Choose sensor for %s:',sensorNames{iSensor}),...
                    'SelectionMode','single',...
                    'InitialValue',sensor.findSensor(defaultSensors{iSensor},'exact'),...
                    'ListString',sensorList);
    if ~status
        error('Sensor not selected!')
    end
end

[fixedColl,fixedCos,fixedSin]=LAC.rot2fix(LAC.deg2rad(timetrace.Ydata(:,index.Azimuth))...
                                            ,timetrace.Ydata(:,index.My1)...
                                            ,timetrace.Ydata(:,index.My3)...
                                            ,timetrace.Ydata(:,index.My2));
                                        
%% Find whirling margin
[FRQ,FFT]=LAC.signal.fftcalc(timetrace.Xdata,fixedCos,round(60/timetrace.GenInfo.SampleTime));
[FRQ_EDGE,FFT_EDGE]=LAC.signal.fftcalc(timetrace.Xdata,timetrace.Ydata(:,index.My1),round(60/timetrace.GenInfo.SampleTime));

frqEdge = LAC.signal.getPeak(timetrace.Xdata,timetrace.Ydata(:,index.My1),0.6,2);
frqBW   = LAC.signal.getPeak(timetrace.Xdata,fixedCos,frqEdge(2)-0.4,frqEdge(2));
frqFW   = LAC.signal.getPeak(timetrace.Xdata,fixedCos,frqEdge(2),frqEdge(2)+0.4);

rangeBW = [frqBW(2)-0.15 frqBW(2)+0.15];
rangeFW = [frqFW(2)-0.15 frqFW(2)+0.15];

%% Filter signals
BW     = LAC.signal.butterFilt(2,rangeBW,fixedCos',timetrace.GenInfo.SampleTime,'bandpass');                                      
BW_rms = LAC.signal.butterFilt(2,0.25,BW.^2,timetrace.GenInfo.SampleTime,'low').^0.5;                                        

FW     = LAC.signal.butterFilt(2,rangeFW,fixedCos',timetrace.GenInfo.SampleTime,'bandpass');                                      
FW_rms = LAC.signal.butterFilt(2,0.25,FW.^2,timetrace.GenInfo.SampleTime,'low').^0.5;  

plotlimit=round(std(timetrace.Ydata(:,index.My1))*0.002)*1000;

%% Plot figures

% Plot time domain
f=figure;
set(f,'color','white'); set(f, 'Position', [120 50 800 950]);

sp(1)=subplot(511);
plot(timetrace.Xdata,fixedCos,'b'); hold on;
plot(timetrace.Xdata,timetrace.Ydata(:,index.My1),'k'); grid on;
ylabel('Edgewise load [kNm]') ;ylim([-plotlimit plotlimit])
title(filename)

sp(2)=subplot(512);
plot(timetrace.Xdata,BW); hold on
plot(timetrace.Xdata,FW,'r');grid on;
ylabel('Whirling Contents [kNm]');ylim([-plotlimit plotlimit]./2)

sp(3)=subplot(513);
plot(timetrace.Xdata,BW_rms); hold on
plot(timetrace.Xdata,FW_rms,'r');grid on; 
ylabel('Whirling Amplitude [kNm]');ylim([0 plotlimit/3])
legend('BW Whirling','FW Whirling','location','best')

sp(4)=subplot(514);
plot(timetrace.Xdata,timetrace.Ydata(:,index.Omega),'k'); grid on; hold on
plot(timetrace.Xdata,ones(timetrace.GenInfo.NoOfSamples,1)*frqBW(2)*20,'b','linewidth',2)
plot(timetrace.Xdata,ones(timetrace.GenInfo.NoOfSamples,1)*frqFW(2)*10,'r','linewidth',2)
ylabel('Omega [rpm]');
sp(5)=subplot(515);
plot(timetrace.Xdata,timetrace.Ydata(:,index.Vhub),'k'); grid on;
ylabel('Wind Speed [m/s]'); xlabel('Time [s]')
linkaxes(sp,'x')
% Plot FFT
axLimits=[0.15 2 0 200];
figH=figure; set(figH,'color','white'); set(figH, 'Position', [120 75 1000 500]);
plot(FRQ(2:end),FFT(2:end),'k','linewidth',2); grid on; hold on;
plot(FRQ_EDGE(2:end),FFT_EDGE(2:end),'--k','linewidth',2);

plot(frqBW(2)*ones(1,2),[0 5000],'--b','linewidth',2);
plot(frqFW(2)*ones(1,2),[0 5000],'--r','linewidth',2);
text(frqBW(2)-0.1,frqBW(1)*1.1,[num2str(round(frqBW(2)*100)/100) 'Hz'])
text(frqFW(2)-0.1,frqFW(1)*1.1,[num2str(round(frqFW(2)*100)/100) 'Hz'])

plot(rangeBW(1)*ones(1,2),[0 5000],'b','linewidth',2);
plot(rangeBW(2)*ones(1,2),[0 5000],'b','linewidth',2);

plot(rangeFW(1)*ones(1,2),[0 5000],'r','linewidth',2);
plot(rangeFW(2)*ones(1,2),[0 5000],'r','linewidth',2);

plot(frqBW(2)*ones(1,2),[0 5000],'--b','linewidth',2);
plot(frqFW(2)*ones(1,2),[0 5000],'--r','linewidth',2);
title(filename)
legend('Fixed Coord','Local Coord','Backward Whirling','Forward Whirling')
ylabel('FFT Blade Edge Moment, Root [kNm]'); xlabel('Frq [Hz]'); xlim([0.15 2]); ylim([0 max(FFT(2:end)*2)])
