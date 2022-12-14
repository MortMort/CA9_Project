classdef BLD_FLXEXP
    properties
        filename char
        SectionTable
        Type char
        
        
    end
    methods (Static)
        function s = decode(Coder)
            FID  = Coder.openFile;
            s = eval(mfilename('class'));
            
            [s.filename] = Coder.getSource;
            [s.Type]     = 'BLD_FLXEXP';           

            %Find beginning of parameter listing
            head_line = fgetl(FID);
            first_propertyline = 'R = ';
            while(isempty(strfind(head_line,first_propertyline)))
                head_line = fgetl(FID);
                if(head_line == -1)
                %Reached the end of the file without finding first property
                %line
                error(['Reached the end of the file without finding first property line: ' first_propertyline s.filename]);
                end
            end
            
            %Extract headers
            headers = cell(0);
            while(~isempty(strfind(head_line,' = ')))
                head_line = strsplit_LMT(head_line);
                headers(end+1) = head_line(1);
                head_line = fgetl(FID);
            end
            
            %Some check of the correct header lines should be implemented,
            %but for now we just hard code it. Since header names may
            %differ in different .csv files they are hardcoded below in the
            %case of 16 and 26 sectional properties.
            if(length(headers) == 16 )
                headers      = {'R',  'EI_Flap'  'EI_Edge'  'GIp'  'm'  'J' 'Xcog'  'Xshc'  'UF0'  'UE0'  'C'  't_C'  'beta'  'Yac_C'  'PhiOut'  'Out'};
                rawData_str = '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %*[^\n]';
            elseif (length(headers) == 26 )
                headers      = {'R',  'C'   't_C'   'beta' 'dum'  'dum'  'Yac_C' 'UF0' 'UE0' 'EI_Flap' 'EI_Edge'  'GIp'  'm'  'J'  'dum'  'dum'  'Xcog'  'dum'  'Xshc'  'dum'  'p_ang'  'EI_1'  'EI_2'  'EA'  'PhiOut'  'Out'};
                rawData_str = '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %*[^\n]';
            else
                error(['The number of properties is not equal to either 16 or 26, which indicates something is wrong in:' s.filename]);
            end
            
            s.SectionTable.parameters = headers;

            % Retrieving sectional properties. 

            % Since .csv files may come with empty lines it tries to until success. 
            % first: try from current line
            rawData      = textscan(FID,rawData_str,'Delimiter',',','HeaderLines',0);
            % try 10 more times
            maxTries = 10;
            tryNumber = 1;
            while isempty(rawData{1}) && tryNumber<=maxTries
                rawData      = textscan(FID,rawData_str,'Delimiter',',','HeaderLines',1);
                tryNumber = tryNumber+1;
            end
            if isempty(rawData{1})
               error('could not read .csv file')
            end
            
            % storing sectional properties in struct.
            for iParameter = 1:size(rawData,2)
               s.SectionTable.(headers{iParameter}) = rawData{iParameter};
               if iParameter == 1
                   % find empty lines in .csv and make sure they are not
                   % stored in the struct.
                   idx = isnan(s.SectionTable.(headers{iParameter}));
               end
               s.SectionTable.(headers{iParameter})(idx) = [];
            end
            fclose(FID);
        end
    end
    
    methods
        function status = encode(self, filename)
        end
    end    

end
