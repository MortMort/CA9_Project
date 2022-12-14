classdef PRO
    properties
        filename
        Header
        HeaderPro cell
        nProfiles,Thickness,nAlpha,nKohanaPos
        KohanaPos
        alpha,cL,cD,cM,dL,dD,dM
        Type
    end
    
    
    methods (Static)
        function s = decode(Coder)
            s = eval(mfilename('class'));
            
            file_data = Coder.readFile;
            cline=file_data{1};
            
            [s.filename] = Coder.getSource;
            
            try testStr = strread(cline{7},'%f');
                s.Type = 'PRO';
                lineOffset = 0;
            catch
                s.Type = 'PRO_KOHANA';
                lineOffset = 2;

            end
            s.Header        = cline{1};
            s.nProfiles      = strread(cline{2},'%f');
            s.Thickness     = strread(cline{3},'%f');
            
            if strcmp(s.Type,'PRO_KOHANA')
                s.nKohanaPos    = strread(cline{4},'%f');
                s.KohanaPos     = strread(cline{5},'%f');
                s.nAlpha        = strread(cline{6},'%f');
                
                
                s.alpha       = zeros(s.nAlpha,1);
                s.cL          = zeros(s.nAlpha,s.nProfiles);
                s.cD          = zeros(s.nAlpha,s.nProfiles);
                s.cM          = zeros(s.nAlpha,s.nProfiles);
                
                s.dL          = zeros(s.nAlpha,s.nProfiles,s.nKohanaPos);
                s.dD          = zeros(s.nAlpha,s.nProfiles,s.nKohanaPos);
                s.dM          = zeros(s.nAlpha,s.nProfiles,s.nKohanaPos);
                
                for iProfile = 1:s.nProfiles
                    istart = 8 + (s.nAlpha+1)*(iProfile-1);
                    s.HeaderPro{iProfile} = cline{istart-1};
                    for iAlpha = 1:s.nAlpha
                        curline = strread(cline{istart+iAlpha-1},'%f');
                        s.alpha(iAlpha) = curline(1);
                        s.cL(iAlpha,iProfile) = curline(2);
                        s.cD(iAlpha,iProfile) = curline(3);
                        s.cM(iAlpha,iProfile) = curline(4);
                        
                        s.dL(iAlpha,iProfile,:) = curline(5:5+s.nKohanaPos-1);
                        s.dD(iAlpha,iProfile,:) = curline(5+s.nKohanaPos:5+s.nKohanaPos*2-1);
                        s.dM(iAlpha,iProfile,:) = curline(5+s.nKohanaPos*2:5+s.nKohanaPos*3-1);
                    end
                end
                
                
            else
                s.nAlpha        = strread(cline{4},'%f');
                
                s.alpha       = zeros(s.nAlpha,1);
                s.cL          = zeros(s.nAlpha,s.nProfiles);
                s.cD          = zeros(s.nAlpha,s.nProfiles);
                s.cM          = zeros(s.nAlpha,s.nProfiles);
                for iProfile = 1:s.nProfiles
                    istart = 6 + (s.nAlpha+1)*(iProfile-1);
                    s.HeaderPro{iProfile} = cline{istart-1};
                    for iAlpha = 1:s.nAlpha
                        curline = strread(cline{istart+iAlpha-1},'%f');
                        s.alpha(iAlpha) = curline(1);
                        s.cL(iAlpha,iProfile) = curline(2);
                        s.cD(iAlpha,iProfile) = curline(3);
                        s.cM(iAlpha,iProfile) = curline(4);
                    end
                end
            end
            
            
        end
    end
    methods
        function encode(s,filename)
            fid = fopen(filename,'wt');
            fprintf(fid,'%s\n',s.Header);
            fprintf(fid,'%i\n',s.nProfiles);
            fprintf(fid,'%3.2f\t',s.Thickness);
            fprintf(fid,'\n');
            
            
            
            if strcmp(s.Type,'PRO_KOHANA')
                fprintf(fid,'%i\n',s.nKohanaPos);
                fprintf(fid,'%i\t',s.KohanaPos);
                fprintf(fid,'\n');
                nFormat = 3+3*s.nKohanaPos;
            else
                nFormat = 3;
            end
            fprintf(fid,'%i\n',s.nAlpha);
            
            formatStr = sprintf('%s','%2.3f\t');
            
            for iFormat = 1:nFormat;
                formatStr = sprintf('%s%s',formatStr,'%3.8f\t');
            end
            formatStr = sprintf('%s%s',formatStr,'\n');
            
            for iProfile = 1:s.nProfiles
                fprintf(fid,'%s\n',s.HeaderPro{iProfile});
                if strcmp(s.Type,'PRO_KOHANA')
                    dL(:,:)= s.dL(:,iProfile,:);
                    dD(:,:)= s.dD(:,iProfile,:);
                    dM(:,:)= s.dM(:,iProfile,:);                

                    fprintf(fid,formatStr,[s.alpha,s.cL(:,iProfile),s.cD(:,iProfile),s.cM(:,iProfile),dL,dD,dM]');
                else
                    fprintf(fid,formatStr,[s.alpha,s.cL(:,iProfile),s.cD(:,iProfile),s.cM(:,iProfile)]');
                    
                end
            end
            
            fclose(fid)
        end
        function compareProfiles(s,pro,xlimit)
            for iProfiles = 1:s.nProfiles
                f{iProfiles} = figure;
                set(f{iProfiles},'color','white'); set(f{iProfiles}, 'Position', [120 75 900 500]);
                
                subplot(131)
                plot(s.alpha,[s.cL(:,iProfiles) pro.cL(:,iProfiles)]); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cl [-]')
                subplot(132)
                plot(s.alpha,[s.cD(:,iProfiles) pro.cD(:,iProfiles)]); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cd [-]')
                subplot(133)
                plot(s.alpha,[s.cM(:,iProfiles) pro.cM(:,iProfiles)]); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cm [-]')
                suptitle(strrep(s.HeaderPro{iProfiles},'_',''))
                legend('Reference','Compare')
            end
        end
        
        function plotProfiles(s,xlimit)  % old plotting function
            if nargin <2
               error('Not enough input arguments. Please specify limits on x-axis!')
            end
            for iProfiles = 1:s.nProfiles
                figH{iProfiles} = figure;
                set(figH{iProfiles},'color','white'); set(figH{iProfiles}, 'Position', [120 75 1100 800]);
                
                subplot(131)
                plot(s.alpha,s.cL(:,iProfiles)); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cl [-]')
                subplot(132)
                plot(s.alpha,s.cD(:,iProfiles)); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cd [-]')
                subplot(133)
                plot(s.alpha,s.cM(:,iProfiles)); grid on
                xlim(xlimit); xlabel('AoA [deg]'); ylabel('Cm [-]')
                title(strrep(s.HeaderPro{iProfiles},'_',''))
            end
        end
        
        
        function print(s)  % PESEG 200303 prints an overview of the airfoils, t/c and comments
            fprintf('Idx  T/C    Comment\n')
            for i = 1:length(s.Thickness)
                fprintf('%3d %6.2f  %s\n', i, s.Thickness(i), s.HeaderPro{i})
            end                
        end
        
        
        function plotRelativeThickness(s,varargin) % PESEG 200303 plot polars for predefined t/c vector
            % specify LineSpec and relative thicknesses, e.g.
            % plotRelativeThickness('b-', [18 21 24])
            % default values for LineSpec is 'b-'
            % default values for relative thickness:
            DefaultRelt = [18 21 24 28 30 32 35 40 50 100];
            
            if nargin < 2
                % default settings - blue color and all elements in
                % Thickness vector
                Colour = 'b-';
                RelativeThickness = DefaultRelt;
            elseif nargin < 3
                Colour = varargin{1};  
                RelativeThickness = DefaultRelt;
            else
                Colour = varargin{1}; 
                RelativeThickness = varargin{2};
            end
            
            % for every entry in the vector, pick or interpolate the polar
            % and plot:
            for i = 1:length(RelativeThickness)
                figH{i} = figure(i);
                set(figH{i},'color','white'); set(figH{i}, 'Position', [120 75 1100 800]);
                Title = sprintf('%6.2f%%', RelativeThickness(i));
                
                % if the exact value of desired relative Thickness is found
                % in the file take the first matching element
                ix = find(s.Thickness == RelativeThickness(i),1,'first');
                
                if ~isempty(ix) 
                    s.plotPolar(ix, 'LineSpec', Colour, 'LegendString', strrep(s.HeaderPro{ix},'_',''), 'TitleString', Title)
                 
                else
                    if RelativeThickness(i) < s.Thickness(1)
                        % if the value of desired Thickness lies on the
                        % left of Thickness vector then take first element
                        % of Thickness vector
                        s.plotPolar(1, 'LineSpec', Colour, 'LegendString', strrep(s.HeaderPro{1},'_',''), 'TitleString', Title)
                        
                    elseif RelativeThickness(i) >  s.Thickness(end)
                        % if the value of desired Thickness lies on the
                        % right of Thickness vector then take last element
                        % of Thickness vector
                        s.plotPolar(length(s.Thickness), 'LineSpec', Colour, 'LegendString', strrep(s.HeaderPro{end},'_',''), 'TitleString', Title)
                        
                    else
                        % if the value of desired Thickness lies inside
                        % Thickness vector, then find two closest elements
                        % to that element in Thickness vector 
                        % and interpolate/weight values in-between accordingly
                        [data,weights,sections] = getInterpolatedData(s,RelativeThickness(i));
                        
                        Legend = sprintf('interp(%3.0f%%) %4.2f * %s + %4.2f * %s', RelativeThickness(i), weights(1), strrep(s.HeaderPro{sections(1)},'_',''), weights(2), strrep(s.HeaderPro{sections(2)},'_',''));
                        
                        s.plotPolar(0, 'Data', data, 'LineSpec', Colour, 'LegendString', Legend, 'TitleString', Title)
                    end
                    
                end
                
            end
        end
        
        function [data,weights,sections] = getInterpolatedData(s,relativeThickness)
            % GETINTERPOLATEDDATA interpolates aerodynamic data
            % finds two closest relative thickness sections and 
            % interpolate/weight aerodynamic data between them
            % output is a matrix with [AoA cL cD cM]
            if relativeThickness < s.Thickness(end)
                sections(1) = find(s.Thickness > relativeThickness, 1);  % find the first entry that is bigger than the t/c sought
            else
                sections(1) = length(s.Thickness);
            end
            sections(2) = sections(1) - 1;
            
            % weights
            weights(1) = 1-abs(s.Thickness(sections(1))-relativeThickness)/(abs(s.Thickness(sections(1))-s.Thickness(sections(2))));
            weights(2) = 1-weights(1);
            
            % final values
            AoA = s.alpha;
            cL = weights(1)*s.cL(:,sections(1)) + weights(2)*s.cL(:,sections(2));
            cD = weights(1)*s.cD(:,sections(1)) + weights(2)*s.cD(:,sections(2));
            cM = weights(1)*s.cM(:,sections(1)) + weights(2)*s.cM(:,sections(2));
            data = [AoA cL cD cM];
        end
        
        
        function plotPolar(s, ipol, varargin)
            % please give at least 1 argument ipol = index number of the
            % polar to be plotted, e.g. plotPolar(2)
            
            if nargin < 2
                error('Not enough input arguments. Please specify the index of the polar to plot, e.g. plotPolar(2)')
            end
            
            % Use input parser object to allow for optional parameters with default
            % values. The purpose is to be able to specify programatically what options
            % to choose instead of being prompted with interactive questions.
            Parser = inputParser;
            Parser.addOptional('AoA_range', [-20 20]); % None = use the interactive dialog.
            Parser.addOptional('CL_range', [-1.5 2.3]);
            Parser.addOptional('CD_range', [0 0.04]);
            Parser.addOptional('CM_range', [-0.5 0.5]);
            Parser.addOptional('LoD_range', [0 180]);
            Parser.addOptional('LineSpec','b-');
            Parser.addOptional('Data', []);
            Parser.addOptional('LegendString', 'Data');
            Parser.addOptional('TitleString', 'Polar');
            Parser.addOptional('Legend', true);
            Parser.addOptional('Title', true);

            % Parse.
            Parser.parse(varargin{:});

            % Set variables.
            AoA_range = Parser.Results.('AoA_range');
            CL_range = Parser.Results.('CL_range');
            CD_range = Parser.Results.('CD_range');
            CM_range = Parser.Results.('CM_range');
            LoD_range = Parser.Results.('LoD_range');
            LineSpec = Parser.Results.('LineSpec');
            Data = Parser.Results.('Data');    
            Legend = Parser.Results.('Legend'); 
            Title = Parser.Results.('Title');
            LegendString = Parser.Results.('LegendString'); 
            TitleString = Parser.Results.('TitleString');
  
            % find the correct polar data. 
            if ipol < 1  
                if ~isempty(Data)   % if ipol is zero, and Data not empty, get it from Data argument
                    AoA = Data(:,1);
                    cL = Data(:,2);
                    cD = Data(:,3);
                    cM = Data(:,4);
                else
                    error(['Please specify a polar index between 1 and ' int2str(length(s.Thickness)) 'or a valid 4 column Data object as varargin'])
                end
                
            elseif ipol <= length(s.Thickness)  % if ipol is valid, load the correct polar from the object
                if ~isempty(Data)
                    disp(['WARNING: found a valid polar index ' num2str(ipol) ' and Data as argument - Data will be discarded'])
                end
                AoA = s.alpha;
                cL = s.cL(:,ipol);
                cD = s.cD(:,ipol);
                cM = s.cM(:,ipol);
            else
                error(['Please specify a polar index between 1 and ' int2str(length(s.Thickness)) 'or a valid 4 column Data object as varargin'])
            end
                   
            % no figure number is set 
                subplot(231); hold on;
                plot(AoA, cL, LineSpec); grid on
                xlim(AoA_range); xlabel('AoA [deg]'); ylim(CL_range); ylabel('Cl [-]')
                subplot(232); hold on;
                plot(cD, cL, LineSpec); grid on
                xlim(CD_range); xlabel('Cd [-]'); ylim(CL_range); ylabel('Cl [-]')
                if Title
                    title(TitleString) 
                end
                
                subplot(233); hold on;                
                plot(cL./cD, cL, LineSpec); grid on
                xlim(LoD_range); xlabel('L/D [-]'); ylim(CL_range); ylabel('Cl [-]')
                subplot(234); hold on;
                plot(AoA, cD, LineSpec); grid on
                xlim(AoA_range); xlabel('AoA [deg]'); ylim(CD_range); ylabel('Cd [-]')
                subplot(235); hold on;
                plot(AoA, cL./cD, LineSpec); grid on
                xlim(AoA_range); xlabel('AoA [deg]'); ylim(LoD_range); ylabel('L/D [-]')
                subplot(236); hold on;
                plot(AoA, cM, LineSpec); grid on
                xlim(AoA_range); xlabel('AoA [deg]'); ylim(CM_range); ylabel('Cm [-]')

                %title('Polar')
                if Legend
                    legobj = legend(LegendString);
                    legobj.Position = [0.5 0.5 0 0];
                end
                hold on;
        end
        
    end
    
    
end
