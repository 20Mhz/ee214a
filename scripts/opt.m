% EE2124 Matlab Script to Optimize Transimpedance Amplifier
clear all; clc;
%addpath('/usr/class/ee114/matlab/hspice_toolbox')

% Setup
format short eng;

% Parameters
uCox = 50e-6;
Cl = 500e-15/2;
Rl = 10e3;
Vtn = 0.5;
Lmin=1e-6;
lambda=0.1;
VDD= 2.5;

% Constraints
freq_target = 100e6; % > 90
power_target = 2e-3; % 5v * Itotal
I_total = 2e-3/5; % 400uA

% Initial Estimations
VOV3=0.3;

%% gm3
tau_target=1/(freq_target*2*pi); % Total available Tau
tau_target_out=0.1*tau_target; % Guess tau out = 10% of tau Total
gm3 = Cl/tau_target_out;
Id3 = VOV3*gm3/2; % seems too high

% Set Id2 & 3 based on budget
Id2= (I_total-2*Id3)/4;% too high
Id1= (I_total-2*Id3)/4;%
Id2= 40e-6;
Id1= 40e-6;

%% gm_l2
Vg3 = VOV3 + 0 + Vtn; 
VOV_L2 = (VDD - Vg3 - Vtn);
gm_l2 = 2*Id2/VOV_L2;
R_l2 = 1/gm_l2


% Core Transistor Sizing
M3 = 2*Id3/(uCox*VOV3^2)*Lmin
M3_ratio = round(M3/Lmin)
M_L2 = gm_l2/(uCox*VOV_L2)*Lmin
M_L2_ratio = round(M_L2/Lmin)

% Bias source sizing based on current requirements

% Craete spice file 
% fwrite(fid, evalc('disp(M3)'))

return
%% Models 
% Gain
Reff = Rcg * gm2 * Rd2;
% Target Reff = 20e3

% ZVTC 
% Starts from input side to output;
tau1 = (Cgs1 + Csb1) * (Rd1); 
tau2 = (Cgd1 + Cdb1 + Cgs2) * Rcg; 
tau3 =  Cgd2 * (Rout_1 *  1/sum(1./[ro Rd2])* gm2 +  1/sum(1./[ro Rd2]) + Rout_1); 
tau4 = (Cdb2 + Cgd3) * 1/sum(1./[ro2 Rd2]);  
tau5 =  Cgs3 * (Rout_2 *  1/sum(1./[Rl  ro3]) * gm3 + Rout_2 + 1/sum(1./[Rl ro3])); 
tau6 = (Cl + Csb3) * 1/sum(1./[Rl ro3]) ;

w_3db = 1/(tau1 + tau2 + tau3 + tau4 + tau5 + tau6);
% Target w_3db = 2*pi*90MHz


%% Load Simulation Data 
%h = loadsig('part3.sw0');
%lssig(h)
%idn = evalsig(h,'i_mn1');

% Visualization
%figure(1);
%plot(vds, idn, 'linewidth', 2);
%set(gca,'FontSize',14);
%title('NMOS 10/1')
%xlabel('V_D_S [V]');
%ylabel('I_D [A]');
%grid;

