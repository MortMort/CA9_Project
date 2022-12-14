function [WTG,Report,Pref] = ReadInputs_PP(file)
%% [WTG, Report] = ReadInputs(file)
% Function to read in the information used throughout the load and power
% performance verification.
% Create a .xlsx file with the wanted variables and values.
% All values between WTGStart and WTGEnd will be loaded to the structure
% WTG.
% All values between ReportStart and ReportEnd will be loaded to the
% structure Report.
%
% Created by RUSJE 14/3-2018
% Update MODFY 22/05/2019 - To fit the Power Performance Verification

[~,txt,raw] = xlsread(file,1);
iWTGS = find(contains(txt,'WTGStart'));
iWTGE = find(contains(txt,'WTGEnd'));

for iWTG=iWTGS+1:iWTGE-1
    WTG.(raw{iWTG,1}) = raw{iWTG,2};
    
    if ischar(WTG.(raw{iWTG,1})) == 1
       WTG.(raw{iWTG,1}) = str2num(WTG.(raw{iWTG,1})); 
    else
    end
        
end

iReportS = find(contains(txt,'ReportStart'));
iReportE = find(contains(txt,'ReportEnd'));

for iRep=iReportS+1:iReportE-1
    Report.(raw{iRep,1}) = raw{iRep,2};
    if isnan(Report.(raw{iRep,1}))
        Report.(raw{iRep,1}) = 'XXXX';
    end
end

% Reference Power Curve
[~,txt,raw] = xlsread(file,4);
iDataS = find(contains(txt,'Data_Start'));
iDataE = find(contains(txt,'Data_End'));

Pref=[]; % double variable which contains the wind speed in the first column 
         % and the reference output power curve
j=1;        
for i=iDataS+1:iDataE-1
    Pref(j,1) = raw{i,1};
    Pref(j,2) = raw{i,2};
    j=j+1;
end


end