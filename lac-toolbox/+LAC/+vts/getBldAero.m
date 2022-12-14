function [radius,section] = getBldAero(simfolder,loadcases)
%% get sensor number for twist sensors
sta = LAC.vts.stapost(simfolder);
sta.read;
% sta.save;
%%
[radius.twt, index]=sta.getSensDat('T2');
section.twt = [];
for sec = index'
    section.twt(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end

%%
[radius.aoa, index]=sta.getSensDat('AoA2');
section.aoa = [];
for sec = index'
    section.aoa(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end

%%
[radius.cd, index]=sta.getSensDat('Cd2');
section.cd = [];
for sec = index'
    section.cd(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end

%%
[radius.cl, index]=sta.getSensDat('Cl2');
section.cl = [];
for sec = index'
    section.cl(:,end+1) = sta.getLoad(sec,'mean',{loadcases});    
end

%%
return
mxr = sta.getLoad('-Mx11r','mean',{loadcases})*1000; 
%% generate equation between blade root flap and twist
for i = 1:length(radLoc(4:end-4))
    Eq(i,:) = polyfit(mxr',tor(:,i),1);
end
Eq=fliplr(Eq);