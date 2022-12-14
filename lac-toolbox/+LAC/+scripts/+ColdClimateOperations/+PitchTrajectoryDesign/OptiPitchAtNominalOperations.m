function pitchVsTSR_Btuning = OptiPitchAtNominalOperations(pitchVsTSR_Btuning_temp, pitAngle)

for n = 1:length(pitchVsTSR_Btuning_temp)
    [~,I] = min(abs(pitchVsTSR_Btuning_temp(n) - pitAngle));
    pitchVsTSR_Btuning(n) = pitAngle(I);
end