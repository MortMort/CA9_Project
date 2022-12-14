%classdef AuxParameterFile < handle
classdef AuxParameterFile < matlab.mixin.Copyable

    properties
        parameters={};   %c List of parameter names
        values=[];       %c The Value of parameter in SI scaling)
        units={};        %c Unit of the 'scaledvalues' 
        scaledvalues={}; %c List of values in their given scaling, e.g. '30' [deg]
        scaleexpressions={};  %c List of expressions to concatinate with the pertaining scaledvalue and though the eval([scaledvalues(i) scaleexpressions(1)] calculate the value in SI 
        scaleexpressions_inv={};  %c List of inverse expressions to concatinate with SI value and though the eval([values(i) scaleexpressions_inv(1)] calculate the scaledvalue     
        unitstring = {}; %c String which contains also unit
        historyChanges = {}; %c Stores the information about parameter changes that changed the parameter
    end
    
    methods (Static)
        function s = decode(Coder)
          FID    = Coder.openFile; 
          s = eval(mfilename('class'));
          patternNo = 0;
          lineNo = 0;
          read = true;                   

          while read == true  
            tline = fgets(FID);
            if tline == -1
                read = false;
                break;
            end
           %filter out lines that are not parameters 
           myParam =regexp(tline,'^\s*(Px_\w+).*\n*','match');
           if isempty(myParam)
               continue;
           end        
          %Possible Patterns encoded by the parameterfile writer
          %1) Value
          %2) Px = Value * SIScaling;
          %3) Px = Value + Offset
          %4) Px = Value * Prefix + Offset
          %5) Px = Value * Prefix * SIScaling;
          %6) Px = ( Value + Offset ) * SIScaling           % Not supported yet
          %7) Px = ( Value * Prefix + Offset ) * SIScaling  % Not supported yet

          while true
              myParam = {};
              %7
              myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*\((-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*[\+|\-]\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*\)\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match'); 
              if ~isempty(myParam)      
                  error('The parameter pattern: Px=(Value*Prefix+Offset)*SIScaling is not supported');   
              end
              %6
              myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*\((-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*[\+|\-]\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*\)\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match'); 
              if ~isempty(myParam)      
                  error('The parameter pattern: Px=(Value+Offset)*SIScaling - is not supported');   
              end
              %5 Px = Value * Prefix * SIScaling;
              myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*(-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match');
              if ~isempty(myParam)
                  patternNo = 5;
                  break;
              end
              %4 Px = Value * Prefix + Offset
               myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*(-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*[\+|\-]\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match');       
              if ~isempty(myParam)
                  patternNo = 4;
                  break;
              end
              %3 Px = Value + Offset
               myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*(-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*[\+|\-]\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match');
              if ~isempty(myParam)
                  patternNo = 3;
                  break;
              end
              %2 Px = Value * SIScaling;
              myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*(-{0,1}(NaN|[\d|\.]+))([Ee][\+|\-]\d+){0,1}\s*\*\s*(-{0,1}[\d|\.]+)([Ee][\+|\-]\d+){0,1}\s*.*\n*','match');
              if ~isempty(myParam)
                  patternNo = 2;
                  break;
              end
              %1    
              myParam = regexp(tline,'\s*(Px_\w+)\s*=\s*(-{0,1}(NaN|[\d|\.]+))(Ee[\+|\-]\d+){0,1}\s*.*\n*','match');
              if ~isempty(myParam)
                  patternNo = 1;
                  break;
              end

              if isempty(myParam) 
                 error('The csv file line %s does not match any supported parameter pattern', tline); 
              end
          end

          lineNo = lineNo +1;  
          [paramName, reminder]  = regexp(tline,'Px_\w+','match','split','once');
          s.parameters{lineNo} = {paramName};
          Val         = regexp(reminder{1,2},'-{0,1}(NaN|\x2A|\+|\-|(\d|\x2E|E\+|e\+|E-|e-)+)','match');
          unitString  = regexp(reminder{1,2},'\$.*\n*','match');
          if patternNo == 1
            s.values{lineNo}   = eval(char(Val{1}));
            s.scaledvalues{lineNo} = Val{1};
            s.scaleexpressions{lineNo} = {};
            s.scaleexpressions_inv{lineNo} = {};

          elseif patternNo == 2 || patternNo == 3
            s.scaledvalues{lineNo} = Val{1};          
            scaling       = [Val{2}, ' ', Val{3}];    
            s.scaleexpressions{lineNo} = scaling ;
            switch Val{2}
                case '+'
                	s.scaleexpressions_inv{lineNo} = ['- ' Val{3}]; 
                case '*'
                    s.scaleexpressions_inv{lineNo} = ['/ ' Val{3}]; 
                otherwise  
            end
            evalstring    = [Val{1}, scaling];
            s.values{lineNo} = eval(evalstring);        

          elseif patternNo == 4 || patternNo == 5
            s.scaledvalues{lineNo} = Val{1};
            scaling       = [Val{2}, ' ', Val{3}, ' ', Val{4}, ' ', Val{5}];
            s.scaleexpressions{lineNo} = scaling ;
            switch [Val{2} Val{4}]
                case '**'
                	s.scaleexpressions_inv{lineNo} = ['/ ' Val{5} ' / ' Val{3}]; 
                case '*+'
                    s.scaleexpressions_inv{lineNo} = ['- ' Val{5} ' / ' Val{3}];  
                otherwise  
            end
            evalstring    = [Val{1} scaling];
            s.values{lineNo} = eval(evalstring);
          end
          
          s.historyChanges{lineNo} = {};
          
         % find the unit string to be presented with the scaled value           
         if ~isempty(unitString)
            unit = {};
            UnitBrackets  = regexp(unitString{1},'\([\w|\/|\*|\^|\xC2|\xB0]+\)','match');    
            if length(UnitBrackets') == 2
              prefix        = regexp(UnitBrackets{1,1}, '\w+','match');
              bareunit      = regexp(UnitBrackets{1,2}, '[\w|\/|\*|\^|\xC2|\xB0]+','match'); 
              unit          = [prefix{1} bareunit{1}];
            elseif size(UnitBrackets) == 1
              unit          = regexp(UnitBrackets{1,1},'[\w|\/|\*|\^|\xC2|\xB0]+','match');  
            elseif ~isempty(regexp(unitString{1},'\$pc:','match')) || ~isempty(regexp(unitString{1},'\${UNTUNED}','match'))
                % do nothing
            else
              error('Scaled parameter %s Has no unit definition', tline);
            end
            s.unitstring{lineNo} = unitString;
            s.units{lineNo} = unit;
         else
            s.unitstring{lineNo} = {};
            s.units{lineNo}   = {};            
         end
       end
       
       s.parameters = [s.parameters{:}]';
       s.values = [s.values{:}];
       for i = 1:length(s.values)
           if iscell(s.units{i})
                s.units{i} = cell2mat(s.units{i});
           end
           if iscell(s.unitstring{i})
                s.unitstring{i} = cell2mat(s.unitstring{i});
           end
       end
       s.units = s.units';
       s.unitstring = s.unitstring';
       fclose(FID);
     end
    end
       
    methods
        function encode(self,filename,varargin)
            %write data to csv in the format as the input file
            fid = fopen(filename,'wt');
            %write header (if it is passed as an additional arg)
            if ~isempty(varargin)
                header = varargin{1};
                for i = 1:length(header)
                    fprintf(fid,'%s\n',header{i});   
                end
            end
            blank = '                      ';
            for i=1:length(self.parameters)
                sv = self.scaledvalues(i);
                se = self.scaleexpressions{i};
                if isempty(se)
                    se = '';
                end
                fprintf(fid,'%-45s = %-0.8G %s;',self.parameters{i},str2double(sv{:}),se);
                fprintf(fid,'%s %% %s',blank, self.unitstring{i});
                if isempty(self.unitstring{i}) || strcmp(self.unitstring{i},'{UNTUNED}')
                	fprintf(fid,'\n');
                end
            end           
            fclose(fid);
        end
       
       	function [value] = getParamExactValue(self, name)
        	[~, value, ~] = self.getParamExact(name);
        end
        
        function [parameter, value, index ] = getParameter(self, name)
            parameter = '';
            value = [];
            try
                index = not(cellfun('isempty', strfind(self.parameters, name)));
                value = self.values(index);
                parameter = self.parameters(index);
%                 for i=1:length(parameter)
%                     fprintf('%s \t = \t %f \n',parameter{i},value(i))                    
%                 end
            end
        end
        
        function [parameter, value, index] = getParamExact(self, name)
            parameter = '';
            value = [];
            try
                index = strcmp(name, self.parameters);
                %index = not(cellfun('isempty', strfind(self.parameters, name)));
                value = self.values(index);
                parameter = self.parameters(index);
                %for i=1:length(parameter)
                %    fprintf('%s \t = \t %f \n',parameter{i},value(i))                    
                %end
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
                
                % set new value of parameter
                self.values(index)=newvalue;
                
                % update as well corresponding scaledvalue
                se_inv = self.scaleexpressions_inv(index);
                if isempty(se_inv{:})
                    se_inv = '';
                else
                    se_inv = se_inv{:};
                end
                tol_digits = 20; % tolerance for num2str function
                self.scaledvalues(index)={num2str(eval([num2str(newvalue,tol_digits) se_inv]))};
                
            catch e
                e.getReport;
            end
        end

            
            
        function table=getTable(self)
            % show data on the table (and numerical values in engineering units)
            scaledvalues_num = {};
            for i = 1:length(self.scaledvalues)
                scaledvalues_num{i} = str2double(self.scaledvalues{i});
            end
            table=[self.parameters scaledvalues_num' self.units];
        end
        
        function compresult=compareTo(self,other)
            paramlist_left = sortrows([self.parameters num2cell(self.values')]);
            paramlist_right = sortrows([other.parameters num2cell(other.values')]);
            
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
                        if ~(isnan(paramlist_left{paramnum_left ,2}) && isnan(paramlist_right{paramnum_right ,2})) %c NaN is now accepted to facilitate a paramset with blanks
                          compresult{end+1,1} = paramlist_left{paramnum_left,1};
                          compresult{end  ,2} = paramlist_left {paramnum_left ,2};
                          compresult{end  ,3} = paramlist_right{paramnum_right,2};
                        end
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
                
        function compresult=compareTabTo(self,other)
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
                        if ~(isnan(paramlist_left{paramnum_left ,2}) && isnan(paramlist_right{paramnum_right ,2})) %c NaN is now accepted to facilitate a paramset with blanks
                          compresult{end+1,1} = paramlist_left{paramnum_left,1};
                          compresult{end  ,2} = paramlist_left {paramnum_left ,2};
                          compresult{end  ,3} = paramlist_right{paramnum_right,2};
                        end
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
    
    
    methods (Access=protected)
        
        function cp=copyElement(self)
            % Make a shallow copy of all properties
            cp = copyElement@matlab.mixin.Copyable(self);
            %deep copy parameter arrays             
%             for k=1:length(self.parameters)
%                 cp.parameters(k)=self.parameters(k);
%             end
%             
%             for k=1:length(self.values)
%                 cp.values(k)=self.values(k);
%             end
%             
%             for k=1:length(self.units)
%                 cp.units(k)=self.units(k);
%             end
        end                 
    end
    
    
    methods (Access=private)
        
        function decodeUnitPrefix(~,postfix)
            regexp(postfix,'.*?\$(Prefix|Unit)\:([^$]+)','tokens')
        end

    end
end
   