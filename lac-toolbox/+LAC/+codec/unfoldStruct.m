classdef unfoldStruct < handle
    properties
        nameVector cell
    end
    
    methods
        
        function self = unfoldStruct(structure,structureName)
            %unfoldStruct Unfolds the fieldnames of a given struct, especially useful for multilayer structs.
            % Syntax:  unfoldStruct(structure,structureName)
            %
            % Required constructor inputs:
            %    structure     - The struct that should be unfolded, class type ''struct''.
            %    structureName - The output name of the struct, usually this should be the variable name of your struct.
            %
            % Properties:
            %    nameVector    - A cell array of all the fields in the struct.

            if nargin == 1
                self.unfoldInternal(structure);
            else
                self.unfoldInternal(structure,structureName);
            end
        end
        
        function unfoldInternal(self,structure,structureName)
            %unfoldInternal Unfolds a structure.
            %   unfoldInternal(structure,structureName) If structure is a struct it
            %   recursively gets the name of struct and the fieldnames of struct and saves it to the nameVector property. 
            % It uses structureName as the name of struct.
            
            
            % check input
            if nargin == 2
                    structureName = inputname(2);
            end
            
            if isstruct(structure)
                
                NS = numel(structure);
                
                %recursively saves structure including fieldnames
                for h=1:NS
                    F = fieldnames(structure(h));
                    NF = length(F);
                    for i=1:NF
                        if NS>1
                            siz = size(structure);
                            Namei = [structureName '(' self.ind2str(siz,h) ').' F{i}];
                        else
                            Namei = [structureName '.' F{i}];
                        end
                        if isstruct(structure(h).(F{i}))
                            self.unfoldInternal(structure(h).(F{i}),Namei);
                        else
                            if iscell(structure(h).(F{i}))
                                siz = size(structure(h).(F{i}));
                                NC = numel(structure(h).(F{i}));
                                jmax = NC;
                                for j=1:jmax
                                        Namej = [Namei '{' self.ind2str(siz,j) '}'];
                                end
                            else                                
                                self.nameVector{end+1} = Namei;
                            end
                        end
                    end
                end
            elseif iscell(structure)
                %recursively saves cell
                siz = size(structure);
                for i=1:numel(structure)
                    Namei = [structureName '{' self.ind2str(siz,i) '}'];
                    self.unfoldInternal(structure{i},Namei);
                end
            else
                self.nameVector{end+1} = structureName;
            end
        end
        
    end
    
    methods (Static)
        function str = ind2str(siz,ndx)
            
            n = length(siz);
            %treat vectors and scalars correctly
            if n==2
                if siz(1)==1
                    siz = siz(2);
                    n = 1;
                elseif siz(2)==1
                    siz = siz(1);
                    n = 1;
                end
            end
            k = [1 cumprod(siz(1:end-1))];
            ndx = ndx - 1;
            str = '';
            for i = n:-1:1,
                v = floor(ndx/k(i))+1;
                if i==n
                    str = num2str(v);
                else
                    str = [num2str(v) ',' str];
                end
                ndx = rem(ndx,k(i));
            end
            
        end 
    end
end

