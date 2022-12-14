classdef VTSCodec < handle
    methods (Abstract)
        getType(self)
        compare(self, obj)
        verify(self, obj)
        search(self, obj)
    end
end
   