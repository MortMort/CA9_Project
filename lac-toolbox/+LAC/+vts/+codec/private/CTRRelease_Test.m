classdef CTRRelease_Test <  matlab.unittest.TestCase
    methods(Test)
        function test_verify(self)
             self.assertTrue(codec.CTRRelease.verify('2014.08','20141030'));
             self.assertTrue(codec.CTRRelease.verify('UNKNOWN','UNKNOWN'));
             self.assertTrue(codec.CTRRelease.verify('UNKNOWN',''));
             self.assertTrue(codec.CTRRelease.verify('',''));
             self.assertTrue(codec.CTRRelease.verify('9999.12','99991231'));
             self.assertFalse(codec.CTRRelease.verify('19999.12','20141030'));
             self.assertFalse(codec.CTRRelease.verify('2014.99','20141030'));
             self.assertFalse(codec.CTRRelease.verify('2014.08','20141432'));
             self.assertFalse(codec.CTRRelease.verify('','bogus'));
             self.assertFalse(codec.CTRRelease.verify('bogus',''));
        end
        
        function test_get(self)
            data =  containers.Map();
            data('ControlRelease')     = '2014.08';
            data('ControlReleaseDate') = '20141030';
            [CTRrelease, CTRdate] = codec.CTRRelease.get(data);
            
            self.assertEqual(CTRrelease, data('ControlRelease'));
            self.assertEqual(CTRdate, data('ControlReleaseDate'));
        end
    end
end