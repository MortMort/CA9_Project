classdef PARAMETER < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = 'Parameter';
            s.Parameters = VTSCoder.getList(VTSCoder.current(),-1,'=');
            %[s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function status = encode(self, VTSCoder)
            VTSCoder.rewind();
            
            VTSCoder.initialize('profile', mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setList(self.Parameters, ' = ');
            %VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            myproperties = {};
            mytables = {};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end
    
    properties
        Parameters
    end
end
   
