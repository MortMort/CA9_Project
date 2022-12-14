classdef LDD < handle
    properties
        filename
        sensno,sensor,description
        m
%         eq1hz,LC,no,frq,n
%         eq1hz_fam,LC_fam,no_fam,frq_fam,n_fam
        EqLoadRanges,Ncycles
        Seed
        Family
        spectrum       
    end
    
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine();  
            s = eval(mfilename('class')); 
            
            [s.filename] = Coder.getSource;
            
            fgetl(FID);fgetl(FID);
            
            [s.sensno, s.sensor, s.description]=line.decode(FID,'comment');
            
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'1Hz Equivalent Loads');
                if lineTxt==-1
                    fclose(FID);
                    return
                end
                lineTxt = fgetl(FID);
            end
                    
            a=textscan(FID, '%s',2);
            keepScanning = true;
            m = [];
            while keepScanning
                curScan = cell2mat(textscan(FID, 'm= %f',1));
                if ~isempty(curScan)
                    m(end+1) = curScan;
                else
                    keepScanning = false;
                end
            end
            
            s.m=m;
            
            fgetl(FID);fgetl(FID);
            
            formatstring=[repmat('%f',1,length(s.m)+3) '%s'];
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.Seed.eq1hz=cell2mat(InputText(4:length(s.m)+3));  
            s.Seed.LC  =InputText{end};
            s.Seed.no  =InputText{1};
            s.Seed.frq =InputText{2};
            s.Seed.n   =InputText{3};
            
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'@equ_w@');
                if lineTxt==-1
                    fclose(FID);
                    return
                end
                lineTxt = fgetl(FID);
            end
            
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.Family.eq1hz= cell2mat(InputText(4:length(s.m)+3));  
            s.Family.LC   = InputText{end};
            s.Family.no   = InputText{1};
            s.Family.frq  = InputText{2};
            s.Family.n    = InputText{3};
            
            textscan(FID,'%s',1);
            
            par=line.decode(FID);
            while ~strcmpi(par,'Level')                
                par=line.decode(FID);
            end         
            
            formatstring=repmat('%f',1,3);
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.spectrum=cell2mat(InputText);
            frewind(FID);
            
            %scan equivalent load ranges
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'Equivalent load ranges');
                if lineTxt==-1
                    fclose(FID);
                    return
                end
                lineTxt = fgetl(FID);
            end  
            lineTxt = fgetl(FID);            
            EqLoadRanges = [];
            curScan = cell2mat(textscan(FID,'%n',length(s.m)));
            EqLoadRanges = curScan;
            s.EqLoadRanges = EqLoadRanges;       
            curScan = cell2mat(textscan(FID,'%n',1));
            s.Ncycles = curScan;
            
            fclose(FID);
            
        end
        
        function encode(self, FID, s)
           
        end
    end
end
   