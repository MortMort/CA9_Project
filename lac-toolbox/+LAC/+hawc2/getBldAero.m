function [radius,section] = getBldAero(simfolder,loadcases)
%% get sensor number for twist sensors
sta = LAC.vts.stapost(simfolder);
sta.read;
% sta.save;
%%
radLoc=[];
secDat = [];
[idxlist, secList]  = sta.findSensor('Twt');
for idx=idxlist'
    a = textscan(sta.stadat.sensor{idx},'Twt%f5.2B1');
    radLoc(end+1) = a{1};
    
end

for sec = idxlist'
    secDat(:,end+1) = -sta.getLoad(sec,'mean',{loadcases});    
end
[radius.twt, idx] = unique(radLoc);
section.twt    = secDat(:,idx);


%%
radLoc=[];
secDat = [];
[idxlist, secList]  = sta.findSensor('AoA');
for idx=idxlist'
    a = textscan(sta.stadat.sensor{idx},'AoA%f5.2B1');
    radLoc(end+1) = a{1};
    
end

for sec = idxlist'
    secDat(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end
[radius.aoa, idx] = unique(radLoc);
section.aoa    = secDat(:,idx);

%%
radLoc=[];
secDat = [];
[idxlist, secList]  = sta.findSensor('Cd');
for idx=idxlist'
    a = textscan(sta.stadat.sensor{idx},'Cd%f5.2B1');
    radLoc(end+1) = a{1};
    
end

for sec = idxlist'
    secDat(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end
[radius.cd, idx] = unique(radLoc);
section.cd    = secDat(:,idx);

%%
radLoc=[];
secDat = [];
[idxlist, secList]  = sta.findSensor('Cl');
for idx=idxlist'
    a = textscan(sta.stadat.sensor{idx},'Cl%f5.2B1');
    radLoc(end+1) = a{1};
    
end

for sec = idxlist'
    secDat(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end
[radius.cl, idx] = unique(radLoc);
section.cl    = secDat(:,idx);

%%
return
mxr = sta.getLoad('-Mx11r','mean',{loadcases})*1000; 
%% generate equation between blade root flap and twist
for i = 1:length(radLoc(4:end-4))
    Eq(i,:) = polyfit(mxr',tor(:,i),1);
end
Eq=fliplr(Eq);