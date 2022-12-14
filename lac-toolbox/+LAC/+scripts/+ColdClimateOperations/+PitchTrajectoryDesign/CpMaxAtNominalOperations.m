function CpMaxVsTSR_Btuning = CpMaxAtNominalOperations(CpTable, TSRTable, TSR)

CpMaxVsTSR_Btuning = max(CpTable,[],1);
CpMaxVsTSR_Btuning = interp1(TSRTable, CpMaxVsTSR_Btuning,TSR,'linear','extrap');
CpMaxVsTSR_Btuning = CpMaxVsTSR_Btuning';