classdef convert_Test < matlab.unittest.TestCase
    properties (Constant)
        testFolder = '\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\ForTestSuite\PartFiles\'
        tempDirLong = tempname;
        part2codec = containers.Map({'BLD','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','WND','YAW','_PL','VRB'},...
            {'BLD','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','WND','YAW','PL' ,'VRB'});
    end
    properties
        encode     = containers.Map({'BLD','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','WND','YAW','PL' ,'VRB','REFMODEL','ERR','PRO','MAS','FRQ','SET','OUT','SENSOR','STA'},...
            {true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,false,false,true,false,true,false});
        autoDectect =containers.Map({'BLD','BRK','CNV','CTR','DRT','FND','GEN','HBX','HUB','NAC','PIT','SEA','SEN','TWR','WND','YAW','PL' ,'VRB','REFMODEL','ERR','PRO','MAS','FRQ','SET','OUT','SENSOR','STA'},...
            {true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,false,true,false,false,false,false,false,false,false,false,false});
        compileError = containers.Map        
        skipFiles = {'2MW_1\Loads\PARTS\CTR\CTR_MK10D_V110_2000kW_60Hz_15.09_T2X302_HH75_0.296Hz_HWO.001'
            '2MW_1\Loads\PARTS\2MWerr.001'
            '2MW_2\Loads\PARTS\CTR\CTR_V100_2000kW-2200kW_Mk10C_50Hz_15.09_HH080_T2X203.006'
            '2MW_2\Loads\PARTS\VRB\Mk10C_2.2MW_Globaloptions_PowerMode4_2015.08.001'
            '2MW_2\Loads\PARTS\2MWerr.001'
            '3MW_4MW\Loads\PARTS\CTR\CTR_mk3e_V117_IEC2AT_4000kW_1540RPM_113.4_19.06_T755401_HH84_0.295Hz.027'
            '3MW_4MW\Loads\PARTS\VRB\Mk3E_4_00MW_Globaloptions_17.03.005'
            '3MW_4MW\Loads\PARTS\3MWerr.001'
            'Enventus\Loads\PARTS\VRB\Vidar_F3_HTq_5600kW_408rpm.004'
            'Enventus\Loads\PARTS\Vidar_err.001'
            'Localisation\Loads\PARTS\CTR\CTR_Mk11C_GW_V120_2000kW_112.8_50Hz_2019.03_HH95_0.216Hz_Std.001'
            'Localisation\Loads\PARTS\VRB\AccelerationSensors.001'
            'Localisation\Loads\PARTS\2MWerr.001'
            'Thor\Loads\PARTS\VRB\VRB_Thor_PM1.006'
            'Thor\Loads\PARTS\Thor_err.001'
            'Vidar\Loads\PARTS\VRB\Vidar_F3_HTq_5600kW_408rpm.004'
            'Vidar\Loads\PARTS\Vidar_err.001'};
        
        skipEncode = {'2MW_1\Loads\PARTS\GEN\gen_DF2000kW_60HzV05_Mk10_SlimGen.003'
            '2MW_2\Loads\PARTS\GEN\gen_DF2200kW_50HzV05_MK10.004'
            'Localisation\Loads\PARTS\GEN\v116_v120_gen_2000kw_50hz.003'
            'Enventus\Loads\PARTS\CTR\CTR_vidar_V162_5600kW_408.2RPM_43.8_TA29500_HH149_0.139Hz.044'
            'Thor\Loads\PARTS\CTR\CTR_thor_T3_LTq_3000kW_476RPM_43.75_T8A6E00_HH117_0.165Hz_MPC.005'
            'Vidar\Loads\PARTS\CTR\CTR_vidar_V162_5600kW_408.2RPM_43.8_TA27700_HH119_0.196Hz.043'
            };
    end
    
    properties (TestParameter)
        files = {'2MW_1\Loads\PARTS\BLD\Blade_V110_a18_l08_s17_2_WithPA_GF_V4_RVG_TwoWebs_MK10D.001'
            '2MW_1\Loads\PARTS\BRK\2MWbrkV05_Mbrk_13.9.001'
            '2MW_1\Loads\PARTS\CNV\cnv_DF2000kW_60HzV05_Mk10.005'
            '2MW_1\Loads\PARTS\CTR\CTR_MK10D_V110_2000kW_60Hz_15.09_T2X302_HH75_0.296Hz_HWO.001'
            '2MW_1\Loads\PARTS\DRT\V110drtV05_MK10_60Hz.003'
            '2MW_1\Loads\PARTS\FND\nofound.001'
            '2MW_1\Loads\PARTS\GEN\gen_DF2000kW_60HzV05_Mk10_SlimGen.003'
            '2MW_1\Loads\PARTS\HBX\0xtender.001'
            '2MW_1\Loads\PARTS\HUB\V110hubV05.003'
            '2MW_1\Loads\PARTS\NAC\2MWnacV05_Mk10.002'
            '2MW_1\Loads\PARTS\PIT\V110pitV05.003'
            '2MW_1\Loads\PARTS\SEA\0sea.001'
            '2MW_1\Loads\PARTS\SEN\sensor_Optimum_VSC.009'
            '2MW_1\Loads\PARTS\TWR\0090-7050_V00.txt'
            '2MW_1\Loads\PARTS\WND\200303kvjhj_Blue_Canyon_II_L04-00_73V110-2MW_Mk10D_HH67m_12Sector_EXT_WSM_LogN_comb_m=4.clm'
            '2MW_1\Loads\PARTS\YAW\2MWyawV05.004'
            '2MW_1\Loads\PARTS\_PL\PL_2MW_V110_MK10_75HH_T2X302.04'
            '2MW_1\Loads\PARTS\2MWerr.001'
            '2MW_1\Loads\PARTS\V110_AerodUpgrade2.0_GF_V4_RVG.pro'
            '2MW_1\Loads\PARTS\V110_AerodUpgrade2.0_GF_V4_RVG_standstill.pro'
            '2MW_1\Loads\Mk10D_iecs_80HH_60Hz_BlueCan.txt'
            '2MW_1\Loads\STA\1104a001.sta'
            '2MW_1\Loads\INPUTS\Mk10D_iecs_80HH_60Hz_BlueCan.mas'
            '2MW_1\Loads\INPUTS\Mk10D_iecs_80HH_60Hz_BlueCan.frq'
            '2MW_1\Loads\INPUTS\Mk10D_iecs_80HH_60Hz_BlueCan.set'
            '2MW_1\Loads\OUT\1104a001.out'
            '2MW_1\Loads\INT\sensor'
            '2MW_2\Loads\PARTS\BLD\V100bldV05T3S_hubcon3_AeroAddOns_RVG_OVG_MK10C.002'
            '2MW_2\Loads\PARTS\BRK\2MWbrkV05_Mbrk_13.9.001'
            '2MW_2\Loads\PARTS\CNV\cnv_DF2200kW_50HzV05_Mk10.005'
            '2MW_2\Loads\PARTS\CTR\CTR_V100_2000kW-2200kW_Mk10C_50Hz_15.09_HH080_T2X203.006'
            '2MW_2\Loads\PARTS\DRT\V100drtV05_MK10_50Hz.006'
            '2MW_2\Loads\PARTS\FND\nofound.001'
            '2MW_2\Loads\PARTS\GEN\gen_DF2200kW_50HzV05_MK10.004'
            '2MW_2\Loads\PARTS\HBX\0xtender.001'
            '2MW_2\Loads\PARTS\HUB\V110hubV05.003'
            '2MW_2\Loads\PARTS\NAC\2MWnacV05_Mk10.002'
            '2MW_2\Loads\PARTS\PIT\V110pitV05.003'
            '2MW_2\Loads\PARTS\SEA\0sea.001'
            '2MW_2\Loads\PARTS\SEN\sensor_Optimum.009'
            '2MW_2\Loads\PARTS\TWR\0074-7921.V04.txt'
            '2MW_2\Loads\PARTS\VRB\Mk10C_2.2MW_Globaloptions_PowerMode4_2015.08.001'
            '2MW_2\Loads\PARTS\WND\TREVERAY-SAINT-JOIRE_4_V100_2.2MW_85m_HH_External_without_LN_30Yr_191024_174529_comb_m=4_LN_FAT_ETM_Corrected.clm'
            '2MW_2\Loads\PARTS\YAW\2MWyawV05.004'
            '2MW_2\Loads\PARTS\_PL\V100_2MW_PL_RLexclude_Mk10_80HH_updated_FND_scaling.V00'
            '2MW_2\Loads\PARTS\2MWerr.001'
            '2MW_2\Loads\PARTS\profi49_Mk10-2_RVG_OVG-stand.100'
            '2MW_2\Loads\PARTS\profi49_Mk10-2_RVG_OVG.100'
            '2MW_2\Loads\V100_2200_Mk10D_HH85_IECS_update_dlc_32preog.txt'
            '2MW_2\Loads\STA\1104a001.sta'
            '2MW_2\Loads\INPUTS\V100_2200_Mk10D_HH85_IECS_update_dlc_32preog.mas'
            '2MW_2\Loads\INPUTS\V100_2200_Mk10D_HH85_IECS_update_dlc_32preog.frq'
            '2MW_2\Loads\INPUTS\V100_2200_Mk10D_HH85_IECS_update_dlc_32preog.set'
            '2MW_2\Loads\OUT\1104a001.out'
            '2MW_2\Loads\INT\sensor'
            '3MW_4MW\Loads\PARTS\BLD\Mk3E_v117_vds_aao.004'
            '3MW_4MW\Loads\PARTS\BRK\Mk3E_igear113.4.002'
            '3MW_4MW\Loads\PARTS\CNV\Mk3E_v117_4.00MW.001'
            '3MW_4MW\Loads\PARTS\CTR\CTR_mk3e_V117_IEC2AT_4000kW_1540RPM_113.4_19.06_T755401_HH84_0.295Hz.027'
            '3MW_4MW\Loads\PARTS\DRT\Mk3E_igear113.4.002'
            '3MW_4MW\Loads\PARTS\FND\nofound.001'
            '3MW_4MW\Loads\PARTS\GEN\Mk3E_v117_4.00MW.003'
            '3MW_4MW\Loads\PARTS\HBX\0xtender.001'
            '3MW_4MW\Loads\PARTS\HUB\Mk3E_v117.002'
            '3MW_4MW\Loads\PARTS\NAC\Mk3E_v117.003'
            '3MW_4MW\Loads\PARTS\PIT\Mk3E_v117.003'
            '3MW_4MW\Loads\PARTS\SEA\nosea.001'
            '3MW_4MW\Loads\PARTS\SEN\sensors_17.03.003'
            '3MW_4MW\Loads\PARTS\TWR\V117_HH084.0_T755401.006'
            '3MW_4MW\Loads\PARTS\VRB\Mk3E_4_00MW_Globaloptions_17.03.005'
            '3MW_4MW\Loads\PARTS\WND\IEC2a(S)_typhoon.001'
            '3MW_4MW\Loads\PARTS\YAW\Mk3E.003'
            '3MW_4MW\Loads\PARTS\_PL\Mk3E_iec_v117.005'
            '3MW_4MW\Loads\PARTS\3MWerr.001'
            '3MW_4MW\Loads\PARTS\V117-3.3MW_Mk3A_RVG_STE_operational.pro'
            '3MW_4MW\Loads\PARTS\V117-3.3MW_Mk3A_RVG_STE_stand_still.pro'
            '3MW_4MW\Loads\V117_4.00_IEC2AT(S)_HH84.0_VDS_AAO_T755401.txt'
            '3MW_4MW\Loads\STA\1104a001.sta'
            '3MW_4MW\Loads\INPUTS\V117_4.00_IEC2AT(S)_HH84.0_VDS_AAO_T755401.mas'
            '3MW_4MW\Loads\INPUTS\V117_4.00_IEC2AT(S)_HH84.0_VDS_AAO_T755401.frq'
            '3MW_4MW\Loads\INPUTS\V117_4.00_IEC2AT(S)_HH84.0_VDS_AAO_T755401.set'
            '3MW_4MW\Loads\OUT\1104a001.out'
            '3MW_4MW\Loads\INT\sensor'
            'Enventus\Loads\PARTS\BLD\Vidar_F3_std_ste.002'
            'Enventus\Loads\PARTS\BRK\Vidar.006'
            'Enventus\Loads\PARTS\CNV\Vidar_F3_HTq_5600kW_408rpm.005'
            'Enventus\Loads\PARTS\CTR\CTR_vidar_V162_5600kW_408.2RPM_43.8_TA29500_HH149_0.139Hz.044'
            'Enventus\Loads\PARTS\DRT\Vidar_HTq.005'
            'Enventus\Loads\PARTS\FND\Vidar.001'
            'Enventus\Loads\PARTS\GEN\Vidar_F3_HTq_5600kW_408rpm.004'
            'Enventus\Loads\PARTS\HBX\Vidar.001'
            'Enventus\Loads\PARTS\HUB\Vidar_F.005'
            'Enventus\Loads\PARTS\NAC\Vidar_HTq.003'
            'Enventus\Loads\PARTS\PIT\Vidar_F3.003'
            'Enventus\Loads\PARTS\SEA\nosea.001'
            'Enventus\Loads\PARTS\SEN\sensors_18.11.001'
            'Enventus\Loads\PARTS\TWR\0091-2639_V00.txt'
            'Enventus\Loads\PARTS\VRB\Vidar_F3_HTq_5600kW_408rpm.004'
            'Enventus\Loads\PARTS\WND\mast_shear_EXT_30y_ICE150_LN_Lantinen-Kalajoki_V00_20xV162-5.6MW_HH159m_191220_135612_comb_m=4_ETM_Corrected.clm'
            'Enventus\Loads\PARTS\YAW\Vidar_F.004'
            'Enventus\Loads\PARTS\_PL\Vidar_F_iec_HTq_pdot_updated_FND_scaling.V00'
            'Enventus\Loads\PARTS\V162_EnVentus_production_mixed_STE_V2.PRO'
            'Enventus\Loads\PARTS\V162_EnVentus_standstill_mixed_STE_V2.PRO'
            'Enventus\Loads\PARTS\Vidar_err.001'
            'Enventus\Loads\V162_5600_ENVENTUS_HH159_IECS.txt'
            'Enventus\Loads\STA\1104a001.sta'
            'Enventus\Loads\INPUTS\V162_5600_ENVENTUS_HH159_IECS.mas'
            'Enventus\Loads\INPUTS\V162_5600_ENVENTUS_HH159_IECS.frq'
            'Enventus\Loads\INPUTS\V162_5600_ENVENTUS_HH159_IECS.set'
            'Enventus\Loads\OUT\1104a001.out'
            'Enventus\Loads\INT\sensor'
            'Localisation\Loads\PARTS\BLD\V120_a47_18-2_l04_s26-1_FG18_VA36_new_prebend_update_infusion_without_ste_aao.011'
            'Localisation\Loads\PARTS\BRK\v116_v120_brk_13_90.000'
            'Localisation\Loads\PARTS\CNV\v116_v120_cnv_2000_50hz.001'
            'Localisation\Loads\PARTS\CTR\CTR_Mk11C_GW_V120_2000kW_112.8_50Hz_2019.03_HH95_0.216Hz_Std.001'
            'Localisation\Loads\PARTS\DRT\v116_v120_drt_50hz.001'
            'Localisation\Loads\PARTS\FND\nofound.001'
            'Localisation\Loads\PARTS\GEN\v116_v120_gen_2000kw_50hz.003'
            'Localisation\Loads\PARTS\HBX\0xtender.002'
            'Localisation\Loads\PARTS\HUB\v116_v120_hub_11b.002'
            'Localisation\Loads\PARTS\NAC\v116_v120_nac.001'
            'Localisation\Loads\PARTS\PIT\v116_v120_pit_fine-exc.005'
            'Localisation\Loads\PARTS\SEA\0sea.001'
            'Localisation\Loads\PARTS\SEN\v116_v120_sen.004'
            'Localisation\Loads\PARTS\TWR\0078-1196_V02.txt'
            'Localisation\Loads\PARTS\VRB\AccelerationSensors.001'
            'Localisation\Loads\PARTS\WND\iecs_NorthCoastal.001'
            'Localisation\Loads\PARTS\YAW\v116_v120_yaw.000'
            'Localisation\Loads\PARTS\_PL\v116_v120_pl_PDoT_FNDx.006'
            'Localisation\Loads\PARTS\2MWerr.001'
            'Localisation\Loads\PARTS\V120-NG01mod1_V15_production_mixed.PRO.txt'
            'Localisation\Loads\PARTS\V120-NG01mod1_V15_standstill_mixed.PRO.txt'
            'Localisation\Loads\V120_2.00_IECS_HH095_INF_STE_50HZ_draft_tower_China.txt'
            'Localisation\Loads\STA\1104a001.sta'
            'Localisation\Loads\INPUTS\V120_2.00_IECS_HH095_INF_STE_50HZ_draft_tower_China.mas'
            'Localisation\Loads\INPUTS\V120_2.00_IECS_HH095_INF_STE_50HZ_draft_tower_China.frq'
            'Localisation\Loads\INPUTS\V120_2.00_IECS_HH095_INF_STE_50HZ_draft_tower_China.set'
            'Localisation\Loads\OUT\1104a001.out'
            'Localisation\Loads\INT\sensor'
            'Thor\Loads\PARTS\BLD\T3_a53_l08b_s21.001'
            'Thor\Loads\PARTS\BRK\BRK_Thor_LTq.005'
            'Thor\Loads\PARTS\CNV\CNV_Thor_3200kW_496rpm.004'
            'Thor\Loads\PARTS\CTR\CTR_thor_T3_LTq_3000kW_476RPM_43.75_T8A6E00_HH117_0.165Hz_MPC.005'
            'Thor\Loads\PARTS\DRT\Thor_LTq.004'
            'Thor\Loads\PARTS\FND\nofound.001'
            'Thor\Loads\PARTS\GEN\GEN_Thor_3200kW_496rpm.006'
            'Thor\Loads\PARTS\HBX\0xtender.001'
            'Thor\Loads\PARTS\HUB\Thor.002'
            'Thor\Loads\PARTS\NAC\Thor_LTq.003'
            'Thor\Loads\PARTS\PIT\Thor_T3.001'
            'Thor\Loads\PARTS\SEA\nosea.001'
            'Thor\Loads\PARTS\SEN\sensors_Thor_inclMPC.001'
            'Thor\Loads\PARTS\TWR\TWR_Thor_T3_HH117_T8A6E00.001'
            'Thor\Loads\PARTS\VRB\VRB_Thor_PM1.006'
            'Thor\Loads\PARTS\WND\WND_Thor_T3_HH117_T8A7500_Vavg8.001'
            'Thor\Loads\PARTS\YAW\Thor.003'
            'Thor\Loads\PARTS\_PL\Thor_iec_LTq_pdot.005'
            'Thor\Loads\PARTS\Thor_T3_profi_file_production_mixed_RVG_V31.PRO'
            'Thor\Loads\PARTS\Thor_T3_profi_file_standstill_mixed_RVG_V31.PRO'
            'Thor\Loads\PARTS\Thor_err.001'
            'Thor\Loads\T3_LTq_3.20_IECS_HH117.0_STD_CBO_T8A6E00.txt'
            'Thor\Loads\STA\1104a001.sta'
            'Thor\Loads\INPUTS\T3_LTq_3.20_IECS_HH117.0_STD_CBO_T8A6E00.mas'
            'Thor\Loads\INPUTS\T3_LTq_3.20_IECS_HH117.0_STD_CBO_T8A6E00.frq'
            'Thor\Loads\INPUTS\T3_LTq_3.20_IECS_HH117.0_STD_CBO_T8A6E00.set'
            'Thor\Loads\OUT\1104a001.out'
            'Thor\Loads\INT\sensor'
            'Vidar\Loads\PARTS\BLD\Vidar_F3_std_ste.002'
            'Vidar\Loads\PARTS\BRK\Vidar.006'
            'Vidar\Loads\PARTS\CNV\Vidar_F3_HTq_5600kW_408rpm.005'
            'Vidar\Loads\PARTS\CTR\CTR_vidar_V162_5600kW_408.2RPM_43.8_TA27700_HH119_0.196Hz.043'
            'Vidar\Loads\PARTS\DRT\Vidar_HTq.005'
            'Vidar\Loads\PARTS\FND\Vidar.001'
            'Vidar\Loads\PARTS\GEN\Vidar_F3_HTq_5600kW_408rpm.004'
            'Vidar\Loads\PARTS\HBX\Vidar.001'
            'Vidar\Loads\PARTS\HUB\Vidar_F.005'
            'Vidar\Loads\PARTS\NAC\Vidar_HTq.003'
            'Vidar\Loads\PARTS\PIT\Vidar_F3.003'
            'Vidar\Loads\PARTS\SEA\nosea.001'
            'Vidar\Loads\PARTS\SEN\sensors_18.11.001'
            'Vidar\Loads\PARTS\TWR\HH119_TA27700.001'
            'Vidar\Loads\PARTS\VRB\Vidar_F3_HTq_5600kW_408rpm.004'
            'Vidar\Loads\PARTS\WND\TowerScope_ColumnP_F3_HH119.0_4p1_25yrs.003'
            'Vidar\Loads\PARTS\YAW\Vidar_F.004'
            'Vidar\Loads\PARTS\_PL\Vidar_F_dibt_HTq.005'
            'Vidar\Loads\PARTS\V162_EnVentus_production_mixed_STE_V2.PRO'
            'Vidar\Loads\PARTS\V162_EnVentus_standstill_mixed_STE_V2.PRO'
            'Vidar\Loads\PARTS\Vidar_err.001'
            'Vidar\Loads\V162_HTq_5.60_DIBT_HH119.0_STD_STE_TA27700.txt'
            'Vidar\Loads\STA\1104ant001.sta'
            'Vidar\Loads\INPUTS\V162_HTq_5.60_DIBT_HH119.0_STD_STE_TA27700.mas'
            'Vidar\Loads\INPUTS\V162_HTq_5.60_DIBT_HH119.0_STD_STE_TA27700.frq'
            'Vidar\Loads\INPUTS\V162_HTq_5.60_DIBT_HH119.0_STD_STE_TA27700.set'
            'Vidar\Loads\OUT\1104ant001.out'
            'Vidar\Loads\INT\sensor'}
         codecs = {'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'WND' 'YAW' 'PL' 'ERR' 'PRO' 'PRO' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'ERR' 'PRO' 'PRO' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'ERR' 'PRO' 'PRO' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'PRO' 'PRO' 'ERR' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'ERR' 'PRO' 'PRO' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'PRO' 'PRO' 'ERR' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR' 'BLD' 'BRK' 'CNV' 'CTR' 'DRT' 'FND' 'GEN' 'HBX' 'HUB' 'NAC' 'PIT' 'SEA' 'SEN' 'TWR' 'VRB' 'WND' 'YAW' 'PL' 'PRO' 'PRO' 'ERR' 'REFMODEL' 'STA' 'MAS' 'FRQ' 'SET' 'OUT' 'SENSOR'}
        
    end
    
    methods (TestClassSetup)
        function makeTestFolder(testCase)
            [~, tempDirShort] = fileparts(testCase.tempDirLong); %Temporary folder name needs to be generated locally, since it is not possible to set it under constants.
            tempDirShort = tempDirShort(end-5:end);
            mkdir(fullfile(testCase.testFolder,'encodeFolder', tempDirShort));
        end
    end
    
    methods (TestClassTeardown)
        function deleteTestOutputs(testCase)
            [~, tempDirShort] = fileparts(testCase.tempDirLong);
            tempDirShort = tempDirShort(end-5:end);
            rmdir(fullfile(testCase.testFolder,'encodeFolder',tempDirShort), 's');
        end
    end
    
    methods (Test, ParameterCombination =  'sequential')
        function testConvertWithoutError(testCase,files,codecs)
            if ~any(contains(testCase.skipFiles,files))
                dummy = LAC.vts.convert(fullfile(testCase.testFolder,files),codecs);
                if iscell(dummy)
                    testCase.compileError(files) = true;
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.vts.convert(''%s'',''%s'')'' throws the error: ''%s''',fullfile(testCase.testFolder,files),codecs,dummy{1}))
                else
                    testCase.compileError(files) = false;
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.vts.convert(''%s'',''%s'')'' throws an error.',fullfile(testCase.testFolder,files),codecs))
                end
            else
                fprintf('\n%s skipped by testConvertWithoutError due to known compile error using LAC.vts.convert\n',fullfile(testCase.testFolder,files))
            end
        end
               
        function testEncode(testCase,files,codecs)
            [~, tempDirShort] = fileparts(testCase.tempDirLong); %Temporary folder name needs to be generated locally, since it is not possible to set it under constants.
            tempDirShort = tempDirShort(end-5:end);
            if ~any(contains(testCase.skipEncode,files))
                if ~any(contains(testCase.skipFiles,files)) && ~testCase.compileError(files) && testCase.encode(codecs)
                    dummy = LAC.vts.convert(fullfile(testCase.testFolder,files),codecs);
                    [~,filename]=fileparts(tempname);
                    fullFileName = fullfile(testCase.testFolder,'encodeFolder',tempDirShort,[filename '.txt']);
                    try
                        dummy.encode(fullFileName);
                    catch
                        testCase.assertTrue(false,sprintf('Error during encode of ''%s''.',fullfile(testCase.testFolder,files)))
                    end
                    actual = testCase.getTXTdata(fullFileName);
                    seperator = strfind(files,'\');
                    expected = testCase.getTXTdata(fullfile(testCase.testFolder,'expectedEncode',files(1:seperator(1)-1),files(seperator(end-1)+1:seperator(end)-1),files(seperator(end)+1:end)));
                    testCase.verifyEqual(actual,expected,sprintf('Encoded file content ''%s'' is not as expected.',fullfile(testCase.testFolder,files)));
                end
            else
                fprintf('\n%s skipped by testEncode due to known encode error using encode() function\n',fullfile(testCase.testFolder,files))
            end
        end
        
        function testAutoDetectWithoutError(testCase,files,codecs)
            if ~any(contains(testCase.skipFiles,files)) && ~testCase.compileError(files) && testCase.autoDectect(codecs)
                dummy = LAC.vts.convert(fullfile(testCase.testFolder,files));
                if iscell(dummy)
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.vts.convert(''%s'')'' throws the error: ''%s''',fullfile(testCase.testFolder,files),dummy{1}))
                else
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.vts.convert(''%s'')'' throws an error.',fullfile(testCase.testFolder,files)))
                end
            end
        end
    end
    
    methods (Static)
        function result = RunUnitTests()
            result = run(LAC.vts.convert_Test);
            failed = result([result.Failed]);
            for iT = 1:length(failed)
                try
                    fprintf('\n%s',failed(iT).Details.DiagnosticRecord.TestDiagnosticResult{1});
                catch
                    fprintf('\nError in test %s at file %s line %i with message %s',failed(iT).Details.DiagnosticRecord.Stack(2).name,failed(iT).Details.DiagnosticRecord.Exception.stack(1).file,failed(iT).Details.DiagnosticRecord.Exception.stack(1).line,failed(iT).Details.DiagnosticRecord.Exception.message);
                end
            end
            fprintf('\n')
        end
        
        function [files,codecs] = findPartFiles()
            list = dir(LAC.vts.convert_Test.testFolder);
            prepFolders = {list([list.isdir]).name};
            prepFolders = prepFolders(cellfun(@isempty,regexp(prepFolders,'^\.\.?$')));
            files = {};
            codecs = {};
            for i = 1:length(prepFolders)
                [files,codecs] = LAC.vts.convert_Test.getFilePaths(files,codecs,fullfile(prepFolders{i},'Loads'));
            end
        end
        
        function  [files,codecs] = getFilePaths(files,codecs,simulationFolder)
            % PART files
            list = dir(fullfile(LAC.vts.convert_Test.testFolder,simulationFolder,'PARTS'));
            partFolders = {list([list.isdir]).name};
            partFolders = partFolders(cellfun(@isempty,regexp(partFolders,'^\.\.?$')));
            
            for i = 1:length(partFolders)
                folder = partFolders{i};
                files{end+1} = LAC.vts.convert_Test.getFile(fullfile(LAC.vts.convert_Test.testFolder,simulationFolder,'PARTS',folder));
                codecs{end+1} = LAC.vts.convert_Test.part2codec(folder);
            end
            
            % ERR and PROFILE
            fileDir = {list(~[list.isdir]).name};
            for i = 1:length(fileDir)
                if contains(fileDir{i},'err','IgnoreCase',true)
                    files{end+1} = fullfile(simulationFolder,'PARTS',fileDir{i});
                    codecs{end+1} = 'ERR';
                else
                    
                    files{end+1} = fullfile(simulationFolder,'PARTS',fileDir{i});
                    codecs{end+1} = 'PRO';
                end
            end
            
            % REFMODEL
            list = dir(simulationFolder);
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'REFMODEL';
            
            % STA
            list = dir(fullfile(simulationFolder,'STA','*.sta'));
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'STA';
            
            % MAS
            list = dir(fullfile(simulationFolder,'INPUTS','*.mas'));
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'MAS';
            
            % FRQ
            list = dir(fullfile(simulationFolder,'INPUTS','*.frq'));
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'FRQ';
            
            % SET
            list = dir(fullfile(simulationFolder,'INPUTS','*.set'));
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'SET';
            
            % OUT
            list = dir(fullfile(simulationFolder,'OUT','*.out'));
            files{end+1} = fullfile(simulationFolder,list(~[list.isdir]).name);
            codecs{end+1} = 'OUT';
            
            % SENSOR
            files{end+1} = fullfile(simulationFolder,'INT','sensor');
            codecs{end+1} = 'SENSOR';
        end
        
        function file = getFile(folder)
            list = ls(folder);

            file = strrep(fullfile(folder,list(3,:)),LAC.vts.convert_Test.testFolder,'');
        end
    end
    
    methods (Access = private)
        function data = getTXTdata(self,fileName)
            fid=fopen(fileName); 
            data=textscan(fid, '%s', -1, 'whitespace', '', 'delimiter', '\n');
            fclose(fid);
        end
    end
    
end