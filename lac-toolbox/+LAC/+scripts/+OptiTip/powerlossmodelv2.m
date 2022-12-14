%function Pel=powerlossmodel(gloss,mloss,auxloss,rpm,Paero)
%
%Computes electrical power from aero power using the VTS-style loss model.
% v2: extrapolation of losses
%
%***INPUTS:
%
%NOTE: (the body of the tables are the loss factors.  
% The first row and first column are the "labels" for power and generator rpm.)
%
%gloss-generator electrical loss table matrix.
%       1st row - power (kw)
%       1st col - generator rpm
%
%mloss-mechanical loss table matrix.
%       1st row - power (kw)
%       1st col - generator rpm
%
%auxloss-auxiliary loss table matrix
%       1st row - power (kw)
%       1st col - generator rpm
%
%rpm-generator rpm (high speed shaft)
%
%Paero-aero power
%
%***OUTPUT:
%
%Pel - electrical power output with losses included
%
%//RLINK

function Pel=powerlossmodelv2(gloss,mloss,auxloss,rpm,Paero)
    
    %get the row and column values from each table
    mech_pow=mloss(1,2:end)';
    mech_rpm=mloss(2:end,1);
    
    gen_pow=gloss(1,2:end)';
    gen_rpm=gloss(2:end,1);
    
    aux_pow=auxloss(1,2:end)';
    aux_rpm=auxloss(2:end,1);
    
    %clear the row and column labels
    mloss(:,1)=[];
    mloss(1,:)=[];
    gloss(:,1)=[];
    gloss(1,:)=[];
    auxloss(1,:)=[];
    auxloss(:,1)=[];
    
    auxloss=auxloss';
    mloss=mloss';
    gloss=gloss';
    
    conv=1e10;
    tol=0.01; %max percent difference for iterative convergence
    maxit=100; %maximum iterations
    iter=1;
    
    Pel_curr=Paero;
    
    %iteratively converge on the correct loss factors
    while (conv>tol) && (iter<maxit)
        
        mf=interp1(mech_pow,mloss,Pel_curr,'linear','extrap');  %mech loss factor
        mf=interp1(mech_rpm,mf,rpm,'linear','extrap');
        gf=interp1(gen_pow,gloss,Pel_curr,'linear','extrap');  %generator electrical loss factor
        gf=interp1(gen_rpm,gf,rpm,'linear','extrap');
        
        Pel_new=Paero*gf*mf;
        conv=(Pel_curr-Pel_new)/Pel_curr;
        Pel_curr=Pel_new;
        
        iter=iter+1;
    end
    
    af=interp1(aux_pow,auxloss,Pel_curr,'linear','extrap');  %aux loss factor
    af=interp1(aux_rpm,af,rpm,'linear','extrap');
        
    Pel=Pel_curr*af;
  