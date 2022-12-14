classdef PWR
    properties
        filename
        V
        P
        T
        Cp
        Ct
        Pitch_Q
        Flap_M
        Edge_M
        Pitch_deg
        rpm
        Tip_x
        Tip_y
        Tip_z
        J_rot
        J_DT       
    end
    methods (Static)
        function obj = decode(Coder)            
            obj = eval(mfilename('class'));                         
            [obj.filename] = Coder.getSource;     
            
            fid = Coder.openFile;
            s = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','HeaderLines',1);
            fclose(fid);
            
            obj.V = s{1};
            obj.P = s{2};
            obj.T = s{3};
            obj.Cp = s{4};
            obj.Ct = s{5};
            obj.Pitch_Q = s{6};
            obj.Flap_M = s{7};
            obj.Edge_M = s{8};
            obj.Pitch_deg = s{9};
            obj.rpm = s{10};
            obj.Tip_x = s{11};
            obj.Tip_y = s{12};
            obj.Tip_z = s{13};
            obj.J_rot = s{14};
            obj.J_DT = s{15};    

        end
    end
end
