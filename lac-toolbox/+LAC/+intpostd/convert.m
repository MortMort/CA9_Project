function [varargout] = convert(filename, varargin)
% Read IntpostD files. 
% Input IntpostD filename can be formated as txt or xml.
% When outputformat is specified a output file will be generated in the
% specified format (txt or xml).
% If two outputs are specified then a struct containing the contents of 
% the decoded file will be returned.
%
% SYNTAX:
%   [status [, decoded]] = LAC.intpostd.convert <filename> [filetype] [outputformat]
%
% Supported filetype are:
%   LDD,RFO,SST,EXT
%   DRT,PIT,TWR,TWR_OFF,
%   MAIN
%
% Supported outputformats are:
%   TXT, XML
%
% EXAMPLES:
%   [status, decoded] = LAC.intpostd.convert('c:\filename.mas')
%   [status, decoded] = LAC.intpostd.convert('c:\BLD\filename.txt')
%   [status, decoded] = LAC.intpostd.convert('c:\filename.txt', 'RFO')
%   [status, decoded] = LAC.intpostd.convert('c:\filename.txt', 'RFO', 'XML')
%   [status, decoded] = LAC.intpostd.convert('c:\filename.xml', 'RFO', 'TXT')
%   [status] = LAC.intpostd.convert('c:\filename.txt', 'BLD', 'TXT')
%   LAC.intpostd.convert('c:\filename.txt', 'RFO', 'XML')
%   LAC.intpostd.convert('c:\filename.xml', 'RFO', 'TXT')
%

varargout{1} = -1;

if ~exist(filename,'file')
    error(['Input file ' filename ' does not exist. Will not continue.'])
end

%% Detect filetype

% Check if filetype is valid
detectedfiletype = '';
if nargin > 1
    detectedfiletype = varargin{1};
end
supportedtypes = {  'LDD','RFO','SST','EXT',...
                    'DRT','PIT','TWR','TWR_OFF',...
                    'MAIN','MAIN_v01','MKO','FND',...
                    'USER'};
allowedtype = supportedtypes(strcmpi(detectedfiletype,supportedtypes));

% Autodetect filetype if not specified (correctly)
if isempty(allowedtype)
    % Try to determine the type from file extension
    [~,~, fileext] = fileparts(filename);
    fileext=strtrim(strrep(fileext,'.',''));
    detectedfiletype  = upper(supportedtypes(strcmpi(fileext,supportedtypes)));
    
    if isempty(detectedfiletype)
        % Try to determine the type from parent folder
        [~, filefolder,  ~] = fileparts(fileparts(filename));
        detectedfiletype = upper(supportedtypes(strcmpi(filefolder,supportedtypes)));
    end    
    
    if isempty(detectedfiletype)
        error(['Could not detect type of file ' filename '. Please, specify file type manually.'])
    end
end

%% Check for legacy filetypes
legacyfiletypes  = {'LDD','RFO','EXT','SST'};
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
    outputfile = fullfile(myfolder,[myfilename '.' lower(outputformat)]);
    if exist(outputfile,'file')
        error(['Output file already exist ' outputfile '. Will not continue.'])
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
    if ismember(detectedfiletype,{'MAIN','MAIN_v01'})
        decoded = LAC.intpostd.codec.(char(detectedfiletype)).decode(VTSDecoder,char(detectedfiletype));
        if strcmp(detectedfiletype,'MAIN_v01')
            warning('''LAC.intpostd.codec.MAIN_v01'' will be deleted in a future release of LMT. Please correct code to use ''MAIN'' codec and make a pull request to ''develop''.')            
        end
    else        
        decoded = LAC.intpostd.codec.(char(detectedfiletype)).decode(VTSDecoder);
    end
catch ME1
    disp(ME1.getReport())
    return
end


if isobject(decoded)
    if nargout>0
        varargout{1} = decoded;
    end
    if ~isempty(VTSEncoder)
        decoded.encode(VTSEncoder);
    end
    
end