classdef DRT < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.Damping5,s.Damping6,s.Damping7,s.ND] = VTSCoder.get();
            [tmp] = VTSCoder.get();
            VTSCoder.jump(VTSCoder.current-1)
            if strcmp(tmp,'explicit')
                [dummy, s.ktors,s.ktilt,s.kyaw] = VTSCoder.get();
            end
            s.ShaftSectionTable{1} = VTSCoder.getTable(2);
            s.ShaftSectionTable{1}.header = {'x','Dout','Din','Radius'};
            
            s.sectionline1 = VTSCoder.get(true);
            [s.kgear] = VTSCoder.get();
            [s.kHSS] = VTSCoder.get();
            [s.VerticalStiffness] = VTSCoder.get();
            [s.HorizontalStiffnessLow, s.HorizontalStiffnessHigh] = VTSCoder.get();
            [s.DistanceGearStays] = VTSCoder.get();
            [s.DistanceMainBearingGearStays] = VTSCoder.get();
            s.sectionline2 = VTSCoder.get(true);
            [s.igear] = VTSCoder.get();
            [s.Jgear] = VTSCoder.get();
            [s.JbrakeHub] = VTSCoder.get();
            [s.Jgenhub] = VTSCoder.get();
            [s.Jhss] = VTSCoder.get();
            [s.R_V,s.K0_Ktors,s.m] = VTSCoder.get();
            s.sectionline3 = VTSCoder.get(true);
            [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            self = self.convertAllToString();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.Damping5,self.Damping6,self.Damping7,self.ND}, 27, 'Damping 5 6 7 ND');
            if ~isempty(self.ktors)
                VTSCoder.setProperty({'explicit', self.ktors,self.ktilt,self.kyaw}, 21, 'ktors ktilt kyaw');
            end
%             VTSCoder.setProperty({num2str(size(self.ShaftSectionTable{1}.data,1))}, 21, 'no of shaft sections');
            % Convert table to strings.
            TableCopy = self.ShaftSectionTable;
            nrows = size(TableCopy{1}.data,1);
            ncolumns = size(TableCopy{1}.data,2);
            % Loop.
            for irow=1:nrows
                for icolumn=1:ncolumns
                    TableCopy{1}.data{irow,icolumn} = TableCopy{1}.data{irow,icolumn};
                end
            end
            VTSCoder.setTable(TableCopy{1},3);
            
            %VTSCoder.setTable(self.ShaftSectionTable{1}.Header, self.ShaftSectionTable{1}.Data);
            
            VTSCoder.setProperty(self.sectionline1);
            VTSCoder.setProperty({self.kgear}, 21, 'kgear (rel to LSS) [Nm/rad]');
            VTSCoder.setProperty({self.kHSS}, 21, 'kHSS (including flexible couplings) [Nm/rad]');
            VTSCoder.setProperty({self.VerticalStiffness}, 21, 'vertical stiffness of one gear stay [N/m] (2b/side)');
            VTSCoder.setProperty({self.HorizontalStiffnessLow, self.HorizontalStiffnessHigh}, 21, 'horz. stiffness low/high  [N/m]');
            VTSCoder.setProperty({self.DistanceGearStays}, 21, 'distance between gear stays [m]');
            VTSCoder.setProperty({self.DistanceMainBearingGearStays}, 21, 'distance between main bearing and gear stay [m]');
            VTSCoder.setProperty(self.sectionline2);
            VTSCoder.setProperty({self.igear}, 21, 'igear');
            VTSCoder.setProperty({self.Jgear}, 21, 'Jgear (rel to HSS)');
            VTSCoder.setProperty({self.JbrakeHub}, 21, 'Jbrake hub');
            VTSCoder.setProperty({self.Jgenhub}, 21, 'Jgenhub');
            VTSCoder.setProperty({self.Jhss}, 21, 'Jhss 	(including flexible couplings)');
            VTSCoder.setProperty({self.R_V,self.K0_Ktors,self.m}, 21, 'V (deg), R/V, K0/Ktors  (main shaft play),v=0.5*slør,m');
            VTSCoder.setProperty(self.sectionline3);
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    end
    
    methods %(Access=protected)
        function myattributes = getAttributes(self)
            
            %check matlab version
            [a dateb]  = version;
            datebnum = datenum(dateb);
            
            myattributes = struct();
            
            mco = metaclass(self);
            if datebnum > 734174
                myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            else
                for i = 1 : length(mco.Properties)
                    idx = 0;
                    if strcmpi(mco.Properties{i}.SetAccess,'public')
                        idx = idx + 1;
                        myproperties{i} = mco.Properties{i}.Name;
                    end
                end
            end               
            mytables = {'ShaftSectionTable'};
            myfiles = {};
            myproperties = myproperties(~strcmpi(myproperties,'ShaftSectionTable'));
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end       
    
    properties
        Header
        Damping5,Damping6,Damping7,ND
        ktors,ktilt,kyaw        
        ShaftSectionTable
        sectionline1
        kgear
        kHSS
        VerticalStiffness
        HorizontalStiffnessLow,HorizontalStiffnessHigh
        DistanceGearStays
        DistanceMainBearingGearStays
        sectionline2
        igear
        Jgear
        JbrakeHub
        Jgenhub
        Jhss
        R_V,K0_Ktors,m
        sectionline3
        comments
    end
end
