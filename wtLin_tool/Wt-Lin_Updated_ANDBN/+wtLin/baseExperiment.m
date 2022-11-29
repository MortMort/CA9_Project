classdef baseExperiment < handle
    
   properties (Access = protected) 
        lp; %Linearised parameters
        comp; %Components
        loop; %Loops
   end
   

   
   methods  (Access = public)
       function obj=baseExperiment(varargin)
           switch nargin
               case 1
                   obj.lp=varargin{1};
                   obj.reComputeModel();        
               otherwise
           end
           
       end
       
       function updateLP(obj,lp)
            obj.lp=lp;
            obj.reComputeModel();
       end
       
       function res=getLP(obj)
            res=obj.lp;
       end
       
        function res=getCLref(obj)
            s=obj.loop.s;
            stat=obj.lp.s.stat;
            if(stat.ctr.FullLoad)
                res=s.FLC_CL;
            else
                res=s.PLC_CL;
            end
        end
        
        function res=getOLref(obj)
            s=obj.loop.s;
            stat=obj.lp.s.stat;  %%%%%%%%%%%%%%%% error corrected
            if(stat.ctr.FullLoad)
                res=s.FLC_OL;
            else
                res=s.PLC_OL;
            end
        end
        
        function res=getCLWndDist(obj)
            s=obj.loop.s;
            stat=obj.lp.s.stat;   %%%%%%%%%%%%%%%% error corrected
            if(stat.ctr.FullLoad)
                res=s.FLC_WndCL;   %%%%%%%%%%%%%%%% error corrected
            else
                res=s.PLC_WndCL;   %%%%%%%%%%%%%%%% error corrected
            end
        end
        
        function res=getLoopByName(obj,name)
            s=obj.loop.s;
            res=s.(name);
        end

        
        function res=getLoopByEndNameAutoCtrl(obj,endName)
            s=obj.loop.s;
            stat=obj.lp.s.stat;
            if(stat.ctr.FullLoad)
                name = ['FLC_' endName];
                res=s.(name);
            else
                name = ['PLC_' endName];
                res=s.(name);
            end
        end

        
        function res=getLoopList(obj)
          m=obj.loop.asMap();
          res=m.keys();  
        end
        
        function res=getLoops(obj)
            res=obj.loop;
        end
        
        function res=getComps(obj)
            res=obj.comp;
        end    
       
   end
   
    methods (Access = protected)
        function reComputeModel(obj)
            import wtLin.* 
            obj.comp=comps.calcComps(obj.lp);
            obj.loop=loops.calcLoops(obj.comp);
        end
    end
    
    methods (Static)
        function obj=create(lp,comp,loop)
           obj=wtLin.baseExperiment();
           obj.lp=lp;
           obj.comp=comp;
           obj.loop=loop;
       end
    end
   
end