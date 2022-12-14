function [folders, values, parameters]=fat1info(simfolder)
% [folders values parameters]=Fat1dat(simfolder)
filename = fullfile(simfolder,'_SimFolderOverview.txt');
fin = fopen(filename);
tline = fgetl(fin);

delimPar=regexp(tline, '[|]');
first=tline(1:delimPar(1)-2);
if strcmpi(first,'ref')
    tline = fgetl(fin);    
end

index=1;
while ischar(tline)   
    delimPar=regexp(tline, '[|]');
    delimEq=regexp(tline, '[=]');
    folders{index}=tline(1:delimPar(1)-2);
    nPar=length(delimPar);
    for i=1:nPar
        parameters{index,i}=tline(delimPar(i)+2:delimEq(i)-2);
        if i==nPar                
            values(index,i)=str2double(tline(delimEq(i)+1:end));
            if values(index,i) == 0 %If value is zero, look in _CtrlParamChange.txt
                CtrParamChangeFileName = fullfile(simfolder,folders{index},'_CtrlParamChanges.txt');
                fID = fopen(CtrParamChangeFileName);
                tParam = fgetl(fID);
                while ischar(tParam)
                    Eq = regexp(tParam, '[=]');
                    if strmatch(strtrim(tParam(1:Eq-1)),parameters{index,i})
                        values(index,i) = str2double(tParam(Eq+1:end));
                    end
                    tParam = fgetl(fID);
                end
                fclose(fID);
            end
        else
            values(index,i)=str2double(tline(delimEq(i)+1:delimPar(i+1)-1));
            if values(index,i) == 0 %If value is zero, look in _CtrlParamChange.txt
                CtrParamChangeFileName = fullfile(simfolder,folders{index},'_CtrlParamChanges.txt');
                fID = fopen(CtrParamChangeFileName);
                tParam = fgetl(fID);
                while ischar(tParam)
                    Eq = regexp(tParam, '[=]');
                    if strmatch(strtrim(tParam(1:Eq-1)),parameters{index,i})
                        values(index,i) = str2double(tParam(Eq+1:end));
                    end
                    tParam = fgetl(fID);
                end
                fclose(fID);
            end
        end
    end
    index=index+1;
    tline = fgetl(fin);
end
fclose(fin);

