classdef CodecTXT < handle

    methods
        function self = CodecTXT(filename)
            self.filename = filename;
                
            % Read entire file into memory
            [FID, ~] = fopen(self.filename,'rt');
            if FID > 0
                self.filedata = textscan(FID, '%s', -1, 'whitespace', '', 'delimiter', '\n'); %#ok<BUFSIZE> % 'BufSize', 65535
                fclose(FID);
                self.filedata = self.filedata{1};
                if ~isempty(self.filedata) %check for empty file in location, could be left behind by a previous crash
                    if length(self.filedata{1}) > 4
                        if (self.isunicode('string',self.filedata{1}) == 2 || self.isunicode('string',self.filedata{1}) == 3) 
                            for i = 1:length(self.filedata)
                               XXX = unicode2native(self.filedata{i});
                               self.filedata{i} = char(XXX(XXX~=0));
                            end
                        end
                    end
                else
                     warning(['!! The file was empty: ' self.filename]);     
                end
            else
                self.filedata = {};
                warning(['!! The file could not be opened: ' self.filename]);
            end
            self.lineno = 1;
        end
        
        function output = isfile(self)
            output = exist(self.filename,'file');
        end
        
        
        function output = getSource(self)
            output = self.filename;
        end
        
        function varargout = get(self, varargin)
            numberofoutputs = nargout;
            numberofinputs = nargin;
            
            if numberofoutputs==1
                if numberofinputs==2
                    % Read whole line
                    varargout{1} = self.filedata{self.lineno};
                    %result = textscan(self.filedata{self.lineno}, '%s', numberofoutputs, 'delimiter', '\n');
                    %varargout{1} = strtrim(char(result{1}(1)));
                else
                    result = textscan(self.filedata{self.lineno}, '%s', numberofoutputs);
                    varargout{1} = strtrim(char(result{1}(1)));
                end
            else
                varargout = cell(1,numberofoutputs);
                if ~isempty(self.filedata{self.lineno})
                    if numberofinputs==2
                        % Read whole line
                        result = textscan(self.filedata{self.lineno}, '%s');
                        if length(result{1}) < numberofoutputs
                            numberofoutputs = length(result{1});
                            result = result{1};
                        else
                            result = {result{1}{1:numberofoutputs-1} strjoin_LMT(result{1}(numberofoutputs:end)')};
                        end
                    else
                        result = textscan(self.filedata{self.lineno}, '%s', numberofoutputs);
                        result = result{1};
                    end
                    
                    for k=1:numberofoutputs
                        varargout{k} = char(result(k));
                    end
                end
            end
            self.lineno = self.lineno+1;
        end
        
        function [output] = getData(self)
            output=self.filedata;
        end
        
        
        function [type, filename] = getFile(self)
            %[type, filename] = self.get(); % Old implementation
            
            line = self.get(true);
            line = strsplit_LMT(strtrim(line));
            filename = line{end};
%             type = strjoin_LMT(line(1:end-1));
            type = line{1};
            
        end
        
        function [output] = getTable(self, tabletype)
            output = LAC.codec.ElementTable.decode(self, tabletype);
        end
        function [output] = readTableHeader(self)
            output = self.lines(self.lineno,self.lineno);
            self.skip(1);
        end
        function [output] = readTableData(self, rows, columns)
            output = LAC.codec.ElementTable.readTable(self, rows, columns);
        end
        
        
        
        function [output] = getList(self, startline, endline, separator)
            rawdata = self.lines(startline,endline);
            
            tmp = cellfun(@(x) textscan(x,['%s ' separator ' %[^;]%[ ;%]%[^%\n]']), rawdata,'uni',false);
            %tmp = cellfun(@(x) strsplit_LMT(x, separator), rawdata,'uni',false);
            
            % Remove lines without the seperator 
            tmp = tmp(~cellfun(@(x) isempty(x), cellfun(@(x) [x{2}{:}], tmp,'uni',false)));
            
            output.left    = strtrim(cellfun(@(x) x{1}{:}, tmp,'uni',false));
            output.right   = strtrim(cellfun(@(x) x{2}{:}, tmp,'uni',false));
            output.comment = cellfun(@(x) [x{4}{:}], tmp,'uni',false);
            
            if all(cell2mat(cellfun(@(x) isempty(x), output.comment, 'UniformOutput', false)))
                output = rmfield(output,'comment');
            end
            
            self.skip(length(rawdata));
        end
        
        function output = getRemaininglines(self)
            output = strjoin_LMT(self.filedata(self.lineno:end)','\n');
        end
        
        function initialize(self, name, type, myattributes)
            % Not used in TXT
        end
        
        function setProperty(self, varargin) % With description after value
            switch nargin
                case 2
                    self.filedata{self.lineno} = strjoin_LMT(varargin);
                case 3
                    self.filedata{self.lineno} = strjoin_LMT(strjoin_LMT(varargin), varargin{3});
                case 4
                    if varargin{2}>=0
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%-' num2str(varargin{2}) 's'], strjoin_LMT(varargin{1}))}, varargin{3}]);
                    else
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%' num2str(varargin{2}) 's'], varargin{3})}, strjoin_LMT(varargin{1})]);
                    end
                otherwise
                    error('TBD')
            end
            self.lineno=self.lineno+1;
        end
        
        function setPropertyReversed(self, varargin) % With description in front of value
            switch nargin
                case 2
                    self.filedata{self.lineno} = strjoin_LMT(varargin);
                case 3
                    self.filedata{self.lineno} = strjoin_LMT(varargin{3}, strjoin_LMT(varargin));
                case 4
                    if varargin{2}>=0
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%-' num2str(varargin{2}) 's'], varargin{3})}, strjoin_LMT(varargin{1})]);
                    else
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%' num2str(varargin{2}) 's'], strjoin_LMT(varargin{1}))}, varargin{3}]);
                    end
                case 5 % With unit
                    if varargin{2}>=0
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%-' num2str(varargin{2}) 's'], varargin{3})}, strjoin_LMT(varargin{1}), varargin{4}]);
                    else
                        self.filedata{self.lineno} = strjoin_LMT([{sprintf(['%' num2str(varargin{2}) 's'], strjoin_LMT(varargin{1}))}, varargin{3}], varargin{4});
                    end
                    
                otherwise
                    error('TBD')
            end
            self.lineno=self.lineno+1;
        end
        
        function setFile(self, type, align, filename)
            setProperty(self, {type}, align, filename);
        end
        
        
        function setTable(self, mystruct, tableType)
            LAC.codec.ElementTable.encode(self, mystruct, tableType);
        end
        function writeTableHeader(self, header)
            self.setLine(strjoin_LMT(header,'\n'));
        end
        function writeTableData(self, mydata, strformat)
            LAC.codec.ElementTable.writeTable(self, mydata, strformat);
        end
        
        
        function setList(self, mycell, separator)
            maxlength = cellfun(@(x) length(x), mycell.left,'uni',false);
            maxlength = max([maxlength{:}]);
            column1 = cellfun(@(x) sprintf(['%-' num2str(maxlength) 's'],x), mycell.left, 'uni',false);
            
            if isfield(mycell, 'comment')
                maxlength = cellfun(@(x) length(x), mycell.right,'uni',false);
                maxlength = max([maxlength{:}]);
                column2 = cellfun(@(x) sprintf(['%-' num2str(maxlength) 's'],x), mycell.right, 'uni',false);
                column3 = cellfun(@(x) [' ;   % ' x], mycell.comment, 'uni',false);
                
                tmp = [column1 column2 column3];
                for i= 1:length(mycell.left)
                    self.setLine(strjoin_LMT([strjoin_LMT(tmp(i,1:2),separator) tmp(i,3)]));
                end
            else
                tmp = [column1 mycell.right];
                for i= 1:length(mycell.left)
                    self.setLine(strjoin_LMT(tmp(i,1:2),separator));
                end
            end
        end
        
        function setLine(self, text)
            self.filedata{self.lineno} = text;
            self.lineno=self.lineno+1;
        end
        
        function insertLine(self, text,direction)
            if nargin < 3
                direction = 'before';
            end
        
            switch direction
                case 'after'
                    self.filedata = [self.filedata(1:self.lineno); text; self.filedata(self.lineno+1:end)];
                    
                case 'before'
                    
                    if self.lineno==1
                        self.filedata = [text; self.filedata(self.lineno:end)];
                    else
                        self.filedata = [self.filedata(1:self.lineno-1); text; self.filedata(self.lineno:end)];
                    end
            end           
                    
            self.lineno=self.lineno+1;
        end
        
        function replaceLine(self,lineNo,str)
            self.filedata{lineNo} = str;
        end
        
        function deleteLines(self,first,last)
            self.filedata = [self.filedata(1:first-1); self.filedata(last+1:end)];
        end
        
        function setRemaininglines(self, comments)
            self.filedata(self.lineno:end) = [];
            [n,m] = size(self.filedata);
            if n < m
                self.filedata = [self.filedata strsplit_LMT(comments,'\n')];
            else
                self.filedata = [self.filedata' strsplit_LMT(comments,'\n')]';
            end                
        end
        
        function output = searchAndReplace(self, oldsubstr,newsubstr)
            % Search and replace string in file
            self.filedata = strrep(self.filedata,oldsubstr,newsubstr);
        end
        

        function status = save(self, varargin)
            status = false;
            if nargin>1
                destination = varargin{1};
            else
                destination = self.filename;
            end
            
            [FID, ~] = fopen(destination,'wt');
            if FID > 0
                fprintf(FID, '%s\n', self.filedata{:});
                fclose(FID);
                self.filename = destination;
                self.rewind();
                status = true;
            end
        end
        
        function [output, txt] = current(self)
            output = self.lineno;
            txt    = self.filedata{self.lineno};
        end
        
        function rewind(self)
            self.lineno = 1;
        end
        
        function jump(self, linenumber)
            self.lineno = linenumber;
        end
        
        function skip(self, lines)
            self.lineno = self.lineno + lines;
        end

        % PESEG 2012 - this function just gets one line at index mystart,
        % without affecting the current lineno
        function output = getLine(self, mystart)
           output = self.filedata{mystart};
        end
        
        function output = lines(self, mystart, myend)
            if strcmpi(myend,'end') || myend<=0 || myend>length(self.filedata)
                output = self.filedata(mystart:end);
            else
                output = self.filedata(mystart:myend);
            end
        end
        
        function [lines, lineno] = search(self, text, option) 
            % Set lineno to first occurrence of text, return all lines
            % containing the text
            if nargin>2 && strcmp(option,'exact')
                lineno = strcmp(self.filedata, text); 
            else
                lineno = not(cellfun('isempty', regexpi(self.filedata,text)));
            end
            lines = self.filedata(lineno);
            if sum(lineno)
                lineno = find(lineno);
                self.lineno = lineno(1);
            end
        end
        
        function isuc = isunicode(self, filename, varargin)
        %ISUNICODE Checks if and which unicode header a file has.
        %  ISUC = ISUNICODE(FILENAME)
        %  ISUC = ISUNICODE('string', TEXTSTRING)
        %  ISUC is true if the file contains unicode characters, otherwise
        %  false. Exact Information about the encoding is also given.
        %  ISUC == 0: No UTF Header
        %  ISUC == 1: UTF-8
        %  ISUC == 2: UTF-16BE
        %  ISUC == 3: UTF-16LE
        %  ISUC == 4: UTF-32BE
        %  ISUC == 5: UTF-32LE
        %
        %  (c) Version 1.0 by Stefan Eireiner (<a href="mailto:stefan.eireiner@siemens.com?subject=isunicode">stefan.eireiner@siemens.com</a>)
        %  last change 10.04.2006

        isuc = false;
        if(nargin == 3)
            if(strcmpi(filename, 'string'))
                firstLine = varargin{1}(1:4);
            end
        end

%         if(~exist('firstLine', 'var'))
%             fin = fopen(filename,'r');
%             if (fin == -1) %does the file exist?
%                 error(['File ' filename ' not found!'])
%                 return;
%             end
%             fileInfo = dir(filename);
%             if(fileInfo.bytes < 4) % a unicode file incl. header can't be smaller than 4 bytes if it shall display at least one char.
%                 return;
%             end
%             firstLine = fread(fin,4)';
%         end
      
        % assign all possible headers to variables
        utf8header    = [hex2dec('EF') hex2dec('BB') hex2dec('BF')];
        utf16beheader = [hex2dec('FE') hex2dec('FF')];
        utf16leheader = [hex2dec('FF') hex2dec('FE')];
        utf32beheader = [hex2dec('00') hex2dec('00') hex2dec('FE') hex2dec('FF')];
        utf32leheader = [hex2dec('FF') hex2dec('FE') hex2dec('00') hex2dec('00')];

        % compare first bytes with header
        if(strfind(firstLine, utf8header) == 1)
                isuc = 1;
        elseif(strfind(firstLine, utf16beheader) == 1)
                isuc = 2;
        elseif(strfind(firstLine, utf16leheader) == 1)
                isuc = 3;
        elseif(strfind(firstLine, utf32beheader) == 1)
                isuc = 4;
        elseif(strfind(firstLine, utf32leheader) == 1)
                isuc = 5;
        end

%         if(~exist('firstLine', 'var'))
%             fclose(fin);
%         end
 
        end
        
        
    end
    
    properties (Access = private)
        filedata
        filename
        lineno
    end
    
    
end
   