classdef SENSOR
    properties
        no,gain,offset,correction,volt,unit,name,description
        
    end
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            s = eval(mfilename('class')); 
            
            for i=1:2
                fgetl(FID);   %reading the header 
            end
            filecontent = textscan(FID,'%f %f %f %f %f %s %s %[^\n]');
            
            s.no         = filecontent{1};
            s.gain       = filecontent{2};
            s.offset     = filecontent{3};
            s.correction = filecontent{4};
            s.volt       = filecontent{5};
            s.unit       = filecontent{6};
            s.name       = filecontent{7};
            s.description= filecontent{8};          
           
            fclose(FID);
            
        end
    end
        
    methods
        function encode(self,filename)
            fid = fopen(filename,'wt');  
            fprintf(fid,'%s\n%s\n','Sensor list: Modified with LACtoolbox','No   forst  offset  korr. c  Volt    Unit   Navn    Beskrivelse---------------');
            for iLines = 1:length(self.no)
                fprintf(fid,'%3i %f %f %f %f %s %s %s\n',...
                    self.no(iLines),self.gain(iLines),self.offset(iLines),self.correction(iLines),self.volt(iLines),self.unit{iLines},self.name{iLines},self.description{iLines});
            end
            fclose(fid);
        end
        
        function [index,name,description,unit]=findSensor(self,sensor,searchtype)
            if nargin == 3 && strcmp(searchtype,'exact')
                index = find(strcmp(self.name, sensor)); 
            end
            if nargin == 3 && strcmp(searchtype,'description')
%                 index = find(strcmp(self.description, sensor)); 
                index = find(not(cellfun('isempty', strfind(self.description, sensor))));
            end
            if nargin == 2          
                index = find(not(cellfun('isempty', strfind(self.name, sensor))));   
            end
            if isempty(index)
                warning('Sensor with name ''%s'' not found!',sensor)
                name={''};
                description={''};
                unit={''};
            else
                name=self.name(index);
                description=self.description(index);
                unit=self.unit(index);
            end
            
        end
        
        function [pos, idx]=getSectionH2Flutter(self,sensorsel)     
            pos=[];
            idx=[];
            switch sensorsel
                case {'Cl'}  
                    index = self.findSensor('Cl');
                    for i=index'
                        out=textscan(self.description{i},'R=  Cl of blade  %s at radius   %f5.2');
                        if strcmp(out{1},'2')
                            pos(end+1)= out{2};
                            idx(end+1) = i;
                        end
                    end 


                case {'Cd'}  
                    index = self.findSensor('Cd');
                    for i=index'
                        out=textscan(self.description{i},'R=  Cd of blade  %s at radius   %f5.2');
                        if strcmp(out{1},'2')
                            pos(end+1)= out{2};
                            idx(end+1) = i;
                        end
                    end 

                    
                case {'AoA'}  
                    index = self.findSensor('Alfa');
                    for i=index'
                        out=textscan(self.description{i},'R Angle of attack of blade  %s at radius   %f5.2');
                        if strcmp(out{1},'2')
                            pos(end+1)= out{2};
                            idx(end+1) = i;
                        end
                    end 
      
                    
                case {'Mx'}  
                    index = self.findSensor('Mx');
                    for i=index'
                        out=textscan(self.description{i},'coo: MomentMx Mbdy:%s nodenr:  %s coo: %s  moment %s %s %f5.2m');
                        if strcmp(out{4},'b2-node')
                            pos(end+1)= out{6};
                            idx(end+1) = i;
                        end
                    end 
    
                    
                case {'My'}  
                    index = self.findSensor('My');
                    for i=index'
                        out=textscan(self.description{i},'coo: MomentMy Mbdy:%s nodenr:  %s coo: %s  moment %s %s %f5.2m');
                        if strcmp(out{4},'b2-node')
                            pos(end+1)= out{6};
                            idx(end+1) = i;
                        end
                    end 
  
                case {'Twt'}  
                    index = self.findSensor('Tors_e');
                    for i=index'
                        out=textscan(self.description{i},'Aero elastic torsion of blade %s at radius %f5.2m');
                        if strcmp(out{1},'2')
                            pos(end+1)= out{2};
                            idx(end+1) = i;
                        end
                    end      
                case {'FlapDef'}  
                    index = self.findSensor('State');
                    for i=index'
                        out=textscan(self.description{i},'p State pos y  Mbdy:%s E-nr:  %n Z-rel:%n coo: %s  defl. flap node %n');
                        if strcmp(out{4},'blade2')
                            pos(end+1)= out{5};
                            idx(end+1) = i;
                        end
                    end 
            end
            [pos, sel] = unique(pos);
            idx = idx(sel); 
            
        end
        
        function [pos, index]=getSection(self,sensorsel)           
            
            pos=[];
            switch sensorsel
                case {'Mxt','Myt','Mzt'}
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%f%s');  
                        pos(end+1)=out{3};
                    end
                case {'Mx1','Mx2','Mx3'}
                    index1 = self.findSensor(sensorsel);
                    index2 = find(not(cellfun('isempty', strfind(self.description, 'Flap moment'))));
                    index=intersect(index1,index2);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%f%s');  
                        pos(end+1)=out{4}; 
                    end
                case {'My1','My2','My3'}
                    index1 = self.findSensor(sensorsel);
                    index2 = find(not(cellfun('isempty', strfind(self.description, 'Edge moment'))));
                    index=intersect(index1,index2);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%f%s');  
                        pos(end+1)=out{4}; 
                    end
                case {'AoA1','AoA2','AoA3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%s%f%s');  
                        pos(end+1)=out{5}; 
                    end
                case {'Cl1','Cl2','Cl3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                 
                case {'Cd1','Cd2','Cd3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                    
                case {'T1','T2','T3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%s%f');  
                        pos(end+1)=out{4}; 
                    end
                case {'Tw1','Tw2','Tw3'}                                        
                    index = self.findSensor(sensorsel);
                    for i=index'
                        out=textscan(self.description{i},'%s%s%f');  
                        pos(end+1)=out{3}; 
                    end
                    
                
            end
            
        end
    end

end
   
