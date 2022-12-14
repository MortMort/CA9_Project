%STAPOST - Object which reads and processes sta-files
%
% SYNTAX:
%   obj = stapost(simulationpath)
%   obj.read()
%
% INPUTS:
%   simulationpath - path to the VTS simulation folder
%
% CLASS METHODS:
%   stapost.read       - reads the stafiles from simulation folder and
%                        store data in the object
%
%   stapost.readfiles  - reads the stafiles specified in input argument
%
%   stapost.save       - saves data from the object into a .mat file
%
%   stapost.load       - loads .mat file into the object
%
%   stapost.calcFamily - calculates design loads according to family method
%   
%
%   stapost.calcEqLoad - calculates the equivalent loads for specified
%                        sensor, load case and wohler coefficient
%
%   stapost.getLoad    - Extract load from stadata and bins to specified
%                        load cases
%
%   stapost.getSumFreq - Calculates the sum of the frequency for the
%                        loadcase filter selected.
%
%   stapost.compareLC  - compares load cases for different stapost
%                        instances.
%
%   stapost.findSensor - find index of sensor name
%
%   stapost.findLC     - find indices of loadcase prefix
%
%   stapost.getSensDat - get location and indices of sensors along blade or
%                        tower
%
%   stapost.stadat2dat - convert stadat data to dat format
%
%   stapost.stadat2matstat - converts stadat to matstat format

%   stapost.plotAoA    - Plot AoA for all sensers along the blade
%
%   stapost.plotBladeLoad - Plot blade load along the blade
%   
%   stapost.plotTowerLoad - Plot tower load along the tower for different
%                           loadcases.
%
%   stapost.plotDeflection -
%
% DATASTRUCTURE:
%   obj.stadat - All statistical data from the sta-files.
%
%   obj.simdat - simulation data, list of input files etc
%
%   obj.info   - info about the data in the object, date, user etc. 
%
%
% EXAMPLES:
% 
%   Read VTS setup:
%   obj        = LAC.vts.stapost('SIMFOLDER')
%   obj.read
%
%   Getload:
%   loadvalues = obj.getLoad('Mxt0','absDesign',{'11','62'})
%
%   Read list of stafiles:
%   obj      = LAC.vts.stapost('SIMFOLDER')
%   stafiles = LAC.dir('SIMFOLDER\STA\11*.sta')
%   sta      = obj.readfiles(stafiles)
%
%
%
% 18/06-2014 - MAARD: V00beta - Not reviewed.
% 15/08-2019 - MISVE: Bumped version to V01 
% V01beta - JADGR
% * Added support for regular expressions in setLCBins
% * Added support for extracting frequency data based on LCBins
% * Added support for mean weighted with frequency in getLoad

classdef stapost < handle
    properties
        stadat;
        simdat=struct('simulationpath','','frqfile','','sensorfile','','setfile','','masfile','')
        info=struct('created',datestr(now),'user',getenv('USERNAME'),'version','V01');
        settings=struct('LCbins',{{'11' '12' '13' '14' '15' '21' '22' '23' '24' '31' '32' '33' '34' '41' '42' '43' '51' '61' '62'}},'loadtype','abs','sensor','Mxt0','plot',true,'plotRatioToRef',true)
    end
    
    methods
        function help(self,method)
            
            if nargin > 1
               eval(sprintf('help LAC.vts.stapost.%s',method)) 
            else
               help LAC.vts.stapost 
            end
        end
        
        
        function self=stapost(simulation)
            if ischar(simulation) % this is the Loads folder
                self.simdat=LAC.vts.simulationdata(simulation);
            else % this is already a LAC.vts.simulationdata
                self.simdat = simulation;
            end
        end
        
        
        function sta=read(self,varargin)
            % sta=read(self,varargin)
            %
            % DESCRIPTION:
            %   Read all stafiles in simulation folder and store it in the
            %   object. If a current stapost.m file exist, this file will be loaded
            %   instead.
            %
            % INPUTS:
            %   forceread        - optional argument. Value 1 = read regardless if
            %                       stapost.m file exist. set input to read(1)
            %   GiveSelectBox    - optional argument. set read('GiveSelectBox',1) to
            %                       recive a select box to decide if the datafile should
            %                       be updated with new data in the case
            %                       where the data is outdated.
            %   ForceReadOldData - optional argument. set read('ForceReadOldData',1) to
            %                       update datafile in the case where the data file
            %                       is outdated.
            
            % default values if no inputs are given. read()
            forceread           = 0;
            giveselectbox       = false;
            forcereadolddata    = false;

            if ~isempty(varargin)
                if isnumeric(varargin{1})
                    forceread = varargin{1};
                else
                    while ~isempty(varargin)
                        switch lower(varargin{1})
                            case 'giveselectbox'
                                giveselectbox = varargin{2};
                                varargin(1:2) = [];
                            case 'forcereadolddata'
                                forcereadolddata = varargin{2};
                                varargin(1:2) = [];
                            otherwise
                                error(['Unexpected option: ' varargin{1}])
                        end
                    end
                end
            end

            
            sensor_file=fullfile(self.simdat.simulationpath,'INT','sensor');
            stapostLoaded = false;
            if exist(fullfile(self.simdat.simulationpath,'stapost.mat'), 'file') && forceread==0
                if exist(sensor_file,'file')
                    temp=dir(sensor_file);
                    dateSens=temp.date;
                    stapostLoaded = self.load(fullfile(self.simdat.simulationpath,'stapost.mat'));
                    self.info.created;
                    if datenum(dateSens)>datenum(self.info.created)
                        if forcereadolddata
                            clear stapostLoaded;
                            stapostLoaded = false;
                        else
                            warning('Simulation has been changed after stapost.mat creation. Consider reading STA-files again!')
                            if giveselectbox
                                answer = questdlg('Would you like to re-read STA-files again?', ...
                                'Simulation has been changed after stapost.mat creation', ...
                                'yes','no','no');
                                if strcmp(answer,'yes')
                                    clear stapostLoaded;
                                    stapostLoaded = false;
                                end
                            end
                        end
                    end
                else
                    stapostLoaded = self.load(fullfile(self.simdat.simulationpath,'stapost.mat'));
                end
            end    
            if(~stapostLoaded)
                %% Read simulation files
                if isempty(self.simdat.frqfile)
                    error('Frequency file not available in %s',fullfile(self.simdat.simulationpath,'INPUTS'))
                end
                % Frequency info
                frq = LAC.vts.convert(fullfile(self.simdat.simulationpath,'INPUTS',self.simdat.frqfile));            

                           
                %% Loop over stafiles
                filelist = strrep(frq.LC,'.int','.sta')';
                [sta, nomiss] = self.readfiles(filelist);

                self.stadat.filenames  = frq.LC;
                self.stadat.frq        = frq.frq;
                self.stadat.hour       = frq.time;
                self.stadat.family     = frq.family;
                self.stadat.PLF        = frq.LF;
                self.stadat.method     = frq.method;
                if nomiss
                    self.save;
                end
            end
        end
        function [sta, nomiss]=readfiles(self,staFilelist)
            % sta=stapost.readfiles(filenames)
            %
            % DESCRIPTION:
            %   Read all stafiles specified in the input from the
            %   simulation foler
            %
            % INPUTS:
            %   filenames - cell arry of stafilenames
            %
            % EXAMPLE:
            %   object   = LAC.vts.stapost('SIMFOLDER')
            %   stafiles = dir('SIMFOLDER\STA\11*.sta')
            %   sta      = object.readfiles({stafiles.name})
            %
            isfirstfile = true;
            if size(staFilelist,1)==1
                % Scan for files using java.io
                jFile = java.io.File(fullfile(self.simdat.simulationpath),'STA');
                allTracksJ = char(jFile.list);
                regStr = ['^',strrep(strrep([staFilelist '.sta'],'?','.'),'*','.{0,}'),'$'];
                starts = regexpi(cellstr(allTracksJ), regStr);
                idxFiles = ~cellfun(@isempty, starts);
                
                if max(idxFiles) > 0
                    staFilelist = cellstr(allTracksJ(idxFiles,:));
                else                     
                    error('No Sta-files with preffix ''%s'' found!',staFilelist)
                    staFilelist ={};
                end
            end
            
            % Loop over stafiles
            nomiss   = true;
            t        = zeros(length(staFilelist),1);
            
            for i=1:length(staFilelist)
                tic;
                stafile = fullfile(self.simdat.simulationpath,'STA',staFilelist{i});                
                if ~exist(stafile,'file')
                    stafile = fullfile(self.simdat.simulationpath,'sta',staFilelist{i});
                end                
                if ~exist(stafile,'file')
                    stafile = fullfile(self.simdat.simulationpath,staFilelist{i});
                end                
                if ~exist(stafile,'file')
                    warning('%s does not exist!',stafile)
                    nomiss = false;
                    continue
                end
                
                % Read the sta-file
                try
                    stafileData = LAC.vts.convert(stafile);
                catch e
                    disp(e.getReport())
                    nomiss = false;
                    continue
                end   
                if ~isobject(stafileData)
                    warning('Error reading %s, the file is skipped!',stafile)
                    nomiss = false;
                    continue
                end
                if isfirstfile       
                    sta.mean  = nan(length(stafileData.sensNo),length(staFilelist));
                    sta.std   = nan(length(stafileData.sensNo),length(staFilelist));
                    sta.min   = nan(length(stafileData.sensNo),length(staFilelist));
                    sta.max   = nan(length(stafileData.sensNo),length(staFilelist));
                    sta.eq1hz = nan(length(stafileData.sensNo),length(staFilelist),8);
                    isfirstfile = false;
                end
                % Convert to combined matices
                sta.mean(:,i)   = stafileData.mean;
                sta.std(:,i)    = stafileData.std;
                sta.min(:,i)    = stafileData.min;
                sta.max(:,i)    = stafileData.max;
                sta.eq1hz(:,i,:)= stafileData.eq1hz;
                sta.Neq(i)      = stafileData.Neq;
                
                % Status on reading
                if rem(i,5)==0
                    if i>50
                        disp(sprintf('Reading %i/%i sta-files: %1.0f seconds remaining',i,length(staFilelist),ceil(sum(t(i-49:i))/50*(length(staFilelist)-i))));
                    else
                        disp(sprintf('Reading %i/%i sta-files',i,length(staFilelist)));
                    end
                end
                t(i) = toc;
            end
                        
            % Store data in object and return stadata
            sta.m      = stafileData.m;            
            sta.sensor = stafileData.sensor;
            sta.sensNo = stafileData.sensNo;
            sta.unit   = stafileData.unit; 
            sta.filenames     = staFilelist;
            
            self.stadat       = sta;
            self.info.created = datestr(now);
        end
        
        function calcFamily(self,savemat)
            % obj.calcFamily(savemat) 
            % 
            % DESCRIPTION:
            %   Calculates the design loads based on family method.
            %
            % OPTIONAL INPUTS:
            %   savemat - save to stapost.mat. Default is 'true'
            %
            % OUTPUT:
            %   obj.stadat.maxDesign - Max designload
            %   obj.stadat.minDesign - Min designload

            if nargin == 1
                savemat = true;
            end
            
            fprintf('Calculating family method...\n')
            
            % Initialize variables
            family  = self.stadat.family;
            method  = self.stadat.method;
            plf     = self.stadat.PLF;
            
            meanRaw = self.stadat.mean;
            stdRaw  = self.stadat.std;
            maxRaw  = self.stadat.max;
            minRaw  = self.stadat.min;
%             eq1hzRaw = self.stadat.eq1hz;
            
%             wohler = self.stadat.m;
%             frq = self.stadat.frq;
%             duration = self.stadat.Neq
            
            % misc params
            NoFam   = max(family);
            NoChan  = size(maxRaw,1);
            NoFiles = length(family);
            single  =~ (family); % non-families
                    
            meanFamily = nan(size(meanRaw));
            stdFamily = nan(size(stdRaw));    
            maxFamily = nan(size(maxRaw));
            minFamily = nan(size(minRaw));
            
            meanDesign = nan(size(meanRaw));
            stdDesign = nan(size(stdRaw));
            maxDesign = nan(size(maxRaw));            
            minDesign = nan(size(minRaw));
            
%             eq1hzRawFamily = nan(size(eq1hzRaw));
%             eq1hzRawDesign = nan(size(eq1hzRaw));
            
            % calculating non-family loads
            if max(single)
                for j=1:NoChan                 
                    meanFamily(j,:) = single.*meanRaw(j,:); % mean
                    stdFamily(j,:)  = single.*stdRaw(j,:);  % std
                    maxFamily(j,:)  = single.*maxRaw(j,:);  % max
                    minFamily(j,:)  = single.*minRaw(j,:);  % min
                    
                    meanDesign(j,:) = plf.*meanFamily(j,:); % mean design
                    stdDesign(j,:)  = plf.*stdFamily(j,:);  % std design
                    maxDesign(j,:)  = plf.*maxFamily(j,:);  % max design
                    minDesign(j,:)  = plf.*minFamily(j,:);  % min design
                    
%                     for k=1:length(wohler)
%                         eq1hzRawFamily(j,:,k) = power(eq1hzRaw(j,:,k),wohler(k)) * ;
%                     end    
                end
            end            
            % calculating family loads
            for j=1:NoFam
                iMembers=find(family==j);
                if ~isempty(iMembers)
                    MeanVal = meanRaw(:,iMembers)';
                    StdVal = stdRaw(:,iMembers)';
                    MinVal = minRaw(:,iMembers)';
                    MaxVal = maxRaw(:,iMembers)';
                    
                    if length(iMembers)>1.5
                        resMean = mean(MeanVal(1:length(iMembers),:),1);
                        resStd = mean(StdVal(1:length(iMembers),:),1);
                        
                        if mean(method(iMembers))==1 % Calculation method-1 family loads
                            resMin = mean(MinVal(1:length(iMembers),:),1);
                            resMax = mean(MaxVal(1:length(iMembers),:),1);
                                                        
%                             maxStd = std(SortMax(1:length(iMembers),:),1);
%                             minStd = std(SortMin(1:length(iMembers),:),1);

                        elseif mean(method(iMembers))==2 % Calculation method-2 family loads
                            SortMin=sort(MinVal,'ascend');
                            SortMax=sort(MaxVal,'descend');
                            
                            resMin=mean(SortMin(1:round(length(iMembers)/2),:),1);
                            resMax=mean(SortMax(1:round(length(iMembers)/2),:),1);
                            
%                             maxStd = std(SortMax(1:round(length(iMembers)/2),:),1);
%                             minStd = std(SortMin(1:round(length(iMembers)/2),:),1);
                        
                        elseif mean(method(iMembers))==3 % Calculation method-3 family loads                
                            meanMin = mean(MinVal(1:length(iMembers),:),1);
                            meanMax = mean(MaxVal(1:length(iMembers),:),1);
                            
                            stdMin = std(MinVal(1:length(iMembers),:),0);
                            stdMax = std(MaxVal(1:length(iMembers),:),0);
                            
                            resMin = meanMin - 3*stdMin;
                            resMax = meanMax + 3*stdMax;
                        end
                    else % only one seed
                        resMax=MaxVal;
                        resMin=MinVal;
                        resMean=MeanVal;
                        resStd=zeros(size(StdVal));
                    end
                        
                    for m=1:NoChan     
                        meanFamily(m,iMembers)=resMean(m); % family max
                        meanDesign(m,iMembers)=resMean(m)*plf(iMembers); % design max 
                        
                        stdFamily(m,iMembers)=resStd(m); % family max
                        stdDesign(m,iMembers)=resStd(m)*plf(iMembers); % design max 

                        minFamily(m,iMembers)=resMin(m); % family min 
                        minDesign(m,iMembers)=resMin(m)*plf(iMembers); % design min
                        
                        maxFamily(m,iMembers)=resMax(m); % family max
                        maxDesign(m,iMembers)=resMax(m)*plf(iMembers); % design max 

                        
%                         maxFamilyStd(m,iMembers)=maxStd(m);
%                         minFamilyStd(m,iMembers)=minStd(m);
                    end                    
                    
                end
            end
            self.stadat.meanFamily = meanFamily;
            self.stadat.meanDesign = meanDesign;
            
            self.stadat.stdFamily = stdFamily;
            self.stadat.stdDesign = stdDesign;
            
            self.stadat.minFamily = minFamily;
            self.stadat.minDesign = minDesign;
            
            self.stadat.maxFamily = maxFamily;
            self.stadat.maxDesign = maxDesign;
            
            %self.stadat.nSeeds = length(iMembers);
            if savemat
                self.save;
            end
        end
        function Leq=calcEqLoad(self,sensor,m,selection)
            % Leq = stapost.calcEqLoad(sensor,m,selection)
            % 
            % DESCRIPTION:
            %   Sum the equivalent loads for a selection of loadcases based 
            %   on the frequency of the load cases.
            %   The load cases can either be defined as the first letters in
            %   the loadcase name or as the index of the load cases which
            %   should be summed.
            % 
            % INPUTS:
            %
            % OUTPUTS:
            %
            
            if nargin>3
                if isnumeric(selection)
                    iLoadcase = selection;
                else
                    if strncmp(selection,'*',1)||strncmpi(selection,'all',3)
                        iLoadcase = true(length(self.stadat.filenames),1);
                    else
                        iLoadcase = strncmp(self.stadat.filenames,selection,length(selection));
                    end
                end
            else
                iLoadcase = true(length(self.stadat.filenames),1);
            end
            if isnumeric(sensor)
                iSensor = sensor;
            elseif ischar(sensor)
                iSensor = find(strcmpi(sensor,self.stadat.sensor));
            end
            m_i = self.stadat.m==m;
            if isempty(find(m_i,1))
                error('Wohler selection not available.')
            end
            Nref=1e7;
            Li  = self.stadat.eq1hz(iSensor,iLoadcase,m_i);
            ni  = round(3600*self.stadat.hour(iLoadcase));
            Leq = (nansum(ni.*Li.^m)/Nref)^(1/m);
        end
               
        function [index,name]=findSensor(self,sensor,searchtype)
            if nargin == 3 && strcmp(searchtype,'exact')
                index = find(strcmp(self.stadat.sensor, sensor));                  
            else            
                index = find(not(cellfun('isempty', strfind(self.stadat.sensor, sensor))));   
            end
            if isempty(index)
                error('Sensor not found!')
            else
                name=self.stadat.sensor(index);
            end
            
        end
        
        function iLoadcase = findLC(self,loadcases)
            iLoadcase = strncmp(self.stadat.filenames,loadcases,length(loadcases));
            if isempty(iLoadcase)
                error('LoadCase not found..')
            end
            
        end
        
        function loadvalues = getLoad(self,sensor,loadtype,loadcases)
            % load=stapost.getLoad(self,sensor,loadtype,LC)
            %
            % DESCRIPTION:
            % Get load for specified loadcases and sensor
            %
            % INPUTS:
            %   sensor - sensor name or sensor number acc. to sensor file
            %
            %   loadtype
            %       std     - mean(std_values)
            %       max     - max(max_values)
            %       min     - min(min_values)
            %       abs     - max(abs(max_values),abs(min_values))
            %       mean    - mean(mean_values)
            %       fat4    - summed fatigue load, wohler 4
            %       fat8    - summed fatigue load, wohler 8
            %       fat10   - summed fatigue load, wohler 10
            %       fat12   - summed fatigue load, wohler 12
            %       eq1hz1  - mean(eq1hz1)
            %       eq1hz4  - mean(eq1hz4)
            %       eq1hz8  - mean(eq1hz8)
            %       eq1hz10 - mean(eq1hz10)
            %       eq1hz12 - mean(eq1hz12)
            %       minDesign - min(minDesign_values)
            %       maxDesign - max(minDesign_values)
            %       absDesign - max(abs(maxDesign_values),abs(minDesign_values))
            %       minFamily - min(minFamily_values)
            %       maxFamily - max(minFamily_values)
            %       absFamily - max(abs(maxFamily_values),abs(minFamily_values))
            %       meanmax   - mean(max_values)
            %       meanmin   - mean(min_values)
            %       meanabs   - mean(abs_values)
            %       stdmax    - std(max_values)
            %       meanFrq   - summed mean weighted with frequency
            %
            %   LC - Load cases, cell structure e.g. {'11','12','13'}
            %
            % OUTPUTS:
            %   load - load value, array with value for each loadcase
            %
            % EXAMPLE:
            %   obj        = LAC.vts.stapost('SIMFOLDER')
            %   obj.read
            %   loadvalues = getLoad('Mxt0','absDesign',{'11','62'})
            %
            
            if isnumeric(sensor)
                iSensor = sensor;
            elseif ischar(sensor)
                iSensor=find(strcmpi(sensor,self.stadat.sensor));
                if isempty(iSensor)
                    error('Sensor not found..')
                end
                if length(iSensor)>1
                    warning('More than one sensor match found! Extracting first match..')
                    iSensor = iSensor(1);
                end
            end
            loadvalues = nan(1,length(loadcases));
            for i=1:length(loadcases)
                if strncmp(loadcases{i},'*',1)||strncmpi(loadcases{i},'all',3)
                    iLoadcase = true(length(self.stadat.filenames),1);
                else
                    iLoadcase = strncmp(self.stadat.filenames,loadcases{i},length(loadcases{i}));
                end
                
                if any(iLoadcase==1)                
                    switch loadtype
                        case 'std'
                            % Law of combined variances - mean of variances
                            loadvalues(i)=sqrt(mean(self.stadat.std(iSensor,iLoadcase),'omitnan').^2);
                        case 'max'
                            loadvalues(i)=max(self.stadat.max(iSensor,iLoadcase));
                        case 'min'
                            loadvalues(i)=min(self.stadat.min(iSensor,iLoadcase));
                        case 'abs'
                            loadvalues(i)=max(abs(max(self.stadat.max(iSensor,iLoadcase))),abs(min(self.stadat.min(iSensor,iLoadcase))));
                        case 'mean'
                            %FACAP. 05.08.2014, max --> mean
                            loadvalues(i)=mean(self.stadat.mean(iSensor,iLoadcase),'omitnan');
                        case 'fat1'
                            loadvalues(i)=self.calcEqLoad(sensor,1,loadcases{i});
                        case 'fat3'
                            loadvalues(i)=self.calcEqLoad(sensor,3,loadcases{i});
                        case 'fat4'
                            loadvalues(i)=self.calcEqLoad(sensor,4,loadcases{i});
                        case 'fat6'
                            loadvalues(i)=self.calcEqLoad(sensor,6,loadcases{i});
                        case 'fat8'
                            loadvalues(i)=self.calcEqLoad(sensor,8,loadcases{i});
                        case 'fat10'
                            loadvalues(i)=self.calcEqLoad(sensor,10,loadcases{i});
                        case 'fat12'
                            loadvalues(i)=self.calcEqLoad(sensor,12,loadcases{i});
                        case 'fat25'
                            loadvalues(i)=self.calcEqLoad(sensor,25,loadcases{i});
                        case 'eq1hz1'
                            iWhoeler=self.stadat.m==1;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz3'
                            iWhoeler=self.stadat.m==3;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz4'
                            iWhoeler=self.stadat.m==4;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz6'
                            iWhoeler=self.stadat.m==6;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz8'
                            iWhoeler=self.stadat.m==8;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz10'
                            iWhoeler=self.stadat.m==10;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');
                        case 'eq1hz12'
                            iWhoeler=self.stadat.m==12;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan');      
                        case 'eq1hz25'
                            iWhoeler=self.stadat.m==25;
                            loadvalues(i)=mean(self.stadat.eq1hz(iSensor,iLoadcase,iWhoeler),'omitnan'); 
                        case 'maxDesign'
                            if ~isfield(self.stadat,'maxDesign')
                                self.calcFamily;
                            end
                            loadvalues(i)=max(self.stadat.maxDesign(iSensor,iLoadcase));                        
                        case 'minDesign'
                            if ~isfield(self.stadat,'minDesign')
                                self.calcFamily;
                            end
                            loadvalues(i)=min(self.stadat.minDesign(iSensor,iLoadcase)); 
                        case 'absDesign'
                            if ~isfield(self.stadat,'minDesign')||~isfield(self.stadat,'maxDesign')
                                self.calcFamily;
                            end
                            loadvalues(i)=max(abs(max(self.stadat.maxDesign(iSensor,iLoadcase))),abs(min(self.stadat.minDesign(iSensor,iLoadcase))));
                        case 'maxFamily'
                            if ~isfield(self.stadat,'maxFamily')
                                self.calcFamily;
                            end
                            loadvalues(i)=max(self.stadat.maxFamily(iSensor,iLoadcase));                        
                        case 'minFamily'
                            if ~isfield(self.stadat,'minFamily')
                                self.calcFamily;
                            end
                            loadvalues(i)=min(self.stadat.minFamily(iSensor,iLoadcase)); 
                        case 'absFamily'
                            if ~isfield(self.stadat,'maxFamily')||~isfield(self.stadat,'minFamily')
                                self.calcFamily;
                            end
                            loadvalues(i)=max(abs(max(self.stadat.maxFamily(iSensor,iLoadcase))),abs(min(self.stadat.minFamily(iSensor,iLoadcase))));  
                         case 'meanmax'
                            loadvalues(i)=mean(self.stadat.max(iSensor,iLoadcase),'omitnan');
                         case 'meanmin'
                            loadvalues(i)=mean(self.stadat.min(iSensor,iLoadcase),'omitnan');
                         case 'meanabs'
                            loadvalues(i)=mean(self.stadat.abs(iSensor,iLoadcase),'omitnan');
                        case 'stdmax'
                            loadvalues(i)=std(self.stadat.max(iSensor,iLoadcase),1);
                        case 'meanFrq'
                            loadvalues(i)=nansum(self.weightMean(iSensor,iLoadcase));
                        otherwise
                            error('Loadtype not found')
                    end     
                end
            end
        end
        
        function frq=getSumFreq(self,loadcases)
            % frq=staPost.getSumFreq(loadcases)
            %
            % DESCRIPTION:
            %   Calculates the sum of frequencies for the loadcases
            %   specified
            %
            % INPUTS:
            %   loadcases - Load cases, cell structure e.g. {'11','12','13'}
            %
            % EXAMPLE:
            %   object   = LAC.vts.stapost('SIMFOLDER')
            %   sta      = object.readfiles({stafiles.name})
            %   f=sta.getSumFreq(sta.setLCbins('NTM'));
            for i=1:length(loadcases)
                if strncmp(loadcases{i},'*',1)||strncmpi(loadcases{i},'all',3)
                    iLoadcase = true(length(self.stadat.filenames),1);
                else
                    iLoadcase = strncmp(self.stadat.filenames,loadcases{i},length(loadcases{i}));
                end
                frq(i)  = sum(3600*self.stadat.hour(iLoadcase));
            end
        end
        
        function [referenceLoads, outputLoads]=compareLC(self,varargin)
            % [ref out]=stapost.compareLC(stapost_objects)
            %
            % DESCRIPTION:
            %   Compare specified simulation loads with settings from
            %   stapost.LC.
            %
            % INPUTS:
            %   stapost_objects - any number of stapost objects, which
            %                     shall be used for comparing.
            referenceLoads = self.getLoad(self.settings.sensor,self.settings.loadtype,self.settings.LCbins);
            legendStr = {self.simdat.simulationpath};
            for i=1:length(varargin)
                if isempty(varargin{i}.stadat)
                    varargin{i}.read;
                end
                outputLoads(i,:)=varargin{i}.getLoad(self.settings.sensor,self.settings.loadtype,self.settings.LCbins);
                legendStr{end+1}=varargin{i}.simdat.simulationpath;
                
            end
            if self.settings.plot
                % Plot figure
                f=figure;
                set(f,'color','white'); set(f, 'Position', [120 75 1100 800]);
                subplot(5,1,1:4)
                if ~self.settings.plotRatioToRef
                    bar([referenceLoads; outputLoads]'); grid on;
                else
                    barVal = [referenceLoads./referenceLoads; outputLoads./repmat(referenceLoads,size(outputLoads,1),1)]';
                    barVal(isnan(barVal)) = 1;
                    barVal(isinf(barVal)) = 1;
                    hBars = bar(barVal); grid on;
                    set(hBars(1),'BaseValue',1);
                    hBaseline = get(hBars(1),'BaseLine');
                    set(hBaseline,'LineStyle',':',...
                        'Color','red',...
                        'LineWidth',2);
                end
                legend(legendStr,'location','Best')
                ylabel([self.settings.loadtype '@' self.settings.sensor]);
                
                
                Xt = 1:1:length(self.settings.LCbins);
                Xl = [0.5 length(self.settings.LCbins)+0.5];
                set(gca,'XTick',Xt,'XLim',Xl);
                ax = axis; % Current axis limits
                axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
                Yl = ax(3:4); % Y-axis limits
                
                % Place the text labels
                t = text(Xt,Yl(1)*ones(1,length(Xt)),self.settings.LCbins);
                set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
                    'Rotation',45);
                % Remove the default labels
                set(gca,'XTickLabel','')               
                if ~self.settings.plotRatioToRef
                    uitable('Data', [referenceLoads; outputLoads], 'ColumnName', self.settings.LCbins, 'Position', [30 20 990 120]);
                else
                    uitable('Data', [referenceLoads; outputLoads./repmat(referenceLoads,size(outputLoads,1),1)], 'ColumnName', self.settings.LCbins, 'Position', [30 20 990 120]);
                end
            end
        end
        
        
        function save(self,savefile)
            if nargin == 1
                savefile = 'stapost.mat';
            end
            fprintf('Saving data to %s...\n',fullfile(self.simdat.simulationpath,savefile))
            export.simdat = self.simdat; 
            export.stadat = self.stadat; 
            export.info   = self.info;
            save(fullfile(self.simdat.simulationpath,savefile), 'export');
        end
        
        
        function loaded = load(self,filename)
            fprintf('Loading %s...\n',filename)
            load(filename)
            % In some folders there will be several master files and frequency
            % files. The saved stapost.mat file needs to correspond to the
            % same master and frequency files that are requested. Otherwise
            % the STA files will be reloaded.
            if(~strcmpi(self.simdat.masfile,export.simdat.masfile))
                warning('Master file differs between saved stapost file and current instance. STA files will be reloaded.\n%s\n%s',['Current: ' self.simdat.masfile],['Saved:   ' export.simdat.masfile] )
                loaded = false;
                return 
            end
            if(~strcmpi(self.simdat.frqfile,export.simdat.frqfile))
                warning('Frequency file differs between saved stapost file and current instance. STA files will be reloaded.\n%s\n%s',['Current: ' self.simdat.frqfile],['Saved:   ' export.simdat.frqfile] )
                loaded = false;
                return 
            end
            self.stadat = export.stadat; 
            self.info   = export.info;
            
            % Treat legacy
            if isempty(export.simdat)
               self.save
            end
            loaded = true;
        end
        
        function plotAoA(self)
            [posAoA1, index]=self.getSensDat('AoA1');            
            for i=1:length(index)
                AoA1(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posAoA2, index]=self.getSensDat('AoA2');            
            for i=1:length(index)
                AoA2(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posAoA3, index]=self.getSensDat('AoA3');            
            for i=1:length(index)
                AoA3(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            

            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 800]);
            h1(1)=subplot(311);
            plot(posAoA1,AoA1,'-*'); grid on;      
            ylabel('AoA1')
            legend(self.settings.LCbins)
            
            h1(2)=subplot(312);
            plot(posAoA2,AoA2,'-*'); grid on;
            ylabel('AoA2')
            
            h1(3)=subplot(313);
            plot(posAoA3,AoA3,'-*'); grid on;
            xlabel('Blade Length [m]'); ylabel('AoA3')
            legend(self.settings.LCbins)
            linkaxes(h1,'xy')
          
            
        end
        function [pos, val] = plotDeflection(self)
            [posUx1, index]=self.getSensDat('ux1');            
            for i=1:length(index)
                Ux1(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posUx2, index]=self.getSensDat('ux2');            
            for i=1:length(index)
                Ux2(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posUx3, index]=self.getSensDat('ux3');            
            for i=1:length(index)
                Ux3(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            

            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 700]);
            h1(1)=subplot(311);
            plot(posUx1,Ux1,'-*'); grid on;      
            ylabel('Ux 1')
            legend(self.settings.LCbins)
            
            h1(2)=subplot(312);
            plot(posUx2,Ux2,'-*'); grid on;
            ylabel('Ux 2')
            
            h1(3)=subplot(313);
            plot(posUx3,Ux3,'-*'); grid on;
            xlabel('Blade Length [m]'); ylabel('Ux 3')
            legend(self.settings.LCbins)
            linkaxes(h1,'xy')
            
            [posUy1, index]=self.getSensDat('uy1');            
            for i=1:length(index)
                Uy1(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posUy2, index]=self.getSensDat('uy2');            
            for i=1:length(index)
                Uy2(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posUy3, index]=self.getSensDat('uy3');            
            for i=1:length(index)
                Uy3(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            

            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 700]);
            h1(1)=subplot(311);
            plot(posUy1,Uy1,'-*'); grid on;      
            ylabel('Uy 1')
            legend(self.settings.LCbins)
            
            h1(2)=subplot(312);
            plot(posUy2,Uy2,'-*'); grid on;
            ylabel('Uy 2')
            
            h1(3)=subplot(313);
            plot(posUy3,Uy3,'-*'); grid on;
            xlabel('Blade Length [m]'); ylabel('Uy 3')
            legend(self.settings.LCbins)
            linkaxes(h1,'xy')
            
            pos.uy1 = posUy1;
            pos.uy2 = posUy2;
            pos.uy3 = posUy3;
            
            pos.ux1 = posUx1;
            pos.ux2 = posUx2;
            pos.ux3 = posUx3;
            
            val.uy1 = Uy1;
            val.uy2 = Uy2;
            val.uy3 = Uy3;
            
            val.ux1 = Ux1;
            val.ux2 = Ux2;
            val.ux3 = Ux3;
        end
        function [pos, Mxt, Myt, Mbt] = getTowerLoad(self)
            
            % Get index and position for Mxt
            [posMxt, index]=self.getSensDat('Mxt');            
            for i=1:length(index)
                Mxt(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            % Get index and position for Mbt
            [posMxt, index]=self.getSensDat('Mbt');            
            for i=1:length(index)
                Mbt(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            % Get index and position for Myt
            [posMyt, index]=self.getSensDat('Myt');            
            for i=1:length(index)
                Myt(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            pos = posMyt;
            
        end
        function plotTowerLoad(self)
            
           
            [pos, Mxt, Myt] = self.getTowerLoad(self);
            
            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 800]);
            subplot(121)
            plot(Mxt,pos,'-*'); grid on;
            xlabel('Mxt'); ylabel('Tower Height [m]')
            
            subplot(122)
            plot(Myt,pos,'-*'); grid on;
            xlabel('Myt')
            legend(self.settings.LCbins)
            
        end
        
        
        function output=plotBladeLoad(self)                
            [posMx1, index]=self.getSensDat('Mx1');            
            for i=1:length(index)
                Mx1(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posMx2, index]=self.getSensDat('Mx2');            
            for i=1:length(index)
                Mx2(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posMx3, index]=self.getSensDat('Mx3');            
            for i=1:length(index)
                Mx3(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posMy1, index]=self.getSensDat('My1');            
            for i=1:length(index)
                My1(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posMy2, index]=self.getSensDat('My2');            
            for i=1:length(index)
                My2(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end
            
            [posMy3, index]=self.getSensDat('My3');            
            for i=1:length(index)
                My3(i,:)=self.getLoad(index(i),self.settings.loadtype,self.settings.LCbins);
            end

            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 800]);
            h1(1)=subplot(311);
            plot(posMx1,Mx1,'-*'); grid on;      
            ylabel('Mx1')
            legend(self.settings.LCbins)
            
            h1(2)=subplot(312);
            plot(posMx2,Mx2,'-*'); grid on;
            ylabel('Mx2')
            
            h1(3)=subplot(313);
            plot(posMx3,Mx3,'-*'); grid on;
            xlabel('Blade Length [m]'); ylabel('Mx3')
            legend(self.settings.LCbins)
            linkaxes(h1,'xy')
            
            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 800 800]);
            h2(1)=subplot(311);
            plot(posMx1,My1,'-*'); grid on;      
            ylabel('My1')
            legend(self.settings.LCbins)
            
            h2(2)=subplot(312);
            plot(posMx2,My2,'-*'); grid on;
            ylabel('My2')
            
            h2(3)=subplot(313);
            plot(posMx3,My3,'-*'); grid on;
            xlabel('Blade Length [m]'); ylabel('My3')
            linkaxes(h2,'xy')
            
            output = struct('Mx1',Mx1,'Mx2',Mx2,'Mx3',Mx3,'My1',My1,'My2',My2,'My3',My3,...
                            'posMx1',posMx1,'posMx2',posMx2,'posMx3',posMx3,'posMy1',posMy1,'posMy2',posMy2,'posMy3',posMy3);
        end
        
        function [pos, index]=getSensDat(self,sensorsel)           
            % Sensor info
            sensorData = LAC.vts.convert(fullfile(self.simdat.simulationpath,'INT','sensor'));       
            
            pos=[];
            switch sensorsel
                case {'Mxt','Myt','Mzt','Mbt'}
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%f%s');  
                        pos(end+1)=out{3};
                    end
                case {'Mx1','Mx2','Mx3'}
                    index1 = self.findSensor(sensorsel);
                    index2 = find(not(cellfun('isempty', strfind(sensorData.description, 'Flap moment'))));
                    index=intersect(index1,index2);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%f%s');  
                        pos(end+1)=out{4}; 
                    end
                case {'My1','My2','My3'}
                    index1 = self.findSensor(sensorsel);
                    index2 = find(not(cellfun('isempty', strfind(sensorData.description, 'Edge moment'))));
                    index=intersect(index1,index2);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%f%s');  
                        pos(end+1)=out{4}; 
                    end
                case {'AoA1','AoA2','AoA3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%s%f%s');  
                        pos(end+1)=out{5}; 
                    end
                case {'Cl1','Cl2','Cl3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                 
                case {'Cd1','Cd2','Cd3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                    
                case {'T1','T2','T3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                case {'Tw1','Tw2','Tw3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%f');  
                        pos(end+1)=out{3}; 
                    end
                case {'ux1','ux2','ux3'}                                        
                    index = self.findSensor(sensorsel);
                    index = index(2:end);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%s%f');  
                        pos(end+1)=out{5}; 
                    end
                case {'uy1','uy2','uy3'}                                        
                    index = self.findSensor(sensorsel);
                    index = index(2:end);
                    for i=index'
                        out=textscan(sensorData.description{i},'%s%s%s%s%f');  
                        pos(end+1)=out{5}; 
                    end

            end
            
        end
        
        function ref=plotLC(self)
            ref=self.getLoad(self.settings.sensor,self.settings.loadtype,self.settings.LCbins);
            legendstr={self.simdat.simulationpath};
            
            % Plot figure
            f=figure;
            set(f,'color','white'); set(f, 'Position', [120 75 1100 800]);
            subplot(5,1,1:4)
            bar(ref); grid on;
            legend(legendstr,'location','NorthOutside')
            ylabel([self.settings.loadtype '@' self.settings.sensor]);


            Xt = 1:1:length(self.settings.LCbins);
            Xl = [0.5 length(self.settings.LCbins)+0.5];
            set(gca,'XTick',Xt,'XLim',Xl);
            ax = axis; % Current axis limits
            axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
            Yl = ax(3:4); % Y-axis limits

            % Place the text labels
            t = text(Xt,Yl(1)*ones(1,length(Xt)),self.settings.LCbins);
            set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
                'Rotation',45);
            % Remove the default labels
            set(gca,'XTickLabel','')               

            uitable('Data', ref, 'ColumnName', self.settings.LCbins, 'Position', [30 20 990 160]);
        end
        function LCbins = setLCbins(self,lcgroup)
            % Options 
            % NTM - 1104 to 1124 in 2 m/s increments
            % ETM - 1304 to 1324 in 2 m/s increments
            % PC_normal - fat 1 PC sims from 4 m/s to 20 m/s in 0.5 m/s
            %             increments
            % All others - Regular expression
            %            - Example 1: '^(11\d\d).*' is all 11 loadcases
            %              grouped by wind speed
            %            - Example 2: '^(11[\d\.]+q[\d\.]+)\d\d\d.*' all 11
            %              simulations as generated by DLCgenerator grouped
            %              by wind speed and quantiles
            switch lcgroup
                case 'NTM'
                    LCbins = {'1104' '1106' '1108' '1110' '1112' '1114' '1116' '1118' '1120' '1122' '1124'};
                    self.settings.LCbins = LCbins;
                    
                case 'ETM'
                    LCbins = {'1304' '1306' '1308' '1310' '1312' '1314' '1316' '1318' '1320' '1322' '1324'};
                    self.settings.LCbins = LCbins;
                    
                case 'PC_normal'
                    WS_array=4:0.5:20;
                    for iLC = 1:length(WS_array)

                        LCbins{iLC} = sprintf('94_Normal_Rho1.225_Vhfree_%s_',num2str(WS_array(iLC)));    


                    end
                    self.settings.LCbins = LCbins;
                case 'PC'
                    WS_array=4:0.5:20;
                    for iLC = 1:length(WS_array)

                        LCbins{iLC} = sprintf('94_Rho1.225_Vhfree_%s_',num2str(WS_array(iLC)));    


                    end
                    self.settings.LCbins = LCbins;  
                otherwise %assume regex 
                    
                    LCbins=regexp(self.stadat.filenames,lcgroup,'tokens','forceCellOutput');
                    %Unroll cell array
                    LCbins=[LCbins{:}];
                    LCbins=[LCbins{:}];
                    %Make sure they are unique
                    LCbins=unique(LCbins);
                    self.settings.LCbins=LCbins(~cellfun('isempty',LCbins));
            end
            
        end
        function dat = stadat2dat(self)
            dat.mean       = self.stadat.mean';
            dat.std        = self.stadat.std';
            dat.max        = self.stadat.max';
            dat.min        = self.stadat.min';
            dat.filename   = self.stadat.filenames;
            dat.sensorname = self.stadat.sensor;
            dat.unit       = self.stadat.unit;
            
            stafields = self.stadat;
            if isfield(stafields,'eq1hz')
                for im = 1:length(self.stadat.m)
                    dat.(sprintf('m%s',num2str(self.stadat.m(im)))) = self.stadat.eq1hz(:,:,im)';
                end
 
            end
            
        end
        function data = stadat2matstat(self,channels,fatigueslopes)
            % STADAT2MATSTAT will generate sta data structure in the 
            % old MatStat format.
            % ---------------------------------------------------------------------
            % old call
            % [data] = MatStat('frq file',[sensors],save,[whoeler],{filesearch})
            % [data] = MatStat('..\iec2a.frq',[27 27],0,[10 12],{'11' '12'})
            %
            % new call
            % [data] = stadat2matstat([sensors],[whoeler])
            % - frq file is redundant as stapost already know this.
            % - save option is not implemented.
            % - filesearch is redundant since stapost already support this
            %
            % MatStat structure output format:     
            %v {} sensor     :   {nSens x 1} cell list of sensors 
            %v {} filenames  :   {nfiles x 1} cell list of load case names *this
            % should be corrected with {} DLC
            %v {} loads      :   {nSens x 1} cell of [nfiles x 4] load values (mean std min max)
            %v {} DLC        :   {nfiles x 1} cell list of full filenames *this
            % should be corrected with {} filenames
            %v [] plf        :   [nfiles x 1] array of plf
            %v [] family     :   [nfiles x 1] array of  family
            %v [] frq        :   [nfiles x 1] array of frequency distribution
            %v [] hour       :   [nfiles x 1] array of hour distribution
            %v [] method     :   [nfiles x 1] array of method
            %v {} fat        :   {1 x nSens} cell of [nfiles+1 x 8] fatigue values
            % [] fatslope   :   [1 x nSens] array of m value
            % [] Leq        :   [1 x nSens] array of Leq value            
            
            
            %% Output data structure
            data = struct;
            
            %% Output sensors
            % find indicies for selected sensors
            if iscell(channels)
                for icell = 1:length(channels)
                    if ischar(channels{icell})
                        index(icell) = self.findSensor(channels{icell});
                    else
                        index(icell) = channels{icell};
                    end
                end
            elseif ischar(channels)
                index = self.findSensor(channels);
            elseif isnumeric(channels)
                for icell = 1:length(channels)
                    index(icell) = channels(icell);
                end
            end
            outputsensoridx = index;
            
            % output sensor names
            data.sensor = self.stadat.sensor(outputsensoridx);
                        
            %% Output filenames
            % sort read filenames
            [names sortidx] = sortrows(self.stadat.filenames);
            
            % output read filenames replacing .int with .sta
            data.filenames = strrep(names,'.int','.sta');
            
            %% Output DLC
            data.DLC = fullfile(self.simdat.simulationpath,'STA',data.filenames);
            
            %% Output frq file information
            % check if freq file information is available else read frq
            if ~isfield(self.stadat,'family')
                % read frq file to get values
                frq = LAC.vts.convert(fullfile(self.simdat.simulationpath,'INPUTS',self.simdat.frqfile));
                % find read files in frqfile list
                [~,frqidx]=ismember(data.filenames,strrep(frq.LC,'.int','.sta'));
                % output selected frq data
                data.plf = frq.LF(frqidx)';
                data.family = frq.family(frqidx)';
                data.frq = frq.frq(frqidx)';
                data.hour = frq.time(frqidx)';
                data.method = frq.method(frqidx)';
                % add to self for fatigue calculation
                self.stadat.PLF = frq.LF(frqidx);
                self.stadat.family = frq.family(frqidx);
                self.stadat.frq = frq.frq(frqidx);
                self.stadat.hour = frq.time(frqidx);
                self.stadat.method = frq.method(frqidx);
            else
                % use existing data
                data.plf = self.stadat.PLF';
                data.family = self.stadat.family';
                data.frq = self.stadat.frq';
                data.hour = self.stadat.hour';
                data.method = self.stadat.method';
            end
            
            %% Output loads
            for iSens = 1:length(outputsensoridx)
                stadata = zeros(length(self.stadat.filenames),4);
                %mean
                rowdata = self.stadat.mean(outputsensoridx(iSens),:);
                stadata(:,1) = rowdata(sortidx)';
                %std
                rowdata = self.stadat.std(outputsensoridx(iSens),:);
                stadata(:,2) = rowdata(sortidx)';
                %min
                rowdata = self.stadat.min(outputsensoridx(iSens),:);
                stadata(:,3) = rowdata(sortidx)';        
                %max
                rowdata = self.stadat.max(outputsensoridx(iSens),:);
                stadata(:,4) = rowdata(sortidx)';        

                data.loads{iSens,1} = stadata;
            end

            %% Output fatigue loads
            for iSens = 1:length(outputsensoridx)
                fatdata = zeros(length(self.stadat.filenames)+1,length(self.stadat.m));

                %loop whoeler slope
                for iwhoeler = 1:length(self.stadat.m)
                    fatdata(1,iwhoeler) = self.stadat.m(iwhoeler);
                    rowdata = self.stadat.eq1hz(outputsensoridx(iSens),:,iwhoeler);
                    fatdata(2:end,iwhoeler) = rowdata(sortidx)';
                end
                data.fat{1,iSens} = fatdata;
            end
            
            %% Calculate equivalent loads for whoeler slopes
            % fatigue slopes
            if length(outputsensoridx)==0
                data.fatslope = ones(1,length(outputsensoridx))*4;
            elseif length(fatigueslopes)==length(outputsensoridx) 
                data.fatslope = fatigueslopes;
            else
                data.fatslope = ones(1,length(outputsensoridx))*fatigueslopes(1);
            end
            
            for iSens = 1:length(outputsensoridx)
                data.Leq(iSens) = self.calcEqLoad(outputsensoridx(iSens),data.fatslope(iSens));
            end
        end
        
    end
    
    methods (Access=protected)
         function wMean=weightMean(self,sensor,iLoadcase)
            %Calculates sum of mean wighted according to the frequency of
            %the loadcases
            if isnumeric(sensor)
                iSensor = sensor;
            elseif ischar(sensor)
                iSensor = find(strcmpi(sensor,self.stadat.sensor));
            end
            
            Mi  = self.stadat.mean(iSensor,iLoadcase);
            ni  = 3600*self.stadat.hour(iLoadcase);
            wMean = ni.*Mi;          
        end
    end
end
