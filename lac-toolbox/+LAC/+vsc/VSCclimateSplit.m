function pathout = VSCclimateSplit(path,splitno)
% pathout = VSCclimateSplit(path,splitno)
%
% Splits the climatefile into x amount of files
% This is helpfull when running Vestas Site Check Universe to
% utillize more cores on you computer
% 
%   path        - path to climate
%   splitno     - number of files to split into
%
% NIWJO 2021

% open climate file
i = 0;
fid=fopen(path);
while 1
    i = 1+i;
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    Data{i} = tline;
end
fclose(fid);

% Split files
Headder = Data(1);
ClimateData = Data(2:end);

splitLength = round(length(ClimateData)/splitno);
for i = 1:splitno
    if i == 1
        idx = [1 splitLength];
        ClimateDataSplit{i} = ClimateData(1:splitLength);
    elseif i == splitno
        ClimateDataSplit{i} = ClimateData((i-1)*splitLength+1:end);
        idx = [idx length(ClimateData)];
    else
        ClimateDataSplit{i} = ClimateData((i-1)*splitLength+1:i*splitLength);
        idx = [idx i*splitLength];
    end
end

% Check that input is equal to the output
ClimateDataSplitCheck = [ClimateDataSplit{:}];
if ~(idx(end) == length(ClimateData)) && isequaln(ClimateDataSplitCheck,ClimateData)
    error('Something is wrong')
else
    disp('Check done. Everything ok')
end

% Write files
[PATHSTR,NAME,EXT] = fileparts(path);
for i = 1:length(ClimateDataSplit)
    pathout{i} = fullfile(PATHSTR,[NAME '_' num2str(i) EXT]);
    fid=fopen(pathout{i},'w');
    for k = 1:length(ClimateDataSplit{i})
        if k == 1
            fprintf(fid,'%s\n',Headder{1});
            fprintf(fid,'%s\n',ClimateDataSplit{i}{k});
        else
            fprintf(fid,'%s\n',ClimateDataSplit{i}{k});
        end
    end
    fclose(fid);
end
end