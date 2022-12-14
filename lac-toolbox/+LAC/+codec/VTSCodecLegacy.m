classdef VTSCodecLegacy < handle
    methods
        function self = VTSCodecLegacy(filename)
            self.filename = filename;     
        end
        
        function fid = openFile(self)
             % Read entire file into memory
            [fid, ~] = fopen(self.filename,'rt');
            if fid == 0
                error(['!! The file could not be opened: ' self.filename])
            end
        end
        
        function data = readFile(self)
            % Read entire file into memory
            [fid, ~] = fopen(self.filename,'rt');
            if fid == 0
                error(['!! The file could not be opened: ' self.filename])
            end     
            
            data = textscan(fid,'%s','delimiter','\n');
            fclose(fid);
            
            
        end
        function output = getSource(self)
            output = self.filename;
        end

    end
    
    properties (Access = private)
        filedata
        filename
        lineno
    end
    
    methods
        
        function iline = findline(~,cline,SearchString)
            
            iline = 1;
            LineString = blanks(100);
            while ~strcmpi(LineString(1:length(SearchString)),SearchString) && iline
                LineString = blanks(100);
                LineString(1:length(cline{iline})) = cline{iline};
                iline = iline + 1;
                if iline > length(cline)
                    iline = 0;
                end
            end
            iline = iline - 1;
        end
        
        
        function para_out = readline(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out = para_in;
            curline = cline{iline};
            parastring = strread(curline,'%s');
            for ipara = 1:length(FieldName)
                para_out.(FieldName{ipara}) = str2double(parastring{ipara});
            end
        end
        
        function para_out = readtable(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out        = para_in;
            curline         = cline{iline};
            NumRowString    = strread(curline,'%s');
            NumRow          = str2double(NumRowString{1});
            
            for ipara = 1:length(FieldName)
                para_out.(FieldName{ipara}) = zeros(NumRow,1);
            end
            
            for irow = 1:NumRow
                curline     = cline{iline+1+irow};
                parastring = strread(curline,'%s');
                for ipara = 1:length(FieldName)
                    para_out.(FieldName{ipara})(irow) = str2double(parastring{ipara});
                end
            end
        end
        
        function para_out = readtable2(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out        = para_in;
            curline         = cline{iline};
            NumString       = strread(curline,'%s');
            NumRow          = str2double(NumString{1});
            NumCol          = str2double(NumString{2});
            
            HeadLine        = strread(cline{iline+1},'%s');
            
            para_out.(FieldName{1}) = zeros(NumRow,NumCol);
            para_out.(FieldName{2}) = zeros(NumRow,1);
            para_out.(FieldName{3}) = str2double(HeadLine(1:NumCol));
            
            for irow = 1:NumRow
                curline     = cline{iline+1+irow};
                linestring = strread(curline,'%s');
                para_out.(FieldName{2})(irow) = str2double(linestring{1});
                para_out.(FieldName{1})(irow,:) = str2double(linestring(2:NumCol+1));
            end
        end
     end

    
end
   