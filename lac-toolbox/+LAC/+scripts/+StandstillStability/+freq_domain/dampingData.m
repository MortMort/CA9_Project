function dampingData(damping,bladeProps,turbname,outpath)
% Extracts the single blade damping data from the VStab analysis and
% calculates 2D damping data using the VStab inputs.

ws = damping.wsp;

load([outpath '/' turbname '_PitchSweep_' num2str(ws) '.mat'])

% May be moved outside function.
yawerr = [wdir(wdir>=180)-360 wdir(wdir<180)];

%Blade Data
R=bladeProps.SectionTable.R(2:end);%Define radial sections
beta=bladeProps.SectionTable.beta(2:end);%Define the section twist radial distribution

N=length(wdir);

idx=[N/2+1:N,1:N/2];
BOdamping=zeros(1,length(wdir));
BOomega=BOdamping;
for i=idx
    BOdamping(i) = Res.logdecrement{1,i}(2);
	BOomega(i) = imag(Res.eigvals{1,i}(2));
end

save([outpath '/' turbname '_BOdamping'],'R','beta','ws','wdir','yawerr','idx','BOdamping','BOomega')


damping = LAC.scripts.StandstillStability.freq_domain.SDOFDamping(Res,Flow,1,2,bladeProps);
save([outpath '/' turbname '_SDOF2Ddamping'],'damping')
