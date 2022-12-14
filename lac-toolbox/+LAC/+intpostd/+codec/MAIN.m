%MAIN - MAIN object reading intpostD mainloads file
%
% Syntax:  mainObj = LAC.intpostd.codec.MAIN(CoderObj)
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
%    mainObj = LAC.intpostd.convert(mainloadsfilename,'MAIN')
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert

classdef MAIN < LAC.intpostd.codec.MAIN_shared
    
    properties
        ExtremeFlapwiseMoment, ExtremeEdgewiseMoment, EquivalentFlapwiseMoment, EquivalentEdgewiseMoment
        ExtremeHubLoads, EquivalentHubLoads, ExtremeBladeBearingLoads, EquivalentBladeBearingLoad, ExtremePitchCylinderForceExclPitchLock, EquivalentPitchCylinderForce, ExtremePitchMomentOnlyPitchLock
        ExtremeLoadsMainBearingorShaft, ExtremeRotorLockLoads, EquivalentLoadsMainBearingorShaft, EquivalentGearBearingLoad
        ExtremeLoadsAtNacelleTowerInterface,  EquivalentLoadsatNacelleTowerInterface
        ExtremeResultantTowerMomentFndLvl, EquivalentTowerMomentFndLvl
        ExtremeBladeDeflectioninFrontofTower
    end
    
    methods
        function addRobustificationFactors(self,RF)
            % addRobustificationFactors(RF) Add robustification factors to loads.
            % Add robustification factors RF to the loads and writes the
            % robustification factor in a comment in the end of each line that is 
            % modified. 
            %  Inputs:
            % RF: RobustificationFactors struct coming from ReadRobustificationFile
            %
            % See also: ReadRobustificationFile

            % T_BLD_T_BRG
            if isfield(RF,'T_BLD_T_BRG')
                subFields = fields(RF.T_BLD_T_BRG);
                for i=1:length(subFields)
                    switch subFields{i}
                        case 'flap_BLD'
                            self.addRobustificationToSection('ExtremeFlapwiseMoment','^B([1-3]|\?)Mx[0-9]{5}$','Max',RF.T_BLD_T_BRG.flap_BLD.maxAbs)
                            self.addRobustificationToSection('ExtremeFlapwiseMoment','^B([1-3]|\?)Mx[0-9]{5}$','Min',RF.T_BLD_T_BRG.flap_BLD.min)
                            self.addRobustificationToSection('EquivalentFlapwiseMoment','^B([1-3]|\?)M(x)[0-9]{5}$','Rfc',RF.T_BLD_T_BRG.flap_BLD.fatigue)
                        case 'edge_BLD'
                            self.addRobustificationToSection('ExtremeEdgewiseMoment','^B([1-3]|\?)My[0-9]{5}$','Max',RF.T_BLD_T_BRG.edge_BLD.maxAbs)
                            self.addRobustificationToSection('ExtremeEdgewiseMoment','^B([1-3]|\?)My[0-9]{5}$','Min',RF.T_BLD_T_BRG.edge_BLD.min)
                            self.addRobustificationToSection('EquivalentEdgewiseMoment','^B([1-3]|\?)My[0-9]{5}$','Rfc',RF.T_BLD_T_BRG.edge_BLD.fatigue)
                        case 'flap_hub'
                            self.addRobustificationToSection('ExtremeHubLoads','^-Mx([1-3]|\?)1(h|r)$','Abs',RF.T_BLD_T_BRG.flap_hub.maxAbs)
                            self.addRobustificationToSection('EquivalentHubLoads','^-Mx([1-3]|\?)1(h|r)$','Rfc',RF.T_BLD_T_BRG.flap_hub.fatigue)
                        case 'edge_hub'
                           self.addRobustificationToSection('ExtremeHubLoads','^My([1-3]|\?)1(h|r)$','Abs',RF.T_BLD_T_BRG.edge_hub.maxAbs)
                           self.addRobustificationToSection('EquivalentHubLoads','^My([1-3]|\?)1(h|r)$','Rfc',RF.T_BLD_T_BRG.edge_hub.fatigue)
                        case 'bld_brng'
                           self.addRobustificationToSection('ExtremeBladeBearingLoads','^Mr','Abs',RF.T_BLD_T_BRG.bld_brng.maxAbs)
                           self.addRobustificationToSection('EquivalentBladeBearingLoad','^Mr','Lrd',RF.T_BLD_T_BRG.bld_brng.fatigue)
                        case 'pitch'
                            %Pi[1 2 3]
                            self.addRobustificationToSection('ExtremePitchCylinderForceExclPitchLock','^Fpi','Max',RF.T_BLD_T_BRG.pitch.maxAbs)
                            self.addRobustificationToSection('ExtremePitchCylinderForceExclPitchLock','^Fpi','Min',RF.T_BLD_T_BRG.pitch.min)
                            self.addRobustificationToSection('ExtremePitchMomentOnlyPitchLock','^Mpi','Max',RF.T_BLD_T_BRG.pitch.maxAbs)
                            self.addRobustificationToSection('ExtremePitchMomentOnlyPitchLock','^Mpi','Min',RF.T_BLD_T_BRG.pitch.min)
                           self.addRobustificationToSection('EquivalentPitchCylinderForce','^Fpi','Rfc',RF.T_BLD_T_BRG.pitch.fatigue)
                        otherwise
                            error('%s%s %s','Robustification field T_BLD_T_BRG.',subFields{i},'is not known.')
                    end
                end
            end
            
            % T_DRT
            % ExtremeLoadsMainBearing, EquivalentLoadsMainBearing
            if isfield(RF,'T_DRT')
                subFields = fields(RF.T_DRT);
                for i=1:length(subFields)
                    switch subFields{i}
                        case 'Forces'
                            %[FxMBf FyMBr FzMBf]
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(FxM_f|FyM_r|FzM_f)','Max',RF.T_DRT.Forces.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(FxM_f|FyM_r|FzM_f)','Abs',RF.T_DRT.Forces.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(FxM_f|FyM_r|FzM_f)','Min',RF.T_DRT.Forces.min)
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(FxM_f|FyM_r|FzM_f)','Rfc',RF.T_DRT.Forces.fatigue)
                        case 'Mom_bending'
                            %[MxMBf MzMBf MxMBr MzMBr]
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Max',RF.T_DRT.Mom_bending.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Abs',RF.T_DRT.Mom_bending.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Min',RF.T_DRT.Mom_bending.min)
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Rfc',RF.T_DRT.Mom_bending.fatigue)
                        case 'Mom_bending_F'
                            %[MxMBf MzMBf]
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Max',RF.T_DRT.Mom_bending_F.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Abs',RF.T_DRT.Mom_bending_F.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Min',RF.T_DRT.Mom_bending_F.min)
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(MxM_f|MzM_f)','Rfc',RF.T_DRT.Mom_bending_F.fatigue)
                       case 'Mom_bending_R'
                            %[MxMBr MzMBr MrMB]
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_r|MzM_r|MrM_','Max',RF.T_DRT.Mom_bending_R.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_r|MzM_r|MrM_','Abs',RF.T_DRT.Mom_bending_R.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MxM_r|MzM_r|MrM_)','Min',RF.T_DRT.Mom_bending_R.min)
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(MxM_r|MzM_r)','Rfc',RF.T_DRT.Mom_bending_R.fatigue)
                        case 'Mom_torque'
                            %[MyMBr]
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MyM_r)','Max',RF.T_DRT.Mom_torque.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MyM_r)','Abs',RF.T_DRT.Mom_torque.maxAbs)
                            self.addRobustificationToSection('ExtremeLoadsMainBearingorShaft','^(MyM_r)','Min',RF.T_DRT.Mom_torque.min)
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(MyM_r)','Rfc',RF.T_DRT.Mom_torque.fatigue)  
                        otherwise
                            error('%s%s %s','Robustification field T_DRT.',subFields{i},'is not known.')
                    end
                end
            end
            
            % T_ML
            % ExtremeLoadsAtNacelleTowerInterface,  EquivalentLoadsatNacelleTowerInterface
            if isfield(RF,'T_ML')
                subFields = fields(RF.T_ML);
                for i=1:length(subFields)
                    switch subFields{i}
                        case 'Mxtt'
                            % Mxtt
                            self.addRobustificationToSection('ExtremeLoadsAtNacelleTowerInterface','^(Mxtt|Mbtt)$','Abs',RF.T_ML.Mxtt.maxAbs)                            
                            self.addRobustificationToSection('EquivalentLoadsatNacelleTowerInterface','^Mxtt$','Rfc',RF.T_ML.Mxtt.fatigue)
                        case 'Mztt'
                            % Mztt
                            self.addRobustificationToSection('ExtremeLoadsAtNacelleTowerInterface','^Mztt','Abs',RF.T_ML.Mztt.maxAbs)                            
                            self.addRobustificationToSection('EquivalentLoadsatNacelleTowerInterface','^Mztt','Rfc',RF.T_ML.Mztt.fatigue)                        
                        case 'Acc'
                            % [AxK AyK]
                            self.addRobustificationToSection('ExtremeLoadsAtNacelleTowerInterface','^(AxK|AyK)$','Abs',RF.T_ML.Acc.maxAbs)                            
                            self.addRobustificationToSection('EquivalentLoadsatNacelleTowerInterface','^(AxK|AyK)$','Rfc',RF.T_ML.Acc.fatigue)   
                        case 'RotAcc'
                            % [OMPxK OMPyK OMPzK]
                            self.addRobustificationToSection('ExtremeLoadsAtNacelleTowerInterface','^(OMPxK|OMPyK|OMPzK)$','Abs',RF.T_ML.RotAcc.maxAbs)                            
                            self.addRobustificationToSection('EquivalentLoadsatNacelleTowerInterface','^(OMPxK|OMPyK|OMPzK)$','Rfc',RF.T_ML.RotAcc.fatigue)   
                        otherwise
                            error('%s%s %s','Robustification field T_ML.',subFields{i},'is not known.')
                    end
                end
            end
            
            % T_TOW
            % ExtremeResultantTowerMomentFndLvl, EquivalentTowerMomentFndLvl
            if isfield(RF,'T_TOW')
                subFields = fields(RF.T_TOW);
                for i=1:length(subFields)
                    switch subFields{i}
                        case 'Mbt1'
                            % [Mxt1 Mbt1] 
                            self.addRobustificationToSection('ExtremeResultantTowerMomentFndLvl','^Mbt1$','Max',RF.T_TOW.Mbt1.maxAbs)                            
                            self.addRobustificationToSection('EquivalentTowerMomentFndLvl','^Mxt1$','Rfc',RF.T_TOW.Mbt1.fatigue)
                        otherwise
                            error('%s%s %s','Robustification field T_TOW.',subFields{i},'is not known.')
                    end
                end
            end
            
            % T_DEST
            % EquivalentGearBearingLoad, EquivalentTowerMomentFndLvl
            if isfield(RF,'T_DEST')
                subFields = fields(RF.T_DEST);
                for i=1:length(subFields)
                    switch subFields{i}
                        case 'MyMBr'
                            % [MyMBr] 
                            self.addRobustificationToSection('EquivalentGearBearingLoad','^MyMBr$','Lrd',RF.T_DEST.MyMBr.LRD)
                            self.addRobustificationToSection('EquivalentGearBearingLoad','^MyMBr$','Ldd',RF.T_DEST.MyMBr.LRD)
                        case 'MainBrg'
                            % [MxMBf MzMBf] 
                            self.addRobustificationToSection('EquivalentLoadsMainBearingorShaft','^(MxM_f|MzM_f)$','Lrd',RF.T_DEST.MainBrg.LRD) 
                        otherwise
                            error('%s%s %s','Robustification field T_DEST.',subFields{i},'is not known.')
                    end
                end
            end
            
        end
    end
    
    methods (Access=protected)
        function sectionNames = getSectionNames(self)
            sectionNames = {'ExtremeFlapwiseMoment', 'ExtremeEdgewiseMoment', 'EquivalentFlapwiseMoment', 'EquivalentEdgewiseMoment'...
                'ExtremeHubLoads', 'EquivalentHubLoads', 'ExtremeBladeBearingLoads', 'EquivalentBladeBearingLoad', 'ExtremePitchCylinderForceExclPitchLock', 'ExtremePitchMomentOnlyPitchLock', 'EquivalentPitchCylinderForce', ...
                'ExtremeLoadsMainBearingorShaft', 'ExtremeRotorLockLoads', 'EquivalentLoadsMainBearingorShaft', 'EquivalentGearBearingLoad'...
                'ExtremeLoadsAtNacelleTowerInterface'  'EquivalentLoadsatNacelleTowerInterface',...
                'ExtremeResultantTowerMomentFndLvl', 'EquivalentTowerMomentFndLvl'...
                'ExtremeBladeDeflectioninFrontofTower'};
        end
        
        function senData = addToSenData(self,senData,C,decodeID)
            curSenLine = length(senData)+1;
            if size(C{1},1)>4
                senData(curSenLine).Sensor = C{1}{1};
                senData(curSenLine).Unit   = C{1}{2};
                senData(curSenLine).Method = C{1}{3};
                senData(curSenLine).Value = str2double(C{1}(4));
                senData(curSenLine).Note = C{1}{5};
                senData(curSenLine).Ref = '';
                senData(curSenLine).Comments = '';
            end
            
            if size(C{1},1)>5 
                if regexp(C{1}{6},'\[[0-9]+\]')
                    senData(curSenLine).Ref = C{1}{6};
                    if size(C{1},1)>6
                        senData(curSenLine).Comments = char(join(C{1}(7:end)));
                    end
                else
                    senData(curSenLine).Comments = char(join(C{1}(6:end)));
                end
            end                
            senData(curSenLine).Chapter = self.decodeSections{decodeID};
        end
        
        function printBladeLoads(self,fid,sectionNumbers,sectionNamesToPrint,header,finalSection)
            if ~exist('finalSection','var')
                finalSection = false;
            end
            loadsAvailable = false;
            for i = sectionNumbers
                if ~isempty(self.(self.sectionName{i}))
                    loadsAvailable = true;
                end
            end
            if loadsAvailable == false
                return
            end
            fprintf(fid,'-------------------------------------------------------------------------\n');
            fprintf(fid,'%s\n',header);
            fprintf(fid,'-------------------------------------------------------------------------\n\n');
            k=1;
            for i = sectionNumbers
                if ~isempty(self.(self.sectionName{i}))
                    fprintf(fid,'%s %s\n',self.decodeSections{i},sectionNamesToPrint{k});
                    extremeTable = ismember(self.(self.sectionName{i})(1).Method,{'Abs','Max','Min'});
                    if extremeTable; noteLabel='LC'; else noteLabel='Woehler'; end;
                    switch self.Type
                        case 'MaxMainLoad'                            
                            fprintf(fid,'%s %11s  %12s %15s  %2s  %21s\n','Sensor','Unit','Method','Combined',noteLabel,'Ref');
                            for j = 1:length(self.(self.sectionName{i}))
                                xx = self.(self.sectionName{i})(j);
                                if ~isempty(xx.Unit) && ismember(xx.Unit,{'[m/s2]','[r/s2]','-'}); decimals=3; else decimals=2; end;
                                fprintf(fid,sprintf('%%s %%7s  %%12s %%15.%0.0ff  %%2s  %%2s %%s\n',decimals),xx.Sensor,xx.Unit,xx.Method,xx.Value,xx.Note,xx.Ref,xx.Comments);
                            end
                        case 'MainLoad'
                            fprintf(fid,'%s %11s  %12s %15s  %2s\n','Sensor','Unit','Method','Value',noteLabel);
                            for j = 1:length(self.(self.sectionName{i}))                                
                                xx = self.(self.sectionName{i})(j);
                                if ~isempty(xx.Unit) && ismember(xx.Unit,{'[m/s2]','[r/s2]','-'}); decimals=3; else decimals=2; end;
                                fprintf(fid,sprintf('%%s %%7s  %%12s %%15.%0.0ff  %%2s %%s\n',decimals),xx.Sensor,xx.Unit,xx.Method,xx.Value,xx.Note,xx.Comments);
                            end
                    end
                    k=k+1;
                end
                if ~finalSection
                fprintf(fid,' \n \n');                
                end
            end
        end
    end
    
    methods (Access=private)
        function addRobustificationToSection(self,section,sensors,method,factor)
            for i = 1:length(self.(section))
                if ~isempty(regexp(self.(section)(i).Sensor,sensors)) && regexp(self.(section)(i).Sensor,sensors)==1 && strcmpi(self.(section)(i).Method,method)
                    self.(section)(i).Value = self.(section)(i).Value*factor;
                    if ~isempty(self.(section)(i).Comments)
                        self.(section)(i).Comments = sprintf('%s - %s: %1.2f',self.(section)(i).Comments,'Robustified',factor);
                    else
                        self.(section)(i).Comments = sprintf('%s: %1.2f','Robustified',factor);
                    end
                end
            end
        end
    end
    
end
