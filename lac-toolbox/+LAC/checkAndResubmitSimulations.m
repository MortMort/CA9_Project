function checkAndResubmitSimulations(folder,vtsconfig,mindstorm)
% Function to check if simulations are done (int files are completed) and 
% resubmits the missing files. When all INT files are completed, it checks 
% if STA files are complete. 
% It reads the _SimFolderOverview.txt file to determine simulation folders, 
% and uses IsDistRunComplete to check int files. If mindstorm settings are 
% provided as input, it runs simulations on mindstorm, otherwise the old 
% cluster. If no cluster settings are provided it runs with FAT1 defaults.
% 
% NB: This function will eventually be redudant, since the same
% functionality is to be implemented in FAT1. Please use it with this in
% mind.
%
%
% Inputs:
%   1) Full path to VTS folder (location of prep file)
%   2) VTS configuration struct: 
%      vts.timeout
%      vts.priority
%      vts.maxruns
%   3) Mindstorm configuration struct: 
%      ms.timeout
%      ms.priority
%      ms.mqueue
%      ms.cqueue   
% NB: all structs must be defined as a char, e.g: vts.maxruns = '10'
%
% Example:
% LAC.checkAndResubmitSimulations('path',[],ms)
% or 
% LAC.checkAndResubmitSimulations('path')
%
% Version History
% 00 - JEHCI 30-01-2019

    % check inputs
    if ~exist('vtsconfig','var')
        vtsconfig.timeout = '600';
        vtsconfig.priority = '5';
        vtsconfig.maxruns = '3';
        disp(['VTS configuration not given as input, using default settings.'])
    else
        if ~exist('mindstorm','var')
            if ~isfield(vtsconfig,'timeout') || ~ischar(vtsconfig.timeout)
                vtsconfig.timeout = '600';
                warning(['The VTS timeout input was not present or not a char, default settings are used (600s)'])
            end

            if ~isfield(vtsconfig,'priority') || ~ischar(vtsconfig.priority)
                vtsconfig.priority = '5';
                warning(['The VTS priority input was not present or not a char, default settings are used (5)'])
            end

            if ~isfield(vtsconfig,'maxruns') || ~ischar(vtsconfig.maxruns)
                vtsconfig.maxruns = '3';
                warning(['The VTS maxruns input was not present or not a char, default settings are used (3)'])
            end
        end
    end
    if ~exist('mindstorm','var')
        mindstorm = [];
    else
        if ~isfield(mindstorm,'timeout') || ~ischar(mindstorm.timeout)
            mindstorm.timeout = '600';
            warning(['The Mindstorm timeout input was not present or not a char, default settings are used (600s)'])
        end
        if ~isfield(mindstorm,'priority') || ~ischar(mindstorm.priority)
            mindstorm.priority = '5';
            warning(['The Mindstorm priority input was not present or not a char, default settings are used (5)'])
        end
        if ~isfield(mindstorm,'mqueue') || ~ischar(mindstorm.mqueue)
            mindstorm.mqueue = 'mj.q';
            warning(['The Mindstorm mqueue input was not present or not a char, default settings are used (mj.q)'])
        end
        if ~isfield(mindstorm,'cqueue') || ~ischar(mindstorm.cqueue)
            mindstorm.cqueue = 'lpe.q';
            warning(['The Mindstorm cqueue input was not present or not a char, default settings are used (lpe.q)'])
        end
    end
    
    % check connection to w:\
    if isempty(dir('\\dkrkbfile01\flex'))
        error('No connection to w:\ (\\dkrkbfile01\flex), aborting');
    end
    
    % get inputs folders from SimFolderOverview
    inputsFolders = readSimFolderOverview(folder);
    
    % check output
    if isempty(inputsFolders)
        error(['Error: No Inputs folders found in ' folder ])
    end
    
    % determine run path to return to after script has run
    runPath = pwd;
    
    % main loop
    for k = 1:length(inputsFolders)
        % find master files in inputsFolders
        masFile = dir(fullfile(inputsFolders{k},'*.mas'));       
        % if found
        if ~isempty(masFile)
            % check master file length 
            if length(masFile) > 1
                masFile = masFile(1);
                warning(['Multiple master files found in ' masFile.folder ', using the first found master file (' masFile.name ')'])
            end
            % create full path
            masFile = fullfile(masFile.folder,masFile.name);
            % check folder
            [status, cmdout] = system(['IsDistRunComplete ' masFile ' -checkall']);
            % sort cmdOut to find int files to re-run
            intFiles = regexp(cmdout,'(?<=MISSING] |BADSIZE] )\S+(?=.int)','match');
            % continue if files are bad
            % make below if-statement to function
            if ~isempty(intFiles)
                % create .bat file to run sims
                [inputsFolder, masFileName, masFileExt] = fileparts(masFile);
                % go to folder
                cd(inputsFolder)
                % create bat file
                batFile = 'RunMissingINT.bat';
                fid = fopen(batFile,'w+');
                % write header
                fprintf(fid, 'set DirPath=..\nset masfile=%s%s\n',masFileName,masFileExt);
                % write all intFiles
                for k = 1:length(intFiles)
                    fprintf(fid,'set filename=%s\ncall FlxCtrl\n',intFiles{k});
                end
                % close bat file
                fclose(fid);
                % run bat file either on old cluster or mindstorm              
                if isempty(mindstorm)
                   [status, cmdout] = system(['DCClient -server dkaarwhpc02 addvtsbatch ' fullfile(inputsFolder,batFile) ' -timeout ' vtsconfig.timeout ' -priority ' vtsconfig.priority ' -tag VTSview -maxruns ' vtsconfig.maxruns]);
                else
                   [status, cmdout] = system(['DCClient_ms_fat1.exe addvtsbatch -server mindstorm -quiet -tag FAT1 -timeout ' mindstorm.timeout ' -priority ' mindstorm.priority '  -maxruns 1 -mqueue ' mindstorm.mqueue ' -cqueue ' mindstorm.cqueue ' -maxmstasks 0 ' fullfile(inputsFolder,batFile)]);
                end
                % inform user 
                disp(sprintf('%s\nMissing or bad int-files: %g \nVTS output: %s\n',inputsFolder,length(intFiles),cmdout));
            else
                % def loads folder
                loadsFolder = strrep(inputsFolders{k},'\Inputs','\');
                % int files are done, check STA files
                fprintf('%s\nAll INT files are complete, checking STA files...',loadsFolder);
                % call STA check
                staout = system(['checkIntAndStaFiles.bat ' fullfile(loadsFolder) ' > NUL']);
                % run STA files 
                fprintf('Done\n')
            end
        else
            warning(['master file not found in ' inputsFolders{k}]);
        end
    end
    
    % return to runPath
    cd(runPath);
    
end

% helper functions
function simFolders = readSimFile(simFolderOverview)
    fid = fopen(fullfile(simFolderOverview.folder,simFolderOverview.name),'r');
    % read while
    tline = fgetl(fid);
    k = 1;
    while ischar(tline)
        if isempty(tline)
            tline = fgetl(fid);
            continue;
        end
        name = strsplit_LMT(tline,' |');
        simFolders{k} = name{1};
        tline = fgetl(fid);
        k = k + 1;
    end
    fclose(fid);
end

function simFolders = readSimFolderOverview(folder)
    % read given VTS setup and returns returns listed in _SimFolderOverview.txt
    simFolders = {};
    % find file
    simFolderOverview = dir(fullfile(folder,'_SimFolderOverview.txt'));
    % if found, get target folders
    if ~isempty(simFolderOverview)
        % read file
        simOverview = readSimFile(simFolderOverview);
        % combine full paths to input folders
        try 
            for n = 1:length(simOverview)
                if strcmp(simOverview{n},'Loads')
                    simFolders{end+1} = fullfile(folder,'Loads','Inputs');
                elseif strcmp(simOverview{n},'PC') || strcmp(simOverview{n},'VSC')
                    subSimFolder = fullfile(folder,simOverview{n});
                    subSimFolderOverview = dir(fullfile(subSimFolder,'_SimFolderOverview.txt'));
                    % read again
                    subSubSimFolder = readSimFile(subSimFolderOverview);
                    if exist('m','var') && m > 1 % if m exist this loop has been executed before
                        m = m;
                    else
                        m = 1;
                    end
                    % read again, and construct output
                    for k = 1:length(subSubSimFolder)
                        subSubSimFolderOverview = dir(fullfile(subSimFolder,subSubSimFolder{k},'_SimFolderOverview.txt'));
                        subSubSimFolders = readSimFile(subSubSimFolderOverview);
                        for n = 1:length(subSubSimFolders)
                            simFolders{end+1} = fullfile(subSubSimFolderOverview.folder,subSubSimFolders{n},'Inputs');
                            m = m + 1;
                        end
                    end
                else % Parameter Study
                    simFolders{end+1} = fullfile(folder,simOverview{n},'Loads','Inputs');
                end
            end
        catch
            error(['Incorrect folder setup in ' fullfile(folder,simOverview{end}) ])
        end
    end
end
