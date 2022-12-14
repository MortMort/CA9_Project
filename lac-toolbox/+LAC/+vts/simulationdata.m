classdef simulationdata < handle
    properties
        simulationpath;
        runname;
        setfile;
        frqfile;
        masfile;
        prepfile;
    end
    methods
        function obj = simulationdata(simulationpath,configurationPrefix)
            % SIMULATIONDATA finds the input data files in a specified simulationpath.
            %  
            %    obj = simulationdata(simulationpath) add the properties simulationpath',
            %    'runname', 'setfile', 'frqfile', 'masfile', 'prepfile' to obj. 
            %    If multiple masterfiles are found a dialog will open where the 
            %    required configuration is chosen.
            %
            %    obj = simulationdata(simulationpath,configurationPrefix) will choose the 
            %    configuration matching the prefix given in configurationPrefix.

                if exist(fullfile(simulationpath, 'Loads'),'dir') == 7
                    simulationpath = fullfile(simulationpath, 'Loads');
                end                
                obj.simulationpath = simulationpath;

            if nargin==1
                masterFiles = LAC.dir(fullfile(simulationpath,'INPUTS','*.mas'));
                frqFiles    = LAC.dir(fullfile(simulationpath,'INPUTS','*.frq'));
                setFiles    = LAC.dir(fullfile(simulationpath,'INPUTS','*.set'));
            else
                masterFiles = LAC.dir(fullfile(simulationpath,'INPUTS',[configurationPrefix,'.mas']));
                frqFiles    = LAC.dir(fullfile(simulationpath,'INPUTS',[configurationPrefix,'.frq']));
                setFiles    = LAC.dir(fullfile(simulationpath,'INPUTS',[configurationPrefix,'.set']));
            end
            
            if ~isempty(masterFiles)
                if size(masterFiles,1) > 1 %in case multiple master files are found, prompts user to either select one or stop execution
                    warning('Multiple master files have been found in %s, select from prompt or stop execution and fix',simulationpath)
                    ok = 0; indx = 0;
                    [indx,ok] = listdlg('PromptString','Multiple master files found',...
                        'SelectionMode','single',...
                        'CancelString','STOP',...
                        'ListSize',[700 200],...
                        'ListString',strcat(simulationpath,masterFiles)); %prompt user to select master file from a list
                    if ok == 0
                        error('Master file not selected')
                    end
                else
                    indx = 1;
                end
                obj.masfile = masterFiles{indx};
                [~ , obj.runname] = fileparts(obj.masfile);
            end            

            if exist(fullfile(simulationpath,'INPUTS',[obj.runname '.frq'])) == 2
                if size(frqFiles,1) > 1 %when multiple frequency files are found, prompts user to select one
                    ok = 0; indx = 0;
                    [indx,ok] = listdlg('PromptString','Select a Frequency File',...
                        'SelectionMode','single',...
                        'ListSize',[700 200],...
                        'ListString',strcat(simulationpath,frqFiles)); %prompt user to select frequency file from a list
                    if ok == 0
                        error('Frequency file not selected')
                    end
                    obj.frqfile = frqFiles{indx};
                else
                    obj.frqfile = [obj.runname '.frq'];
                end
            end

            if exist(fullfile(simulationpath,'INPUTS',[obj.runname '.set'])) == 2           
                obj.setfile = [obj.runname '.set'];
            end

            if exist(fullfile(simulationpath,'INPUTS',[obj.runname '.txt'])) == 2           
                obj.prepfile = [obj.runname '.txt'];
            end
        end
    end
end




