classdef FRQ
    properties
        filename
        PrepVersion
        SimTitle
        Vavg,Weib,lifetime
        LC,time,frq,family,method,LF,V
        
    end
    
    methods (Static)
        function s = decode(Coder)
            FID = Coder.openFile;         
            line  = LAC.codec.ElementLine();  
            s = eval(mfilename('class')); 
                        
            [s.filename] = Coder.getSource;
            
            [s.PrepVersion] = line.decode(FID);
            [s.SimTitle] = line.decode(FID);
            line.decode(FID);  
            line.decode(FID);
            s.Vavg=line.decode(FID);
            s.Weib=line.decode(FID);
            s.lifetime = line.decode(FID);
            line.decode(FID);
            line.decode(FID);
            
            filecontent = textscan(FID, '%s', 'delimiter','\n'); 
            stop = length(filecontent{1,1})-2;

            for line=1:stop
                %Extract primary .set data
                try
                    data(line,1:7) = textscan(filecontent{1,1}{line,1}, '%s %f %f %f %f %f (%f)'); 
                catch
                    continue
                end
            end
            s.LC=[data{:,1}];
            s.time=[data{:,2}];
            s.frq=[data{:,3}];
            s.family=[data{:,4}];
            s.method=[data{:,5}];
            s.LF=[data{:,6}];
            s.V=[data{:,7}];
            
            fclose(FID);
        end
        
        function encode(self, FID, s)
           
        end
        
        function compareListOfFrequencyObjects(varargin)
            % A function for comparing the hourly distribution between two frequency files.
            
            % frequencyObjList: {FrgObj1, FrgObj2,...}
            
            parser = inputParser;
            parser.KeepUnmatched = true;
            
            %Set default values.
            parser.addParamValue('FrequencyObjList',[]);
            parser.addParamValue('legend_texts', []);
            
            %Parse.
            parser.parse(varargin{:});
            
            % Set variables.
            FrequencyObjList = parser.Results.('FrequencyObjList');
            legend_texts = parser.Results.('legend_texts');
            
            % Initiate.
            figure;
            hold on;
            cmap = hsv(length(FrequencyObjList));
            plot_handles = [];
            
            % Loop.
            for iFrequencyFileObj=1:length(FrequencyObjList);
                % Set object.
                FrequencyFileObj = FrequencyObjList{iFrequencyFileObj};
                
                % Set color.
                Color = cmap(iFrequencyFileObj, :);

                % Filter load cases.
                RegExpFilter = '11.*';
                LC = FrequencyFileObj.LC;
                IndicesToUse = ~cellfun(@isempty,regexp(LC,'^11.*a.*1\.int'));
                
                nseeds = sum(~cellfun(@isempty,regexp(LC,'^1104.*')));
                
                % Set data to use for plotting.
                windspeeds = FrequencyFileObj.V(IndicesToUse);
                hours = FrequencyFileObj.time(IndicesToUse);
                hours = hours*nseeds;
                
                % Plot.
                plot(windspeeds, hours, 'Color',Color);
                xlabel('Wind speed [m/s]');
                ylabel('Hours [m/s]');
                grid on;
                if ~isempty(legend_texts)
                    legend(plot_handles, legend_texts);
                end

            end

        end
    end
end
   
