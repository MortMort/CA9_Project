classdef CMB
    properties
        filename
        nSetpoints
        nModes
        windspeed
        frequency
        damping   
    end
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class')); 
                        
            [s.filename] = Coder.getSource;            
            temp         = textscan(fileContent{1},'%s');
            headerline       = temp{1};
            s.nModes     = (length(headerline)-3)/2;      
            s.nSetpoints = length(fileContent)-1;
                      
            for iSetpoint = 1:s.nSetpoints
                data = textscan(fileContent{iSetpoint+1},'%f');
                s.windspeed(iSetpoint)  = data{1}(1);
                s.frequency(iSetpoint,:)= data{1}(2:s.nModes+1);
                s.damping(iSetpoint,:)  = data{1}(s.nModes+2:s.nModes*2+1);    
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
