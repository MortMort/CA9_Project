classdef Part_Common < handle & matlab.mixin.Copyable
    methods
        function [status, output] = compare(self, obj)
            output = struct();
            
            selfattr = self.getAttributes();
            objattr = obj.getAttributes();
            
            attributesOk = isequal(selfattr,objattr);
            
            if attributesOk
                righthand = obj.convertAllToString();
                lefthand  = self.convertAllToString();
                
                for i = 1:length(selfattr.properties)
                    if isequal(lefthand.(selfattr.properties{i}), righthand.(selfattr.properties{i}))
                        output.(selfattr.properties{i}) = [];
                    else
                        output.(selfattr.properties{i}) = ['"' lefthand.(selfattr.properties{i}) '" ~= "' righthand.(selfattr.properties{i}) '"'];
                    end
                end
                for i = 1:length(selfattr.tables)
                    table1 = lefthand.(selfattr.tables{i});
                    if isstruct(lefthand.(selfattr.tables{i}))
                        table1 = {lefthand.(selfattr.tables{i})};
                    end
                    
                    table2 = righthand.(selfattr.tables{i});
                    if isstruct(righthand.(selfattr.tables{i}))
                        table2 = {righthand.(selfattr.tables{i})};
                    end
                    
                    output.(selfattr.tables{i}) = [];
                    if ~isequal(table1, table2)
                        try
                            tmp1 = setdiff(table1{i}.data, table2{i}.data);
                            tmp2 = setdiff(table2{i}.data, table1{i}.data);
                            if ~isempty(tmp1) && ~isempty(tmp2)
                                output.(selfattr.tables{i}) = ['"' strjoin_LMT(tmp1,'\n') '" ~= "' strjoin_LMT(tmp2,'\n') '"'];
                            end
                        catch
                            output.(selfattr.tables{i}) = 'Not equal';
                        end
                    end
                end
                
                if isfield(lefthand,'Files')
                    filetypes = lefthand.Files.keys;
                    for i = 1:length(filetypes)

                        if isequal(lefthand.Files(filetypes), righthand.Files(filetypes))
                            output.(selfattr.files{i}) = [];
                        else
                            output.(selfattr.files{i}) = ['"' lefthand.Files(selfattr.files{i}) '" ~= "' righthand.Files(selfattr.files{i}) '"'];
                        end
                    end
%                 for i = 1:length(selfattr.files)
%                     if isequal(lefthand.Files(selfattr.files{i}), righthand.Files(selfattr.files{i}))
%                         output.(selfattr.files{i}) = [];
%                     else
%                         output.(selfattr.files{i}) = ['"' lefthand.Files(selfattr.files{i}) '" ~= "' righthand.Files(selfattr.files{i}) '"'];
%                     end
%                 end
                end
            end
            
            status = cellfun(@(x) isempty(x), struct2cell(output), 'uni',false);
            status = all([status{:}]);            
        end
        
        function [status, output] = verify(self)
            output = struct();
            
            myattr = self.getAttributes();
            
            % Are all public properties set?
            for i = 1:length(myattr.properties)
                output.(myattr.properties{i}) = false;
                if ~isempty(self.(myattr.properties{i}))
                    output.(myattr.properties{i}) = true;
                else
                    if strcmpi(myattr.properties{i},'comments') % It is ok with no comments!
                        output.(myattr.properties{i}) = true;
                    end
                end
            end
            
            % Does all files exist?
            for i = 1:length(myattr.files)
                output.(myattr.files{i}) = false;
                try
                    if isKey(self.Files, myattr.files{i})
                        if exist(self.Files(myattr.files{i}),'file') >= 2
                            output.(myattr.files{i}) = true;
                        end
                    else
                        % It is ok that not all files are set, some files are optional.
                        output.(myattr.files{i}) = true;
                    end
                catch ME
                    % We do not want to stop execution when verifying - print
                    % error only
                    disp(ME.getReport())
                end
            end
            
            status = struct2cell(output);
            status = all([status{:}]);
        end
        
        function output = toTXT(self, varargin)
            output = '';
            
            tmpTXTfile = [tempname '.txt'];
            VTSEncoder = LAC.codec.CodecTXT(tmpTXTfile);
            self.encode(VTSEncoder);
            [FID, ~] = fopen(tmpTXTfile,'rt');
            if FID > 0
                tmp = textscan(FID, '%s', -1, 'whitespace', '', 'delimiter', '\n');
                fclose(FID);
                output = strjoin_LMT(tmp{1}','\n');
            end
            
            if nargin > 1
                if ~exist(varargin{1},'file')
                    if ~strcmpi(varargin{1}(end-3:end),'.txt')
                        throw(MException('Part_Common:toTXT','!!Illegal input. extention of file must be .txt'));
                    end
                    copyfile(tmpTXTfile, varargin{1});
                else
                    throw(MException('Part_Common:toTXT',['Output file already exist ' char(varargin{1}) '. Will not continue.']));
                end
            end
            
            delete(tmpTXTfile);
        end
        
        function self = fromTXT(self, inputtext)
            if isstruct(inputtext)
                throw(MException('Part_Common:fromTXT','!!Illegal input. Are you sure that input is TXT?'));
            end
            
            tmpTXTfile = [tempname '.txt'];
            
            if exist(inputtext,'file')
                %if ~strcmpi(inputtext(end-3:end),'.txt')
                if any(strcmpi(inputtext(end-3:end),{'.xml','.json','.mat'}))
                    throw(MException('Part_Common:fromTXT','!!Illegal input. extention of file must be .txt'));
                end
                %copyfile(inputtext, tmpTXTfile); % Creates a problem when translating relative paths in CTR or BLD parts
                tmpTXTfile = inputtext;
            else
                % Write to file and decode
                [FID, ~] = fopen(tmpTXTfile,'wt');
                if FID > 0
                    if iscell(inputtext)
                        inputtext = strjoin_LMT(inputtext,'\n');
                    end
                    fprintf(FID, '%s\n', inputtext);
                    fclose(FID);
                end
            end
            
            try
                VTSDecoder = LAC.codec.CodecTXT(tmpTXTfile);
                self = eval([ class(self) '.decode(VTSDecoder)']);
            catch ME
                ME.getReport()
            end
            
            if ~strcmpi(inputtext, tmpTXTfile)
                %throw(MException('Part_Common:fromTXT','!!TBD exception'));
                %delete(tmpTXTfile);
            end
        end
        
        function output = toStruct(self, varargin)
            output = struct();
            
            myattributes = self.getAttributes();
            for i = 1:length(myattributes.properties)
                output.(myattributes.properties{i}) = self.(myattributes.properties{i});
            end
            
            for i = 1:length(myattributes.tables)
                output.(myattributes.tables{i}) = self.(myattributes.tables{i});
            end
            
            for i = 1:length(myattributes.files)
                if ischar(self.Files(myattributes.files{i}))
                    output.(myattributes.files{i}) = self.Files(myattributes.files{i});
                else
                    fields = self.(myattributes.files{i}).keys;
                    for j=1:length(fields)
                        output.(fields{j}) = self.(myattributes.files{i})(fields{j});
                    end
                end
            end
            
            if nargin > 1
                if ~exist(varargin{1},'file')
                    if ~strcmpi(varargin{1}(end-3:end),'.mat')
                        throw(MException('Part_Common:toStruct','!!Illegal input. Extention of file must be .mat'));
                    end
                    save(varargin{1},'output');
                else
                    throw(MException('Part_Common:toStruct',['Output file already exist ' char(varargin{1}) '. Will not continue.']));
                end
            end
        end
        
        function self = fromStruct(self, inputstruct)
            if ~isstruct(inputstruct)
                if exist(inputstruct,'file')
                    if ~strcmpi(inputstruct(end-3:end),'.mat')
                        throw(MException('Part_Common:fromStruct','!!Illegal input. Extention of file must be .mat'));
                    end
                    S = load(inputstruct);
                    self.fromStruct(S.output);
                else
                    throw(MException('Part_Common:fromStruct','!!Illegal input. Are you sure that input is struct?'));
                end
            else
                myattributes = self.getAttributes();
                for i = 1:length(myattributes.properties)
                    self.(myattributes.properties{i}) = inputstruct.(myattributes.properties{i});
                end

                for i = 1:length(myattributes.tables)
                    self.(myattributes.tables{i}) = inputstruct.(myattributes.tables{i});
                end

                % WORKAROUND: JSON does not load tables in to proper struct
                for i = 1:length(myattributes.tables)
                    if ~iscell(self.(myattributes.tables{i}))
                        self.(myattributes.tables{i}) = {self.(myattributes.tables{i})};
                        if iscell(self.(myattributes.tables{i}){1}.data{1})
                            self.(myattributes.tables{i}){1}.data = reshape([self.(myattributes.tables{i}){1}.data{:}],length(self.(myattributes.tables{i}){1}.data{1}),length(self.(myattributes.tables{i}){1}.columnnames));
                        end
                    end
                end

                for i = 1:length(myattributes.files)
                    self.Files(myattributes.files{i}) = inputstruct.(myattributes.files{i});
                end
            end
        end
        
        function output = toJSON(self, varargin)
            output = self.convertAllToString();
            
            if nargin > 1
                if ~exist(varargin{1},'file')
                    if ~strcmpi(varargin{1}(end-4:end),'.json')
                        throw(MException('Part_Common:toJSON','!!Illegal input file extension. Are you sure that input is JSON?'));
                    end
                    output = LAC.vts.shared.jsonlab.savejson('',output.toStruct(),varargin{1});
                else
                    throw(MException('Part_Common:toJSON',['Output file already exist ' char(varargin{1}) '. Will not continue.']));                    
                end
            else
                output = LAC.vts.shared.jsonlab.savejson('',output.toStruct());
            end
        end
        
        function self = fromJSON(self, inputjson)
            if isstruct(inputjson)
                throw(MException('Part_Common:fromJSON','!!Illegal input. Are you sure that input is JSON?'));
            end
            if strcmpi(inputjson(1:5), '<?xml')
                throw(MException('Part_Common:fromJSON','!!Illegal input. Are you sure that input is JSON?'));
            end
            
            if exist(inputjson,'file')
                if ~strcmpi(inputjson(end-4:end),'.json')
                    throw(MException('Part_Common:fromJSON','!!Illegal input file extension. Are you sure that input is JSON?'));
                end
            end
            
            tmp = LAC.vts.shared.jsonlab.loadjson(inputjson);
            self = self.fromStruct(tmp);
            self = self.convertAllToNumeric();
        end
        
        function output = toXML(self, varargin)
            output = '';
            
            tmpXMLfile = [tempname '.xml'];
            VTSEncoder = LAC.vts.shared.VTSCodecXML(tmpXMLfile);
            self.encode(VTSEncoder);
            [FID, ~] = fopen(tmpXMLfile,'rt');
            if FID > 0
                tmp = textscan(FID, '%s', -1, 'whitespace', '', 'delimiter', '\n');
                fclose(FID);
                output = strjoin_LMT(tmp{1}','\n');
            end
            
            if nargin > 1
                if ~exist(varargin{1},'file')
                    if ~strcmpi(varargin{1}(end-3:end),'.xml')
                        throw(MException('Part_Common:toXML','!!Illegal input. extention of file must be .xml'));
                    end
                    copyfile(tmpXMLfile, varargin{1});
                else
                    throw(MException('Part_Common:toXML',['Output file already exist ' char(varargin{1}) '. Will not continue.']));
                end
            end
            
            delete(tmpXMLfile);
        end
        
        function self = fromXML(self, inputxml)
            if isstruct(inputxml)
                throw(MException('Part_Common:fromXML','!!Illegal input. Are you sure that input is XML?'));
            end
            
            tmpXMLfile = [tempname '.xml'];
            
            if exist(inputxml,'file')
                if ~strcmpi(inputxml(end-3:end),'.xml')
                    throw(MException('Part_Common:fromXML','!!Illegal input. extention of file must be .xml'));
                end
                copyfile(inputxml, tmpXMLfile);
            else
                if ~strcmpi(inputxml(1:5), '<?xml')
                    throw(MException('Part_Common:fromXML','!!Illegal input. Are you sure that input is XML?'));
                end
                
                % Write to file and decode
                [FID, ~] = fopen(tmpXMLfile,'wt');
                if FID > 0
                    if iscell(inputxml)
                        inputxml = strjoin_LMT(inputxml,'\n');
                    end
                    fprintf(FID, '%s\n', inputxml);
                    fclose(FID);
                end
            end
            
            try
                VTSDecoder = LAC.vts.shared.VTSCodecXML(tmpXMLfile);
                self = eval([ class(self) '.decode(VTSDecoder)']);
            catch ME
                ME.getReport()
            end
            
            delete(tmpXMLfile);
        end
        
        
        function self = convertAllToNumeric(self)
            myattributes = self.getAttributes();
            for i = 1:length(myattributes.properties)
                if all(ismember(self.(myattributes.properties{i}), '0123456789+-.eEdD'))
                    if ~isempty(self.(myattributes.properties{i}))
                        if ~strcmpi(self.(myattributes.properties{i}),'-') % Do not convert cells containing '-'
                            self.(myattributes.properties{i}) = str2double(self.(myattributes.properties{i}));
                        end
                    end
                else
                    specialHTMLchars = regexp(self.(myattributes.properties{i}), '(&[#a-zA-Z0-9]{1,4}+;)', 'tokens');
                    if ~isempty(specialHTMLchars)
                        self.(myattributes.properties{i}) = self.convertSpecialHTMLChars(self.(myattributes.properties{i}), specialHTMLchars);
                    end
                end
            end
            
            for i = 1:length(myattributes.tables)
                for j = 1:size(self.(myattributes.tables{i}){1}.data,1)
                    for k = 1:size(self.(myattributes.tables{i}){1}.data,2)
                        if all(ismember(self.(myattributes.tables{i}){1}.data{j,k}, '0123456789+-.eEdD'))
                            if ~isempty(self.(myattributes.tables{i}){1}.data{j,k})
                                if ~strcmpi(self.(myattributes.tables{i}){1}.data{j,k},'-') % Do not convert cells containing '-'
                                    self.(myattributes.tables{i}){1}.data{j,k} =  str2double(self.(myattributes.tables{i}){1}.data{j,k});
                                end
                            end
                        else
                            specialHTMLchars = regexp(self.(myattributes.tables{i}){1}.data{j,k}, '(&[#a-zA-Z0-9]{1,4}+;)', 'tokens');
                            if ~isempty(specialHTMLchars)
                                self.(myattributes.tables{i}){1}.data{j,k} = self.convertSpecialHTMLChars(self.(myattributes.tables{i}){1}.data{j,k}, specialHTMLchars);
                            end
                        end
                    end
                end
            end
        end
        
        function self = convertAllToString(self)
            myattributes = self.getAttributes();
            for i = 1:length(myattributes.properties)
                if isnumeric(self.(myattributes.properties{i}))
                    self.(myattributes.properties{i}) = num2str(self.(myattributes.properties{i}));
                end
            end
            
            for i = 1:length(myattributes.tables)
                for j = 1:size(self.(myattributes.tables{i}){1}.data,1)
                    for k = 1:size(self.(myattributes.tables{i}){1}.data,2)
                        if isnumeric(self.(myattributes.tables{i}){1}.data{j,k})
                            self.(myattributes.tables{i}){1}.data{j,k} = num2str(self.(myattributes.tables{i}){1}.data{j,k});
                        end
                    end
                end
            end
        end
        
    end
    
    methods (Access=private)
        function text = convertSpecialHTMLChars(~, text, specialCharacters)
            % http://www.ascii.cl/htmlcodes.htm
            supportedChars = {'"','&quot;'; ...
                              '&','&amp;'; ...
                              '<','&lt;'; ...
                              '>','&gt;'};
            found = supportedChars(strcmpi(supportedChars(:,2), specialCharacters{:}),:);
            if ~isempty(found)
                for i = 1: size(found,1)
                    text = strrep(text, found{1,2}, found{1,1});
                end
            end
        end
    end
    
    properties (Access=protected)
        FileName
        Type
    end
end
