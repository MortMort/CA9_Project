classdef OUT
    
    properties
        blade = struct;
        tower = struct;
    end
    
    methods (Static)
        function s = decode(Coder)            
            file_data = Coder.readFile;
            cline=file_data{1};

         %*********************************************
         % Read blade and tower mode frequencies: begin
         %*********************************************
            Blade = struct;
            Tower = struct;
            

            bladeKeywordsAndFields = { 'Blade flapwise mode 1', 'flap1'; ...
                                       'Blade flapwise mode 2', 'flap2'; ...
                                       'Blade flapwise mode 3', 'flap3'; ...
                                       'Blade flapwise mode 4', 'flap4'; ...
                                       'Blade edgewise mode 1', 'edge1'; ...
                                       'Blade edgewise mode 2', 'edge2'; ...
                                       'Blade torsion', 'torsion' };                   

			%Tower keyword names. 
			%First column: The mode name in the OUT file for VTS versions before version 190
			%Second column: The mode name in the OUT file for VTS versions 190 and later
			%Third column: The mode name in the matlab toolbox (which needs to be without spaces)
            towerKeywordsAndFields = { 'Tower fore-aft 1', 'Tower fore-a 1', 'foraft1', ; ...
                                       'Tower fore-aft 2', 'Tower fore-a 2', 'foraft2', ; ...
                                       'Tower fore-aft 3', 'Tower fore-a 3', 'foraft3', ; ...
                                       'Tower fore-aft 4', 'Tower fore-a 4', 'foraft4', ; ...
                                       'Tower side-side1', 'Tower side-s 1', 'sideside1'; ...
                                       'Tower side-side2', 'Tower side-s 2', 'sideside2'; ...
                                       'Tower side-side3', 'Tower side-s 3', 'sideside3'; ...
                                       'Tower side-side4', 'Tower side-s 4', 'sideside4'; ...
                                       'Tower torsion', 'Tower+yaw torsion', 'torsion'};            

            %initialize blade structure
            [mBlade,n] = size(bladeKeywordsAndFields);
            for i = 1:mBlade
                Blade.(bladeKeywordsAndFields{i,n}).('freq') = [];
            end
            
            Blade.clearance=[];
            % Read clearance
            iline = Coder.findline(cline,'Clearance');
            if iline ~= -1
                s=sscanf(cline{iline},'Clearance : %f m');
                Blade.clearance=s;
            end
            
            
            %initialize tower structure
            [mTower,n] = size(towerKeywordsAndFields);
            for i = 1:mTower
                Tower.(towerKeywordsAndFields{i,n}).('freq') = [];
            end
            
            %read blade modes and frequencies
            iline = Coder.findline(cline,'DOFs for blade: 1:');
            if iline ~= -1
                for i=1:9

                    curLine = cline{iline + i};

                    for j = 1:mBlade
                        pos = strfind(curLine, bladeKeywordsAndFields{j,1});
                        if ~isempty(pos)
                            subString = curLine(pos + length(bladeKeywordsAndFields{j,1}) : end );
                            parString = strread(subString, '%s');
                            Blade.(bladeKeywordsAndFields{j,2}).('freq') = str2double(cell2mat(parString(2)));
                        end
                    end

                end
            end
            
            %read tower modes and frequencies
            iline = Coder.findline(cline,'Degrees of freedom for foundation, tower, shaft, generator & dampers:');
            if iline ~= -1
                for i=1:28

                    curLine = cline{iline + i};

                    for j = 1:mTower
                        keywordVersion = 1;
                        pos = strfind(curLine, towerKeywordsAndFields{j,keywordVersion});
						%If keyword is not found, it may be a more recent VTS version. So trying with new keywords.
                        if isempty(pos)
                            keywordVersion = 2;
                            pos = strfind(curLine, towerKeywordsAndFields{j,keywordVersion});
                        end
                        
                        if ~isempty(pos)
                            subString = curLine(pos + length(towerKeywordsAndFields{j,keywordVersion}) : end );
                            parString = strread(subString, '%s');
                            Tower.(towerKeywordsAndFields{j,3}).('freq') = str2double(cell2mat(parString(2)));
                        end
                    end

                end
            end
            
            s = eval(mfilename('class'));            
            s.blade = Blade;
            s.tower  = Tower;

         %*********************************************
         % Read blade and tower mode frequencies: end
         %*********************************************

        end
      
        
        function encode(self, FID, s)

        end
        
    end
    
end
