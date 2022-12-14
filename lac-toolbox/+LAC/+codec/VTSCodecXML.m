classdef VTSCodecXML < handle
    methods
        function self = VTSCodecXML(filename)
            self.filename = filename;
            try
                self.filedata = LAC.vts.shared.xml2struct(filename);
            catch ME
                self.filedata = [];
            end
            self.currentProperty = 1;
            self.currentTable = 1;
            self.currentList = 1;
            self.currentFile = 1;
        end
        
        function output = getSource(self)
            output = self.filename;
        end
        
        function varargout = get(self, varargin)
            varargout = cell(1,nargout);
            for i=1:nargout
                varargout{i} = self.filedata.section.properties.property{self.currentProperty}.Attributes.value;
                self.currentProperty = self.currentProperty + 1;
            end
        end
        
        function [type, filename] = getFile(self)
            type = self.filedata.section.files.file{self.currentFile}.Attributes.name;
            filename = self.filedata.section.files.file{self.currentFile}.Attributes.value;
            self.currentFile = self.currentFile + 1;
        end
        
        function [output] = getTable(self, ~)
            output = struct();
            
            tmpheader = self.readTableHeader();
            output = self.readTableData();
            output.header = tmpheader;
            
            self.currentTable = self.currentTable + 1;
        end
        
        % TBD: These function could replace LAC.vts.shared.ElementTable
        function [output] = readTableHeader(self)
            currenttable = self.filedata.section.tables.table;
            if iscell(currenttable)
                currenttable = currenttable{self.currentTable};
            end
            
            output = [];
            if isfield(currenttable, 'header')
               if isfield(currenttable.header, 'CDATA')
                    output = {currenttable.header.CDATA};
                end
            end
        end
        
        function [output] = readTableData(self, ~, ~)
            currenttable = self.filedata.section.tables.table;
            if iscell(currenttable)
                currenttable = currenttable{self.currentTable};
            end
            
            nRows = length(currenttable.row);
            nColumns = length(currenttable.row{1}.cell);
            output.data = cell(nRows,nColumns);
            output.rownames = cell(nRows,1);
            output.columnnames = cell(1,nColumns);
            for i=1:nRows
                for j=1:nColumns
                    output.data{i,j} = currenttable.row{i}.cell{j}.Attributes.value;
                    if i==1
                        output.columnnames{j} = currenttable.row{i}.cell{j}.Attributes.name;
                    end
                end
                
                if isfield(currenttable.row{i},'header')
                    output.rownames{i} = currenttable.row{i}.header.Text;
                end
            end
            
            index = find(strcmpi(output.columnnames,'comments'));
            if index
                output.columnnames = output.columnnames(~strcmpi(output.columnnames,'comments'));
                output.comments = output.data(:,index);
                output.data = output.data(:,[1:index-1 index+1:end]);
            end
            
            if isfield(output, 'columnnames')
                if isnan(sum(str2double(output.columnnames)))
                    output.datastruct = cell2struct(output.data, regexprep(output.columnnames,'[/-]',''), 2);
                end
            end
            
            if isfield(output, 'rownames')
                if cellfun('isempty', output.rownames)
                    output = rmfield(output,'rownames');
                end
            end
            
            self.currentTable = self.currentTable + 1;
        end
        
        
        function [output] = getList(self, startline, endline, ~)
            currentlist = self.filedata.section.lists.list;
            if iscell(currentlist)
                currentlist = currentlist{self.currentList};
            end
            
            nElements = length(currentlist.element);
            output.left = cell(nElements,1);
            output.right = cell(nElements,1);
            comments = cell(nElements,1);
            for i=1:nElements
                output.left{i} = currentlist.element{i}.left;
                output.right{i} = currentlist.element{i}.right;
                if isfield(currentlist.element{i},'comment')
                    comments{i} = currentlist.element{i}.comment;
                end
            end
            
            if sum(~cellfun('isempty', comments))
                output.comment = comments;
            end
            
            self.currentList = self.currentList + 1;
        end
        
        function output = getRemaininglines(self)
            output = self.filedata.section.comments.CDATA;
        end
        
        function initialize(self, name, type, myattributes)
            self.attributes = myattributes;
            
            self.filedata.section.Attributes.type = type;
            self.filedata.section.Attributes.name = name;
            self.filedata.section.properties.property = cell(1,length(self.attributes)-1);
        end
        
        function setProperty(self, varargin)
            %self.filedata.section.properties.property{self.currentProperty}.Attributes.name  = self.attributes{self.currentProperty};
            %self.filedata.section.properties.property{self.currentProperty}.Attributes.value = strjoin_LMT(varargin);
            
            data = varargin{1};
            switch class(data)
                case 'char'
                    self.filedata.section.properties.property{self.currentProperty}.Attributes.name  = self.attributes{self.currentProperty};
                    self.filedata.section.properties.property{self.currentProperty}.Attributes.value = data;
                    self.currentProperty = self.currentProperty + 1;
                case 'cell'
                    for i=1:length(data)
                        try
                            self.filedata.section.properties.property{self.currentProperty}.Attributes.name  = self.attributes{self.currentProperty};
                            self.filedata.section.properties.property{self.currentProperty}.Attributes.value = data{i};
                            self.currentProperty = self.currentProperty + 1;
                        catch ME
                           error(data{i})
                        end
                    end
                otherwise
                    error(class(data))
            end
        end
        
        function setFile(self, type, align, filename)
            self.filedata.section.files.file{self.currentFile} = struct();
            self.filedata.section.files.file{self.currentFile}.Attributes.name = type;
            self.filedata.section.files.file{self.currentFile}.Attributes.value = filename;
            self.currentFile = self.currentFile + 1;
        end
        
        function setTable(self, mystruct, ~)
            if isfield(mystruct, 'header')
                if ~isempty(mystruct.header)
                    if iscell(mystruct.header)
                        self.filedata.section.tables.table{self.currentTable}.header.CDATA = strjoin_LMT(mystruct.header','\n');
                    else
                        self.filedata.section.tables.table{self.currentTable}.header.CDATA = mystruct.header;
                    end
                end
            end
            
            if isfield(mystruct, 'comments') && isfield(mystruct,'columnnames')
                tmpdata = [mystruct.data mystruct.comments];
                tmpcolumnnames = [mystruct.columnnames {'comments'}];
            else
                tmpdata = mystruct.data;
                tmpcolumnnames = mystruct.columnnames;
            end
            [nRows, nColumns] = size(tmpdata);
            
            self.filedata.section.tables.table{self.currentTable}.row = cell(1,nRows);
            for i=1:nRows
                if isfield(mystruct,'rownames')
                    self.filedata.section.tables.table{self.currentTable}.row{i}.header.Text = mystruct.rownames{i};
                end
                self.filedata.section.tables.table{self.currentTable}.row{i}.cell = cell(1,nColumns);
                for j=1:nColumns
                    self.filedata.section.tables.table{self.currentTable}.row{i}.cell{j}.Attributes.name = tmpcolumnnames{j};
                    self.filedata.section.tables.table{self.currentTable}.row{i}.cell{j}.Attributes.value = tmpdata{i,j};
                end
            end
            
            self.currentTable = self.currentTable + 1;
        end
        
        % TBD: These function could replace LAC.vts.shared.ElementTable
        function writeTableHeader(self, header)
            if ~isempty(header)
                if iscell(header)
                    self.filedata.section.tables.table{self.currentTable}.header.CDATA = strjoin_LMT(header','\n');
                else
                    self.filedata.section.tables.table{self.currentTable}.header.CDATA = header;
                end
            end
        end
        
        function writeTableData(self, mystruct, ~)
            if isfield(mystruct, 'comments') && isfield(mystruct,'columnnames')
                tmpdata = [mystruct.data mystruct.comments];
                tmpcolumnnames = [mystruct.columnnames {'comments'}];
            else
                tmpdata = mystruct.data;
                tmpcolumnnames = mystruct.columnnames;
            end
            [nRows, nColumns] = size(tmpdata);
            
            self.filedata.section.tables.table{self.currentTable}.row = cell(1,nRows);
            for i=1:nRows
                if isfield(mystruct,'rownames')
                    self.filedata.section.tables.table{self.currentTable}.row{i}.header.Text = mystruct.rownames{i};
                end
                self.filedata.section.tables.table{self.currentTable}.row{i}.cell = cell(1,nColumns);
                for j=1:nColumns
                    self.filedata.section.tables.table{self.currentTable}.row{i}.cell{j}.Attributes.name = tmpcolumnnames{j};
                    self.filedata.section.tables.table{self.currentTable}.row{i}.cell{j}.Attributes.value = tmpdata{i,j};
                end
            end
            
            self.currentTable = self.currentTable + 1;            
        end
        
        function setList(self, mycell, ~)
            self.filedata.section.lists.list{self.currentList}.element = cell(1,length(mycell.left));
            for i = 1:length(mycell.left)
                self.filedata.section.lists.list{self.currentList}.element{i}.left  = mycell.left{i};
                self.filedata.section.lists.list{self.currentList}.element{i}.right = mycell.right{i};
                
                if isfield(mycell, 'comment')
                    if ~isempty(mycell.comment{i})
                        self.filedata.section.lists.list{self.currentList}.element{i}.comment = mycell.comment{i};
                    end
                end
            end
            self.currentList = self.currentList + 1;
        end
        
        function setLine(self, text)
            % Does nothing in XML
        end
        
        function setRemaininglines(self, comments)
            self.filedata.section.comments.CDATA = comments;
        end
        
        function status = save(self, varargin)
            if nargin>1
                destination = varargin{1};
            else
                destination = self.filename;
            end
            
            LAC.vts.shared.struct2xml( self.filedata, destination);
            self.currentProperty = 1;
            self.currentTable = 1;
            self.currentList = 1;
            self.currentFile = 1;
            status = true;
        end
        
        function output = current(self)
            % Not used for XML
            output = 0;
        end
        
        function rewind(self)
            self.currentProperty = 1;
            self.currentTable = 1;
            self.currentList = 1;
            self.currentFile = 1;
        end
        function jump(self, linenumber)
            % Not used for XML
        end
        function skip(self, lines)
            % Not used for XML
        end
        function output = lines(self, mystart, myend)
            % Not used for XML
            output = {};
        end
        function [lines] = search(self, text) 
            % Not used for XML
            lines = [];
            for i=1:length(self.filedata.section.properties.property)
                existing = [self.filedata.section.properties.property{i}.Attributes.name '='... 
                            self.filedata.section.properties.property{i}.Attributes.value];
                if ~isempty(regexpi(existing, text))
                    lines = existing;
                    return
                end
            end
            
            if isfield(self.filedata.section, 'tables')
                for i=1:length(self.filedata.section.tables.table)
                    existing = self.filedata.section.tables.table{i}.header.CDATA;
                    if ~isempty(regexpi(existing, text))
                        lines = existing;
                        return
                    end

                    for j=1:length(self.filedata.section.tables.table{i}.row)
                        if isfield(self.filedata.section.tables.table{i}.row{j}, 'header')
                            existing = self.filedata.section.tables.table{i}.row{j}.header.Text;
                            if ~isempty(regexpi(existing, text))
                                lines = existing;
                                return
                            end
                        end

                        for k=1:length(self.filedata.section.tables.table{i}.row{j}.cell)
                            existing = [self.filedata.section.tables.table{i}.row{j}.cell{k}.Attributes.name '='... 
                                        self.filedata.section.tables.table{i}.row{j}.cell{k}.Attributes.value];
                            if ~isempty(regexpi(existing, text))
                                lines = existing;
                                return
                            end
                        end
                    end
                end
            end
            
            if ~isempty(regexpi(self.filedata.section.comments.CDATA,text))
                lines = self.filedata.section.comments;
            end
        end
    end
    
    properties (Access = private)
        filedata
        filename
        currentProperty
        currentTable
        currentList
        currentFile
        attributes
    end
end
   