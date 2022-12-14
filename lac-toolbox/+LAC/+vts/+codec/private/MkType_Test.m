classdef MkType_Test <  matlab.unittest.TestCase
    methods(Test)
        function test_verify(self)
             self.assertTrue(codec.MkType.verify('Mk2a'));
             self.assertTrue(codec.MkType.verify('Mk9999a'));
             self.assertTrue(codec.MkType.verify('Mk7.5'));
             self.assertTrue(codec.MkType.verify('Mk0'));
             self.assertTrue(codec.MkType.verify('mk10'));
             self.assertTrue(codec.MkType.verify('MK10'));
             self.assertFalse(codec.MkType.verify('Mk2q'));
             self.assertFalse(codec.MkType.verify('Mkqa'));
             self.assertFalse(codec.MkType.verify('bogus'));
             self.assertFalse(codec.MkType.verify(''));
        end
        
        function test_getMk0289(self)
            % \\dkaartswrel01\Release\V112_V80V90V100Mk8_2013.07.x\V112_V80V90V100Mk8_2013.07.30\Configurations\
            configurations = {{'100','2000','50','Onshore', 'Mk9', '104.4'} ...
                              {'100','2000','60','Onshore', 'Mk9', '104.4'} ...
                              {'112','3000','50','Onshore', 'Mk0', '113.3'} ...
                              {'112','3000','60','Onshore', 'Mk0', '113.3'} ... % 113.25
                              {'112','3000','50','Offshore','Mk0', '105.2'} ... % 105.22
                              {'112','3300','50','Onshore', 'Mk2a',''} ...
                              {'117','3300','50','Onshore', 'Mk2a',''} ...
                              {'126','3300','50','Onshore', 'Mk2a',''} ...
                              { '90','1800','50','Onshore', 'Mk8', '104.4'} ...
                              { '90','1800','60','Onshore', 'Mk8', '104.4'} ...
                              { '90','2000','50','Onshore', 'Mk8', '104.4'} ...
                              { '90','2000','60','Onshore', 'Mk8', '104.4'} ...
                              { '80','2000','50','Onshore', 'Mk8', '92.8'} ...  % 92.6
                              { '80','2000','60','Onshore', 'Mk8', '92.8'}};
            
            for K = configurations
                data =  containers.Map();
                data('Rotor')     = K{1}{1};
                data('GearRatio') = K{1}{6};
                data('NominalPower') = K{1}{2};
                %disp([codec.MkType.get(data) '==' K{1}{5}])
                self.assertFalse(isempty(strfind(codec.MkType.get(data), K{1}{5})))
            end
        end
        
        function test_getMk567(self)
            % \\dkaartswrel01\Release\V80V90V100_1.8MW2MW_Mk5Mk6Mk7_2013.07.x\V80V90V100_1.8MW2MW_Mk5Mk6Mk7_2013.07.28\Configurations\
            configurations = {{'100','1800','VCSS','60','Mk7','92.8'} ...
                              {'100','1800','VCS', '60','Mk7','92.8'} ...
                              {'100','1800','VCUS','60','Mk7','92.8'} ...
                              {'100','2000','VCSS','60','Mk7','90.3'} ...
                              { '80','2000','VCSS','60','Mk6','120.7'} ... % 120.6
                              { '80','2000','VCSS','60','Mk7','120.7'} ... % 120.6
                              { '80','2000','VCS', '50','Mk5','100.6'} ... % 100.4
                              { '80','2000','VCS', '50','Mk7','100.6'} ... % 100.4
                              { '80','2000','VCS', '60','Mk5','120.7'} ... % 120.6
                              { '80','2000','VCS', '60','Mk7','120.7'} ... % 120.6
                              { '80','2000','VCUS','60','Mk6','120.7'} ... % 120.6
                              { '90','1800','VCSS','60','Mk7','92.8'} ...  % 92.6?
                              { '90','1800','VCS', '60','Mk7','92.8'} ...  % 92.6?
                              { '90','1800','VCUS','60','Mk7','92.8'} ...  % 92.6?
                              { '90','1800','VCS', '50','Mk5','112.8'} ...
                              { '90','1800','VCS', '50','Mk7','112.8'} ...
                              { '90','2000','VCS', '50','Mk5','112.8'} ...
                              { '90','2000','VCS', '50','Mk7','112.8'} ...
                              { '80','2000','VCUS','60','Mk7','120.7'}};   % 120.6
                              
                            %{'100','1800','VCS', '50','Mk7','112.8'} ... % Not a variant?
                            %{ '90','1800','VCSS','60','Mk6','92.8'} ...  % Not a variant?
                            %{ '90','1800','VCUS','60','Mk6','92.8'} ...  % Not a variant?
                              
            for K = configurations
                data =  containers.Map();
                data('Rotor')     = K{1}{1};
                data('GearRatio') = K{1}{6};
                data('NominalPower') = K{1}{2};
                %disp([codec.MkType.get(data) '==' K{1}{5}])
                self.assertFalse(isempty(strfind(codec.MkType.get(data), K{1}{5})))
                
            end
        end
    end
end