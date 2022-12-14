classdef CTRRelease
    methods (Static)
        function [CTRrelease, CTRdate] = get(RefmodelData)
            CTRrelease = RefmodelData('ControlRelease');
            CTRdate = RefmodelData('ControlReleaseDate');
        end
        
        function status = verify(CTRrelease, CTRdate)
            % CTR Release, e.g. 2014.08 or 2014.08.207
            CtrReleaseOk = false;
            res = regexp(CTRrelease,'[0-9]{4}\.[0-9]{2}(.[0-9]+)?','match');
            if length(res)==1 && strcmp(res,CTRrelease)
                if strcmpi(CTRrelease(1:7), datestr(datenum(CTRrelease(1:7),'yyyy.mm'),'yyyy.mm'))
                    CtrReleaseOk = true;
                end
            end
            if isempty(CTRrelease) || strcmpi(CTRrelease, 'UNKNOWN')
                CtrReleaseOk = true;
            end

            % CTR Release Date, e.g. 20141030
            CtrDateOk = false;
            res = regexp(CTRdate,'[0-9]{8}','match');
            if length(res)==1 && strcmp(res,CTRdate)
                if strcmpi(CTRdate, datestr(datenum(CTRdate,'yyyymmdd'),'yyyymmdd'))
                    CtrDateOk = true;
                end
            end
            if isempty(CTRdate) || strcmpi(CTRdate, 'UNKNOWN')
                CtrDateOk = true;
            end
            
            status = CtrReleaseOk && CtrDateOk;
        end
    end
end
   