classdef BladeFixTest < matlab.unittest.TestCase
    properties (Access=private)
        inputFiles
    end
    
    
    methods (TestClassSetup)
        function getTestParameters(testCase)
            testCase.inputFiles{1} = 'w:\ToolsDevelopment\BladeFix\tests\BladeFix_Input_Test_1.txt';
            testCase.inputFiles{2} = 'w:\ToolsDevelopment\BladeFix\tests\BladeFix_Input_Test_2.txt';
            testCase.inputFiles{3} = 'w:\ToolsDevelopment\BladeFix\tests\BladeFix_Input_Test_3.txt';
            testCase.inputFiles{4} = 'w:\ToolsDevelopment\BladeFix\tests\BladeFix_Input_Test_4.txt';
            testCase.inputFiles{5} = 'w:\ToolsDevelopment\BladeFix\tests\BladeFix_Input_Test_5.txt';
        end
        
    end
    
        methods (TestClassTeardown)
            function deleteFolders(testCase)
                rmdir('W:\ToolsDevelopment\BladeFix\tests\output', 's')
            end
        end
    
    methods (Test)
        function readBladeFixInputFileTest(testCase)
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{1});
            
            expected.BLDFileName='newBlade.002';
            expected.BLDTemplate='w:\ToolsDevelopment\BladeFix\tests\BLDtemplateTest_1.tpl.txt';
            expected.FlexExportCSV='w:\ToolsDevelopment\BladeFix\tests\flexExport.csv';
            expected.PrepFile='w:\ToolsDevelopment\BladeFix\VTS\Variant01.txt';
            expected.AeroInpFile='w:\ToolsDevelopment\BladeFix\tests\pyro.inp';
            expected.OutputFolder='w:\ToolsDevelopment\BladeFix\tests\output';
            
            expected.tags.SVN_FlexExportCSV = {' https://dkrdssvn01.vestas.net/  '};
            expected.tags.SVN_FlexExportRevision = {' 0003 '};
            expected.tags.AeroInpFile = {' w:\ToolsDevelopment\BladeFix\tests\pyro.inp '};
            expected.tags.BLDname = {'new blade hep hey'};
            
            expected.specialTags.ProfileDataSets = {...
                'DEFAULT'       'w:\ToolsDevelopment\BladeFix\production.PRO'
                'STANDSTILL'    'w:\ToolsDevelopment\BladeFix\standstill.PRO'};
            
            testCase.assertEqual(inputStruct,expected,...
                sprintf('input read from %s is from LAC.vts.BladeFix.readBladeFixInputFile not as expected',testCase.inputFiles{1}))
            
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{2});
            
            testCase.assertEqual(inputStruct,expected,...
                sprintf('input read from %s is from LAC.vts.BladeFix.readBladeFixInputFile not as expected',testCase.inputFiles{2}))
            
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{5});
            
            expected.DefaultProfile = 'w:\ToolsDevelopment\BladeFix\production.PRO';
            testCase.assertEqual(inputStruct,expected,...
                sprintf('input read from %s is from LAC.vts.BladeFix.readBladeFixInputFile not as expected',testCase.inputFiles{5}))
            
            expected = rmfield(expected,'DefaultProfile');
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{3});
            
            expected.PreviousBlade = 'w:\ToolsDevelopment\BladeFix\tests\oldBlade.001';
            expected.HotTwistWindSpeed = '9.5';
            expected.RotorDiameter = '123';
            expected.BLDTemplate='w:\ToolsDevelopment\BladeFix\tests\BLDtemplateTest_2.tpl.txt';
            expected.tags.AeroOutFile={' w:\ToolsDevelopment\BladeFix\pyro.out '};
            
            expected.specialTags.NoiseEquations ={...
                'LwA_Thor_T0_noSTE'    'w:\ToolsDevelopment\BladeFix\noise_nao.csv'
                'LwA_Thor_T0_noSTE'    'w:\ToolsDevelopment\BladeFix\noise_nao.csv'};
            expected.specialTags.CommentsFromPreviousBlade ={...
                'w:\ToolsDevelopment\BladeFix\tests\oldBlade.001'};
            
            testCase.assertEqual(inputStruct,expected,...
                sprintf('input read from %s is from LAC.vts.BladeFix.readBladeFixInputFile not as expected',testCase.inputFiles{3}))
        end
        
        function checkInputsTest(testCase)
            inputStruct1 = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{1});
            inputStruct2 = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{2});
            inputStruct3 = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{3});
            try
                LAC.vts.BladeFix(inputStruct1);
                LAC.vts.BladeFix(inputStruct2);
                LAC.vts.BladeFix(inputStruct3);
            catch
                testCase.assertEqual(true,false,'checkInputs probably failed where it should not.')
            end
            inputStruct4 = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{4});
            testCase.assertError(@() LAC.vts.BladeFix(inputStruct4),'checkInputs:AssertError','checkInputs probably failed where it should not.')
        end
        
        function insertTagsInTemplateTest(testCase)
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{3});
            actual = LAC.vts.BladeFix.insertTagsInTemplate(inputStruct.BLDTemplate,inputStruct);
            expected = testCase.getExpectedTpl(3);
            
            testCase.assertEqual(actual,expected,...
                'insertTagsInTemplate did not create the expected tpl file')
            
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{1});
            actual = LAC.vts.BladeFix.insertTagsInTemplate(inputStruct.BLDTemplate,inputStruct);
            expected = testCase.getExpectedTpl(1);
            
            testCase.assertEqual(actual,expected,...
                'insertTagsInTemplate did not create the expected tpl file')
            
        end
        
        function ConvertPyroInputTest(testCase)
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(testCase.inputFiles{1});
            actual = LAC.vts.BladeFix.ConvertPyroInput(inputStruct.AeroInpFile);
            expected= testCase.getExpectedhotTwist(1);
            
            testCase.assertEqual(actual,expected,...
                'ConvertPyroInputTest did not capture the correct hot twist information from the .inp file')
        end
        
    end
    
    methods (Access = private)
        function [ expected ] = getExpectedhotTwist(~,inputFileNumber)
            %GETEXPECTEDHOTTWIST Summary of this function goes here
            %   Detailed explanation goes here
            
            switch inputFileNumber
                case 1
                    matrix = [2.500	5.100	12.295	100.000
                        3.013	5.100	13.126	100.000
                        5.067	5.100	15.651	100.000
                        7.120	5.100	17.085	100.000
                        9.173	5.100	17.473	95.457
                        12.253	5.100	16.287	82.793
                        14.307	5.100	15.047	75.957
                        16.360	5.100	13.638	69.986
                        18.413	5.100	12.053	64.614
                        20.467	5.100	10.272	59.723
                        22.520	5.100	8.487	55.813
                        24.573	5.100	7.085	52.629
                        26.627	5.100	6.015	49.877
                        28.680	5.100	5.205	47.416
                        30.733	5.090	4.606	45.169
                        32.787	5.052	4.193	43.059
                        34.840	4.990	3.881	41.257
                        36.893	4.906	3.589	39.811
                        38.947	4.803	3.313	38.592
                        41.000	4.685	3.053	37.527
                        43.053	4.555	2.811	36.570
                        45.107	4.417	2.589	35.691
                        47.160	4.273	2.390	34.872
                        49.213	4.126	2.202	34.108
                        51.267	3.981	2.021	33.401
                        53.320	3.841	1.844	32.740
                        55.373	3.707	1.672	32.109
                        57.427	3.581	1.501	31.500
                        59.480	3.460	1.334	30.894
                        61.533	3.346	1.167	30.286
                        63.587	3.237	1.003	29.682
                        65.640	3.132	0.840	29.080
                        67.693	3.031	0.676	28.480
                        69.747	2.934	0.513	27.884
                        71.800	2.839	0.350	27.303
                        73.853	2.746	0.187	26.742
                        75.907	2.655	0.025	26.207
                        77.960	2.565	-0.137	25.698
                        80.013	2.479	-0.297	25.212
                        82.067	2.399	-0.442	24.740
                        84.120	2.323	-0.574	24.289
                        86.173	2.257	-0.699	23.850
                        88.227	2.204	-0.816	23.402
                        90.280	2.153	-0.930	22.942
                        92.333	2.103	-1.039	22.470
                        94.387	2.054	-1.146	21.985
                        96.440	2.005	-1.251	21.482
                        98.493	1.955	-1.353	20.980
                        100.547	1.899	-1.455	20.511
                        102.600	1.840	-1.557	20.106
                        104.653	1.774	-1.660	19.763
                        106.707	1.697	-1.765	19.453
                        108.760	1.603	-1.870	19.172
                        110.813	1.481	-1.976	18.918
                        112.867	1.315	-2.090	18.688
                        113.893	1.207	-2.147	18.575
                        114.920	1.072	-2.204	18.460
                        115.947	0.898	-2.015	18.343
                        116.973	0.652	-1.825	18.232
                        117.487	0.467	-0.601	18.180
                        117.692	0.363	-0.112	18.161
                        118.000	0.016	0.622	18.130];
                    
                    expected.parameters = strsplit_LMT('Radius Chord Twist Thickness');
                    expected.matrix = matrix;
            end
        end
        
        function expected = getExpectedTpl(~,inputFileNumber)
            
            switch inputFileNumber
                case 1
                    expected = {...
                        'new blade hep hey'
                        '1	0.11	0.05	40	10	4									dCLda dCLdaS AlfS Alfrund Taufak'
                        '2                                                               Number of profile data sets'
                        'DEFAULT w:\ToolsDevelopment\BladeFix\production.PRO'
                        'STANDSTILL w:\ToolsDevelopment\BladeFix\standstill.PRO'
                        '0.011 0.015 0.004 0.005 0.003 0.002 0.001 2.000					LogD for blade DOF 1-8 (Blade mode 1-6, blade damper, Quasistatic torsion)'
                        '3.00 -5.80 6.00 0.10  0.01										NoBlade; Gamma; Tilt; Rtipcut Delta3(0 for a non-teeter system) '
                        '0.200 0.300														GammaRootFlap GammaRootEdge '
                        '-2.00 1.00 2.00 3.00 4.00 5.00 6.00								Rbd Mbd11 Mbd12 Mbd22 Kbd Ybdmax Khi/Klo '
                        '-1.00															Structural pitch '
                        '0.100	0.200	-0.300											PiOff1 PiOff2 PiOff3 '
                        '0.400	0.500	0.600											AzOff1 AzOff2 AzOff3 '
                        '1.700	1.800	1.900											KFfac1 KFfac2 KFfac3 '
                        '1.100	1.110	1.120											KEfac1 KEfac2 KEfac3 '
                        '1.130	1.140	1.150											KTFac1 KTFac2 KTfac3 '
                        '1.160	1.170	1.180											mfac1 mfac2 mfac3 '
                        '1.190	1.200	1.210											Jfac1 Jfac2 Jfac3 '
                        '1.220	1.230	1.240											dfac1 dfac2 dfac3 '
                        '0																nCrossSections '
                        '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
                        'R			EI_2			EI_1			GIp			m			J			Xcog			Xshc			UF0			UE0			C			t_C			beta			p_ang			Yac_C			PhiOut			Out			'
                        '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
                        '2 3.00e+04 0.0010 4.40 8000.0									Retype; MFric0 [Nm];mu;DL [m] '
                        'SVN reference:  https://dkrdssvn01.vestas.net/  '
                        'SVN rev.:  0003 '
                        ''
                        'Aero-file Reference (.inp):  w:\ToolsDevelopment\BladeFix\tests\pyro.inp '};
                case 3
                    
                    expected = {...
                        'new blade hep hey'
                        '1	0.11	0.05	40	10	4									dCLda dCLdaS AlfS Alfrund Taufak'
                        '2                                                               Number of profile data sets'
                        'DEFAULT w:\ToolsDevelopment\BladeFix\production.PRO'
                        'STANDSTILL w:\ToolsDevelopment\BladeFix\standstill.PRO'
                        '0.011 0.015 0.004 0.005 0.003 0.002 0.001 2.000					LogD for blade DOF 1-8 (Blade mode 1-6, blade damper, Quasistatic torsion)'
                        '3.00 -5.80 6.00 0.10  0.01										NoBlade; Gamma; Tilt; Rtipcut Delta3(0 for a non-teeter system) '
                        '0.200 0.300														GammaRootFlap GammaRootEdge '
                        '-2.00 1.00 2.00 3.00 4.00 5.00 6.00								Rbd Mbd11 Mbd12 Mbd22 Kbd Ybdmax Khi/Klo '
                        '-1.00															Structural pitch '
                        '0.100	0.200	-0.300											PiOff1 PiOff2 PiOff3 '
                        '0.400	0.500	0.600											AzOff1 AzOff2 AzOff3 '
                        '1.700	1.800	1.900											KFfac1 KFfac2 KFfac3 '
                        '1.100	1.110	1.120											KEfac1 KEfac2 KEfac3 '
                        '1.130	1.140	1.150											KTFac1 KTFac2 KTfac3 '
                        '1.160	1.170	1.180											mfac1 mfac2 mfac3 '
                        '1.190	1.200	1.210											Jfac1 Jfac2 Jfac3 '
                        '1.220	1.230	1.240											dfac1 dfac2 dfac3 '
                        '0																nCrossSections '
                        '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
                        'R			EI_2			EI_1			GIp			m			J			Xcog			Xshc			UF0			UE0			C			t_C			beta			p_ang			Yac_C			PhiOut			Out			'
                        '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
                        '2 3.00e+04 0.0010 4.40 8000.0									Retype; MFric0 [Nm];mu;DL [m] '
                        '  2                                                            Number of noise equations'
                        'LwA_Thor_T0_noSTE'
                        '  NoiseEquationVersion  1'
                        '  1                                                                             Number of radii (one per line)'
                        '  87.00   0.07   0.24   0.01                                                    Radius[%] A1 A2 AoASwitch[deg]'
                        '  49.78  11.43  90.00 155.00 155.00  51.13   8.88  90.00 155.00 155.00          B1 Cmodified1 Cconst1 D1 Dref1 B2 Cmodified2 Cconst2 D2 Dref2'
                        'LwA_Thor_T0_noSTE'
                        '  NoiseEquationVersion  1'
                        '  1                                                                             Number of radii (one per line)'
                        '  87.00   0.07   0.24   0.01                                                    Radius[%] A1 A2 AoASwitch[deg]'
                        '  49.78  11.43  90.00 155.00 155.00  51.13   8.88  90.00 155.00 155.00          B1 Cmodified1 Cconst1 D1 Dref1 B2 Cmodified2 Cconst2 D2 Dref2'
                        ''
                        'SVN reference:  https://dkrdssvn01.vestas.net/  '
                        'SVN rev.:  0003 '
                        ''
                        'Aero-file Reference (.inp):  w:\ToolsDevelopment\BladeFix\tests\pyro.inp '
                        ''
                        '12-Mar-2020 Created from h:\3MW\Mk3E_Extreme_Climate\USER\KOTNI\Repos\lfs_040_blue_marlin_v2_LFS_1962\BladeFiles\V236_a34_s4.csv and h:\3MW\Mk3E_Extreme_Climate\USER\KOTNI\Repos\lfs_040_blue_marlin_v2_LFS_1919\PARTS\BLD\BM_V236_a27x_I00_s1.001'
                        ''
                        '20200312-14:11 - Torsional stiffness increased by 20% and shear center corrected using "h:\3MW\Mk3E_Extreme_Climate\USER\KOTNI\Repos\lfs_040_blue_marlin_v2_LFS_1962\BladeFiles\BLD_file_generation\+LAC\+vts\apply_BLD_correction".'
                        'Changed by kotni, original file: h:\3MW\Mk3E_Extreme_Climate\USER\KOTNI\Repos\lfs_040_blue_marlin_v2_LFS_1919\PARTS\BLD\BM_V236_a34_s4.001'};
            end
            
            
        end
    end
end
    
    
