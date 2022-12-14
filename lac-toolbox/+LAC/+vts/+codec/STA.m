classdef STA
    properties
        filename
        intfile
        version
        date
        NT
        sensNo,sensor
        mean,max,min,maxmin,std,unit
        Neq,Tmin,Tmax,dT,frq,m,eq1hz
        
    end
    
    
    methods (Static)
        function s = decode(Coder)
            FID  = Coder.openFile;         
            line = LAC.codec.ElementLine();  
            s    = eval(mfilename('class')); 
            s.filename = Coder.getSource;
            
            headerLines = textscan(FID, '%s', 6, 'Delimiter', '\n');
            
            lineContent  = textscan(headerLines{1}{3}, '%s', 2, 'Delimiter', ':');
            s.intfile    = lineContent{1}{2};
            
            lineContent  = textscan(headerLines{1}{5}, '%s', 2, 'Delimiter', ':');
            s.version    = lineContent{1}{2};
            
            lineContent  = textscan(headerLines{1}{5}, '%s', 2, 'Delimiter', ':');
            s.date       = lineContent{1}{2};
            
            out=textscan(FID,'NT =%f,  Tmin = %f,  Tmax =  %f,  dT = %f%s  f = %f Hz');
            s.NT=out{1};s.Tmin=out{2};s.Tmax=out{3};s.dT=out{4};s.frq=out{6};
            fgetl(FID);
            
            formatstring = ['%f %s ' repmat('%f ',1,5) ' %s '];
            InputText    = textscan(FID,formatstring);
            s.sensNo     = InputText{1}(1:end-1);
            s.sensor     = InputText{2}(1:end-1);
            s.mean       = InputText{3};
            s.std        = InputText{4};
            s.min        = InputText{5};
            s.max        = InputText{6};
            s.maxmin     = InputText{7};
            s.unit       = InputText{8};        
            
            tline = fgetl(FID);
            out=textscan(tline,'%s');
            s.Neq = str2num(out{1}{4});
            
            tline = fgetl(FID);
            out=textscan(tline,['%*s%*s m=' repmat('%d ',1,8)]);
            s.m = cell2mat(out);
            
            out     = textscan(FID,['%*s%*s' repmat('%f ',1,8)]);
            s.eq1hz = cell2mat(out);
            fclose(FID);
%             tic;s.eq1hz=cellstr(num2str(s.eq1hz));toc
%             toc;s.eq1hz=str2num(char(s.eq1hz));tic;
            
        end
             
         
        
        function encode(self, FID, s)
           
        end
    end    

end
   
