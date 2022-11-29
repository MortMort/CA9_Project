classdef benchmarkExperiment < wtLin.experiment
         
    properties (Access = protected)
        intPth
    end
    
    methods  (Access = public)
        function obj=benchmarkExperiment(gp,op,intPth)
          obj=obj@wtLin.experiment(gp,op);
          obj.addBenchmarkLoops();
          obj.intPth=intPth;
        end
 
        function makeComparePlots(self,LCgroup,wnd)
            
            switch (LCgroup)
                case 99
                    stepsize=30;
                case 98
                    stepsize=10;
                case 97
                    stepsize=75;
                otherwise
                    error('No such LC group');
            end
            
            intf=fullfile(self.intPth,sprintf('%2d%02d.int',LCgroup,wnd));
            [GI,X,Y]=self.readTimeTrace(intf);
            
            %%Read sensors
            genSpd=self.getSensor(GI,Y,'.*Generator speed');
            power=self.getSensor(GI,Y,'.*Power');
            rotSpd=self.getSensor(GI,Y,'.*Rotor speed');
            Maero=self.getSensor(GI,Y,'.*Aerodynamic Torque');
            genSpdRef=self.getSensor(GI,Y,'.*GeneratorSpeedReference');
            pitch=self.getSensor(GI,Y,'.*pitch 2');
            pitchRef=self.getSensor(GI,Y,'.*PiRS_PitchPosRef');
            Mgen=self.getSensor(GI,Y,'.*Generator torque');
            powRef=self.getSensor(GI,Y,'.*PowerReference');
            wind=self.getSensor(GI,Y,'.*free wind');
            tsim=X;
            
            %%Operating point comparison
            f=figure();
            genSpdOp=mean(genSpd(1:1000));
            MaeroOp=mean(Maero(1:1000));
            pitchOp=mean(pitch(1:1000));
            MgenOp=mean(Mgen(1:1000));
            powerOp=mean(power(1:1000));
            
            lp=self.lp.s;
            dat=[genSpdOp,pitchOp,powerOp;lp.stat.genSpd,lp.stat.pitch,lp.stat.power]';
            rnames={'GenSpeed','Pitch','Power'};
            cnames={'VTS','WTLin'};
            
            uitable('Parent',f,'Data',dat,'ColumnName',cnames,'RowName',rnames)
            
            %setup figure
            figure() %Easy
            
            %% Closed loop
            [ym,t]=step(self.getCLref(),150);          
            subplot(2,3,1);
            plot(t+50,ym*stepsize,tsim,genSpd-mean(genSpd(1:1000)))
            title('Closed loop step response')
                      
            %% aerodynamics
            U1=pitch-mean(pitch(1:1000));
            U3=rotSpd-mean(rotSpd(1:1000));
            U2=wind-mean(wind(1:1000));
            
            if (self.lp.s.stat.ctr.FullLoad)
                aero=self.comp.s.aeroFLC;
            else
                aero=self.comp.s.aeroPLC;
                %U1=U1*0; %The current PLC model has fixed pitch
                %aero=self.comp.s.aeroFLC;
            end
                        
            U=[U1,U2,U3/60*2*pi];
            
            Maeron=lsim(aero,U,tsim);

            % Maero filter
            %[b,a] = butter(12,0.05,'low');
            %Maerofilt=filtfilt(b,a,Maero);
 
            subplot(2,3,2)
            plot(tsim,Maeron,tsim,(Maero-mean(Maero(1:1000)))*1000);%,Maerofilt-mean(Maerofilt(1:1000)))*1000);
            title('Aerodynamic torque')
            
            %% Controller
            
            U2=genSpd-genSpdRef(1);
            U1=genSpdRef-genSpdRef(1);
            U=[U1,U2];
            
            if (self.lp.s.stat.ctr.FullLoad)
                ctr=self.comp.s.FLC_full;
                usig=pitchRef-mean(pitchRef(1:1200));
            else
                ctr=self.comp.s.PLC_full;
                usig=powRef-mean(powRef(1:1200));
            end
            
            ctrRefm=lsim(ctr,U,tsim);

            subplot(2,3,3)
            plot(tsim,ctrRefm,tsim,usig)
            title('Controller Output')

            %% Converter generator

            U2=rotSpd-mean(rotSpd(1:1000));
            U1=powRef-mean(powRef(1:1000));
            U=[U1,U2/60*2*pi];

            Mgenm=lsim(self.comp.s.ConGen,U,tsim);

            subplot(2,3,4)
            plot(tsim,Mgenm/113.3,tsim,Mgen-Mgen(1))
            title('Generator Torque')

            %% Drivetrain
            U2=(Mgen-mean(Mgen(1:1200)))*self.lp.s.mp.drt.GearRatio;
            U1=(Maero-mean(Maero(1:1200))-1)*1000;
            U=[U1,U2];

            wm=lsim(self.comp.s.drt,U,tsim);

            subplot(2,3,5)
            plot(tsim,wm,tsim,genSpd-mean(genSpd(1:1000)))
            title('Generator Speed')

            %% Pitch
            U=pitchRef-mean(pitchRef(1:1000));

            pitchm=lsim(self.comp.s.pit,U,tsim);
            subplot(2,3,6)
            plot(tsim,pitchm,tsim,pitch-mean(pitch(1:1000)),tsim,U)
            title('Pitch Angle')

        end
        
    end
   
    methods (Access = protected)
        function addBenchmarkLoops(self)
            c=self.comp.s;
            Sum = sumblk('e','w_ref_filt','w_filt','+-');
            self.comp.s.FLC_full=connect(c.FLCRefFilt,c.FLC,c.FBfilt,Sum,{'w_ref','w'},'th_ref');
            self.comp.s.ConGen=connect(c.cnv,c.gen,{'P_ref','W'},'Mgen');
            self.comp.s.PLC_full=connect(c.PLCRefFilt,c.PLC,c.FBfilt,Sum,{'w_ref','w'},'P_ref');
        end
    end
    
    methods (Static)
        
        function createBenchmarkPrep(inPrepFile)
            fid=fopen(inPrepFile,'r');
            refModel=LAC.codec.vts.ReferenceModel.decode(fid);
            fclose(fid);
            refModel.simtime=200;
            refModel.BladeDOF1=0;
            refModel.BladeDOF2=0;
            refModel.BladeDOF3=0;
            refModel.BladeDOF4=0;
            refModel.BladeDOF5=0;
            refModel.BladeDOF6=0;
            refModel.BladeDamper=0;
            refModel.BladeTorsion=0;
            refModel.DOF13=1;
            refModel.DOF14=0;
            refModel.DOF15=0;
            refModel.ND=0;
            refModel.Rot=0;
            refModel.DOF11=0;
            refModel.DOF12=0;
            refModel.DmprX=0;
            refModel.DmprY=0;
            refModel.DmprZ=0;
            refModel.DOFDownwind1=0;
            refModel.DOFDownwind2=0;
            refModel.DOFDownwind3=0;
            refModel.DOFDownwind4=0;
            refModel.DOFLateral1=0;
            refModel.DOFLateral2=0;
            refModel.DOFLateral3=0;
            refModel.DOFLateral4=0;
            refModel.DOF=0;
            refModel.Damper=0;
            refModel.DOFX=0;
            refModel.DOFY=0;
            refModel.DOFZ=0;
            refModel.DOFRotX=0;
            refModel.DOFRotY=0;
            refModel.DOFRotZ=0;
            
            
            %refModel.RemainingLines=genLoadcases();
            [pathstr,name,~]=fileparts(inPrepFile);
            ofid=fopen(fullfile(pathstr,[name '_wtLin.txt']),'w');
            refModel.encode(ofid);
            fclose(ofid);
        end
        
    end
    
    methods (Static, Access=private)
        %Temporary function until LMT supports reading DVX/int files
        function [GI,X,Y] = readTimeTrace(filenamein)
            if filenamein(end) == ' '
                filenamein = strtrim(filenamein);
            end
            % Temporary solution for handling zip files
            if strcmpi(filenamein(end-3:end),'.zip')
                fn = unzip(filenamein,tempdir);
                filename = fn{1};
            else
                filename = filenamein;
            end

            [~,~,FileExt] = fileparts(filename);
            FileReadFcn=FindFileReadFcn(FileExt(2:end)); % VDAT function

            if exist('shared.lib.VDATInfo','class')
                VDATConfig = shared.lib.VDATInfo.instance();
                VDATversion = VDATConfig.Version;
            else
                % older versions of VDAT do not have the class for version info
                [GI,X,Y] = feval(FileReadFcn,filename,1,[],[]); % VDAT function
                return;
            end

            tok = regexp(VDATversion,'(\d+)\.(\d+)\.(\d+)','tokens');

            if str2double(tok{1}{1}) >= 2 && str2double(tok{1}{2}) >= 4 && str2double(tok{1}{3}) >= 4
                [GI,X,Y] = feval(FileReadFcn,filename,1,[],[],[]); % VDAT function
            else
                [GI,X,Y] = feval(FileReadFcn,filename,1,[],[]); % VDAT function
            end

            if ~isfield(GI,'SensorSym') && ~isempty(X)
                SensorReadFcn=FindSensorsFcn(FileExt(2:end));
                [SensorList,SensorDesc] = feval(SensorReadFcn,filename,GI,struct('AutoRenameDuplSens',true,'SensorListConfig','Auto Detection'));
                GI.SensorSym = SensorList;
                GI.SensorDesc = SensorDesc;
            end
            if exist('fn','var')
                delete(fn{:});
            end
        end
        
        function dat=getSensor(GI,Y,senspatt)
            descs=cellstr(GI.SensorDesc);
            sens=~cellfun(@isempty,regexp(descs,senspatt));
            sensIdx=find(sens,1);
            dat = Y(:,sensIdx);
        end
    end
    
end



