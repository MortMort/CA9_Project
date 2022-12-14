classdef PL < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header1] = VTSCoder.get(true);
            [s.Header2] = VTSCoder.get(true);
            
            [s.nPIT] = {}; [s.PIT_R] = {}; [s.PIT_alfa_0] = {}; [s.PIT_A] = {}; [s.PIT_L] = {};
            [s.DRT] = {}; [s.nDRT] = {};           
            [s.PITlockLCs] = {}; [s.nPITlockLCs] = {};
            [s.FND] = {};
            [s.TWR] = {};
            [s.TWR_DLC] = {}; [s.nTWR_DLC] = {};
            [s.FNDx] = {};
            [s.BLDDIREXT] = {}; [s.nBLDDIREXT] = {};
            [s.BLDDIRFAT] = {}; [s.nBLDDIRFAT] = {};   
            s.PDoT = {};   
            [s.TWRDLCEXCLUDE] = {}; [s.nTWRDLCEXCLUDE] = {};
            [s.RNADLCEXCLUDE] = {}; [s.nRNADLCEXCLUDE] = {};   
            [s.USERconfig] = {}; [s.nUSERconfig] = {};
            [s.plfGravityCorrectionLCs] = {}; [s.GravityCorrectionLCs] = {};
            [s.iDFOnOffStatus] = {}; [s.dDFAngle] = {};
            [s.iDFLdcaseCnt] = {}; [s.DFLdCaseList] = {};
            [s.dTwrFnLatxValue] = {};
            [s.DLCOverrideTable] = {};
                
            linetxt = VTSCoder.get(1);

            while ischar(linetxt)
            
                switch(strrep(linetxt, ' ', ''))
                    
                    case ''
                    
                    case 'PIT:'
                        [s.nPIT] = VTSCoder.get();
                        if str2double(s.nPIT)>0
                            [s.PIT_R] = strsplit(VTSCoder.get());
                            [s.PIT_alfa_0] = strsplit(VTSCoder.get());
                            [s.PIT_A] = strsplit(VTSCoder.get());
                            [s.PIT_L] = strsplit(VTSCoder.get());
                        end

                    case 'DRT:'
                        [s.nDRT] = VTSCoder.get();
                        if str2double(s.nDRT)>0
                            [s.DRT] = strsplit(VTSCoder.get(true));
                        end

                    case 'PITlockLCs:'
                        [s.nPITlockLCs] = VTSCoder.get();
                        if str2double(s.nPITlockLCs)>0
                            [s.PITlockLCs] = strsplit(VTSCoder.get(true));
                        end

                    case 'FND:'
                        [s.FND] = VTSCoder.get();

                    case 'TWR:'
                        [s.TWR{1}] = VTSCoder.get();
                        [s.TWR{2}] = VTSCoder.get();
                        [s.TWR{3}] = VTSCoder.get();
                        [s.TWR{4}] = VTSCoder.get();

                    case 'TWR_DLC:'
                        [s.nTWR_DLC] = VTSCoder.get();
                        if str2double(s.nTWR_DLC)>0
                            [s.TWR_DLC] = strsplit(VTSCoder.get(true));
                        end

                    case 'FNDx:'
                        [s.FNDx] = strsplit(VTSCoder.get(true));

                    case 'BLDDIREXT:'
                        [s.nBLDDIREXT] = VTSCoder.get();
                        if str2double(s.nBLDDIREXT)>0
                            [s.BLDDIREXT] = strsplit(VTSCoder.get(true));
                        end

                    case 'BLDDIRFAT:'
                        [s.nBLDDIRFAT] = VTSCoder.get();
                        if str2double(s.nBLDDIRFAT)>0
                            [s.BLDDIRFAT] = strsplit(VTSCoder.get(true));
                        end

                    case 'PDoT:'
                        [s.PDoT] = VTSCoder.get();

                    case 'TWRDLCEXCLUDE:'
                        [s.nTWRDLCEXCLUDE] = VTSCoder.get();
                        if str2double(s.nTWRDLCEXCLUDE)>0
                            [s.TWRDLCEXCLUDE] = strsplit(VTSCoder.get(true));
                        end

                    case 'RNADLCEXCLUDE:'
                        [s.nRNADLCEXCLUDE] = VTSCoder.get();
                        if str2double(s.nRNADLCEXCLUDE)>0
                            [s.RNADLCEXCLUDE] = strsplit(VTSCoder.get(true));
                        end

                    case 'USERconfig:'
                        [s.nUSERconfig] = VTSCoder.get();
                        s.USERconfig = cell(1,str2double(s.nUSERconfig));
                        for i=1:str2double(s.nUSERconfig)
                            [filename] = VTSCoder.get();
                            s.USERconfig{i} = filename; % TBD: Create reader object!!
                        end

                    case 'GravityCorrectionLCs:'
                        [s.plfGravityCorrectionLCs] = strsplit(VTSCoder.get(true));
                        s.plfGravityCorrectionLCs = s.plfGravityCorrectionLCs{end};

                        [s.GravityCorrectionLCs] = strsplit(VTSCoder.get(true));

                    case 'FAT:'
                        [s.iDFOnOffStatus] = VTSCoder.get();
                        [s.dDFAngle] = VTSCoder.get();

                    case 'DIRLC:'
                        [s.iDFLdcaseCnt] = VTSCoder.get();
                        if str2double(s.iDFLdcaseCnt)>0
                            [s.DFLdCaseList] = strsplit_LMT(VTSCoder.get(true));
                        end

                    case 'TWRFNDLATx:'
                        [s.dTwrFnLatxValue] = VTSCoder.get();

                    case 'DLCFAMILYMETHODOVERRIDE:'
                        VTSCoder.skip(1);
                        tmp_line = strsplit(VTSCoder.get(true));
                        j = 1;
                        while length(tmp_line) > 1
                            [s.DLCOverrideTable(j, 1)] = tmp_line(1);
                            [s.DLCOverrideTable(j, 2)] = tmp_line(2);
                            [s.DLCOverrideTable(j, 3)] = tmp_line(3);
                            [s.DLCOverrideTable(j, 4)] = tmp_line(4);
                            tmp_line = strsplit(VTSCoder.get(true));
                            j = j + 1;
                        end

                    otherwise
                        [s.comments] = VTSCoder.getRemaininglines();
                        if isempty(s.comments)
                            s.comments = '';
                        end
                end
                try
                    linetxt = VTSCoder.get(1);
                catch
                    linetxt = -1;
                end
            end
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
%             VTSCoder.initialize('part',mfilename, self.getAttributes());
            
            VTSCoder.setProperty(self.Header1);
            VTSCoder.setProperty(self.Header2);
            
            if ~isempty(self.PIT_R)
                VTSCoder.setLine('');
                VTSCoder.setLine('PIT:');
                VTSCoder.setProperty(self.nPIT);
                VTSCoder.setProperty({strjoin(self.PIT_R)},      23, 'R Radius of crank [mm]');
                VTSCoder.setProperty({strjoin(self.PIT_alfa_0)}, 23, 'pitch cylinger angle position at 0 degr. pitch [degr.]');
                VTSCoder.setProperty({strjoin(self.PIT_A)},      23, 'A Distance of cylinder bracket in x direction [mm]');
                VTSCoder.setProperty({strjoin(self.PIT_L)},      23, 'L Distance of cylinder bracket in y direction [mm]');
            end
            
            if ~isempty(self.TWR)
                VTSCoder.setLine('');
                VTSCoder.setLine('TWR:');
                VTSCoder.setProperty(self.TWR{1});
                VTSCoder.setProperty(self.TWR{2});
                VTSCoder.setProperty(self.TWR{3});
                VTSCoder.setProperty(self.TWR{4});
            end
            
            if ~isempty(self.DRT)
                VTSCoder.setLine('');
                VTSCoder.setLine('DRT:');
                VTSCoder.setProperty(self.nDRT);
                VTSCoder.setProperty(strjoin(self.DRT));
            end
            
            if ~isempty(self.PITlockLCs)
                VTSCoder.setLine('');
                VTSCoder.setLine('PITlockLCs:');
                VTSCoder.setProperty(self.nPITlockLCs);
                VTSCoder.setProperty(strjoin(self.PITlockLCs));
            end
            
            if ~isempty(self.FND)
                VTSCoder.setLine('');
                VTSCoder.setLine('FND:');
                VTSCoder.setProperty(self.FND);
            end
            
            if ~isempty(self.TWR_DLC)
                VTSCoder.setLine('');
                VTSCoder.setLine('TWR_DLC:');
                VTSCoder.setProperty(self.nTWR_DLC);
                VTSCoder.setProperty(strjoin_LMT(self.TWR_DLC));
            end
            
            if ~isempty(self.FNDx)
                VTSCoder.setLine('');
                VTSCoder.setLine('FNDx:');
                VTSCoder.setProperty(strjoin(self.FNDx));
            end
            if ~isempty(self.BLDDIREXT)

                VTSCoder.setLine('');
                VTSCoder.setLine('BLDDIREXT:');
                VTSCoder.setProperty(self.nBLDDIREXT);
                VTSCoder.setProperty(strjoin(self.BLDDIREXT));
            end
            if ~isempty(self.BLDDIRFAT)

                VTSCoder.setLine('');
                VTSCoder.setLine('BLDDIRFAT:');
                VTSCoder.setProperty(self.nBLDDIRFAT);
                VTSCoder.setProperty(strjoin(self.BLDDIRFAT));
            end            
            if ~isempty(self.PDoT)
                VTSCoder.setLine('');
                VTSCoder.setLine('PDoT:');
                VTSCoder.setProperty(self.PDoT);
            end
            
            if ~isempty(self.TWRDLCEXCLUDE)
                VTSCoder.setLine('');
                VTSCoder.setLine('TWRDLCEXCLUDE:');
                VTSCoder.setProperty(self.nTWRDLCEXCLUDE);
                VTSCoder.setProperty(strjoin(self.TWRDLCEXCLUDE));
            end
            
            if ~isempty(self.RNADLCEXCLUDE)
                VTSCoder.setLine('');
                VTSCoder.setLine('RNADLCEXCLUDE:');
                VTSCoder.setProperty(self.nRNADLCEXCLUDE);
                VTSCoder.setProperty(strjoin(self.RNADLCEXCLUDE));
            end
            
            if ~isempty(self.USERconfig)
                VTSCoder.setLine('');
                VTSCoder.setLine('USERconfig:');
                VTSCoder.setProperty(self.nUSERconfig);
                VTSCoder.setProperty(strjoin(self.USERconfig));
            end
            
            if ~isempty(self.iDFOnOffStatus)
                VTSCoder.setLine('');
                VTSCoder.setLine('FAT:');
                VTSCoder.setProperty(self.iDFOnOffStatus);
                VTSCoder.setProperty(self.dDFAngle);
            end
            
            if ~isempty(self.iDFLdcaseCnt)
                VTSCoder.setLine('');
                VTSCoder.setLine('DIRLC:');
                VTSCoder.setProperty(self.iDFLdcaseCnt);
                VTSCoder.setProperty(strjoin(self.DFLdCaseList));
            end
            
            if ~isempty(self.dTwrFnLatxValue)
                VTSCoder.setLine('');
                VTSCoder.setLine('TWRFNDLATx:');
                VTSCoder.setProperty(self.dTwrFnLatxValue);
            end

            if ~isempty(self.GravityCorrectionLCs)

                VTSCoder.setLine('');
                VTSCoder.setLine('GravityCorrectionLCs:');
                VTSCoder.setProperty(sprintf('PLF_LOWER_BOUND : %s',self.plfGravityCorrectionLCs));
                VTSCoder.setProperty(strjoin(self.GravityCorrectionLCs));
            end
            
            if ~isempty(self.DLCOverrideTable)
                
                VTSCoder.setLine('');
                VTSCoder.setLine('DLCFAMILYMETHODOVERRIDE:');
                VTSCoder.setLine('sensor		loadcase	Method	Contemp');
                for i = 1:length(self.DLCOverrideTable)
                    VTSCoder.setProperty(sprintf('%s\t%s\t%s\t%s', self.DLCOverrideTable{i, 1}, self.DLCOverrideTable{i, 2}, self.DLCOverrideTable{i, 3}, self.DLCOverrideTable{i, 4}));
                end
            end
            
            if ~isempty(self.comments)
                VTSCoder.setRemaininglines(self.comments);
			else
            end
            status = VTSCoder.save();
        end
    end
    
    methods (Access=protected)
        function [myproperties, mytables, myfiles] = getAttributes(self)
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            %myproperties = myproperties(~strcmpi(myproperties,'USERconfig')); % SensorCfg is not a property
            mytables = {};
            %myfiles = {'USERconfig'};
            myfiles = {};
        end
    end        
    
    properties
        Header1
        Header2
        nPIT
        PIT_R
        PIT_alfa_0
        PIT_A
        PIT_L
        nDRT
        DRT
        nPITlockLCs
        PITlockLCs
        FND
        TWR
        nTWR_DLC
        TWR_DLC
        FNDx
        nBLDDIREXT
        nBLDDIRFAT
        BLDDIREXT
        BLDDIRFAT
        PDoT
        nTWRDLCEXCLUDE
        TWRDLCEXCLUDE
        nRNADLCEXCLUDE
        RNADLCEXCLUDE
        nUSERconfig
        USERconfig
		iDFOnOffStatus
		dDFAngle
		iDFLdcaseCnt
		DFLdCaseList
        TowerFndLatx
		dTwrFnLatxValue
        plfGravityCorrectionLCs
        GravityCorrectionLCs
        DLCOverrideTable
        comments
    end
end
