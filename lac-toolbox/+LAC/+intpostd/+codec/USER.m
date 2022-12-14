%USER - USER object reading intpostD USERload.txt file
%
% Syntax:  userObj = LAC.intpostd.convert(USERload_path,'USER');
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    userObj   - USERload loads object containing all the loads
%
% Methods
%
% Example:
%    userObj = LAC.intpostd.convert(USERload_path,'USER');
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert

classdef USER < handle
    
    properties %(SetObservable)
        filename char
        Date
        Type
        sectionName
        decodeSections
        references
        combinedSensors
        extreme
        fatigue
        ldd
        
    end
    
    methods (Static)
        function s = decode(Coder)
            
            s = eval(mfilename('class'));
            s.Date = datestr(now());
            s.Type = 'USERload';
            s.filename = Coder.getSource;
            
            s.decodeSections = {'REFERENCES' , 'LIST OF COMBINED SENSORS','EXTREME RESULTS' ,'FATIGUE RESULTS', 'LDD RESULTS'};
            s.sectionName    = {'references','combinedSensors','extreme','fatigue','ldd'};
            offset         = 3;
            
            for decodeID=1:length(s.decodeSections)
                
                sectionSize = size(Coder.search(s.decodeSections{decodeID}),1);
                linestr = Coder.get('whole');
                senData = [];
                curSenLine = 1;
                switch s.decodeSections{decodeID}
                    case 'REFERENCES'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData.calculationPath = C{end};
                        linestr = Coder.get('whole');
                        C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData.intPath = C{end};
                        linestr = Coder.get('whole');C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData.frqPath = C{end};
                        linestr = Coder.get('whole');C = textscan(linestr,'%s');
                        C = vertcat(C{:});
                        senData.masPath = C{end};
                    case 'LIST OF COMBINED SENSORS'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        while ~isempty(linestr)
                            combinedCell = strtrim(strsplit(linestr,'='));
                            senData(curSenLine).Sensor = combinedCell{1};
                            senData(curSenLine).Combination = combinedCell{2};
                            curSenLine = curSenLine + 1;
                            linestr = Coder.get('whole');
                        end
                    case 'EXTREME RESULTS'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        currentLine = Coder.current;
                        [~,sectionEnd] = Coder.search(s.decodeSections{decodeID+1});
                        Coder.jump(currentLine);
                        while Coder.current < sectionEnd
                            [~,tableEndAbs] = Coder.search('Comment');
                            tableEndRel = tableEndAbs-currentLine;
                            [~,idEnd]=min(tableEndRel(tableEndRel>0));
                            tableEndAbs = tableEndAbs(tableEndRel>0);
                            tableEndLineNo = tableEndAbs(idEnd);
                            if isempty(tableEndLineNo)
                                break
                            end
                            Coder.jump(currentLine);
                            
                            senData(curSenLine).leadSensor = cell2mat(strtrim(regexp(linestr,'(?<=Lead sensor:).*','match')));
                            linestr = Coder.get('whole');
                            senData(curSenLine).loadSensors = strsplit(cell2mat(strtrim(regexp(linestr,'(?<=Type).*','match'))));
                            linestr = Coder.get('whole');
                            table=Coder.readTableData(tableEndLineNo- (Coder.current), length(senData(curSenLine).loadSensors)+4);
                            
                            senData(curSenLine).Rank = str2double(table.data(:,1));
                            senData(curSenLine).LoadCase = table.data(:,2);
                            senData(curSenLine).PLF = str2double(table.data(:,3));
                            senData(curSenLine).Type = table.data(:,4);
                            senData(curSenLine).Loads = str2double(table.data(:,5:end));
                            linestr = Coder.get('whole');
                            commentNo = 1;
                            while ~isempty(linestr)
                                senData(curSenLine).Comments{commentNo} = linestr;
                                linestr = Coder.get('whole');
                                commentNo = commentNo +1 ;
                            end
                            Coder.skip(1);
                            linestr = Coder.get('whole');
                            currentLine = Coder.current;
                            curSenLine = curSenLine + 1;
                        end
                    case 'FATIGUE RESULTS'
                        for off=1:offset % Reads the offset lines
                            linestr = Coder.get('whole');
                        end
                        linestr = Coder.get('whole');
                        linestr = Coder.get('whole');
                        curSenLine = 1;
                        continueSection = true;
                        if regexp(strtrim(linestr),'^\-+$'); continueSection = false; end
                        while continueSection
                            if isempty(linestr)
                                break
                            else
                                while ~isempty(linestr)
                                    data = strsplit(strtrim(linestr));
                                    if length(senData) < curSenLine
                                        senData(curSenLine).Sensor = data{1};
                                        senData(curSenLine).Woehler = str2double(data{2});
                                        senData(curSenLine).EqLoad_1E7 = str2double(data{3});
                                        senData(curSenLine).Eqload_1Hz = str2double(data{4});
                                        senData(curSenLine).Time_s = str2double(data{5});
                                        senData(curSenLine).Time_y = str2double(data{6});
                                    else
                                        senData(curSenLine).Woehler = [senData(curSenLine).Woehler str2double(data{2})];
                                        senData(curSenLine).EqLoad_1E7 = [senData(curSenLine).EqLoad_1E7 str2double(data{3})];
                                        senData(curSenLine).Eqload_1Hz = [senData(curSenLine).Eqload_1Hz str2double(data{4})];
                                        senData(curSenLine).Time_s = [senData(curSenLine).Time_s str2double(data{5})];
                                        senData(curSenLine).Time_y = [senData(curSenLine).Time_y str2double(data{6})];
                                    end
                                    linestr = Coder.get('whole');
                                end
                                curSenLine = curSenLine + 1;
                                linestr = Coder.get('whole');
                            end
                        end
                    case 'LDD RESULTS'
                        if length(strsplit(Coder.getRemaininglines,'\n')) > offset
                            for off=1:offset % Reads the offset lines
                                linestr = Coder.get('whole');
                            end
                        end
                        if length(strsplit(Coder.getRemaininglines,'\n')) > 2
                            linestr = Coder.get('whole');
                            linestr = Coder.get('whole');
                        else
                            linestr = [];
                        end
                        curSenLine = 1;
                        while 1
                            if isempty(linestr)
                                break
                            else
                                while ~isempty(linestr)
                                    data = strsplit(strtrim(linestr));
                                    if length(senData) < curSenLine
                                        senData(curSenLine).Sensor = data{1};
                                        senData(curSenLine).Woehler = str2double(data{2});
                                        senData(curSenLine).EqLoad_1E7 = str2double(data{3});
                                        senData(curSenLine).Eqload_1Hz = str2double(data{4});
                                        senData(curSenLine).Time_s = str2double(data{5});
                                        senData(curSenLine).Time_y = str2double(data{6});
                                    else
                                        senData(curSenLine).Woehler = [senData(curSenLine).Woehler str2double(data{2})];
                                        senData(curSenLine).EqLoad_1E7 = [senData(curSenLine).EqLoad_1E7 str2double(data{3})];
                                        senData(curSenLine).Eqload_1Hz = [senData(curSenLine).Eqload_1Hz str2double(data{4})];
                                        senData(curSenLine).Time_s = [senData(curSenLine).Time_s str2double(data{5})];
                                        senData(curSenLine).Time_y = [senData(curSenLine).Time_y str2double(data{6})];
                                    end
                                    if isempty(Coder.getRemaininglines)
                                        break
                                    end
                                    linestr = Coder.get('whole');
                                end
                                curSenLine = curSenLine + 1;
                                if isempty(Coder.getRemaininglines)
                                        break
                                end
                                linestr = Coder.get('whole');
                            end
                        end
                        
                end
                eval(['s.' s.sectionName{decodeID} ' = senData;']);
            end
        end
        
        function encode(self, FID, s)
            warning('encode function not available')
        end
    end
    
end
