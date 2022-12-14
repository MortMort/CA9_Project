classdef BLD_update < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get('line');
            [s.StallOnOff, s.dCLda, s.dCLdaS, s.AlfS, s.Alfrund, s.Taufak] = VTSCoder.get('value');
            [s.NumberOfProfileDataSets] = VTSCoder.get('value');
            s.Profile = containers.Map();
            for i = 1:s.NumberOfProfileDataSets
                [mytype, myfilename] = VTSCoder.getFile();
                s.Profile(mytype{1}) = myfilename;
            end
            
            [s.Logd1,s.Logd2,s.Logd3,s.Logd4,s.Logd5,s.Logd6,s.Logd7,s.Logd8] = VTSCoder.get('value');
            [s.B,s.Gamma,s.Tilt,s.X_dr_tip] = VTSCoder.get('value');
            [s.GammaRootFlap,s.GammaRootEdge] = VTSCoder.get('value');
            [s.rd,s.md1,s.md2,s.md3,s.kd,s.Ybdmax,s.Khi_Klo] = VTSCoder.get('value');
            [s.structuralPitch] = VTSCoder.get('value');
            
            [s.PiOff1, s.PiOff2, s.PiOff3] = VTSCoder.get('value');
            [s.AzOff1, s.AzOff2, s.AzOff3] = VTSCoder.get('value');
            [s.KFfac1, s.KFfac2, s.KFfac3] = VTSCoder.get('value');
            [s.KEfac1, s.KEfac2, s.KEfac3] = VTSCoder.get('value');
            [s.KTFac1, s.KTFac2, s.KTfac3] = VTSCoder.get('value');
            [s.mfac1, s.mfac2, s.mfac3] = VTSCoder.get('value');
            [s.Jfac1, s.Jfac2, s.Jfac3] = VTSCoder.get('value');
            [s.dfac1, s.dfac2, s.dfac3] = VTSCoder.get('value');
            
            tabletype = 6;
            s.SectionTable{1} = VTSCoder.getTable(tabletype);

            [s.Retype,s.MFric0,s.mu,s.DL,s.c_fric] = VTSCoder.get();
            
            [s.comments] = VTSCoder.getRemaininglines();
        end
    end
    
    methods
        function status = encode(self, VTSCoder)
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty({self.StallOnOff, self.dCLda, self.dCLdaS, self.AlfS, self.Alfrund, self.Taufak}, 27, 'dCLda; dCLdaS; AlfS; Alfrund; Taufak;');
            
            VTSCoder.setProperty({self.NumberOfProfileDataSets}, 27, 'Number of profile data sets');
            VTSCoder.setFile('DEFAULT',length('STANDSTILL')+2,self.Profile('DEFAULT'));
            VTSCoder.setFile('STANDSTILL',length('STANDSTILL')+2,self.Profile('STANDSTILL'));
            
            VTSCoder.setProperty({self.Logd1,self.Logd2,self.Logd3,self.Logd4,self.Logd5,self.Logd6,self.Logd7,self.Logd8}, 27, 'Logd 1-8 (1. flap, 2. flap, 1. edge, 2. edge, blade damper)');
            VTSCoder.setProperty({self.B,self.Gamma,self.Tilt,self.X_dr_tip}, 27, 'B; Gamma; Tilt; X-dr.tip;');
            VTSCoder.setProperty({self.GammaRootFlap,self.GammaRootEdge}, 27,'GammaRootFlap; GammaRootEdge;');
            VTSCoder.setProperty({self.rd,self.md1,self.md2,self.md3,self.kd,self.Ybdmax,self.Khi_Klo}, 27,'rd; md1; md2; md3; kd; Ybdmax; Khi/Klo');
            VTSCoder.setProperty({self.structuralPitch}, 27,'Structural pitch');
            VTSCoder.setProperty({self.PiOff1, self.PiOff2, self.PiOff3}, 27,'PiOff1 PiOff2 PiOff3');
            VTSCoder.setProperty({self.AzOff1, self.AzOff2, self.AzOff3}, 27,'AzOff1 AzOff2 AzOff3');
            VTSCoder.setProperty({self.KFfac1, self.KFfac2, self.KFfac3}, 27,'KFfac1 KFfac2 KFfac3');
            VTSCoder.setProperty({self.KEfac1, self.KEfac2, self.KEfac3}, 27,'KEfac1 KEfac2 KEfac3');
            VTSCoder.setProperty({self.KTFac1, self.KTFac2, self.KTfac3}, 27,'KTFac1 KTFac2 KTfac3');
            VTSCoder.setProperty({self.mfac1, self.mfac2, self.mfac3}, 27,'mfac1 mfac2 mfac3');
            VTSCoder.setProperty({self.Jfac1, self.Jfac2, self.Jfac3}, 27,'Jfac1 Jfac2 Jfac3');
            VTSCoder.setProperty({self.dfac1, self.dfac2, self.dfac3}, 27,'dfac1 dfac2 dfac3');
            
            tabletype = 6;
            VTSCoder.setTable(self.SectionTable{1}, tabletype);
            
            VTSCoder.setProperty({self.Retype,self.MFric0,self.mu,self.DL,self.c_fric}, 27,'Retype; MFric0 [Nm];mu;DL [m]');
            
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    end
    
    methods (Access=protected)
        function [myproperties, mytables, myfiles] = getAttributes(self)
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'SectionTable')); % SectionTable is not a property
            myproperties = myproperties(~strcmpi(myproperties,'Profile')); % Profile is not a property
            
            mytables = {'SectionTable'};
            myfiles = {'Profile'};
        end
    end        
    
    properties
        Header
        StallOnOff,dCLda,dCLdaS,AlfS,Alfrund,Taufak
        NumberOfProfileDataSets
        Profile
        Logd1,Logd2,Logd3,Logd4,Logd5,Logd6,Logd7,Logd8
        B,Gamma,Tilt,X_dr_tip
        GammaRootFlap,GammaRootEdge
        rd,md1,md2,md3,kd,Ybdmax,Khi_Klo
        structuralPitch
        PiOff1,PiOff2,PiOff3
        AzOff1,AzOff2,AzOff3
        KFfac1,KFfac2,KFfac3
        KEfac1,KEfac2,KEfac3
        KTFac1,KTFac2,KTfac3
        mfac1,mfac2,mfac3
        Jfac1,Jfac2,Jfac3
        dfac1,dfac2,dfac3
        SectionTable
        Retype,MFric0,mu,DL,c_fric
        comments
    end
    
    properties (Dependent=true, SetAccess=private)
        DEFAULT
        STANDSTILL
    end
    
    methods
        function decoded = get.DEFAULT(self)
            decoded = [];
            myfilename = self.Profile('DEFAULT');
            if ~exist(myfilename, 'file')
                myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
            end
            if exist(myfilename, 'file')
                readerobj = LAC.codec.CodecTXT(myfilename);
                decoded = LAC.vts.codec.PROFILE.decode(readerobj);
            end
        end
        function decoded = get.STANDSTILL(self)
            decoded = [];
            myfilename = self.Profile('STANDSTILL');
            if ~exist(myfilename, 'file')
                myfilename = LAC.vts.shared.absolutepath(myfilename,fileparts(self.FileName),false);
            end
            if exist(myfilename, 'file')
                readerobj = LAC.codec.CodecTXT(myfilename);
                decoded = LAC.vts.codec.PROFILE.decode(readerobj);
            end
        end
    end    
end
