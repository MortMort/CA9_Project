function Result_Loads = extractsimulationdata(turbinepaths)
% Result_Loads = LAC.vts.extractsimulationdata(turbinepaths) Extract all relevant information 
% regarding a VTS simulation. Both input, output and postprocessing.
%
% Syntax:  Result_Loads = extractsimulationdata(turbinepaths)
%
% Inputs:
%   turbinepaths       - cell array with full path string to root of simulations , e.g.
%                        {'h:\3MW\MK2A\V1053300.072\IEC1a.013\LOADS\'}
%
% Outputs:
%   Result_Loads                                    Struct with all the results.
%   Result_Loads.RAWDATA                            raw data extracted from the loads folder.
%   Result_Loads.RAWDATA.postloadfiles(iTurbine)    data from the postloads folder
%   Result_Loads.RAWDATA.inputfiles(iTurbine)       important vts input files
%   Result_Loads.RAWDATA.controller(iTurbine)       important control parameter settings
%   Result_Loads.RAWDATA.loads(iTurbine)            important intpostd loads
%   Result_Loads.RAWDATA.properties(iTurbine)       important turbine properties
%   Result_Loads.TWR{iTurbine}                      tower loads/properties to be used e.g. for tower scaling
%   Result_Loads.MAIN                               loads in FLE format.
%   Result_Loads.OTC                                OTC information from the controller input.
%   Result_Loads.OTC.PartLoadLambdaOpt              equivalent to the controller parameter Px_SC_PartLoadLambdaOpt
%   Result_Loads.OTC.PartLoadLambda                 equivalent to the controller parameter Px_OTC_TableLambdaToPitchOptX
%   Result_Loads.OTC.PartLoadPi                     equivalent to the controller parameter Px_OTC_TableLambdaToPitchOptY
%   
% Author: MAARD, Martin Brødsgaard

%% Read turbines
for iPath = 1:length(turbinepaths)
    fprintf('(%d/%d) reading from: %s\n',iPath,length(turbinepaths),turbinepaths{iPath});
    turbine{iPath,1}  = LAC.vts.stapost(turbinepaths{iPath});
    turbine{iPath,1}.read();
end

%% Get Load Data
for iCase = 1:1
    for iTurbine = 1:length(turbinepaths)
        
        fprintf('(%d/%d) Get load data for: %s\n',iTurbine,length(turbinepaths),turbinepaths{iTurbine});
        % READ SIMULATION DATA
        paths{iTurbine,iCase} = turbine{iTurbine,iCase}.simdat.simulationpath;
        prep = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS',turbine{iTurbine,iCase}.simdat.prepfile),'REFMODEL');
        mas  = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS',turbine{iTurbine,iCase}.simdat.masfile));
        [~,bldfile,ext]   = fileparts(prep.Files('BLD'));
        bld               = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'PARTS','BLD',[bldfile,ext]));
        [~,wndfile,ext]   = fileparts(prep.Files('WND'));
        wnd               = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'PARTS','WND',[wndfile,ext]));
        [~,hubfile,ext]   = fileparts(prep.Files('HUB'));
        hub               = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'PARTS','HUB',[hubfile,ext]));
        mainload          = LAC.intpostd.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'Postloads','MAIN','MainLoad.txt'),'MAIN_v01');
        drtload           = LAC.intpostd.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'Postloads','DRT','DRTload.txt'),'DRT');
        twrload           = LAC.intpostd.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'Postloads','TWR','TWRload.txt'),'TWR');
    %         bldload           = LAC.intpostd.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'Postloads','BLD','BLDload.txt'),'BLD');
        frq               = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS',turbine{iTurbine,iCase}.simdat.frqfile));
        pitchCtrlFn       = LAC.dir(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS','PitchCtrl*.csv'));
        pitchCtrl         = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS',pitchCtrlFn{1}));
        prodCtrlFn        = LAC.dir(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS','ProdCtrl_*.csv'));
        prodCtrl          = LAC.vts.convert(fullfile(turbine{iTurbine,iCase}.simdat.simulationpath,'INPUTS',prodCtrlFn{1}));

        % Write struct for export
        Result_Loads.RAWDATA.postloadfiles(iTurbine) = struct('mainload',mainload,'drtload',drtload,'twrload',twrload);
        Result_Loads.RAWDATA.inputfiles(iTurbine)    = struct('prep',prep,'bld',bld,'wnd',wnd,'hub',hub,'frq',frq,'pitchCtrl',pitchCtrl,'prodCtrl',prodCtrl);

        % EXTRACT CLIMATE
        Vavg(iTurbine,iCase)      = wnd.Vav;
        k(iTurbine,iCase)         = wnd.k;
        Iref(iTurbine,iCase)      = wnd.TurbPar;
        density(iTurbine,iCase)   = wnd.Rhofat;
        Slope(iTurbine,iCase)     = wnd.TerrainSlope;
        Shear(iTurbine,iCase)     = wnd.WindShearExponent;

        % EXTRACT TURBINE PROPERTIES
        hubheight(iTurbine,iCase)    = prep.Hhub;
        %    hubheight(iTurbine,iCase) = max(mas.twr.ElHeight);
        smom(iTurbine,iCase)         = bld.computeMass.Smom;
        bldmass(iTurbine,iCase)      = bld.computeMass.Mass;
        D(iTurbine,iCase)            = round(max(bld.SectionTable.R)*2);
        hubmass(iTurbine,iCase)      = hub.Mhub;
        mbpos(iTurbine,iCase)        = hub.ZRMB;
        gearRatio(iTurbine,iCase)    = mas.drv.Ngear;
        maxchord(iTurbine,iCase)     = max(bld.SectionTable.C);

        % EXTRACT CONTROL SETTINGS

        [param,value] = pitchCtrl.getParameter('Px_TYC_SwitchToRLC');
        if isempty(value)
            isRLC(iTurbine,iCase) = false;
        else
            isRLC(iTurbine,iCase) = logical(value);
        end
        [param,PartLoadLambdaOpt(iTurbine,iCase)] = prodCtrl.getParameter('Px_SC_PartLoadLambdaOpt');
        [param,PartLoadLambda(iTurbine,:)] = prodCtrl.getParameter('Px_OTC_TableLambdaToPitchOptX');
        [param,PartLoadPi(iTurbine,:)] = prodCtrl.getParameter('Px_OTC_TableLambdaToPitchOptY');

        Result_Loads.RAWDATA.controller(iTurbine) = struct('TYC_SwitchToRLC',isRLC(iTurbine,iCase),'SC_PartLoadLambdaOpt',PartLoadLambdaOpt(iTurbine,iCase),'OTC_TableLambdaToPitchOptX',PartLoadLambda(iTurbine,:),'OTC_TableLambdaToPitchOptY',PartLoadPi(iTurbine,:));

        % EXTRACT INTPOSTD LOADS
        % -- Blade Loads --
        temp = fields(mainload.ch51_ExtremeFlapwiseMoment);
        intpost_Bld_Mx_Max(iTurbine,iCase) = mainload.ch51_ExtremeFlapwiseMoment.(temp{1}).Value;
        intpost_BldMid_Mx_Max(iTurbine,iCase) = mainload.ch51_ExtremeFlapwiseMoment.(temp{5}).Value;
        temp = fields(mainload.ch52_ExtremeEdgewiseMoment);
        Bld_My_Max     = mainload.ch52_ExtremeEdgewiseMoment.(temp{1}).Value;
        Bld_My_Min     = mainload.ch52_ExtremeEdgewiseMoment.(temp{9}).Value;
        BldMid_My_Max  = mainload.ch52_ExtremeEdgewiseMoment.(temp{5}).Value;
        BldMid_My_Min  = mainload.ch52_ExtremeEdgewiseMoment.(temp{13}).Value;
        intpost_Bld_My_Max(iTurbine,iCase) = max(abs([Bld_My_Max,Bld_My_Min]));
        intpost_BldMid_My_Max(iTurbine,iCase) = max(abs([BldMid_My_Max,BldMid_My_Min]));
        temp = fields(mainload.ch53_EquivalentFlapwiseMoment);
        intpost_Bld_Mx_Rfc_10p00(iTurbine,iCase) = mainload.ch53_EquivalentFlapwiseMoment.(temp{1}).Value;
        intpost_BldMid_Mx_Rfc_10p00(iTurbine,iCase) = mainload.ch53_EquivalentFlapwiseMoment.(temp{5}).Value;
        temp = fields(mainload.ch54_EquivalentEdgewiseMoment);
        intpost_Bld_My_Rfc_10p00(iTurbine,iCase) = mainload.ch54_EquivalentEdgewiseMoment.(temp{1}).Value;
        intpost_BldMid_My_Rfc_10p00(iTurbine,iCase) = mainload.ch54_EquivalentEdgewiseMoment.(temp{5}).Value;
        intpost_CRF(iTurbine,iCase) = mainload.ch101_ExtremeBladeDeflectioninFrontofTower.CRF_Min.Value;

        % -- Hub Loads --
        temp = fields(mainload.ch62_EquivalentHubLoads);    
        aux=zeros(length(temp),2);
        for iHubLoads=1:length(temp)
            aux(iHubLoads,1)=strcmp('Mx11h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is from 1st blade
            if aux(iHubLoads,1)==0
                aux(iHubLoads,1)=strcmp('Mx21h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is 2nd blade
                if aux(iHubLoads,1)==0
                    aux(iHubLoads,1)=strcmp('Mx31h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is 3rd blade
                end
            end

            aux(iHubLoads,2)=strcmp('My11h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is from 1st blade
            if aux(iHubLoads,2)==0
                aux(iHubLoads,2)=strcmp('My21h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is 2nd blade
                if aux(iHubLoads,2)==0
                    aux(iHubLoads,2)=strcmp('My31h_Rfc_8p00',temp{iHubLoads});  %Check if sensor is 3rd blade
                end
            end    
        end   

        if sum(aux(:,1))==0 %Sensor Mx*h_Rfc_8p00 not present
            intpost_Mx01h_Rfc_8p00(iTurbine,iCase) = nan;
        else
            intpost_Mx01h_Rfc_8p00(iTurbine,iCase) = mainload.ch62_EquivalentHubLoads.(temp{find(aux(:,1)==1)}).Value;
        end

        if sum(aux(:,2))==0 %Sensor 'My*h_Rfc_8p00 not present
            intpost_My01h_Rfc_8p00(iTurbine,iCase) = nan;
        else
            intpost_My01h_Rfc_8p00(iTurbine,iCase) = mainload.ch62_EquivalentHubLoads.(temp{find(aux(:,2)==1)}).Value;
        end


        temp = fields(mainload.ch63_ExtremeBladeBearingLoads);
        intpost_Mr_Bld_Abs(iTurbine,iCase) = mainload.ch63_ExtremeBladeBearingLoads.(temp{1}).Value;
        temp = fields(mainload.ch64_EquivalentBladeBearingLoad);
        intpost_Mr_B2_lrd_3p00(iTurbine,iCase) = mainload.ch64_EquivalentBladeBearingLoad.(temp{1}).Value;      % (1E7 pitch degrees)
        if length(temp)>1
            intpost_Mr_B2_lrd_3p33(iTurbine,iCase) = mainload.ch64_EquivalentBladeBearingLoad.(temp{2}).Value;  % (1E7 pitch degrees)
        else
            intpost_Mr_B2_lrd_3p33(iTurbine,iCase) = nan;
        end
        % -- Main bearing loads --
        intpost_MxMBf_Rfc_4p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MxMBf_Rfc_4p00.Value;
        intpost_MxMBf_Rfc_8p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MxMBf_Rfc_8p00.Value;
        intpost_MxMBr_Rfc_4p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MxMBr_Rfc_4p00.Value;
        intpost_MxMBr_Rfc_8p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MxMBr_Rfc_8p00.Value;
        intpost_MyMBr_Rfc_8p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MyMBr_Rfc_8p00.Value; %(Added DANAS)
        intpost_MzMBf_Rfc_4p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MzMBf_Rfc_4p00.Value;
        intpost_MzMBf_Rfc_8p00(iTurbine,iCase)  = mainload.ch73_EquivalentLoadsMainBearing.MzMBf_Rfc_8p00.Value;
        intpost_MxMBf_Abs(iTurbine,iCase)       = abs(mainload.ch71_ExtremeLoadsMainBearing.MxMBf_Abs.Value);
        intpost_MzMBf_Abs(iTurbine,iCase)       = abs(mainload.ch71_ExtremeLoadsMainBearing.MzMBf_Abs.Value);
        intpost_MxMBf_lrd_3p33(iTurbine,iCase)      = drtload.Equivalent_Load_Revolutions.MxMBf.m3; %REVeq=1E6
        intpost_MzMBf_lrd_3p33(iTurbine,iCase)      = drtload.Equivalent_Load_Revolutions.MzMBf.m3; %REVeq=1E6
        intpost_MyMBr_Lrd_3p33(iTurbine,iCase)      = drtload.Equivalent_Load_Revolutions.MyMBr.m3; %REVeq=1E6
        intpost_FzMBf_Lrd_3p33(iTurbine,iCase)      = drtload.Equivalent_Load_Revolutions.FzMBf.m3; %REVeq=1E6
        intpost_FyMBr_Lrd_3p33(iTurbine,iCase)      = drtload.Equivalent_Load_Revolutions.FyMBr.m3; %REVeq=1E6  %(Added DANAS)

        % -- Yaw Loads --
        intpost_Mxtt_Abs(iTurbine,iCase) = abs(mainload.ch81_ExtremeLoadsAtNacelleTowerInterface.Mxtt_Abs.Value);
        intpost_Mztt_Abs(iTurbine,iCase) = abs(mainload.ch81_ExtremeLoadsAtNacelleTowerInterface.Mztt_Abs.Value);

        % -- Tower Loads --
        intpost_Mxt0_Abs(iTurbine,iCase) = twrload.ExtremeTowerMomentInclPLF.Value(end);
        intpost_Mxt0_Rfc_4p00(iTurbine,iCase) = twrload.EquivalentTowerMoment(end).Value;

        % Scale Tower Loads
        Mx_Ext_height  =    [];
        Mx_Ext_value   =    [];
        Mx_Fat_height  =    [];
        Mx_Fat_value   =    [];
        for i = 1:length(twrload.ExtremeTowerMomentInclPLF)
                intpost_Mxt_height(i) = twrload.ExtremeTowerMomentInclPLF.Height(i);
                intpost_Mxt_Abs(i)  = twrload.ExtremeTowerMomentInclPLF.Value(i);
        end
        for i = 1:length(twrload.EquivalentTowerMoment)
    %             Mx_Fat_height(i) = twrload.EquivalentTowerMoment(i).Height;
                intpost_Mxt_Rfc_4p00(i)  = twrload.EquivalentTowerMoment(i).Value;
        end
        Result_Loads.RAWDATA.loads(iTurbine) = struct('intpost_Mxt_height',intpost_Mxt_height,'intpost_Mxt_Abs',intpost_Mxt_Abs,'intpost_Mxt_Rfc_4p00',intpost_Mxt_Rfc_4p00);

        % EXTRACT STAPOST LOADS
        revs(iTurbine,iCase)      = sum(turbine{iTurbine,iCase}.stadat.hour.*turbine{iTurbine,iCase}.stadat.mean(turbine{iTurbine,iCase}.findSensor('Omega'),:))*60;
        % Get mean values
        power(iTurbine,iCase,:)  = turbine{iTurbine,iCase}.getLoad('P','mean',turbine{iTurbine,iCase}.setLCbins('NTM'));
        MyMBr(iTurbine,iCase)  = turbine{iTurbine,iCase}.getLoad('MyMBr','mean',{'1116'});
        omega(iTurbine,iCase)  = turbine{iTurbine,iCase}.getLoad('Omega','mean',{'1116'});

        % FORMAT LOADS FOR MAT-OUTPUT

        Result_Loads.TWR{iTurbine}.ExtremeTowerMomentInclPFL.Height      = Mx_Ext_height';
        Result_Loads.TWR{iTurbine}.EquivalentTowerMoment.Height          = Mx_Fat_height';
        
        Result_Loads.RAWDATA.properties(iTurbine)  = struct('hubheight',hubheight(iTurbine,iCase),'bldmass',bldmass(iTurbine,iCase),'bldsmom',smom(iTurbine,iCase),'rotordiameter',D(iTurbine,iCase),...
                                        'hubmass',hubmass(iTurbine,iCase),'MBpos',mbpos(iTurbine,iCase),'ngear',gearRatio(iTurbine,iCase),'maxchord',maxchord(iTurbine,iCase),'ratedpower',round(power(iTurbine,iCase,7)/50)*50,'ratedspeed',omega(iTurbine,iCase));

        
        turbinename{iTurbine,iCase} = sprintf('V%3.0f-%2.2fMW-HH%03.0f',D(iTurbine,iCase),round(power(iTurbine,iCase,7)/50)/20,hubheight(iTurbine,iCase));
    end
end
idx=1;

TurbineInfo = [double(isRLC(:,idx)), PartLoadLambdaOpt(:,idx), D(:,idx), round(power(:,idx,7)/50)*50, omega(:,idx), round(MyMBr(:,idx)/10)*10,  gearRatio(:,idx), LAC.rpm2ts(omega(:,idx),D(:,idx)), hubheight(:,idx), mbpos(:,idx), hubmass(:,idx), bldmass(:,idx), smom(:,idx), Vavg(:,idx), k(:,idx), Iref(:,idx), density(:,idx), Slope(:,idx), Shear(:,idx)];
LoadSet = [intpost_Bld_Mx_Max(:,idx), intpost_BldMid_Mx_Max(:,idx), intpost_Bld_My_Max(:,idx), intpost_BldMid_My_Max(:,idx), intpost_Bld_Mx_Rfc_10p00(:,idx), intpost_BldMid_Mx_Rfc_10p00(:,idx), intpost_Bld_My_Rfc_10p00(:,idx), intpost_BldMid_My_Rfc_10p00(:,idx), intpost_Mr_Bld_Abs(:,idx), intpost_Mr_B2_lrd_3p00(:,idx), intpost_Mr_B2_lrd_3p33(:,idx),intpost_Mx01h_Rfc_8p00(:,idx),intpost_My01h_Rfc_8p00(:,idx), intpost_MxMBf_Abs(:,idx), intpost_MxMBf_Rfc_4p00(:,idx), intpost_MxMBf_Rfc_8p00(:,idx), intpost_MxMBr_Rfc_4p00(:,idx), intpost_MxMBr_Rfc_8p00(:,idx), intpost_MxMBf_lrd_3p33(:,idx), intpost_MzMBf_Abs(:,idx), intpost_MzMBf_Rfc_4p00(:,idx), intpost_MzMBf_Rfc_8p00(:,idx), intpost_MzMBf_lrd_3p33(:,idx), intpost_FzMBf_Lrd_3p33(:,idx),intpost_FyMBr_Lrd_3p33(:,idx),intpost_MyMBr_Rfc_8p00(:,idx), intpost_MyMBr_Lrd_3p33(:,idx), revs(:,idx), intpost_Mztt_Abs(:,idx), intpost_Mxtt_Abs(:,idx), intpost_Mxt0_Abs(:,idx), intpost_Mxt0_Rfc_4p00(:,idx), intpost_CRF(:,idx)];

S1 = {'NAME', 'Path', 'RLC', 'Lambda', 'D', 'Power rating', 'Rotor spd', 'GenMom', 'Gear Ratio', 'Tip Speed', 'Hub Height', 'MB pos', 'Hub mass', 'Blade mass', 'Blade Smom', 'Average wind speed', 'k-facor', 'Turbulence intensity (Iref)', 'Air Density', 'Terrain slope', 'Wind shear exponent'};
S2 = {'Bld_Flap_Extreme_root', 'Bld_Flap_Extreme_mid', 'Bld_Edge_Extreme_root', 'Bld_Edge_Extreme_mid', 'Bld_Flap_Fat_m=10_root', 'Bld_Flap_Fat_m=10_mid', 'Bld_Edge_Fat_m=10_root', 'Bld_Edge_Fat_m=10_mid', 'Bld_Bearing_Extreme', 'Bld_Bearing_LRD_m=3.00_Neq_1E7', 'Bld_Bearing_LRD_m=3.33_Neq_1E7','HubFlap_Fat_m=8','HubEdge_Fat_m=8', 'Tilt_MxMBf_Extreme', 'Tilt_MxMBf_Fat_m=4', 'Tilt_MxMBf_Fat_m=8', 'Tilt_MxMBr_Fat_m=4', 'Tilt_MxMBr_Fat_m=8', 'Tilt_MxMBf_LRD_m=3.33_Neq_1E6', 'Yaw_MzMBf_Extreme', 'Yaw_MzMBf_Fat_m=4', 'Yaw_MzMBf_Fat_m=8', 'Yaw_MzMBf_LRD_m=3.33_Neq_1E6', 'VertForce_FzMBf_LRD_m=3.33_Neq_1E6', 'Thrust_FyMBr_LRD_m=3.33_Neq_1E6', 'DrivingMom_MyMBr_Fat_m=8', 'DrivingMom_MyMBr_LRD_m=3.33_Neq_1E6', 'Revolutions', 'Mztt_Extreme', 'Mxtt_Extreme', 'Mxt0_Extreme', 'Mxt0_Fat_m=4_Neq_1E7', 'CRF'};
S3 = {'UNIT', '-', '-', '-', 'm', 'kW', 'rpm', 'kNm', '-', 'm/s', 'm', 'm', 'kg', 'kg', 'kgm', 'm/s', '-', '-', 'kg/m³', 'deg', '-','kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm','kNm','kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kNm', 'kN', 'kNm','kN','-', 'kNm', 'kNm', 'kNm', 'kNm', '-'};

R1 = turbinename(:,1);
R2 = paths(:,1);
R3 = num2cell(TurbineInfo);
R4 = num2cell(LoadSet);

C1 = [S1,S2];
C2 = S3;
C3 = [R1,R2,R3,R4];

Result_Loads.MAIN = [C1',C2',C3'];

Result_Loads.OTC.PartLoadLambdaOpt = PartLoadLambdaOpt;
Result_Loads.OTC.PartLoadLambda =PartLoadLambda;
Result_Loads.OTC.PartLoadPi = PartLoadPi;