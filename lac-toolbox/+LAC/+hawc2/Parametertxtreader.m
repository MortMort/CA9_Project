function [HWC]=Parametertxtreader(PSpath)
%% This function reads the parameter file
fileID=fopen([PSpath,'_ParameterStudy.txt']);
PS=textscan(fileID,'%s');
fclose(fileID);

%parameters to update
Para_len=find(contains(PS{1,1},'Par0'));

    for i=1:length(Para_len)-1
        HWC.Para_study_overview{i,1}=PS{1,1}{Para_len(i)}(8:end);
        HWC.Parameter{i,1}=extractBefore(HWC.Para_study_overview{i,1},'=');
        Para_Values_temp{i,1}=extractAfter(HWC.Para_study_overview{i,1},'=');
        HWC.Parameter_Values(i,:)=sscanf(Para_Values_temp{i,1},'%g,',[1,count(HWC.Para_study_overview{1,1},',')+1]);        
    end
end
