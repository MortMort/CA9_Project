function [varargout] = convert(filename, varargin)
% Read VTS files. 
% Input VTS filename can be formated as txt or xml.
% When outputformat is specified a output file will be generated in the
% specified format (txt or xml).
% If two outputs are specified then a struct containing the contents of 
% the decoded file will be returned.
%
% SYNTAX:
%   [status [, decoded]] = LAC.vts.convert <filename> [filetype]
%
% Supported filetype are:
%   'REFERENCEMODEL','REFMODEL'
%   'BLD','BLD_PROPS','BLD_FLXEXP','BLD_FLXEXPv2','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','VRB','WND','YAW','PL','ERR'
%   'PROFILE','PARAMETER','SENSOR','AuxParameterFile', 'AuxInterfaceFile'
%   'EIG','FRQ','MAS','SET','STA','PRO', 'OUT'
%   
%
% Supported outputformats are:
%   'TXT'
%
% EXAMPLES:
%   [obj] = LAC.vts.convert('c:\filename.mas')
%   [obj] = LAC.vts.convert('c:\BLD\filename.txt')
%   [obj] = LAC.vts.convert('c:\filename.txt', 'BLD')


ErrorMessage = [];

if ~exist(filename,'file')
    ErrorMessage{end+1} = ['Input file ' char(filename) ' does not exist. Will not continue.'];
else
    filedir = dir(filename);
    if filedir.bytes == 0
        ErrorMessage{end+1} = ['Input file ' char(filename) ' is empty. Will not continue.'];
    end
    clear filedir;
end

%% Detect filetype

% Check if filetype is valid
detectedfiletype = '';
if nargin > 1
    detectedfiletype = varargin{1};
end
if nargout == 0
    error('Please specify object as output!')
end

supportedtypes = {'REFERENCEMODEL','REFMODEL',...
                  'BLD','BLD_PROPS','BLD_FLXEXP','BLD_FLXEXPv2','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','VRB','WND','YAW','PL','ERR' ...
                  'PROFILE','PARAMETER','SENSOR','AuxParameterFile', 'AuxInterfaceFile' ...
                  'EIG','FRQ','MAS','SET','STA','PRO', 'OUT'};
allowedtype = supportedtypes(strcmpi(detectedfiletype,supportedtypes));

% Autodetect filetype if not specified (correctly)
if isempty(allowedtype)
    % Try to determine the type from file extension
    [~,fname, fileExtension] = fileparts(filename);
    fileExtension            = strtrim(strrep(fileExtension,'.',''));
    detectedfiletype         = upper(supportedtypes(strcmpi(fileExtension,supportedtypes)));
    
    if isempty(detectedfiletype) && strcmpi(fileExtension,'csv')
        detectedfiletype   = 'AuxParameterFile';
    end
    
    if isempty(detectedfiletype)
        % Try to determine the type from parent folder
        [~, filefolder,  ~] = fileparts(fileparts(filename));
        detectedfiletype = upper(supportedtypes(strcmpi(filefolder,supportedtypes)));
    end    
    
    if isempty(detectedfiletype)
        % Check if file is a sensorfile
        if strcmp(fname,'sensor')
            detectedfiletype='SENSOR';
        end
    end
    
    if isempty(detectedfiletype)
        ErrorMessage{end+1} = ['Could not detect type of file ' filename '. Please, specify file type manually.'];
    end
end

%% Check for legacy filetypes
legacyfiletypes  = {'EIG','FRQ','LDD','MAS','RFO','SET','STA','SENSOR','PRO','SST','BLD','BLD_PROPS','BLD_FLXEXP','BLD_FLXEXPv2','REFERENCEMODEL','AuxParameterFile','OUT'};
isLegacyfiletype = max(strcmpi(legacyfiletypes,detectedfiletype));

%% Create decoder object
if isLegacyfiletype
    VTSDecoder = LAC.codec.VTSCodecLegacy(filename);
else
    [myfolder,myfilename,ext] = fileparts(filename);
    inputformat = ext(2:end);
    switch upper(inputformat)
        case 'XML'
            VTSDecoder = LAC.codec.CodecXML(filename);
        otherwise
            VTSDecoder = LAC.codec.CodecTXT(filename);
    end  
end

%% Create encoded object
outputformat = '';
if nargin > 2
    outputformat = varargin{2};
    outputfile   = fullfile(myfolder,[myfilename '.' lower(outputformat)]);
    if exist(outputfile,'file')
        ErrorMessage{end+1} = ['Output file already exist ' outputfile '. Will not continue.'];
    end
end
switch upper(outputformat)
    case 'TXT'
        VTSEncoder = LAC.codec.CodecTXT(outputfile);
    case 'XML'
        VTSEncoder = LAC.codec.VTSCodecXML(outputfile);
    otherwise
        %output to varargout{1}
        VTSEncoder = [];
end

%% Decode or encode object
try    
    output = LAC.vts.codec.(char(detectedfiletype)).decode(VTSDecoder);
catch ME
    ErrorMessage{end+1} = ME.message;
    ME.getReport
end

if nargout>0
    varargout{1} = '';
    if isempty(ErrorMessage)
        varargout{1} = output;
    else
        varargout{1} = ErrorMessage;
    end
end
