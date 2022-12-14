function [DLC13,Frq,Extremes,ExtremesSorted,NonExceedanceProb,flag] = LoadExtrapolationLoadExtremesEdge(SimPath,PathDLC11,PathDLC13,Options,Sensors,check_NTM,check_ETM)
DLC13 = []; Frq = []; Extremes = []; ExtremesSorted = []; NonExceedanceProb = []; flag = [0 0];

%% Read extremes from sta files if only one extreme per time series is required, or int files if more than 1 extreme is required
if ~strcmpi(PathDLC11,'')
    if check_NTM ~= 2
        disp(['WARNING: No ' Options.SaveDLC11 ' found in:'])
        disp(SimPath)
        disp('DLC 11 extremes will be extracted from:')
        disp(PathDLC11)
        fprintf('\n')
        [Frq,Extremes] = ExtractExtremes(PathDLC11,Sensors,Options);
        %% Distribution probability
        PSeed=Frq/sum(Frq); % Probability of the i'th seed.
        PSeedSorted = zeros(size(Extremes));
        ExtremesSorted = zeros(size(Extremes));
        NonExceedanceProb = zeros(size(ExtremesSorted,1),size(Extremes,2));
        for i=1:size(Extremes,2)    % Loop on sensors
            % Sorting Extremes in ascending order
            [DataSorted]=sortrows([Extremes(:,i) PSeed],1);
            PSeedSorted(:,i) = DataSorted(:,2);
            ExtremesSorted(:,i) = DataSorted(:,1);
            
            % Define non exceedance probability
            for k=1:size(ExtremesSorted,1)
                idat = ExtremesSorted(:,i) < ExtremesSorted(k,i);
                NonExceedanceProb(k,i) = (idat'*PSeedSorted(:,i))^Options.NExt;
            end
        end
        flag(1) = 1;
    end
end

%% Get 1.3etm loads from frq file
if ~strcmpi(PathDLC13,'')
    if check_ETM ~= 2
        disp(['WARNING: No ' Options.SaveDLC13 ' found in:'])
        disp(SimPath)
        disp('DLC 13 extremes will be extracted from:')
        disp(PathDLC13)
        fprintf('\n')
        [DLC13] = CalculateExtremesDLC13(PathDLC13,Sensors);
        flag(2) = 1;
    end
end

end


function [Frq,Extremes] = ExtractExtremes(PathDLC11,Sensors,Options)
if Options.NExt ==1
    PathHere = pwd;
    dat=MatStat(PathDLC11,Sensors(:,1)');
    cd(PathHere);
    Frq = dat.frq;
    Extremes = zeros(length(dat.loads{1}(:,4)),length(Sensors(:,1)));
    for i=1:length(Sensors(:,1))
        Extremes(:,i)=dat.loads{i}(:,4);
    end
else
    dat.sensor = Sensors(:,1)';
    
    [C] = sensreadTL([PathDLC11(1:regexp(PathDLC11,'INPUTS')-1),'INT\sensor']);
    sensno = zeros(length(Sensors(:,1)),1); Extremes = zeros(Options.NExt,1);
    for i=1:length(Sensors(:,1))
        sensno(i) = sensNoTL(C,Sensors(i,1));
    end
    clear C
    
    [F,~] = readfrq(PathDLC11);
    
    % Matrix to multiply
    
    h=waitbar(0,'Extracting extremes in INT files...');
    for i=1:length(F.name)
        waitbar(i/length(F.name),h);
        dat.filenames((i-1)*Options.NExt+1:i*Options.NExt,1)  = F.name(i);
        Frq((i-1)*Options.NExt+1:i*Options.NExt,1)        = F.freq(i);
        [~,t,IntDat] = LAC.timetrace.int.readint([PathDLC11(1:regexp(PathDLC11,'INPUTS')-1),'INT\',F.name{i}],1,[],[],[]);
        
        NN = floor(size(IntDat,1)/Options.NExt);
        
        for j=1:length(Sensors(:,1))
            frqEdge    = SPV.User.getPeak(t,IntDat(:,sensno(j)),0.5,2);        
            edgesignal = SPV.User.butterFilt(2,[frqEdge(2)-0.15 frqEdge(2)+0.15],IntDat(:,sensno(j)),mean(diff(t)),'bandpass');

            TmpExtremes = zeros(Options.NExt,1);
            for k=1:Options.NExt
                TmpExtremes(k,1) = max(edgesignal((k-1)*NN+1:k*NN));
            end
            Extremes((i-1)*Options.NExt+1:i*Options.NExt,j) = TmpExtremes;
        end
        clear IntDat TmpExtremes
    end
    close(h);
end

end


function [DLC13] = CalculateExtremesDLC13(PathDLC13,Sensors)
C = sensreadTL([PathDLC13(1:max(strfind(PathDLC13,'INPUTS'))-1),'INT/sensor']);
DLC13SensNo = zeros(size(Sensors,1),1);
for i=1:size(Sensors,1)
    DLC13SensNo(i) = sensNoTL(C,Sensors{i,1});
end
PathHere = pwd;
DLC13.Data = MatStat(PathDLC13,DLC13SensNo,0,[],'13');
cd(PathHere);
DLC13.Families = unique(DLC13.Data.family);
for i=1:size(Sensors,1)
    for j=1:length(DLC13.Families)
        DLC13.ExtWS(i,j) = mean(DLC13.Data.loads{i}(DLC13.Data.family==DLC13.Families(j),4));
    end
    DLC13.Extremes(i) = max(DLC13.ExtWS(i,:));
end
% Maximum of 3 blades
for i=1:size(Sensors,1)
    DLC13.Extremes3B(i) = max(DLC13.Extremes([Sensors{:,2}]==Sensors{i,2}));
end
end

