classdef ElementLine < handle
    methods
        function varargout = decode(self, FID, varargin)
            numberofoutputs = nargout;
            numberofinputs = nargin;
            if numberofoutputs==1
                if numberofinputs==3
                    % Read whole line
                    result = textscan(FID, '%s', numberofoutputs, 'delimiter', '\n');
                    varargout{1} = strtrim(char(result{1}(1)));
                else
                    result = textscan(FID, '%s', numberofoutputs);
                    varargout{1} = strtrim(char(result{1}(1)));
                    
                    % Read the rest of the line
                    textscan(FID, '%s', 1, 'delimiter', '\n');
                end
            else
                result= textscan(FID, '%s', numberofoutputs);
                for k=1:numberofoutputs
                    varargout{k} = char(result{1}(k));
                end
                % Read the rest of the line
                textscan(FID, '%s', 1, 'delimiter', '\n');
            end
        end
        
        function encode(self, FID, varargin)
            numberofinputs = nargin - 2;
            if numberofinputs>0
                formatstr = [deblank(repmat('%s ', 1, numberofinputs)) '\n'];
                fprintf(FID, formatstr, varargin{:});
            end
        end
    end
end
   