classdef MAS  < LAC.vts.codec.Part_Common
    properties (Dependent)
        hubheight_calculated
        hubheight_specified
        towerheight
    end
    properties (Dependent, Access=private)
        is_data_available_
    end
    properties
        data
        do_data_checks
        hubheight_error_threshold
    end
    methods %Constructor.
        function self = Inputs_mas(varargin)
            %Constructor using a matlab buildin parser. The purpose is to
            %make the constructor flexible, i.e. easy to override
            %parameters or use default parameter values. E.g. override
            %"do_data_checks" by initiating the object as this:
            %   Obj = LAC.codec.vts.Inputs_mas('do_data_checks',true)%
            parser = inputParser;
            parser.KeepUnmatched = true;
            
            %Set default values.
            parser.addParamValue('do_data_checks',false);
            parser.addParamValue('hubheight_error_threshold',0.5);
            
            %Parse.
            parser.parse(varargin{:});
            
            %Set values.
            self = ParserToObject(self,parser);
        end
    end
    methods (Static)
        function s = decode(Coder)            
            file_data = Coder.readFile;
            cline=file_data{1};
            
            %Turbine
            turb        = struct;
            iline       = Coder.findline(cline,'GENERAL PARAMETERS');
            curline     = strread(cline{iline+1},'%s');
            turb.WindTurbineType = curline{1};
            turb        = Coder.readline(cline,iline+2,turb,{'HubHeight','PiAvg'});
            turb        = Coder.readline(cline,iline+13,turb,{'Stall','dCLda','dCLdaS','Als','Alrund','TauFak'});
            
            %Simulation data
            curline     = strread(cline{iline-2},'%s');
            simdat.MasVersion=curline{1};
            
            %Profile data
            if strcmp(simdat.MasVersion,'V05')
                iline       = Coder.findline(cline,'DEFAULT');
                curline     = strread(cline{iline},'%s');
                profile.Default = fullfile(fileparts(Coder.getSource),curline{2});
                curline     = strread(cline{iline+1},'%s');
                profile.Standstill = fullfile(fileparts(Coder.getSource),curline{2});
            elseif strcmp(simdat.MasVersion,'V03')
                iline       = Coder.findline(cline,'HUB:');
                curline     = strread(cline{iline+1},'%s');
                profile.Default = fullfile(fileparts(fileparts(file_data{1}{3})),'PARTS',curline{1});
%                error('Masterfile is version V03, LAC.codec.vts.Inputs_mas() not compatible with this version')
            end
            pro = struct;
            if exist(profile.Default,'file')
                pro.default=profile.Default;
%                 pro.standstill=profile.Standstill;
            else
                warning(['Profile data file ''',profile.Default,''' not found'])
                pro = struct;
            end
            

            
            %Rotor
            rot         = struct;
            rot         = Coder.readline(cline,iline+3,rot,{'NumBlades','Gamma','Tilt','Rtipcut','Delta3'});
            rot         = Coder.readline(cline,iline+4,rot,{'GammaRootFlap', 'GammaRootEdge'});
            rot         = Coder.readline(cline,iline+6,rot,'StructuralPitch');
            dum         = Coder.readline(cline,iline+7,struct,{'num1','num2','num3'});
            pit.Offset  = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+9,struct,{'num1','num2','num3'});
            rot.KFfac   = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+10,struct,{'num1','num2','num3'});
            rot.KEfac   = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+11,struct,{'num1','num2','num3'});
            rot.KTfac   = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+12,struct,{'num1','num2','num3'});
            rot.mfac   = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+13,struct,{'num1','num2','num3'});
            rot.JFfac   = [dum.num1 dum.num2 dum.num3];
            dum         = Coder.readline(cline,iline+14,struct,{'num1','num2','num3'});
            rot.dfac    = [dum.num1 dum.num2 dum.num3];
            
            %Blade
            if strcmp(simdat.MasVersion,'V05')
                dum         = Coder.readline(cline,iline+11,struct,{'num1','num2','num3'});
                rot.KTfac   = [dum.num1 dum.num2 dum.num3];
                dum         = Coder.readline(cline,iline+12,struct,{'num1','num2','num3'});
                rot.mfac   = [dum.num1 dum.num2 dum.num3];
                dum         = Coder.readline(cline,iline+13,struct,{'num1','num2','num3'});
                rot.JFfac   = [dum.num1 dum.num2 dum.num3];
                dum         = Coder.readline(cline,iline+14,struct,{'num1','num2','num3'});
                rot.dfac    = [dum.num1 dum.num2 dum.num3];
                bld         = Coder.readtable(cline,iline+15,struct,{'Radius','EIflap','EIedge','GIp','m','J','ycog','yshc', ...
                    'uf0','ue0','Chord','Thickness','Beta','YaCC','PhiOut','POut'});
            elseif strcmp(simdat.MasVersion,'V03')
                dum         = Coder.readline(cline,iline+11,struct,{'num1','num2','num3'});
                rot.mfac   = [dum.num1 dum.num2 dum.num3];
                dum         = Coder.readline(cline,iline+12,struct,{'num1','num2','num3'});
                rot.JFfac   = [dum.num1 dum.num2 dum.num3];
                bld         = Coder.readtable(cline,iline+13,struct,{'Radius','EIflap','EIedge','m', ...
                    'uf0','ue0','Chord','Beta','Thickness','YaCC','PhiOut','POut'});
            end
            
            drv         = struct;
            drv         = Coder.readline(cline,iline+16+length(bld.Radius)+1,drv,'Friction');
            rot         = Coder.readline(cline,iline+16+length(bld.Radius)+2,rot,{'HubMass','Ycogh','Yhtc','Yhn','YhMB'});
            
            %Drive train
            iline       = Coder.findline(cline,'DRT:');
            drv         = Coder.readline(cline,iline+3,drv,{'Jgen','Ngear'});
            drv         = Coder.readline(cline,iline-5,drv,'Friction');
            %rot         = Coder.readline(cline,iline-4,rot,{'HubMass','Ycogh','Yhtc','Yhn','YhMB'});
            %drv         = Coder.readline(cline,iline+1,drv,{'DampRot','DampYaw','DampTilt','DampTors'});
            drv         = Coder.readline(cline,iline+2,drv,{'kshtors','Kshy','Kshz'});
            
            %Generator
            if strcmp(simdat.MasVersion,'V05')
                search1='G1 Electrical efficiency';
                search2='G1 Mechanical efficiency';              
                
            elseif strcmp(simdat.MasVersion,'V03')
                search1='Electrical efficiency';
                search2='Mechanical efficiency';                
            end
            gen         = struct;
            iline       = Coder.findline(cline,'GEN:');
            gen         = Coder.readline(cline,iline+1,gen,{'PolePairs','NetFrequency','ConstLoss'});
            turb        = Coder.readline(cline,iline+3,turb,{'RatedPower','RatedSpeed'});
            iline       = Coder.findline(cline,search1);
            gen         = Coder.readtable2(cline,iline+1,gen,{'G1ElEfficiency','RpmBinEl','PelBinEl'});
            iline       = Coder.findline(cline,search2);
            gen         = Coder.readtable2(cline,iline+1,gen,{'G1MechEfficiency','RpmBinMech','PelBinMech'});
            if strcmp(simdat.MasVersion,'V05')
                iline       = Coder.findline(cline,'AUXLOSSTABLE');
                gen         = Coder.readtable2(cline,iline+1,gen,{'AuxLoss','RpmBinAux','PelBinAux'});
            end
            
            %Converter
             cnv         = struct;
            if strcmp(simdat.MasVersion,'V05')
                if Coder.findline(cline,'GAPC Data')>0
                    iline       = Coder.findline(cline,'CNV:');
                    cnv         = Coder.readline(cline,iline+2,cnv,{'GAPC_format_version'});
                    if cnv.GAPC_format_version == 1
                        % GAPC format version 1
                        cnv         = Coder.readline(cline,iline+7,cnv,{'fBW_PL_REF_LPF'});
                        cnv         = Coder.readline(cline,iline+8,cnv,{'AP_CTRL_fBW_PL_LPF'});
                        cnv         = Coder.readline(cline,iline+9,cnv,{'SFC_fBW_PEM_LPFPx'});
                        cnv         = Coder.readline(cline,iline+10,cnv,{'GAPC_KP','GAPC_WZERO'});
                        cnv         = Coder.readline(cline,iline+12,cnv,{'DTD_format_verfion'});
                    end
                    if cnv.DTD_format_verfion == 2
                        % DTD format version 2
                        cnv         = Coder.readline(cline,iline+13,cnv,{'fBW_OMEGAEM_LPF_DTDPx','fBW_OMEGAEM_HPF_DTDPx'});
                        cnv         = Coder.readline(cline,iline+14,cnv,{'fL_NOMPx','GDT_DTDPx','fDT_DTDPx'});
                        cnv         = Coder.readline(cline,iline+15,cnv,{'ETA_BW_DTDPx','ETA_fDT_DTDPx','ETA_fBW_DTDPx'});
                        cnv         = Coder.readline(cline,iline+16,cnv,{'LIM_PL_REF_DTD','PLIM_PL_REF','NLIM_PL_REF'});
                        cnv         = Coder.readline(cline,iline+17,cnv,{'PL_MinLimit_Low_DTD','PL_MinLimit_High_DTD'});
                        cnv         = Coder.readline(cline,iline+19,cnv,{'USE_LPF_HPF_DTD','K_LPF_HPF_DTD','fBW_MOD_DTD_LPF','fBW_MOD_DTD_HPF'});
                        cnv         = Coder.readline(cline,iline+20,cnv,{'USE_2ndOrderFilt_DTD','K_2ndOrdFilt_DTD','a1_2ndOrdFilt_DTD','a2_2ndOrdFilt_DTD'});
                        cnv         = Coder.readline(cline,iline+21,cnv,{'b0_2ndOrdFilt_DTD','b1_2ndOrdFilt_DTD','b2_2ndOrdFilt_DTD'});
                    end
                    cnv         = Coder.readline(cline,iline+24,cnv,{'GenVoltage','RatedPower','RatedSpeed'});
                else
                    iline       = Coder.findline(cline,'CNV:');
                    cnv.GAPC_format_version = -1; %Not GAPC
                    cnv.DTD_format_verfion = -1; %Not DTD, but Umpdamp
                    cnv         = Coder.readline(cline,iline+3,cnv,{'GenVoltage','RatedPower','RatedSpeed'});
                    cnv         = Coder.readline(cline,iline+1,cnv,{'T_PM','Ti','kP'});
                    cnv         = Coder.readline(cline,iline+2,cnv,{'T_est','Tdamp','kdamp','dlim'});
                    cnv         = Coder.readline(cline,iline+4,cnv,{'RpmHigh','dum','RpmLow'});
                end
            elseif strcmp(simdat.MasVersion,'V03')
                iline       = Coder.findline(cline,'CON:');
                cnv         = Coder.readline(cline,iline+3,cnv,{'GenVoltage','RatedPower'});
                cnv         = Coder.readline(cline,iline+1,cnv,{'T_PM','Ti','kP'});
                cnv         = Coder.readline(cline,iline+2,cnv,{'T_est','Tdamp','kdamp','dlim'});
            end

            
            %Nacelle
            nac         = struct;
            iline       = Coder.findline(cline,'NAC:');
            
            % Handle of mas files generated with VTS version >= VTS002v05_206
            if contains(strrep(lower(cline{iline+1}),' ',''),'formatversion2')
                nac         = Coder.readline(cline,iline+8,nac,{'NacelleMass','X_cog','Z_TowerTop_K','Xtac'});
                % Note that the format Jnx as first intrence is kept for
                % legacy. The real format is JnY(roll) JnX(tilt)
                % JnZ(yaw)[K-sys], thus Jnx = JnY(roll)
                nac         = Coder.readline(cline,iline+9,nac,{'Jnx','Jntilt','Jnyaw'});
            else
                nac         = Coder.readline(cline,iline+6,nac,{'NacelleMass','X_cog','Z_TowerTop_K','Xtac'});
                nac         = Coder.readline(cline,iline+7,nac,{'Jnx','Jntilt','Jnyaw'});
            end            
            
            %Tower
            twr         = struct;
            iline       = Coder.findline(cline,'TWR:');
            if strcmp(simdat.MasVersion,'V05')
                twr         = Coder.readline(cline,iline+1,twr,{'LogDL1','LogDL2','LogDL3','LogDL4'});            
                twr         = Coder.readline(cline,iline+2,twr,{'LogDX1','LogDX2','LogDX3','LogDX4'});
                twr         = Coder.readline(cline,iline+3,twr,{'LogDDmprX','LogDDmprY'});
            elseif strcmp(simdat.MasVersion,'V03')
                twr         = Coder.readline(cline,iline+1,twr,{'LogDL1','LogDL2','LogDX1','LogDX2','LogDDmprX','LogDDmprY'});
                iline       = iline-2;
            end
            twr         = Coder.readline(cline,iline+4,twr,{'TowerHeight'});
            twr         = Coder.readline(cline,iline+6,twr,{'Emodule','Density'});
            cline       = [cline(1:iline+7);{' '};cline(iline+8:end)];
            twr         = Coder.readtable(cline,iline+7,twr,{'ElHeight','ElDiameter','ElThickness','ElMass','ElCd','ElOut'});
            
            %Pitch
            iline       = Coder.findline(cline,'PIT:');
            pit         = Coder.readline(cline,iline+1,pit,{'order','timeconst','ksiDamping','delay'});       
            if strcmp(simdat.MasVersion, 'V03')
                lnadd = 0;
            else
                lnadd = 1;
            end
            pit         = Coder.readtable2(cline,iline+5+lnadd,pit,{'PitchRate','UctrlBin','PitchMomentBin'});
            dum         = Coder.readline(cline,iline+5+lnadd,struct,'NumRow');
            pit         = Coder.readtable2(cline,iline+7+lnadd+dum.NumRow,pit,{'PitchRateEMC','PitchAngleBin','PitchMomentEMCBin'});
            dum2        = Coder.readline(cline,iline+7+lnadd+dum.NumRow,struct,'NumRow');
            tmp         = Coder.readline(cline,iline+9+lnadd+dum.NumRow+dum2.NumRow,struct,'a1');
            tmp         = Coder.readline(cline,iline+10+lnadd+dum.NumRow+dum2.NumRow,tmp,'a2');
            tmp         = Coder.readline(cline,iline+11+lnadd+dum.NumRow+dum2.NumRow,tmp,'a3');
            tmp         = Coder.readline(cline,iline+12+lnadd+dum.NumRow+dum2.NumRow,tmp,'a4');
            tmp         = Coder.readline(cline,iline+13+lnadd+dum.NumRow+dum2.NumRow,tmp,'a5');
            pit.geom    = [tmp.a1 tmp.a2 tmp.a3 tmp.a4 tmp.a5];
                        
            %Controller
            ctr=struct();
            iline       = Coder.findline(cline,'CTR:');
            ctr         = Coder.readline(cline,iline+2,ctr,{'LSS','LSSstop'});
            ctr         = Coder.readline(cline,iline+3,ctr,{'HSS','HSSstop'});
            ctr         = Coder.readline(cline,iline+4,ctr,{'VOG'});
            
            % Read noise equations
            lwa{1} = struct;         
            supportedNoiseTags = {'NoiseEquationVersion','LwA'};
            idx_offset = {-2, -1};
            
            for noiseTag = 1:length(supportedNoiseTags)
                iline(1) = Coder.findline(cline,supportedNoiseTags{noiseTag}); % Coder.findline checks that tag must be first on line
                if iline(1) ~= -1% if a tag was found, then break loop
                    break
                end
            end
            
            if iline(1) ~= -1 % if a tag has been found
                curline  = strread(cline{iline(1)+idx_offset{noiseTag}},'%s');
                lwa_cnt = str2num( curline{1} );
                if( lwa_cnt>1 )
                    for k = 1:lwa_cnt-1
                        % Check if LwA exists from current line until end of file, otherwise break loop
                        if Coder.findline(cline(iline(k)+1:end),supportedNoiseTags{noiseTag}) < 0
                            break;
                        end
                    iline(k+1) = iline(k) + Coder.findline(cline(iline(k)+1:end),supportedNoiseTags{noiseTag});
                    end
                end

                % check that found number of noise equations matches the stated
                if length(iline) ~= lwa_cnt % nbr of found eqns do not match stated number. (stated > found)
                    warning('Number of found noise equations (%d), does not match the stated number of noise equations (%d). The output will contain only the found equations!',length(iline),lwa_cnt)
                    lwa_cnt = length(iline);
                elseif Coder.findline(cline(iline(end)+1:end),supportedNoiseTags{noiseTag}) > 0 % (stated < found)
                    warning('There is found more noise equations than the stated number of noise equations (%d). The output will contain the first (%d) found equations!',lwa_cnt,lwa_cnt)
                end
                
                switch supportedNoiseTags{noiseTag}
                    case 'LwA'
                        for idx=1:1:lwa_cnt
                            name = strread(cline{iline(idx)},'%s');
                            lwa{ idx }.name  = name{1};
                            lwa{ idx }.legacy = 'NoiseEquationVersion_0';
                            lwa{ idx } = sparseLwaEqu( lwa{ idx }, iline(idx), 0 );
                        end
                        
                    case 'NoiseEquationVersion'
                        for idx=1:1:lwa_cnt
                            curline     = strread(cline{iline(idx)},'%s');
                            name = strread(cline{iline(idx)-1},'%s');
                            lwa{ idx }.name   = name{1};
                            lwa{ idx }.legacy = [curline{1},'_',curline{2}];
                            lwa{ idx } = sparseLwaEqu( lwa{ idx }, iline(idx), str2num(curline{2}) );
                        end
                end     
            else % no supported noise tag was found
                warning backtrace off
                warning('No noise equations found in %s.',Coder.getSource);
                warning backtrace on
            end
              
            function obj = sparseLwaEqu( obj, base, version )
                
                switch version
                    case 0
                        obj      = Coder.readline(cline,base+1,obj,{'NumRadii'});
                        obj      = Coder.readline(cline,base+2,obj,{'Radius_pct','A'});
                        obj      = Coder.readline(cline,base+3,obj,{'B','Cmodified','Cconst','D','Dref'});
                    case 1
                        obj      = Coder.readline(cline,base+1,obj,{'NumRadii'});
                        obj      = Coder.readline(cline,base+2,obj,{'Radius_pct','A1','A2','AoASwitch_deg'});
                        obj      = Coder.readline(cline,base+3,obj,{'B1','Cmodified1','Cconst1','D1','Dref1','B2','Cmodified2','Cconst2','D2','Dref2'});
                    otherwise
                        warning('Noise type not supported.')
                end
                
            end
           
            s = eval(mfilename('class'));            
            s.turb = turb;
            s.pro  = pro;
            s.rot  = rot;
            s.bld  = bld;
            s.drv  = drv;
            s.gen  = gen;
            s.cnv  = cnv;
            s.nac  = nac;
            s.twr  = twr;
            s.pit  = pit;
            s.ctr  = ctr;
            s.lwa  = lwa;  % LWA may constain multiple struct entries with diffirent architecture. Hence need cell entries
            s.simdat = simdat;

        end
      
        
        function encode(self, FID, s)

        end
        
        function perform_data_checks(self)
            %Call the individual data checks.
            self.check_specified_hub_height_vs_calculated_hub_height;
        end
    end
    properties
        turb = struct;
        pro = struct;
        rot = struct;
        bld = struct;
        drv = struct;
        gen = struct;
        cnv = struct;
        nac = struct;
        twr = struct;
        pit = struct;
        ctr = struct;
        lwa = {struct};
        simdat = struct;
    end
    
    
    
    
    
    
    methods %Get.
        function out = get.is_data_available_(self)
            %Set flag.
            out = ~isempty(self.data);
        end
        function out = get.hubheight_specified(self)
            %Initiate output.
            out = [];
            
            if self.is_data_available_
                out = self.data.turb.HubHeight;
            end
        end
        function out = get.hubheight_calculated(self)
            %Initiate output.
            out = [];
            
            %Calculate hub height.
            if self.is_data_available_
                %Use calculated/derived tower height instead of
                %"data.twr.ElHeight(1)" since we will then calculate the
                %same as the "specified hub height" and this is not the
                %purpose. We want to be able to validate the specified hub
                %height.
                tower_height = self.towerheight;
                
                %Set other parameters needed for the calculation.
                z_towertop_k = self.data.nac.Z_TowerTop_K;
                tilt_angle = self.data.rot.Tilt;
                overhang_tilted = self.data.nac.X_cog + self.data.nac.Xtac;
                z_tilt= sind(tilt_angle)*overhang_tilted;

                %Calculate hub height.
                out = tower_height + z_towertop_k + z_tilt;
            end
        end
        function out = get.towerheight(self)
            %Calculate the tower height as the difference between the
            %maximum tower station (tower top) and MINIMUM POSITIVE station
            %(POSITIVE to not use negative station since these are inserted
            %to provide rotational stiffness - and "MINIMUM" to use e.g. 8m
            %in case of 8 being the lowest station). This will then
            %indicate that hub height is wrong.
            
            %Initiate output.
            out = [];
            
            if self.is_data_available_
                %Minimum positiv station.
                min_pos_station = min(abs(self.data.twr.ElHeight));
                max_pos_station = self.data.twr.ElHeight(1);
                
                %Calculate tower height.
                tower_height = max_pos_station - min_pos_station;
                
                %Set output.
                out = tower_height;
            end
        end
    end
    methods %Perform checks
        function check_specified_hub_height_vs_calculated_hub_height(self)
            if self.is_data_available_
                %Actual difference between tower and hub height.
                z_towertop_k = self.data.nac.Z_TowerTop_K;
                
                %Difference according to tower height and specified hub height.
                z_towertop_k_estimated = self.hubheight_calculated - self.towerheight;
                
                %If the difference is larger then 0.1m then it is an
                %indication that the specified hub height has not been set
                %to the correct value.
                threshold = self.hubheight_error_threshold;
                is_specified_hubheight_calculated_wrong = abs(z_towertop_k_estimated-z_towertop_k) > threshold;
                
                %Warning.
                if is_specified_hubheight_calculated_wrong
                    message = ['The specified hub height ' sprintf('%.2f', self.hubheight_specified) ' does not match the calculated hub height ' sprintf('%.2f',self.hubheight_calculated) '.'];
                    message = [message ' You should check the original tower file and update the specified hub height so that it is correct. Be aware that negative tower stations can disturb the hub height check above. E.g. a negative station (in the original tower data) of -2 could become +8 if a wrong hub heigth is specified which is +10 wrong. So, instead of using the correct +10 for the hub height check, +8 will be used, and this is not correct and disturbs the check.'];
                    warning(message);
                end
            end
        end
    end
    
    methods (Access=private)
        
        function iline = findline(~,cline,SearchString)
            
            iline = 1;
            LineString = blanks(100);
            while ~strcmpi(LineString(1:length(SearchString)),SearchString) && iline
                LineString = blanks(100);
                LineString(1:length(cline{iline})) = cline{iline};
                iline = iline + 1;
                if iline > length(cline)
                    iline = 1;
                end
            end
            iline = iline - 1;
        end
        
        
        function para_out = readline(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out = para_in;
            curline = cline{iline};
            parastring = strread(curline,'%s');
            for ipara = 1:length(FieldName)
                para_out.(FieldName{ipara}) = str2double(parastring{ipara});
            end
        end
        
        function para_out = readtable(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out        = para_in;
            curline         = cline{iline};
            NumRowString    = strread(curline,'%s');
            NumRow          = str2double(NumRowString{1});
            
            for ipara = 1:length(FieldName)
                para_out.(FieldName{ipara}) = zeros(NumRow,1);
            end
            
            for irow = 1:NumRow
                curline     = cline{iline+1+irow};
                parastring = strread(curline,'%s');
                for ipara = 1:length(FieldName)
                    para_out.(FieldName{ipara})(irow) = str2double(parastring{ipara});
                end
            end
        end
        
        function para_out = readtable2(~,cline,iline,para_in,FieldName)
            
            if ~iscell(FieldName), FieldName = {FieldName}; end
            para_out        = para_in;
            curline         = cline{iline};
            NumString       = strread(curline,'%s');
            NumRow          = str2double(NumString{1});
            NumCol          = str2double(NumString{2});
            
            HeadLine        = strread(cline{iline+1},'%s');
            
            para_out.(FieldName{1}) = zeros(NumRow,NumCol);
            para_out.(FieldName{2}) = zeros(NumRow,1);
            para_out.(FieldName{3}) = str2double(HeadLine(1:NumCol));
            
            for irow = 1:NumRow
                curline     = cline{iline+1+irow};
                linestring = strread(curline,'%s');
                para_out.(FieldName{2})(irow) = str2double(linestring{1});
                para_out.(FieldName{1})(irow,:) = str2double(linestring(2:NumCol+1));
            end
        end
        
        function output = getIncludedFile(~, files, name)
            for i = 1: length(files)
                if strcmpi(files{i}.Type, name)
                    output = files{i};
                    break
                end
            end
        end
    end
end
