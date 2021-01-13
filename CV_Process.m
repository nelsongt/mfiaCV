%%%%% Copyright George Nelson 2020 %%%%%

clear
format long
% Setup PATH

%%%%%%% Begin Main %%%%%%
File_Name = 'GAP500-VI-10VPre_290'

[Sample_Name,Area,Temp,Data] = FileRead(File_Name);
total = length(Data);

%% Calculate Doping vs Depletion
Biases = Data(:,1);
Caps = Data(:,2);

%Depletion
vac_perm = 8.854e-12; %F/m
rel_perm = 13.9;
die_const = vac_perm*rel_perm; %F/m
area_m = Area * 1e-6; %m^2

Deps = (area_m * 1e9 * die_const) ./ Caps; %nm

%Doping
elem_char = 1.602e-19; %C
cap_m = (1/area_m) .* Caps;
cap_sqinv = cap_m .^ -2;

smoothing = 4; %must be even number

slopes = zeros(length(Biases)-smoothing,1);
for ii = 1:(length(Biases)-smoothing)
    fit = polyfit(Biases(ii:ii+smoothing),cap_sqinv(ii:ii+smoothing),1);
    slopes(ii) = fit(1);
end

Dops = (2e-6/(die_const*elem_char))* (slopes .^ -1);


%% Plotting
figure
plot(Deps(((smoothing/2)+1):length(Deps)-(smoothing/2)),Dops);
xlabel('Distance From Junction (nm)','fontsize',14);
ylabel('Doping (cm^{-3})','fontsize',14);
set(gca, 'XScale', 'lin','xlim',[0 Deps(length(Deps))]);
set(gca, 'YScale', 'log','ylim',[1e14 1e18]);
set(gca, 'YGrid', 'on', 'XGrid', 'on');



% No-zoom bias plot
%Setup tick marks
bias_step = 1.0;
jj = 1;
start = ceil(Biases(1)/bias_step);
stop = floor(Biases(length(Biases))/bias_step);
for nn = start:stop
    x2tik(jj) = nn*bias_step;
    jj = jj+1;
end
xtik = interp1(Biases,Deps,x2tik);

figure
hold on;
plot(Deps(((smoothing/2)+1):length(Deps)-(smoothing/2)),Dops);
set(gca, 'XScale', 'lin','xlim',[Deps(1) Deps(length(Deps))]);
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
    'xlim',[Deps(1) Deps(length(Deps))],...
    'XTick',xtik,...
    'XScale','lin',...
    'Color','none',...
    'ytick',[]);
% Replace ticks with biases
xlabel('Reverse Bias (V)','fontsize',14);
xt = get(gca, 'XTick');
[UniDeps index] = unique(Deps); % Small trick to avoid error in case of repeated values
xt2 = interp1(UniDeps,Biases(index),xt);
set(gca, 'XTickLabel', xt2);
hold off;

% Weighted doping in certain volume
Spacing = Deps(2:length(Deps))-Deps(1:length(Deps)-1);
SpacingTrunc = Spacing(smoothing/2:length(Spacing)-(smoothing/2));
weighted = SpacingTrunc(15:105).*Dops(15:105);
doping = sum(weighted)/sum(SpacingTrunc(15:105));
