% PESEG 2012 - Patched to work with latest - but this piece of code is not 
% very robust regarding changes in the pyro input format. 

classdef INP < LAC.vts.codec.Part_Common
    properties
        Header
        Rotor
        ws_min, ws_max, ws_step
        wsCalc_min, wsCalc_step
        airdensity, cAir, nu
        weibullA, weibullC, TI
        hubheight, windshear
        tilt, yaw, coning, nBlades
        ts_min, ts_max, ts_setting
        isFixedpitch, pitchregulation
        enableNoiseOpt, noise_max
        ratedPower, ratedSpeed, gearratio
        
        outputLambda, outputTS, outputOmega, outputGenSpd, outputPitch
        outputCp, outputCt, outputInduction
        outputPaero, outputThrust, outputPgen, outputdPdTheta
        outputGearloss, outputGenloss, outputOtherloss
        outputP10min, outputCpElec, outputThrust10min, outputCt10min, outputNoise
        outputSectionAlpha, outputSectionCl, outputSectionCd, outputSectionCp, outputSectionCt, outputSectionInduction, outputSectionInductionRad, outputSectionVelocity
        outputTableCp, outputTableCt
        
        theta_min, theta_max, theta_step
        lambda_min, lambda_max, lambda_step
        doNoisecalc, outputSectionNoise, outputNoise10min
        OutputLoads, flap_bm, edge_bm, pitch_m, thrust_c, torque_c
        Output_VTS,  lambda_min_vts,  lambda_max_vts,  lambda_oper_vts
        
        profiFile
        
        
        
        
        
        %Tables
        LossTableIdle,LossTableGear,LossTableOther,LossTableGenerator,SectionTableBlade,OptispeedTable, OptipitchTable
        
        comments
    end
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.Rotor]  = VTSCoder.get();
            VTSCoder.skip(1);
            [s.ws_min, s.ws_max, s.wsCalc_min, s.wsCalc_step, s.ws_step] = VTSCoder.get();
            [s.airdensity, s.cAir, s.nu]              = VTSCoder.get();
            [s.weibullA, s.weibullC, s.TI]            = VTSCoder.get();  
            [s.hubheight, s.windshear]                = VTSCoder.get(); 
            [s.tilt, s.yaw, s.coning, s.nBlades]      = VTSCoder.get(); 
            [s.ts_min, s.ts_max, s.ts_setting]        = VTSCoder.get(); 
            [s.isFixedpitch, s.pitchregulation]       = VTSCoder.get(); 
            [s.enableNoiseOpt, s.noise_max]           = VTSCoder.get(); 
            [s.ratedPower, s.ratedSpeed, s.gearratio] = VTSCoder.get();
            VTSCoder.skip(4);  % some extra lines in the new pyro format

            [nRows] = skipUnknownLines();
            s.LossTableGear{1} = VTSCoder.readTableData(str2double(nRows),2);           
            
            [nRows] = skipUnknownLines();
            %nRows = VTSCoder.get();
            s.LossTableIdle{1} = VTSCoder.readTableData(str2double(nRows),2);        
            
            %[nRows] = skipUnknownLines();
            VTSCoder.skip(1);
            s.LossTableGenerator{1}  = myTableReader();            

            [nRows] = skipUnknownLines()
            s.LossTableOther{1} = VTSCoder.readTableData(str2double(nRows),2);           
            VTSCoder.skip(1);
            
            [s.outputLambda, s.outputTS, s.outputOmega, s.outputGenSpd, s.outputPitch] = VTSCoder.get(); 
            [s.outputCp, s.outputCt, s.outputInduction] = VTSCoder.get(); 
            [s.outputPaero, s.outputThrust, s.outputPgen, s.outputdPdTheta] = VTSCoder.get(); 
            [s.outputGearloss, s.outputGenloss, s.outputOtherloss] = VTSCoder.get(); 
            [s.outputP10min, s.outputCpElec, s.outputThrust10min, s.outputCt10min, s.outputNoise] = VTSCoder.get(); 
            [s.outputSectionAlpha, s.outputSectionCl, s.outputSectionCd, s.outputSectionCp, s.outputSectionCt, s.outputSectionInduction, s.outputSectionInductionRad, s.outputSectionVelocity] = VTSCoder.get(); 
            
            [s.outputTableCp, s.outputTableCt] = VTSCoder.get(); 
            [s.theta_min, s.theta_max, s.theta_step] = VTSCoder.get(); 
            [s.lambda_min, s.lambda_max, s.lambda_step] = VTSCoder.get(); 
            [s.doNoisecalc, s.outputSectionNoise, s.outputNoise10min] = VTSCoder.get();
            [s.OutputLoads,s.flap_bm,s.edge_bm,s.pitch_m,s.thrust_c,s.torque_c] = VTSCoder.get();
            [s.Output_VTS,  s.lambda_min_vts,  s.lambda_max_vts,  s.lambda_oper_vts] = VTSCoder.get();
            VTSCoder.skip(1);

            [nRows] = skipUnknownLines();
            VTSCoder.skip(1);
            s.SectionTableBlade{1} = VTSCoder.readTableData(str2double(nRows),4);           
            [s.profiFile] = VTSCoder.get();
            %VTSCoder.skip(1);
            
            [nRows] = skipUnknownLines();
            VTSCoder.skip(1);
            s.OptispeedTable{1} = VTSCoder.readTableData(str2double(nRows),2);           
            %VTSCoder.skip(1);
            
            [nRows] = skipUnknownLines();
            VTSCoder.skip(1);
            s.OptipitchTable{1} = VTSCoder.readTableData(str2double(nRows),2);           
            %VTSCoder.skip(1);
            
           [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
            % why
            % Table reader
            function [table] = myTableReader()

                % this part will skip new lines until a non-empty one is
                % found
                tmp = strtrim(VTSCoder.getLine(VTSCoder.current));
                while isempty(tmp)
                    VTSCoder.skip(1)
                    tmp = strtrim(VTSCoder.getLine(VTSCoder.current));
                end
                
                % and here the matrix is read:
                tmp = VTSCoder.lines(VTSCoder.current,VTSCoder.current+1);
                if ~isempty(tmp)
                    VTSCoder.skip(2);
                    rowcol = str2double(strsplit_LMT(tmp{1}));
                    table = VTSCoder.readTableData(rowcol(2),rowcol(1));
                    table.columnnames = strsplit_LMT(strtrim(tmp{2}));
                    table.rownames = table.data(:,1);
                    table.data = table.data(:,2:end);
                else
                    table = VTSCoder.readTableData('','');
                    table.header = tHeader;
                end

            end
            
            % PESEG 2012 - as I understand it, this skips at least one line (assumed a space)
            % and then keeps looking through lines until it successfully
            % finds a line that starts with an integer, then it will return
            % that integer as nRows
            function [nRows] = skipUnknownLines()                           
                                                  
                VTSCoder.skip(1);
                while true
                    try
                        nRows = VTSCoder.get();
                        break;
                    catch ME
                        if (strcmp(ME.identifier,'MATLAB:textscan:NoInput'))
                            VTSCoder.skip(1);
                        % added the error that currently matlab throws for
                        % an empty line
                        elseif (strcmp(ME.identifier,'MATLAB:badsubscript'))
                            VTSCoder.skip(1);
                        else
                            % if the error is otherwise, return the error
                            % and the line number, 
                            error(['ERROR whilst reading line ' num2str(VTSCoder.current()) ME.identifier]);
                            break;
                        end
                    end
                end
            end
        end
    end
    
    methods
        function encode(s,filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, s.getAttributes());
            s = s.convertAllToString();
            
            VTSCoder.setProperty(s.Header);
            VTSCoder.setProperty({s.Rotor})
            VTSCoder.setProperty('');
            VTSCoder.setProperty({s.ws_min, s.ws_max, s.wsCalc_min, s.wsCalc_step, s.ws_step},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.airdensity, s.cAir, s.nu},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.weibullA, s.weibullC, s.TI},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.hubheight, s.windshear},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.tilt, s.yaw, s.coning, s.nBlades},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.ts_min, s.ts_max, s.ts_setting},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.isFixedpitch, s.pitchregulation},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.enableNoiseOpt, s.noise_max},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');
            VTSCoder.setProperty({s.ws_min, s.ws_max, s.wsCalc_min, s.wsCalc_step, s.ws_step},21,'min_vind  max_vind  min_vind_beregn  vindstep_beregn  vindstep_output');

            [s.airdensity, s.cAir, s.nu]              = VTSCoder.get();
            [s.weibullA, s.weibullC, s.TI]            = VTSCoder.get();  
            [s.hubheight, s.windshear]                = VTSCoder.get(); 
            [s.tilt, s.yaw, s.coning, s.nBlades]      = VTSCoder.get(); 
            [s.ts_min, s.ts_max, s.ts_setting]        = VTSCoder.get(); 
            [s.isFixedpitch, s.pitchregulation]       = VTSCoder.get(); 
            [s.enableNoiseOpt, s.noise_max]           = VTSCoder.get(); 
            [s.ratedPower, s.ratedSpeed, s.gearratio] = VTSCoder.get();            
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            s.LossTableGear{1} = VTSCoder.readTableData(str2double(nRows),2);           
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            s.LossTableIdle{1} = VTSCoder.readTableData(str2double(nRows),2);        
            VTSCoder.skip(1);
            
            s.LossTableGenerator{1}  = myTableReader();            
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            s.LossTableOther{1} = VTSCoder.readTableData(str2double(nRows),2);           
            VTSCoder.skip(1);
            
            [s.outputLambda, s.outputTS, s.outputOmega, s.outputGenSpd, s.outputPitch] = VTSCoder.get(); 
            [s.outputCp, s.outputCt, s.outputInduction] = VTSCoder.get(); 
            [s.outputPaero, s.outputThrust, s.outputPgen, s.outputdPdTheta] = VTSCoder.get(); 
            [s.outputGearloss, s.outputGenloss, s.outputOtherloss] = VTSCoder.get(); 
            [s.outputP10min, s.outputCpElec, s.outputThrust10min, s.outputCt10min, s.outputNoise] = VTSCoder.get(); 
            [s.outputSectionAlpha, s.outputSectionCl, s.outputSectionCd, s.outputSectionCp, s.outputSectionCt, s.outputSectionInduction, s.outputSectionInductionRad, s.outputSectionVelocity] = VTSCoder.get(); 
            
            [s.outputTableCp, s.outputTableCt] = VTSCoder.get(); 
            [s.theta_min, s.theta_max, s.theta_step] = VTSCoder.get(); 
            [s.lambda_min, s.lambda_max, s.lambda_step] = VTSCoder.get(); 
            [s.doNoisecalc, s.outputSectionNoise, s.outputNoise10min] = VTSCoder.get();
            [s.OutputLoads,s.flap_bm,s.edge_bm,s.pitch_m,s.thrust_c,s.torque_c] = VTSCoder.get();
            [s.Output_VTS,  s.lambda_min_vts,  s.lambda_max_vts,  s.lambda_oper_vts] = VTSCoder.get();
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            VTSCoder.skip(1);
            s.SectionTableBlade{1} = VTSCoder.readTableData(str2double(nRows),4);           
            [s.profiFile] = VTSCoder.get();
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            VTSCoder.skip(1);
            s.OptispeedTable{1} = VTSCoder.readTableData(str2double(nRows),2);           
            VTSCoder.skip(1);
            
            nRows = VTSCoder.get();
            VTSCoder.skip(1);
            s.OptipitchTable{1} = VTSCoder.readTableData(str2double(nRows),2);           
            VTSCoder.skip(1);
            
            VTSCoder.setRemaininglines(s.comments);
            
            status = VTSCoder.save();            
            
        end
        
        function myattributes = getAttributes(self)
            myattributes = struct();
            
            mco = metaclass(self);
            myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            myproperties = myproperties(~strcmpi(myproperties,'LossTableIdle'));
            myproperties = myproperties(~strcmpi(myproperties,'LossTableGear'));
            myproperties = myproperties(~strcmpi(myproperties,'LossTableOther')); 
            myproperties = myproperties(~strcmpi(myproperties,'LossTableGenerator')); 
            myproperties = myproperties(~strcmpi(myproperties,'SectionTableBlade'));
            myproperties = myproperties(~strcmpi(myproperties,'OptispeedTable')); 
            myproperties = myproperties(~strcmpi(myproperties,'OptipitchTable'));
            
            mytables = {'LossTableIdle','LossTableGear','LossTableOther','LossTableGenerator','SectionTableBlade','OptispeedTable', 'OptipitchTable'};
            myfiles = {};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;            
        end
    end        
    

end
