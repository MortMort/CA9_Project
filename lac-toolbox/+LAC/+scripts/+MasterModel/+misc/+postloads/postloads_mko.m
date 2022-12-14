classdef postloads_mko < handle
    methods
        function s = decode(self, FID)
            frewind(FID);
            line  = LAC.codec.ElementLine();    
            s = struct();
                        
            [s.FileName] = fopen(FID);
            [s.Type] = 'mko';
            
            fgetl(FID);fgetl(FID);
            
            [s.sensno s.sensor s.description]=line.decode(FID,'comment');
            fgetl(FID);fgetl(FID); fgetl(FID);fgetl(FID);                         
            formatstring=repmat('%f',1,4);
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.spectrum=cell2mat(InputText);
            
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
   