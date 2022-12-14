classdef EXT < handle
    properties
        filename
        sensor,rank,value,plf,lc
        
    end
    
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine(); 
            s = eval(mfilename('class')); 
            
            [s.filename] = Coder.getSource;
            
            fgetl(FID);fgetl(FID);
            
            SensorLine = fgetl(FID);
            tmp = textscan(SensorLine,'%s %s','delimiter',' ');
            s.sensor = tmp{2};
            
            fgetl(FID); fgetl(FID); fgetl(FID); fgetl(FID); fgetl(FID); fgetl(FID); 

            InputText=textscan(FID,'%u %f %f %s','delimiter','\t');  
            
            s.rank      = InputText{1};
            s.value     = InputText{2};
            s.plf       = InputText{3};
            s.lc        = InputText{4};
            fclose(FID);
            
        end
        
        function encode(self, FID, s)
           
        end
    end
    
end
   