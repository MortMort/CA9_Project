classdef SET
    properties
        filename
        
        PrepVersion,SimTitle,Type
        
        LC,rpm,Vhub,Gen,Wdir,Vexp,Turb,rho,Wind,Turbfile,Comment,option

        
    end
    
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine();  
            s = eval(mfilename('class')); 
            
            [s.filename] = Coder.getSource; 
            
            [s.PrepVersion,~] = line.decode(FID, true);
            [s.SimTitle,~] = line.decode(FID, true);
            [s.Type] = line.decode(FID, true);
            
            [~] = line.decode(FID);
            [~] = line.decode(FID);
                        
            
            filecontent = textscan(FID, '%s', 'delimiter','\n'); 
            stop = length(filecontent{1,1})+1;
            line=1;
            i=1;
            while line < stop

                %Extract primary .set data
                data(i,1:11) = textscan(filecontent{1,1}{line,1}, '%s %f %f %f %f %f %f %f %s %s %[^\n]');
                %Check for second Title lines
                ischevron = strfind(char(data{i,11}), '>>');

                if ischevron

                    line=line + 1; 
                    option = textscan(filecontent{1,1}{line,1}, '%[^\n]');
                    data(i,12) = option;

                    %Older versions of Prep create third Title lines
                    checknum = line + 1;
                    if checknum < stop   
                        linecheck = length(filecontent{1,1}{line+1,1});
                        if linecheck < 50 
                            line = line + 1;
                            option2 = textscan(filecontent{1,1}{line,1}, '%[^\n]');
                            data(i,13) = option2;
                        end
                    end

                end

                line = line + 1;
                i = i + 1;

            end
            s.LC      = [data{:,1}];
            s.rpm     = [data{:,2}];
            s.Vhub    = [data{:,3}];
            s.Gen     = [data{:,4}];
            s.Wdir    = [data{:,5}];
            s.Turb    = [data{:,6}];
            s.Vexp    = [data{:,7}];
            s.rho     = [data{:,8}];
            s.Wind    = [data{:,9}];
            s.Turbfile= [data{:,10}];            
            s.Comment = data(:,11);
            if size(data,2) >= 12
                s.option  = data(:,12);   
            else
                s.option = cell(size(data,1),1); %Create empty options fields if no options are found
            end
            fclose(FID);
            
        end
    end
    methods
        function encode(self,filename)
            fid = fopen(filename,'wt');
            
            %Write header
            fprintf(fid,'%s\n',self.PrepVersion);
            fprintf(fid,'%s\n',self.SimTitle);
            fprintf(fid,'%s\n\n',self.Type);
            fprintf(fid,'%s\n','LC file      n_rot    Vhub Gen Wdir   Turb   Vexp    rho   Wind  Turbfil Title');
            fprintf(fid,'%s\n','             [rpm]   [m/s]    [deg]');
            

            nrows = length(self.LC);
            formatSpec  = '%s\t %2.2f\t %2.2f\t %2.0f\t %2.0f\t %2.3f\t %2.3f\t %2.3f\t %s\t %s\t';
            formatSpecOption = '%s\n\t\t\t\t\t\t\t\t\t\t\t\t %s\n';
            
            %Write each load case definition
            for row = 1:nrows
                fprintf(fid,formatSpec,self.LC{row},self.rpm(row),self.Vhub(row),self.Gen(row),self.Wdir(row),self.Turb(row),self.Vexp(row),self.rho(row),self.Wind{row},self.Turbfile{row});
                
                %Writing options if they exist
                comment = self.Comment{row};
                opt = self.option{row};
                if(~isempty(opt))
                    fprintf(fid, formatSpecOption, comment{1},opt{1});
                else
                    if(~isempty(comment)) %Comment line may be completely empty, if so, just write a newline
                        fprintf(fid,'%s\n',self.Comment{row}{1});
                    else
                        fprintf(fid,'\n');
                    end
                end
            end
            fclose(fid);
        end

    end
end
   
