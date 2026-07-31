%% =========================================================================
% APPENDIX A - COMPLETE SENSITIVITY ANALYSIS (LOCAL + GLOBAL) - COMBINED
% TCO HFCT/BET/ICET - Uruguay, Chile, Spain, Germany (PFG)
%
%   PART 1 (A.1) - LOCAL one-at-a-time sensitivity  -> Figures 8-16
%   PART 2 (A.2) - GLOBAL variance decomposition (Sobol) -> Sobol figures
%
% Shared data (net of recoverable VAT; ETS2 from 2028; EUR/USD = 1.17;
% BET 100% overnight Valle; H2 range UY/CL +/-50%, ES/DE +/-30%).
%
% RUN: press RUN (F5). PART 2 (Sobol) takes ~5-6 min at N=8192 (lower N if slow).
% NOTE: all local functions are at the END of the file (MATLAB requirement).
%% ================== SHARED CONFIGURATION =================================
clear; clc; close all; rng(42,'twister');
P = struct( ...
'name',       {'Uruguay','Chile','Spain','Germany'}, ...
'tau',        {0.13,    0.02,    0.015,   0.015}, ...   % import tariff (s.3.1.5)
'icet',       {120000,  120000,  130000,  130000}, ...  % ICET base 2026
'icetTariff', {false,   true,    true,    true}, ...     % UY already includes fiscal load
'h2a',        {10.00,   10.00,   8.19,    9.36}, ...     % H2 2026 $/kg NET (UY/CL early-deploy; ES/DE real)
'h2b',        {6.00,    6.00,    5.85,    6.44}, ...     % H2 2030 $/kg NET
'elec',       {0.0607,  0.095,   0.0901,  0.1825}, ...   % $/kWh NET (100% Valle)
'diesel',     {1.176,   1.319,   1.470,   1.929}, ...    % $/L NET (excise kept, no relief)
'ets',        {false,   false,   true,    true}, ...      % ETS2 only ES/DE
'tollICET',   {2500,    13250,   2432,    50875}, ...     % ICET toll $/yr (EUR/USD 1.17)
'ii',         {0.040,   0.040,   0.040,   0.040}, ...     % ICET insurance
'iz',         {0.034,   0.036,   0.036,   0.036}, ...     % ZE insurance
'chg',        {0.03,    0.03,    0.05,    0.05});          % charger decadal decline


%% #########################################################################
%% ###############   PART 1 - LOCAL SENSITIVITY (Figs 8-16)   ##############
%% #########################################################################
pB = struct('r',0.095,'maint',0.06,'stackPV',0,'flat',false,'ins',struct());
Ys = 2026:2041;

% --- VERIFICATION: print the 12 baseline TCOs (compare with Excel) ---
tgt = [764604 603710 659430; 915815 671192 618538; ...
       648077 610588 891713; 759234 713334 1268041];   % <-- UPDATE from Excel
dts = {'HFCT','BET','ICET'}; ok = true;
fprintf('=== PART 1: LOCAL SENSITIVITY ===\n');
fprintf('--- 2026 baseline TCO (paste into Excel to verify) ---\n');
fprintf('%-10s %12s %12s %12s\n','Country','HFCT','BET','ICET');
for k = 1:4
    row = zeros(1,3);
    for j = 1:3
        row(j) = tcoCalc(P(k),dts{j},2026,pB);
        if abs(row(j)-tgt(k,j))>2, ok=false; end
    end
    fprintf('%-10s %12.0f %12.0f %12.0f\n',P(k).name,row(1),row(2),row(3));
end
if ok, fprintf('VERIFICATION OK: 12 baseline TCOs match tgt.\n');
else,  warning('Baseline TCOs differ from tgt (expected after the price update) - verify against Excel, then paste into both tgt blocks.'); end

%% ----- TABLA MAESTRA (8 escenarios -> CSV) -----
esc = {'Base',pB};
s=pB; s.r=0.07; esc(end+1,:)={'r = 7%',s};
s=pB; s.r=0.12; esc(end+1,:)={'r = 12%',s};
s=pB; s.maint=0.10; esc(end+1,:)={'HFCT maint $0.10/km',s};
s=pB; s.stackPV=20000/1.095^8; esc(end+1,:)={'Stack repl. yr 8',s};
s=pB; s.flat=true; esc(end+1,:)={'HFCT flat $260k',s};
s=pB; s.ins=struct('Chile',[.04 .04],'Spain',[.04 .04],'Germany',[.04 .04]);
esc(end+1,:)={'No ZE ins. discount',s};
s=pB; s.ins=struct('Uruguay',[.045 .03825],'Chile',[.045 .0405], ...
'Spain',[.025 .0225],'Germany',[.025 .0225]);
esc(end+1,:)={'Diff. ins. 4.5/2.5%',s};
nE=size(esc,1); R=cell(nE,13); hdr={'Escenario'};
for k=1:4, hdr=[hdr,{[P(k).name '_BvI'],[P(k).name '_HvI'],[P(k).name '_HvB']}]; end
for e=1:nE
R{e,1}=esc{e,1}; col=2;
for k=1:4
[H,B,I]=series(P(k),Ys,esc{e,2});
R{e,col}=fy(B<I,Ys); R{e,col+1}=fy(H<I,Ys); R{e,col+2}=fy(H<B,Ys); col=col+3;
end
end
T=cell2table(R,'VariableNames',matlab.lang.makeValidName(hdr));
disp('--- TABLA MAESTRA: break-even years ---'); disp(T);
writetable(T,'tabla_maestra_sensibilidad.csv');

%% ----- FIGURE 8 - DISCOUNT RATE SWEEP 6-13% -----
rs = 0.06:0.0025:0.13; cols = lines(4);
lsty = {'-','-','-','--'}; mk = {'o','s','^','d'};
xoff = [-0.12 -0.04 0.04 0.12];   % small x-offset so coincident lines are visible
fig8 = figure('Position',[40 40 1120 520]);
ttl = {'HFCT < BET','BET < ICET'};
for sp = 1:2
subplot(1,2,sp); hold on; h = gobjects(1,4);
for k = 1:4
xc = nan(size(rs));
for ir = 1:numel(rs)
p = pB; p.r = rs(ir); [H,B,I] = series(P(k),Ys,p);
if sp==1, cc = H<B; else, cc = B<I; end
i1 = find(cc,1); if ~isempty(i1), xc(ir) = Ys(i1); end
end
h(k) = plot(xc + xoff(k), rs*100, lsty{k}, 'Color',cols(k,:), ...
'LineWidth',1.8, 'Marker',mk{k}, 'MarkerSize',4, 'MarkerIndices',1:4:numel(rs));
end
yline(9.5,':k','base 9.5%');
grid on; xlim([2025 2042]); ylim([6 13]);
xlabel('Break-even purchase year'); ylabel('Discount rate (%)');
title(['Break-even year: ' ttl{sp}]);
if sp==1, legend(h,{P.name},'Location','northeast'); end
end
sgtitle('Figure 8 - Break-even year vs discount rate (6-13%); gaps = no crossover by 2041');
saveFig(fig8,'fig_8_discount.png');
p=pB; p.r=.07; fprintf('\nFig.8 r=7%% : '); printCross(P,Ys,p);
p=pB; p.r=.12; fprintf('Fig.8 r=12%% : '); printCross(P,Ys,p);

%% ----- FIGURE 9 - HFCT MAINT $0.10/km -----
p=pB; p.maint=0.10;
plot2x2(P,Ys,pB,p,'HFCT maint. $0.10/km', ...
'Figure 9 - HFCT maintenance at diesel parity ($0.10/km vs $0.06/km baseline)','fig_9_maintenance.png');

%% ----- FIGURE 10 - STACK REPLACEMENT YEAR 8 -----
p=pB; p.stackPV=20000/1.095^8;
plot2x2(P,Ys,pB,p,'HFCT + stack replacement', ...
'Figure 10 - Fuel cell stack replacement in year 8 (+$20,000; PV $9,676 added to HFCT)','fig_10_stack.png');

%% ----- FIGURE 11 - HFCT FLAT $260k FROM 2030 -----
p=pB; p.flat=true;
plot2x2(P,Ys,pB,p,'HFCT flat $260k', ...
'Figure 11 - Flat-cost scenario: HFCT acquisition held at $260,000 from 2030','fig_11_flatcost.png');

%% ----- FIGURE 12 - NO ZE INSURANCE DISCOUNT (CL/ES/DE) -----
p=pB; p.ins=struct('Chile',[.04 .04],'Spain',[.04 .04],'Germany',[.04 .04]);
insFigure(P,Ys,pB,p,'Figure 12 - Removing the assumed ZE insurance discount (CL/ES/DE: 3.6% -> 4.0%)','fig_12_insurance_nodisc.png');

%% ----- FIGURE 13 - DIFFERENTIATED INSURANCE 4.5% LatAm / 2.5% EU -----
p=pB; p.ins=struct('Uruguay',[.045 .03825],'Chile',[.045 .0405], ...
'Spain',[.025 .0225],'Germany',[.025 .0225]);
insFigure(P,Ys,pB,p,'Figure 13 - Differentiated insurance: 4.5%/yr LatAm, 2.5%/yr EU (ZE discounts applied)','fig_13_insurance_diff.png');

%% ----- FIGURE 14 - CDFs OF HFCT TCO/km -----
Phi = @(x) 0.5*erfc(-x/sqrt(2));
SREG = 140871; nn=1:10; vv=1/(1+pB.r); dd=vv.^nn;
Sins = sum((1-0.08*nn).*dd); v10b = vv^10;
yrsCDF = [2026 2030 2035 2040];
cCDF = [0.35 0.62 0.87; 0.47 0.67 0.19; 0.93 0.69 0.13; 0.13 0.32 0.13];
xg = 0.10:0.005:1.00;
fig14 = figure('Position',[40 40 1150 800]);
for k = 1:4
sigkm = SREG*(1+P(k).tau)*(1+P(k).iz*Sins-0.2*v10b)/1.25e6;
subplot(2,2,k); hold on;
for t = 1:4
mu = tcoCalc(P(k),'HFCT',yrsCDF(t),pB)/1.25e6;
plot(xg, Phi((xg-mu)/sigkm)*100, 'Color',cCDF(t,:), 'LineWidth',2);
end
grid on; xlim([0.10 1.00]); ylim([0 100]);
title(sprintf('%s (\\sigma = %.3f $/km)',P(k).name,sigkm));
xlabel('TCO/km HFCT (US$/km)'); ylabel('Cumulative (%)');
legend('2026','2030','2035','2040','Location','southeast');
end
sgtitle({'Figure 14 - Cumulative distribution of HFCT TCO/km by purchase year', ...
'HFCT acquisition cost ~ N(anchor, S = $140,871) from the Section 3.1.3 regression'});
saveFig(fig14,'fig_14_cdf_hfct.png');

%% ----- FIGURES 15-16 - BOXPLOTS OF TCO/km DIFFERENCE -----
rng(42); Nbx = 10000;
for comp = 1:2
figBox = figure('Position',[50 50 1150 800]);
for k = 1:4
sigkm = SREG*(1+P(k).tau)*(1+P(k).iz*Sins-0.2*v10b)/1.25e6;
allD = []; allG = [];
for t = 1:4
hh = tcoCalc(P(k),'HFCT',yrsCDF(t),pB)/1.25e6;
if comp==1, ref = tcoCalc(P(k),'ICET',yrsCDF(t),pB)/1.25e6;
else, ref = tcoCalc(P(k),'BET', yrsCDF(t),pB)/1.25e6; end
d = ref - (hh + sigkm*randn(Nbx,1));
allD = [allD; d]; allG = [allG; repmat(yrsCDF(t),Nbx,1)]; %#ok<AGROW>
end
subplot(2,2,k);
bc = boxchart(allG, allD, 'MarkerStyle','none', 'BoxWidth', 2.5);
bc.BoxFaceColor = [0 .62 .45]; bc.WhiskerLineColor = [0 .45 .35];
hold on; yline(0,'-k','LineWidth',1);
for t = 1:4
dt2 = allD(allG==yrsCDF(t)); ds = sort(dt2);
med = ds(round(0.5*Nbx)); p75 = ds(round(0.75*Nbx));
text(yrsCDF(t), p75+0.05, sprintf('%+.2f',med), ...
'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
grid on; title(P(k).name); ylabel('\Delta TCO/km ($/km)');
ylim([-0.5 1.0]); xlim([2024 2042]); xticks(yrsCDF); xlabel('Purchase year');
end
if comp==1, lbl='ICET - HFCT'; fn='fig_15_box_icet_hfct.png'; fnum='Figure 15';
else,       lbl='BET - HFCT';  fn='fig_16_box_bet_hfct.png';  fnum='Figure 16'; end
sgtitle({sprintf('%s - Distribution of the HFCT per-km saving vs %s, by purchase year',fnum,lbl), ...
'Boxes = interquartile range (50% of cases); positive values = HFCT cheaper'});
saveFig(figBox,fn);
end
fprintf('\nPART 1 done: 9 figures (8-16) + tabla_maestra_sensibilidad.csv\n');


%% #########################################################################
%% ###############   PART 2 - GLOBAL SENSITIVITY (Sobol)   ################
%% #########################################################################
PAR = {
'r'        0.07    0.13      % discount rate (base 0.095)
'caH'      0.80    1.20      % HFCT acquisition-cost multiplier
'maintH'   0.04    0.10      % HFCT maintenance $/km (base 0.06)
'uH2'      0.00    1.00      % H2 price: raw U(0,1), mapped per-country in modelRow
'fElec'    0.75    1.25      % electricity multiplier (+/-25%)
'fDiesel'  0.80    1.20      % diesel multiplier (+/-20%)
'K'        100000  150000    % km/year (base 125000)
'resid'    0.10    0.30      % residual-value fraction (base 0.20)
};
prettyNames = {'Discount rate (r)','HFCT acq. cost (caH)','HFCT maint. (maintH)', ...
'H2 price (uH2 -> per-country fH2)','Electricity (fElec)','Diesel price (fDiesel)', ...
'Annual km (K)','Residual value (resid)'};
Yr = 2030; N = 8192; nboot = 200; k = size(PAR,1);
parNames = PAR(:,1);
outNames = {'HFCT TCO per km','ICET-HFCT margin ($/km)','BET-HFCT margin ($/km)'};

% --- VERIFICATION (parameterized model reproduces the same 12 TCOs) ---
tgt2=[764604 603710 659430; 915815 671192 618538; ...
      648077 610588 891713; 759234 713334 1268041];   % <-- UPDATE from Excel
th0=thBase(); ok2=true;
fprintf('\n=== PART 2: GLOBAL SOBOL ===\n');
fprintf('--- 2026 baseline TCO via tcoG (should match PART 1) ---\n');
for kk=1:4, for j=1:3
g=tcoG(P(kk),dts{j},2026,th0);
if abs(g-tgt2(kk,j))>2, ok2=false; end
end, end
if ok2, fprintf('VERIFICATION OK: parameterized model matches tgt.\n');
else,   warning('Parameterized model differs from tgt (expected after price update) - paste verified 12 TCOs into both tgt blocks.'); end

% --- Sampling and Sobol indices ---
[A,B] = makeAB(N,k);
Res = struct('name',{},'R',{});
for ki=1:4
c = P(ki); f = @(u) modelRow(u,PAR,c,Yr);
Res(ki).name = c.name; Res(ki).R = sobolSaltelli(f,A,B,nboot);
fprintf('Sobol computed: %s\n',c.name);
end

% --- Figures (one per output): sorted, total-order index ---
colT = [0.13 0.47 0.39];
for o=1:3
fg = figure('Position',[40 40 1240 880],'Color','w');
for ki=1:4
Rr = Res(ki).R; ax = subplot(2,2,ki); hold on;
[~,ord] = sort(Rr.ST(:,o),'ascend');
lbl = prettyNames(ord); STv = Rr.ST(ord,o); SEv = Rr.ST_se(ord,o);
cats = categorical(lbl, lbl);
hb = barh(cats, STv, 'FaceColor', colT, 'EdgeColor','none', 'BarWidth', 0.6);
errorbar(hb.XEndPoints, hb.YEndPoints, 1.645*SEv, 'horizontal', ...
'LineStyle','none','Color',[0.25 0.25 0.25],'CapSize',3,'LineWidth',0.8);
for b = 1:numel(STv)
if STv(b) >= 0.02
text(STv(b)+0.03, cats(b), sprintf('%.2f',STv(b)), ...
'FontSize',9.5,'VerticalAlignment','middle','Color',[0.20 0.20 0.20]);
end
end
xlim([0 1.0]); xticks(0:0.2:1);
set(ax,'FontSize',11,'TickDir','out','Box','off','Layer','top');
ax.XGrid='on'; ax.YGrid='off'; ax.GridColor=[0.6 0.6 0.6]; ax.GridAlpha=0.25;
xlabel('Total-order Sobol index S_{Ti}','FontSize',10);
title(sprintf('%s (mean = %.3f $/km)',Res(ki).name,Rr.meanA(o)),'FontSize',12.5,'FontWeight','bold');
end
sgtitle(sprintf('Global sensitivity analysis (Sobol) - output: %s, purchase year %d', ...
outNames{o},Yr),'FontSize',14,'FontWeight','bold');
saveFig(fg,sprintf('fig_sobol_out%d.png',o));
end

% --- Convergence (nested) ---
ki_c = 2; o_c = 3; Nlist = [512 1024 2048 4096 8192]; Nmax = max(Nlist);
[Ac,Bc] = makeAB(Nmax,k);
fc = @(u) modelRow(u,PAR,P(ki_c),Yr);
YAc = evalRows(fc,Ac); YBc = evalRows(fc,Bc); mC = size(YAc,2);
YCc = zeros(Nmax,mC,k); YDc = zeros(Nmax,mC,k);
for i=1:k
ABi=Ac; ABi(:,i)=Bc(:,i); YCc(:,:,i)=evalRows(fc,ABi);
BAi=Bc; BAi(:,i)=Ac(:,i); YDc(:,:,i)=evalRows(fc,BAi);
end
ST_conv = zeros(k,numel(Nlist));
for q=1:numel(Nlist)
nn = Nlist(q);
[~,STq] = sobolIdx(YAc(1:nn,:),YBc(1:nn,:),YCc(1:nn,:,:),YDc(1:nn,:,:));
ST_conv(:,q) = STq(:,o_c);
end
fgc = figure('Position',[60 60 820 560],'Color','w'); hold on;
top = find(ST_conv(:,end) > 0.1); co = lines(max(1,numel(top)));
for j = 1:numel(top)
plot(Nlist, ST_conv(top(j),:), '-o', 'LineWidth',2, 'MarkerSize',7, ...
'MarkerFaceColor','w', 'Color',co(j,:), 'DisplayName',prettyNames{top(j)});
end
grid on; set(gca,'XScale','log','FontSize',11,'TickDir','out','Box','off');
axc=gca; axc.GridColor=[0.6 0.6 0.6]; axc.GridAlpha=0.25;
xticks(Nlist); xticklabels(string(Nlist));
ylo = min(ST_conv(top,:),[],'all'); yhi = max(ST_conv(top,:),[],'all');
pad = max(0.06, yhi-ylo); ylim([max(0,ylo-pad) yhi+pad]);
xlabel('N (base samples)','FontSize',11); ylabel('S_{Ti} (total order)','FontSize',11);
title(sprintf('Convergence of S_{Ti} (nested) - %s, output: %s',P(ki_c).name,outNames{o_c}), ...
'FontSize',12.5,'FontWeight','bold');
legend('Location','best','FontSize',10,'Box','off');
saveFig(fgc,'fig_sobol_convergence.png');

% --- CSV + .mat + summary ---
rows={};
for ki=1:4, Rr=Res(ki).R;
for o=1:3, for i=1:k
rows(end+1,:)={Res(ki).name,outNames{o},parNames{i},Rr.S(i,o),Rr.ST(i,o),Rr.ST_se(i,o)}; %#ok<AGROW>
end, end
end
Tg=cell2table(rows,'VariableNames',{'Country','Output','Parameter','S_first','S_total','S_total_se'});
writetable(Tg,'tabla_sobol_indices.csv');
save('sobol_resultados.mat','Res','PAR','Yr','outNames','parNames','ST_conv','Nlist','N');
fprintf('\n--- GSA SUMMARY (dominant parameter per case, total-order index) ---\n');
for ki=1:4, Rr=Res(ki).R;
for o=1:3
[~,im]=max(Rr.ST(:,o));
fprintf('%-8s | %-26s | dominant: %-8s (S_T=%.2f) | sumS_T=%.2f\n', ...
Res(ki).name,outNames{o},parNames{im},Rr.ST(im,o),sum(Rr.ST(:,o)));
end
end
fprintf('\nALL DONE: 9 local figs (8-16) + 3 Sobol + 1 convergence + 2 CSV + 1 .mat\n');


%% #########################################################################
%% ##############################  FUNCTIONS  ##############################
%% #########################################################################

% ---------- PART 1 helpers (local sensitivity) ----------
function [H,B,I] = series(c,Ys,p)
H = arrayfun(@(Y) tcoCalc(c,'HFCT',Y,p), Ys);
B = arrayfun(@(Y) tcoCalc(c,'BET', Y,p), Ys);
I = arrayfun(@(Y) tcoCalc(c,'ICET',Y,p), Ys);
end

function printCross(P,Ys,p)
for k=1:4
[H,B,I]=series(P(k),Ys,p);
fprintf('%s %s/%s/%s ',P(k).name(1:2),fy(B<I,Ys),fy(H<I,Ys),fy(H<B,Ys));
end
fprintf('\n');
end

function plot2x2(P,Ys,p0,p1,scenLabel,figTitle,fname)
figH = figure('Position',[50 50 1150 800]);
for k=1:4
[H0,B0,I0]=series(P(k),Ys,p0); [H1,B1,I1]=series(P(k),Ys,p1);
h0=H0/1.25e6; h1=H1/1.25e6; b=B1/1.25e6; i=I1/1.25e6;
subplot(2,2,k); hold on;
plot(Ys,i,'-','Color',[.45 .45 .45],'LineWidth',2);
plot(Ys,b,'-','Color',[0 .45 .70],'LineWidth',2);
plot(Ys,h0,'-','Color',[0 .62 .45],'LineWidth',2.2);
plot(Ys,h1,'--','Color',[0 .62 .45],'LineWidth',2.2);
fill([Ys fliplr(Ys)],[h0 fliplr(h1)],[0 .62 .45],'FaceAlpha',.12,'EdgeColor','none');
grid on; xlim([2026 2041]); ylim([0.25 1.35]);
title(P(k).name); xlabel('Purchase year'); ylabel('TCO per km ($/km)');
txt=sprintf('H<ICET: %s \\rightarrow %s | H<BET: %s \\rightarrow %s', ...
fy(H0<I0,Ys),fy(H1<I1,Ys),fy(H0<B0,Ys),fy(H1<B1,Ys));
text(2026.3,1.28,txt,'FontSize',9,'FontWeight','bold','BackgroundColor',[1 1 1 .7],'Margin',2);
legend('ICET','BET','HFCT baseline',scenLabel,'Location','southeast');
end
sgtitle({figTitle,'Annotation: break-even years, baseline \rightarrow scenario'});
saveFig(figH,fname);
fprintf('\n%s\n base: ',figTitle); printCross(P,Ys,p0);
fprintf(' escen: '); printCross(P,Ys,p1);
end

function insFigure(P,Ys,p0,p1,figTitle,fname)
d=zeros(4,3);
for k=1:4
d(k,1)=tcoCalc(P(k),'ICET',2026,p1)-tcoCalc(P(k),'ICET',2026,p0);
d(k,2)=tcoCalc(P(k),'BET', 2026,p1)-tcoCalc(P(k),'BET', 2026,p0);
d(k,3)=tcoCalc(P(k),'HFCT',2026,p1)-tcoCalc(P(k),'HFCT',2026,p0);
end
cats=reordercats(categorical({P.name}),{P.name});
figH = figure('Position',[60 60 950 540]);
hb=bar(cats,d/1000,'grouped');
hb(1).FaceColor=[.45 .45 .45]; hb(2).FaceColor=[0 .45 .70]; hb(3).FaceColor=[0 .62 .45];
for s=1:3
xt=hb(s).XEndPoints; yt=hb(s).YEndPoints;
lb=compose('%+.1f',d(:,s)'/1000); lb(d(:,s)'==0)={'0'};
off=0.12*sign(yt); off(off==0)=0.12;
text(xt,yt+off,lb,'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
legend('ICET','BET','HFCT','Location','best'); grid on;
ylabel('\Delta TCO 2026 (thousand USD)');
ylim([min(0,min(d(:)/1000))-2 max(d(:)/1000)+2]);
title({figTitle,'Zeros are the finding: rates unchanged for those cases'});
saveFig(figH,fname);
fprintf('\n%s\n base: ',figTitle); printCross(P,Ys,p0);
fprintf(' escen: '); printCross(P,Ys,p1);
end

function out = fy(cond,Ys)
i=find(cond,1);
if isempty(i), out='>2041'; else, out=num2str(Ys(i)); end
end

function t = tcoCalc(c,dt,Y,p)
K=125000; n=1:10; v=1/(1+p.r); disc=v.^n;
a10=sum(disc); S=sum((1-0.08*n).*disc); v10=v^10; yrs=Y:Y+9;
aY=[2026 2030 2035 2040 2045 2050];
if p.flat, aV=[400000 260000 260000 260000 260000 260000];
else, aV=[400000 260000 200000 183000 167000 150000];
end
pV=[105 75 60 55 52 50];
icetB=@(y) c.icet*1.03.^((y-2026)/10);
ii=c.ii; iz=c.iz;
if isfield(p.ins,c.name), o=p.ins.(c.name); ii=o(1); iz=o(2); end
switch dt
case 'HFCT'
Ca=interp1(aY,aV,Y)*(1+c.tau);
fuel=arrayfun(@(y)(0.078-(0.078-0.067)*min(y-2026,4)/4)*h2p(y,c.h2a,c.h2b)*K,yrs);
m=p.maint*K; a=iz; infra=0; toll=tollZE(c,yrs); ex=p.stackPV;
case 'BET'
Ca=(1.60*0.97^((Y-2026)/10)*icetB(Y)+interp1(aY,pV,Y)*800)*(1+c.tau);
fuel=ones(1,10)*1.34*c.elec*K;
m=0.06*K; a=iz; infra=140000*(1-c.chg)^((Y-2026)/10)*(1+c.tau);
toll=tollZE(c,yrs); ex=0;
case 'ICET'
if c.icetTariff, Ca=icetB(Y)*(1+c.tau); else, Ca=icetB(Y); end
fuel=arrayfun(@(y)0.359*c.diesel*1.02^(y-2026)*K + c.ets*ets2c(y,K),yrs);
m=0.10*K; a=ii; infra=0; toll=ones(1,10)*c.tollICET; ex=0;
end
t=Ca+infra+sum(fuel.*disc)+m*a10+a*Ca*S+sum(toll.*disc)-0.2*Ca*v10+ex;
end

% ---------- PART 2 helpers (Sobol) ----------
function th = thBase()
th = struct('r',0.095,'K',125000,'caH',1,'maintH',0.06, ...
'fH2',1,'fElec',1,'fDiesel',1,'uH2',0.5,'resid',0.20, ...
'izMult',1,'stackPV',0,'fETS',1);
end

function y = modelRow(u,PAR,c,Yr)
th = thBase();
for j=1:size(PAR,1)
th.(PAR{j,1}) = PAR{j,2} + u(j)*(PAR{j,3}-PAR{j,2});
end
% --- per-country fH2 override (UY/CL +/-50%, ES/DE +/-30%) ---
if any(strcmp(c.name, {'Uruguay','Chile'}))
   th.fH2 = 0.5 + th.uH2 * 1.0;   % UY/CL: 0.5-1.5
else
   th.fH2 = 0.7 + th.uH2 * 0.6;   % ES/DE: 0.7-1.3
end
Kkm = th.K*10;
H = tcoG(c,'HFCT',Yr,th)/Kkm;
I = tcoG(c,'ICET',Yr,th)/Kkm;
Bt= tcoG(c,'BET', Yr,th)/Kkm;
y = [H, I-H, Bt-H];
end

function [A,B] = makeAB(N,k)
rng(42,'twister');
try
ps = sobolset(2*k,'Skip',1024,'Leap',101);
ps = scramble(ps,'MatousekAffineOwen');
U = net(ps,N);
catch
U = rand(N,2*k);
end
A = U(:,1:k); B = U(:,k+1:2*k);
end

function R = sobolSaltelli(f,A,B,nboot)
[N,k]=size(A);
YA=evalRows(f,A); YB=evalRows(f,B); m=size(YA,2);
YC=zeros(N,m,k); YD=zeros(N,m,k);
for i=1:k
ABi=A; ABi(:,i)=B(:,i); YC(:,:,i)=evalRows(f,ABi);
BAi=B; BAi(:,i)=A(:,i); YD(:,:,i)=evalRows(f,BAi);
end
[R.S,R.ST]=sobolIdx(YA,YB,YC,YD);
R.meanA=mean(YA,1); R.stdA=std(YA,0,1);
R.S_se=zeros(k,m); R.ST_se=zeros(k,m);
if nboot>0
Sb=zeros(k,m,nboot); STb=zeros(k,m,nboot);
for b=1:nboot
idx=randi(N,N,1);
[sb,stb]=sobolIdx(YA(idx,:),YB(idx,:),YC(idx,:,:),YD(idx,:,:));
Sb(:,:,b)=sb; STb(:,:,b)=stb;
end
R.S_se=std(Sb,0,3); R.ST_se=std(STb,0,3);
end
end

function [S,ST]=sobolIdx(YA,YB,YC,YD)
[~,m]=size(YA); k=size(YC,3);
VarY = var([YA;YB],0,1);
S=zeros(k,m); ST=zeros(k,m);
for i=1:k
yc=YC(:,:,i); yd=YD(:,:,i);
mu = mean((YA+yd)/2, 1);
num = mean(YA.*yd, 1) - mu.^2;
den = mean((YA.^2+yd.^2)/2, 1) - mu.^2;
S(i,:) = num./den;
ST(i,:)= 0.5*mean((YA-yc).^2,1)./VarY;
end
end

function Y=evalRows(f,U)
N=size(U,1); y1=f(U(1,:)); m=numel(y1);
Y=zeros(N,m); Y(1,:)=y1;
for r=2:N, Y(r,:)=f(U(r,:)); end
end

function t = tcoG(c,dt,Y,th)
K=th.K; r=th.r; n=1:10; v=1/(1+r); disc=v.^n;
a10=sum(disc); S=sum((1-0.08*n).*disc); v10=v^10; yrs=Y:Y+9;
aY=[2026 2030 2035 2040 2045 2050];
aV=[400000 260000 200000 183000 167000 150000];
pV=[105 75 60 55 52 50];
icetB=@(y) c.icet*1.03.^((y-2026)/10);
ii=c.ii; iz=c.iz*th.izMult;
switch dt
case 'HFCT'
Ca=interp1(aY,aV,Y)*(1+c.tau)*th.caH;
fuel=arrayfun(@(y)(0.078-(0.078-0.067)*min(y-2026,4)/4)*h2p(y,c.h2a,c.h2b)*th.fH2*K,yrs);
m=th.maintH*K; a=iz; infra=0; toll=tollZE(c,yrs); ex=th.stackPV;
case 'BET'
Ca=(1.60*0.97^((Y-2026)/10)*icetB(Y)+interp1(aY,pV,Y)*800)*(1+c.tau);
fuel=ones(1,10)*1.34*c.elec*th.fElec*K;
m=0.06*K; a=iz; infra=140000*(1-c.chg)^((Y-2026)/10)*(1+c.tau);
toll=tollZE(c,yrs); ex=0;
case 'ICET'
if c.icetTariff, Ca=icetB(Y)*(1+c.tau); else, Ca=icetB(Y); end
fuel=arrayfun(@(y)0.359*c.diesel*th.fDiesel*1.02^(y-2026)*K + c.ets*ets2c(y,K)*th.fETS,yrs);
m=0.10*K; a=ii; infra=0; toll=ones(1,10)*c.tollICET; ex=0;
end
t=Ca+infra+sum(fuel.*disc)+m*a10+a*Ca*S+sum(toll.*disc)-th.resid*Ca*v10+ex;
end

% ---------- shared helpers ----------
function pr = h2p(y,p26,p30)
if y<=2026, pr=p26;
elseif y<=2030, pr=p26+(p30-p26)*(y-2026)/4;
else, pr=p30*0.99^(y-2030); end
end

function e = ets2c(y,K)
% ETS2 starts Jan 2028; ramp 45 -> 150 EUR/tCO2 over 2028-2040 (12 yrs).
% 1.17 converts EUR/tCO2 -> USD/tCO2 (2026 average EUR/USD).
CO2t=0.359*K*2.68/1000;
if y<2028, e=0; else, e=CO2t*min(45+105*(y-2028)/12,150)*1.17; end
end

function t = tollZE(c,yrs)
% Germany: zero-emission Lkw-Maut exempt until 30 Jun 2031, then reduced (1.17).
if strcmp(c.name,'Germany'), t=(yrs>2031)*12750;
else, t=ones(1,numel(yrs))*c.tollICET; end
end

function saveFig(figH,fname)
% Robust save: never throws; warns if all methods fail (MATLAB Online glitch).
if nargin<1 || isempty(figH) || ~isgraphics(figH,'figure'), figH=gcf; end
drawnow; pause(0.2); ok=false;
try exportgraphics(figH,fname,'Resolution',300); ok=true; catch, end
if ~ok, try saveas(figH,fname); ok=true; catch, end, end
if ~ok, try print(figH,'-dpng','-r300',fname); ok=true; catch, end, end
if ~ok, try fr=getframe(figH); imwrite(fr.cdata,fname); ok=true; catch, end, end
if ~ok, warning('Could not save %s (MATLAB Online glitch). Save by hand: File > Save As.',fname); end
end
