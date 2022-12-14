classdef TurbulenceFiles_Test <  matlab.unittest.TestCase & handle
    methods(Test)
        function test_get(self)
            obj = codec.TurbulenceFiles();
            tmp = obj.get('w:\wind\100_600_39.Mann\');
            
            tmp.files{1}
            tmp.mdhhash{1}
        end
    end
end