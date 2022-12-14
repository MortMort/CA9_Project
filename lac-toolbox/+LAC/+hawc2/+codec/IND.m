classdef IND
    properties
        filename
        fields
        units
        Data       
    end
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class')); 
                        
            [s.filename] = Coder.getSource;        
            s.fields = {'s' 'A' 'AP' 'PHI0' 'ALPHA0' 'U0' 'FX0' 'FY0' 'M0' 'UX0'    'UY0'    'UZ0' 'Twist' 'X_AC0' 'Y_AC0' 'Z_AC0'    'CL0'...
                'CD0' 'CM0' 'CLp0' 'CDp0' 'CMp0' 'F0' 'F' 'CL_FS0' 'CLFS' 'V_a'  'V_t' 'Tors' 'vx'   'vy'  'chord'     'CT'     'CP'};
            
            for iLines = 2:length(fileContent)
                line = textscan(fileContent{iLines},'%f');
                data(iLines-1,:) = line{1}';            
                
            end
            
            for iField = 1:length(s.fields)
                s.Data.(s.fields{iField}) = data(:,iField);
            end
            
        end
    end
    methods
        function encode(s, filename)
            FID = fopen(filename,'wt');
            s.nSetpoints = length(s.Windspeed);
            fprintf(FID,'%i\n',s.nSetpoints);
            fprintf(FID,'%6.3f\t%6.3f\t%6.3f\n',[s.Windspeed;s.Pitch;s.Rotorspeed]);
            fclose(FID);
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
