classdef YAW < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.LogD11,s.LogD12] = VTSCoder.get();
            [s.Kyawlo,s.Kyawhi,s.ktilt] = VTSCoder.get();
            [s.V,s.R] = VTSCoder.get();
            [s.vmot,s.igear,s.Tau] = VTSCoder.get();
            [s.nomt,s.Imot,s.Mfricmot,s.Eta] = VTSCoder.get();
            [s.nbrk,s.Mfricbrk] = VTSCoder.get();
            [s.UserDefined,s.MfricStat,s.cFz,s.cFxy,s.cMxy,s.MfricDyn] = VTSCoder.get();
            [s.comments] = VTSCoder.getRemaininglines();
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.LogD11,self.LogD12}, 36, 'LogD11 LogD12');
            VTSCoder.setProperty({self.Kyawlo,self.Kyawhi,self.ktilt}, 36, 'kyawlo kyawhi ktilt');
            VTSCoder.setProperty({self.V,self.R}, 36, 'V R');
            VTSCoder.setProperty({self.vmot,self.igear,self.Tau}, 36, 'vmot [rpm], igear, Tau [s]');
            VTSCoder.setProperty({self.nomt,self.Imot,self.Mfricmot,self.Eta}, 36, 'nmot [-], Imot [kgm2], Mfricmot [Nm], Eta');
            VTSCoder.setProperty({self.nbrk,self.Mfricbrk}, 36, 'nbrk, Mfricbrk [Nm]');
            VTSCoder.setProperty({self.UserDefined,self.MfricStat,self.cFz,self.cFxy,self.cMxy,self.MfricDyn}, 36, 'RE-type MfricStat, cFz, cFxy, cMxy MfricDyn');
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
        LogD11,LogD12
        Kyawlo,Kyawhi,ktilt
        V,R
        vmot,igear,Tau
        nomt,Imot,Mfricmot,Eta
        nbrk,Mfricbrk
        UserDefined,MfricStat,cFz,cFxy,cMxy,MfricDyn
        comments
    end
end



