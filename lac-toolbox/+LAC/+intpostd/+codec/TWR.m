%TWR - TWR object reading intpostD mainloads file
%
% Syntax:  twrObj = LAC.intpostd.convert(postLoad_file,'TWR');
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    twrObj   - Towerloads object containing all the loads of the tower
%
% Methods
%
% Example: 
%    twrObj = LAC.intpostd.convert(postLoad_file,'TWR');
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert   

classdef TWR < handle
    
    properties %(SetObservable)
        filename char
        Date
        Type
        sectionName
        decodeSections
        EquivalentTowerMoment
        ExtremeTowerMomentInclPLF
        ExtremeTowerMomentExclPLF
        MomentDueToTowerOutOfVerticalExclPlf
        SLSLoads
        LateralForeAftFatigueLoadsAndRatio
    end
    
    methods (Static)
        function s = decode(Coder)
            
            s = eval(mfilename('class'));
            s.Date = datestr(now());
            s.Type = 'TWRLoad';
            s.filename = Coder.getSource;                      
            s.decodeSections = {'3.1 Equivalent', '4.1 EXTREME LOADS','Tower out of vertical moment excl. PLF','#5.1 SLS Loads','6  Lateral fatigue loads' };
            s.sectionName    = {'EquivalentTowerMoment', {'ExtremeTowerMomentInclPLF','ExtremeTowerMomentExclPLF'},'MomentDueToTowerOutOfVerticalExclPlf', 'SLSLoads','LateralForeAftFatigueLoadsAndRatio'};
            offset         = 4;
            
            for decodeID=1:length(s.decodeSections) 

                sectionSize = size(Coder.search(s.decodeSections{decodeID}),1);
                linestr = Coder.get('whole');
                %s.sectionName{decodeID} = linestr
                senData = [];
                curSenLine = 1;
                
                if strcmp(s.decodeSections{decodeID},'3.1 Equivalent')
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Height = str2double(C{1});
                            senData(curSenLine).Value = str2double(C{2});
                            senData(curSenLine).PLF = str2double(C{3}); 
                            senData(curSenLine).Sensor = C{4};
                            senData(curSenLine).Unit   = 'kNm';
                            senData(curSenLine).Method = 'Rfc';
                            senData(curSenLine).Note   = '4';
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                            %obj.offsetline(1);
                        end
                elseif regexp(linestr,'^4\.[1-4] EXTREME LOADS')
                        index = 1;
                        % Loop through all EXTREME LOADS INCL tables 
                        while 1
                            header = linestr;
                            for off=1:offset
                                linestr = Coder.get('whole');
                            end
                            
                            senData = [];
                            curSenLine = 1;
                            while ~isempty(linestr)
                                C = textscan(linestr,'%s');
                                senData(curSenLine).Height = str2double(C{1}{1});
                                senData(curSenLine).Value = str2double(C{1}{2});
                                senData(curSenLine).PLF = str2double(C{1}{3});
                                senData(curSenLine).Mz = str2double(C{1}{4});
                                senData(curSenLine).Fp = str2double(C{1}{5});
                                senData(curSenLine).FzTT = str2double(C{1}{6});
                                senData(curSenLine).Vhub = str2double(C{1}{7});
                                senData(curSenLine).Sensor = C{1}{8};
                                senData(curSenLine).Note = C{1}{9};
                                senData(curSenLine).Unit   = 'kNm';
                                senData(curSenLine).Method = 'Abs';
                                curSenLine = curSenLine + 1;
                                linestr = Coder.get('whole');
                            end
                            for off=1:2
                                linestr = Coder.get('whole');
                            end
                            
                            index = index + 1;
                            %Store the table data to class variable
                            if any(strfind(header,'EXCL'))
                                s.ExtremeTowerMomentExclPLF{end + 1} = senData;
                            elseif any(strfind(header,'INCL'))
                                s.ExtremeTowerMomentInclPLF{end + 1} = senData;
                            end
                            if contains(linestr, 'MOMENT DUE TO TOWER OUT OF VERTICAL')
                                break
                            end
                        end                     
                elseif strcmp(s.decodeSections{decodeID},'6  Lateral fatigue loads')
                        % -------------------------------------------------------------------------
                        % #6  Lateral fatigue loads
                        % -------------------------------------------------------------------------
                        % Height        m          Myt         Mxt       Ratio
                        %    [m]       [-]       [kNm]       [kNm]         [-]
                        %   90.3      4.00      667.05     3066.71        0.22
                        %   87.2      4.00      726.93     3077.96        0.24
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr) % read the data matrix
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            linestr = Coder.get('whole');
                            %obj.offsetline(1);
                            senData(curSenLine).Height = str2double(C{1});
                            senData(curSenLine).Whoeler = str2double(C{2});
                            senData(curSenLine).MxtSensor = 'Mxt';
                            senData(curSenLine).MytSensor = 'Myt';
                            senData(curSenLine).RatioSensor = 'Myt/MxtRatio';
                            senData(curSenLine).MytValue = str2double(C{3});
                            senData(curSenLine).MxtValue = str2double(C{4});
                            senData(curSenLine).Value = str2double(C{5});
                            senData(curSenLine).Unit   = {'kNm' 'kNm' '-'};
                            senData(curSenLine).Sensor = ['Myt/Mxt' (C{1})];
                            senData(curSenLine).Method = 'Rfc';
                            senData(curSenLine).Note   = '4';
                            curSenLine = curSenLine + 1;
                        end
                        %assign the sensors 
                           
                elseif strcmp(s.decodeSections{decodeID},'Tower out of vertical moment excl. PLF')
                        Coder.search('Tower out of vertical 1:');
                        if (Coder.current > 0)
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            tow1 = str2double(C{end-1});
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            Mtov1Plf = str2double(C{end});

                            Coder.search('Tower out of vertical 2:');
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            tow2 = str2double(C{end-1});
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            Mtov2Plf = str2double(C{end});


                            Coder.search(s.decodeSections{decodeID});
                            Coder.skip(3);
                            linestr = strtrim(Coder.readTableHeader{1});
                            while length(linestr) > 2
                                C = strsplit_LMT(linestr);
                                senData(curSenLine).Height = str2double(C{1});
                                senData(curSenLine).Mtov1 = str2double(C{2});
                                senData(curSenLine).Mtov1Plf = Mtov1Plf;
                                senData(curSenLine).Mtov2 = str2double(C{3});
                                senData(curSenLine).Mtov2Plf = Mtov2Plf;
                                linestr = strtrim(Coder.readTableHeader{1});
                                curSenLine = curSenLine + 1;
                            end
                        else
                            Coder.search('Tower out of vertical:');
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            tow1 = str2double(C{end-1});
                            linestr = strtrim(Coder.readTableHeader{1});
                            linestr = strtrim(Coder.readTableHeader{1});
                            linestr = strtrim(Coder.readTableHeader{1});
                            C = strsplit_LMT(linestr);
                            Mtov1Plf = str2double(C{end});
                            
                            tow2 = 0;
                            Mtov2Plf = 0;
                            
                            Coder.search('Height        Mtow');
                            Coder.skip(2);
                            linestr = strtrim(Coder.readTableHeader{1});
                            while length(linestr) > 2
                                C = strsplit_LMT(linestr);
                                senData(curSenLine).Height = str2double(C{1});
                                senData(curSenLine).Mtov1 = str2double(C{2});
                                senData(curSenLine).Mtov1Plf = Mtov1Plf;
                                senData(curSenLine).Mtov2 = 0;
                                senData(curSenLine).Mtov2Plf = Mtov2Plf;
                                [output] = Coder.getData();
                                if (Coder.current > length(output))
                                    linestr = '';
                                else
                                    linestr = strtrim(Coder.readTableHeader{1});
                                    curSenLine = curSenLine + 1;
                                end
                            end
                        end
                elseif strcmp(s.decodeSections{decodeID},'#5.1 SLS Loads')
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Height = str2double(C{1});
                            senData(curSenLine).Value = str2double(C{2});
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Mz = str2double(C{4});
                            senData(curSenLine).Fp = str2double(C{5});
                            senData(curSenLine).FzTT = str2double(C{6});
                            senData(curSenLine).Vhub = str2double(C{7});                            
                            senData(curSenLine).Sensor = C{8};
                            senData(curSenLine).Note = C{9};
                            senData(curSenLine).Unit   = 'kNm';
                            senData(curSenLine).Method = 'Abs';
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                end
                
                % for 'EXTREME LOADS INCL' tables, Data is being taken in
                % Switch case itself
                % For other tables, the below code should get processed 
                if ~any(string(s.decodeSections{decodeID}) == {'4.1 EXTREME LOADS'})
                    eval(['s.' s.sectionName{decodeID} ' = senData;']);
                end
            end
            
        end
        
        function encode(self, output)
            % read file content
            fid=fopen(self.filename);
            tline = fgetl(fid);
            tlines = cell(0,1);
            while ischar(tline)
                tlines{end+1,1} = tline;
                tline = fgetl(fid);
            end
            fclose(fid);
            
            % Magic
            offset = 4;
            
            % Main encode loop
            for k = 1:length(tlines) 
                
                if startsWith(tlines{k},'3.1 Equivalent')
                    k = k + offset;
                    for j = 1:length([self.EquivalentTowerMoment.Value])
                        % write
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %s',self.EquivalentTowerMoment(j).Height, self.EquivalentTowerMoment(j).Value, self.EquivalentTowerMoment(j).PLF, self.EquivalentTowerMoment(j).Sensor);
                        % update k
                        k = k + 1;
                    end
                end
                
                if strcmp(tlines{k},'4.1 EXTREME LOADS EXCL PLF SORTED INCL PLF')
                    k = k + offset;
                    for j = 1:length([self.ExtremeTowerMomentExclPLF{1}.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %s \t %s \t ',...
                                    self.ExtremeTowerMomentExclPLF{1}(j).Height, self.ExtremeTowerMomentExclPLF{1}(j).Value,...
                                    self.ExtremeTowerMomentExclPLF{1}(j).PLF, self.ExtremeTowerMomentExclPLF{1}(j).Mz,...
                                    self.ExtremeTowerMomentExclPLF{1}(j).Fp, self.ExtremeTowerMomentExclPLF{1}(j).FzTT,...
                                    self.ExtremeTowerMomentExclPLF{1}(j).Vhub, self.ExtremeTowerMomentExclPLF{1}(j).Sensor,...
                                    self.ExtremeTowerMomentExclPLF{1}(j).Note);
                        
                        % update k
                        k = k +1;
                    end
                end
                
                if strcmp(tlines{k},'4.2 EXTREME LOADS INCL PLF SORTED INCL PLF')
                    k = k + offset;
                    for j = 1:length([self.ExtremeTowerMomentInclPLF{1}.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %s \t %s \t ',...
                                    self.ExtremeTowerMomentInclPLF{1}(j).Height, self.ExtremeTowerMomentInclPLF{1}(j).Value,...
                                    self.ExtremeTowerMomentInclPLF{1}(j).PLF, self.ExtremeTowerMomentInclPLF{1}(j).Mz,...
                                    self.ExtremeTowerMomentInclPLF{1}(j).Fp, self.ExtremeTowerMomentInclPLF{1}(j).FzTT,...
                                    self.ExtremeTowerMomentInclPLF{1}(j).Vhub, self.ExtremeTowerMomentInclPLF{1}(j).Sensor,...
                                    self.ExtremeTowerMomentInclPLF{1}(j).Note);
                        
                        % update k
                        k = k +1;
                    end
                end
                
                if strcmp(tlines{k},'4.3 EXTREME LOADS EXCL PLF SORTED INCL PLF Max Mz load set')
                    k = k + offset;
                    for j = 1:length([self.ExtremeTowerMomentExclPLF{2}.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %s \t %s \t ',...
                                    self.ExtremeTowerMomentExclPLF{2}(j).Height, self.ExtremeTowerMomentExclPLF{2}(j).Value,...
                                    self.ExtremeTowerMomentExclPLF{2}(j).PLF, self.ExtremeTowerMomentExclPLF{2}(j).Mz,...
                                    self.ExtremeTowerMomentExclPLF{2}(j).Fp, self.ExtremeTowerMomentExclPLF{1}(j).FzTT,...
                                    self.ExtremeTowerMomentExclPLF{2}(j).Vhub, self.ExtremeTowerMomentExclPLF{1}(j).Sensor,...
                                    self.ExtremeTowerMomentExclPLF{2}(j).Note);
                        
                        % update k
                        k = k +1;
                    end
                end
                
                if strcmp(tlines{k},'4.4 EXTREME LOADS INCL PLF SORTED INCL PLF Max Mz load set')
                    k = k + offset;
                    for j = 1:length([self.ExtremeTowerMomentInclPLF{2}.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %s \t %s \t ',...
                                    self.ExtremeTowerMomentInclPLF{2}(j).Height, self.ExtremeTowerMomentInclPLF{2}(j).Value,...
                                    self.ExtremeTowerMomentInclPLF{2}(j).PLF, self.ExtremeTowerMomentInclPLF{2}(j).Mz,...
                                    self.ExtremeTowerMomentInclPLF{2}(j).Fp, self.ExtremeTowerMomentInclPLF{2}(j).FzTT,...
                                    self.ExtremeTowerMomentInclPLF{2}(j).Vhub, self.ExtremeTowerMomentInclPLF{2}(j).Sensor,...
                                    self.ExtremeTowerMomentInclPLF{2}(j).Note);
                        
                        % update k
                        k = k +1;
                    end
                end
                
                if strcmp(tlines{k},'4.5 MOMENT DUE TO TOWER OUT OF VERTICAL')
                    k = k + offset * offset; % more magic
                    for j = 1:length([self.MomentDueToTowerOutOfVerticalExclPlf.Mtov1])
                        tlines{k} = sprintf('%.2f \t %.2f \t 0.00 ',self.MomentDueToTowerOutOfVerticalExclPlf(j).Height,...
                                                                self.MomentDueToTowerOutOfVerticalExclPlf(j).Mtov1 );
                        
                        k = k + 1;
                    end
                end
                
                if startsWith(tlines{k},'#5.1 SLS Loads')
                    k = k + offset;
                    for j = 1:length([self.SLSLoads.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %.2f \t %s \t %s \t ',...
                                    self.SLSLoads(j).Height, self.SLSLoads(j).Value,...
                                    self.SLSLoads(j).PLF, self.SLSLoads(j).Mz,...
                                    self.SLSLoads(j).Fp, self.SLSLoads(j).FzTT,...
                                    self.SLSLoads(j).Vhub, self.SLSLoads(j).Sensor,...
                                    self.SLSLoads(j).Note);
                        k = k + 1;
                    end
                end
                
                if strcmp(tlines{k},'#6  Lateral fatigue loads ')
                    k = k + offset;
                    for j = 1:length([self.LateralForeAftFatigueLoadsAndRatio.Value])
                        tlines{k} = sprintf('%.2f \t %.2f \t %.2f \t %.2f \t %.2f \t ',...
                            self.LateralForeAftFatigueLoadsAndRatio(j).Height,...
                            self.LateralForeAftFatigueLoadsAndRatio(j).Whoeler,...
                            self.LateralForeAftFatigueLoadsAndRatio(j).MytValue,...
                            self.LateralForeAftFatigueLoadsAndRatio(j).MxtValue,...
                            self.LateralForeAftFatigueLoadsAndRatio(j).Value);
                        k = k + 1;
                    end
                end
            end
            
            % Write tlines to output
            fid = fopen(output,'w');
            fprintf(fid,'%s\n', tlines{:});
            fclose(fid);

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
   