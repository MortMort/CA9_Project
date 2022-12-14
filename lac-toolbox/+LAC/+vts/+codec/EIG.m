classdef EIG
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine();  
            s = eval(mfilename('class'));  
            
            s.filename = fopen(FID);
            
            [~,~,s.version]=line.decode(FID);
            [~,~,s.lc]=line.decode(FID);
            out=line.decode(FID);
            while ~strcmpi(out,'EIGENVALUES')
                out=line.decode(FID);
            end
            out=line.decode(FID)    ;     
            [~, frq{1:8}] = line.decode(FID);
            [~,~, damp{1:8}] = line.decode(FID);
            
            while ~strcmpi(out,'EIGENVALUES')
                out=line.decode(FID);
            end
            out=line.decode(FID);        
            [~, frq{9:16}] = line.decode(FID);
            [~,~, damp{9:16}] = line.decode(FID);
            
%             while ~strcmpi(out,'EIGENVALUES')
%                 out=line.decode(FID);
%             end
%             out=line.decode(FID); 
%             [~, frq{17:24}] = line.decode(FID);
%             [~,~, damp{17:24}] = line.decode(FID); 
%             
%             while ~strcmpi(out,'EIGENVALUES')
%                 out=line.decode(FID);
%             end
%             out=line.decode(FID); 
%             [~, frq{25}] = line.decode(FID);
%             [~,~, damp{25}] = line.decode(FID);    
            
            frq=cellfun(@str2num,frq);
            damp=damp(frq>0);
            
            s.frq=frq(frq>0);
            s.damp=cellfun(@str2num,damp);
            
            fclose(FID);
        end
        function encode(self, FID, s)
           
        end
    end
    
    properties
       frq  = struct;
       damp = struct;
       filename
       version
       lc
       
        
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
   
