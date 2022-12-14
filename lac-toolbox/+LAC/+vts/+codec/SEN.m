classdef SEN < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            
            startline = VTSCoder.current();
            s.Sensors = VTSCoder.getList(startline,'end','');
            
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
            VTSCoder.setList(self.Sensors,' ');
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    
        function myattributes = getAttributes(self)
            myattributes = struct();
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'Sensors'));
            mytables = {};
            myfiles = {};
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        Sensors
        comments
    end
end
