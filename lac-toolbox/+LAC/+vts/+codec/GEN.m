classdef GEN < LAC.vts.codec.Part_Common
    methods (Static)
        function s = decode(VTSCoder)
            foundACDUMPLOAD = VTSCoder.search('ACDUMPLOAD|number of data points');
            if isempty(foundACDUMPLOAD)
                s = LAC.vts.codec.GENv1.decode(VTSCoder);
            else
                s = LAC.vts.codec.GENv2.decode(VTSCoder);
            end
            
            s = s.convertAllToNumeric();
        end
    end
    
    properties
        Header
        GeneratorInertia
        Polepairs,Fnet,ConstLoss
        TGridErr,HFTorgue
        PelRtd,GenRpmRtd
        Generator1Table
        Generator2Table
        Psc,dtsc
        DelayTime, TorqueRef, TorqueFraction
        Capacity
        ACDumpLoadTable
        AuxLossTable
        comments
    end
    
end
