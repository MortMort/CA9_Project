function dd = aerodiff(lambda,theta,aero)

        lambda_delta = 1;
        theta_delta = 1;
        
        lambda1 = min(lambda+lambda_delta,max(aero.lambda));
        lambda2 = max(lambda-lambda_delta,min(aero.lambda));
        theta1 = min(theta+theta_delta,max(aero.theta));
        theta2 = max(theta-theta_delta,min(aero.theta));
        
        cM = aero.cp./(ones(length(aero.theta),1)*aero.lambda'); 
        cT = aero.ct;
        
        dd.cM = interp2(aero.lambda',aero.theta,cM,lambda,theta,'spline');
        
        %dcM/dlambda
        cM1 = interp2(aero.lambda',aero.theta,cM,lambda1,theta,'spline');
        cM2 = interp2(aero.lambda',aero.theta,cM,lambda2,theta,'spline');
        dd.dcM.dl = (cM1-cM2)/(lambda1-lambda2);
        
        %dcM/dtheta
        cM1 = interp2(aero.lambda',aero.theta,cM,lambda,theta1,'spline');
        cM2 = interp2(aero.lambda',aero.theta,cM,lambda,theta2,'spline');
        dd.dcM.dth = (cM1-cM2)/(theta1-theta2);
        
        dd.cT = interp2(aero.lambda',aero.theta,cT,lambda,theta,'spline');
        
        %dcT/dlambda
        cT1 = interp2(aero.lambda',aero.theta,cT,lambda1,theta,'spline');
        cT2 = interp2(aero.lambda',aero.theta,cT,lambda2,theta,'spline');
        dd.dcT.dl = (cT1-cT2)/(lambda1-lambda2);
        
        %dcT/dtheta
        cT1 = interp2(aero.lambda',aero.theta,cT,lambda,theta1,'spline');
        cT2 = interp2(aero.lambda',aero.theta,cT,lambda,theta2,'spline');
        dd.dcT.dth = (cT1-cT2)/(theta1-theta2);
end