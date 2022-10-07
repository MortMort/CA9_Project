clc; clear; close all

% Generator
syms P Ploss(P,omega) omega Mgen


Mgen = (P + Ploss)/omega;

MgenJacob = jacobian(Mgen, [P; omega])