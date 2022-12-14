classdef MkType
    methods (Static)
        function mktype = get(RefmodelData)
            Rotor = RefmodelData('Rotor');
            GearRatio = RefmodelData('GearRatio');
            NominalPower = str2double(RefmodelData('NominalPower'));
            
            tolerance = 0.0;
            mktype = 'UNKNOWN';
            switch Rotor
                case '80'
                    tolerance = 0.21;
                    if codec.MkType.isEqual(GearRatio, '92.1',tolerance)
                        mktype = 'Mk7';
                    elseif codec.MkType.isEqual(GearRatio, '92.6',tolerance)
                        mktype = 'Mk8';
                    elseif codec.MkType.isEqual(GearRatio, '100.4',tolerance)
                        mktype = 'Mk5/Mk7';
                    elseif codec.MkType.isEqual(GearRatio, '120.6',tolerance)
                        mktype = 'Mk5/Mk6/Mk7';
                    end
                case '90'
                    tolerance = 0.21;
                    if codec.MkType.isEqual(GearRatio, '92.6',tolerance)
                        mktype = 'Mk7';
                    elseif codec.MkType.isEqual(GearRatio, '104.4',tolerance)
                        mktype = 'Mk8';
                    elseif codec.MkType.isEqual(GearRatio, '104.6',tolerance)
                        mktype = 'Mk5/Mk6/Mk7/Mk8/Mk9';
                    elseif codec.MkType.isEqual(GearRatio, '109',tolerance)
                        mktype = 'Mk5/Mk7/Mk8/Mk9';
                    elseif codec.MkType.isEqual(GearRatio, '112.8',tolerance)
                        mktype = 'Mk5/Mk7';
                    end
                case '100'
                    tolerance = 0.01;
                    if codec.MkType.isEqual(GearRatio, '90.3',tolerance)
                        mktype = 'Mk7H/Mk10';
                    elseif codec.MkType.isEqual(GearRatio, '92.8',tolerance)
                        mktype = 'Mk7';
                    elseif codec.MkType.isEqual(GearRatio, '104.4',tolerance)
                        mktype = 'Mk9';
                    elseif codec.MkType.isEqual(GearRatio, '112.8',tolerance)
                        if NominalPower == 1800
                            mktype = 'Mk7H';
                        else
                            mktype = 'Mk10';
                        end
                    elseif codec.MkType.isEqual(GearRatio, '113.1',tolerance)
                        mktype = 'Mk7.5/Mk8';
                    elseif codec.MkType.isEqual(GearRatio, '125.66',tolerance)
                        mktype = 'Mk0';
                    end
                case '105'
                    mktype = 'Mk2a';
                case '110'
                    mktype = 'Mk10';
                case '112'
                    if NominalPower < 3100
                        mktype = 'Mk0';
%                         tolerance = 0.05;
%                         if codec.MkType.isEqual(GearRatio, '105.22',tolerance)
%                             mktype = 'Mk0';
%                         elseif codec.MkType.isEqual(GearRatio, '113.25',tolerance)
%                             mktype = 'Mk0';
%                         end
                    else
                        mktype = 'Mk2a';
                    end
                case '117'
                    mktype = 'Mk2a';
                case '126'
                    mktype = 'Mk2a';
                case '164'
                    mktype = 'Mk1';
            end
        end
        
        function status = verify(mktype)
            % Verify MkType format, e.g. Mk10, Mk2a, or Mk7.1
            status =false;
            mktype = strrep(lower(mktype), 'mk', 'Mk');
            mktype = strrep(mktype, 'h', 'H');
            
            res = regexp(mktype, 'Mk[0-9]+[a-dH]|Mk[0-9]+(\.[0-9]+)?','match');
            if length(res)==1 && strcmp(res,mktype)
                % Update MkType in uitable_Parts
                status = true;
            end
        end
    end
    
    methods(Static,Access=private)
        function output = isEqual(x, y, tolerance)
            output = (abs(str2double(x)-str2double(y)) <= tolerance);
        end
    end
end
   