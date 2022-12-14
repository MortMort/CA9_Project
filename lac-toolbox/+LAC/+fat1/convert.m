function [varargout] = convert(filename, varargin)
% Read FAT1 files. 
% When outputformat is specified a output file will be generated in the
% specified format (txt or xml).
% If two outputs are specified then a struct containing the contents of 
% the decoded file will be returned.
%
% SYNTAX:
%   [status [, decoded]] = LAC.fat1.convert <filename> [filetype] [outputformat]
%
% Supported filetype are:%   
%   CTRCHG, MASCHG, PARSTUDY
%
% Supported outputformats are:
%   TXT, XML
%
% EXAMPLES:
%   [status, decoded] = LAC.fat1.convert('c:\DATA\blade.st')
%   [status, decoded] = LAC.fat1.convert('c:\DATA\blade.st','ST')

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
supportedtypes = {'CTRCHG', 'MASCHG', 'PARSTUDY'};
allowedtype = supportedtypes(strcmpi(detectedfiletype,supportedtypes));

% Autodetect filetype if not specified (correctly)
if isempty(allowedtype)  
   
    if isempty(detectedfiletype)
        error(['Could not detect type of file ' filename '. Please, specify file type manually.'])
    end
end

%% Create decoder object

VTSDecoder = LAC.codec.VTSCodecLegacy(filename);


%% Create encoded object
outputformat = '';
if nargin > 2
    outputformat = varargin{2};
    outputfile   = fullfile(myfolder,[myfilename '.' lower(outputformat)]);
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
    decoded = LAC.fat1.codec.(char(detectedfiletype)).decode(VTSDecoder);
catch ME1
    disp(ME1.getReport())
    return
end


if isobject(decoded)
    if nargout>0
        varargout{1} = decoded;
    else
        warning('Cannot return object without output argument!')
    end
    if ~isempty(VTSEncoder)
        decoded.encode(VTSEncoder);
    end
    
end
