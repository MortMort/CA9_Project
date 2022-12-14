classdef MKO < handle
    properties
        filename
        
        sensno,sensor
        
        markov
    end
    
    
    methods (Static)
        function s = decode(VTSDecoder)
            VTSDecoder.rewind;         
              
            s = eval(mfilename('class')); 
            
            [s.filename] = VTSDecoder.getSource(); 
            
            VTSDecoder.get();VTSDecoder.get();
            % find sensor no
            [s.sensno s.sensor] = VTSDecoder.get();
               
            
            %VTSDecoder.get();VTSDecoder.get();VTSDecoder.get();VTSDecoder.get();
            
            markovStr = VTSDecoder.lines(8,10000);
            for i = 1:length(markovStr) 
                dummy = textscan(markovStr{i},'%f %f %f %f');
                Markov(i).Level = dummy{1};
                Markov(i).Range = dummy{2};
                Markov(i).Cycles = dummy{3};
                Markov(i).CumCycles = dummy{4};
            end
                        
            s.markov.Level = s.Yrange([Markov.Level]);
            LevelMax = max(s.markov.Level);

            s.markov.Range = s.Yrange([Markov.Range]);
            RangeMax = max(s.markov.Range);
            
            s.markov.CountWithLevelRange(:,1) = [0 s.markov.Level];
            Count = [Markov.Cycles];
            for i = 1:length(Markov)
               im = round( (LevelMax-Markov(i).Level)/(s.markov.Level(1)-s.markov.Level(2)) )+1; 
               id = round( (RangeMax-Markov(i).Range)/(s.markov.Range(1)-s.markov.Range(2)) )+1;
               s.markov.CountWithLevelRange(im+1,id+1) = Count(i);
               s.markov.Count(im,id) = Count(i);
            end
            s.markov.CountWithLevelRange(1,:) = [0 s.markov.Range];

        end
        
        function encode(self, FID, s)
            
        end
    end
    
    methods (Access=public)
        
        function Yr = Yrange(self,Y) 
            %% Data read from file in columns are converted to a matrix:

            Ymax = max(Y);
            Ymin = min(Y);

            dy = min(diff(unique(Y)));

            nd = round((Ymax-Ymin)/dy)+1;

            Yr = Ymax - (Ymax-Ymin)/(nd-1)*[0:nd-1];

        end
    end
end
