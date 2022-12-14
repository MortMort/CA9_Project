classdef ReferenceModelGetSet
    properties (Dependent=true, SetAccess=private)
        BLD
        BRK
        CNV
        CTR
        DRT
        FND
        GEN
        HBX
        HUB
        NAC
        PIT
        SEA
        SEN
        TWR
        VRB
        WND
        YAW
        PL
        ERR
    end
    
    methods
        function decoded = get.BLD(self)
            decoded = self.decodePart('BLD');
        end
        function decoded = get.BRK(self)
            decoded = self.decodePart('BRK');
        end
        function decoded = get.CNV(self)
            decoded = self.decodePart('CNV');
        end
        function decoded = get.CTR(self)
            decoded = self.decodePart('CTR');
        end
        function decoded = get.DRT(self)
            decoded = self.decodePart('DRT');
        end
        function decoded = get.FND(self)
            decoded = self.decodePart('FND');
        end
        function decoded = get.GEN(self)
            decoded = self.decodePart('GEN');
        end
        function decoded = get.HBX(self)
            decoded = self.decodePart('HBX');
        end
        function decoded = get.HUB(self)
            decoded = self.decodePart('HUB');
        end
        function decoded = get.NAC(self)
            decoded = self.decodePart('NAC');
        end
        function decoded = get.PIT(self)
            decoded = self.decodePart('PIT');
        end
        function decoded = get.SEA(self)
            decoded = self.decodePart('SEA');
        end
        function decoded = get.SEN(self)
            decoded = self.decodePart('SEN');
        end
        function decoded = get.TWR(self)
            decoded = self.decodePart('TWR');
        end
        function decoded = get.VRB(self)
            decoded = self.decodePart('VRB');
        end
        function decoded = get.WND(self)
            decoded = self.decodePart('WND');
        end
        function decoded = get.YAW(self)
            decoded = self.decodePart('YAW');
        end
        function decoded = get.PL(self)
            decoded = self.decodePart('_PL');
        end
        function decoded = get.ERR(self)
            decoded = self.decodePart('ERR');
        end
    end
    
    methods (Access=private)
        function decoded = decodePart(self, parttype)
            decoded = struct();
            
            filenamePart = self.components(parttype);
            if isempty(regexp(filenamePart, '(@|:|\\\\)', 'once'))
                filenamePart = codec.CleanFileName().absolutePath([self.PartsFolder parttype '\' filenamePart], fileparts(self.FileName));
            end
            
            % Convert to workingcopy
            if ~isempty(strfind(filenamePart,'@'))
                tmp = regexp(filenamePart, '@', 'split');
                versioncontrolinfo = gui.getVersionControlInfo();
                b = versioncontrol.SVNFile(versioncontrolinfo.Repository,versioncontrolinfo.WorkingCopy);
                filenamePart = b.Repository2WorkingCopy(filenamePart);
                b.saveAs(['file:///' tmp{1}], tmp{2}, filenamePart);
            end

            [FID, ~] = fopen(filenamePart,'rt');
            if FID>0
                coder_part = codec.Part();
                decoded = coder_part.decode(FID,parttype);
                fclose(FID);
                
                if isfield(decoded,'AuxDLL')
                    for i = 1:length(decoded.AuxDLL)
                        if isempty(regexp(decoded.AuxDLL{i}.FileName, '(@|:|\\\\)', 'once'))
                            decoded.AuxDLL{i}.FileName = codec.CleanFileName().absolutePath(decoded.AuxDLL{i}.FileName, fileparts(filenamePart));
                        end
                    end
                end
            end
        end
    end
    methods (Abstract)
        findPart(self, searchstring)
    end
end
   