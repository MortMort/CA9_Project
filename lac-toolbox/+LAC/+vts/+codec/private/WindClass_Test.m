classdef WindClass_Test < matlab.unittest.TestCase
    methods(Test)
        function test_verify(self)
             self.assertTrue(codec.WindClass.verify('IEC1A'));
             self.assertTrue(codec.WindClass.verify('IECS'));
             self.assertTrue(codec.WindClass.verify('iec3c'));
             self.assertTrue(codec.WindClass.verify('DIBt1I'));
             self.assertTrue(codec.WindClass.verify('DIBt4IV'));
             self.assertTrue(codec.WindClass.verify('DIBT4IV'));
             self.assertTrue(codec.WindClass.verify('dibt4IV'));
             self.assertTrue(codec.WindClass.verify('dibt4iv'));
             self.assertFalse(codec.WindClass.verify('IEC5A'));
             self.assertFalse(codec.WindClass.verify('IEC1W'));
             self.assertFalse(codec.WindClass.verify('DIBt42I'));
             self.assertFalse(codec.WindClass.verify('DIBt1V'));
             self.assertFalse(codec.WindClass.verify('bogus'));
             self.assertFalse(codec.WindClass.verify(''));
        end
        
        function test_getIEC(self)
            %filename = 'R:\2MW\MK8\V100\+++REFERENCE_MODEL+++\REF_MODEL_2010-08-27\iec32a_hh95.txt';
            filename = 'test\develop\refmodels\V100_1800_GS_50_onshore_Unknown.txt';
            [readonly, message] = fopen(filename,'r','l');
            b = codec.ReferenceModel();
            s = b.decode(readonly);
            fclose(readonly);
            
            filenameWND = char(b.findPart('WND'));
            [partsfile, message] = fopen(filenameWND,'r','l');
            coder_part = codec.Part();
            s.WND = coder_part.decode(partsfile);
            fclose(partsfile);
            
            a = codec.WindClass();
            self.assertEqual(a.get(s), 'IECS');
            
            testdata = [ ...
                        {'IEC1A', '50.0', '0.16', '137'}; ...
                        {'IEC1B', '50.0', '0.14', '137'}; ...
                        {'IEC1C', '50.0', '0.12', '137'}; ...
                        {'IEC2A', '42.5', '0.16', '137'}; ...
                        {'IEC2B', '42.5', '0.14', '137'}; ...
                        {'IEC2C', '42.5', '0.12', '137'}; ...
                        {'IEC3A', '37.5', '0.16', '137'}; ...
                        {'IEC3B', '37.5', '0.14', '137'}; ...
                        {'IEC3C', '37.5', '0.12', '137'}; ...
                       ];
            
            for i=1:length(testdata)
                [classname,Vref, Turbpar, HubHeight] = testdata{i,:};
                s = self.getTestData(Vref, Turbpar, HubHeight);
                self.assertEqual(a.get(s), classname);
            end
            
            s.WindSpeeds.V50 = num2str(50.2); % User defined
            self.assertEqual(a.get(s), 'IECS');
        end
        
        function test_getDIBt(self)
            filename = 'h:\3MW\MK2A\+++REFERENCE_MODEL+++\V126\DIBt2_2012_GKII.txt';
            [readonly, message] = fopen(filename,'r','l');
            b = codec.ReferenceModel();
            s = b.decode(readonly);
            fclose(readonly);
            
            filenameWND = char(b.findPart('WND'));
            [partsfile, message] = fopen(filenameWND,'r','l');
            coder_part = codec.Part();
            s.WND = coder_part.decode(partsfile);
            fclose(partsfile);
            
            % Test data from VTS Reference model 
            a = codec.WindClass();
            self.assertEqual(a.get(s), 'DIBt2II');
            
            % Test data from calculated from w:\USER\Thtba\matlab\TLtoolbox\WpDIBt2012.m 
            % with HubHeight = 137m
            testdata = [ ...
                    {'DIBt1I',   'DIN','36.35','50.89','29.08', '40.71', '0.102', '6.54', '7.27'}; ...
                    {'DIBt2I',   'DIN','40.39','56.55','32.31', '45.23', '0.102', '8'   , '8.88'}; ...
                    {'DIBt3I',   'DIN','44.42','62.19','35.54', '49.76', '0.102', '8'   , '8.88'}; ...
                    {'DIBt4I',   'DIN','48.46','67.84','38.77', '54.28', '0.102', '8.72', '9.69'}; ...
                    
                    {'DIBt1II',  'DIN','34.2', '47.88','27.36', '38.3',  '0.125', '6.16', '6.84'}; ...
                    {'DIBt2II',  'DIN','38',   '53.2', '30.4',  '42.56', '0.125', '7.52', '8.36'}; ... 
                    {'DIBt3II',  'DIN','41.8', '58.52','33.44', '46.82', '0.125', '7.52', '8.36'}; ...
                    {'DIBt4II',  'DIN','45.6', '63.84','36.48', '51.07', '0.125', '8.21', '9.12'}; ...
                    
                    {'DIBt1III', 'DIN','30.81','43.13','24.65', '34.51', '0.157', '5.55', '6.16'}; ...
                    {'DIBt2III', 'DIN','34.24','47.94','27.39', '38.35', '0.157', '6.78', '7.53'}; ...
                    {'DIBt3III', 'DIN','37.66','52.72','30.13', '42.18', '0.157', '6.78', '7.53'}; ...
                    {'DIBt4III', 'DIN','41.09','57.53','32.87', '46.02', '0.157', '7.4',  '8.22'}; ...
                    
                    {'DIBt1IV',  'DIN','27.63','38.68','22.1',  '30.94', '0.196', '4.97', '5.53'}; ...
                    {'DIBt2IV',  'DIN','30.7', '42.98','24.56', '34.38', '0.196', '6.08', '6.75'}; ...
                    {'DIBt3IV',  'DIN','33.77','47.28','27.02', '37.83', '0.196', '6.08', '6.75'}; ...
                    {'DIBt4IV',  'DIN','36.84','51.58','29.47', '41.26', '0.196', '6.63', '7.37'}; ...
                    
                    {'DIBt1I',   'ALT','35.52','49.73','28.42', '39.79', '0.112', '6.39', '7.1'}; ... % TBD
                    {'DIBt2I',   'ALT','39.46','55.24','31.57', '44.2',  '0.112', '7.81', '8.68'}; ...
                    {'DIBt3I',   'ALT','43.41','60.77','34.73', '48.62', '0.112', '7.81', '8.68'}; ...
                    {'DIBt4I',   'ALT','47.35','66.29','37.88', '53.03', '0.112', '8.52', '9.47'}; ...
                    
                    %DIBt2__ == DIBt3__
                    %Alternative only: DIBt_I  == DIBt_II
                    ];
            
            for i=1:length(testdata)
                [classname,DIN_ALT,V50,Ve50,V1,Ve1,Turbpar,Vav,VavNSI] = testdata{i,:};
                s.WindSpeeds.V50=V50;
                s.WindSpeeds.Ve50=Ve50;
                s.WindSpeeds.V1=V1;
                s.WindSpeeds.Ve1=Ve1;
                s.WND.Turbpar='0.16';
                s.WND.Vav=Vav;
                a = codec.WindClass();
                self.assertEqual(a.get(s), classname);
                
                s.WND.Vav=VavNSI;
                self.assertEqual(a.get(s), classname);
            end
            
%             a.getCalculatedWindData().IEC
%             a.getCalculatedWindData().DIBt.DIN.II
%             a.getCalculatedWindData().DIBt.ALT.II
        end
    end
    
    methods
        function output = getTestData(~, Vref, Turbpar, Hhub)
            % Generate test data
            output.WindSpeeds.V50  = Vref;
            output.WindSpeeds.Ve50 = num2str(1.4 * str2double(Vref));
            output.WindSpeeds.V1   = num2str(0.8 * str2double(Vref));
            output.WindSpeeds.Ve1  = num2str(0.8 * 1.4 * str2double(Vref));
            output.WND.Turbpar = Turbpar;
            output.WND.Vav     = num2str(0.2 * str2double(Vref));
            output.Hhub        = Hhub;
        end
    end
end