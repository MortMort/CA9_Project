classdef CTRCHG  < handle
    
    properties
        parameters  = {};
        values      = {};
        scaling     = {};
    end
    
    methods (Static)
        function s = decode(Coder)
            FID    = Coder.openFile; 
            s = eval(mfilename('class'));
%             out = textscan(FID,'%s = %[^;%\n] %[^\n]','commentStyle','%'); % Old implementation
            out = textscan(FID,'%[^ =;%\n] %[^\n]','commentStyle','%');
            out{2} = strtok(strtok(strtok(out{2},'='),'%'),';');

            for i=1:length(out{2})
                SplitStr = strsplit_LMT(out{2}{i},'*');
                out{2}{i}   = strtrim(SplitStr(1));
                if length(SplitStr)>1
                    scaling(i)   = str2double(strtrim(SplitStr(2)));
                else
                    scaling(i)   = str2double('');
                end
            end
            
            % Write output
            s.parameters    = strtrim(out{1});
            s.values        = str2double([out{2}{:}]');
            s.scaling       = scaling; % Added to support complete vector of NaN
            
            fclose(FID);
        end
    end
       
    methods
        function encode(self,filename)
            fid = fopen(filename,'wt');
            for i=1:length(self.parameters)
                fprintf(fid,'%s = %12.8g \n',self.parameters{i},self.values(i));
            end           
            fclose(fid)
        end
        
        function [parameter, value] = getParameter(self, name)
            parameter = '';
            value = [];
            try
                index = not(cellfun('isempty', strfind(self.parameters, name)));
                value = self.values(index);
                parameter = self.parameters(index);
                for i=1:length(parameter)
                    fprintf('%s \t = \t %f \n',parameter{i},value(i))                    
                end
            end
        end
        
        function self = setParameter(self, name, newvalue)
            try
                index = find(strcmp(name,self.parameters));
                %index = find(not(cellfun('isempty', strfind(self.parameters, name))));
                if isempty(index)
                    disp('No parameter found..')
                    return
                end
                if length(index)>1
                    disp('More than one parameter found:')
                    for i = index
                        fprintf('%s\n',self.parameters{i})                  
                    end
                    return
                end
                    
                self.values(index)=newvalue;
            catch e
                e.getReport;
            end
        end

            
            
        function table=getTable(self) 
            table=[self.parameters num2cell(self.values)' cell(size(self.parameters))];
        end
                
        function compresult=compareTo(self,other)
            t1=self.getTable();
            t2=other.getTable();
            paramlist_left  = sortrows(t1(:,1:2));
            paramlist_right = sortrows(t2(:,1:2));
            paramnum_left  = 1;
            paramnum_right = 1;
            compresult = cell(0,3);
            while paramnum_left <= size(paramlist_left,1) || paramnum_right <= size(paramlist_right,1)
                % Special case : only left parameters remaining
                if paramnum_right > size(paramlist_right,1)
                    compresult{end+1,1} = paramlist_left{paramnum_left,1};
                    compresult{end  ,2} = paramlist_left{paramnum_left,2};
                    compresult{end  ,3} = '';
                    paramnum_left  = paramnum_left  + 1;
                    continue;
                end
                % Special case : only right parameters remaining
                if paramnum_left > size(paramlist_left,1)
                    compresult{end+1,1} = paramlist_right{paramnum_right,1};
                    compresult{end  ,2} = '';
                    compresult{end  ,3} = paramlist_right{paramnum_right,2};
                    paramnum_right = paramnum_right + 1;
                    continue;
                end
                % Normal case
                if strcmp(paramlist_left{paramnum_left,1},paramlist_right{paramnum_right,1})
                    if (paramlist_left{paramnum_left ,2} ~= paramlist_right{paramnum_right ,2})
                        compresult{end+1,1} = paramlist_left{paramnum_left,1};
                        compresult{end  ,2} = paramlist_left {paramnum_left ,2};
                        compresult{end  ,3} = paramlist_right{paramnum_right,2};
                    end
                    paramnum_left  = paramnum_left  + 1;
                    paramnum_right = paramnum_right + 1;
                else
                    [~,ix] = sort({paramlist_left{paramnum_left,1},paramlist_right{paramnum_right,1}});
                    if ix(1) == 1
                        % left side parameter to be used
                        compresult{end+1,1} = paramlist_left{paramnum_left,1};
                        compresult{end  ,2} = paramlist_left {paramnum_left ,2};
                        compresult{end  ,3} = '';
                        paramnum_left  = paramnum_left  + 1;
                    else
                        % right side parameter to be used
                        compresult{end+1,1} = paramlist_right{paramnum_right,1};
                        compresult{end  ,2} = '';
                        compresult{end  ,3} = paramlist_right{paramnum_right,2};
                        paramnum_right = paramnum_right + 1;
                    end
                end
            end

        end
    end
    
    methods (Access=private)
        
        function decodeUnitPrefix(~,postfix)
            regexp(postfix,'.*?\$(Prefix|Unit)\:([^$]+)','tokens')
        end
    end
end
   
