classdef TWR < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.DOFDownwind1,s.DOFDownwind2,s.DOFDownwind3,s.DOFDownwind4] = VTSCoder.get();
            [s.DOFcrosswind1,s.DOFcrosswind2,s.DOFcrosswind3,s.DOFcrosswind4] = VTSCoder.get();
            [s.DOFForeaft,s.DOFSideSide] = VTSCoder.get();
            [s.XH,s.Xm11,s.Xm12,s.Xm22,s.Xk,s.Xxmax,s.XKhiKlo] = VTSCoder.get();
            [s.YH,s.Ym11,s.Ym12,s.Ym22,s.Yk,s.Yxmax,s.YKhiKlo] = VTSCoder.get();
            [s.mcor,s.Cshcor,s.Cdcor,s.Emod] = VTSCoder.get();
            [s.SectionTableNrOfFields] = VTSCoder.get();
            table{1} = VTSCoder.readTableData(str2num(s.SectionTableNrOfFields),6);
            s.SectionTable.headers = {'H','D','t','M','Cd','Out'};

            [s.comments] = VTSCoder.getRemaininglines();
            s = s.convertAllToNumeric();
            
            % Convert sectional properties from table format
            mat = str2double(table{1}.data);            
            s.SectionTable.Height    = round(mat(:,1)*100)/100;
            s.SectionTable.Diameter  = round(mat(:,2)*1000)/1000;
            s.SectionTable.Thickness = mat(:,3);
            s.SectionTable.Mass      = round(mat(:,4));
            s.SectionTable.Cd        = mat(:,5);
            s.SectionTable.Out       = mat(:,6);
            
            %Prep002 corrections
            % Prep002 hardDoce
            rhoFe = 7850.0;          
            s.Emod = s.Emod*10^6;
            s.Density = round(s.mcor*rhoFe);
        end
    end
    
    methods
        function encode(self,filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            
            self.Emod = self.Emod/10^6;
            self = self.convertAllToString();
            
            % Convert sectional properties into table format
            mat(:,1) = self.SectionTable.Height   ;
            mat(:,2) = self.SectionTable.Diameter ;
            mat(:,3) = self.SectionTable.Thickness;
            mat(:,4) = self.SectionTable.Mass     ;
            mat(:,5) = self.SectionTable.Cd       ;
            mat(:,6) = self.SectionTable.Out      ;
            table{1}.data = cellfun(@num2str, num2cell(mat), 'UniformOutput', false);
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.DOFDownwind1,self.DOFDownwind2,self.DOFDownwind3,self.DOFDownwind4}, 23, 'Log. Damping DownWind');
            VTSCoder.setProperty({self.DOFcrosswind1,self.DOFcrosswind2,self.DOFcrosswind3,self.DOFcrosswind4}, 23, 'Log. Damping CrossWind');
            VTSCoder.setProperty({self.DOFForeaft,self.DOFSideSide}, 23, 'Log. Damping Damper');
            VTSCoder.setProperty({self.XH,self.Xm11,self.Xm12,self.Xm22,self.Xk,self.Xxmax,self.XKhiKlo}, 23, 'X: H m11 m12 m22 kx xmax Khi/Klo');
            VTSCoder.setProperty({self.YH,self.Ym11,self.Ym12,self.Ym22,self.Yk,self.Yxmax,self.YKhiKlo}, 23, 'Y: H m11 m12 m22 ky ymax Khi/Klo');
            VTSCoder.setProperty({self.mcor,self.Cshcor,self.Cdcor,self.Emod}, 23, 'mcor    Cshcor  Cdcor   Emod');
            VTSCoder.setProperty({self.SectionTableNrOfFields},10,strjoin_LMT(self.SectionTable.headers));
            VTSCoder.writeTableData(table{1},'%9.4f');
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    
        function myattributes = getAttributes(self)
            myattributes = struct();
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'SectionTable')); % TowerCrossSections is not a property
% 
            mytables = {};
            myfiles = {};
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        DOFDownwind1,DOFDownwind2,DOFDownwind3,DOFDownwind4
        DOFcrosswind1,DOFcrosswind2,DOFcrosswind3,DOFcrosswind4
        DOFForeaft,DOFSideSide
        XH,Xm11,Xm12,Xm22,Xk,Xxmax,XKhiKlo
        YH,Ym11,Ym12,Ym22,Yk,Yxmax,YKhiKlo
        mcor,Cshcor,Cdcor,Emod
        SectionTableNrOfFields
        comments
        SectionTable
        Density 
    end
end
