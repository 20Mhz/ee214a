* Design Problem, ee114/214A- 2012
* Please fill in the specification achieved by your circuit 
* before your submit the netlist.
**************************************************************
* The specifications that this script achieves are:
* 
* Power  =    mW 
* Gain   =    K
* BandWidth =   MHz
***************************************************************


** Including the model file
.include /usr/class/ee114/hspice/ee114_hspice.sp

* Defining Top level circuit parameters
.param Cin = 100f
.param CL  = 500f
.param RL  = 10K

* defining the supply voltages

vdd vdd 0 2.5
vss vss 0 -2.5
.param gnd=0

* Defining the input current source

** For ac simulation uncomment the following 2 lines**
*Iina		iina	vdd	ac	0.5	
*Iinb		vdd	iinb	ac	0.5	

** For transient simulation uncomment the following 2 lines**
Iina		iina	vdd	sin(0 0.5u 1e6) ac 0.5
Iinb		vdd	iinb	sin(0 0.5u 1e6) ac 0.5

* Defining Input capacitance

Cina	vdd	iina 'Cin'
Cinb	vdd	iinb 'Cin'

* Defining the differential load 

RL	vouta		voutb		'RL'
CL	vouta		voutb		'CL'

*** Your Trans-impedance Amplifier here ***
.include './sizes.inc'

*Plus side
*CG
ML1a vdd vdd vo1a   vss nmos114 w='W_L1' l='L_L1' 
M1a  vo1a gnd iina  vss nmos114 w='W_1' l='L_1' 
  
*CS
M2a  vo2a vo1a vs2a  vss nmos114 w='W_2' l='L_2'
ML2a vdd vdd vo2a   vss nmos114 w='W_L2' l='L_L2'

*CD
M3a  vdd vo2a vouta vss nmos114 w='W_3' l='L_3' 

*Minus side
*CG
ML1b vdd vdd vo1b   vss nmos114 w='W_L1' l='L_L1' 
M1b  vo1b gnd iinb  vss nmos114 w='W_1' l='L_1' 
  
*CS
M2b  vo2b vo1b vs2a  vss nmos114 w='W_2' l='L_2'
ML2b vdd vdd vo2b   vss nmos114 w='W_L2' l='L_L2'

*CD
M3b  vdd vo2b voutb vss nmos114 w='W_3' l='L_3'

*** Your Bias Circuitry here ***

****Biasing FETs for positive output*****
.param Id1=9u, Id2=18.6u, Id3=170u
Ids1 iina vss 'Id1'
Ids2 vs2a vss 'Id2'
Ids3 vouta vss 'Id3'
Ids1b iinb vss 'Id1'
Ids2b vs2a vss 'Id2'
Ids3b voutb vss 'Id3'
*Mb1a  iina nbias  vss vss   nmos114 w='W_b1' l='L_b1'
*Mb2a  vs2a nbias  vss vss   nmos114 w='W_b2' l='L_b2'
*Mb3a  vouta nbias vss vss   nmos114 w='W_b3' l='L_b3'
*
****Biasing FETs for negative output same sizes as correspiding biasing fets on positive side*****
*
*Mb1b  iinb nbias  vss vss   nmos114 w='W_b1' l='L_b1'
*Mb2b  vs2a nbias  vss vss   nmos114 w='W_b2' l='L_b2'
*Mb3b  voutb nbias vss vss   nmos114 w='W_b3' l='L_b3'
*
** Reference device
*Mdrv  nbias nbias vss vss      nmos114 w=16u l=2u
*
*** for students enrolled in ee114, you can use the given ideal voltage source
*Vbias_n nbias gnd -1.6724

** For students enrolled in ee214A, you need to design your bias ciruit. You cannpt use Vbias_n as ideal voltage source.



* defining the analysis

.op
.option post brief nomod

** For ac simulation uncomment the following line** 
.ac dec 100 100 1g

** For transient simulation uncomment the following line **
.tran 0.01u 4u 
.probe i(*) v(*)
.end

