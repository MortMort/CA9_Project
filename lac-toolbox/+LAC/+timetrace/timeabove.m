function [sensorInterval, cont, t, meanVal] = timeabove(intfile,sensor,limits)


[GenInfo,Xdata,Ydata,ErrorString] = LAC.timetrace.int.readint(intfile,1,[],[],[]);

sen = LAC.vts.convert(fullfile(fileparts(intfile),'sensor'));
idx = sen.findSensor(sensor,'exact');
sensorArray    = SPV.User.movingAverage(2,GenInfo.SampleTime,Ydata(:,idx));
% sensorArray    = Ydata(:,idx);
sensorInterval = linspace(limits(1),limits(2),100);
meanVal        = mean(Ydata(:,idx));
for iInterval = 1:length(sensorInterval)
    sensorArrayOffset = sensorArray - sensorInterval(iInterval);
    sensorArrayOffset(1)   = -1;
    sensorArrayOffset(end) = -1;
    sensorArraySign   = sign(sensorArrayOffset);
    
    crossFromAbove    = find(diff(sensorArraySign)==-2);
    crossFromBelow    = find(diff(sensorArraySign)==2);
    if ~isempty(crossFromBelow)
        cont(iInterval) = max((crossFromAbove - crossFromBelow)*GenInfo.SampleTime);
    else
        cont(iInterval) = 0;
    end
    
    t(iInterval) = sum(sensorArrayOffset>0)*GenInfo.SampleTime;
%     if sensorInterval(iInterval)>13.0
%         
%         
%         figure
%         plot(Xdata,sensorArray); hold on;
%         plot(Xdata(sensorArrayOffset>0),sensorArray(sensorArrayOffset>0),'y.')
% 
%         plot(Xdata(crossFromAbove),sensorArray(crossFromAbove),'go')
%         plot(Xdata(crossFromBelow),sensorArray(crossFromBelow),'ro')
%     end
    
end