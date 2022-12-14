classdef HUB < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            
            [s.Mhub,s.ZGNAV,s.ZNAV,s.ZRN,s.ZRMB] = VTSCoder.get();
            [s.Rhub,s.Iyhub,s.Ixhub,s.Izhub] = VTSCoder.get();
            [s.Cdxs,s.Cdyzs,s.ARx,s.ARyz,s.XlatR] = VTSCoder.get();
            [s.Nacc] = VTSCoder.get();
            
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
            VTSCoder.setProperty({self.Mhub,self.ZGNAV,self.ZNAV,self.ZRN,self.ZRMB}, 47, 'Mhub; YGNAV; YNAV; YRN; YRMB');
            VTSCoder.setProperty({self.Rhub,self.Iyhub,self.Ixhub,self.Izhub}, 47, 'Rhub; Iyhub; Ixhub; Izhub (see input file)');
            VTSCoder.setProperty({self.Cdxs,self.Cdyzs,self.ARx,self.ARyz,self.XlatR}, 47, 'Cdxs; Cdyzs; ARx; ARyz; XlatR');
            VTSCoder.setProperty({self.Nacc}, 47, 'Nacc');

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
            mytables = {};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end
         
    
    properties
        Header
        Mhub,ZGNAV,ZNAV,ZRN,ZRMB
        Rhub,Ixhub,Iyhub,Izhub
        Cdxs,Cdyzs,ARx,ARyz,XlatR
        Nacc
        comments
    end
    
end
