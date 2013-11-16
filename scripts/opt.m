% EE2124 Matlab Script to Optimize Transimpedance Amplifier
clear all; clc;
%addpath('/usr/class/ee114/matlab/hspice_toolbox')

% Setup
format short eng;

% Parameters
uCox = 50e-6;
Cox = 2.3e-3;% fF/um^2
mu_n = uCox/Cox;
Cl = 2*500e-15;
Cin = 100e-15;
Rl = 10e3/2;
Vtn = 1; % Closer than Vth0
Lmin=1e-6;
lambda=0.1;
VDD= 2.5;

% Constraints
freq_target = 100e6; % > 90
power_target = 2e-3; % 5v * Itotal
I_total = 2e-3/5; % 400uA
Rspec=15e3/2;
% Initial Estimations
VOV3=0.2;

%% gm3
tau_target=1/(freq_target*2*pi); % Total available Tau
tau_target_out=0.4*tau_target; % Guess tau out = 10% of tau Total
gm3 = (Cl/tau_target_out);
Id3 = VOV3*gm3/2 % 

% Set Id2 & 3 based on budget
Id2= (I_total-2*Id3)/4*3/5% 
Id1= (I_total-2*Id3)/4*2/5%
% 7.9530u  177.2793u   37.8186u
%Id3 = 177e-6
%Id2 = 6.4e-6
%Id1 = 18e-6 % Fixed by exploration
%Id2 = 5.6e-6
%Id3 = 140e-6
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
gm2 = Rspec/(R_l1*R_l2);
VOV2= 2*Id2/gm2;
VOV2=0.2;
%gm2 = 2*Id2/VOV2;

%% gm1
VOV1BIAS=1;
VOV1 = 0 - (VOV1BIAS-2.5)- Vtn;
gm1 = 2* Id1/VOV1;

% Core Transistor Sizing
W3 = 2*Id3/(uCox*VOV3^2)*Lmin;
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

%the gate bias for curent mirrors is set by a diode connected NMOS which
%has as current source to the drain

%biasing circuot 
Iref = 18e-6;
W_dr = 4e-6;
L_dr = 2e-6;
vdd=2.5;
vt=0.5;
vss = -2.5;
Vov_pmos = -1;

Iref_actual= (uCox/4)*(W_dr/L_dr)*(Vov_pmos)^2;
vov_dr= sqrt((2*Iref)/(uCox*(W_dr/L_dr)));
vds_pmos= 2.5-vov_dr+vss;
Lmin_cs=2e-6;
vbiasgen = vov_dr+0.5+vss;
res =(vdd-vbiasgen)/Iref;

Mb1_ratio= round(Id1/((uCox/2)*(vbiasgen-vss-vt)^2));
Mb2_ratio= round(Id2/((uCox/2)*(vbiasgen-vss-vt)^2));
Mb3_ratio= round(Id3/((uCox/2)*(vbiasgen-vss-vt)^2));

Mb1_Width = Mb1_ratio*Lmin_cs;
Mb2_Width= Mb2_ratio*Lmin_cs;
Mb3_Width = Mb3_ratio*Lmin_cs;

% Bias source sizing based on current requirements
Wb1_ratio= round(Id1/((uCox/2)*(vbiasgen-vss-0.5)^2)*2);
Wb2_ratio= round(Id2/((uCox/2)*(vbiasgen-vss-0.5)^2)*2);
Wb3_ratio= round(Id3/((uCox/2)*(vbiasgen-vss-0.5)^2)*2);
sprintf('.param WB1=%du\n.param WB2=%du\n.param WB3=%du',Wb1_ratio,Wb2_ratio,Wb3_ratio)

%fprintf(Mb2_ratio);


% Craete spice file 
% fwrite(fid, evalc('disp(M3)'))

%% ZVTC based Models 

% Coeffitients
alpha1= 0.26; % Csb1/Cgs1 
beta1 = 0.25; % Cgd1/Cgs1
gamma1 = 0.41; % Cdb1/Cgs1
beta2 = beta1;
gamma2 = gamma1;
beta3 = beta2;

A = 1+alpha1;
B = beta1 + gamma1;
C = beta2;
D = gamma2;
E = beta3;
F = C+1;
G = C+D;
H = E + 1/6;

% Tau 
Aspec = 10e3;
t0_vov = (2*Lmin^2)/(3*mu_n); % T0 by Vov 
tau_in =  (Cin + A*2*Id1/VOV1^2 * t0_vov) /(1.2*gm1)
tau_out = ( 5*2*Id3/VOV3^2 *t0_vov + 6*Cl/5)/gm3
tau_core = 2 * t0_vov * VOV2*( Aspec/0.8 * ( B* Id1/VOV1^2 + (F+C*VOV_L2/VOV2)*Id2/VOV2^2) + VOV_L2/(2*Id2)*(G*Id2/VOV2^2 + H*Id3/VOV3^2))
tau_total = tau_in + tau_out + tau_core;
f3db = 1/(tau_total*2*pi)
return
%% Exploration of VOV3
VOV3=[0.15:.001:2];
tau_core = 2 * t0_vov * VOV2*( Aspec/0.8 * ( B* Id1/VOV1^2 + (F+C*VOV_L2/VOV2)*Id2/VOV2^2) + VOV_L2/(2*Id2)*(G*Id2/VOV2^2 + H*Id3./VOV3.^2));
plot(VOV3,tau_core);
%% Exploration of VOV2 VOV1

VO2=[0.15:0.01:6];
VO1=[0.15:0.01:6];

%tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1/VOV1^2 + (F+C*VOV_L2/VOV2).*Id2/VOV2^2) + VOV_L2./(2*Id2).*(G*Id2/VOV2^2 + H*Id3/VOV3^2));
[VOV_L1,VOV_L2] = meshgrid(VO1,VO1);


tau_in =  (Cin + A*2*Id1./VOV1^2 * t0_vov) ./(1.2*2*Id1)*VOV1; 
tau_out = ( 5*2*Id3./VOV3^2 *t0_vov + 6*Cl/5)*VOV3./(2*Id3);
tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1./VOV1^2 + (F+C*VOV_L2./VOV2)*Id2./VOV2^2) + VOV_L2./(2*Id2).*(G*Id2./VOV2^2 + H*Id3./VOV3^2));

mesh(VO1,VO2,tau_core./max(max(tau_core)));

title ('Tau(Id1,Id2)');
xlabel('VOV1')
ylabel('VOV2')
%% Exloration of Id1
Id2=[4e-6:0.1e-6:8e-6];
Id1=400e-6 - 2*Id3 - 2*Id2;

%tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1/VOV1^2 + (F+C*VOV_L2/VOV2).*Id2/VOV2^2) + VOV_L2./(2*Id2).*(G*Id2/VOV2^2 + H*Id3/VOV3^2));
[I1,I2] = meshgrid(Id1,Id2);

tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* I1./VOV1^2 + (F+C*VOV_L2/VOV2)*I2./VOV2^2) + VOV_L2./(2*I2).*(G*I2./VOV2^2 + H*Id3/VOV3^2));

mesh(Id1,Id2,tau_core./max(max(tau_core)));

title ('Tau(Id1,Id2)');
xlabel('Id1')
ylabel('ID2')
%% Reexploration of Id1
Id1=[0e-6:0.1e-6:50e-6];

tau_in =  (Cin + A*2*Id1./VOV1^2 * t0_vov) ./(1.2*2*Id1)*VOV1; 
tau_out = ( 5*2*Id3./VOV3^2 *t0_vov + 6*Cl/5)*VOV3./(2*Id3);
tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1./VOV1^2 + (F+C*VOV_L2./VOV2)*Id2./VOV2^2) + VOV_L2./(2*Id2).*(G*Id2./VOV2^2 + H*Id3./VOV3^2));

plot(Id1,tau_core);
%% Exloration of Id3
%Id3=[170e-6 - 100e-6 : 1e-6: 170e-6 + 850e-6];;  Id1=72e-6;
%Id2=[17.9e-6 - 10e-6 : 1e-6: 17.9e-6 + 175e-6];
Id3=[170e-6 - 70e-6 : 1.5e-6: 200e-6];;  
Id2=[3e-6: 1e-6: 20e-6 + 40e-6]; % 
Id1=8.5e-6;
VOV_L1=0.3832;
VOV1=0.154;
VOV2=0.282;
VOV_L2=0.393;
VOV3=0.346; 

[I3,I2] = meshgrid(Id3,Id2);

tau_in = 5/6*(Cin*VOV1/2/Id1 + A*t0_vov/VOV1);
tau_out = 5/6*(t0_vov/VOV3 + VOV3*Cl/2./I3);
tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1./VOV1^2 + (F+C*VOV_L2/VOV2)*I2./VOV2^2) + VOV_L2./(2*I2).*(G*I2./VOV2^2 + H*I3/VOV3^2));
tau_total = tau_in + tau_out + tau_core;
mesh(Id3,Id2,tau_total./max(max(tau_total)))

%mesh(Id3,Id2,tau_core./max(max(tau_core)));
title ('Tau(Id3,Id2)');
xlabel('Id3')
ylabel('Id2')
%% Fine tuning 
Id1=[8.5e-6 - 5e-6 : 1e-6: 8.5e-6 + 95e-6];
%Id2=[17.9e-6 - 15e-6 : 0.1e-6: 17.9e-6 + 15e-6];
Id2=[42.9e-6 - 40e-6 : 1e-6: 42.9e-6 + 56e-6]; 
%Id3=70e06;
Id3=420e-6;
VOV_L1=0.3832;
VOV1=0.154;
VOV2=0.282;
VOV_L2=0.393;
VOV3=0.346;
 
[I1,I2] = meshgrid(Id1,Id2);

tau_in = 5/6*(Cin*VOV1/2./I1 + A*t0_vov/VOV1);
tau_out = 5/6*(t0_vov/VOV3 + VOV3*Cl/2./Id3);
tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* I1./VOV1^2 + (F+C*VOV_L2/VOV2)*I2./VOV2^2) + VOV_L2./(2*I2).*(G*I2./VOV2^2 + H*Id3/VOV3^2));
tau_total = tau_in + tau_out + tau_core;
mesh(Id1,Id2,tau_total./max(max(tau_total)));

%gain=VOV_L1./(2*I1).*VOV_L2./(VOV2)*0.8; 

%figure(1);
%mesh(Id1,Id2,tau_total./max(max(tau_total)));
%mesh(Id1,Id2,tau_in./max(max(tau_in)));
%mesh(Id1,Id2,tau_core);
title ('Tau(Id1,Id2)');
xlabel('Id1')
ylabel('Id2') 

%%
clc;
Id1=8.5e-6; Id2=17.9e-6; Id3=170e-6;
VOV_L1=0.3832;
VOV1=0.154;
VOV2=0.2819;
VOV_L2=0.393;
VOV3=0.346; 
%tau_in =  (Cin + A*2*Id1./VOV1^2 * t0_vov) ./(1.2*2*Id1)*VOV1 
%tau_out = ( 5*2*Id3/VOV3^2 *t0_vov + 6*Cl/5)*VOV3./(2*Id3)
tau_in = 5/6*(Cin*VOV1/2/Id1 + A*t0_vov/VOV1)
tau_out = 5/6*(t0_vov/VOV3 + VOV3*Cl/2/Id3)
tau_core = 2 * t0_vov * VOV2.*( Aspec/0.8 * ( B* Id1./VOV1^2 + (F+C*VOV_L2/VOV2)*Id2./VOV2^2) + VOV_L2./(2*Id2).*(G*Id2./VOV2^2 + H*Id3/VOV3^2))
tau_total = tau_in + tau_out + tau_core
f3db = 1/(tau_total*2*pi)
gain=VOV_L1./(2*Id1).*VOV_L2./VOV2*(0.8)^2

%% VOV tuning
Id1=8.5e-6; Id2=17.9e-6; Id3=170e-6;
VOV_L1=0.3832;
VOV1=0.154;
VOV2=[0.15:0.1:4];
VOV_L2=0.393;
VOV3=[0.15:0.1:4]; 

[VO2,VO3] = meshgrid(VOV2,VOV3);

tau_in = 5/6*(Cin*VOV1/2/Id1 + A*t0_vov/VOV1);
tau_out = 5/6*(t0_vov./VO3 + VO3*Cl/2/Id3);
tau_core = 2 * t0_vov * VO2.*( Aspec/0.8 * ( B* Id1./VOV1^2 + (F+C*VOV_L2./VO2)*Id2./VO2.^2) + VOV_L2./(2*Id2).*(G*Id2./VO2.^2 + H*Id3./VO3.^2));
tau_total = tau_in + tau_out + tau_core;
figure(1);
mesh(VOV2,VOV3,tau_total./max(max(tau_total)));

gain=VOV_L1./(2*Id1).*VOV_L2./VOV2*(0.8)^2
figure(2);
plot(VOV2,gain);
%%

f3db = 1/(tau_total*2*pi);








%%
%plot(Id2,tau_core);


title ('Tau(Id1,Id2)');
xlabel('Id1')
ylabel('ID2')
%hleg1 = legend('V_{ov,min}=0.1541)','NorthWest');

%set(hleg1,'FontSize',16);
figureHandle = gcf;
%# make all text in the figure to size 14 and bold
set(findall(figureHandle,'type','text'),'fontSize',16,'fontWeight','bold')
%%
x = -8:.5:8; y=x;
[X,Y] = meshgrid(x,y);
R=sqrt(X.^2 + Y.^2) + eps;
Z = sin(R)./R;
mesh(x,y,Z);
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

