% EE2124 Matlab Script to Optimize Transimpedance Amplifier
clear all; clc;
%addpath('/usr/class/ee114/matlab/hspice_toolbox')

% Setup
format short eng;

% Parameters
uCox = 50e-6;
Cl = 250e-15;
Rl = 10e3/2;
Vtn = 1; % Closer than Vth0
Lmin=1e-6;
lambda=0.1;
VDD= 2.5;

% Constraints
freq_target = 100e6; % > 90
power_target = 2e-3; % 5v * Itotal
I_total = 2e-3/5; % 400uA
Rspec=25e3;
% Initial Estimations
VOV3=0.3;

%% gm3
tau_target=1/(freq_target*2*pi); % Total available Tau
tau_target_out=0.15*tau_target; % Guess tau out = 10% of tau Total
gm3 = (Cl/tau_target_out);
Id3 = VOV3*gm3/2 % 

% Set Id2 & 3 based on budget
Id2= (I_total-2*Id3)/4*4/3% 
Id1= (I_total-2*Id3)/4*2/3%

%% gm_l2
Vg3 = VOV3 + 0 + Vtn; 
VOV_L2 = (VDD - Vg3 - Vtn);
gm_l2 = (2*Id2/VOV_L2)/1.2;
R_l2 = 1/gm_l2;

%% gm_l1 
VOV_L1 = sqrt(2*Id1/(uCox*2))
gm_l1 = 2*Id1/VOV_L1;
R_l1 = 1/gm_l1;

%% gm2
gm2 = 1.5*Rspec/(R_l1*R_l2);
VOV2= 2*Id2/gm2;

%% gm1
VOV1BIAS=1;
VOV1 = 0 - (VOV1BIAS-2.5)- Vtn;
gm1 = 2* Id1/VOV1;

% Core Transistor Sizing
%W3 = 2*Id3/(uCox*VOV3^2*(1+lambda*2.5))*Lmin;
W3 = *Lmin;
W3_ratio = max(2,round(W3/Lmin));

W_L2 = gm_l2/(uCox*VOV_L2)*Lmin;
W_L2_ratio = max(2,round(W_L2/Lmin));
W2 = gm2/(uCox*VOV2)*Lmin;
W2_ratio = max(2,round(W2/Lmin));

W_L1 = gm_l1/(uCox*VOV_L1)*Lmin;
W_L1_ratio = max(2,round(W_L1/Lmin));

W1 = gm1/(uCox*VOV1)*Lmin;
W1_ratio = max(2,round(W1/Lmin));

sprintf('.param W_1=%du\n.param W_2=%du\n.param W_3=%du\n.param W_L1=%du\n.param W_L2=%du',W1_ratio,W2_ratio,W3_ratio,W_L1_ratio,W_L2_ratio)
return

% Bias source sizing based on current requirements

% Craete spice file 
% fwrite(fid, evalc('disp(M3)'))

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

