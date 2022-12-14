classdef PROFILE < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = 'Profile';
            
            [s.Header] = VTSCoder.get(true);
            [s.nProfiles] = str2double(VTSCoder.get());
            s.ThicknessTable{1} = VTSCoder.readTableData(1, s.nProfiles);
            s.ThicknessTable{1}.columnnames = cellstr(char((65:65+str2double(s.nProfiles)-1)'))';
            %[s.Thickness1,s.Thickness2,s.Thickness3,s.Thickness4,s.Thickness5,s.Thickness6,s.Thickness7,s.Thickness8,s.Thickness9,s.Thickness10,s.Thickness11,s.Thickness12] = VTSCoder.get();
            
            [s.nRows] = str2double(VTSCoder.get());
            
            for i=1:s.nProfiles
                % TBD: Read rownames
                header = VTSCoder.readTableHeader();
                s.ProfileTables{i} = VTSCoder.readTableData(s.nRows, 4);
                s.ProfileTables{i}.header = header;
                s.ProfileTables{i}.columnnames = {'alpha','cL','cD','cM'};
            end
            
            %[s.comments] = VTSCoder.getRemaininglines();
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function encode(self,filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('profile', mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.nProfiles},0,'');
            VTSCoder.writeTableData(self.ThicknessTable{1},'%8.1f'); 
            %VTSCoder.setProperty({self.Thickness1,self.Thickness2,self.Thickness3,self.Thickness4,self.Thickness5,self.Thickness6,self.Thickness7,self.Thickness8,self.Thickness9,self.Thickness10,self.Thickness11,self.Thickness12},0,'');
            VTSCoder.setProperty({self.nRows},0,'');
            
            for i=1:length(self.ProfileTables)
                VTSCoder.writeTableHeader(self.ProfileTables{i}.header);
                VTSCoder.writeTableData(self.ProfileTables{i}, '%8.4f');
            end
            
            %VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    
        function myattributes = getAttributes(self)
            myattributes = struct();
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'ProfileTables'));
            myproperties = myproperties(~strcmpi(myproperties,'ThicknessTable'));
            mytables = {'ProfileTables','ThicknessTable'};
            myfiles = {};
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end
    
    properties
        Header
        nProfiles
        ThicknessTable
        nRows
        ProfileTables
    end
end
