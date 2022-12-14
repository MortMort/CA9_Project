classdef NAC < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.Ax,s.Ay] = VTSCoder.get();
            [s.Cdx,s.Cdyz] = VTSCoder.get();
            [s.XlatK,s.zkk2,s.Rtac] = VTSCoder.get();
            
            VTSCoder.skip(1);
            s.Table{1} = VTSCoder.readTableData(1, 7);
            s.Table{1}.columnnames = {'Mass','Cgy','Cgx','Cgz','J2x0','J2y0','J2z0'};
            VTSCoder.skip(1); % -1
            
            [s.DamperMass] = VTSCoder.get();
            [s.DamperXnd,s.DamperYnd,s.DamperZnd] = VTSCoder.get();
            [s.DamperLogDX,s.DamperLogDY,s.DamperLogDZ] = VTSCoder.get();
            [s.DamperKx,s.DamperKy,s.DamperKz] = VTSCoder.get();
            [s.DamperStopXmax,s.DamperStopYmax,s.DamperStopZmax,s.DamperStopKratx,s.DamperStopKraty,s.DamperStopKratz] = VTSCoder.get();
            
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
            VTSCoder.setProperty({self.Ax,self.Ay}, 23, 'Ax Ay');
            VTSCoder.setProperty({self.Cdx,self.Cdyz}, 23, 'Cdx Cdyz');
            VTSCoder.setProperty({self.XlatK,self.zkk2,self.Rtac}, 23, 'XlatK zkk2 Rtac');
            
            tHeader = strjoin_LMT(self.Table{1}.columnnames,'     ');
            VTSCoder.setLine(tHeader);
            VTSCoder.writeTableData(self.Table{1},'%8.1f');
            VTSCoder.setProperty({sprintf('%.0f',-1)}, 1, ''); % VTS manual: "-1 indicates that the table for the different masses in the nacelle is ended."
            
            VTSCoder.setProperty({self.DamperMass}, 23, 'Damper mass');
            VTSCoder.setProperty({self.DamperXnd,self.DamperYnd,self.DamperZnd}, 23, 'Damper xnd ynd znd');
            VTSCoder.setProperty({self.DamperLogDX,self.DamperLogDY,self.DamperLogDZ}, 23, 'Damper LogD xyz');
            VTSCoder.setProperty({self.DamperKx,self.DamperKy,self.DamperKz}, 23, 'Damper Kx Ky Kz');
            VTSCoder.setProperty({self.DamperStopXmax,self.DamperStopYmax,self.DamperStopZmax,self.DamperStopKratx,self.DamperStopKraty,self.DamperStopKratz}, 23, 'Damper stops: xmax ymax zmax Kratx Kraty Kratz');
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'Table')); % FoundationTable is not a property
            mytables = {'Table'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
    end        
    
    properties
        Header
        Ax,Ay
        Cdx,Cdyz
        XlatK,zkk2,Rtac
        Table
        DamperMass
        DamperXnd,DamperYnd,DamperZnd
        DamperLogDX,DamperLogDY,DamperLogDZ
        DamperKx,DamperKy,DamperKz
        DamperStopXmax,DamperStopYmax,DamperStopZmax, DamperStopKratx,DamperStopKraty,DamperStopKratz
        comments
    end
end
