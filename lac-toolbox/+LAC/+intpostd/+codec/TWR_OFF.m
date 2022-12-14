classdef TWR_OFF < handle
    methods
        function s = decode(self, FID)
            frewind(FID);
            
            s = struct();
            
            s.FileName = fopen(FID);
            s.Date = datestr(now());
            s.Type = 'TwrOffLoad';
            
            decodeSections = {'3.1 Equivalent fatigue load ranges'};
            sectionName = {'EquivalentTowerMoment'};
            offset = [3];
            
            obj=LAC.txtFile(s.FileName);
            
            for decodeID=1:length(decodeSections)
                obj.findline(decodeSections{decodeID},offset(decodeID));
                senData = [];
                curSenLine = 1;
                
                switch decodeID
                    case 1
                        % first decodes which tower direction we have
                        C = strsplit_LMT(obj.current);
                        TwrLoadDirections = str2double(cellstr(C));
                        % Any empty element will map into a NaN, thereby
                        % will be removed
                        TwrLoadDirections = TwrLoadDirections(~isnan(TwrLoadDirections));
                        senData(curSenLine).TwrLoadDirections = TwrLoadDirections;
                        obj.offsetline(1);

                        while ~isempty(obj.current)
                            C = strsplit_LMT(obj.current);
                            senData(curSenLine).TwrLoadDirections = TwrLoadDirections;
                            senData(curSenLine).Height = str2double(C{1});
                            senData(curSenLine).Value = str2double(cellstr(C(2:end)));
                            senData(curSenLine).Unit   = 'kNm';
                            senData(curSenLine).Method = 'RFC, m=4';
                            curSenLine = curSenLine + 1;
                            obj.offsetline(1);
                        end
                    case 2
                        while ~isempty(obj.current)
                            C = strsplit_LMT(obj.current);
                            senData(curSenLine).Height = str2double(C{1});
                            senData(curSenLine).Value = str2double(C{2});
                            senData(curSenLine).PLF = str2double(C{3});
                            senData(curSenLine).Sensor = C{8};
                            senData(curSenLine).Note = C{9};
                            senData(curSenLine).Unit   = 'kNm';
                            senData(curSenLine).Method = 'Abs';
                            curSenLine = curSenLine + 1;
                            obj.offsetline(1);
                        end
                end
                eval(['s.' sectionName{decodeID} ' = senData;']);
            end
            
            frewind(FID);
            
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
