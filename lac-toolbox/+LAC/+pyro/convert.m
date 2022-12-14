function [varargout] = convert(filename, varargin)
% Read Pyro files. 
% When outputformat is specified a output file will be generated in the
% specified format (txt or xml).
% If two outputs are specified then a struct containing the contents of 
% the decoded file will be returned.
%
% SYNTAX:
%   [status [, decoded]] = LAC.fat1.convert <filename> [filetype] [outputformat]
%
% Supported filetype are:%   
%   'INP'
%
% Supported outputformats are:
%   TXT, XML
%
% EXAMPLES:
%   [status, decoded] = LAC.pyro.convert('c:\DATA\blade.st')
%   [status, decoded] = LAC.pyro.convert('c:\DATA\blade.st','ST')

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
supportedtypes = {'INP'};
allowedtype = supportedtypes(strcmpi(detectedfiletype,supportedtypes));

% Autodetect filetype if not specified (correctly)
if isempty(allowedtype)
    % Try to determine the type from file extension
    [~,fname, fileExtension] = fileparts(filename);
    fileExtension            = strtrim(strrep(fileExtension,'.',''));
    detectedfiletype         = upper(supportedtypes(strcmpi(fileExtension,supportedtypes)));
    
    if isempty(detectedfiletype)
        ErrorMessage{end+1} = ['Could not detect type of file ' filename '. Please, specify file type manually.'];
    end
end

%% Create decoder object

VTSDecoder = LAC.codec.CodecTXT(filename);


%% Decode object

try
    decoded = LAC.pyro.codec.(char(detectedfiletype)).decode(VTSDecoder);
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
end
