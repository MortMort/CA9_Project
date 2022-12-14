function [data]=stareadTL(sensor,directory,dirsearch,saveoption,fatigueoption)
% Read statistical data from sta-files by dir(*.*).
%___________________________TL-TOOLBOX © -STAREAD__________________________
%
%  STAREAD    Read statistical data from sta-files.
%       [data] = stareadTL(sensor,directory); reads statistical data from
%       sta-files in the specified directory. If no directory is specified,
%       the sta-files is sought in the folder location of the m-file.
%       Variable no. of inputs, 2-5. Default values are identical to
%       previous version of staread_TL.
%       
%       Sensor input must be a cell array and directory a string. Data output
%       is in a structure, with the following format
%       
%       data -
%             sensorname (not case sensitive)
%                        * mean 
%                        * std
%                        * max
%                        * min
%             
%       Example: 
%               Load the statistical data for the main bearing torque and
%               the tower top yaw moment.    
%
%       [data] = stareadTL({'Mymbr','Mztt'},'C:\VestasToolbox\TLtoolbox\Example_Inputs\LoadCases_reduced\STA\','11*.sta',false,true)
%      
%       HINTS
%       Define statistical files:
%           files=struct2cell(dir('*.sta'));
%
%       Extract the mean value for a sensor
%           meanvalue=data.sensorname.mean
%       
%       Saving option as pwd 3, default is not saving:
%           sensorname.stt will be written in ascii format
%               mean    std     min     max
%
%       Go backstage by pressing <a href="matlab:
%       open('stareadATL.m')">here</a>.
%--------------------------------------------------------------------------
% Update History
%  *    line 100: senNo changed to senNo+1, since the fist line
%       in FatInfo is the m exponents. 26-08-2010. SORSO

tstart=tic;
if nargin<5
    fatigueoption=false;
end
sensorinput=zeros(1,length(sensor));
%directory={pwd};
if nargin==1
    directory=pwd;
end
dirstart=pwd;
cd(directory)

% Value of interest: 1: mid 2: St.dev. 3: min 4: max 5: max-min
        value_mean=3; value_std=4; value_min=5; value_max=6;

h = waitbar(0,'making dir of sta folder, please wait');
% Reads contents of folder
if  nargin<3 || ~ischar(dirsearch)
    dirsearch='*.sta';
end
files=dir(dirsearch);  % Captures all sta-files
close(h)
[NoStaFiles col]= size(files);
% Data loading
h=waitbar(0);
for l=1:NoStaFiles
    i=0;
    if NoStaFiles>100
        if ~mod(l,3)
            waitbar(l/NoStaFiles,h,['Reading file: ',num2str(l) ' out of ',num2str(NoStaFiles)]);
        end
    else
        waitbar(l/NoStaFiles,h,['Reading file: ',num2str(l) ' out of ',num2str(NoStaFiles)]); % ' out of ',NoStaFiles]
    end
    [StaDat FatInfo]=ReadStaCore(files(l,1).name,fatigueoption);
    
    [NoOfSen col] =size(cell2mat(StaDat(1,1)));
    ChDesc = StaDat(1,2);
    for SenNo=1:NoOfSen
        for p=1:length(sensor)
            if strcmp(lower(ChDesc{1,1}(SenNo)),lower(sensor(p)))       
                sensorinput(p)=SenNo;
                channel{p}=char(ChDesc{1,1}(SenNo));
                
                if strcmp(channel{1,p}(1),'-')
                    ReplaceName=char([channel{p},'_neg']);
                    ReplaceName=ReplaceName(2:end);
                    channel{p}=ReplaceName;
                end
                
                if ~isempty(strfind(channel{1,p},'.'))
                    channel{1,p}=strrep(channel{1,p}, '.', 'p');
                end
               
                data.(channel{1,p}).mean(l,1)=StaDat{1,value_mean}(SenNo);%(startvalue(n),value_mean);
                data.(channel{1,p}).std(l,1)=StaDat{1,value_std}(SenNo);
                data.(channel{1,p}).min(l,1)=StaDat{1,value_min}(SenNo);
                data.(channel{1,p}).max(l,1)=StaDat{1,value_max}(SenNo);
                if fatigueoption
                    data.(channel{1,p}).fatigue(l,:)=FatInfo(SenNo+1,:);
                end
                % data.(channel{1,p}).FatInfo(l,1:8)=FatInfo{1,3}(SenNo,1)
                % if all sensors in sta-file are found, jump to next
                % sta-file
                if p==length(sensor)             
                    continue
                end
               
            end
        end
    end
    data.DLC{l}=files(l).name;
end
data.DLC=data.DLC';
if min(sensorinput)==0
    if find(sensorinput==0)>1
        warndlg(['The requested sensors ',sensor{find(sensorinput==0)},' cannot be found. Check sensor file and sensor input.'])
    else
        warndlg(['The requested sensor ',sensor{find(sensorinput==0)},' cannot be found. Check sensor file and sensor input.'])
    end
end

% saving routine
if nargin>3 && saveoption
    DLCnames(:,1)=data.DLC;
    for j=1:length(sensor)
        waitbar((j-1)/length(sensor),h,'saving files...');
        SaveName(j) = sensor(j);
%         save1(:,value_mean-2) = data.(ChDesc{1,1}{sensorinput(j)}).mean;
%         save1(:,value_max-2) = data.(ChDesc{1,1}{sensorinput(j)}).max;
%         save1(:,value_std-2) = data.(ChDesc{1,1}{sensorinput(j)}).std;
%         save1(:,value_min-2) = data.(ChDesc{1,1}{sensorinput(j)}).min;
%         savename=char([SaveName{j},'.stt'])
%         save(savename, 'save1', '-ascii');
        fid = fopen([SaveName{j}, '.stt'], 'wt');
        fprintf(fid,['Filename            ','mean         ','std          ','min          ', 'max           ','\n']);
        fclose(fid);
        for i=1:NoStaFiles
            fid = fopen([SaveName{j}, '.stt'], 'a+');
            fprintf(fid,[DLCnames{i},'  ',...
                num2str(data.(char(channel(j))).mean(i),'%12.3E'),'  ', ...
                num2str(data.(char(channel(j))).std(i),'%12.3E'),'  '...
                num2str(data.(char(channel(j))).max(i),'%12.3E'),'  '...
                num2str(data.(char(channel(j))).min(i),'%12.3E'),'  ','\n']);
            fclose(fid);
        end
    end
    
    
    % a_str = strrep(a_str,'e+0','e+');
    % a_str = strrep(a_str,'e-0','e-');
    %DLCnames(:,1)=data.DLC
    %test=char(data.DLC(:))
    %save('filenames.txt', 'test', '-ascii');
    
%     fid = fopen('V60_DLC.txt', 'wt');
% numit=1;
% for i = 1:numer
%     fprintf(fid,[DLC_name{i} ' wsp=',num2str(wind_speed(i),'%2.1f'),' wdir=',num2str(wdir_sorted(numer),'%2.1f'),'\n']);
% end
end
telapsed=toc(tstart);
waitbar(l/length(files),h,['Time used: ',num2str(telapsed),' second.']);
pause(1.5);
delete(h);
cd(dirstart)


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

