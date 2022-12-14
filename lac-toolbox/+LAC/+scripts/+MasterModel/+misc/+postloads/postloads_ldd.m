classdef postloads_ldd < handle
    methods
        function s = decode(self, FID)
            frewind(FID);
            line  = LAC.codec.ElementLine();
            s = struct();
            
            [s.FileName] = fopen(FID);
            [s.Type] = 'ldd';
            
            fgetl(FID);fgetl(FID);
            
            [~, ~, ~, s.sensno, s.sensor, s.description]=line.decode(FID,'comment');
            
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'1Hz Equivalent Loads');
                lineTxt = fgetl(FID);
            end
                    
            a=textscan(FID, '%s',2);
            % m=textscan(FID, 'm= %f',6);
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
            s.eq1hz=cell2mat(InputText(4:length(s.m)+3));
            s.LC=InputText{end};
            s.no=InputText{1};
            s.frq=InputText{2};
            s.n=InputText{3};
            
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'@equ_w@');
                lineTxt = fgetl(FID);
            end
            
            InputText=textscan(FID,formatstring,'delimiter',',');
            s.eq1hz_fam=cell2mat(InputText(4:length(s.m)+3));
            s.LC_fam=InputText{end};
            s.no_fam=InputText{1};
            s.frq_fam=InputText{2};
            s.n_fam=InputText{3};
            
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
                lineTxt = fgetl(FID);
            end  
            lineTxt = fgetl(FID);            
            EqLoadRanges = [];
            curScan = cell2mat(textscan(FID,'%n',length(s.m)));
            EqLoadRanges = curScan;
            s.EqLoadRanges = EqLoadRanges;       
            curScan = cell2mat(textscan(FID,'%n',1));
            s.Ncycles = curScan;
            
        end
        
        function encode(self, FID, s)
            
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
