classdef experiment < wtLin.baseExperiment
     
    properties (Access = private)
        gp; %Gross parameters
        op; %Operating point
    end
    
    methods  (Access = public)
        function obj=experiment(gp,op)
          lp=wtLin.linparms.calcParms(gp,op);
          obj=obj@wtLin.baseExperiment(lp);
          obj.gp=gp;
          obj.op=op;
          obj.lp=lp;
        end
        
        function updateGP(obj,gp)
             obj.gp=gp;
             obj.reComputeLP();
             obj.reComputeModel();
        end
        
        function updateOP(obj,op)
            obj.gp=op;
            obj.reComputeLP();
            obj.reComputeModel();
        end
        
        function updateGPOP(obj,gp,op)
            obj.gp=gp;
            obj.gp=op;
            obj.reComputeLP();
            obj.reComputeModel();
        end
        
        function gp=getGP(obj)
            gp=obj.gp;
        end
        
        function gp=getOP(obj)
            gp=obj.gp;
        end
        
        function be=baseExperiment(obj)
            be=wtLin.baseExperiment.create(obj.lp,obj.comp,obj.loop);       
        end
                      
       
   end
    
    methods (Access = private)
        function reComputeLP(obj)
            import wtLin.* 
            obj.lp=linparms.calcParms(obj.gp,obj.op);
        end
    end
    
end



