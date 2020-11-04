%%% MFIA C-V Profiler %%%  Author: George Nelson 2020
% Set sample info
sample.user = 'George';
sample.material = 'In0.53Ga0.47As';
sample.name = 'GPD2-1MeVF2';
sample.area = '0.196';  % mm^2
sample.comment = 'Long integration';

% Set YSpec experiment parameters
mfia.sample_time = 7;    % sec, length to sample each temp point, determines speed of scan and SNR
bias_start = 0.1;      % V, start bias
bias_final = -4;      % V, final bias
bias_step = 0.02;      % V, Bias step size

% Set temperature parameters
temp_init = 250;        % K, Initial temperature
temp_step = 150;         % K, Temperature step size
temp_final = 100;        % K, Ending temperature
temp_idle = 250;        % K, Temp to set after experiment is over
temp_stability = 0.05;   % K, Sets how stable the temperature point must be (set point +- stability)
time_stability = 20;    % s, How long must temperature be stable before collecting data, useful if sample lags temperature or if PID settings are overshooting beyond the stability criteria above

% Set MFIA Parameters
mfia.time_constant = 2.0e-2;  % s, lock in time constant, GN suggests ~2.4e-2
mfia.pulse_height = 0.0;      % V, has to be zero for CV, don't change this
mfia.ac_ampl = 0.080;           % V, lock in AC amplitude, GN suggests ~100 mV for good SNR
mfia.sample_rate = 107143;     % Hz, sampling rate Hz, for CV use 53571 or 107143
mfia.ac_freq = 1e6;           % Hz, not used for CV
mfia.ss_bias = bias_start;           % Hz, not used for CV
mfia.full_period = 0.150;     % s, not used for CV
mfia.trns_length = 0.150;     % s, not used for CV
mfia.pulse_width = 0.000;     % s, not used for CV
mfia.irange = 0.0001;         % A, current range for MFIA  


% Setup PATH
sample.save_folder = strcat('.\data\',sample.name,'_',datestr(now,'mm-dd-yyyy-HH-MM-SS'));  % folder data will be saved to, uses timecode so no overwriting happens
addpath(genpath('.\lakeshore'))		% point to lakeshore driver
addpath(genpath('.\LabOneMatlab'))  % point to LabOneMatlab drivers
ziAddPath % ZI instrument driver load


%% MAIN %%
% Check for and initialize lakeshore 331
if LAKESHORE_INIT()==0
    return;
end
% Check for and initialize MFIA
device = MFIA_INIT(mfia);

bsteps = ceil(abs(bias_start - bias_final)/bias_step);
biases = linspace(bias_start,bias_final,bsteps+1);
current_temp = temp_init;
current_num = 0;
steps = ceil(abs(temp_init - temp_final)/temp_step);
while current_num <= steps
    cprintf('blue', 'Waiting for set point (%3.2f)...\n',current_temp);
    SET_TEMP(current_temp,temp_stability,time_stability); % Wait for lakeshore to reach set temp;
    for i=1:length(biases)
        mfia.ss_bias = biases(i);
        [timeStamp, sampleCap, sampleRes] = MFIA_CAPACITANCE_POLL(device,mfia);
        pause(0.5);
        avg_R(i) = mean(sampleRes);
        avg_C(i) = mean(sampleCap);
        cprintf('blue', 'Current bias: %d \n',biases(i));
    end
    
    cprintf('blue', 'Saving data...\n');
    CV_FILE(sample,mfia,current_temp,biases,avg_C,avg_R);
    
    if temp_init > temp_final
        current_temp = current_temp - temp_step;    % Changes +/- for up vs down scan
    elseif temp_init < temp_final
        current_temp = current_temp + temp_step;
    end
    current_num = current_num + 1;
end

cprintf('blue', 'Finished data collection, returning to idle temp.\n');
SET_TEMP(temp_idle,temp_stability,time_stability); % Wait for lakeshore to reach set temp;
cprintf('green', 'All done.\n');

%% END MAIN %%
