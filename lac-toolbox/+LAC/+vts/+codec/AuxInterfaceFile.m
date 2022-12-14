classdef AuxInterfaceFile < handle
% Handles the ifdef.txt, which exist with interfaceversion 7

    properties
%         parameters = {};
%         values=[];
%         units={};
    end
    
    methods (Static)
        function s = decode(Coder)                                            
            %create empty CTRv7 instance
            s = eval('LAC.vts.codec.CTRv7');                        
            s = s.decodeInterfaceFile(Coder);
        end                
    end
       
%    methods
%         function encode(self,filename)
%             fid = fopen(filename,'wt');
%             for i=1:length(self.parameters)
%                 fprintf(fid,'%s = %12.8g \n',self.parameters{i},self.values(i));
%             end           
%             fclose(fid)
%         end
       
%          function [value] = getParamExactValue(self, name)
%              [~, value, ~] = self.getParamExact(name);
%          end
        
%         function [parameter, value, index] = getParameter(self, name)
%             parameter = '';
%             value = [];
%             try
%                 index = not(cellfun('isempty', strfind(self.parameters, name)));
%                 value = self.values(index);
%                 parameter = self.parameters(index);
%                 for i=1:length(parameter)
%                     fprintf('%s \t = \t %f \n',parameter{i},value(i))                    
%                 end
%             end
%         end
        
%         function [parameter, value, index] = getParamExact(self, name)
%             parameter = '';
%             value = [];
%             try
%                 index = strcmp(name, self.parameters);
%                 %index = not(cellfun('isempty', strfind(self.parameters, name)));
%                 value = self.values(index);
%                 parameter = self.parameters(index);
%                 %for i=1:length(parameter)
%                 %    fprintf('%s \t = \t %f \n',parameter{i},value(i))                    
%                 %end
%             end
%         end
        
        
        
%         function self = setParameter(self, name, newvalue)
%             try
%                 index = find(strcmp(name,self.parameters));
%                 %index = find(not(cellfun('isempty', strfind(self.parameters, name))));
%                 if isempty(index)
%                     disp('No parameter found..')
%                     return
%                 end
%                 if length(index)>1
%                     disp('More than one parameter found:')
%                     for i = index
%                         fprintf('%s\n',self.parameters{i})                  
%                     end
%                     return
%                 end
%                     
%                 self.values(index)=newvalue;
%             catch e
%                 e.getReport;
%             end
%         end

            
            
%         function table=getTable(self) 
%             table=[self.parameters num2cell(self.values)' cell(size(self.parameters))];
%         end
                
%         function compresult=compareTo(self,other)
%             t1=self.getTable();
%             t2=other.getTable();
%             paramlist_left  = sortrows(t1(:,1:2));
%             paramlist_right = sortrows(t2(:,1:2));
%             paramnum_left  = 1;
%             paramnum_right = 1;
%             compresult = cell(0,3);
%             while paramnum_left <= size(paramlist_left,1) || paramnum_right <= size(paramlist_right,1)
%                 % Special case : only left parameters remaining
%                 if paramnum_right > size(paramlist_right,1)
%                     compresult{end+1,1} = paramlist_left{paramnum_left,1};
%                     compresult{end  ,2} = paramlist_left{paramnum_left,2};
%                     compresult{end  ,3} = '';
%                     paramnum_left  = paramnum_left  + 1;
%                     continue;
%                 end
%                 % Special case : only right parameters remaining
%                 if paramnum_left > size(paramlist_left,1)
%                     compresult{end+1,1} = paramlist_right{paramnum_right,1};
%                     compresult{end  ,2} = '';
%                     compresult{end  ,3} = paramlist_right{paramnum_right,2};
%                     paramnum_right = paramnum_right + 1;
%                     continue;
%                 end
%                 % Normal case
%                 if strcmp(paramlist_left{paramnum_left,1},paramlist_right{paramnum_right,1})
%                     if (paramlist_left{paramnum_left ,2} ~= paramlist_right{paramnum_right ,2})
%                         compresult{end+1,1} = paramlist_left{paramnum_left,1};
%                         compresult{end  ,2} = paramlist_left {paramnum_left ,2};
%                         compresult{end  ,3} = paramlist_right{paramnum_right,2};
%                     end
%                     paramnum_left  = paramnum_left  + 1;
%                     paramnum_right = paramnum_right + 1;
%                 else
%                     [~,ix] = sort({paramlist_left{paramnum_left,1},paramlist_right{paramnum_right,1}});
%                     if ix(1) == 1
%                         % left side parameter to be used
%                         compresult{end+1,1} = paramlist_left{paramnum_left,1};
%                         compresult{end  ,2} = paramlist_left {paramnum_left ,2};
%                         compresult{end  ,3} = '';
%                         paramnum_left  = paramnum_left  + 1;
%                     else
%                         % right side parameter to be used
%                         compresult{end+1,1} = paramlist_right{paramnum_right,1};
%                         compresult{end  ,2} = '';
%                         compresult{end  ,3} = paramlist_right{paramnum_right,2};
%                         paramnum_right = paramnum_right + 1;
%                     end
%                 end
%             end
% 
%         end
%    end
    
    
%    methods (Access=protected)
%         function cp=copyElement(self)
%             % Make a shallow copy of all properties
%             cp = copyElement@matlab.mixin.Copyable(self);
%             %deep copy parameter arrays             
% %             for k=1:length(self.parameters)
% %                 cp.parameters(k)=self.parameters(k);
% %             end
% %             
% %             for k=1:length(self.values)
% %                 cp.values(k)=self.values(k);
% %             end
% %             
% %             for k=1:length(self.units)
% %                 cp.units(k)=self.units(k);
% %             end
%         end
        
%    end
    
    
%    methods (Access=private)
        
%         function decodeUnitPrefix(~,postfix)
%             regexp(postfix,'.*?\$(Prefix|Unit)\:([^$]+)','tokens')
%         end
%     end
%    end
end
   
