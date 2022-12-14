% clear all; close all; clc;

% See 0055-4135.V00 for guideline

% In this script, the user has to change:
%     - path to master file
%     - path to frq file
%     - AoA output sensor names
%     - The AoA.Radius = Radius where AoA are output
%     - Stall.AoA = stall AoA for the profiles at the T/C defined in the
%     polar file.

% -- read settings
run('OptiTip_Configuration.m');

% -- redirect some variables
GBXRatio   = OTC.GBXRatio;
Radius     = OTC.Radius;
RatedPower = OTC.RatedPower;

% -- check that this part is to be executed
if(OTC.Steps(1)==0)
    fprintf('This step was disabled in configuration. Check OTC.Steps variable.\n');
    fprintf('Configuration defines the following steps to be executed:\n');
    for i=1:length(OTC.Steps)
        fprintf('\tStep %d: ',i);
        if(OTC.Steps(i)==0)
            fprintf('skip\n');
        else
            fprintf('execute\n');
        end
    end
    error('This step was disabled in configuration. Check OTC.Steps variable.');
end

% ---- find mas file
mas_file = dir(fullfile(pwd,OTC.Step_1.dir,'Loads','INPUTS','*mas'));
if (isempty(mas_file))
    error('Failed to locate mas files');
end

% Path to the master file where the LC were run
msd = LAC.vts.convert(fullfile(pwd,OTC.Step_1.dir,'Loads','INPUTS',mas_file.name));

    % Path to the frequency file where the load cases were run. Change AoA sensors
%     data = MatStat('W:\user\daca\OptiTip\Scripts\20140612\Tables\01\INPUTS\iec2b_HH95-EU_60Hz_SlimGen.frq',{'Maero','Pi2','Vhub',...
%         'Omega','Fthr','AoA223','AoA226','AoA230','AoA233','AoA236','AoA238','AoA240','AoA244'},0);
%     save('OptiTip_STA','data');
    
sta = LAC.vts.stapost(fullfile(pwd,OTC.Step_1.dir,'Loads\'));
sta.read();


% Change to match radius where AoA are output
% AoA.Radius = [25.4 31 36 40 44 46 48 49.5];
% [AoA.Radius,idxAoA] = sta.getSensDat('AoA2');

% Stall AoA: first column is thickness ratio, second column is stall AoA
% Stall.AoA = [25.00	10.60
%     21.00	11.00
%     18.00	10.20
%     17.80	10.00 
%     ];
% Stall margin = the margin is applied to all AoA sensors read from the STA
% files.
% Stall.Margin = 0.0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 DON'T CHANGE ANYTHING IN THE CODE BELOW                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
OptiLambda.Range = OptiLambda.min:OptiLambda.Step:OptiLambda.max;

TmpRefPitch = round(interp1(Ref.OptiTip.TSR,Ref.OptiTip.Pitch,OptiLambda.Range)/Pitch.step)*Pitch.step;
OptiLambda.PitchRange = max(Pitch.min,min(TmpRefPitch)-Pitch.Amp):Pitch.step:max(TmpRefPitch)+Pitch.Amp;

%% WS distribution
Weibull.Lambda  = Weibull.V/gamma(1+1/Weibull.k);
Weibull.WSbtw   = Weibull.Vin-Weibull.step/2:Weibull.step:Weibull.Vout+Weibull.step/2;
Weibull.CumProb = 1-exp(-(Weibull.WSbtw/Weibull.Lambda).^Weibull.k);

Weibull.WS = Weibull.Vin:Weibull.step:Weibull.Vout;
Weibull.Weight  = Weibull.CumProb(2:end)-Weibull.CumProb(1:end-1);

%%
LC.Maero       = sta.stadat.mean(sta.findSensor('Maero'),:)';%data.loads{1}(:,1);
LC.Pitch       = round(sta.stadat.mean(sta.findSensor('Pi2'),:)'/Pitch.step)*Pitch.step;
LC.WS          = sta.stadat.mean(sta.findSensor('Vhub'),:)';
LC.Omega       = sta.stadat.mean(sta.findSensor('Omega'),:)';
LC.Fthr        = sta.stadat.mean(sta.findSensor('Fthr'),:)';
LC.Paero       = max(0,LC.Maero.*LC.Omega*(pi/30));
LC.WSunique    = unique(round(LC.WS*100)/100);

% for i=1:length(AoA.Radius)
%     LC.AoA(:,i)         = sta.stadat.mean(idxAoA(i),:);
% end
LC.CT          = min(max(0,LC.Fthr./(0.5*1.225*pi*Radius^2*LC.WS.^2)*1e3),1);
LC.WakeDeficit = 1-(1-sqrt(1-LC.CT))/(1+2*Wake.k*Wake.s)^2;
LC.TSR         = LC.Omega*2*pi/60*Radius./LC.WS;

%% Check stall limits
% get thickness ratio at AoA output and check stall aoa for them
% for i=1:length(AoA.Radius)
%     AoA.TR(i) = interp1(msd.bld.Radius,msd.bld.Thickness,AoA.Radius(i));
%     AoA.Stall(i) = interp1(Stall.AoA(:,1),Stall.AoA(:,2),AoA.TR(i));
% end
% 
% for i=1:length(LC.WS)
%     LC.StallMargin(i,:) = AoA.Stall(:)-LC.AoA(i,:)';
%     if min(LC.StallMargin(i,:))<Stall.Margin
%         LC.StallOK(i) = 0;
%     else
%         LC.StallOK(i) = 1;
%     end
% end

%% Calculated electric power
gloss = [0 msd.gen.PelBinEl'
    msd.gen.RpmBinEl msd.gen.G1ElEfficiency];
mloss = [0 msd.gen.PelBinMech'
    msd.gen.RpmBinMech msd.gen.G1MechEfficiency];
auxloss = [0 msd.gen.PelBinAux'
    msd.gen.RpmBinAux msd.gen.AuxLoss];

for i=1:length(LC.Paero)
    LC.PelNoWake(i,1)=LAC.scripts.OptiTip.powerlossmodelv2(gloss,mloss,auxloss,LC.Omega(i)*GBXRatio,LC.Paero(i));
end
LC.PelWake       = LC.PelNoWake.*(1-Wake.c + Wake.c.*LC.WakeDeficit.^3);

%% Building Optimal operation point in Part 1 and Part 3

for i=1:find(Weibull.WS==Part1.MaxWS)
    Part1.WS(i) = Weibull.WS(i);
    IndexWS = LC.WS == Weibull.WS(i);
    TmpPitchUnique = unique(LC.Pitch(IndexWS));
    for j=1:length(TmpPitchUnique)
        IndexWSPitch = LC.WS==Weibull.WS(i) & LC.Pitch==TmpPitchUnique(j);
        if isempty(find(IndexWSPitch, 1)) % This case should not happen
            return;
        elseif length(find(IndexWSPitch))==1 % If LC at given WS and Pitch was run at only one rotor speed
            % Check rotor speed with rotor speed step
            TmpRotorStep = round(OptiLambda.Step*60/(2*pi*Radius)*Weibull.WS(i)*100)/100;
            if abs(LC.Omega(IndexWSPitch)-GRPM.min/GBXRatio) < TmpRotorStep
                TmpPelWake(j) = LC.PelWake(IndexWSPitch);
                TmpPelNoWake(j) = LC.PelNoWake(IndexWSPitch);
                TmpMaero(j) = LC.Maero(IndexWSPitch);
                TmpFthr(j) = LC.Fthr(IndexWSPitch);
%                 TmpStallMargin(j,:) = LC.StallMargin(IndexWSPitch,:);
%                 if min(TmpStallMargin(j,:))<Stall.Margin
%                     TmpStallOK(j) = 0;
%                 else
%                     TmpStallOK(j) = 1;
%                 end
            end
        else
            TmpPelWake(j) = interp1(LC.Omega(IndexWSPitch),LC.PelWake(IndexWSPitch),GRPM.min/GBXRatio);
            TmpPelNoWake(j) = interp1(LC.Omega(IndexWSPitch),LC.PelNoWake(IndexWSPitch),GRPM.min/GBXRatio);
            TmpMaero(j) = interp1(LC.Omega(IndexWSPitch),LC.Maero(IndexWSPitch),GRPM.min/GBXRatio);
            TmpFthr(j) = interp1(LC.Omega(IndexWSPitch),LC.Fthr(IndexWSPitch),GRPM.min/GBXRatio);
%             for k=1:length(AoA.Radius)
%                 TmpStallMargin(j,k) = interp1(LC.Omega(IndexWSPitch),LC.StallMargin(IndexWSPitch,k),GRPM.min/GBXRatio);
%             end
%             if min(TmpStallMargin(j,:))<Stall.Margin
%                 TmpStallOK(j) = 0;
%             else
%                 TmpStallOK(j) = 1;
%             end
        end
        
    end
    Part1.Opt.Constraint{i} = '';
%     IndexStallOK = find(TmpStallOK == 1);
%     if isempty(IndexStallOK)
%         TmpMinMargin = min(TmpStallMargin,[],2);
%         [~,TmpIndex] = max(TmpMinMargin);
%         Part1.Opt.PelWake(i) = TmpPelWake(TmpIndex);
%         Part1.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
%         Part1.Opt.Maero(i) = TmpMaero(TmpIndex);
%         Part1.Opt.Fthr(i) = TmpFthr(TmpIndex);
%         Part1.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
%         Part1.Opt.StallMargin(i,:) = TmpStallMargin(TmpIndex,:);
%         Part1.Opt.StallOK(i) = 0;
%         Part1.Opt.TSR(i) = GRPM.min/GBXRatio*2*pi/60*Radius./Part1.WS(i);
%         Part1.Opt.GRPM(i) = GRPM.min;
%         Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Stall margins not fulfilled (Margin to stall:',num2str(min(Part1.Opt.StallMargin(i,:)),'%.2f'),'°). '];
%         if Part1.Opt.Pitch(i) == max(TmpPitchUnique) || Part1.Opt.Pitch(i) == min(TmpPitchUnique)
%             Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
%         end
%     else
%         [Part1.Opt.PelWake(i),TmpIndex] = max(TmpPelWake(IndexStallOK));
%         Part1.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
%         TmpIndex = IndexStallOK(TmpIndex);
%         Part1.Opt.Maero(i) = TmpMaero(TmpIndex);
%         Part1.Opt.Fthr(i) = TmpFthr(TmpIndex);
%         Part1.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
%         Part1.Opt.StallMargin(i,:) = TmpStallMargin(TmpIndex,:);
%         Part1.Opt.StallOK(i) = 1;
%         Part1.Opt.TSR(i) = GRPM.min/GBXRatio*2*pi/60*Radius./Part1.WS(i);
%         Part1.Opt.GRPM(i) = GRPM.min;
%         if Part1.Opt.PelWake(i)<max(TmpPelWake)
%             Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Constrained by margin to stall(Margin to stall: ',num2str(min(Part1.Opt.StallMargin(i,:)),'%.2f'),'°). '];
%         else
%             Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Margin to stall: ',num2str(min(Part1.Opt.StallMargin(i,:)),'%.2f'),'°. '];
%         end
%         if Part1.Opt.Pitch(i) == max(TmpPitchUnique) || Part1.Opt.Pitch(i) == min(TmpPitchUnique)
%             Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
%         end
%     end
    % -- VLLEB
    [~,TmpIndex] = max(TmpPelWake);
    Part1.Opt.PelWake(i) = TmpPelWake(TmpIndex);
    Part1.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
    Part1.Opt.Maero(i) = TmpMaero(TmpIndex);
    Part1.Opt.Fthr(i) = TmpFthr(TmpIndex);
    Part1.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
    Part1.Opt.TSR(i) = GRPM.min/GBXRatio*2*pi/60*Radius./Part1.WS(i);
    Part1.Opt.GRPM(i) = GRPM.min;
    if Part1.Opt.Pitch(i) == max(TmpPitchUnique) || Part1.Opt.Pitch(i) == min(TmpPitchUnique)
        Part1.Opt.Constraint{i} = [Part1.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
    end
    
    clear TmpPitchUnique TmpPelWake TmpPelNoWake TmpMaero TmpFthr TmpStallMargin TmpStallOK TmpAoA TmpIndex;
end

for i=find(Weibull.WS==Part3.MinWS):find(Weibull.WS==max(LC.WS))
    Part3.WS(i) = Weibull.WS(i);
    IndexWS = LC.WS == Weibull.WS(i);
    TmpPitchUnique = unique(LC.Pitch(IndexWS));
    for j=1:length(TmpPitchUnique)
        IndexWSPitch = LC.WS==Weibull.WS(i) & LC.Pitch==TmpPitchUnique(j);
        if isempty(find(IndexWSPitch, 1)) % This case should not happen
            return;
        elseif length(find(IndexWSPitch))==1 % If LC at given WS and Pitch was run at only one rotor speed
            % Check rotor speed with rotor speed step
            TmpRotorStep = round(OptiLambda.Step*60/(2*pi*Radius)*Weibull.WS(i)*100)/100;
            if abs(LC.Omega(IndexWSPitch)-GRPM.max/GBXRatio) < TmpRotorStep
                TmpPelWake(j) = LC.PelWake(IndexWSPitch);
                TmpPelNoWake(j) = LC.PelNoWake(IndexWSPitch);
                TmpMaero(j) = LC.Maero(IndexWSPitch);
                TmpFthr(j) = LC.Fthr(IndexWSPitch);
%                 for k=1:length(AoA.Radius)
%                     TmpStallMargin(j,k) = LC.StallMargin(IndexWSPitch,k);
%                 end
%                 if min(TmpStallMargin(j,:))<Stall.Margin
%                     TmpStallOK(j) = 0;
%                 else
%                     TmpStallOK(j) = 1;
%                 end
            end
        else
            TmpPelWake(j) = interp1(LC.Omega(IndexWSPitch),LC.PelWake(IndexWSPitch),GRPM.max/GBXRatio);
            TmpPelNoWake(j) = interp1(LC.Omega(IndexWSPitch),LC.PelNoWake(IndexWSPitch),GRPM.max/GBXRatio);
            TmpMaero(j) = interp1(LC.Omega(IndexWSPitch),LC.Maero(IndexWSPitch),GRPM.max/GBXRatio);
            TmpFthr(j) = interp1(LC.Omega(IndexWSPitch),LC.Fthr(IndexWSPitch),GRPM.max/GBXRatio);
%             for k=1:length(AoA.Radius)
%                 TmpStallMargin(j,k) = interp1(LC.Omega(IndexWSPitch),LC.StallMargin(IndexWSPitch,k),GRPM.max/GBXRatio);
%             end
%             if min(TmpStallMargin(j,:))<Stall.Margin
%                 TmpStallOK(j) = 0;
%             else
%                 TmpStallOK(j) = 1;
%             end
        end
        
    end
    Part3.Opt.Constraint{i} = '';
%     IndexStallOK = find(TmpStallOK == 1);
%     if isempty(IndexStallOK)
%         TmpMinMargin = min(TmpStallMargin,[],2);
%         [~,TmpIndex] = max(TmpMinMargin);
%         Part3.Opt.PelWake(i) = TmpPelWake(TmpIndex);
%         Part3.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
%         Part3.Opt.Maero(i) = TmpMaero(TmpIndex);
%         Part3.Opt.Fthr(i) = TmpFthr(TmpIndex);
%         Part3.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
%         Part3.Opt.StallMargin(i,:) = TmpStallMargin(TmpIndex,:);
%         Part3.Opt.StallOK(i) = 0;
%         Part3.Opt.TSR(i) = GRPM.max/GBXRatio*2*pi/60*Radius./Part3.WS(i);
%         Part3.Opt.GRPM(i) = GRPM.max;
%         Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Stall margins not fulfilled (Margin to stall:',num2str(min(Part3.Opt.StallMargin(i,:)),'%.2f'),'°). '];
%         if Part3.Opt.Pitch(i)==max(TmpPitchUnique) || Part3.Opt.Pitch(i)==min(TmpPitchUnique)
%             Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
%         end
%     else
%         [Part3.Opt.PelWake(i),TmpIndex] = max(TmpPelWake(IndexStallOK));
%         Part3.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
%         TmpIndex = IndexStallOK(TmpIndex);
%         Part3.Opt.Maero(i) = TmpMaero(TmpIndex);
%         Part3.Opt.Fthr(i) = TmpFthr(TmpIndex);
%         Part3.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
%         Part3.Opt.StallMargin(i,:) = TmpStallMargin(TmpIndex,:);
%         Part3.Opt.StallOK(i) = 1;
%         Part3.Opt.TSR(i) = GRPM.max/GBXRatio*2*pi/60*Radius./Part3.WS(i);
%         Part3.Opt.GRPM(i) = GRPM.max;
%         if Part3.Opt.PelWake(i)<max(TmpPelWake)
%             Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Constrained by margin to stall(Margin to stall: ',num2str(min(Part3.Opt.StallMargin(i,:)),'%.2f'),'°). '];
%         else
%             Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Margin to stall: ',num2str(min(Part3.Opt.StallMargin(i,:)),'%.2f'),'°. '];
%         end
%         if Part3.Opt.Pitch(i)==max(TmpPitchUnique) || Part3.Opt.Pitch(i)==min(TmpPitchUnique)
%             Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
%         end
%     end
    % -- VLLEB
    [~,TmpIndex] = max(TmpPelWake);
    Part3.Opt.PelWake(i) = TmpPelWake(TmpIndex);
    Part3.Opt.PelNoWake(i) = TmpPelNoWake(TmpIndex);
    Part3.Opt.Maero(i) = TmpMaero(TmpIndex);
    Part3.Opt.Fthr(i) = TmpFthr(TmpIndex);
    Part3.Opt.Pitch(i) = TmpPitchUnique(TmpIndex);
    Part3.Opt.TSR(i) = GRPM.max/GBXRatio*2*pi/60*Radius./Part3.WS(i);
    Part3.Opt.GRPM(i) = GRPM.max;
    if Part3.Opt.Pitch(i) == max(TmpPitchUnique) || Part3.Opt.Pitch(i) == min(TmpPitchUnique)
        Part3.Opt.Constraint{i} = [Part3.Opt.Constraint{i},'Limited by max or min pitch simulated [',num2str(min(TmpPitchUnique)),' / ',num2str(max(TmpPitchUnique)),'°]. '];
    end

    clear TmpPitchUnique TmpPelWake TmpPelNoWake TmpMaero TmpFthr TmpStallMargin TmpStallOK TmpAoA TmpIndex;
end

%% Optimisation: loop on OptiLambda and pitch at OptiLambda

N_TSR = length(OptiLambda.Range);
N_Pitch = length(OptiLambda.PitchRange);

WeightedPower = zeros(N_TSR,N_Pitch);
WeightedPowerNoWake = zeros(N_TSR,N_Pitch);

for i=1:N_TSR
    for j=1:length(Weibull.WS)
        OptiSpeed = OptiLambda.Range(i)*GBXRatio*60*Weibull.WS(j)/(2*pi*Radius);
        if OptiSpeed<=GRPM.min % In Part 1
            % --- VLLEB shouldn't it be index = find(Part1.WS == Weibull.WS(j)); ????
            % --- otherwise index is logical and not index
            index = Part1.WS == Weibull.WS(j);
            WeightedPower(i,:)                  = WeightedPower(i,:) + ones(1,N_Pitch)*(Weibull.Weight(j)*min(Part1.Opt.PelWake(index),RatedPower));
            WeightedPowerNoWake(i,:)            = WeightedPowerNoWake(i,:) + ones(1,N_Pitch)*(Weibull.Weight(j)*min(Part1.Opt.PelNoWake(index),RatedPower));
            for k=1:N_Pitch
                OpPoint(i,k).WS(j)          = Weibull.WS(j);
                OpPoint(i,k).Pitch(j)       = Part1.Opt.Pitch(index);
                OpPoint(i,k).TSR(j)         = Part1.Opt.TSR(index);
%                 OpPoint(i,k).StallOK(j)     = Part1.Opt.StallOK(index);
                OpPoint(i,k).Fthr(j)        = Part1.Opt.Fthr(index);
                OpPoint(i,k).GRPM(j)        = Part1.Opt.GRPM(index);
                OpPoint(i,k).PelWake(j)     = Part1.Opt.PelWake(index);
                OpPoint(i,k).PelNoWake(j)   = Part1.Opt.PelNoWake(index);
                OpPoint(i,k).Constraint{j}  = Part1.Opt.Constraint{index};
%                 OpPoint(i,k).StallMargin(j,:) = Part1.Opt.StallMargin(index,:);
                OpPoint(i,k).Mode(j)        = 1; % LC1
            end
        elseif OptiSpeed>=GRPM.max % In Part 3
            index = Part3.WS == Weibull.WS(j);
            WeightedPower(i,:)              = WeightedPower(i,:) + ones(1,N_Pitch)*(Weibull.Weight(j)*min(Part3.Opt.PelWake(index),RatedPower));
            WeightedPowerNoWake(i,:)        = WeightedPowerNoWake(i,:) + ones(1,N_Pitch)*(Weibull.Weight(j)*min(Part3.Opt.PelNoWake(index),RatedPower));
            for k=1:N_Pitch
                OpPoint(i,k).WS(j)          = Weibull.WS(j);
                OpPoint(i,k).Pitch(j)       = Part3.Opt.Pitch(index);
                OpPoint(i,k).TSR(j)         = Part3.Opt.TSR(index);
%                 OpPoint(i,k).StallOK(j)     = Part3.Opt.StallOK(index);
                OpPoint(i,k).Fthr(j)        = Part3.Opt.Fthr(index);
                OpPoint(i,k).GRPM(j)        = Part3.Opt.GRPM(index);
                OpPoint(i,k).PelWake(j)     = Part3.Opt.PelWake(index);
                OpPoint(i,k).PelNoWake(j)   = Part3.Opt.PelNoWake(index);
                OpPoint(i,k).Constraint{j}  = Part3.Opt.Constraint{index};
%                 OpPoint(i,k).StallMargin(j,:) = Part3.Opt.StallMargin(index,:);
                OpPoint(i,k).Mode(j)        = 3; % LC3
            end
        else % Part 2
            for k=1:N_Pitch
                index = (LC.WS==Weibull.WS(j)) & (round(LC.Pitch/Pitch.step)*Pitch.step==round(OptiLambda.PitchRange(k)/Pitch.step)*Pitch.step);
                switch length(find(index))
                    case 0 % No simulations match the required TSR and pitch
                        error('No simulations match the required TSR and pitch!');

                    case 1 % Only one simulations match the combination of TSR and pitch
                        error('Only one simulations match the combination of TSR and pitch!');
                    otherwise
%                         OpPoint(i,k).StallOK(j)     = interp1(LC.TSR(index),LC.StallOK(index),OptiLambda.Range(i)); % COULD BE IMPROVED
                        WeightedPower(i,k)          = WeightedPower(i,k) + Weibull.Weight(j)*min(interp1(LC.TSR(index),LC.PelWake(index),OptiLambda.Range(i)),RatedPower);
                        WeightedPowerNoWake(i,k)    = WeightedPowerNoWake(i,k) + Weibull.Weight(j)*min(interp1(LC.TSR(index),LC.PelNoWake(index),OptiLambda.Range(i)),RatedPower);
                        OpPoint(i,k).WS(j)          = Weibull.WS(j);
                        OpPoint(i,k).Pitch(j)       = OptiLambda.PitchRange(k);
                        OpPoint(i,k).TSR(j)         = OptiLambda.Range(i);
                        OpPoint(i,k).Fthr(j)        = interp1(LC.TSR(index),LC.Fthr(index),OptiLambda.Range(i));
                        OpPoint(i,k).GRPM(j)        = interp1(LC.TSR(index),LC.Omega(index),OptiLambda.Range(i))*GBXRatio;
                        OpPoint(i,k).PelWake(j)     = interp1(LC.TSR(index),LC.PelWake(index),OptiLambda.Range(i));
                        OpPoint(i,k).PelNoWake(j)   = interp1(LC.TSR(index),LC.PelNoWake(index),OptiLambda.Range(i));
%                         OpPoint(i,k).StallMargin(j,:) = interp1(LC.TSR(index),LC.StallMargin(index,:),OptiLambda.Range(i));
%                         OpPoint(i,k).Constraint{j}  = ['Margin to stall:',num2str(min(OpPoint(i,k).StallMargin(j,:)),'%.2f'),'°. '];
                        OpPoint(i,k).Mode(j)        = 2; % LC2
                end
            end
        end
    end
end

% Check stall margins in the 3 steps
% for i=1:size(OpPoint,1)% tsr
%     for k=1:size(OpPoint,2) % pitch
%         LC1StallOK(i,k) = min(min(OpPoint(i,k).StallMargin(OpPoint(i,k).Mode==1,:))); % VLLEB fixed to be like LC2
%         LC2StallOK(i,k) = min(min(OpPoint(i,k).StallMargin(OpPoint(i,k).Mode==2,:)));
%         LC3StallOK(i,k) = min(min(OpPoint(i,k).StallMargin(OpPoint(i,k).Mode==3,:))); % VLLEB fixed to be like LC2
%     end
% end

% Select max AEP for LC2 stall OK
% WeightedPowerStallOK = WeightedPower;
% WeightedPowerStallOK(LC2StallOK<Stall.Margin) = 0;
% [MaxPower,index] = max(WeightedPowerStallOK(:));
% [IndexOptiLambda,IndexOptiPitch] = ind2sub(size(WeightedPowerStallOK),index);
% VLLEB
[MaxPower,index] = max(WeightedPower(:));
[IndexOptiLambda,IndexOptiPitch] = ind2sub(size(WeightedPower),index);

OptiLambda.OptiPitch   = OptiLambda.PitchRange(IndexOptiPitch);
OptiLambda.OptiLambda  = OptiLambda.Range(IndexOptiLambda);

% Check constraints on Step2
OptiLambdaConstraints = '';
if MaxPower<max(WeightedPower(:))
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', Not in max Power'];
else
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', Max Power'];
end
if OptiLambda.OptiPitch==max(OptiLambda.PitchRange)
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', OptiPitch is max simulated pitch'];
end
if OptiLambda.OptiPitch==min(OptiLambda.PitchRange)
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', OptiPitch is min simulated pitch'];
end
if OptiLambda.OptiLambda==max(OptiLambda.Range)
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', OptiLambda is max simulated TSR'];
end
if OptiLambda.OptiLambda==min(OptiLambda.Range)
    OptiLambdaConstraints = [ OptiLambdaConstraints, ', OptiLambda is min simulated TSR'];
end
    
    
% Add something is constrained by stall %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
subplot(211); hold on; grid on; box on;
plot(OpPoint(IndexOptiLambda,IndexOptiPitch).WS,OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch);
subplot(212); hold on; grid on; box on;
plot(OpPoint(IndexOptiLambda,IndexOptiPitch).WS,OpPoint(IndexOptiLambda,IndexOptiPitch).TSR);

figure
plot(OpPoint(IndexOptiLambda,IndexOptiPitch).TSR,OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch)

% disp([OpPoint(IndexOptiLambda,IndexOptiPitch).TSR' OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch']);

%% VLLEB interpolate results
% --- include exact OptiLambda in OTC
% --- for this, shift Starting OTC point
dist = abs(Ref.OptiTip.TSR-OptiLambda.OptiLambda);
j=find(min(dist)==dist,1);
Ref.OptiTip.TSR(j)=OptiLambda.OptiLambda;
% --- find unique values
[Targ_lambda, index] = unique(OpPoint(IndexOptiLambda,IndexOptiPitch).TSR');
Targ_pitch = OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch(index)';
% --- inteporlate
TargPitch_interp = interp1(Targ_lambda,Targ_pitch,Ref.OptiTip.TSR,'pchip','extrap');
% --- fix interpolation for HIGH lambdas
j=find(Ref.OptiTip.TSR>max(Targ_lambda));
for i=j
    TargPitch_interp(1,i)=Ref.OptiTip.Pitch(1,i)+TargPitch_interp(1,i-1)-Ref.OptiTip.Pitch(1,i-1);
end
% --- fix interpolation for LOW lambdas
j=find(Ref.OptiTip.TSR<min(Targ_lambda));
% reverse order
j = fliplr(j);
for i=j
    % --- removed due to high pitch angles in some cases. Kept only delta
    % --- based extrapolation.
%     if(TargPitch_interp(1,i+1)>0)
%         TargPitch_interp(1,i)=TargPitch_interp(1,i+1)*Ref.OptiTip.Pitch(1,i)/Ref.OptiTip.Pitch(1,i+1);
%     else
        TargPitch_interp(1,i)=TargPitch_interp(1,i+1)+Ref.OptiTip.Pitch(1,i)-Ref.OptiTip.Pitch(1,i+1);
%     end
end


% -------------------------------------
% --- PLOT ----------------------------
% -------------------------------------
figure
hold on
plot(Ref.OptiTip.TSR,Ref.OptiTip.Pitch,'LineWidth',1);
plot(Targ_lambda,Targ_pitch,'+-','LineWidth',2);
plot(Ref.OptiTip.TSR',TargPitch_interp,'LineWidth',1,'color','k','LineWidth',2);
grid on
xlabel('Lambda')
ylabel('Pitch')
legend({'Starting','VTS max power','Resulting'});
hold off
print(fullfile(pwd,'Step_1_OTC.png'),'-dpng','-r300');
saveas(gcf,fullfile(pwd,'Step_1_OTC.fig'));
%% Writes output file
fid = fopen(OTC.Step_1.OTCfile,'w');
fprintf(fid,'%s\n',date);
fprintf(fid,'OptiLambda: %2.2f\n',OptiLambda.OptiLambda);
fprintf(fid,'OptiPitch: %2.2f\n',OptiLambda.OptiPitch);
fprintf(fid,'Constraints on OptiLambda and OptiPitch: %s\n',OptiLambdaConstraints);
fprintf(fid,'--------OptiTip-------\n');
for i=1:length(OpPoint(IndexOptiLambda,IndexOptiPitch).TSR)
    fprintf(fid,'%8.2f %8.2f\n',OpPoint(IndexOptiLambda,IndexOptiPitch).TSR(i),OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch(i));
end
fprintf(fid,'--Expected Operation--\n');
fprintf(fid,'      WS    Power    Pitch     GRPM     Fthr Constraints\n');
for i=1:length(OpPoint(IndexOptiLambda,IndexOptiPitch).TSR)
    fprintf(fid,'%8.2f %8.2f %8.2f %8.2f %8.2f %s\n',OpPoint(IndexOptiLambda,IndexOptiPitch).WS(i),OpPoint(IndexOptiLambda,IndexOptiPitch).PelNoWake(i),OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch(i),OpPoint(IndexOptiLambda,IndexOptiPitch).GRPM(i),OpPoint(IndexOptiLambda,IndexOptiPitch).Fthr(i),OpPoint(IndexOptiLambda,IndexOptiPitch).Constraint{i});
end
fprintf(fid,'--Margin to stall--\n');
fprintf(fid,'      WS   Pitch    GRPM     Margin to stall\n');
% fprintf(fid,'             Radius [m]:');
% for i=1:length(AoA.Radius)
%     fprintf(fid,'%7.2f',AoA.Radius(i));
% end
fprintf(fid,'\n');
for i=1:length(OpPoint(IndexOptiLambda,IndexOptiPitch).TSR)
    fprintf(fid,'%8.2f',OpPoint(IndexOptiLambda,IndexOptiPitch).WS(i));
    fprintf(fid,'%8.2f',OpPoint(IndexOptiLambda,IndexOptiPitch).Pitch(i));
    fprintf(fid,'%8.2f',OpPoint(IndexOptiLambda,IndexOptiPitch).GRPM(i));
%     for j=1:size(OpPoint(IndexOptiLambda,IndexOptiPitch).StallMargin,2)
%         fprintf(fid,'%7.2f',OpPoint(IndexOptiLambda,IndexOptiPitch).StallMargin(i,j));
%     end
    fprintf(fid,'\n');
end
fprintf(fid,'-- Sensitivity to OptiLambda and OptiPitch--\n');
fprintf(fid,'          Pitch \\ TSR |  %5.2f  |  %5.2f  |  %5.2f  |\n',OptiLambda.OptiLambda-OptiLambda.Step,OptiLambda.OptiLambda,OptiLambda.OptiLambda+OptiLambda.Step);
fprintf(fid,'-----------------------------------------------------\n');
for i=-1:1:1 % Loop on OptiPitch
    fprintf(fid,'AEP (Park)      |     |');
    for j=-1:1:1 %Loop on OptiLambda
        if(IndexOptiLambda+j>0 && IndexOptiPitch+i>0 && IndexOptiLambda+j<=size(WeightedPower,1) && IndexOptiPitch+i<=size(WeightedPower,2) ) % VLLEB index out of matrix FIX
            fprintf(fid,'%8.5f |',WeightedPower(IndexOptiLambda+j,IndexOptiPitch+i)/WeightedPower(IndexOptiLambda,IndexOptiPitch));
        else % VLLEB index out of matrix FIX
            fprintf(fid,' --- |'); % VLLEB index out of matrix FIX
        end % VLLEB index out of matrix FIX
    end
    fprintf(fid,'\n');
    fprintf(fid,'AEP (Free)      |%3.2f|',OptiLambda.PitchRange(IndexOptiPitch+i));
    for j=-1:1:1 %Loop on OptiLambda
        if(IndexOptiLambda+j>0 && IndexOptiPitch+i>0 && IndexOptiLambda+j<=size(WeightedPower,1) && IndexOptiPitch+i<=size(WeightedPower,2) ) % VLLEB index out of matrix FIX
            fprintf(fid,'%8.5f |',WeightedPowerNoWake(IndexOptiLambda+j,IndexOptiPitch+i)/WeightedPowerNoWake(IndexOptiLambda,IndexOptiPitch));
        else % VLLEB index out of matrix FIX
            fprintf(fid,' --- |'); % VLLEB index out of matrix FIX
        end % VLLEB index out of matrix FIX
    end
    fprintf(fid,'\n');
%     fprintf(fid,'Margin to stall |     |');
%     for j=-1:1:1 %Loop on OptiLambda
%         if(IndexOptiLambda+j>0 && IndexOptiPitch+i>0 && IndexOptiLambda+j<=size(WeightedPower,1) && IndexOptiPitch+i<=size(WeightedPower,2) ) % VLLEB index out of matrix FIX
%             fprintf(fid,'%8.2f |',min(min(OpPoint(IndexOptiLambda+j,IndexOptiPitch+i).StallMargin(OpPoint(IndexOptiLambda+j,IndexOptiPitch+i).Mode==2,:))));
%         else % VLLEB index out of matrix FIX
%             fprintf(fid,' --- |'); % VLLEB index out of matrix FIX
%         end % VLLEB index out of matrix FIX
%     end
%     fprintf(fid,'\n');
    fprintf(fid,'-----------------------------------------------------\n');
end
fprintf(fid,'--------OptiTip CONTROLLER-------\n');
for i=1:length(Ref.OptiTip.TSR)
    fprintf('Px_OTC_TableLambdaToPitchOptX%02d =\t%2.2f\n',i,Ref.OptiTip.TSR(i));   
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptX%02d =\t%2.2f\n',i,Ref.OptiTip.TSR(i));   
end
for i=1:length(TargPitch_interp)
    fprintf('Px_OTC_TableLambdaToPitchOptY%02d =\t%2.2f\n',i,TargPitch_interp(i)); 
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptY%02d =\t%2.2f\n',i,TargPitch_interp(i));
end
fprintf('Px_SC_PartLoadLambdaOpt =\t%2.2f\n',OptiLambda.OptiLambda);
fprintf(fid,'Px_SC_PartLoadLambdaOpt =\t%2.2f\n',OptiLambda.OptiLambda);
fprintf(fid,'-----------------------------------------------------\n');
fclose(fid);


%
