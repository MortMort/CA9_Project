classdef postloads_rfo < handle
    methods
        function s = decode(self, FID)
            frewind(FID);
            line  = LAC.codec.ElementLine();    
            s = struct();
                        
            [s.FileName] = fopen(FID);
            [s.Type] = 'rfo';
            
            fgetl(FID);fgetl(FID);
            
            [s.sensno s.sensor s.description]=line.decode(FID,'comment');
            fgetl(FID);fgetl(FID);            

            m=textscan(FID, '%f');            
            s.m=cell2mat(m);
            textscan(FID,'%s',1);
            eq=textscan(FID,'%s',length(s.m));
            s.sum=cellfun(@str2num,eq{1});
            
            fgetl(FID);fgetl(FID); fgetl(FID);fgetl(FID); fgetl(FID);
            
            formatstring=repmat('%f',1,3);
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.spectrum=cell2mat(InputText);
            
            fgetl(FID);fgetl(FID);
            
            formatstring=[repmat('%f',1,length(s.m)+1) '%s'];
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.relative=cell2mat(InputText(2:length(s.m)+1));  
            s.LC=InputText{end};
            s.no=InputText{1}(1:end-1);
            
            fgetl(FID);fgetl(FID);
            
            formatstring=['%*f' repmat('%f',1,length(s.m)+2) '%*s'];
            InputText=textscan(FID,formatstring,'delimiter',';');
            s.eq1hz=cell2mat(InputText(3:length(s.m)+2));
            s.frq=InputText{1};
            s.n=InputText{2};
            
            fgetl(FID);
            
            [~,mean]=line.decode(FID);
            s.mean=str2num(mean);
            frewind(FID);
            
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
   