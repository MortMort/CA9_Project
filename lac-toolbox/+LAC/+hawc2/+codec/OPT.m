classdef OPT
    properties
        filename
        nSetpoints
        Windspeed
        Rotorspeed
        Pitch
       
    end
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class')); 
                        
            [s.filename] = Coder.getSource;            
           
            s.nSetpoints = str2num(fileContent{1});                 
                      
            for iSetpoint = 1:s.nSetpoints
                data = textscan(fileContent{iSetpoint+1},'%f');
                s.Windspeed(iSetpoint)  = data{1}(1);
                s.Pitch(iSetpoint)      = data{1}(2);
                s.Rotorspeed(iSetpoint) = data{1}(3);    
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
