classdef Part_Test < matlab.unittest.TestCase
    methods (Test)
        
        function test_DecodeEncode(self)
            filename = 'R:\2MW\Parts\Parts.V05\GEN\gen_DF1800kW_50HzV05.005';
            [readonly, message] = fopen(filename,'r','l');
            b = codec.Part(filename);
            s = b.decode(readonly);
            s
            s.Fnet
            
            % no codec exist
            filename = 'R:\2MW\Parts\Parts.V05\PIT\LMV100pitV05.006';
            [readonly, message] = fopen(filename,'r','l');
            b = codec.Part(filename);
            s = b.decode(readonly);
            
        end
     
    end
end