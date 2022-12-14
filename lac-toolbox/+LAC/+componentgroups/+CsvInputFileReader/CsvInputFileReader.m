classdef CsvInputFileReader < hgsetget
    properties
        LineItems
        Filename
    end
    
    methods
        function Self = ReadFile(Self, filename)
            % Read all lines.
            Fid = fopen(filename);
            Lines = textscan(Fid,'%s','delimiter','\n');
            Lines = Lines{1};
            fclose(Fid);
            
            % Save filename.
            Self.Filename = filename;
            
            % Initiate.
            Self.LineItems = LAC.componentgroups.CsvInputFileReader.LineItem;
            
            % Loop through lines.
            nLines = length(Lines);
            for iLine=1:nLines
                
                if iLine == 1;
                    % This is the header.
                    continue
                end
                
                % Set local.
                Line = Lines{iLine};
                
                % New item.
                line_item = LAC.componentgroups.CsvInputFileReader.LineItem();
                
                % Parse.
                Result = strsplit_LMT(Line, ';');
                line_item.Abriviation = strtrim(Result{1});
                
                % Check if the input is with comma or dot format. If its
                % comma formated then it replaces the "," with a ".".
                line_item.Value = str2double(strrep(strtrim(Result{2}),',','.'));
                
                if ~isempty(strtrim(Result{3}))
                    line_item.Explanation = strtrim(Result{3});
                end
                if ~isempty(strtrim(Result{4}))
                    line_item.Comments = strtrim(Result{4});
                end
                
                % Set value.
                Self.LineItems(end+1) = line_item;
            end
        end
        function value = get_value_by_name(Self, name)
            line_item = findobj(Self.LineItems,'Abriviation',name);
            if length(line_item) > 1;
                error(['It seems that the parameter name "' name '" seems to not be unique (multiple). Please ensure that parameter names are unique.']);
            end
            if isempty(line_item);
                error(['The parameter "' name '" could not be found in "' Self.Filename '".']);
            end
            value = line_item.Value;
        end
    end
end
   