classdef SEA < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.rho,s.Depth,s.Ucur,s.DirCur,s.ExpCur] = VTSCoder.get();
            
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
            VTSCoder.setProperty({self.rho,self.Depth,self.Ucur,self.DirCur,self.ExpCur},'40','rho Depth Ucur DirCur ExpCur');
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
        rho,Depth,Ucur,DirCur,ExpCur
        comments
    end
end
