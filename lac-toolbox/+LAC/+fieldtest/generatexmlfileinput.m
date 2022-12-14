function generatexmlfileinput(turbinedump,pitchctrlname,prodctrlname,responsible,comment)
%This script can be used to generate input for an VOT XML file for 
%parameter upload. The input for the XML file is displayed in the Command 
%Window and can be cut directly into an existing VOT XML file with
%predefined header and footer.
% 
% Inputs
% turbinedump       Parameter dump file from VOT (.xls)
% pitchctrlname     VTS pitch controller parameter file (.csv)
% prodctrlname      VTS prod controller parameter file (.csv)
% responsible       XML file meta data, e.g. 'JAKKR'
% comment           XML file meta data, e.g. 'For V112-3.3MW IEC1B prototype'
%
% Outputs
% The parameter differences between a turbine parameter dump and 
% VTS pitchctrl/prodctrl parameter files are determined. Based upon this 
% XML file input is generated and displayed in the Command Window.
% Furthermore, parameters existing in VTS but not in the turbine
% configuration are subsequently displayed in the Command Window.
%
% Notes
% - THE XML FILE INPUT SHOULD ALWAYS BE REVIEWED BEFORE TURBINE UPLOAD!!!
% - Both new and old csv parameter format are supported
%
% Example:
%   cd('Y:\_Data\LAC\Control\ControlTools\Misc\FieldTest');
%
%   turbinedump     = 'TurbineParamDump.xls';
%   pitchctrlname   = 'PitchCtrl_params.csv';
%   prodctrlname    = 'ProdCtrl_params.csv';
%   responsible     = 'jakkr';
%   comment         = 'test';
%
%   GenerateXMLFileInput(turbinedump,pitchctrlname,prodctrlname,responsible,comment)
%
% Assumptions
% It is assumed that the turbine dump file contains the sheet 'Page 4 Target Parameters'

% Version history:
% V0 - 26-03-2013 - JAKKR
% V1 - 31-07-2013 - JADGR (Updated to support new SI unit config files)
%
% Todo:
% Generate xlm file instead of input to xml file (written in Command Window)

% Clear Command Window
clc

% Check input arguments
if (nargin == 3)
    responsible = '';
    comment = '';
elseif (nargin == 4)
    comment = '';
elseif (nargin < 3 && nargin > 5)
    error('Erroneous number of input arguments')
end
    
% Assumed name of Excel sheet with all parameters
sheet = 'Page 4 Target Parameters';

% Read turbine parameter dump
[turbineparam.val,turbineparam.name] = xlsread(turbinedump,sheet);

% Read VTS parameter files
pitchctrl = ReadVTSParamFile(pitchctrlname);
prodctrl = ReadVTSParamFile(prodctrlname);

% Get turbine parameter names
pitchctrl = ReadTurbineParamFile(pitchctrl,turbineparam);
prodctrl = ReadTurbineParamFile(prodctrl,turbineparam);

% Merge pitchctrl and prodctrl
ctrlparam = {pitchctrl{:},prodctrl{:}};

% Get overview of parameter updates
update = [];
nupdate = [];
nexist = [];
for k=1:length(ctrlparam)
    ctrl = ctrlparam{k};
    
    if (isfield(ctrl,'turbinename'))                
        if (ctrl.vtsval ~= ctrl.turbineval)            
            update = [update k];
        else
            nupdate = [nupdate k];
        end
    else
        nexist = [nexist k];        
    end        
end

% Generate XML file input (parameter updates only)
disp('\\ Parameter differences between VTS and turbine')
for k=1:length(update)
    ctrl = ctrlparam{update(k)};
    com = [comment ' (Old value: ' num2str(ctrl.turbineval) ')'];        
    str = sprintf('<Parameter Id="%s" Type="float" Value="%g" Comment="%s" Responsible="%s" />',ctrl.turbinename,ctrl.vtsval,com,responsible);
    disp(str)
end
disp('-------------------------------------------------')

% List of parameters not existing in turbine configuration
disp('\\ Parameters not existing in turbine configuration')
for k=1:length(nexist)
    disp(ctrlparam{nexist(k)}.vtsname)
end
disp('-------------------------------------------------')

% List of identical parameters
% disp('\\ Parameters identical in VTS and turbine')
% for k=1:length(nupdate)
%     disp(ctrlparam{nupdate(k)}.vtsname)
% end

end


%% Local functions
function param = ReadVTSParamFile(paramfile)
    % Open file
    fid = fopen(paramfile,'r');
    if (fid == -1)
        error(sprintf('%s does not exist',paramfile))
    end

    pattern='\s*(Px\w+)\s*=\s*([+\-]?[\d\.]+[eE]?[+\-]?\d*).*';
    % Read file
    k = 1;
    while 1
        tline = fgetl(fid);
        if ~ischar(tline), break, end
        
        tok=regexp(tline,pattern,'tokens');
        
        if(~isempty(tok))
            % Remove spaces and tabs in name and value string    
               param{k}.vtsname = tok{1}{1};
               param{k}.vtsval = str2double(tok{1}{2});             
            k = k + 1;
        end
    end
    fclose(fid);
end

function param = ReadTurbineParamFile(vtsparam,turbineparam)

    param = vtsparam;
    
    for j=1:length(param)
        % Remove Px in beginning of name and add Px in the end
        str2find = [param{j}.vtsname(4:end) 'Px'];

        for k=1:size(turbineparam.name,1)
            if (strmatch(str2find,turbineparam.name{k,2},'exact'))                
                param{j}.turbinename = strtrim(turbineparam.name{k,3});
                val=turbineparam.val(k-1,3);
                if(isnan(val))
                    strNum=strrep(strtrim(turbineparam.name{k,4}),',','.');
                    param{j}.turbineval = str2double(strNum);
                else
                    param{j}.turbineval = val;
                end
                break
            end    
        end        
    end    
end

