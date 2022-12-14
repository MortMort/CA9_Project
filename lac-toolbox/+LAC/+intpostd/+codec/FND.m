%FND - FND object reading intpostD mainloads file
%
% Syntax:  fndObj = LAC.intpostd.convert(postLoad_file,'FND');
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    fndObj   - Foundation loads object containing all the foundation loads
%
% Methods
%
% Example:
%    fndObj = LAC.intpostd.convert(postLoad_file,'FND');
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert

classdef FND < handle
    
    properties %(SetObservable)
        filename char
        Date
        Type
        sectionName
        decodeSections
        ExtX
        FatX
        ExtremeLoads_ExclPLF_SortedwithPLF
        ExtremeLoads_ExclPLF_SortedwithoutPLF
        ExtremeLoads_ExclPLF_DLC_PLF1_10
        ExtremeLoads_ExclPLF_DLC_PLF1_35
        EquivalentLoads
        Rainflow
    end
    
    methods (Static)
        function s = decode(Coder)
            
            s = eval(mfilename('class'));
            s.Date = datestr(now());
            s.Type = 'FNDLoad';
            s.filename = Coder.getSource;
            
            s.decodeSections = {'Extreme loads scaling factor','Fatigue loads scaling factor','Load cases sorted with PLF','Load cases sorted without PLF','Only load cases with PLF = 1.10', 'Only load cases with PLF = 1.35','Fatigue loads for N=1E7 cycles','Rainflow counting spectra'};
            s.sectionName    = {'ExtX','FatX','ExtremeLoads_ExclPLF_SortedwithPLF','ExtremeLoads_ExclPLF_SortedwithoutPLF','ExtremeLoads_ExclPLF_DLC_PLF1_10', 'ExtremeLoads_ExclPLF_DLC_PLF1_35', 'EquivalentLoads','Rainflow'};
            offset         = 3;
            
            for decodeID=1:length(s.decodeSections)
                
                sectionSize = size(Coder.search(s.decodeSections{decodeID}),1);
                linestr = Coder.get('whole');
                senData = [];
                curSenLine = 1;
                switch s.decodeSections{decodeID}
                    case 'Extreme loads scaling factor'
                        C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData = str2double(C{end});
                    case 'Fatigue loads scaling factor'
                        C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData = str2double(C{end});
                    case 'Load cases sorted with PLF'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Sensor = C{1};
                            senData(curSenLine).LC = C{2};
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Mbt1 = str2double(C{5});
                            senData(curSenLine).Mzt1 = str2double(C{6});
                            senData(curSenLine).FndFr = str2double(C{7});
                            senData(curSenLine).Fzt1 = str2double(C{8});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'Load cases sorted without PLF'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Sensor = C{1};
                            senData(curSenLine).LC = C{2};
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Mbt1 = str2double(C{5});
                            senData(curSenLine).Mzt1 = str2double(C{6});
                            senData(curSenLine).FndFr = str2double(C{7});
                            senData(curSenLine).Fzt1 = str2double(C{8});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'Only load cases with PLF = 1.10'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Sensor = C{1};
                            senData(curSenLine).LC = C{2};
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Mbt1 = str2double(C{5});
                            senData(curSenLine).Mzt1 = str2double(C{6});
                            senData(curSenLine).FndFr = str2double(C{7});
                            senData(curSenLine).Fzt1 = str2double(C{8});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'Only load cases with PLF = 1.35'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Sensor = C{1};
                            senData(curSenLine).LC = C{2};
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Mbt1 = str2double(C{5});
                            senData(curSenLine).Mzt1 = str2double(C{6});
                            senData(curSenLine).FndFr = str2double(C{7});
                            senData(curSenLine).Fzt1 = str2double(C{8});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'Fatigue loads for N=1E7 cycles'
                        
                        for off=1:(offset-1) % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(curSenLine).Sensor = C{1};
                            senData(curSenLine).Mean = str2double(C{3});
                            senData(curSenLine).Range_m4 = str2double(C{4});
                            senData(curSenLine).Range_m7 = str2double(C{5});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'Rainflow counting spectra'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData.Fy(curSenLine).Range = str2double(C{1});
                            senData.Fy(curSenLine).Frequency = str2double(C{2});
                            senData.Mx(curSenLine).Range = str2double(C{3});
                            senData.Mx(curSenLine).Frequency = str2double(C{4});
                            senData.Mz(curSenLine).Range = str2double(C{5});
                            senData.Mz(curSenLine).Frequency = str2double(C{6});
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                end
                eval(['s.' s.sectionName{decodeID} ' = senData;']);
            end
        end
        
        function encode(self, FID, s)
            
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
