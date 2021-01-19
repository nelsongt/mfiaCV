%%%%% Copyright George Nelson 2020 %%%%%

clear
format long
% Setup PATH

%%%%%%% Begin Main %%%%%%
File_Name = 'GPD1-10VPre_290'

[Sample_Name,Area,Temp,Data] = FileRead(File_Name);
total = length(Data);

% Constants, change for your device and material
vac_perm = 8.854e-12; %F/m
rel_perm = 13.9;
die_const = vac_perm*rel_perm; %F/m
area_m = Area * 1e-6; %m^2
elem_char = 1.602e-19; %C

%%% Calculate Doping vs Depletion %%%
Biases = Data(:,1);
Caps = Data(:,2);

cap_m = (1/area_m) .* Caps;
cap_sqinv = cap_m .^ -2;

%%% This section smoothes data in incremental moving sections, it
%%% truncates the data based on smoothing value so it is somewhat incomplete. 
%%% Adjust until satisfied

smoothing = 10; %must be even number

slopes = zeros(length(Biases)-smoothing,1);
smoothcaps = zeros(length(Biases)-smoothing,1);
for ii = 1:(length(Biases)-smoothing)
    fitdop = polyfit(Biases(ii:ii+smoothing),cap_sqinv(ii:ii+smoothing),2);
    derdop = polyder(fitdop);
    slopes(ii) = polyval(derdop,Biases(ii+smoothing/2));
    
    fitdep = polyfit(Biases(ii:ii+smoothing),Caps(ii:ii+smoothing),2);
    smoothcaps(ii) = polyval(fitdep,Biases(ii+smoothing/2));
end

%%% End of moving section smoothing

%%% Following section fits the entire dataset to a polynomial before
%%% processing, it works well for many occasions but sometimes incremental
%%% smoothing is needed. Adjust along with above smoothing to find best fit

fitorder = 10;  % polynomial fit order

[capfit,S] = polyfit(Biases,cap_sqinv,fitorder);
[fitcaps,delta] = polyval(capfit,Biases,S);

dopfit = polyder(capfit);
fitslopes = polyval(dopfit,Biases);

%%% End of full segment smoothing

Dops = (2e-6/(die_const*elem_char))* (slopes .^ -1);
Deps = (area_m * 1e9 * die_const) ./ smoothcaps; %nm
FitDops = (2e-6/(die_const*elem_char))* (fitslopes .^ -1);
FitDeps = (1e9 * die_const) ./ (fitcaps.^(-0.5)); %nm


%%% Plotting %%%
% Direct data fit plot %
figure
hold on
plot(Biases,cap_sqinv, '+b')
plot(Biases,fitcaps,'-r', Biases,fitcaps+delta,'-g', Biases,fitcaps-delta,'-g')
grid
hold off


% Zoomable plot, check doping fits %
figure
hold on
plot(FitDeps,FitDops);
xlabel('Distance From Junction (nm)','fontsize',14);
ylabel('Doping (cm^{-3})','fontsize',14);
set(gca, 'XScale', 'lin','xlim',[min(FitDeps) max(FitDeps)]);
set(gca, 'YScale', 'log','ylim',[1e14 1e18]);
set(gca, 'YGrid', 'on', 'XGrid', 'on');
plot(Deps,Dops);
hold off



% No-zoom bias plot %
%Setup tick marks
bias_step = 1.0;
jj = 1;
start = ceil(Biases(1)/bias_step);
stop = floor(Biases(length(Biases))/bias_step);
for nn = start:stop
    x2tik(jj) = nn*bias_step;
    jj = jj+1;
end
xtik = interp1(Biases,FitDeps,x2tik);

figure
hold on;
plot(FitDeps,FitDops);
set(gca, 'XScale', 'lin','xlim',[min(FitDeps) max(FitDeps)]);
set(gca, 'YScale', 'log','ylim',[1e14 1e18]);
%set(gca, 'YScale', 'log');
set(gca, 'YGrid', 'on', 'XGrid', 'on');
ax1 = gca;
xlabel('Distance From Junction (nm)','fontsize',14);
ylabel('Doping (cm^{-3})','fontsize',14);
pos=get(gca,'position');  % retrieve the current values
pos(4)=0.95*pos(4);       % try reducing height 5%
set(gca,'position',pos);  % write the new values
ax2 = axes('Position',ax1.Position,...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'xlim',[min(FitDeps) max(FitDeps)],...
    'XTick',xtik,...
    'XScale','lin',...
    'Color','none',...
    'ytick',[]);
%Replace ticks with biases
xlabel('Reverse Bias (V)','fontsize',14);
xt = get(gca, 'XTick');
[UniDeps index] = unique(FitDeps); % Small trick to avoid error in case of repeated values
xt2 = interp1(UniDeps,Biases(index),xt);
set(gca, 'XTickLabel', xt2);
hold off;

% Weighted doping in certain volume
Spacing = Deps(2:length(Deps))-Deps(1:length(Deps)-1);
SpacingTrunc = Spacing((smoothing/2)+1:length(Spacing)-(smoothing/2));
weighted = SpacingTrunc(15:105).*Dops(15:105);
doping = sum(weighted)/sum(SpacingTrunc(15:105));
