classdef Properties_Test <  matlab.unittest.TestCase
    methods(Test)
        function test_verify(self)
            % create from struct
            mdlproperties = containers.Map;
            mdlproperties('Rotor') = '110';
            mdlproperties('ConverterSystem') = 'VCS';
            mdlproperties('HubHeight') = '125';
            mdlproperties('GridFreq') = '50';
            mdlproperties('GenSpeed') = '1680';
            mdlproperties('NominalPower') = '2000';
            mdlproperties('GearRatio') = '112.8';
            mdlproperties('Flex5Filename') = '\\dkrkbfile01\flex\SOURCE\vts002v05_V110Beta_Mk10.exe';
            mdlproperties('TowerCode') = [];
            mdlproperties('ControlRelease') = '2013.05';
            mdlproperties('ControlReleaseDate') = '20130703';
            mdlproperties('WindClass') = 'IEC3A';
            mdlproperties('MkType') = 'Mk10';
            obj1 = codec.Properties(mdlproperties);
            self.assertTrue(obj1.verify());
            self.assertEqual(obj1.getRefModelFilename(), 'V110_2000_VCS_50_1680_IEC3A_112.8_125_Mk10.txt');
            
            % create from decoded
            s = codec.ReferenceModel();
            [FID, message] = fopen('H:\2MW\MK10\V110\+++REFERENCE_MODEL+++\iec3a_125HH-EU_50Hz.txt','rt');
            obj2 = codec.Properties(s.decode(FID));
            fclose(FID);
            self.assertTrue(obj2.verify());
            self.assertEqual(obj2.getRefModelFilename(), 'V110_2000_VCS_50_1680_IEC3A_112.8_125_Mk10.txt');
            
            % compare the two objects, above
            self.assertTrue(obj1.compare(obj2.get()));
        end
    end
end