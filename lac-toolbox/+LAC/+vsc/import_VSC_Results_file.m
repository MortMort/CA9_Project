function [dataout] = import_VSC_Results_file(VSCresultsfile)
% [dataout] = import_VSC_Results_file(VSCresultsfile)
% 
% Input
% - VSCresultsfile path to the VSC result file. If VSCresultsfile is a cell
%   the different result files will be combined into one.
% 
% Output
% - dataout data structure with following fields
%                     dataout.Fatigue.(SensorName)
%                     dataout.Extreme.(SensorName)
%                     dataout.dataExtremeLC.(SensorName)
%                     dataout.ExtremeLC.(SensorName)
% 
% Reader for VSC result files
% NIWJO Dec 2020

if ~iscell(VSCresultsfile)
    VSCresultsfile = {VSCresultsfile};
end
k = 0;kk = 0;
for t = 1:length(VSCresultsfile)
    A = textscan(fileread(VSCresultsfile{t}),'%[^\n\r]');
    data = A{1};
    dataFatigueRaw = data(find(contains(data,'Fatigue Loads'))+2:find(contains(data,'Extreme Loads'))-1);
    dataExtremeRaw = data(find(contains(data,'Extreme Loads'))+2:find(contains(data,'Extreme Load Case'))-1);
    dataExtremeLCRaw = data(find(contains(data,'Extreme Load Case'))+2:end);

    dataSensorsFatigueRaw = data(find(contains(data,'Fatigue Loads'))+1);
    dataSensorsFatigue = regexprep(strsplit_LMT(dataSensorsFatigueRaw{1},'\t'),{'\t' ' ' '/'},{'' '' '_'});
    dataSensorsFatigue = dataSensorsFatigue(2:end);

    dataSensorsExtremeRaw = data(find(contains(data,'Extreme Loads'))+1);
    dataSensorsExtreme = regexprep(strsplit_LMT(dataSensorsExtremeRaw{1},'\t'),{'\t' ' ' '/'},{'' '' '_'});
    dataSensorsExtreme = dataSensorsExtreme(2:end);

    
    for i = 1:length(dataFatigueRaw)
        dataFatigueRawSplit = str2double(strsplit_LMT(dataFatigueRaw{i},'\t'));
        if length(dataFatigueRawSplit(~isnan(dataFatigueRawSplit)))==length(dataSensorsFatigue)
            k = k+1;
            dataFatigue(k,:) = dataFatigueRawSplit(~isnan(dataFatigueRawSplit));
            dataout.Fatigue.IndexName(k,1) = str2double(dataFatigueRaw{i}(strfind(dataFatigueRaw{i},'[')+1:strfind(dataFatigueRaw{i},']')-1));
        else
            warning(['Skipping line. Something is wrong with line ' num2str(i) ' please check ' VSCresultsfile{t}])
        end
    end

    
    for i = 1:length(dataExtremeRaw)
        dataExtremeRawSplit = str2double(strsplit_LMT(dataExtremeRaw{i},'\t'));
        dataExtremeLCRawSplit = strsplit_LMT(dataExtremeLCRaw{i},'\t');
        if length(dataExtremeRawSplit(~isnan(dataExtremeRawSplit)))==length(dataSensorsExtreme)
            kk = kk+1;
            dataExtreme(kk,:) = dataExtremeRawSplit(~isnan(dataExtremeRawSplit));
            dataExtremeLC(kk,:) = dataExtremeLCRawSplit;
            dataout.Extreme.IndexName(kk,1) = str2double(dataExtremeRaw{i}(strfind(dataExtremeRaw{i},'[')+1:strfind(dataExtremeRaw{i},']')-1));
            dataout.dataExtremeLC.IndexName(k,1) = str2double(dataExtremeRaw{i}(strfind(dataExtremeLCRaw{i},'[')+1:strfind(dataExtremeLCRaw{i},']')-1));
        else
            warning(['Skipping line. Something is wrong with line ' num2str(i) ' please check ' VSCresultsfile{t}])
        end
    end
end
    dataExtremeLC = regexprep(dataExtremeLC,{'\t' ' '},{'' ''});

    for i = 1:length(dataSensorsFatigue)
        sensorfixed = regexprep(dataSensorsFatigue{i},{'=', '\.'},{'', ''});
        dataout.Fatigue.(sensorfixed) = dataFatigue(:,i);
    end

    for i = 1:length(dataSensorsExtreme)
        sensorfixed = regexprep(dataSensorsExtreme{i},{'=','/', '\.'},{'','_', ''});
        dataout.Extreme.(sensorfixed) = dataExtreme(:,i);
        dataout.ExtremeLC.(sensorfixed) = dataExtremeLC(:,i);
    end
end
