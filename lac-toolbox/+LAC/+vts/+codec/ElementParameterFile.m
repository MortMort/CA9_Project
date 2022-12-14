classdef ElementParameterFile < handle
    methods
        function self = ElementParameterFile( filename )
            self.readCSV(filename);
        end
        
        function output = getParameter(self, name)
            output = '';
            try
                output = self.values{strcmpi(self.parameters, name)};
            end
        end
        
        function output = getParameterNames(self)
            output =  self.parameters;
        end
        
        function output = getData(self)
            output =  self.values;
        end
    end
    
    methods (Access=private)
        function readCSV(self, filename)
            if exist(filename ,'file')
                [FileID, message] = fopen(filename, 'r','l');
                tmp = textscan(FileID, '%s = %s%*[^\n]');
                fclose(FileID);
                
                self.parameters = tmp{1};
                self.values = tmp{2};
            end
        end
    end
    
    properties (Access=private)
        parameters = {};
        values= {};
    end
end

   
