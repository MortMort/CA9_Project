% Wrapper: Detects EVs, Adds edgewise blade damping and resubmits LCs.
%
% LAC WIKI: Detect & Dampen Edgewise Vibrations In Idling, Maintenance Load Cases
% http://wiki.tsw.vestas.net/pages/viewpage.action?pageId=175997177
%
% Process:
% 1. Input LCs for damping.
% 2. Checks for EVs.
% 3. Dampen if needed.
% 4. If dampened, resubmits seeds.
%
% Inputs
% 	Simulation folder - cell input with .../Loads/ present.
%
% Optional inputs
% 	useMScluster 	Use Mindstorm cluster (dk2 is recommended), default useMScluster 	= false;
% 	recheckEVs 		Rechecks EV after finalization, default recheckEVs 		= true;
%   sens    		Sensors to read, default sens    = {'My11r', 'My21r', 'My31r'}
%   prep            If 'auto' is stated, the script detects the prep
%                   version from the _FAT1.log file in ...\Loads\LOG\.
%                   Otherwise 'Prep002v05.exe' is used.
%   DLCs    		DLC's to be read, default DLCs    = {'62'; '82'; '81I'; ...}
%   margin  		Gravity bending moment margin (Smom1*9.81*margin    = EV limit.
%                   Default margin = 2.0 i.e. peak-to-peak.
%   period          [s], time period the script pause to wait for
%                   simulations to finish before checking for .int-file 
%                   existance. 300s is default. Works best for dk2 cluster.
%   forceRead       Default set to true, but can be set to false which
%                   means that the already saved .mat file with sta info will be loaded. 
%                   Nice for debugging. 
% Other .m-files required:  LAC.scripts.AddDamping.edgewise_vibration_detect()
%                           LAC.scripts.AddDamping.apply_edgewise_damping()

function damping_wrapper(SimFolder,varargin)
%% INPUTs (default values)
useMScluster 	= false; % use Mindstorm cluster (dk2 is recommended)
recheckEVs 		= true; % rechecks EV after finalization
prep            = 'auto';
sens    		= {'My11r', 'My21r', 'My31r'}; % sensors to read
DLCs    		= {'62';'71';'82';'81SBI';'81TG';'81HSB';'81Iwd';'81RLIpi';...
                   '81RLIwd';'81RLSpi';'81RLSwd';'81Swd'}; % DLCs to be read
margin  		= 2.0; % multiplier for Smom (2 equals peak-to-peak)
period          = 300; % [s] idle time per variant before rechecking EVs
forceRead       = true;

while ~isempty(varargin)
    switch lower(varargin{1})
        case 'prep'
            prep            = varargin{2};
            varargin(1:2) = [];
        case 'usemscluster'
            useMScluster    = varargin{2};
            varargin(1:2) = [];
        case 'recheckevs'
            recheckEVs            = varargin{2};
            varargin(1:2) = [];
        case 'sens'
            sens            = varargin{2};
            varargin(1:2) = [];
        case 'dlcs'
            DLCs            = varargin{2};
            varargin(1:2) = [];
        case 'margin'
            margin            = varargin{2};
            varargin(1:2) = [];
        case 'period'
            period            = varargin{2};
            varargin(1:2) = [];
        case 'forceread'
            forceRead            = varargin{2};
            varargin(1:2) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end

% check if input is cell
if ~iscell(SimFolder)
    SimFolder = {SimFolder};
end

% use MS cluster or normal cluster
if ~useMScluster
    dcclient = 'dcclient -server dkcdclac01';
else
    dcclient = 'dcclient_ms';
end

%% Detect instabilities

maslist = []; batlist = []; damplist = [];
for i=1:length(SimFolder)
    
    % locate VTS prep (in .../Loads folder)
    loads_dir = dir([SimFolder{i,1} '/Loads/' '*.txt']);
    [~,prep_idx] = sort([loads_dir.bytes],'descend'); % largest file size (prep)
    
    prepfile = loads_dir(prep_idx(1)).name;
    prep_path = [SimFolder{i,1} '\' prepfile];
    
    % get prep version
    if strcmpi(prep,'auto')
        % find the _FAT file to detect the prep version, assumes that all the
        % prep paths are siumulated with the samme prep version
        disp('')
        if exist(fullfile([SimFolder{i,1} '/Loads/LOG/'],'_FAT1.log'))
            FAT1data = textscan(fileread(fullfile([SimFolder{i,1} '/Loads/LOG/'],'_FAT1.log')),'%s');
            prep 			= FAT1data{1}{find(cellfun(@(x) strcmpi(x,'Prep_prg'), FAT1data{1}))+2};
            disp(['Prep version : ' prep])
        else
            % use default version
            prep 			= 'Prep002v05.exe';
            warning('_FAT1.log not found to detect prep version, using Prep002v05.exe');
        end
    end
    
    % detect EVs
    disp('Detecting EVs.')
    n_damping = LAC.scripts.AddDamping.edgewise_vibration_detect(prep_path,'sens',sens,'DLCs',DLCs,'margin',margin,'forceRead',forceRead);
    if n_damping == 0
        disp(['No damping added for ' prepfile '.'])
    else
        disp(['Adding damping to ' num2str(n_damping) ' LCs in ' prepfile '.'])
    end
    
    damplist(end+1) = n_damping;
    fclose all;
    if n_damping > 0
        fid         = fopen([SimFolder{i,1} '/damping_application.txt'], 'r');  % open damping application text file
        loadcase         = textscan(fid, '%s','delimiter','\n');                  % read
        loadcase         = loadcase{:, 1};                           % store DLC list in cell array
        fclose(fid);
        % close damping application text file
    end
    % apply damping if necessary
    disp('Applies damping.')
    LAC.scripts.AddDamping.apply_edgewise_damping(prep_path,1,0,1,1);
    
    % EV cases - submit to cluster
    if n_damping > 0
        
        % .batname
        date_str = datestr(now, 'yy_mm_dd_HH_MM_SS'); % unique date string identifier
        bat_name = ['damping' date_str '_resubmission.bat']; % resubmission .bat (these files will be ignored by the radar which invalidates the int files)
        bat_pathstr = [SimFolder{i,1} '/Loads/Inputs/' bat_name];
        batlist{end+1} = bat_pathstr;
        
        % .mas file
        [~,prepname,~] = fileparts(prepfile);
        masFiles = dir([SimFolder{i,1} '/Loads/Inputs/' prepname '.mas']);
        mas = fullfile(masFiles(1).folder,masFiles(1).name); % graps default (original master file) masterfile
        maslist{end+1} = mas;
        copyfile(mas, strcat(mas,'_org'),'f');
		
        % open temporary files
        tmpFile = tempname;
        fid = fopen(tmpFile,'w');
        
        % write .bat content
        fprintf(fid,'set DirPath=..\n');
        fprintf(fid,'set masfile=%s\n',masFiles(1).name);%
        for lcs=1:length(loadcase)
            seed_list   = dir(fullfile(SimFolder{i,1}, 'Loads', 'STA', [loadcase{1}, '*.sta'])); % lc list
            seeds = length(seed_list);
            for s=1:seeds
                fprintf(fid,'set filename=%s%03d\n',loadcase{lcs},s);
                fprintf(fid,'call FlxCtrl\n');
            end
        end
        fclose(fid);
        
        copyfile(tmpFile,[SimFolder{i,1} '/Loads/Inputs/' bat_name]); % move .bat to inputs folder
        delete(tmpFile); % delete temporary file
        
        % prep
        disp('Running VTS prep and submitting to cluster.')
        temp = dir([SimFolder{i,1} '/' '*.txt']);
        
        % if _SubSet.txt prepfile exist, use for prep. Case Sensitive.
        if  any(~cellfun('isempty',strfind({temp.name},'_SubSet.txt'))) % FAT1 creates SubSet.old if a FLS is run afterwards
                prep_used = [prepname '_SubSet.txt'];
        else
                prep_used = prepfile;
        end
        
        copyfile([SimFolder{i,1} '/' prep_used],[SimFolder{i,1} '/Loads/' prepfile])
        [~, ~] = system([prep ' ' SimFolder{i,1} '\Loads\' prepfile ' -forcecontinue']); % Use '\' in path (no DOS formats) 
        copyfile(strcat(mas,'_org'), mas,'f');
		delete(strcat(mas,'_org'));
		
        % execute on selected cluster - execution.bat
        [~,cmdout] = system([dcclient ' addvtsbatch ' bat_pathstr]);
    end
end

%% check if complete (.int level)
if any(damplist)>0
    status = 1;
    disp('Monitors jobs.')
else
    status = 0;
    disp('Process finalized.')
end

lim = 0; counter = 0; 
while any(status)>0
    for d=1:length(maslist)
        [status(d), ~] = system(['IsDistRunComplete ' maslist{d} ' -checkall']);
        lim = lim+1;
    end
    
    fprintf('Waiting %d seconds.\n',period)
    pause(period)
    
    % resubmitting as a precaution 
    if counter<1 && lim>length(maslist)*600/period
        for e=1:length(batlist)
            % resubmit on selected cluster - execution.bat
            disp('Resubmitting stalling loadcases to cluster.')
            [~,cmdout] = system([dcclient ' addvtsbatch ' batlist{e}]);
        end
        counter = counter+1;
    elseif counter>=1
        disp('Error in VTS resubmission. Debug.')
        break
    end
end

if recheckEVs && any(damplist)>0
    fprintf('\n')
    disp('Rechecking for EVs.')
    for i=1:length(SimFolder)
        % locate VTS prep (in .../Loads folder)
        loads_dir = dir([SimFolder{i,1} '/Loads/' '*.txt']);
        [~,prep_idx] = sort([loads_dir.bytes],'descend'); % largest file size (prep)
    
        prepfile = loads_dir(prep_idx(1)).name;
        prep_path = [SimFolder{i,1} '/' prepfile];

        n_damping = LAC.scripts.AddDamping.edgewise_vibration_detect(prep_path,'sens',sens,'DLCs',DLCs,'margin',margin,'forceRead',true);
        
        fclose all;
        if n_damping > 0
            fprintf('%d unstable load cases still detected.\n',n_damping)
            disp('Rerun process. Consider additional edgewise damping, source of instability.')
        end
    end
    disp('Process finalized.')
end
end