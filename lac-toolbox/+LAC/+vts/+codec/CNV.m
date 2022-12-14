classdef CNV < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            if ~contains(s.Header,'GAPC')
                [s.T_PM,s.Ti,s.kP] = VTSCoder.get();
                [s.T_est,s.Tdamp,s.kdamp,s.dlim] = VTSCoder.get();
                [s.gen_Voltage,s.Pel_rtd,s.ratedRPM] = VTSCoder.get();
                [s.OverspeedLimit1,s.OverspeedReaction1,s.UnderspeedLimit1,s.UnderspeedReaction1] = VTSCoder.get();
                [s.OverspeedLimit2,s.OverspeedReaction2,s.UnderspeedLimit2,s.UnderspeedReaction2] = VTSCoder.get();
                [s.BypassStopType0,s.BypassStopType1,s.BypassStopType2,s.BypassStopType3,s.BypassStopType4] = VTSCoder.get();
                [s.Omega0] = VTSCoder.get();
                [s.StopFastPowerRampRate] = VTSCoder.get();

                [s.comments] = VTSCoder.getRemaininglines();
                s = s.convertAllToNumeric();
            end
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            
            VTSCoder.setProperty({self.T_PM,self.Ti,self.kP}, 25, 'cp.vcs.T_PM, cp.vcs.Ti, cp.vcs.kP');
            VTSCoder.setProperty({self.T_est,self.Tdamp,self.kdamp,self.dlim}, 25, 'T_est,Tdamp,kdamp,dlim');
            VTSCoder.setProperty({self.gen_Voltage,self.Pel_rtd,self.ratedRPM}, 25, 'gen_Voltage, Pel_rtd, rated rpm');
            VTSCoder.setProperty({self.OverspeedLimit1,self.OverspeedReaction1,self.UnderspeedLimit1,self.UnderspeedReaction1}, 25, 'OverspeedLimit1, OverspeedReaction1, UnderspeedLimit1, UnderspeedReaction1');
            VTSCoder.setProperty({self.OverspeedLimit2,self.OverspeedReaction2,self.UnderspeedLimit2,self.UnderspeedReaction2}, 25, 'OverspeedLimit1, OverspeedReaction1, UnderspeedLimit1, UnderspeedReaction1');
            VTSCoder.setProperty({self.BypassStopType0,self.BypassStopType1,self.BypassStopType2,self.BypassStopType3,self.BypassStopType4}, 25, 'Bypass converter control on stop type 0 1 2 3 4');
            VTSCoder.setProperty({self.Omega0}, 25, 'Omega0');
            VTSCoder.setProperty({self.StopFastPowerRampRate}, 25, 'StopFastPowerRampRate (not needed for GS)');
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();

            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            mytables = {};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;            
        end
    end
    
    properties
        Header
        T_PM,Ti,kP
        T_est,Tdamp,kdamp,dlim
        gen_Voltage,Pel_rtd,ratedRPM
        OverspeedLimit1,OverspeedReaction1,UnderspeedLimit1,UnderspeedReaction1
        OverspeedLimit2,OverspeedReaction2,UnderspeedLimit2,UnderspeedReaction2
        BypassStopType0,BypassStopType1,BypassStopType2,BypassStopType3,BypassStopType4
        Omega0
        StopFastPowerRampRate
        comments
    end
end
