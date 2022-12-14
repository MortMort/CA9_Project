function PCFile = ReadPCFile(fname)
%Function to read powercurve files
% Input  : full path to pc/nm file
% Output : struct with cell arrays containing:
% - Power
% - AEP
% - CT
% - Pitch
% - PitchSTD
% - RPM
% - RPMSTD
% - OPTIPITCH
% Noise outputs are included as structs and named with their respective names.

% Import Data from Power curve file
fid = fopen(fname,'r'); % open file
tline = 'temp';
while isstr(tline)
    tline=fgets(fid);
    if isstr(tline)
        if strmatch('#POWER',tline)
            data = getLocalData(fid,'%f %f');
            PCFile.Power.Wind=data{1};
            PCFile.Power.Power=data{2};
        elseif strmatch('#AEP',tline)
            ReadingAEP = 1;
            IECFound = 0;
            PCFile.AEP = {};
            while ReadingAEP
                tline=fgets(fid);
                if strfind(tline,'IEC')
                    IECFound = 1;
                    TempLine = strtrim(tline);
                    idx = strfind(TempLine,' ');
                    PCFile.AEP{end+1}.IECClass = TempLine(1:idx(2));
                    PCFile.AEP{end}.AEP = str2num(TempLine(idx(end):end));
                end
                if IECFound
                    if isempty(strfind(tline,'IEC'))
                        ReadingAEP = 0;
                    end
                end
            end
        elseif strmatch('#CT',tline)
            data = getLocalData(fid,'%f %f');
            PCFile.CT.Wind=data{1};
            PCFile.CT.CT=data{2};
        elseif strmatch('#PITCH',strtrim(tline),'exact')
            data = getLocalData(fid,'%f %f');
            PCFile.Pitch.Wind=data{1};
            PCFile.Pitch.Pitch=data{2};
        elseif strmatch('#PITCH_STD',strtrim(tline),'exact')
            data = getLocalData(fid,'%f %f');
            PCFile.PitchSTD.Wind=data{1};
            PCFile.PitchSTD.PitchSTD=data{2};
        elseif strmatch('#RPM',strtrim(tline),'exact')
            data = getLocalData(fid,'%f %f');
            PCFile.RPM.Wind=data{1};
            PCFile.RPM.RPM=data{2};
        elseif strmatch('#RPM_STD',strtrim(tline),'exact')
            data = getLocalData(fid,'%f %f');
            PCFile.RPMSTD.Wind=data{1};
            PCFile.RPMSTD.RPMSTD=data{2};
        elseif strmatch('#OPTIPITCH',tline)
            data = getLocalData(fid,'%f %f');
            PCFile.OPTIPITCH.Wind=data{1};
            PCFile.OPTIPITCH.OPTIPITCH=data{2};
        end
    end
end

fclose(fid);  % close file

%% Extracting noise equations
% opening, reading and closing file
fid=fopen(fname,'rt');
data=textscan(fid,'%s','delimiter','\n');
fclose(fid);
fileContent=data{1};
noiseIdx=find(strcmp(fileContent,'#NOISE_EQS'),1,'first'); % position of Noise equation

% position of noise data
i = 1;
if ~isempty(noiseIdx)
    [posNoise,noiseTags,noiseName] = deal([]);
    while ~isempty(strfind(fileContent{noiseIdx+i+4},' '))
        posNoise{i} = find(strcmp(fileContent,num2str(['#NOISE_',fileContent{noiseIdx+i+4}(1:(strfind(fileContent{noiseIdx+i+4},' '))-1)])),1,'first'); 
        noiseTags{i} = strsplit_LMT(fileContent{noiseIdx+i+4},' ');
        noiseName{i} = noiseTags{i}(1);
        i = i+1;
    end
end

% extracting Noise
if ~isempty(noiseIdx)
    for j=1:length(posNoise)       
        k = 1;
        noise_columns{j} = strsplit_LMT(fileContent{posNoise{j}+3});
        while strfind(fileContent{posNoise{j}+5+k},' ')
            noise{j}(k,:) = textscan(fileContent{posNoise{j}+5+k},'%f %f %f %f %f',1);
            k = k + 1;
        end
    end
else
    warning(['#NOISE_EQS tag not found in ' Filename])
end

if exist('noise','var') && ~isempty(noise)
    for k = 1:length(noise)
        noiseActual = cell2mat(noise{k});
        for c=1:length(noise_columns{k})
            variableName = matlab.lang.makeValidName(noise_columns{k}{c});
            charNoiseName = matlab.lang.makeValidName(char(noiseName{k}));
            PCFile.(charNoiseName).(variableName) = noiseActual(:,c);
        end
    end
end

%% getLocalData: function description
function data = getLocalData(fid,pattern)
    data = textscan(fid, pattern);
    while isempty(data{1})
        tline=fgets(fid);
        data = textscan(fid, pattern);
    end
end

end

