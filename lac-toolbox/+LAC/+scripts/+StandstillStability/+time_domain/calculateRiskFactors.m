function calculateRiskFactors(config,turbname,outfolder)
% Script to calculate risk factors i.e. Zfac, Wfac and assemble loads
% matrix.

%% Data processing
N=length(config.azim); M=length(config.wdir); ...
        H = length(config.pitch_misalignment);...
    LoadsWD=zeros(N*3,M,H,length(config.wsps));  Loads=LoadsWD; ... % for the azimuth of each blade i.e. azim*3

Zfac=zeros(length(config.wsps),1); % initialize    

load([outfolder '/' turbname '_' config.case '_' 'Loads_PP.mat']) % robustify for idle
for k=1:length(config.wsps) % wind speed
    for m=1:H % pitch misalignment
        for j=1:N % azim
            for l=1:M % wdir
                LoadsWD(j,l,m,k) = My1.range(H*N*M*(k-1)+N*M*(m-1)+M*(j-1)+l);
                LoadsWD(j+N,l,m,k) = My3.range(H*N*M*(k-1)+N*M*(m-1)+M*(j-1)+l);
                LoadsWD(j+2*N,l,m,k) = My2.range(H*N*M*(k-1)+N*M*(m-1)+M*(j-1)+l);
            end
        end
        Loads(:,:,:,k)=[LoadsWD(:,ceil(M/2)+1:M,:,k),LoadsWD(:,1:ceil(M/2),:,k)]; % for each yaw direction (pos, neg)
        Zfac(k)=length(find(Loads(:,:,:,k)>config.p2pMoment))/(M*N*H*3); % (My*r,azim,wdir > p2pmom) / (wdir,azim)*3  
    end
end

% map variables for storage
wdir = config.wdir;
yawerr = config.yawerr;
azim = config.azim;
mis = config.pitch_misalignment;    
wsps = config.wsps;    
p2pMoment = config.p2pMoment;

save([outfolder '\' turbname '_' config.case '_' 'ZFac.mat'],'wdir','yawerr','azim','mis','wsps','p2pMoment','Loads','Zfac','M','N')
