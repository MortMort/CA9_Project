classdef BLD_PROPS
    properties
        filename char
        Type
        Mass
        Struct
        
        
    end
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class'));
            
            [s.filename] = Coder.getSource;
            [s.Type]     = 'BLD_PROPS';
            
            indexLine = 25;
            data = textscan(fileContent{indexLine},'%s',16,'delimiter',',');
            data{1} = strrep(data{1},'''','');
            s.Struct.parameters = strtrim(data{1});
            indexLine = indexLine +1; i=1;
            while ~isempty(fileContent{indexLine})
                lineData = textscan(fileContent{indexLine},'%f',16,'delimiter',',');
                dataStruct(i,:) = lineData{1}';
                indexLine = indexLine+1; i = i+1;
            end
            for iParameter = 1:size(dataStruct,2)
               s.Struct.(s.Struct.parameters{iParameter}) = dataStruct(:,iParameter);
            end
            
            indexLine = indexLine + 11;
            data = textscan(fileContent{indexLine},'%s',16,'delimiter',',');
            data{1} = strrep(data{1},'''','');
            s.Mass.parameters = strtrim(data{1});
            indexLine = indexLine +1; i=1;
            while ~isempty(fileContent{indexLine})
                lineData = textscan(fileContent{indexLine},'%f',7,'delimiter',',');
                dataMass(i,:) = lineData{1}';
                indexLine = indexLine+1; i = i+1;
            end
            for iParameter = 1:size(dataMass,2)
               s.Mass.(s.Mass.parameters{iParameter}) = dataStruct(:,iParameter);
            end
        end
    end
    methods
        function encode(self, filename)
        end
    end
    
    methods (Access=private)
        
        function output = getIncludedFile(~, files, name)
            for i = 1: length(files)
                if strcmpi(files{i}.Type, name)
                    output = files{i};
                    break
                end
            end
        end
    end
end
