cleafunction LMT_Check(name,pth,varargin)
% Checks if a LAC Matlab toolbox already exists in path and asks what to do
% Optional parameters -forceOwn or -forceExisting will respectively force
% using its own toolbox or using whatever toolbox is already in path.



    %mpath = mfilename('fullpath');
    %rpath='\LT';

    cpath=which('LAC.Canary');

    if(isempty(cpath))
        ToolBox=false;
    else
        ToolBox=true;
    end

    %[pth,~,~]=fileparts(mpath);
    %expTBpath=fullfile(pth,rpath,'+LAC');
    expTBpath=fullfile(pth,'+LAC');

    [TBpth,~,~]=fileparts(cpath);

    ownToolBox=strcmpi(expTBpath,TBpth);
    
    opt.Interpreter='tex';
    opt.Default=[name ' version'];
 
    TBpthTex=strrep(TBpth,'\','\\');
    
    %Check for overwrites
    nInputs = numel(varargin);
    if (nInputs > 0)
        switch varargin{1}
            case '-forceOwn'
                addpath(pth)
                return
            case '-forceExisting'
                if(~ToolBox)
                   warndlg(['LAC Matlab Toolbox not found. ' name ' will not work without it. Please start ' name ' without -forceExisting option set'],'No LAC Matlab Toolbox found') 
                end
                return
            otherwise
                pathtool
        end
        
    end
    
    
    if(~ToolBox) %If no version of the toolbox exists, ask which one to ask
        answer=questdlg('Which Toolbox would you like to use?','No LAC toolbox found',[name ' version'],'Add one manually',opt);
        switch answer
            case 'Current version'
            case [name ' version']
                addpath(pth)
            case 'Add one manually'
                pathtool
        end
    elseif(~ownToolBox) %If it exist but is not our own toolbox then ask
        answer=questdlg(['Current version: ' TBpthTex ' \newline Which Toolbox would you like to use?'],'Existing version of LAC toolbox found','Current version',[name ' version'],'Add one manually',opt);
        switch answer
            case 'Current version'
            case [name ' version']
                addpath(pth)
            case 'Add one manually'
                pathtool
        end
    end





