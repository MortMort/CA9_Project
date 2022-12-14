classdef BRK < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.Jbrake] = VTSCoder.get();
            [s.OmBrkOn,s.DynFak,s.Swdfak] = VTSCoder.get();
            [s.nCallibers] = VTSCoder.get();
            [s.DynBrakeTorque,s.Tau,s.TdelayCalliper1] = VTSCoder.get();
            
            % TBD: Support for several self.nCallibers
            % for i=1:str2double(s.nCallibers)
            %     [s.DynBrakeTorque, s.Tau, s.TdelayCalliper1] = VTSCoder.get();
            % end
            
            [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function encode(self,filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            
            VTSCoder.setProperty({self.Jbrake}, 23, 'Jbrake');
            VTSCoder.setProperty({self.OmBrkOn,self.DynFak,self.Swdfak}, 23, 'OmBrkOn DynFak Swdfak');
            VTSCoder.setProperty({self.nCallibers}, 23, 'No. of Callibers');
            % TBD: Support for several self.nCallibers
            VTSCoder.setProperty({self.DynBrakeTorque,self.Tau,self.TdelayCalliper1}, 23, 'Dyn. Brake Torque, Tau, Tdelay [kNm,s,s] Calliper 1');
            
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
        Jbrake
        OmBrkOn,DynFak,Swdfak
        nCallibers
        DynBrakeTorque,Tau,TdelayCalliper1
        comments
    end
end
