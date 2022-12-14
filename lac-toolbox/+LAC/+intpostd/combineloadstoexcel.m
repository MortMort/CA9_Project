function combineloadstoexcel(compareMainLoadRatioFilePath,limits)
% COMBINELOADSTOEXCEL converts a CompareMainLoadRatio.txt to an Excel sheet.
%
% This function creates an excel with the data from compareloads with the cells colored by the ratio to the design.
% Works for a maximum of 47 inputs.
%
% Syntax :
%
% combineloadstoexcel(compareMainLoadRatioFilePath) reads the CompareMainLoadRatio.txt (has to
% be an absolute path) and converts it to an Excel sheet with ratio coloring according to the standard
% limits: green <= 1.005, 1.005 < yellow <= 1.015 and red >1.015
%
% combineloadstoexcel(__, limits) same as above, but with user defined limits given as a two element
% double vector, e.g. limits = [1.01 1.05] will format cells according to green <= 1.01, 
% 1.01 < yellow <= 1.05 and red >1.05
if nargin == 1
    limits = [1.005 1.015];
end

fid = fopen(compareMainLoadRatioFilePath);
data = textscan(fid, '%s', 'Delimiter', '\n', 'CollectOutput', true);
data = data{1,1};

First_section = '#5.1 Extreme Flapwise Moment (-Mx)      ';
Last_section  = '#FAT Result ratios (Worst case for all sensors above):';

Excel = actxserver('Excel.Application');
% Show the Excel window
set(Excel, 'Visible', 1);
%%INSERT NEW WORKBOOK
W = Excel.Workbooks.Add;

indexC = strfind(data,First_section);
i_vec_start = find(not(cellfun('isempty',indexC)));

indexL = strfind(data,Last_section);
indexL = find(not(cellfun('isempty',indexL)));
indexL = indexL-4;

Activesheet = Excel.Activesheet;

formatting = struct;
Alphabet = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ'};

for i=1:indexL
    dat_string = data{i,1};
    
    if length(data{i,1}) == 0;
       value = ' ';
       ActivesheetRange = get(Activesheet,'Range',sprintf('A%d',i));
       set(ActivesheetRange, 'Value', value);  
    else 
    if i>i_vec_start && (strcmp(dat_string(1:2),'--') || strcmp(dat_string(1),'#'))
        value = data{i,:};
        ActivesheetRange = get(Activesheet,'Range',sprintf('A%d',i));
        set(ActivesheetRange, 'Value', value);
    elseif i<i_vec_start+1
        value = data{i,:};
        ActivesheetRange = get(Activesheet,'Range',sprintf('A%d',i));
        set(ActivesheetRange, 'Value', value); 
    else
        value = data{i,:};
        splitvalues_orig = strsplit_LMT(value);
        if strcmp(splitvalues_orig(1),'Sensor') 
            splitvalues = [splitvalues_orig 'Max ratio'];
            idx_maxratio = length(splitvalues);
        elseif strcmp(splitvalues_orig(2),'[Design]') 
            splitvalues = [splitvalues_orig 'Max ratio'];
            idx_maxratio = length(splitvalues);
        else
            ratios = splitvalues_orig(5:end-3);
            splitvalues = strsplit_LMT(value);
            splitvalues(idx_maxratio) = cellstr(sprintf('%0.2f',max(abs(str2double(ratios)))));
        end
        
        ActivesheetRange = get(Activesheet,'Range',sprintf('A%d:%s%d',i,Alphabet{length(splitvalues)},i));
        set(ActivesheetRange, 'Value', splitvalues);
        formatting = reColor(Excel,splitvalues,i,formatting,limits);
    end
    end
end

for i_format = i_vec_start:indexL
    if ~isempty(formatting(i_format).sens_name)
        index1 = strfind(data,formatting(i_format).sens_name);
        idx1 = find(not(cellfun('isempty',index1)));
        index2 = strfind(data,formatting(i_format).direction);
        idx2 = find(not(cellfun('isempty',index2)));
        [val,~]=intersect(idx1,idx2);
        if length(val)>2
            idx_val = val(length(val)/2:end);
        else
            idx_val = val(end);
        end
        for i_col=5:length(formatting(i_format).format)
            for i_val=1:length(idx_val)
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{i_col},idx_val(i_val))).Interior.Color = formatting(i_format).format(i_col);
            end
       end
    end
end

outputfolder = dir(compareMainLoadRatioFilePath);
excelFileName = [outputfolder.folder,'\','CompareMainLoadRatio.xls'];

W.SaveAs(excelFileName)
end
    
%Quit(Excel)



function formatting = reColor(Excel,splitvalues,i,formatting,limits)
Alphabet = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ'};

% Change colour to RGB
Col_green = double(198) * 256^0 + double(239) * 256^1 + double(206) * 256^2;
Col_red = double(255) * 256^0 + double(199) * 256^1 + double(206) * 256^2;
Col_white = double(255) * 256^0 + double(255) * 256^1 + double(255) * 256^2;
Col_yellow = double(255) * 256^0 + double(204) * 256^1 + double(0) * 256^2;
% Set normal formatting to white
formatting(i).format    = ones(1,length(splitvalues)).*Col_white;
for idx=5:length(splitvalues)
    [~, status] = str2num(splitvalues{5});
    if status
        formatting(i).sens_name = splitvalues{1};
        formatting(i).direction = splitvalues{3};
        
        if abs(str2num((splitvalues{idx})))<=limits(1)
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).Interior.Color = Col_green;
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).NumberFormat = '0.00';
            formatting(i).format(idx) = Col_green;
        elseif (abs(str2num((splitvalues{idx})))>limits(1)) & (abs(str2num((splitvalues{idx})))<=limits(2))
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).Interior.Color = Col_yellow;
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).NumberFormat = '0.00';
            formatting(i).format(idx) = Col_yellow;
        elseif abs(str2num((splitvalues{idx})))>limits(2)
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).Interior.Color = Col_red;
            Excel.Worksheets.Item(1).Range(sprintf('%s%i',Alphabet{idx},i)).NumberFormat = '0.00';
            formatting(i).format(idx) = Col_red;
        end
    end
end
end

