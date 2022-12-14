function [DLC13,Frq,Extremes,ExtremesSorted,NonExceedanceProb,flag] = getExtrapolationLoadExtremes(matfile,nSeeds)
DLC13 = []; Frq = []; Extremes = []; ExtremesSorted = []; NonExceedanceProb = []; flag = [0 0];

%% Read extremes from sta files if only one extreme per time series is required, or int files if more than 1 extreme is required
    load(matfile)
%     idx = randi(length(Frq),nSeeds,1);
    load('idx1000.mat')
    Frq      = Frq(idx,:);
    Extremes = Extremes(idx,:);
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


