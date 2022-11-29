classdef GrossParams < wtLin.mapAbleStruct
    
    methods (Static)
        function obj=importFromOldMat(matfile)
            load(matfile);
            obj=wtLin.GrossParams();
            
            %Rotor parameters
            s.rot.radius=mp.rot.radius;
            s.rot.inertia=mp.rot.inertia;
            
            %Aerodynamic parameters
            s.aero.cp=mp.rot.cp;
            s.aero.ct=mp.rot.ct;
            s.aero.lambda=mp.rot.lambda_tab;
            s.aero.theta=mp.rot.theta_tab;
            s.aero.tauIL=mp.rot.tauIL;
            
            s.gen.ElecEff=mp.gen.ElecEff;
            s.gen.MechEff=mp.gen.MechEff;
            s.gen.AuxLoss=mp.gen.AuxLoss;
            s.gen.inertia=mp.gen.inertia;
            s.gen.tau=mp.gen.tau;
            s.gen.gridFreq = mp.gen.gridFreq;
            
            s.drt.torsStiffness = mp.drv.torsStiffness;
            s.drt.torsDampingLogDecr = mp.drv.torsDampingLogDecr;
            s.drt.gearRatio = mp.drv.gear_ratio;
            s.drt.eigfreq = mp.drv.eigfreq;
            s.drt.useEigFreq = mp.drv.useEigFreq;
            
            s.dtd = mp.dtd;
            
            s.twr = mp.twr;
            
            %This is not strictly true. Effort to use simplified pith model
            s.ctr.pipc.pitErr=cp.pit.theta_tab;
            s.ctr.pipc.cVol=cp.pit.utab;
            s.pit.propVol=mp.pit.u_tab;
            s.pit.pitSpd=mp.pit.dthetadt_tab;
            s.pit.timeconst=mp.pit.timeconst;
            s.pit.delay=mp.pit.delay;
           
            %OTC table
            s.ctr.otc.tab=cp.otc.tab;
                        
            %TL settings in own substruct
            s.ctr.NomPow=cp.otc.NomPow;
            s.ctr.tl.offset=cp.otc.tl.offset;
            s.ctr.tl.slope=cp.otc.tl.slope;
            
            %LambdaOpt, NomSpd, MinSpd
            s.ctr.sc=cp.sc;
            
            %This parameter is not available from VTS setup
            s.ctr.delay=cp.ctrl_delay;
            s.ctr.Ts=fcp.Ts;
            
            %FLC params
            s.ctr.flc=fcp.flc;
            s.ctr.flc.K_PI=fcp.flc.K_PI;
            
            %PLC params
            s.ctr.plc=fcp.plc;
            
            %FATD
            s.ctr.fatd = fcp.fatd;
            
            %SP (band stop filters)
            s.ctr.sp.bs=fcp.filt;
            
            %Converter
            if mp.cnv.GAPC_format_version > 0
                s.cnv.GAPC_format_version = mp.cnv.GAPC_format_version;
                s.cnv.GAPC.LPf = mp.cnv.GAPC.LPf;
                s.cnv.GAPC.Kp = mp.cnv.GAPC.Kp;
                s.cnv.GAPC.wZero = mp.cnv.GAPC.wZero;
            else
                s.cnv.GAPC_format_version = -1;
            end
            
            obj.s=s;
        end
    end
    
end