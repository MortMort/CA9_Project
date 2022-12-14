classdef BandPassFilter   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS
% whirlingLowPass
% whirlingHighPass
% edgeLowPassn
% edgeHighPass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE
% LAC.timetrace.models.BandPassFilter()
% LAC.timetrace.models.BandPassFilter(0.75, 1.3, 0.5, 1.5)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Created by:  JANOW, 30.05.2019
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     properties (Access = public)
       whirlingLowPass;
       whirlingHighPass;
       edgeLowPass;
       edgeHighPass;
     end % end properties   
     methods        
       function self = BandPassFilter(varargin)  % BandPassFilter constructor
           if nargin == 0
               self.whirlingLowPass = 0.85;
               self.whirlingHighPass = 1.15;
               self.edgeLowPass = 0.6;
               self.edgeHighPass = 1.4;
           elseif nargin == 4
               self.whirlingLowPass = varargin{1};
               self.whirlingHighPass = varargin{2};
               self.edgeLowPass = varargin{3};
               self.edgeHighPass = varargin{4};
               
               self.checkPassRange();
           else
               msg = 'The number of parameters is incorrect!';
               error(msg)
           end
        end % end BandPassFilter constructor
        
     end
     
     methods (Access = private)
        function checkPassRange(self)
            if (self.whirlingLowPass <= 0.7 || ...
                    self.whirlingLowPass > self.whirlingHighPass || ...
                    self.whirlingHighPass >= 1.3 ...
                )
                msg = 'Whirling low pass and high pass are incorrect! Please, provide values between 0.7 and 1.3';
                error(msg)
            end

            if (self.edgeLowPass <= 0.5 || ...
                    self.edgeLowPass > self.edgeHighPass || ...
                    self.edgeHighPass >= 1.5 ...
                )
                msg = 'Edge low pass and high pass are incorrect! Please, provide values between 0.5 and 1.5';
                error(msg)
            end
        end
     end % methods
     
end  % end classdef