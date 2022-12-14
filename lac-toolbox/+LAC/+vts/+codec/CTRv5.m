classdef CTRv5 < LAC.vts.codec.CTRv4
    methods (Static)
        function s = decode(VTSCoder)
            s = eval(mfilename('class'));
            %A check of IF versinos should be included
            s.ProductionControlInterfaceVersion = 5;
            s=s.decodeMe(VTSCoder);
            s.comments=VTSCoder.getRemaininglines();
        end
    end
end
   
