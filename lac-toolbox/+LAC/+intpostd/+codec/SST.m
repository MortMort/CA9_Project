classdef SST < handle
    properties
        filename
        
        sensno,sensor
        
        PLF_Max,PLF_Min,FamilyMethod,FamilyMean,FamilyMin,FamilyMax,FamilyStd,FamilyNames
        FamilyNo,Method,Mean,Min,Max,Std,LCNames
        
        CrossingLevels,Frq,TotalCrossings,crossings
    end
    
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine();  
            s = eval(mfilename('class')); 
            
            [s.filename] = Coder.getSource; 
            
            fgetl(FID);
            fgetl(FID);
            % find sensor no
            s.sensno = cell2mat(textscan(FID, '%f',1));
            temp = textscan(FID, '%[^:]',1);
            s.sensor = temp{1}{1};    
            
            % scanning for family wise statistics
                       
            while  ~feof(FID) 
                temp = ftell(FID);                
                lineTxt = fgetl(FID);  
                currentPos = ftell(FID);
                if(strcmpi(lineTxt,'@sta_w@'))
                    break
                end
                prevPos = temp;
                
            end
            
            % Get no. of Columns
            fseek(FID,prevPos,'bof');  
            header = fgetl(FID);
            ncol=length(strread(header,'%s','delimiter',' '))-1;
            
            % Set to original Position
            fseek(FID,currentPos,'bof');  
            
            if ncol < 9
                formatstring=[repmat('%f',1,7) '%s'];
                InputText=textscan(FID,formatstring,'delimiter',',');
                s.PLF_Min=cell2mat(InputText(2));
                s.PLF_Max=cell2mat(InputText(2));
                s.FamilyMethod=cell2mat(InputText(3));
                s.FamilyMean=cell2mat(InputText(4));
                s.FamilyMin=cell2mat(InputText(5));
                s.FamilyMax=cell2mat(InputText(6));
                s.FamilyStd=cell2mat(InputText(7));
                s.FamilyNames=InputText{8};
            else
                formatstring=[repmat('%f',1,8) '%s'];
                InputText=textscan(FID,formatstring);
                s.PLF_Min=cell2mat(InputText(2));
                s.PLF_Max=cell2mat(InputText(3));
                s.FamilyMethod=cell2mat(InputText(4));
                s.FamilyMean=cell2mat(InputText(5));
                s.FamilyMin=cell2mat(InputText(6));
                s.FamilyMax=cell2mat(InputText(7));
                s.FamilyStd=cell2mat(InputText(8));
                s.FamilyNames=InputText{9};                
            end
            
            
            % scanning for load case wise statistics
            lineTxt = fgetl(FID);
            while ~strcmpi(lineTxt,'@sta@');
                lineTxt = fgetl(FID);
            end
            InputText=textscan(FID,formatstring,'delimiter',',');
            s.FamilyNo=cell2mat(InputText(2));
            s.Method=cell2mat(InputText(3));
            s.Mean=cell2mat(InputText(4));
            s.Min=cell2mat(InputText(5));
            s.Max=cell2mat(InputText(6));
            s.Std=cell2mat(InputText(7));
            s.LCNames=InputText{8};
            
            % scannin for crossing levels/counts
            storeCrossings = false;
            lineTxt = fgetl(FID);
            while ((~strcmpi(lineTxt,'Load case wise crossing levels and countings, scaled by load case frequency:'))&&(~feof(FID)))
                lineTxt = fgetl(FID);
                if strcmpi(lineTxt,'Load case wise crossing levels and countings, scaled by load case frequency:')
                   storeCrossings = true;
                end   
            end
            if storeCrossings
                a=textscan(FID, '%s',2);
                s.CrossingLevels = cell2mat(textscan(FID, '%f'));
                l = fgetl(FID);
                formatstring=['%s' repmat('%f',1,length(s.CrossingLevels)+1)];
                InputText=textscan(FID,formatstring);
                s.Frq=cell2mat(InputText(2));
                s.TotalCrossings(1)= s.Frq(end-1,1);
                s.Frq = s.Frq(1:end-2,1);
                counter = 1;
                for i=3:length(s.CrossingLevels)+2
%                     s.crossings(counter,:)=cell2mat(InputText(i));                       
                    tmpCrossings(counter,:)=cell2mat(InputText(i));  
                    counter = counter+1;
                end
                % store total crossings
                for i=1:length(s.CrossingLevels)-1
                   s.TotalCrossings(i+1)=tmpCrossings(1,end-1);
                end                
                for i=1:length(s.CrossingLevels)
                   s.crossings(i,:)=tmpCrossings(i,1:end-2);
                end                                
                
            end
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
