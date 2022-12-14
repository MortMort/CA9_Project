function varargout = textread_compiler(varargin);
% TEXTREAD_COMPILER : Performs a 'textread' which is compatible with the Matlab compiler
% 
% The 'textread' function supplied with Matlab is not compatible with the Matlab compiler
% due to the use of the 'which' function
%
% textread_compiler has the same input and output parameters as 'textread'
% Difference between the 2 are that some error checked on input parameters has been omitted
% in 'textread_compiler'
%
% See also TEXTREAD
%
% JEB, January 14, 2002


% do some preliminary error checking
narginchk(1, inf)

% The following 3 commented lines is present in 'textread'
%if (exist(varargin{1}) ~= 2 | exist(fullfile(cd,varargin{1})) ~= 2) & ~isempty(which(varargin{1}))
%    varargin{1} = which(varargin{1});
%end

if exist(varargin{1}) ~= 2
    error('File not found.');
end

if nargout == 0
    nlhs = 1;
else
    nlhs = nargout;
end

[varargout{1:nlhs}]=dataread('file',varargin{:});
