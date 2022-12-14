function [DLC11] = LoadExtrapolationDoubleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors)

% In this script an extreme event is estimated on basis of a set of
% observed data. The prediction is carried by fitting of three different
% probability distribution functions, and the expected extreme value is
% taken as the one leading to the lowest value among the functions that has
% a "least-squares-error" below a predefined level. The first fit is made
% by using a single probability distribution and the two other fit are
% "double" distributions:

% Sum of 2 distributions with the probability p and (1-p), respectively:
%       FY(y) = p*F_Y1(y) + (1-p)*F_Y2(y)
% 
% Two joint independent distributions:
%       FY(y) = F_Y1(y) + F_Y2(y) - F_Y1(y)*F_Y2(y)
% 
% Both the "Fit and Aggregate" and "Aggregate and Fit" approach is used,
% i.e. there is a total of 6 distribution fit. The following type of
% distributions can be chosen (abbreviation used is in brackets)
% Deterministic (D), Normal (N), Lognormal (LN), 2-parameter Weibull (W2),
% Gumbel (G)
% 
% All estimates of a probability distributions are made as
% least-squares-fit of ln(-ln(FY(y)), which means that it is a linear fit
% in case of a Gumbel.
%%
Py50    = 1/(50*365.25*24*6);      % corresponding probability of a return period of 50 year (for 10min simulation)

%% User Inputs
N_min = 4;              % absolute number of data points
p_FitMin = 0.1;         % relative number of data points
epsilon_FitMax = 0.3;   % maximum acceptable least-square-error for a distribution fit

% Distribution family
if max(strcmp(Options.DoubleFamily, {'N','LN','W2','G'}))
    type_FitAll = Options.DoubleFamily;
else
    type_FitAll = 'W2';
end
type_single = type_FitAll;
type_sum = type_FitAll;
type_joint = type_FitAll;

timestep = 10*60; % time step in data [sec]
Tr = 50*365.25*24*60*60; % return period for extreme estimate [years]

% End of User Inputs

%% If DNV option is checked, make sure there is only one set of DLC11, tailfit and tailfitignore
if (Options.DNV==1) && ((length(DLC11File)~=1) || (length(Options.TailFit)~=1) || (length(Options.TailFitIgnore)~=1))
    disp('ERROR : DNV option checked. Make sure that only one set of DLC11, TailFit and TailFitIgnore is input');
    return;
end
% if (Options.DNV==1)
%     for i=1:size(Sensors,1)
%         if sum([Sensors{i,3:7}])~=1
%             disp('ERROR : DNV option checked. Make sure that one and only one fitting distribution is selected in the Sensors variables.');
%             return;
%         end
%     end
% end

%% Checks that files exist
for i=1:length(DLC11File)
    if ~strcmpi(DLC11File{i}(end-3:end),'.mat') 
        DLC11File{i} = [DLC11File{i},'.mat'];
    end
    if ~exist([DLC11File{i}],'file')
        disp(['ERROR : file ',DLC11File{i},' does not exist.']);
        disp('        Use LoadExt_LoadExtremesRun.m to generate the file');
        return;
    end
end
if ~exist(DLC13File,'file')
    disp(['ERROR : file ',DLC13File,' does not exist.']);
    disp('        Use LoadExt_LoadExtremesRun.m to generate the file');
    return;
end


%% Loads data and checks sensors
% Loads DLC11 data
DLC11   = cell(length(DLC11File),1);
for i=1:length(DLC11File)
    DLC11{i} = load(DLC11File{i}); DLC11{i}.File = DLC11File{i};
    if min(strcmpi(Sensors(:,1),(DLC11{i}.Sensors(:,1))))~=1
        disp(['WARNING: Sensors are different in ',DLC11File{i}]);  % A warning is prompted if sensors in DLC11 are different from the ones specified in the LoadExtrapolationRun script
    end
end

% Loads DLC13 data and rearrange them
tmp                 = load(Options.SaveDLC13);
DLC13.File          = DLC13File;
DLC13.Data          = tmp.DLC13.Data;
DLC13.Families      = tmp.DLC13.Families;
DLC13.ExtWS         = tmp.DLC13.ExtWS;
DLC13.Extremes      = tmp.DLC13.Extremes;
DLC13.Extremes3B    = tmp.DLC13.Extremes3B;
DLC13.Sensors       = tmp.Sensors;
DLC13.PathDLC13     = tmp.PathDLC13;
if min(strcmpi(Sensors(:,1),(DLC13.Sensors(:,1))))~=1
    disp(['WARNING: Sensors are different in ',DLC13File{i}]); % A warning is prompted if sensors in DLC13 are different from the ones specified in the LoadExtrapolationRun script
end


%% Creates a folder if figures have to be saved
if Options.SaveFigs == 1
    FolderFigs = [SimPath 'Figures_' Options.NameStr '_DoubleD'];
    mkdir(FolderFigs);
end

%% Preparation for plots
TmpPlotFandA.fig(size(Sensors,1)).Legends = {};
TmpPlotFandA.fig(size(Sensors,1)).p = [];
TmpPlotAandF.fig(size(Sensors,1)).Legends = {};
TmpPlotAandF.fig(size(Sensors,1)).p = [];
if Options.DNV ==1 % If plots are made to send to DNV, then DLC1.3 loads are not plotted, and extremes where fitting is applied are not highlighted. All plots will be black.
    Options.HighlightFitting = 0;
    Options.PlotDLC13 = 0;
end

%% Fitting
% Number of the sensor for which the fitting is carried out:
for sensor = 1:size(DLC13.Sensors,1)
    iSensor = sensor;
    fprintf('Fitting load %s...\n', Sensors{iSensor});    
    %% Checks
    if ~exist('iSensor','var')
        error(message('User must enter the number of the sensor for the fitting to be applied to.'))
    elseif ~exist('N_min','var')
        error(message('N_min must define the absolute number of data points.'))
    elseif ~exist('p_FitMin','var')
        error(message('p_FitMin must define the relative number of data points.'))
    elseif ~exist('epsilon_FitMax','var')
        error(message('epsilon_FitMax must define the maximum acceptable least-square-error for a distribution fit.'))
    elseif ~exist('type_FitAll','var')
        error(message('type_FitAll must define the distribution type to be used for fitting.'))
    end
    %% Extreme Load Input
    load(DLC11{1,1}.File,'PathDLC11');   
    stapostmat = load([PathDLC11 filesep 'stapost.mat']);
    data = num2cell(DLC11{1,1}.Extremes);
%Leo change:
%   data = [data stapostmat.export.stadat.filenames'];
    for i = 1:size(data,1)
        file_names(i) = stapostmat.export.stadat.filenames(ceil(i/Options.NExt));  
    end;
    data = [data file_names'];
    
    ExtremesSorted = DLC11{1,1}.ExtremesSorted;
    NonExceedanceProb = DLC11{1,1}.NonExceedanceProb;
    TailFit = Options.TailFit(1);
    TailFitIgnore = Options.TailFitIgnore(1);

    NTailBegin  = max(find(NonExceedanceProb(:,iSensor)<1-TailFit,1,'last'));
    NTailEnd    = max(find(NonExceedanceProb(:,iSensor)<1-TailFitIgnore,1,'last'));

    i_freq = 1; % Col num 
    % Number of loads for each wind speed 
    i=1;
    while DLC11{1,1}.Frq(i) == DLC11{1,1}.Frq(1)
       i = i+1;
    end
    N_y0 = i-1;
    % Number of sensors
    num_sensors = size(DLC11{1,1}.Sensors,1);
    % Choose number of load cases to be considered if only a reduced number
    % should be analyzed (to reduce calculation time):
    N_dlc = size(data,1)/N_y0;

    % Number of the first load case to be applied:
    i_DLC = 1;
    % Chose number of data points per load case if only a reduced number should
    % be analyzed (e.g. for sensitivity study):
    N_y = round(N_y0);
    dj = floor(N_y0/N_y);

    % Extreme loads are assigned to the variable x:
    headings = {'sim' 'value'};
    for i = 1:N_dlc
        for j = 1:N_y
            val = data{N_y0*(i_DLC+i-2)+j*dj, iSensor};
            id = data{N_y0*(i_DLC+i-2)+j*dj, num_sensors+i_freq};
            x(j,i) = cell2struct({id val},headings,2);
        end
    end

    % The probability for each load case is assigned to the variable p:
    probabilities=DLC11{1,1}.Frq/sum(DLC11{1,1}.Frq);
    for i = 1:N_dlc
        val = probabilities(N_y0*(i_DLC+i-2)+2, i_freq);
        id = data{N_y0*(i_DLC+i-2)+1, num_sensors+i_freq};
        p_struct(i) = cell2struct({id val},headings,2);
    end

    % The probabilities are normalized so the sum is equal to 1 (... just to
    % ensure that it is 1):
    p = num2cell([p_struct.value]/sum([p_struct.value]));
    [p_struct.value] = p{:};

    % The extreme loads are sorted in ascending order:
    x_sorted = sortMultiDimStruct(x);
    x_temp=zeros(size(x_sorted));
    for i=1:size(x_sorted,2)
        x_temp(:,i)=[x_sorted(:,i).value]';
    end

    % Some loads might be identical which makes it impossible to find the
    % probability of exceedance from the empirical probability distribution by
    % using the built-in interpolation functions. Consequently, a small delta
    % is added to make them different.
    % x_sorted = Ascend(x_sorted);

    % Number of outliers for each load case
    numberOfOutliers = zeros(1,size(x_temp,2));
    % Outliers contains the simulations (first column) and values (second
    % column) detected as outliers in Grubb's test
    Outliers = {};
    GrubbsInfo.Confidence = Options.OutliersConfidence;
    GrubbsInfo.Sensor{iSensor} = Sensors{iSensor};
    for i = 1:size(x_temp,2)
        if Options.OutliersConfidence > 0
            numberOfOutliers(i) = N_outliers(x_temp(:,i),N_min,Options.OutliersConfidence);
        else
            numberOfOutliers(i) = 0;
        end
        if numberOfOutliers(i)
            for ii=1:numberOfOutliers(i)
                Outliers{end+1,1} = x_sorted(end+1-ii,i).sim;
                Outliers{end,2} = x_sorted(end+1-ii,i).value;
            end
        end
    end
    if (Options.OutliersConfidence > 0) && (size(Outliers,1) >1)
        Outliers = sortrows(Outliers,1);
        GrubbsInfo.Seeds{iSensor}  = Outliers(:,1);
    else
        GrubbsInfo.Seeds{iSensor}  = [];
    end
    
    % A linear transformation is made of the extremes x to a variable y with a
    % given minimum value and mean to make the applied procedures more stable.
    % Minimum value and mean:
    yy_min = 0.1;
    mu_y = 3;

    % Determination of the two variables which defines the linear
    % transformation from the requirement to have the above minimum value and
    % mean:

    for i = 1:size(x_temp,2)  
        xx = NoOut(x_temp(:,i),numberOfOutliers(i));
        mu_x(i) = mean(xx{1});
        sigma_x(i) = std(xx{1},1);
        eta_x(i) = LAC.statistic.skewness(xx{1});
        k_w(i) = min(k_w3(eta_x(i)),10);
    end
    
    a_yx = mu_x - sigma_x.*gamma(1+1./k_w)./sqrt(gamma(1+2./k_w) - gamma(1+1./k_w).^2);
    a_yx = a_yx';
    x_min = min(x_temp)';
    a_yx = min(a_yx, x_min - yy_min);
    b_yx = (mu_x' - a_yx)./mu_y; 
    y=zeros(size(x_temp));
    for i = 1:size(x_temp,1)
        y(i,:) = ((x_temp(i,:)' - a_yx)./b_yx)';
    end

    %% Fit and Aggregate
    disp('Running Fit and Aggregate method...')
    %Execution of the fitting of the probability distribution
    %Empirical probability distribution for maxima
    j=(1:size(x_sorted,1))';
    a_MR = 0.3;
    b_MR = 1 - 2*a_MR;
    Fy = (j - a_MR)./(N_y + b_MR);
    Fy = Fy.^Options.NExt;

    % Transformed "probability distribution" used for fitting:
    ln_Fy = -log(-log(Fy));

    % Minimum number of data points required for a fit of a distribution:
    N_min_sum = max(N_min, round(p_FitMin*N_y));
    N_min_joint = max(N_min, round(p_FitMin*N_y));

    % Fit of a single distribution
    A_single = SingleFit(type_single,0,NoOut(y,numberOfOutliers),NoOut(Fy,numberOfOutliers));
    epsilon_single1 = epsilon_Single(type_single,A_single,NoOut(y,numberOfOutliers),Fy);
    rho_single1 = rho_Single(type_single,A_single,NoOut(y,numberOfOutliers),Fy);
    % Fit of the sum of distributions
    epsilon_CutMax = 2;
    FitCheck = 1;
    for ii = 1:size(y,2)
        A_sum(:,ii) = SumFitIte(type_sum,NoOut(y(:,ii),numberOfOutliers(ii)),NoOut(Fy,numberOfOutliers(ii)),N_min_sum,p_FitMin,epsilon_FitMax,epsilon_CutMax,FitCheck);
    end
    epsilon_sum1 = A_sum(end-1,:)';
    rho_sum1 = A_sum(end,:)';
    % Fit of joint distribution
    for ii = 1:size(y,2)
        A_joint(:,ii) = JointFitIte(type_joint,type_sum,NoOut(y(:,ii),numberOfOutliers(ii)),NoOut(Fy,numberOfOutliers(ii)),N_min_joint,A_sum(:,ii),epsilon_FitMax,FitCheck);
    end
    epsilon_joint1 = A_joint(end-1,:)';
    rho_joint1 = A_joint(end,:)';
    
    % Aggregation of fit
    % Number of maxima within the considered return period for the extrapolated extreme load:
    NR = Tr/timestep;
    %Probability of load being less than the extrapolated load:
    FR=1-1/NR;
    %Determination of the extrapolated load for the different distribution fit:
    ZRsi=max([x.value]'); % initial guess
    ZRsi=quantiles(@F_Single_Aggregated,type_single,A_single,a_yx,b_yx,p,FR,ZRsi);
    ZRs=ZRsi; % initial guess
    ZRs=quantiles(@F_Sum_Aggregated,type_sum,A_sum,a_yx,b_yx,p,FR,ZRs);
    ZRj=0.8*ZRsi; % initial guess
    ZRj=quantiles(@F_Joint_Aggregated,type_joint,A_joint,a_yx,b_yx,p,FR,ZRj);

    %% Aggregate and Fit
    disp('Running Aggregate and Fit method...')
    % All the load maxima given for each load case in columns in the matrix x
    % are collected in a vector z with the length Nz. The load maxima are
    % sorted in ascending order and the original indeces rearranged
    % similarly.
    index_i=[];
    index_j=[];
    for i=1:N_dlc
        for j=1:N_y
            index_i = [index_i; i];
            index_j = [index_j; j];
        end
    end

    all_x = x_sorted(:);
    C1=num2cell(index_i);
    [all_x(:).indexi]=deal(C1{:});
    C2=num2cell(index_j);
    [all_x(:).indexj]=deal(C2{:});
    z = sortMultiDimStruct(all_x);

    index_i=[z(:).indexi]';
    index_j=[z(:).indexj]';

    N_z = size(z,1);
    % Aggregated load distribution. Note that the probability distribution
    % for y-values is the same as for the corresponding z-values: F_y = F_z
    a_MR = 0.3;
    Fz = EmpiricalDistFunction(a_MR,N_y,N_z,Options.NExt,p,index_i);

    % Transformation to a variable y with a given minimum value and mean
    % (y_min = 1, mu_y = 3)
    y_min = 1.0;
    z_min = min([z.value]);
    a_yz = (y_min*mean([z.value]) - z_min*mu_y)/(y_min-mu_y);
    b_yz = (z_min - a_yz)/y_min;
    
    % Removal of outliers
    A = removeOutliersAggregated(z,a_yz,b_yz,Fz,index_i,index_j,N_y,numberOfOutliers); % y0 = A(:,1); Fy0 = A(:,2);
    
    % To reduce the calculation time and to ensure a higher weighting of
    % the data points at the upper tail, the distribution fit is only made
    % for a subset of the data. The subset is selected so the discrete
    % values of -ln(-ln(F_y)) are equidistant.
    dln_ln_Fy = 0.05;   
    residual = getSubsetOfData([A.y]',[A.Fy]',dln_ln_Fy); % y = residual(:,1); Fy = residual(:,2); index_DFz = residual(:,3);
       
    a_MR = a_MR_fit(type_sum,A_sum,type_joint,A_joint,a_yx,b_yx,z,N_y,N_z,Options.NExt,p,index_i,index_j,residual(:,3),numberOfOutliers);
    a_MR = min(max(0.0,a_MR),0.5);

    % Update of aggregated distribution function according to the calculated
    % value of a_MR and the corresponding data to be used for the fitting
    Fz = EmpiricalDistFunction(a_MR,N_y,N_z,Options.NExt,p,index_i);
    A = removeOutliersAggregated(z,a_yz,b_yz,Fz,index_i,index_j,N_y,numberOfOutliers); 
    residual = getSubsetOfData([A.y]',[A.Fy]',dln_ln_Fy);  
    
    % Errors for "fit and aggregate" distributions
    err = 0.0;
    epsilon_single = epsilon_fit(type_single,@F_Single_Aggregated,A_single,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
    epsilon_sum = epsilon_fit(type_sum,@F_Sum_Aggregated,A_sum,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
    epsilon_joint = epsilon_fit(type_joint,@F_Joint_Aggregated,A_joint,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);

    if (epsilon_sum > epsilon_FitMax) && (epsilon_joint > epsilon_FitMax) && (a_MR < 0.0) %!!!!!!!!!!!!!!!!!!!!!!! 
        a_MR = 0.5;
        Fz = EmpiricalDistFunction(a_MR,N_y,N_z,Options.NExt,p,index_i);
        A = removeOutliersAggregated(z,a_yz,b_yz,Fz,index_i,index_j,N_y,numberOfOutliers); 
        residual = getSubsetOfData([A.y]',[A.Fy]',dln_ln_Fy);
        epsilon_single = epsilon_fit(type_single,@F_Single_Aggregated,A_single,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
        epsilon_sum = epsilon_fit(type_sum,@F_Sum_Aggregated,A_sum,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
        epsilon_joint = epsilon_fit(type_joint,@F_Joint_Aggregated,A_joint,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
    end
    
    % Fitting of single distribution
    A_single0 = SingleFit(type_single,0,{residual(:,1)},{residual(:,2)});
    epsilon_single0 = epsilon_Single(type_single,A_single0,{residual(:,1)},residual(:,2));
    rho_single0 = rho_Single(type_single,A_single0,{residual(:,1)},residual(:,2));
    % Minimum number of data points for each of the distributions in the
    % sum of distributions
    N_min_sum0=max(N_min,round(p_FitMin*N_y));
    % Fitting of sum distributions
    epsilon_CutMax = 2*epsilon_FitMax;
    FitCheck = 0;
    A_sum0 = SumFitIte(type_sum,{residual(:,1)},{residual(:,2)},N_min_sum0,p_FitMin,epsilon_FitMax,epsilon_CutMax,FitCheck);
    epsilon_sum0 = A_sum0(end-1,:);
    rho_sum0 = A_sum0(end,:);
    % Minimum number of data points for each of the distributions in the
    % joint distributions
    N_min_joint0=max(N_min,round(p_FitMin*N_y));
    % Fitting of joint distribution
    FitCheck = 1;
    A_joint0 = JointFitIte(type_joint,type_sum,{residual(:,1)},{residual(:,2)},N_min_joint0,A_sum0,epsilon_FitMax,FitCheck);
    epsilon_joint0 = A_joint0(end-1,:);
    rho_joint0 = A_joint0(end,:);

    % Determination of the extrapolated load for the different distribution fit
    ZRsi0=0.9*ZRsi; % initial guess
    ZRsi0=quantiles(@F_Single_Aggregated,type_single,A_single0,a_yz,b_yz,{1},FR,ZRsi0);
    ZRs0=1.2*ZRs; % initial guess
    if rho_sum0 == 0
        ZRs0 = 10 *ZRs0;
    else
        ZRs0=quantiles(@F_Sum_Aggregated,type_sum,A_sum0,a_yz,b_yz,{1},FR,ZRs0);
    end
    ZRj0=0.9*ZRj; % initial guess
    if rho_joint0 == 0
        ZRj0 = 10*ZRj0;
    else
        ZRj0=quantiles(@F_Joint_Aggregated,type_joint,A_joint0,a_yz,b_yz,{1},FR,ZRj0);
    end

    %% Selection of extreme load
    disp('Selecting extreme loads...')
    % The final extreme load is taken as the one leading to the lowest load
    % among the distribution functions that have a least-quares-error below
    % a predefined level
   
    % Correlation coefficient for "fit and aggregate" distributions
    rho_single = rho_fit(type_single,@F_Single_Aggregated,A_single,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
    rho_sum = rho_fit(type_sum,@F_Sum_Aggregated,A_sum,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);
    rho_joint = rho_fit(type_joint,@F_Joint_Aggregated,A_joint,a_yx,b_yx,p,a_yz+residual(:,1)*b_yz,residual(:,2),err);    

    % Selection of the extreme load
    eps_vec = [epsilon_single, epsilon_sum, epsilon_joint, epsilon_sum0, epsilon_joint0];
    ZR_vec = [ZRsi, ZRs, ZRj, ZRs0, ZRj0];
    Distr_arr = {'FASi', 'FAS', 'FAJ', 'AFS', 'AFJ'};
    
%     if Options.DNV == 0
%         [epsilon_min, ZR_idx] = min(eps_vec);
%         if epsilon_min < epsilon_FitMax
%             ZR_min = ZR_vec(ZR_idx);
%             Distr_type = Distr_arr{ZR_idx};
%         else
%             epsilon_min = epsilon_FitMax;
%             [ZR_min, ZR_idx] = max([ZRsi ZRs ZRj]);
%             Distr_type = Distr_arr{ZR_idx};
%         end
%     elseif Options.DNV == 1
%         ZR_idx = find(cell2mat(Sensors(iSensor,3:end)));
%         ZR_min = ZR_vec(ZR_idx);
%         epsilon_min = eps_vec(ZR_idx);
%         Distr_type = Distr_arr{ZR_idx};
%     end

%    [epsilon_min, ZR_idx] = min(eps_vec);
%    ZR_min = ZR_vec(ZR_idx);
    epsilon_min = min(eps_vec);    
    if ZRs < ZRj
        ZR_min = ZRs;
        ZR_idx = 2;
    else
        ZR_min = ZRj;
        ZR_idx = 3;
    end
    Distr_type = Distr_arr{ZR_idx};
    for ii = 1:length(ZR_vec)
        if (ZR_vec(ii) < ZR_min) && ((eps_vec(ii) < epsilon_FitMax) || (eps_vec(ii) < eps_vec(ZR_idx)))
            ZR_idx = ii;
            ZR_min = ZR_vec(ZR_idx);
            Distr_type = Distr_arr{ZR_idx};
        end
    end 
    
    %Saving data for plots and report
    Sensors{iSensor,ZR_idx+2} = 1;
    DLC11{1}.Fitting{iSensor}.Extrapolated50 = ZR_min;
    DLC11{1}.Fitting{iSensor}.Epsilon = epsilon_min;
    DLC11{1}.Fitting{iSensor}.Type = Distr_type;
    DLC11{1}.Fitting{iSensor}.Py50 = Py50;
    
    % Fitting Data
    Np = 100;
    jj= (1:Np)';

    xx = ones(length([A.y]'),1)*a_yz+[A.y]'*b_yz;
    Fy0 = -log(-log([A.Fy]'));

    zz_min = max(0.9*min([z.value]'),min(a_yx));
    zz_max = max(1.15*max([z.value]'),1.1*ZRsi);
    zz_jj = zz_min + (zz_max-zz_min).*(jj-1)/(Np-1);

    z_single = F_Single_Aggregated(type_single,A_single,zz_jj,a_yx,b_yx,p);
    z_sum = F_Sum_Aggregated(type_sum,A_sum,zz_jj,a_yx,b_yx,p);
    z_joint = F_Joint_Aggregated(type_joint,A_joint,zz_jj,a_yx,b_yx,p);

    z0_single = F_Single(type_single,A_single0,(zz_jj-a_yz)/b_yz);
    z0_sum = F_Sum(type_sum,A_sum0,(zz_jj-a_yz)/b_yz);
    z0_joint = F_Joint(type_joint,A_joint0,(zz_jj-a_yz)/b_yz);
    
    % Save empirical distribution in output matrix
    DLC11{1}.Fitting{iSensor}.EmpiricalData(:,1:2) = [xx (1-[A.Fy]')]; 
    
    switch Distr_type
        case 'FAS'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z_single];
        case 'FAJ'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z_joint];
        case 'FAD'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z_sum];
        case 'AFS'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z0_single];
        case 'AFJ'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z0_joint];
        case 'AFD'
            DLC11{1}.Fitting{iSensor}.Distribution(:,1:2) = [zz_jj z0_sum];
    end
    
    
    %% Plots
    % If required (Options.DNV=1 or Options.Plots=1), plots of the load distribution and the fitting curve are generated
    if Options.Plots==1 || Options.DNV==1
        disp('Creating plots...')
        
        h_fig = 12;   %total height of figure
        w_fig = 18;  %total width of figure
        n_hor = 1;   %number of figures in the horizontal direction
        n_ver = 1;   %number of figures in the vertical direction
        d_vtop = 1.0; %vertical distance to top figure
        d_vbot = 1.5; %vertical distance to bottom figure
        d_hfir = 1.5; %horizontal distances to first column of figures
        d_hlas = 0.5; %horizontal distances to last column of figures
        d_vbet = 1.8;%vertical distance between figures
        d_hbet = 1.5;%horizontal distance between figures
        h_axis = (h_fig-d_vbot-d_vtop-d_vbet*(n_ver-1))/n_ver;    %height of axis
        w_axis = (w_fig-d_hfir-d_hlas-d_hbet*(n_hor-1))/n_hor;    %width of axis

        % Fit and Aggregate Plot
        if Options.DNV==0 || any(cell2mat(Sensors(iSensor,3:5)))
            % Create empty figures
            if iSensor < size(Sensors,1)-2
                TmpPlotFandA.Sensor(iSensor).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',Sensors{iSensor,1});
            else
                TmpPlotFandA.Sensor(iSensor).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',['- ' Sensors{iSensor,1}]);
            end
            axes('box', 'on', 'fontsize', 10,  'units', 'centimeters', 'position',[d_hfir, d_vbot+0*(d_vbet+h_axis), w_axis, h_axis], 'yscale','log'); hold on; grid on;
            ylabel('P(X>x | load case)');
            if iSensor < length(Sensors(:,1))-2
                xlabel(Sensors{iSensor,1});
            else
                xlabel(['- ' Sensors{iSensor,1}]);
            end
            title('"Fit and Aggregate" Conditional Cumulated Exceedance Probability');

            TmpPlotFandA.fig(iSensor).p(end+1) = plot(xx,1-[A.Fy]','k.');
            if Options.DNV==1
                 TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Empirical data';
            else
                TmpPlotFandA.fig(iSensor).Legends{end+1} = DLC11{1}.Options.Legend;
            end

            if Sensors{iSensor,3} == 1
                if Options.DNV==1
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_single),1)-z_single,'k-');
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Fitting function - Single distribution';
                else
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_single),1)-z_single,'LineStyle','-','Color',[0,0.4470,0.7410]);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = ['Single distribution fitting - R^2 = ', num2str(rho_single^2)];
                end
            end

            if Sensors{iSensor,4} == 1
                if Options.DNV==1
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_sum),1)-z_sum,'k-');
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Fitting function - Sum of distributions';
                else
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_sum),1)-z_sum,'LineStyle','-.','Color',[0.8500,0.3250,0.0980]);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = ['Sum of distributions fitting - R^2 = ', num2str(rho_sum^2)];
                end
            end

            if Sensors{iSensor,5} == 1
                if Options.DNV==1
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_joint),1)-z_joint,'k-');
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Fitting function - Joint distribution';
                else
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z_joint),1)-z_joint,'LineStyle','--','Color',[0.9290,0.6940,0.1250]);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = ['Joint distribution fitting - R^2 = ', num2str(rho_joint^2)];
                end
            end
            
            % Plot selected extrapolated value
            if Options.DNV==1
                TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC11{1}.Fitting{iSensor}.Extrapolated50,Py50,'ok','MarkerSize',8,'LineWidth',1.5);
                TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Selected extrapolated value';
            else
                TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC11{1}.Fitting{iSensor}.Extrapolated50,Py50,'ob','MarkerSize',8,'LineWidth',1.5);
                TmpPlotFandA.fig(iSensor).Legends{end+1} = ['Selected extrapolated value: type ' DLC11{1}.Fitting{iSensor}.Type];
            end

            % Plot DLC 13 extreme value
            switch Options.PlotDLC13
                case 1
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC13.Extremes(iSensor)*1.35/1.25,Py50,'xr','MarkerSize',10,'LineWidth',2);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'ETM value on blade (scaled)';
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC13.Extremes(iSensor)*1.35/1.25*1.03,Py50,'xg','MarkerSize',10,'LineWidth',2);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'ETM value on blade (scaled) with 3% margin';
                case 2
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC13.Extremes3B(iSensor)*1.35/1.25,Py50,'xr','MarkerSize',10,'LineWidth',2);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Maximum ETM value (scaled)';
                    TmpPlotFandA.fig(iSensor).p(end+1) = plot(DLC13.Extremes3B(iSensor)*1.35/1.25*1.03,Py50,'xg','MarkerSize',10,'LineWidth',2);
                    TmpPlotFandA.fig(iSensor).Legends{end+1} = 'Maximum ETM value (scaled) with 3% margin';
            end

            axs = get(gcf,'CurrentAxes');
            xl=get(axs,'xlim');
            if Options.NExt == 1    
                axis([xl(1) max([xl(2),DLC13.Extremes3B(iSensor)*1.35/1.25*1.05]) 1e-7 1]);
            elseif Options.NExt > 1
                axis([xl(1) max([xl(2),DLC13.Extremes3B(iSensor)*1.35/1.25*1.05]) 1e-8 1]);
            end

            xl=get(axs,'xlim');
            plot(xl,[Py50 Py50],'-k');
            if Options.NExt == 1
                set(axs,'Ytick',[1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
            elseif Options.NExt > 1
                set(axs,'Ytick',[1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
            end        
            set(axs, 'YMinorGrid','off');

            legend(TmpPlotFandA.fig(iSensor).p,TmpPlotFandA.fig(iSensor).Legends,'Location','best');

            if Options.SaveFigs == 1
                if iSensor < length(Sensors(:,1))-2
                    saveas(TmpPlotFandA.Sensor(iSensor).fig, [FolderFigs '/' Sensors{iSensor,1} '_FandA.fig']) %Matlab .FIG file
                    saveas(TmpPlotFandA.Sensor(iSensor).fig, [FolderFigs '/' Sensors{iSensor,1} '_FandA.emf']) %Windows Enhanced Meta-File (best for powerpoints)
                else
                    saveas(TmpPlotFandA.Sensor(iSensor).fig, [FolderFigs '/-' Sensors{iSensor,1} '_FandA.fig']) %Matlab .FIG file        
                    saveas(TmpPlotFandA.Sensor(iSensor).fig, [FolderFigs '/-' Sensors{iSensor,1} '_FandA.emf']) %Windows Enhanced Meta-File (best for powerpoints)        
                end
            end
            
        end

        % Aggregate and Fit Plot
        if Options.DNV==0 || any(cell2mat(Sensors(iSensor,6:7)))
            % Create empty figures
            if iSensor < size(Sensors,1) -2
                TmpPlotAandF.Sensor(iSensor).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',Sensors{iSensor,1});
            else
                TmpPlotAandF.Sensor(iSensor).fig = figure('paperpositionmode', 'auto', 'units','centimeters','position', [5, 5, w_fig, h_fig],'color',[1 1 1],'name',['- ' Sensors{iSensor,1}]);
            end
            axes('box', 'on', 'fontsize', 10,  'units', 'centimeters', 'position',[d_hfir, d_vbot+0*(d_vbet+h_axis), w_axis, h_axis], 'yscale','log'); hold on; grid on;
            ylabel('P(X>x | load case)');
            if iSensor < length(Sensors(:,1)) -2
                xlabel(Sensors{iSensor,1});
            else
                xlabel(['- ' Sensors{iSensor,1}]);
            end
            title('"Aggregate and Fit" Conditional Cumulated Exceedance Probability');

                TmpPlotAandF.fig(iSensor).p(end+1) = plot(xx,1-[A.Fy]','k.');
            if Options.DNV==1
                TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Empirical data';
            else
                TmpPlotAandF.fig(iSensor).Legends{end+1} = DLC11{1}.Options.Legend;
            end            

            if Sensors{iSensor,6} == 1
                if Options.DNV==1
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z0_sum),1)-z0_sum,'k-');
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Fitting function - Sum of distributions';
                else
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z0_sum),1)-z0_sum,'LineStyle','-.','Color',[0.4660,0.6740,0.1880]);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = ['Sum of distributions fitting - R^2 = ', num2str(rho_sum0^2)];
                end
            end

            if Sensors{iSensor,7} == 1
                if Options.DNV==1
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z0_joint),1)-z0_joint,'k-');
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Fitting function - Joint distribution';
                else
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(zz_jj,ones(length(z0_joint),1)-z0_joint,'LineStyle','--','Color',[0.3010,0.7450,0.9330]);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = ['Joint distribution fitting - R^2 = ', num2str(rho_joint0^2)];
                end
            end

            % Selected selected extrapolated value
            if Options.DNV==1
                TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC11{1}.Fitting{iSensor}.Extrapolated50,Py50,'ok','MarkerSize',8,'LineWidth',1.5);
                TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Selected extrapolated value';
            else
                TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC11{1}.Fitting{iSensor}.Extrapolated50,Py50,'ob','MarkerSize',8,'LineWidth',1.5);
                TmpPlotAandF.fig(iSensor).Legends{end+1} = ['Selected extrapolated value: type ' DLC11{1}.Fitting{iSensor}.Type];
            end

            % Plot DLC 13 extreme value
            switch Options.PlotDLC13
                case 1
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC13.Extremes(iSensor)*1.35/1.25,Py50,'xr','MarkerSize',10,'LineWidth',2);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'ETM value on blade (scaled)';
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC13.Extremes(iSensor)*1.35/1.25*1.03,Py50,'xg','MarkerSize',10,'LineWidth',2);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'ETM value on blade (scaled) with 3% margin';
                case 2
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC13.Extremes3B(iSensor)*1.35/1.25,Py50,'xr','MarkerSize',10,'LineWidth',2);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Maximum ETM value (scaled)';
                    TmpPlotAandF.fig(iSensor).p(end+1) = plot(DLC13.Extremes3B(iSensor)*1.35/1.25*1.03,Py50,'xg','MarkerSize',10,'LineWidth',2);
                    TmpPlotAandF.fig(iSensor).Legends{end+1} = 'Maximum ETM value (scaled) with 3% margin';
            end            

            axs = get(gcf,'CurrentAxes');
            xl=get(axs,'xlim');
            if Options.NExt == 1    
                axis([xl(1) max([xl(2),DLC13.Extremes3B(iSensor)*1.35/1.25*1.05]) 1e-7 1]);
            elseif Options.NExt > 1
                axis([xl(1) max([xl(2),DLC13.Extremes3B(iSensor)*1.35/1.25*1.05]) 1e-8 1]);
            end

            xl=get(axs,'xlim');
            plot(xl,[Py50 Py50],'-k');
            if Options.NExt == 1
                set(axs,'Ytick',[1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
            elseif Options.NExt > 1
                set(axs,'Ytick',[1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1e0]);
            end        
            set(axs, 'YMinorGrid','off');

            legend(TmpPlotAandF.fig(iSensor).p,TmpPlotAandF.fig(iSensor).Legends,'Location','best');

            if Options.SaveFigs == 1
                if iSensor < length(Sensors(:,1))-2
                    saveas(TmpPlotAandF.Sensor(iSensor).fig, [FolderFigs '/' Sensors{iSensor,1} '_AndF.fig']) %Matlab .FIG file
                    saveas(TmpPlotAandF.Sensor(iSensor).fig, [FolderFigs '/' Sensors{iSensor,1} '_AandF.emf']) %Windows Enhanced Meta-File (best for powerpoints)
                else
                    saveas(TmpPlotAandF.Sensor(iSensor).fig, [FolderFigs '/-' Sensors{iSensor,1} '_AandF.fig']) %Matlab .FIG file        
                    saveas(TmpPlotAandF.Sensor(iSensor).fig, [FolderFigs '/-' Sensors{iSensor,1} '_AandF.emf']) %Windows Enhanced Meta-File (best for powerpoints)        
                end
            end
        
        end
        
    end

end

%% Reports
% If an output file name is given in Options.OutFile, then a text file report is generated
% This file contains DLC 13 values, extrapolated values and ratio extrapolated / DLC 13
if ~strcmpi(Options.OutFile,'')
    disp('Creating reports...')
    % Calculation of the mean of the extrapolated load on the 3 blades
    for iSensor = 1:size(DLC11{1}.Sensors,1)
        index = [Sensors{:,2}]==Sensors{iSensor,2};
        DLC11{1}.Fitting{iSensor}.Extrapolated50_3B = 0;
        for kk=1:length(index)
            DLC11{1}.Fitting{iSensor}.Extrapolated50_3B = DLC11{1}.Fitting{iSensor}.Extrapolated50_3B + DLC11{1}.Fitting{kk}.Extrapolated50*index(kk);
        end
        DLC11{1}.Fitting{iSensor}.Extrapolated50_3B = DLC11{1}.Fitting{iSensor}.Extrapolated50_3B/sum(index);
    end
    
    LoadExtrapolationReport(SimPath,DLC11{1},DLC13,Options,Sensors,GrubbsInfo);
end

% For DNV a file containing the extremes considered in load extrapolation is generated
if Options.DNV ==1
    LoadExtrapolationXLS(SimPath,DLC11{1}.Frq,DLC11{1}.Extremes,Sensors,DLC11{1}.Options.NExt,Options,DLC11{1}.File,GrubbsInfo);
end

disp('Done!');

end


%% Functions
function enableFigureInteraction(fig)
    datacursormode on
    dcm = datacursormode(fig);
    set(dcm,'UpdateFcn',@getDataPointInfo)
end

function txt = getDataPointInfo(~,event)
    pos = get(event,'Position');
    tag = get(event.Target,'UserData');
    xPosns=[tag.xPos]';
    yPosns=[tag.yPos]';
    index_x = find(xPosns==pos(1));
    index_y = find(yPosns==pos(2));
    index = intersect(index_x,index_y);
    if length(index) < 1
        disp('error, no simulation ID found')
    end
    txt = {['X: ',num2str(pos(1))],['Y: ',num2str(pos(2))],tag(index).sim};
end

function R = TestValues(X,max_num_outliers)
    for ji=1:max_num_outliers
        x1=X;
        n=length(x1);
        mu = mean(x1(:));
        sigma = std(x1(:));
        R(ji) = 0;
        for ij = 1:n
            x_norm = (x1(ij)-mu)/sigma;
            if x_norm > R(ji)
                R(ji) = x_norm;
                X_ext(ji) = x1(ij);
                index = ij;
            end
        end
        k=0;
        X=0;
        for ij=1:n
            if ij ~= index
                k=k+1;
                X(k) = x1(ij);
            end
        end
    end
end

function num = N_outliers(y,N_min,alpha_Grubb)
    Ny=length(y);
    r = min(20,min(round(30*0.01*Ny),Ny-N_min));
    r = max(r,1);
    eta = LAC.statistic.skewness(y);
    if eta > 0.1
        y_min_lim = 0.1;
        y_min = min(y);
        if y_min < y_min_lim
            y = y + y_min_lim - y_min;
        end;
        k = k_w3(eta);
        if k > 0.01
            A = mean(y)/gamma(1+1/k);
            for ji = 1:Ny
                y(ji) = F_X_inv('N',0,1,0,F_X('W2',A,k,0,y(ji)));
            end
        end
    end
    R = TestValues(y,r);
    num = 0;
    if Ny>2    
        for ji = 1:r
            if R(ji) > lambda(alpha_Grubb,Ny-ji+1)
                num = ji;
            end
        end
    end

    function result = lambda(alpha_Grubb,n)
        P = 1 - alpha_Grubb/n;
        tdist2T = @(t,v) (1-betainc(v/(v+t^2),v/2,0.5));
        tdist1T = @(t,v) 1-(1-tdist2T(t,v))/2;
        t_inv = @(alpha,v) fzero(@(tval) (max(alpha,(1-alpha)) - tdist1T(tval,v)), 5);
        t_alpha = t_inv(P,n-2) * [-1 1];
        t_alpha = t_alpha(1);
        t_alpha = t_alpha*-1;
        result = t_alpha*(n-1)/sqrt((n-2+t_alpha^2)*n);
    end
end

function non_outliers = NoOut(x,N_out)
    N = size(x,1);
    if size(x,2) == 1
        for ii=1:length(N_out)
            n{ii} = x(1:N-N_out(ii),1);
        end
    else
        for ii=1:size(x,2)
            n{ii} = x(1:N-N_out(ii),ii);
        end
    end
    non_outliers = n';
end

function FX = F_Single(type,A,y)
    FX = F_X(type,A(1),A(2),0,y);
end

function FX = F_Joint(type,A,y)
    FX = F_YJ(type,A(1),A(2),y) + F_YJ(type,A(3),A(4),y) - F_YJ(type,A(1),A(2), y).*F_YJ(type,A(3),A(4),y);
    function F = F_YJ(type,a,b,y)
        F = F_X(type,a,b,0,y);
        F(F<0)=0;
    end
end

function FX = F_Sum(type,A_aug,y)
    F_S1 = F_YS(type,A_aug(2),A_aug(3),y);
    F_S2 = F_YS(type,A_aug(4),A_aug(5),y);
    FX = zeros(length(y),1);
    for ii = 1:length(y)
        if F_S1(ii)<=A_aug(6) || F_S2(ii)<=0
            FX(ii) = A_aug(1)*F_S1(ii) + (1-A_aug(1))*F_S2(ii);
        else
            y_c = F_X_inv(type,A_aug(2),A_aug(3),0,A_aug(6));
            F_S2c = F_YS(type,A_aug(4),A_aug(5),y_c);
            if F_S2c < 1.0
                P_S1 = (F_Sum0(type,A_aug(1),A_aug(2),A_aug(3),A_aug(4),A_aug(5),y_c)-F_S2c)/(1-F_S2c);
            else
                P_S1 = 1.0;
            end
            FX(ii) = P_S1+(1-P_S1)*F_YS(type,A_aug(4),A_aug(5),y(ii));
        end
    end
    
    function F = F_YS(type,a,b,y)
        F = F_X(type,a,b,0,y);
        F(F<0)=0;
    end
end

function FX0 = F_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y)
    FX0 = p_S1*F_X(type,a_S1,b_S1,0,y) + (1-p_S1)*F_X(type,a_S2,b_S2,0,y);
end

function f0 = f_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y)
    f0 = p_S1*f_X(type,a_S1,b_S1,0,y) + (1-p_S1)*f_X(type,a_S2,b_S2,0,y);
end

function fd0 = fd_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y)
    fd0 = p_S1*fd_X(type,a_S1,b_S1,0,y) + (1-p_S1)*fd_X(type,a_S2,b_S2,0,y);
end

function par = SingleFit(type,method,y,Fy)
    % Function for making a single distribution fit. 
    % Method =
    % 0: LSE for -ln(-ln(F_X))
    % 1: If Weibull, a linear fit is made for ln(x),ln(-ln(1-F_X(x))) and
    % if another distribution then the parameters are determined from the
    % mean and the standard deviation found for the Weibull distribution
    res = DistFilt(y,Fy);
    for index=1:length(res)
        yy{index} = res{index}(:,1);
        Fyy{index} = res{index}(:,2);
    end
    yy=yy';
    Fyy=Fyy';
    Nyy = length(yy);
    for k=1:length(yy)
        if length(yy{k}) > 1
            if type == 'G'
                result(:,k) = GumbelFit(yy{k},Fyy{k});
            else
                v = Weibull2Fit(yy{k},Fyy{k});
                if type ~= 'W2'
                    mu_sig = MeanStd('W2',v(1), v(2));
                    v = DistPar(type,mu_sig(1),mu_sig(2),0);
                end
                if method == 0
                    v = SingleMinerr(v(1),v(2),type,yy{k},Fyy{k});
                end
                result(:,k) = v(1:2);
            end
        elseif length(yy{k}) <= 1
          %  mu_y1 = mean(y{k});
          %  sigma_y = std(y{k},1);
          %  out = DistPar(type,mu_y1,sigma_y,0);
          %  result(:,k) = out(1:2);
            result(:,k) = [0 ; 0];
        end
        if ~DistParCheck(type,result(1,k),result(2,k),0) 
            mu_y1 = mean(y{k});
            sigma_y = std(y{k},1);
            out = DistPar(type,mu_y1,sigma_y,0);
            result(:,k) = out(1:2);
        end
    end
    par = [result(1,:); result(2,:)];

    % Private functions
    % Removal of data points which has a probability of exceedance less
    % than 0 and higher than 1:
    function result = DistFilt(y,Fy)

        for jjj=1:length(y)
            ii=0;
            for iii=1:length(y{jjj})
               if Fy{jjj}(iii) > 0 && Fy{jjj}(iii) < 1
                  ii = ii + 1;
                  yy1{jjj,1}(ii,1) = y{jjj}(iii);
                  Fyy1{jjj,1}(ii,1) = Fy{jjj}(iii);
               end
            end
            if ii == 0
                yy1{jjj,1}(1,1) = 0;
                Fyy1{jjj,1}(1,1) = 0;
            end
        end
        for jjj=1:length(yy1)
            result{jjj} = horzcat(yy1{jjj},Fyy1{jjj});
        end
        result = result';
    end

    function vec = GumbelFit(x,Fx)
        ln_Fx = -log(-log(Fx));
        warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
        line = polyfit(x,ln_Fx,1); % line = [slope, intercept];
        alpha = line(1);
        if alpha > 0
            u = -line(2)/alpha;
            vec = [u; alpha];
        else
            vec = [0;0];
        end
    end

    % Least-squares-fit for Gumbel and Weibull distribution
    function vec = Weibull2Fit(x,Fx)
        zz = log(-log(1-Fx));
        ln_x = log(x);
        warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
        line = polyfit(ln_x,zz,1); % line = [slope, intercept];
        kw = line(1);
        ln_Aw = -line(2)/kw;
        if kw > 0 && ln_Aw < 700
            vec = [exp(ln_Aw); kw];
        else
            vec = [0;0];
        end
    end

    function result = epsilon0_noSSQ(a0,b0,type,y,Fy)
        Fx = F_X(type,a0,b0,0,y);
        Fy(Fx <= 0.0) = exp(-1); 
        Fy(Fx >= 1.0) = exp(-1);
        Fx(Fx <= 0.0) = exp(-1);
        Fx(Fx >= 1.0) = exp(-1);
        Fx(Fy <= 0.0) = exp(-1);
        Fx(Fy >= 1.0) = exp(-1);
        Fy(Fy <= 0.0) = exp(-1);
        Fy(Fy >= 1.0) = exp(-1);
        result = log(-log(Fy)) - log(-log(Fx));   
        result(sum(result) == 0.0) = 100;
    end

    function result = epsilon0(a0,b0,type,y,Fy)
        result = sqrt(sum(epsilon0_noSSQ(a0,b0,type,y,Fy).^2)./length(y));
    end

    function x = SingleMinerr(a0,b0,type,y,Fy)
        x0 = [a0,b0];
        options.Algorithm = 'levenberg-marquardt';
        options.Display = 'off';
        fun = @(x) epsilon0_noSSQ(x(1),x(2),type,y,Fy);
%         eps=epsilon0(a0,b0,type,y,Fy);
        x = lsqnonlin(fun,x0,[],[],options); 
    end

end


function result = SumFitIte(type,y,Fy,N_min,p_FitMin,epsilon_FitMax,epsilon_CutMax,FitCheck)
    % Function for making the "sum of distributions" fit.
    % Sometimes the sum distribution only fits to the lower part of the
    % distribution. In order to avoid that, some of the lower values are
    % removed until the fit fulfills the requirement for the LSE.
    % FitCheck =
    % 0: No check of fit
    % 1: If the check fails, a single distribution fit is made
    % 2: If the check fails, the fit is maintained but epsilon is set to
    %    100 and rho to 0
    F_S1max = 1.0;
    y = y{1};
    Fy = Fy{1};
    epsilon = 1001;
    epsilon_min = epsilon;
    rho = 0;
    rho_min = rho;
    deltaN = max(round(length(y)/20),1);
    dtheta_max = deg2rad([0.1 ; 1.0 ; 5.0 ; 10.0]);
    N_ite_y2 = 1;
    v = [1; 0; 0; 0; 0];
    FirstIteration = 1;
    while ((length(y) >= max(N_min,deltaN+2)) || FirstIteration) && (epsilon > epsilon_FitMax)
        v = SumFit(type,y,Fy,N_min,dtheta_max(1),N_ite_y2,v);
        epsilon = epsilon_Sum(type,v(1),v(2),v(3),v(4),v(5),F_S1max,y,Fy);
        rho = rho_Sum(type,v(1),v(2),v(3),v(4),v(5),1.0,y,Fy);
        if epsilon < epsilon_min
            v_min = v;
            epsilon_min = epsilon;
            rho_min = rho;
            yy_min = y;
            Fyy_min = Fy;
        end;
        ii = 1;
        while (ii <= length(dtheta_max)) && (epsilon > epsilon_FitMax)
            for N_ite_y2 = 1:2
                v(1) = 1;
                v = SumFit(type,y,Fy,N_min,dtheta_max(ii),N_ite_y2,v);
                epsilon = epsilon_Sum(type,v(1),v(2),v(3),v(4),v(5),F_S1max,y,Fy);
                rho = rho_Sum(type,v(1),v(2),v(3),v(4),v(5),1.0,y,Fy);
                if epsilon < epsilon_min
                    v_min = v;
                    epsilon_min = epsilon;
                    rho_min = rho;
                    yy_min = y;
                    Fyy_min = Fy;
                end;
            end
            ii = ii + 1;
        end
        v = v_min;
        epsilon = epsilon_min;
        rho = rho_min;
        yy1 = yy_min;
        Fyy1 = Fyy_min;
        y = y(deltaN+1:end);
        Fy = Fy(deltaN+1:end);
        FirstIteration = 0;
    end
    v_aug = vertcat(v, F_S1max);
    if (v(1) > 0.0) && (v(1) < 1.0) 
        v_aug1 = SumFitCut(type,yy1,Fyy1,v,N_min,p_FitMin,F_S1max);
        epsilon1 = epsilon_Sum(type,v_aug1(1),v_aug1(2),v_aug1(3),v_aug1(4),v_aug1(5),v_aug1(6),yy1,Fyy1);
        rho1 = rho_Sum(type,v_aug1(1),v_aug1(2),v_aug1(3),v_aug1(4),v_aug1(5),v_aug1(6),yy1,Fyy1);
        vec = SingleFit(type,0,{yy1},{Fyy1});
        epsilon2 = epsilon_Sum(type,1.0,vec(1),vec(2),0.0,0.0,1.0,yy1,Fyy1);
        rho2 = rho_Sum(type,1.0,vec(1),vec(2),0.0,0.0,1.0,yy1,Fyy1);
        if v_aug1(6) < 1.0
            if (epsilon1 < epsilon_CutMax) 
                v_aug = v_aug1;
                epsilon = epsilon1;
                rho = rho1;
            end
            if (epsilon2 < epsilon1) && (epsilon2 < epsilon_FitMax)
                v_aug = [1.0; vec(1); vec(2); 0.0; 0.0; 1.0];
                epsilon = epsilon2;
                rho = rho2;           
            end
        end
    end
    v_aug = vertcat(v_aug, epsilon, rho);
    if FitCheck >0
        result = SumFitCheck(type,yy1,Fyy1,N_min,v_aug,FitCheck);
    else
        result = v_aug;
    end
    
    
    function result = SumFit(type,y,Fy,N_min,dtheta_max,N_ite_y2,vec)
        % If the number of data points representing one of the
        % distributions is too small or it's not valid, then a single
        % distribution is applied.
        if (vec(1) >= 1.0)
            vec = SumInitialFit(type,y,Fy,N_min,dtheta_max,N_ite_y2);
        end
        result = SumMinerr(type,vec(1),vec(2),vec(3),vec(4),vec(5),1,y,Fy);

        % The first step is to make an initial guess for the distribution.
        % Firstly, the number of data points, Ny2, representing the upper part
        % of the distribution are estimated by making a linear fit to the Nmin
        % number of points and then increasing the number of data points until
        % the slope starts to change:

        % Fitting of "sum of distributions"
        function result = Ny2(y,ln_Fy,N_min,dtheta_max,N_ite_y2)
            y = (y - mean(y))/std(y);
            Ny = length(y);
            for i = 1:N_ite_y2
                jjj = N_min;
                theta_max = -pi;
                theta_min = pi;
                theta = 0;
                while (theta_max - theta < dtheta_max) && (theta - theta_min < dtheta_max) && (jjj <= Ny)
                    Y = ln_Fy(Ny-jjj+1:Ny,1:1);
                    X = y(Ny-jjj+1:Ny,1:1);
                    line = polyfit(X,Y,1);
                    a = line(1);
                    theta = atan(a);
                    if theta > theta_max
                        theta_max = theta;
                    end
                    if theta < theta_min
                        theta_min = theta;
                    end
                    jjj = jjj + 1;
                end
                Ny = Ny - jjj + 1;
            end
            result = [jjj-1, Ny + jjj - 1];
        end

        % Initial guess for fit:
        function result = SumInitialFit(type,y,Fy,N_min,dtheta_max,N_ite_y2)
            Ny = length(y);
            Nmax = round((Ny-1)/(Fy(Ny) - Fy(1))) - 1;
            ln_Fy = -log(-log(Fy));
            res = Ny2(y,ln_Fy,N_min,dtheta_max,N_ite_y2);
            N_y2 = res(1);
            Ny_y2 = res(2);
            if (N_y2 >= N_min) && (Ny_y2 > N_min)
                N_y2 = min(N_y2, Ny_y2-3);
                Fy_sub2 = Fy(Ny_y2-N_y2+1:Ny_y2);
                y2 = y(Ny_y2-N_y2+1:Ny_y2);
                p_S1 = (Nmax - N_y2)/Nmax;
                Fy2 = (Fy_sub2 - p_S1)/(1-p_S1);
                v2 = SingleFit(type,1,{y2},{Fy2});
                Fy1 = (Fy - (1-p_S1)*F_X(type,v2(1),v2(2),0,y))/p_S1;
                v1 = SingleFit(type,1,{y},{Fy1});
                Fy2 = (Fy_sub2 - p_S1*F_X(type,v1(1),v1(2),0,y2))/(1-p_S1);
                v2 = SingleFit(type,1,{y2},{Fy2});
                result = vertcat(p_S1,v1(1),v1(2),v2(1),v2(2));
            else
                v1 = SingleFit(type,1,{y},{Fy});
                result = vertcat(1,v1(1),v1(2),0,0);
            end
        end
        
    end

    function result = F_sum(type,v_aug,y)
        F_S1 = F_YS(type,v_aug(2),v_aug(3),y);
        F_S2 = F_YS(type,v_aug(4),v_aug(5),y);
        result = zeros(length(y),1);
        for jj = 1:length(y)
            if F_S1(jj) <= v_aug(6) || F_S2(jj) <= 0
                result(jj) = v_aug(1)*F_S1(jj) + (1-v_aug(1))*F_S2(jj);
            else
                y_c = F_X_inv(type,v_aug(2),v_aug(3),0,v_aug(6));
                F_S2c = F_YS(type,v_aug(4),v_aug(5),y_c);
                if F_S2c < 1.0
                    P_S1 = (F_sum0(type,v_aug(1),v_aug(2),v_aug(3),v_aug(4),v_aug(5),y_c)-F_S2c)/(1-F_S2c);
                else
                    P_S1 = 1.0;
                end
                result(jj) = P_S1+(1-P_S1)*F_YS(type,v_aug(4),v_aug(5),y(jj));
            end
        end
    end

    function result = F_sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y)
        result = p_S1*F_YS(type,a_S1,b_S1,y) + (1-p_S1)*F_YS(type,a_S2,b_S2,y);
    end

    function F = F_YS(type,a,b,y)
        F = F_X(type,a,b,0,y);
        F(F<0)=0;
    end

    % Minimisation function for least-squares-error:    
    function result = SumMinerr(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy)
        x0 = [p_S1; a_S1; b_S1; a_S2; b_S2];
        options.Algorithm = 'levenberg-marquardt';
        options.Display = 'off';
%         eps=epsilon_Sum_noSSQ(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy);
        fun = @(x) epsilon_Sum_noSSQ(type,x(1),x(2),x(3),x(4),x(5),F_S1max,y,Fy);
        result = lsqnonlin(fun,x0,[],[],options);
    end

    function F = epsilon_Sum_noSSQ(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy)
        v1 = vertcat(p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max);
        t1 = DistParCheck(type,a_S1,b_S1,0);
        t2 = DistParCheck(type,a_S2,b_S2,0);
        t2b = t2 || (p_S1 == 1.0); 
        t3 = (p_S1 >= 0.0) && (p_S1 <= 1.0);
        Ny = length(y);
        t4 = 1;
        if t1
            mu_sig1 = MeanStd(type,a_S1,b_S1);
            t4 = (mu_sig1(1) > 0.0) && (mu_sig1(1) < y(Ny));
        end;
        t5 = 1;        
        if t2 
            mu_sig2 = MeanStd(type,a_S2,b_S2);        
            t5 = (mu_sig2(1) > 0.0) && (mu_sig2(1) < y(Ny));
        end
        Fsum = F_sum(type,v1,y);
        ln_Fsum = -log(Fsum);
        ln_Fy = -log(Fy);
        F = -log(ln_Fsum) + log(ln_Fy);
        F(isinf(F))=1000;
        F(~t1)=1000;
        F(~t2b)=1000;
        F(~t3)=1000;
        F(~t4)=1000;
        F(~t5)=1000;
    end

    function result = epsilon_Sum(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy)
        result = sqrt(sum(epsilon_Sum_noSSQ(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy).^2)./length(y));
    end

    function result = epsilon_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy)
        v1 = vertcat(p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max);
        t1 = DistParCheck(type,a_S1,b_S1,0);
        t2 = DistParCheck(type,a_S2,b_S2,0);
        t2 = 1;
        t3 = (p_S1 >= 0.0) && (p_S1 <= 1.0);
        t3 = 1;
        if (t1 && t2 && t3) %|| ((p_S1 == 1.0) && t1)
            Ny = length(y);
            Fsum = F_sum(type,v1,y);
            SSQ = 0;
            for jj=1:Ny
                if (Fsum(jj) > 0) && (Fy(jj) > 0)
                    ln_Fsum = -log(Fsum(jj));
                    ln_Fy = -log(Fy(jj));
                    if (ln_Fy > 0) && (ln_Fsum > 0)
                        SSQ = SSQ + (-log(ln_Fsum) + log(ln_Fy))^2;
                    end
                end
            end
            result = sqrt(SSQ/Ny);
        else
            result = 100;
        end
    end

    function result = rho_Sum(type,p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max,y,Fy)
        v1 = vertcat(p_S1,a_S1,b_S1,a_S2,b_S2,F_S1max);
        Ny = length(y);
        Fsum = F_sum(type,v1,y);
        z1=zeros(length(Fsum),1);
        z2=zeros(length(Fsum),1);
        for jj=1:Ny
            if (Fsum(jj) > 0) && (Fy(jj) > 0) 
                ln_Fsum = -log(Fsum(jj));
                ln_Fy = -log(Fy(jj));                
                if (ln_Fy > 0) && (ln_Fsum > 0)
                    z1(jj) = -log(ln_Fsum);
                    z2(jj) = -log(ln_Fy);
                end
            end
        end
        rho_matrix = corrcoef([z1,z2]);
        result = rho_matrix(1,2);
    end

    % If the check of the upper tail fit made with SumFitTailOff is not ok,
    % meaning that we can have a kink, then a new fit is made, where an
    % upper level is defined for the probability distribution F_S1, denoted
    % F_S1max. The probability distribution F_S1 must represent the lower
    % part of the combined distribution and therefore an interchange is
    % made of the two distributions if needed.
    function result = SumFitCut(type,y,Fy,v,N_min,p_FitMin,F_S1max)
        t0 = F_X(type,v(4),v(5),0,y(1)) > F_X(type,v(2),v(3),0,y(1));
        if t0
            v(1) = 1-v(1);
            a = v(2);
            b = v(3);
            v(2) = v(4);
            v(3) = v(5);
            v(4) = a;
            v(5) = b;
        end
        t1 = SumFitTailOff(type,y,Fy,v,p_FitMin);
        MeanStdVec = MeanStd(type,v(4),v(5));
        if t1
            F_S1max = F_X(type,v(2),v(3),0,MeanStdVec(1));
            v = SumMinerr(type,v(1),v(2),v(3),v(4),v(5),F_S1max,y,Fy);
        else
            y_max = 2.0*max(y);
            y_min = min(MeanStdVec(1) + MeanStdVec(2), max(y));
            fun = @(yc) ln_fd_sum(type,v(1),v(2),v(3),v(4),v(5),yc);
            yc = fminbnd(fun,y_min,y_max);
            ln_fd_1 = ln_fd_sum(type,v(1),v(2),v(3),v(4),v(5),y_min);
            ln_fd_2 = ln_fd_sum(type,v(1),v(2),v(3),v(4),v(5),y_max);
            ln_fd_c = ln_fd_sum(type,v(1),v(2),v(3),v(4),v(5),yc);
            tt1 = (ln_fd_c < ln_fd_1) && (ln_fd_c < ln_fd_2);
            tt2 = (yc > 1.02*y_min) && (yc < 0.98*y_max);
            if tt1 && tt2
                F_S1max = F_X(type,v(2),v(3),0,yc);
                v = SumMinerr(type,v(1),v(2),v(3),v(4),v(5),F_S1max,y,Fy); %New!!!!!!!!!!
           %     if F_S1max < 1 - p_FitMin
           %         F_S1max = 1.0;
           %     end   
            end
        end
        result = vertcat(v,F_S1max);
        
        %One of the two distributions may fit both to the upper and lower
        %tail of the combined distribution. Here, it is checked if that is
        %the case and, if the upper tail of the fitted distribution has a
        %low probability, then the output is "true", meaning that the tail
        %fit is not ok. Firstly it is checked if the two proability 
        %distributions are crossing each other. Next the probability
        %content in the upper tail coming from the distribution that drives
        %the tail fit is calculated and it is checked if this value is
        %below the minimum requirement for a fit.
        function check = SumFitTailOff(type,y,Fy,v,p_FitMin)
            MeanStdVec1 = MeanStd(type,v(2),v(3));
            MeanStdVec2 = MeanStd(type,v(4),v(5));
            N_y = length(y);
            t1off = F_X(type,v(4),v(5),0,y(1)) > F_X(type,v(2),v(3),0,y(1));
            t3off = F_X(type,v(2),v(3),0,y(N_y)) > F_X(type,v(4),v(5),0,y(N_y));
            t0off = (t1off && t3off) || (~t1off && ~t3off);
            if t3off
                t1off = (1-v(1))*(1-F_X(type,v(4),v(5),0,sum(MeanStdVec1))) < p_FitMin;
              %  t2off = (0.5 <= v(1)) && (v(1) < 1.0);
                t2off = 1;
            else
                t1off = v(1)*(1-F_X(type,v(2),v(3),0,sum(MeanStdVec2))) < p_FitMin;
              %  t2off = v(1) < 0.5;
                t2off = 1;
            end
            check = t0off && t1off && t2off;
        end
   
        % Second derivative of -ln(-ln(F_Sum0(y))) 
        function result = ln_fd_sum(type,p_S1,a_S1,b_S1,a_S2,b_S2,y)
           F = F_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y);
           f = f_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y);
           fd = fd_Sum0(type,p_S1,a_S1,b_S1,a_S2,b_S2,y);
           lnF = log(F);
           if -lnF > 0.0
               result = f^2/F^2/lnF*(1 + 1/lnF) - fd/F/lnF;
           else
               result = 10;
           end
        end
        
    end

    % Check of the "Sum of Distributions" fit. If the number of data points
    % representing one of the distributions is too small or it's not valid,
    % then a single distribution is applied (FitCheck == 1) or the
    % distribution is maintained but epsilon is set to 100 and rho to 0 
    % (FitCheck == 2)
    function result = SumFitCheck(type,y,Fy,N_min,v,FitCheck)
        fail1 = v(1)*length(y) < N_min;
        fail2 = (1-v(1))*length(y) < N_min;
        fail3 = ~DistParCheck(type,v(2),v(3),0);
        fail4 = ~DistParCheck(type,v(4),v(5),0);
        if ~fail3
            M = DistIntervalFit(type,v(2),v(3),y);
            N_S1 = M(3);
        else
            N_S1 = 0;
        end
        if ~fail4
            M = DistIntervalFit(type,v(4),v(5),y);
            N_S2 = M(3);
        else
            N_S2 = 0;
        end
        N = length(y);
        Njoint = max(N_S1 + N_S2 - N,0);
        N_S1 = N_S1 - (1 - v(1))*Njoint;
        N_S2 = N_S2 - v(1)*Njoint;
        fail5 = (N_S1 < N_min) || (N_S2 < N_min);
        if (fail1 || fail2 || fail3 || fail4 || fail5) 
            if FitCheck == 1
                v(1) = 1.0;
                vec1 = SingleFit(type,0,{y},{Fy});
                v(2) = vec1(1);
                v(3) = vec1(2);
                v(4) = 0.0;
                v(5) = 0.0;
                v(6) = 1.0;
                v(7) = epsilon_Sum(type,v(1),v(2),v(3),v(4),v(5),v(6),y,Fy);
                v(8) = rho_Sum(type,v(1),v(2),v(3),v(4),v(5),v(6),y,Fy);
            end
            if FitCheck == 2 
                v(7) = 100;
                v(8) = 0;
            end
        end
        result = vertcat(v(1),v(2),v(3),v(4),v(5),v(6),v(7),v(8));
    end
end


function result = JointFitIte(type_joint,type_sum,y,Fy,N_min,A_Sum,epsilon_FitMax,FitCheck)
    % Function for making the joint distribution fit.
    % Sometimes the joint distribution only fits to the lower part of the
    % distribution. In order to avoid that, some of the lower values are
    % removed until the fit fulfils the requirement for the LSE
    y = y{1};
    Fy = Fy{1};
    epsilon = 100;
    epsilon_min = epsilon;
    rho = 0;
    rho_min = rho;
    p_S1_start = A_Sum(1);
    deltaN = max(round(length(y)/20),1);
    FirstIteration = 1;
    while ((length(y) >= max(N_min,deltaN+2)) || FirstIteration) && (epsilon > epsilon_FitMax)
        p_S1 = p_S1_start;
        while (p_S1 < 1.0) && (epsilon > epsilon_FitMax)
            A_sum(1) = p_S1;
            v = JointFit(type_joint,type_sum,y,Fy,N_min,A_Sum);
            epsilon = epsilon_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            rho = rho_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            if epsilon < epsilon_min
                v_min = v;
                epsilon_min = epsilon;
                rho_min = rho;
                y_min = y;
                Fy_min = Fy;
            end
            p_S1 = p_S1 + 0.1;
        end
        p_S1 = p_S1_start - 0.1;
        while (p_S1 > 0.0) && (epsilon > epsilon_FitMax)
            A_Sum(1) = p_S1;
            v = JointFit(type_joint,type_sum,y,Fy,N_min,A_Sum);
            epsilon = epsilon_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            rho = rho_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            if epsilon < epsilon_min
                v_min = v;
                epsilon_min = epsilon;
                rho_min = rho;
                y_min = y;
                Fy_min = Fy;
            end
            p_S1 = p_S1 - 0.1;
        end    
        epsilon = epsilon_min;
        rho = rho_min;
        v = v_min; 
        v1 = v_min;
        if epsilon > epsilon_FitMax
            v1(1:2,1) = SingleFit(type_joint,0,{y},{Fy});
            v1(3:4,1) = [0; 0];
            epsilon1 = epsilon_Joint(type_joint,v1(1),v1(2),v1(3),v1(4),y,Fy);
            rho1 = rho_Joint(type_joint,v1(1),v1(2),v1(3),v1(4),y,Fy);
            if epsilon1 < epsilon
                v = v1;
                v_min = v;
                epsilon = epsilon1;
                epsilon_min = epsilon;
                rho = rho1;
                y_min = y;
                Fy_min = Fy;
            end
            v = JointMinerr(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            epsilon = epsilon_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            rho = rho_Joint(type_joint,v(1),v(2),v(3),v(4),y,Fy);
            if epsilon < epsilon_min
                v_min = v;
                epsilon_min = epsilon;
                rho_min = rho;
                y_min = y;
                Fy_min = Fy;
            end
        end            
        y = y(deltaN+1:end);
        Fy = Fy(deltaN+1:end);
        FirstIteration = 0;
    end
    v_aug = vertcat(v_min, epsilon_min, rho_min);
    if FitCheck > 0
        result = JointFitCheck(type_joint,y_min,Fy_min,N_min,v_aug,FitCheck);
    else
        result = v_aug;
    end
    
    function result = JointFit(type_joint,type_sum,y,Fy,N_min,A)
        % If the number of data points representing one of the
        % distributions or its not valid, then a single distribution is
        % applied.
        if length(A) > 4           
            vec = JointInitFit(type_joint,type_sum,y,Fy,N_min,A);
        else
            vec = A;
        end
        result = JointMinerr(type_joint,vec(1),vec(2),vec(3),vec(4),y,Fy);

        % Initial guess for fit:
        function result = JointInitFit(type_joint,type_sum,y,Fy,N_min,A_Sum)
            Ny=length(y);
            Nmax = round(1/(Fy(end) - Fy(end-1))) - 1;
            MeanStdVec1 = MeanStd(type_sum,A_Sum(2),A_Sum(3));
            mu_S1 = MeanStdVec1(1);
            MeanStdVec2 = MeanStd(type_sum,A_Sum(3),A_Sum(4));
            mu_S2 = MeanStdVec2(1);
            if mu_S1 > mu_S2
                p_J1 = 1 - A_Sum(1); 
            else
                p_J1 = A_Sum(1);
            end
        %    p_J1 = max(0.5,p_J1);
            p_J1 = min(max(p_J1,0.1),0.9);
            Ny1 = min(max(round(p_J1*Nmax), N_min), Ny-N_min);
            Ny2 = Ny - Ny1;
            Fy1 = Fy(1:Ny1);
            y1 = y(1:Ny1);
            vJ1 = SingleFit(type_joint,1,{y1},{Fy1})';
            Fy_sub2 = Fy(Ny-Ny2+1:Ny);
            y2 = y(Ny-Ny2+1:Ny);
            for jj=1:Ny2
                den = 1 - F_X(type_joint, vJ1(1), vJ1(2), 0, y2(jj));
                if den ~= 0.0
                    Fy2(jj) = (Fy_sub2(jj) - F_X(type_joint, vJ1(1), vJ1(2), 0, y2(jj)))/den;
                else
                    Fy2(jj) = 0;
                end
            end
            vJ2 = SingleFit(type_joint,1,{y2},{Fy2})';
            if ~DistParCheck(type_joint, vJ2(1), vJ2(2), 0)
                vJ2 = [0 0];
            end
            result = [vJ1 vJ2]';
        end

    end

    function result = F_joint(type,a_J1, b_J1, a_J2, b_J2, y)
        result = F_YJ(type,a_J1, b_J1, y) + F_YJ(type,a_J2, b_J2, y) - F_YJ(type,a_J1, b_J1, y).*F_YJ(type,a_J2,b_J2,y);
    end

    % Joint probability distribution function:
    function F = F_YJ(type,a,b,y)
        F = F_X(type,a,b,0,y);
        F(F<0)=0;
    end

    % Minimization function for least squares error:  
    function result = JointMinerr(type,a_J1, b_J1, a_J2, b_J2, y, Fy)
        x0 = [a_J1; b_J1; a_J2; b_J2];
        options.Algorithm = 'levenberg-marquardt';
        options.Display = 'off';
%             eps=epsilon_Joint_noSSQ(type,x0(1),x0(2),x0(3),x0(4),y,Fy);
        fun = @(x) epsilon_Joint_noSSQ(type,x(1),x(2),x(3),x(4),y,Fy);
        result = lsqnonlin(fun,x0,[],[],options);
    end

    function F = epsilon_Joint_noSSQ(type,a_J1,b_J1,a_J2,b_J2,y,Fy)
        Fjoint = F_joint(type,a_J1,b_J1,a_J2,b_J2,y);
        ln_Fjoint = -log(Fjoint);
        ln_Fy = -log(Fy);
        F = -log(ln_Fjoint) + log(ln_Fy);
        F(isinf(F))=100;
        t1 = DistParCheck(type,a_J1,b_J1,0);
        t2 = DistParCheck(type,a_J2,b_J2,0);
        t3 = (a_J2 == 0.0) && (b_J2 == 0.0);
        t4 = t2 || t3;
        F(~t1)=100;
        F(~t4)=100;
    end

    function result = epsilon_Joint(type,a_J1,b_J1,a_J2,b_J2,y,Fy)
        result = sqrt(sum(epsilon_Joint_noSSQ(type,a_J1,b_J1,a_J2,b_J2,y,Fy).^2)./length(y));
    end

    function epsilon = epsilon_Joint0(type,a_J1,b_J1,a_J2,b_J2,y,Fy)
        t1 = DistParCheck(type,a_J1,b_J1,0);
        t2 = DistParCheck(type,a_J2,b_J2,0);
        t3 = (a_J2 == 0.0) && (b_J2 == 0.0);
        if (t1 && t2) || (t1 && t3)
            Ny = length(y);
            Fjoint = F_joint(type,a_J1,b_J1,a_J2,b_J2,y);
            SSQ = 0;
            for jj=1:Ny
                if (Fjoint(jj) > 0) && Fy(jj) > 0
                    ln_Fjoint = -log(Fjoint(jj));
                    ln_Fy = -log(Fy(jj));                
                    if (ln_Fy > 0) && (ln_Fjoint > 0)
                        SSQ = SSQ + (-log(ln_Fjoint) + log(ln_Fy))^2;
                    end
                end
            end
            epsilon = sqrt(SSQ/Ny);
        else
            epsilon = 100;
        end
    end

    function result = rho_Joint(type,a_J1,b_J1,a_J2,b_J2,y,Fy)
        Ny = length(y);
        Fjoint = F_joint(type,a_J1,b_J1,a_J2,b_J2,y);
        z1=zeros(length(Fjoint),1);
        z2=zeros(length(Fjoint),1);
        for jj=1:Ny
            if (Fjoint(jj) > 0) && Fy(jj) > 0
                ln_Fjoint = -log(Fjoint(jj));
                ln_Fy = -log(Fy(jj));
                if (ln_Fy > 0) && (ln_Fjoint > 0)
                    z1(jj) = -log(ln_Fjoint);
                    z2(jj) = -log(ln_Fy);
                end
            end
        end
        rho_matrix = corrcoef([z1,z2]);
        result = rho_matrix(1,2);
    end
    
    % Check of the "Joint Distributions" fit. If the number of data points
    % representing one of the distributions is too small or it's not valid,
    % then a single distribution is applied (FitCheck == 1) or the
    % distribution is maintained but epsilon is set to 100 and rho to 0 
    % (FitCheck == 2)
    function result = JointFitCheck(type,y,Fy,N_min,vec,FitCheck)
        if DistParCheck(type,vec(1),vec(2),0)
            M = DistIntervalFit(type,vec(1),vec(2),y);
            N_J1 = M(3);
        else
            N_J1 = 0;
        end
        if DistParCheck(type,vec(3),vec(4),0)
            M = DistIntervalFit(type,vec(3),vec(4),y);
            N_J2 = M(3);
        else
            N_J2 = 0;
        end
        if (N_J1 < N_min) || (N_J2 < N_min)
            if FitCheck == 1
                vec(1:2) = SingleFit(type,0,{y},{Fy});
                vec(3:4) = [0; 0];
                vec(5) = epsilon_Joint(type,vec(1),vec(2),vec(3),vec(4),y,Fy);
                vec(6) = rho_Joint(type,vec(1),vec(2),vec(3),vec(4),y,Fy);
            end
            if FitCheck == 2 
                vec(5) = 100;
                vec(6) = 0;
            end
        end
        result = vec;        
    end
end

% General function which finds the number of data points N_y_int
% within the vector y that belongs to a given probability
% distribution
function M = DistIntervalFit(type_y,a,b,y)
    Ny = length(y);
    p_min = 1/(2*Ny);
    y_a = F_X_inv(type_y,a,b,0,p_min);
    y_b = F_X_inv(type_y,a,b,0,1-p_min);
    y_aa = 1000;
    y_bb = 0;
    N_y_int = 0;
    for iii=1:Ny
        if (y(iii) > y_a) && (y(iii) < y_b)
            N_y_int = N_y_int + 1;
            y_aa = min(y_aa,y(iii));
            y_bb = max(y_bb,y(iii));
        end
    end
    if N_y_int <= 1
        y_aa = y_a;
        y_bb = y_b;
    end
    Fa = F_X(type_y,a,b,0,y_aa);
    Fb = F_X(type_y,a,b,0,y_bb);
    M = [Fa; Fb; N_y_int];    
end

function eps_all = epsilon_Single(type,A,y,Fy)
    for ii=1:size(A,2)
        Fx = F_Single(type,A(:,ii),y{ii});
        eps=0;
        N=0;
        if DistParCheck(type,A(1,ii),A(2,ii),0)
            for iii=1:length(Fx)
                if Fx(iii) > 0 && Fy(iii) > 0
                    ln_Fy1(iii) = -log(Fy(iii));
                    ln_Fx(iii) = -log(Fx(iii));
                    if ln_Fy1(iii) > 0 && ln_Fx(iii) > 0
                        eps = eps + (-log(ln_Fx(iii)) + log(ln_Fy1(iii)))^2;
                        N=N+1;
                    end
                end
            end
            eps_all(ii) = sqrt(eps/N);
        else
            eps_all(ii) = 100;
        end
    end
end

function rho_all = rho_Single(type,A,y,Fy)
    rho_all = zeros(size(A,2),1);
    for ii=1:size(A,2)
        Fx = F_Single(type,A(:,ii),y{ii});
        z1=zeros(length(Fx),1);
        z2=zeros(length(Fx),1);
        for iii=1:length(Fx)
            if Fy(iii) > 0 && Fx(iii) > 0
                ln_Fy = -log(Fy(iii));
                ln_Fx = -log(Fx(iii));
                if ln_Fy > 0 && ln_Fx > 0
                    z1(iii) = -log(ln_Fx);
                    z2(iii) = -log(ln_Fy);
                end
            end
        end
        rho_matrix = corrcoef([z1,z2]);
        rho_all(ii) = rho_matrix(1,2);
    end
end

function result = F_Single_Aggregated(type,A,x,a,b,p)
    result=0;
    if length(a)>1
        for ii =1:length(p)
            result = result + p{ii}.*F_X(type,A(1,ii),A(2,ii),0,(x-a(ii))./b(ii));
        end
    else
        for ii =1:length(p)
            result = result + p{ii}.*F_X(type,A(1,1),A(2,1),0,(x-a(1))./b(1));
        end
    end
end

function result = F_Sum_Aggregated(type,A,x,a,b,p)
    result=0;
    if length(a)>1
        for ii =1:length(p)
            result = result + p{ii}.*F_Sum(type,A(:,ii),(x-a(ii))./b(ii));
        end
    else
        for ii =1:length(p)
            result = result + p{ii}.*F_Sum(type,A(:,ii),(x-a(1))./b(1));
        end
    end
end

function result = F_Joint_Aggregated(type,A,x,a,b,p)
    result=0;
    if length(a)>1
        for ii =1:length(p)
            result = result + p{ii}.*F_Joint(type,A(:,ii),(x-a(ii))./b(ii));
        end
    else
        for ii =1:length(p)
            result = result + p{ii}.*F_Joint(type,A(:,ii),(x-a(1))./b(1));
        end
    end
end

function Fy = EmpiricalDistFunction(a_MR,Ny,Nz,NExt,p,index_i)
    b_MR = 1 - 2*a_MR;
    delta_Fy = Nz/(Nz + b_MR)/Ny;
    Ndlc = length(p);
    Fys = zeros(Ndlc,1);
    Fy = zeros(Nz,1);
    for k=1:Ndlc 
        pp(k) = p{k};
    end
    for i=1:Nz
        Fys(index_i(i)) = Fys(index_i(i)) + delta_Fy*(1 - a_MR);
        Fy(i) = pp*Fys.^NExt;
        Fys(index_i(i)) = Fys(index_i(i)) + delta_Fy*a_MR;      
    end
    % The above calculation leads to the exact same distribution as for the
    % LoadExtrapolationSingleDistribution.m when a_MR = 1 and b_MR = 0.
end

function A = removeOutliersAggregated(z,a,b,Fz,index_i,index_j,Ny,Nout)
    y1={};
    Fy1={};
    y1_sim={};
    for ii=1:length([z.value]')
        if index_j(ii) <= Ny-Nout(index_i(ii))
            y1{end+1} = (z(ii).value-a)/b;
            Fy1{end+1} = Fz(ii);
            y1_sim{end+1} = z(ii).sim;
        end
    end
    A=struct('sim',y1_sim','y',y1','Fy',Fy1');
end

function result=getSubsetOfData(y0,Fy0,dln_ln_Fy)
    Ny0=length(y0);
    iii=1;
    ii=1;
    y1(iii)=y0(ii);
    Fy1(iii)=Fy0(ii);
    Index_Fy_sub(iii) = ii;
    while ii <=Ny0
        while (-log(-log(Fy0(ii))) + log(-log(Fy1(iii))) < dln_ln_Fy) && ii < Ny0
            ii=ii+1;
        end
        iii=iii+1;
        y1(iii)=y0(ii);
        Fy1(iii)=Fy0(ii);
        Index_Fy_sub(iii) = ii;
        ii=ii+1;
    end
    result = [y1;Fy1;Index_Fy_sub]';
end

% Function for determination of the factor a_MR used in the nominator to
% calculate the empirical distribution function. The factor is determined
% by minimizing the least-squares-error between the empirical aggregated
% distribution function and the analytical "sum of distributions" and "joint
% distributions" found by "fit and aggregate"

function result = a_MR_fit(type_sum,A_sum,type_joint,A_joint,a_yx,b_yx,z,Ny,Nz,NExt,p,index_i,index_j,index_dF,Nout)
    a_MR = 0.3;
    result = a_MR_Minerr(a_MR);
    
    function eps = eps_a_MR_fit(a_MR)
        Fz = EmpiricalDistFunction(a_MR,Ny,Nz,NExt,p,index_i);
       % Fz = EmpiricalDistFunction2(a_MR,x,z,p);
        AA = removeOutliersAggregated(z,0.0,1.0,Fz,index_i,index_j,Ny,Nout);
        z0 = [AA.y]';
        Fz0 = [AA.Fy]';
        Nzz = length(index_dF);
        zz(1:Nzz) = z0(index_dF(1:Nzz));
        Fzz(1:Nzz) = Fz0(index_dF(1:Nzz));
        if (imag(a_MR) ~= 0)
            eps = 100;
        else
            NN = 0;
            eps = 0.0;
            for kk = 1:Nzz
                ln_F = -log(F_Sum_Aggregated(type_sum,A_sum,zz(kk),a_yx,b_yx,p));
                if ln_F > 0.0
                    eps = eps + (-log(ln_F) + log(-log(Fzz(kk))))^2;
                    NN = NN + 1;            
                end
                ln_F = -log(F_Joint_Aggregated(type_joint,A_joint,zz(kk),a_yx,b_yx,p));
                if ln_F > 0.0
                    eps = eps + (-log(ln_F) + log(-log(Fzz(kk))))^2;
                    NN = NN + 1;            
                end       
            end 
            eps = sqrt(eps/NN);
        end
    end

    function eps = eps_a_MR_noSSQ(a_MR)
        Fz = EmpiricalDistFunction(a_MR,Ny,Nz,NExt,p,index_i);
        AA = removeOutliersAggregated(z,0.0,1.0,Fz,index_i,index_j,Ny,Nout);
        z0 = [AA.y]';
        Fz0 = [AA.Fy]';
        Nzz = length(index_dF);
        zz(1:Nzz,1) = z0(index_dF(1:Nzz));
        Fzz(1:Nzz,1) = Fz0(index_dF(1:Nzz));
        if (imag(a_MR) ~= 0)
            eps = ones(Nzz,1)*100;
        else
            ln_Fzz_Sum = -log(Fzz);
            ln_Fzz_Joint = ln_Fzz_Sum;
            ln_F_Sum = -log(F_Sum_Aggregated(type_sum,A_sum,zz,a_yx,b_yx,p));  
            ln_Fzz_Sum(ln_F_Sum <= 0.0) = 1.0;
            ln_F_Sum(ln_F_Sum <= 0.0) = 1.0;
            ln_F_Joint = -log(F_Joint_Aggregated(type_joint,A_joint,zz,a_yx,b_yx,p));
            ln_Fzz_Joint(ln_F_Joint <= 0.0) = 1.0;
            ln_F_Joint(ln_F_Joint <= 0.0) = 1.0;       
            eps = [-log(ln_F_Sum)+ log(ln_Fzz_Sum);-log(ln_F_Joint)+ log(ln_Fzz_Sum)];
        end
    end
   
    function result = a_MR_Minerr(a_MR)
        x0 = a_MR;
      %  options.Algorithm = 'levenberg-marquardt';
        options.Algorithm = 'trust-region-reflective';
        options.Display = 'off';
        fun = @(x) eps_a_MR_noSSQ(x);
        result = lsqnonlin(fun,x0,0.0,0.5,options);
    end

end

function result = epsilon_fit(type,FX,A,a,b,p,y,Fy,e)
    epsilon=0;
    for ii=1:length(y)
        Fx = FX(type,A,y(ii),a,b,p);
        if (Fx+e > 0) && (Fy(ii)+e > 0)
            ln_Fx = -log(Fx+e);
            ln_Fy = -log(Fy(ii)+e);
            if (ln_Fx > 0) && (ln_Fy > 0)
                epsilon = epsilon + (-log(ln_Fx) + log(ln_Fy))^2;
            end
        end
    end
    result = sqrt(epsilon/length(y));
end

function result = rho_fit(type,FX,A,a,b,p,y,Fy,e)
    z1 = zeros(length(y),1);
    z2 = zeros(length(y),1);
    for ii=1:length(y)
        Fx = FX(type,A,y(ii),a,b,p);
        if (Fx+e > 0) && (Fy(ii)+e > 0)
            ln_Fx = -log(Fx+e);
            ln_Fy = -log(Fy(ii)+e);
            if (ln_Fx > 0) && (ln_Fy > 0)
                z1(ii) = -log(ln_Fx);
                z2(ii) = -log(ln_Fy);
            end
        end
    end
    rho_matrix = corrcoef([z1,z2]);
    result = rho_matrix(1,2);
end



%% Distributions
% Normal distribution:
function result = f_N(mu,sigma,x)
    if sigma > 0
       result = LAC.statistic.normalpdf(x,mu,sigma);
    else
        result = 0.0;
    end
end

function result = fd_N(mu,sigma,x) %derivative of pdf with respect to x
    if sigma > 0
       result = LAC.statistic.normalpdf(x,mu,sigma)*(mu - x)/sigma^2;
    else
        result = 0.0;
    end
end

function result = F_N(mu,sigma,x)
    if real(sigma) > 0
        x(imag(x)~=0) = 0;
        mu = real(mu);
        sigma = real(sigma);
        result = max(min(LAC.statistic.normalcdf(x,mu,sigma),1.0-1.0e-15),1.0e-15);
    else
        result = zeros(length(x),1);
    end
end

function result = F_N_inv(mu,sigma,p)
    if sigma > 0
       result = LAC.statistic.normalinvcdf(p)*sigma + mu;
    else
        result = 0.0;
    end
end

% Function for calculation of the m'th order central moment
function result = KCN(mu,sigma,m)
    if mod(m,2)==0
       n = m/2;
       result = factorial(m)*(sigma^m)/( factorial(n)*(2^n) );
    else
        result = 0;
    end
end

% Function for calculation of the m'th order moment
function km = kappa_N(mu,sigma,m)
   km = 0;
   for ii=0:m
      km = km + nchoosek(m,ii)*KCN(mu,sigma,ii)*(mu^(m-ii));
   end
end

% Gumbel Distribution
function result = alpha_G(mu,sigma)
    result = pi/(sqrt(6)*sigma); 
end

function result = u_G(mu,sigma)
    result = mu - eulerMascheroniConstant*sqrt(6)*sigma/pi;
end

function result = F_G(mu,alpha,x)
   if alpha > 0
       result = exp(-exp(-alpha*(x-mu)));
   else
       result = zeros(length(x),1);
   end
end

function result = F_G_inv(mu,alpha,p)
    if alpha > 0
       result =  mu - log(-log(p))/alpha;
    else 
        result = mu;
    end
end

function result = f_G(mu,alpha,x)
   if alpha > 0
       result = alpha*exp(-alpha*(x-mu))*exp(-exp(-alpha*(x-mu)));
   else
       result = 0;
   end
end

function result = fd_G(mu,alpha,x) %derivative of pdf with respect to x
   if alpha > 0
       result = alpha*f_G(mu,alpha,x)*(exp(-alpha*(x-mu)) - 1);
   else
       result = 0;
   end
end

% Lognormal Dist
function result = sigma_n(mu,sigma)
    if mu > 0
        result = sqrt(log( (sigma/mu)^2 + 1 ));
    else 
        result = 0;
    end
end

function result = mu_n(mu,sigma)
    if mu > 0
        result = log(mu) - 0.5*log( (sigma/mu)^2 + 1 );
    else
        result = 0;
    end
end

function result = F_LN(mu_n,sigma_n,x)
    if sigma_n > 0
        x(x<0) = 0;
        x(imag(x)~=0) = 0;
        z = (log(x) - mu_n)./(sqrt(2)*sigma_n);
        result = 0.5*(erfc(-z));
    %    result = LAC.statistic.lognormalcdf(x,mu_n,sigma_n);
    else
        result = zeros(length(x),1);
    end
end

function result = F_LN_inv(mu_n, sigma_n,p)
    if sigma_n > 0
        result = LAC.statistic.invlognormalcdf(p,mu_n,sigma_n);
    else
        result = 0;
    end
end

function result = f_LN(mu_n,sigma_n,x)
    if sigma_n > 0 
        result = LAC.statistic.lognormalpdf(x,mu_n,sigma_n);
    else
        result = 0;
    end
end

function result = fd_LN(mu_n,sigma_n,x) %derivative of pdf with respect to x
    if (sigma_n > 0) && (x > 0.0) 
        result = LAC.statistic.lognormalpdf(x,mu_n,sigma_n)/x*((mu_n - log(x))/sigma_n^2 - 1);
    else
        result = 0;
    end
end

% 2-parameter Weibull distribution
function result = k_w(mu,sigma)
    kappa = sigma^2 + mu^2;
    k0 = 1.5;
    dk = 0.5;
    fun = @(k) ((mu^2/kappa) - (gamma(1+1/k))^2/(gamma(1+2/k)));
    if sigma > 0
        for ii=1:50
            kw = fzero(fun,k0);
            if kw > 0.02
                break;
            end
            k0 = k0 + dk;
        end
    else
        kw = 0.0;
    end
    result = kw;
end

function result = A_w(mu,k)
   result = mu/gamma(1+1/k); 
end

function result = F_w(A,k,x)
    if real(k) > 0
        x(x<0) = 0;
        y = x./A;
        z = y.^k;
        result = -expm1(-z);
        result(imag(result)~=0) = 0;
    else 
        result = zeros(length(x),1);
    end
end

function result = F_w_inv(A,k,p)
   if k > 0.01
      result = A*exp( log(-log(1-p))/k ); 
   else
       result = A;
   end
end

function result = f_w(A,k,x)
    if k > 0
        result = (x/A).^(k-1)*(k/A)*exp(-(x/A).^k);
    else 
        result = zeros(length(x),1);
    end
end

function result = fd_w(A,k,x) %derivative of pdf with respect to x
    if (k > 0) && (x > 0)
        result = f_w(A,k,x)*((k - 1)/x - k/A*(x/A)^(k - 1));
    else 
        result = zeros(length(x),1);
    end
end

%3-parameter Weibull distribution
function result = k_w3(eta)
    k0 = exp(exp(-1.08*eta+0.22));
    dk = 0.2;
    fun = @(k) (eta - (gamma(1+3/k)-3*gamma(1+1/k)*(gamma(1+2/k)-gamma(1+1/k)^2)-gamma(1+1/k)^3)/(gamma(1+2/k)-gamma(1+1/k)^2)^1.5);
    for ii=1:10
        kw = fzero(fun,k0);
        if kw > 0.02
            break;
        end
        k0 = k0 + dk;
    end
    result = kw;
end

%Function for determination of 3rd parameter, b, and scale parameter, A 
function result = Ab_w3(mu,sigma,k)
    b = mu - sigma*gamma(1+1/k)/sqrt(gamma(1+2/k)-gamma(1+1/k)^2);
    A = (mu - b)/gamma(1+1/k) + b;
    result = [A ; b];
end

%% General Functions
% General procedure for determination of parameters in distributions
% determined from mean, mu, standard deviation, sigma, and skewness,
% nu:
function vec = DistPar(type,mu,sigma,eta)
    if strcmp(type,'D')
        vec = [mu; 0; 0];
    elseif strcmp(type,'N')
        vec = [mu; sigma; 0];
    elseif strcmp(type,'LN')
        vec = [mu_n(mu,sigma); sigma_n(mu,sigma); 0];
    elseif strcmp(type,'G')
        vec = [u_G(mu,sigma); alpha_G(mu,sigma); 0];
    elseif strcmp(type,'W2')
        c = k_w(mu,sigma);
        vec = [A_w(mu,c); c; 0];
    end 
end

% Functions for determination of probanility distribution and inverse
% probability distribution:
function result = f_X(type,a,b,c,x)
    if strcmp(type,'N')
        result = f_N(a,b,x);
    elseif strcmp(type,'LN')
        result = f_LN(a,b,x);
    elseif strcmp(type,'G')
        result = f_G(a,b,x);
    elseif strcmp(type,'W2')
        result = f_w(a,b,x);
    else
        error('Invalid type entered. Please enter a valid type.')
    end
end

function result = fd_X(type,a,b,c,x) %derivative of pdf with respect to x
    if strcmp(type,'N') || strcmp(type,'D')
        result = fd_N(a,b,x);
    elseif strcmp(type,'LN')
        result = fd_LN(a,b,x);
    elseif strcmp(type,'G')
        result = fd_G(a,b,x);
    elseif strcmp(type,'W2')
        result = fd_w(a,b,x);
    else
        error('Invalid type entered. Please enter a valid type.')
    end
end

function result = F_X(type,a,b,c,x)
    if strcmp(type,'N') || strcmp(type,'D')
        result = F_N(a,b,x);
    elseif strcmp(type,'LN')
        result = F_LN(a,b,x);
    elseif strcmp(type,'G')
        result = F_G(a,b,x);
    elseif strcmp(type,'W2')
        result = F_w(a,b,x);
    else
        error('Invalid type entered. Please enter a valid type.')
    end
end

function result = F_X_mom(type,mu,sigma,eta,x)
   vec = DistPar(type,mu,sigma,eta);
   result = F_X(type,vec(1),vec(2),vec(3),x);
end

function result = F_X_inv(type,a,b,c,p)
    if strcmp(type,'D')
        result = a;
    elseif strcmp(type,'N')
        result = F_N_inv(a,b,p);
        %result = LAC.statistic.normalinvcdf(p,a,b);
    elseif strcmp(type,'LN')
        result = F_LN_inv(a,b,p);
    elseif strcmp(type,'G')
        result = F_G_inv(a,b,p);
    elseif strcmp(type,'W2')
        result = F_w_inv(a,b,p);
    else
        error('Invalid type entered. Please enter a valid type.')
    end
end

% Moments of order m: % Gumbel is missing!!!!!!!!!!
function result = kappa_X(type,a,b,c,m)
   if strcmp(type,'D')
       result = a^m;
   elseif strcmp(type,'N')
       result = kappa_N(a,b,m);
   elseif strcmp(type,'LN')
       if m*a + 0.5*(m^2)*(b^2) < 500
       result = exp(m*a + 0.5*(m^2)*(b^2));
       else
           result = 0;
       end
   elseif strcmp(type,'W2')
       if (b > 0) && ((m/b) < 100)
           result = a.^m * gamma(1+m/b);
       else
           result = 0;
       end
   end
end

% Mean and standard deviation
function result = MeanStd(type,a,b)
    result = zeros(length(a),2);
    for i=1:length(a)
        if strcmp(type,'G')
           if b > 0 
               mu = a(i) + eulerMascheroniConstant/b(i);
               sigma = pi/(sqrt(6)*b(i));
           else
               mu = 0;
               sigma = 0;
           end
        else
           mu = kappa_X(type,a(i),b(i),0,1);
           sigma = sqrt(kappa_X(type,a(i),b(i),0,2)-mu^2);
        end
        result(i,:) = [mu sigma];
    end
end

function e = eulerMascheroniConstant
    % Symbolic Math Toolbox has builtin function see
    % https://uk.mathworks.com/help/symbolic/eulergamma.html#bt5isgg-2

    % Hard coded to 50 digits to save computation time 
    e = 0.57721566490153286060651209008240243104215933593992;
end

% Check of the parameters to ensure that they are valid for the
% distribution
function checkPassed = DistParCheck(type,a,b,c)
    checkPassed = false;
    if strcmp(type,'D')
        checkPassed = true;
    elseif strcmp(type,'N') || strcmp(type,'LN') || strcmp(type,'G')
        checkPassed = b>0;
    elseif strcmp(type,'W2')
        for i=1:length(b)
            checkPassed = b(i)>0 && b(i) < 200;
        end
    end              
    check2 = (imag(a) == 0) && (imag(b) == 0);
    checkPassed = checkPassed && check2;
end

% Below, the q'th quantile, x0, of the probability distribution F_X is
% found. Initially, an interval for the solution defined by a minimum
% value, x_Min, and a maximum value, x_Max, is determined. Afterwards,
% the solution is found.
function x = x_Min(type,Func,A,a,b,p,q,x0)
    x = x0;
    x_00 = 1;
    i = 0;
    while (Func(type,A,x,a,b,p) <= 0 || Func(type,A,x,a,b,p) >= q) && (i <1000)
        dx = max((x_00 - x0)/2, 0.5*x0);
        if Func(type,A,x,a,b,p) <= 0
            if Func(type,A,x_00,a,b,p) >= q
                x = x_00 - dx;
            else 
                x = max(x_00, x0) + dx;
            end
        else
            if Func(type,A,x_00,a,b,p) >= q
                x = min(x0,x_00) - dx;
            else 
                x = (x_00+x0)/2;
            end
        end
        x_00 = x0;
        x0 = x;
        i = i+1;
    end
end

function x = x_Max(type,Func,A,a,b,p,q,x0)
    x = 2*x0;
    x_00 = 1;
    i = 0;
    while (Func(type,A,x,a,b,p) >= 1 || Func(type,A,x,a,b,p) <= q) && (i <1000)
        Fx=Func(type,A,x,a,b,p);
        dx = max(abs(x_00 - x0)/2, abs(0.5*x0));
        Fx0=Func(type,A,x,a,b,p);
        if Func(type,A,x,a,b,p) >= 1
            if Func(type,A,x_00,a,b,p) <= q
                x = x_00 + dx;
            else 
                x = min(x_00, x0) - dx;
            end
        else
            if Func(type,A,x_00,a,b,p) <= q
                x = max(x0,x_00) + dx;
            else 
                x = (x_00+x0)/2;
            end
        end
        x_00 = x0;
        x0 = x;
        i = i+1;
    end
end

function result = quantiles(FX,type,A,a,b,p,q,x0)
   x_min = x_Min(type,FX,A,a,b,p,q,x0);
   x_max = x_Max(type,FX,A,a,b,p,q,x0);
   fun = @(x) log(-log(FX(type,A,x,a,b,p))) - log(-log(q));
   f_min = fun(x_min);
   f_max = fun(x_max);
   if (f_min > 0.0) && (f_min < Inf) && (f_max < 0.0) && (f_max > -Inf)      
       result = fzero(fun, [x_min x_max]);
   else
       result = 1e20;
   end
end

% Determination of the 2 parameters for a probability distribution so
% that it has 2 prescribed quantities:
function x = DistParQ(a,b,type,y1,y2,F_y1,F_y2)
    x0 = [a,b];
    options.Algorithm = 'levenberg-marquardt';
    options.Display = 'off';
    fun = @(x) [F_X(type,x(1),x(2),0,y1)-F_y1; F_X(type,x(1),x(2),0,y2)-F_y2];
    x = lsqnonlin(fun,x0,[],[],options);
end

function vec = DistParQuantile(type,y1,y2,F_y1,F_y2)
    if strcmp(type,'G')
        G1 = -log(-log(F_y1));
        G2 = -log(-log(F_y2));
        u = (G1*y2 - G2*y1)/(G1-G2);
        alpha = G1/(y1-u);
        vec = [u; alpha];
    end
    if ~strcmp(type,'G')
        G1 = log(-log(1-F_y1));
        G2 = log(-log(1-F_y2));
        A = exp( (log(y1) - log(y2)*G1/G2)/(1-G1/G2) );
        k = G1/(log(y1/A));
        vec = [A; k];
    end
    if ~strcmp(type,'G') && ~strcmp(type,'W2')
        v = MeanStd('W2',A,k);
        v1 = DistPar(type,v(1),v(2),0);
        vec = DistParQ(v1(1),v1(2),type,y1,y2,F_y1,F_y2);
    end
end

function x_sorted = sortMultiDimStruct(x)
    for ii=1:size(x,2)
        Afields=fieldnames(x(:,ii));
        Acell = struct2cell(x(:,ii));
        sz=size(Acell);
        Acell=reshape(Acell,sz(1),[]);
        Acell=Acell';
        Acell=sortrows(Acell,2);
        Acell=reshape(Acell',sz);
        x_sorted(:,ii) = cell2struct(Acell',Afields,2);
    end
end

function sorted_x = Ascend(x)
    epsilon = 0.0001;
    N = length(x);
    for i=1:N-1
        j = 1;
        while x(i+j).value == x(j).value
            x(i+j).value = x(i+j).value + j*epsilon;
            j = j+1;
            if i+j > N
                break;
            end
        end
    end
    sorted_x = sortMultiDimStruct(x);
end

function result = DistInterp(type,xv,Fx,x,num_outliers)
    N = length(xv) - num_outliers;
    im = round(N/2);
    for i=1:length(x)
        if x(i)<xv(1)
            vec=DistParQuantile(type,xv(1),xv(im),Fx(1),Fx(im));
            result(i) = F_X(type,vec(1),vec(2),0,x(i));
        elseif xv(1)<= x(i) && x(i) <= xv(N)
            ln_Fx = -log(-log(Fx));
            result(i) = exp(-exp(-linterp(xv,ln_Fx,x(i))));
        elseif x(i)>xv(N)
            vec=DistParQuantile(type,xv(N),xv(im),Fx(N),Fx(im));
            result(i) = F_X(type,vec(1),vec(2),0,x(i));
        end
    end
end


%% Functions for reports

function [] = LoadExtrapolationReport(SimPath,DLC11,DLC13,Options,Sensors,GrubbsInfo)

% Generates a txt file with main results of the load extrapolation
% 
% Syntax:
%       [] = LoadExtrapolationReport(DLC11,DLC13,Options,Sensors)
% 
% Inputs:
%     - DLC11: cell array which includes the 50 year extrapolated loads. Generated by LoadExtrapolationFitting.
%     - DLC13: structure which includes the 1.3etm extreme loads
%     - Options: structure containing some options for the load extrapolations
%     - Sensors: cell array containing the list of sensor names used for the load extrapolation
%     - GrubbsInfo: structure array containing information regarding the identification of outliers
%
% Outputs:
%     - No numerical outputs. A txt file is generated.

%% Write results in txt file
fidout = fopen([SimPath Options.OutFile,'_DoubleD.txt'],'w');
fprintf(fidout,date); fprintf(fidout,' - load extrapolation\n');
fprintf(fidout,'Path to NTM simulations : %s\n', DLC11.PathDLC11);
fprintf(fidout,'Path to ETM simulations : %s\n', DLC13.PathDLC13);
fprintf(fidout,'Number of extremes per time series: %i\n',DLC11.Options.NExt);
fprintf(fidout,'Significance level for Grubbs test: %1.3f\n',GrubbsInfo.Confidence);
fprintf(fidout,'-----------------------------------------------------------------------------------------------------------------------------\n');
fprintf(fidout,'In the table below:\n');
fprintf(fidout,'Loads are given without PLF. Ratio are given including PLF (1.35 for 1.3etm extreme loads, 1.25 for extrapolated loads)\n');
fprintf(fidout,'Rat1: ratio blade to maximum of 3 blades, for example (extrapolated(blade 1)*1.25)/(max(extreme(3 blades))*1.35).\n');
fprintf(fidout,'FASi: Fit and Aggregate, Single Distr.; FAS: Fit and Aggregate, Sum of Distr.; FAJ: Fit and Aggregate, Joint Distr.\n');
fprintf(fidout,'AFS: Aggregate and Fit, Sum of Distr.; AFJ: Aggregate and Fit, Joint Distr.\n');
fprintf(fidout,'-----------------------------------------------------------------------------------------------------------------------------\n');
fprintf(fidout,'           | ETM load |  Selected Extreme   |  Distribution  |\n');
fprintf(fidout,'    Sensor | (No PLF) |  Extrap.      Rat1  |      type      |\n');
for ii=1:size(Sensors,1)
    if ii < size(Sensors,1) -2
    fprintf(fidout,'%10s | %8.2f | %8.2f      %4.3f |           %4s |\n', Sensors{ii,1}, DLC13.Extremes(ii),...
        DLC11.Fitting{ii}.Extrapolated50, DLC11.Fitting{ii}.Extrapolated50*1.25/(DLC13.Extremes3B(ii)*1.35), DLC11.Fitting{ii}.Type);
    else 
    fprintf(fidout,'%10s | %8.2f | %8.2f      %4.3f |           %4s | \n', ['-' Sensors{ii,1}], DLC13.Extremes(ii),...
        DLC11.Fitting{ii}.Extrapolated50, DLC11.Fitting{ii}.Extrapolated50*1.25/(DLC13.Extremes3B(ii)*1.35), DLC11.Fitting{ii}.Type);
    end
end
if Options.DNV
    fprintf(fidout,'---------------------------------------------------------------------------------------------------------------------------------------------\n');
    fprintf(fidout,'Outputs for documentation: Loads below are the 3 blades average of the selected distribution provided to DNV in addition to bladewise results\n');
    fprintf(fidout,'---------------------------------------------------------------------------------|\n');
    fprintf(fidout,'           |  Ext. per   | Distribution | Extrap. value  |    ETM load   |       |\n');
    fprintf(fidout,'    Sensor | time series |     type     | mean-PLF incl. | max-PLF incl. | Ratio |\n');
    fprintf(fidout,'---------------------------------------------------------------------------------|\n');

    % -Mx?1r
    IndexFamily = find(strcmp(Sensors(:,1),'-Mx11r') | strcmp(Sensors(:,1),'-Mx21r') | strcmp(Sensors(:,1),'-Mx31r'));
    IndexFitting = find([Sensors{IndexFamily(1),3:7}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:7}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:7}]==1);
    
%     if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
%         disp('Error, you should use the same fitting on sensors of the same family')
%         return;
%     end
    fprintf(fidout,'   -Mx?1r  | %6i      | %7s      | %11.2f    | %10.2f    | %4.3f | \n', DLC11.Options.NExt, DLC11.Fitting{IndexFamily(1)}.Type,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25, DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % My?1r
    IndexFamily = find(strcmp(Sensors(1:13,1),'My11r') | strcmp(Sensors(1:13,1),'My21r') | strcmp(Sensors(1:13,1),'My31r'));
    IndexFitting = find([Sensors{IndexFamily(1),3:7}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:7}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:7}]==1);
    
%     if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
%         disp('Error, you should use the same fitting on sensors of the same family')
%         return;
%     end
    fprintf(fidout,'    My?1r  | %6i      | %7s      | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt, DLC11.Fitting{IndexFamily(1)}.Type,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25, DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % Uy
    IndexFamily = find(strcmp(Sensors(:,1),'uy1') | strcmp(Sensors(:,1),'uy2') | strcmp(Sensors(:,1),'uy3'));
    IndexFitting = find([Sensors{IndexFamily(1),3:7}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:7}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:7}]==1);
    
%     if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
%         disp('Error, you should use the same fitting on sensors of the same family')
%         return;
%     end
    fprintf(fidout,'      Uy   | %6i      | %7s      | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt, DLC11.Fitting{IndexFamily(1)}.Type,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25, DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));

    % -My?1r
    IndexFamily = find(strcmp(Sensors(14:end,1),'My11r') | strcmp(Sensors(14:end,1),'My21r') | strcmp(Sensors(14:end,1),'My31r'))+13;
    IndexFitting = find([Sensors{IndexFamily(1),3:7}]==1);
    % check that the 3 sensors use the same fitting
    IndexFitting2 = find([Sensors{IndexFamily(2),3:7}]==1);
    IndexFitting3 = find([Sensors{IndexFamily(3),3:7}]==1);
    
%     if IndexFitting2~=IndexFitting || IndexFitting3~=IndexFitting
%         disp('Error, you should use the same fitting on sensors of the same family')
%         return;
%     end
    fprintf(fidout,'   -My?1r  | %6i      | %7s      | %11.2f    | %10.2f    | %4.3f | \n',DLC11.Options.NExt, DLC11.Fitting{IndexFamily(1)}.Type,...
        -DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25, -DLC13.Extremes3B(IndexFamily(1))*1.35,...
        DLC11.Fitting{IndexFamily(1)}.Extrapolated50_3B*1.25/(DLC13.Extremes3B(IndexFamily(1))*1.35));
    
    fprintf(fidout,'---------------------------------------------------------------------------------|\n');
end
fclose(fidout);

end

function [] = LoadExtrapolationXLS(SimPath,Frq,Extremes,Sensors,Nextremes,Options,DLC11matfile,GrubbsInfo)

% Function adjusted by YAYDE (10/09/2018) - checked MGMMI 11/09/2018
% loading data from stapost file to get the name of the time-series
% correspoing to each extreme, as well as the wind speed and quartile
load(DLC11matfile,'PathDLC11');
load([PathDLC11 filesep 'stapost.mat']);
filename=export.stadat.filenames;
wsIdx=strcmpi(export.stadat.sensor,'Vhfree');
wsraw=export.stadat.mean(wsIdx,:);
ws=round(2*wsraw')/2; % change to account for 1st decimal
quantiles=zeros(size(ws));
for ii=1:length(quantiles)
    qidx=strfind(filename{ii},'q');
    quantiles(ii,1)=str2double(filename{ii}(qidx+1:qidx+2));
end

h = actxserver('excel.application');
%Create a new work book (excel file)
wb = h.WorkBooks.Add();
% Delete old sheets
for i=1:h.Worksheets.Count-1
    h.Worksheets.Item(1).Delete;
end
set(h.Worksheets.Item(1),'Name','Extremes');
ActiveRange = get(h.Activesheet,'Range','A3'); set(ActiveRange, 'Value',  'Probability of the given extremes');
ActiveRange = get(h.Activesheet,'Range','B3'); set(ActiveRange, 'Value',  '-Mx11r');
ActiveRange = get(h.Activesheet,'Range','C3'); set(ActiveRange, 'Value',  '-Mx21r');
ActiveRange = get(h.Activesheet,'Range','D3'); set(ActiveRange, 'Value', '-Mx31r');
ActiveRange = get(h.Activesheet,'Range','E3'); set(ActiveRange, 'Value', 'My11r');
ActiveRange = get(h.Activesheet,'Range','F3'); set(ActiveRange, 'Value', 'My21r');
ActiveRange = get(h.Activesheet,'Range','G3'); set(ActiveRange, 'Value', 'My31r');
ActiveRange = get(h.Activesheet,'Range','H3'); set(ActiveRange, 'Value', 'Uy1');
ActiveRange = get(h.Activesheet,'Range','I3'); set(ActiveRange, 'Value', 'Uy2');
ActiveRange = get(h.Activesheet,'Range','J3'); set(ActiveRange, 'Value', 'Uy3');
ActiveRange = get(h.Activesheet,'Range','K3'); set(ActiveRange, 'Value', '-My11r');
ActiveRange = get(h.Activesheet,'Range','L3'); set(ActiveRange, 'Value', '-My21r');
ActiveRange = get(h.Activesheet,'Range','M3'); set(ActiveRange, 'Value', '-My31r');
ActiveRange = get(h.Activesheet,'Range','N3'); set(ActiveRange, 'Value', 'Simulation Name');
ActiveRange = get(h.Activesheet,'Range','O3'); set(ActiveRange, 'Value', 'Wind Speed');
ActiveRange = get(h.Activesheet,'Range','P3'); set(ActiveRange, 'Value', 'TI Quantile');

XLSindex = [find(strcmpi(Sensors(:,1),'-Mx11r')) ...
    find(strcmpi(Sensors(:,1),'-Mx21r')) ...
    find(strcmpi(Sensors(:,1),'-Mx31r')) ...
    find(strcmpi(Sensors(1:13,1),'My11r')) ...
    find(strcmpi(Sensors(1:13,1),'My21r')) ...
    find(strcmpi(Sensors(1:13,1),'My31r')) ...
    find(strcmpi(Sensors(:,1),'Uy1')) ...
    find(strcmpi(Sensors(:,1),'Uy2')) ...
    find(strcmpi(Sensors(:,1),'Uy3')) ...
    find(strcmpi(Sensors(14:16,1),'My11r'))+13 ...
    find(strcmpi(Sensors(14:16,1),'My21r'))+13 ...
    find(strcmpi(Sensors(14:16,1),'My31r'))+13];
    
XLSData = [Frq/sum(Frq) Extremes(:,XLSindex)];

cell1 = get (h.Activesheet.Cells,'Item',4,1);
cell2 = get (h.Activesheet.Cells,'Item',size(XLSData,1)+4-1,size(XLSData,2));
ActiveRange = get(h.Activesheet,'Range',cell1,cell2);
%JAMTS, here  all the extremes are copied
%to excell from Matrix XLSData[no seeds X Nextremes, 13]; where 13 are the
%following sensors: Probability of the given extremes,-Mx11r,-Mx21r,-Mx31r,My11r,My21r,My31r,Uy1,Uy2,Uy3,-My11r,-My21r,-My31r
set(ActiveRange, 'Value',  XLSData); 

counter=0;
filename_Nextremes = repelem(filename,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes, 
ws_Nextremes = repelem(ws,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes
quantiles_Nextremes = repelem(quantiles,Nextremes);%JAMTS 26/03/2019, correction for taking into account 6 extremes
%Loop copy the name of seeds in order, correction included for 6 extremes
for ic=1:size(XLSData,1)
counter=counter+1;
cell_name = get (h.Activesheet.Cells,'Item',3+ic,size(XLSData,2)+1);
ActiveRange = get(h.Activesheet,'Range',cell_name, cell_name);
set(ActiveRange, 'Value',  filename_Nextremes{ic}); %JAMTS name changed
end

cell1_wind = get (h.Activesheet.Cells,'Item',4,size(XLSData,2)+2);
cell2_wind = get (h.Activesheet.Cells,'Item',size(XLSData,1)+4-1,size(XLSData,2)+3);
ActiveRange = get(h.Activesheet,'Range',cell1_wind,cell2_wind);
set(ActiveRange, 'Value',  [ws_Nextremes quantiles_Nextremes]);%JAMTS name changed

ActiveRange = get(h.Activesheet,'Range','A1'); set(ActiveRange, 'Value', ['Number of extremes per time series: n(V) = ',num2str(Nextremes)]);
ActiveRange = get(h.Activesheet,'Range','A2'); set(ActiveRange, 'Value', 'The "probability of the given extremes" is the probability of the associated 10 minute time series, function of the wind speed probability distribution and the turbulence intensity probability distribution only.');

% Add Outlier Information
h.Worksheets.Add([],h.Worksheets.Item(h.Worksheets.Count));
set(h.Worksheets.Item(2),'Name','Outliers');
ActiveRange = get(h.Activesheet,'Range','A1'); set(ActiveRange, 'Value',  ['Outliers identified with Grubbs statistic test with a significance level of ', num2str(GrubbsInfo.Confidence),'.']);

cell1 = get(h.Activesheet.Cells,'Item',2,1);
cell2 = get(h.Activesheet.Cells,'Item',size(GrubbsInfo.Sensor,1)+1,size(GrubbsInfo.Sensor,2));
range  = get(h.Activesheet, 'Range', cell1, cell2);
set(range,'Value',GrubbsInfo.Sensor);

for isensor = 1 : length(GrubbsInfo.Sensor)
cell1 = get(h.Activesheet.Cells,'Item',size(GrubbsInfo.Sensor,1)+2,isensor);
    if isempty(GrubbsInfo.Seeds{isensor})
        cell2 = get(h.Activesheet.Cells,'Item',size(GrubbsInfo.Sensor,1)+2,isensor);
        range  = get(h.Activesheet, 'Range', cell1, cell2);
        set(range,'Value','-');
    else
        cell2 = get(h.Activesheet.Cells,'Item',size(GrubbsInfo.Seeds{isensor},1)+size(GrubbsInfo.Sensor,1)+1,isensor);
        range  = get(h.Activesheet, 'Range', cell1, cell2);
        set(range,'Value',GrubbsInfo.Seeds{isensor});
    end    
end

% save the file with the given file name, close Excel
wb.SaveAs([SimPath,'/',Options.OutFile,'_DoubleD_Extremes.xlsx']);
wb.Close;
h.Quit;
h.delete;

end


