classdef WND < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.ReferenceStandard,s.Windpar] = VTSCoder.get();
            [s.IECgustWindpar,s.IECgust,s.Turbpar,s.Dummy1] = VTSCoder.get();
            
            try
                % this will try to pull 4 variables in, assuming
                % TurbQuantiles is available
                [s.TurbulenceStandard,s.TurbPar,s.Dummy2,s.AdditionalFactor,s.TurbQuantiles] = VTSCoder.get();
                if isempty(str2num(s.TurbQuantiles))
                    s.TurbQuantiles = [];
                end   
            catch % error is assumed to be one variable missing
                [s.TurbulenceStandard,s.TurbPar,s.Dummy2,s.AdditionalFactor] = VTSCoder.get();
                s.TurbQuantiles = [];
            end
            
            [s.Iparked,s.Ipark0,s.RowSpacing,s.ParkSpacing] = VTSCoder.get();
            [s.I2,s.I3] = VTSCoder.get();
            [s.TerrainSlope] = VTSCoder.get();
            [s.WindShearExponent] = VTSCoder.get();
            [s.Rhoext,s.Rhofat] = VTSCoder.get();
            [s.Vav,s.k,s.Lifetime] = VTSCoder.get();
            [s.comments] = VTSCoder.getRemaininglines();
            s = s.convertAllToNumeric();
            if strcmp(s.TurbulenceStandard,'VSCTable')
                [lines, lineno] = VTSCoder.search('SiteTurb');
                lineno = lineno+2;
                VTSCoder.jump(lineno);
                count = 1;
                Line = textscan(VTSCoder.get('whole'),'%f');
                while Line{1}(1) > 0
                    s.VSCtabel(count).WSs = Line{1}(1);
                    s.VSCtabel(count).WSe = Line{1}(2);
                    s.VSCtabel(count).DetWind = Line{1}(3);
                    s.VSCtabel(count).NtmFat = Line{1}(4);
                    s.VSCtabel(count).NtmExt = Line{1}(5);
                    s.VSCtabel(count).Etm = Line{1}(6);
                    lineno = lineno + 1;
                    count = count + 1;
                    Line = textscan(VTSCoder.get('whole'),'%f');
                end
                
                [lines, lineno_V50] = VTSCoder.search('V50');
                if ~isempty(lines)
                    Line = textscan(lines{1},'%s');
                    s.V50 = str2double(Line{1}{2});
                    lineno = lineno_V50;
                else
                    lineno = lineno + 3;
                end
                VTSCoder.jump(lineno-2);
            end
            if strcmp(s.TurbulenceStandard,'LNTable')
                [lines, lineno] = VTSCoder.search('SiteTurb');
                lineno = lineno+2;
                VTSCoder.jump(lineno);
                count = 1;
                Line = textscan(VTSCoder.get('whole'),'%f');
                while Line{1}(1) > 0
                    s.LNtable(count).WSs = Line{1}(1);
                    s.LNtable(count).WSe = Line{1}(2);
                    s.LNtable(count).DetWind = Line{1}(3);
                    s.LNtable(count).NtmFat = Line{1}(4);
                    s.LNtable(count).NtmExt = Line{1}(5);
                    s.LNtable(count).Etm = Line{1}(6);
                    if length(Line{1}) > 6
                        s.LNtable(count).WS_Prob = Line{1}(7);
                        s.LNtable(count).LN_MEAN = Line{1}(8);
                        s.LNtable(count).LN_STD = Line{1}(9);
                    else
                        s.LNtable(count).WS_Prob = 0;
                        s.LNtable(count).LN_MEAN = 0;
                        s.LNtable(count).LN_STD = 0;
                    end
                    lineno = lineno + 1;
                    count = count + 1;
                    Line = textscan(VTSCoder.get('whole'),'%f');
                end
                
                [lines, lineno_V50] = VTSCoder.search('V50');
                if ~isempty(lines)
                    Line = textscan(lines{1},'%s');
                    s.V50 = str2double(Line{1}{2});
                    lineno = lineno_V50;
                else
                    lineno = lineno + 3;
                end
                VTSCoder.jump(lineno-2);
            end			
            [s.comments] = VTSCoder.getRemaininglines();
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.ReferenceStandard,self.Windpar}, 39, 'reference standard, windpar');
            VTSCoder.setProperty({self.IECgustWindpar,self.IECgust,self.Turbpar,self.Dummy1}, 39, 'iecgust windpar, iecgust turbpar, a (dummy if IECed3)');
            VTSCoder.setProperty({self.TurbulenceStandard,self.TurbPar,self.Dummy2,self.AdditionalFactor,self.TurbQuantiles}, 39, 'Turbulence standard, turbpar, a (dummy if IECed3), additional factor, LogNormal quantiles');
            VTSCoder.setProperty({self.Iparked,self.Ipark0,self.RowSpacing,self.ParkSpacing}, 39, 'Iparked Ipark0, row spacing, park spacing');
            VTSCoder.setProperty({self.I2,self.I3}, 39, 'I2,I3');
            VTSCoder.setProperty({self.TerrainSlope}, 39, 'Terrain slope');
            VTSCoder.setProperty({self.WindShearExponent}, 39, 'Wind shear exponent');
            VTSCoder.setProperty({self.Rhoext,self.Rhofat}, 39, 'rhoext rhofat');
            VTSCoder.setProperty({self.Vav,self.k,self.Lifetime}, 39, 'Vav      k       lifetime (for Weibull Calculation)');
            
            if ~isempty(self.VSCtabel)
                VTSCoder.setProperty('');
                VTSCoder.setProperty('SiteTurb');
                VTSCoder.setProperty(sprintf('%-24s%-12s%-12s%-12s%-12s', 'Vhub', 'DETwind', 'NTM_Fat', 'NTM_Ext', 'ETM', 'WS_Prob'));
                for iLine = 1:length(self.VSCtabel)
                    VTSCoder.setProperty(sprintf('%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f', self.VSCtabel(iLine).WSs, self.VSCtabel(iLine).WSe, self.VSCtabel(iLine).DetWind, self.VSCtabel(iLine).NtmFat, self.VSCtabel(iLine).NtmExt, self.VSCtabel(iLine).Etm));
                end
                VTSCoder.setProperty('-1');
            end
            
            if ~isempty(self.LNtable)
                VTSCoder.setProperty('');
                VTSCoder.setProperty('SiteTurb');
                VTSCoder.setProperty(sprintf('%-24s%-12s%-12s%-12s%-12s%-12s%-12s%-12s', 'Vhub', 'DETwind', 'NTM_Fat', 'NTM_Ext', 'ETM', 'WS_Prob', 'LN_MEAN', 'LN_STD'));
                for iLine = 1:length(self.LNtable)
                    VTSCoder.setProperty(sprintf('%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f%-12.3f', self.LNtable(iLine).WSs, self.LNtable(iLine).WSe, self.LNtable(iLine).DetWind, self.LNtable(iLine).NtmFat, self.LNtable(iLine).NtmExt, self.LNtable(iLine).Etm, self.LNtable(iLine).WS_Prob, self.LNtable(iLine).LN_MEAN, self.LNtable(iLine).LN_STD));
                end
                VTSCoder.setProperty('-1');
            end
            
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
        ReferenceStandard,Windpar
        IECgustWindpar,IECgust,Turbpar,Dummy1
        TurbulenceStandard,TurbPar,Dummy2,AdditionalFactor,TurbQuantiles
        Iparked,Ipark0,RowSpacing,ParkSpacing
        I2,I3
        TerrainSlope
        WindShearExponent
        Rhoext,Rhofat
        Vav,k,Lifetime
        VSCtabel
        LNtable
        V50
        comments
    end
end



