function [StaInfo WohlerMatrix]=ReadStaCore(StaFile,fatigue)
% reads stafiles
fid = fopen(StaFile);
NoHeader =11;
% scanning sta-file until format changes at 1Hz loads in sta-file
StaInfo=textscan(fid,'%f %s %f %f %f %f %f %s','headerlines',NoHeader);
if ~StaInfo{1,1}(1)==1
    error('Sta file format not recognized')
end
if StaInfo{1,1}(end,1)==1
    StaInfo{1,1}=StaInfo{1,1}(1:end-1,1);
    StaInfo{1,2}=StaInfo{1,2}(1:end-1,1);
end

fclose(fid);
%% reading fatigue eq. loads
if nargin==2 && fatigue
    fid = fopen(StaFile);
    NoHeaderFat =NoHeader+4+length(StaInfo{1,1}(:,1));
%     Wohler=textscan(fid,'%f %s %f %f %f %f %f %f %f %f','headerlines',NoHeaderFat,'CollectOutput', 1);
%        Wohler1=textscan(fid,'%s %f %f %f %f %f %f %f %f','headerlines',NoHeaderFat-1);
    FatInfo=textscan(fid,'%s %s %f %f %f %f %f %f %f %f','headerlines',NoHeaderFat);
    WohlerMatrix=zeros(length(StaInfo{1,1}(:,1))+1,8); % header of matrix is wöhler slopes
    WohlerMatrix(1,:)=[1,3,4,6,8,10,12,25]; % sorry for the hard coding
    for j=3:10
        for k=1:length(StaInfo{1,1}(:,1))
        WohlerMatrix(k+1,j-2)=FatInfo{1,j}(k,1);
        end
    end
    fclose(fid);
   
else
    WohlerMatrix='';
end