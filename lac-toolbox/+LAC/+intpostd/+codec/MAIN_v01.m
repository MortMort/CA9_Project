%MAIN_v01 - MAIN_v01 object reading intpostD mainloads file
%
% Syntax:  mainObj = LAC.intpostd.codec.MAIN_v01(CoderObj)
%
% Description: This is an alternative to the MAIN codec. The difference
% between MAIN and MAIN_v01 is the structure in the output, which has been
% arranged in a more intuitive format.
% 
% This codec should be merged into the MAIN codec and used as an alternative in a future version.
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    mainObj   - Mainloads object containing all properties of the blade
%
% Methods
%
% Example: 
%    mainObj = LAC.intpostd.convert(mainloadsfilename,'MAIN_v01')
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert   

classdef MAIN_v01 < LAC.intpostd.codec.MAIN_shared
    
    properties 
        ch51_ExtremeFlapwiseMoment, ch52_ExtremeEdgewiseMoment, ch53_EquivalentFlapwiseMoment, ch54_EquivalentEdgewiseMoment
        ch61_ExtremeHubLoads, ch62_EquivalentHubLoads, ch63_ExtremeBladeBearingLoads, ch64_EquivalentBladeBearingLoad, ch65_ExtremePitchCylinderForceExclPitchLock, ch66_ExtremePitchMomentOnlyPitchLock, ch67_EquivalentPitchCylinderForce
        ch71_ExtremeLoadsMainBearingorShaft, ch72_ExtremeRotorLockLoads, ch73_EquivalentLoadsMainBearingorShaft, ch74_EquivalentGearBearingLoad
        ch81_ExtremeLoadsAtNacelleTowerInterface,  ch82_EquivalentLoadsatNacelleTowerInterface
        ch91_ExtremeResultantTowerMomentFndLvl, ch92_EquivalentTowerMomentFndLvl
        ch101_ExtremeBladeDeflectioninFrontofTower        
    end    
    
    
    methods (Access=protected)
        function sectionNames = getSectionNames(self)
            sectionNames = {'ch51_ExtremeFlapwiseMoment', 'ch52_ExtremeEdgewiseMoment', 'ch53_EquivalentFlapwiseMoment', 'ch54_EquivalentEdgewiseMoment'...
                'ch61_ExtremeHubLoads', 'ch62_EquivalentHubLoads', 'ch63_ExtremeBladeBearingLoads', 'ch64_EquivalentBladeBearingLoad', 'ch65_ExtremePitchCylinderForceExclPitchLock', 'ch66_ExtremePitchMomentOnlyPitchLock', 'ch67_EquivalentPitchCylinderForce', ...
                'ch71_ExtremeLoadsMainBearingorShaft', 'ch72_ExtremeRotorLockLoads', 'ch73_EquivalentLoadsMainBearingorShaft', 'ch74_EquivalentGearBearingLoad'...
                'ch81_ExtremeLoadsAtNacelleTowerInterface'  'ch82_EquivalentLoadsatNacelleTowerInterface',...
                'ch91_ExtremeResultantTowerMomentFndLvl', 'ch92_EquivalentTowerMomentFndLvl'...
                'ch101_ExtremeBladeDeflectioninFrontofTower'};
        end

        function senData = addToSenData(self,senData,C,decodeID)
            if max(strcmp(C{1}{3},{'Rfc','Lrd','Ldd'}))
                sensorname = [regexprep(regexprep(C{1}{1},'[-\.()]',''),'*','_') '_'  regexprep(C{1}{3},'[-\.()*]','') '_' strrep(num2str(C{1}{5}),'.','p')];                            
            else
                sensorname = [regexprep(regexprep(C{1}{1},'[-\.()]',''),'*','_') '_'  regexprep(C{1}{3},'[-\.()*]','')];
            end
            sensorname = regexprep(sensorname,'?','_');
            if size(C{1},1)>4
                senData.(sensorname).Sensor = C{1}{1};
                senData.(sensorname).Unit   = C{1}{2};
                senData.(sensorname).Method = C{1}{3};
                senData.(sensorname).Value = str2double(C{1}(4));
                senData.(sensorname).Note = C{1}{5};
                senData.(sensorname).Comments = '';
                senData.(sensorname).Ref = '';
            end
            
            if size(C{1},1)>5 
                if regexp(C{1}{6},'\[[0-9]+\]')
                    senData.(sensorname).Ref = C{1}{6};
                    if size(C{1},1)>6
                        senData.(sensorname).Comments = char(join(C{1}(7:end)));
                    end
                else
                    senData.(sensorname).Comments = char(join(C{1}(6:end)));
                end
            end                
            senData.(sensorname).Chapter = self.decodeSections{decodeID};
        end
        
        function printBladeLoads(self,fid,sectionNumbers,sectionNamesToPrint,header,finalSection)
           error('The function ''printBladeLoads'' is not implemented in ''MAIN_v01'' codec yet. Please use ''MAIN'' codec') 
        end
            
    end
    
    methods
        function addRobustificationFactors(self,RF)
           error('The function ''addRobustificationFactors'' is not implemented in ''MAIN_v01'' codec yet. Please use ''MAIN'' codec')
        end
    end
end
   