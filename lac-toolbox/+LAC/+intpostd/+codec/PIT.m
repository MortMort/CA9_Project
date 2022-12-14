%PIT - PIT object reading intpostD mainloads file
%
% Syntax:  pitObj = LAC.intpostd.convert(postLoad_file,'PIT');
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    pitObj   - Pitch load object containing all the pitch loads
%
% Methods
%    pitObj.computePTD()
%
% Example:
%    pitObj = LAC.intpostd.convert(postLoad_file,'PIT');
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert


classdef PIT < handle
    properties %(SetObservable)
        filename char
        Date
        Type
        CumAbsPitPistMov
        Blade1PitchSpdvsPitchMomDuration
        Blade2PitchSpdvsPitchMomDuration
        Blade3PitchSpdvsPitchMomDuration
    end
    
    methods (Static)
        function s = decode(Coder)
            
            s = eval(mfilename('class'));
            s.Date = datestr(now());
            s.Type = 'PITLoad';
            s.filename = Coder.getSource;
            
            decodeSections = {'#8.5','#9.1','#9.2','#9.3'};
            sectionName = {'CumAbsPitPistMov', 'Blade1PitchSpdvsPitchMomDuration', 'Blade2PitchSpdvsPitchMomDuration', 'Blade3PitchSpdvsPitchMomDuration'};
            
            for decodeID=1:length(decodeSections)
                
                Coder.search(decodeSections{decodeID});
                linestr = Coder.get('whole');
                senData = [];
                curSenLine = 1;
                switch decodeSections{decodeID}
                    
                    case '#8.5'
                        Coder.search(decodeSections{decodeID});
                        Coder.get; linestr = Coder.get('whole');
                        
                        for bl=1:3
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            senData(bl).Sensor=['Blade' num2str(bl)];
                            senData(bl).Unit='m';
                            senData(bl).Method='CumSum';
                            senData(bl).Value=str2double(C{3});
                            senData(bl).Note='';
                            linestr = Coder.get('whole');
                        end
                        eval(['s.' sectionName{decodeID} ' = senData;']);
                        
                    case {'#9.1','#9.2','#9.3'}
                        %
                        % #9.1 Blade 1, Pitch speed vs. Pitch moment duration
                        %        dPidt1        Mpi11         Time          Sum
                        %        [dg/s]        [kNm]          [s]          [s]
                        %    1.3730E+01  -5.7819E+01   8.7548E-03   8.7548E-03
                        %    1.2813E+01  -4.4782E+01   8.7548E-03   1.7510E-02
                        %    1.2813E+01  -5.1301E+01   8.7548E-03   2.6264E-02
                        %    .............%
                        
                        BladeNum = decodeSections{decodeID}(end); % Blade number as string
                        headers = 3;
                        
                        for off=1:headers; linestr = Coder.get('whole'); end % Reads the header lines
                        
                        % Setup fixed data
                        SensNum = 1; % dPidtX
                        senData(SensNum).Sensor     = ['dPidt' BladeNum];
                        senData(SensNum).Unit       = 'dg/s';
                        senData(SensNum).Method     = '';
                        senData(SensNum).Value      = []; % Init Value
                        senData(SensNum).Note       = '';
                        senData(SensNum).Chapter    = decodeSections{decodeID};
                        SensNum = 2; % MpiX1
                        senData(SensNum).Sensor     = ['Mpi' BladeNum '1'];
                        senData(SensNum).Unit       = 'kNm';
                        senData(SensNum).Method     = '';
                        senData(SensNum).Value      = []; % Init Value
                        senData(SensNum).Note       = '';
                        senData(SensNum).Chapter    = decodeSections{decodeID};
                        SensNum = 3; % Time
                        senData(SensNum).Sensor     = 'Time';
                        senData(SensNum).Unit       = 's';
                        senData(SensNum).Method     = '';
                        senData(SensNum).Value      = []; % Init Value
                        senData(SensNum).Note       = '';
                        senData(SensNum).Chapter    = decodeSections{decodeID};
                        SensNum = 4; % Sum
                        senData(SensNum).Sensor     = 'Sum';
                        senData(SensNum).Unit       = 's';
                        senData(SensNum).Method     = '';
                        senData(SensNum).Value      = []; % Init Value
                        senData(SensNum).Note       = '';
                        senData(SensNum).Chapter    = decodeSections{decodeID};
                        
                        % Read the data matrix
                        while ~isempty(linestr)
                            C = textscan(linestr,'%s');
                            C = vertcat(C{:});
                            linestr = Coder.get('whole');
                            
                            % Add data to value-vektor
                            SensNum = 1; % dPidtX
                            senData(SensNum).Value = [senData(SensNum).Value str2double(C{SensNum})];
                            SensNum = 2; % MpiX1
                            senData(SensNum).Value = [senData(SensNum).Value str2double(C{SensNum})];
                            SensNum = 3; % Time
                            senData(SensNum).Value = [senData(SensNum).Value str2double(C{SensNum})];
                            SensNum = 4; % Sum
                            senData(SensNum).Value = [senData(SensNum).Value str2double(C{SensNum})];
                            
                            % Next line
                            curSenLine = curSenLine + 1;
                        end
                        
                        eval(['s.' sectionName{decodeID} ' = senData;']);       
                end   
            end
        end
        
        function encode(self, FID, s)
            
        end
    end
    
    methods
        function PTD = computePTD(self)
            % Calculation of Pitch Travelled Distance (PTD) based on load duration matrix
            
            % Pitch Travelled Distance (PTD) is found by
            % multiplying dPidt with Time and summing the
            % absolute values.
            
            PTD(1) = sum(abs(self.Blade1PitchSpdvsPitchMomDuration(1).Value.*self.Blade1PitchSpdvsPitchMomDuration(3).Value)); % Blade 1
            PTD(2) = sum(abs(self.Blade2PitchSpdvsPitchMomDuration(1).Value.*self.Blade2PitchSpdvsPitchMomDuration(3).Value)); % Blade 2
            PTD(3) = sum(abs(self.Blade3PitchSpdvsPitchMomDuration(1).Value.*self.Blade3PitchSpdvsPitchMomDuration(3).Value)); % Blade 3
            
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

