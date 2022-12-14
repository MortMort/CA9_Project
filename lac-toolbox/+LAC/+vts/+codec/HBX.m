classdef HBX < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.ExtenderDensity, s.E] = VTSCoder.get();
            [s.NSections, s.nTubes] = VTSCoder.get();
            s.SectionsTable{1} = VTSCoder.readTableData(3, 6);
            s.SectionsTable{1}.columnnames = {'L','d1','t1','d2','t2','tbd'};
            [s.nbolt,s.dbolt] = VTSCoder.get();
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
            VTSCoder.setProperty({self.ExtenderDensity, self.E}, 27, 'Density for extender, E');
            VTSCoder.setProperty({self.NSections, self.nTubes}, 27, 'No of sections No of tubes');
            VTSCoder.writeTableData(self.SectionsTable{1},'%8.1f');
            VTSCoder.setProperty({self.nbolt,self.dbolt}, 27, 'nbolt dbolt [m]');
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'SectionsTable')); % SectionsTable is not a property
            mytables = {'SectionsTable'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        ExtenderDensity,E
        NSections,nTubes
        SectionsTable
        nbolt,dbolt
        comments
    end
end
