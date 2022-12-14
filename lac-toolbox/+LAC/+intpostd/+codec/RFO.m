classdef RFO < handle
    properties
        filename
        sensno,sensor,description
        m
        %relative,LC,no,eq1hz,frq,n
        mean,sum
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
            fgetl(FID);fgetl(FID);            

            m=textscan(FID, '%f');            
            s.m=cell2mat(m);
            textscan(FID,'%s',1);
            eq=textscan(FID,'%s',length(s.m));
            s.sum=cellfun(@str2num,eq{1});
            
            fgetl(FID);fgetl(FID); fgetl(FID);fgetl(FID); fgetl(FID);
            
            % Spectrum
            formatstring=repmat('%f',1,3);
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.spectrum=cell2mat(InputText);
            
            fgetl(FID);fgetl(FID);
            
            %damage
            formatstring=[repmat('%f',1,length(s.m)+1) '%s'];
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.Seed.relative=cell2mat(InputText(2:length(s.m)+1));  
            s.Seed.LC=InputText{end};
            s.Seed.no=InputText{1}(1:end-1);
            
            fgetl(FID);fgetl(FID);
            
            %1Hz
            formatstring=['%*f' repmat('%f',1,length(s.m)+2) '%*s'];
            InputText=textscan(FID,formatstring,'delimiter',',');
            s.Seed.eq1hz =cell2mat(InputText(3:length(s.m)+2));
            s.Seed.frq   =InputText{1};
            s.Seed.n     =InputText{2};
            
            fgetl(FID);fgetl(FID);fgetl(FID);%fgetl(FID);
            
            %family damage
            formatstring=[repmat('%f',1,length(s.m)+1) '%s'];
            InputText=textscan(FID,formatstring,'delimiter',',');            
            s.Family.relative=cell2mat(InputText(2:length(s.m)+1));  
            s.Family.LC=InputText{end};
            s.Family.no=InputText{1}(1:end-1);
            
            fgetl(FID);fgetl(FID);
            
            %family 1Hz
            formatstring   =['%*f' repmat('%f',1,length(s.m)+2) '%*s'];
            InputText      =textscan(FID,formatstring,'delimiter',';');
            s.Family.eq1hz =cell2mat(InputText(3:length(s.m)+2));
            s.Family.frq   =InputText{1};
            s.Family.n     =InputText{2};
            
            fgetl(FID);
            
            [~,mean]=line.decode(FID);
            s.mean=str2num(mean);
            fclose(FID);
            
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
   