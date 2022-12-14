function [CpMax, idMax ] = findCpMaxVsTSR(Cp, cpMaxFactor, direction)
if nargin<3
    direction = 'last';
end

% Cp : tsr x pitch
CpMax = zeros(1,size(Cp,1));
idMax = zeros(size(Cp,1),1);
for tsrIdx = 1:size(Cp,1)
    CpVsTSR                     = Cp(tsrIdx, :);
    [maxCpVsTSR, idxMaxVsTSR]   = max(CpVsTSR);
    CpVsTSRcut                  = CpVsTSR(idxMaxVsTSR:end);
    ratio2CpMax                 = round(CpVsTSRcut./maxCpVsTSR,2);
    if maxCpVsTSR>0
        idCut                   = find(ratio2CpMax >= cpMaxFactor, 1, direction);
    else
        idCut                   = find(ratio2CpMax <= cpMaxFactor, 1, direction);
    end
    idMax(tsrIdx)               = idxMaxVsTSR + idCut -1;
    CpMax(tsrIdx)               = CpVsTSR(idMax(tsrIdx));
end








