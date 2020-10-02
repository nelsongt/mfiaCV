%%% MFIA C-V Profiler %%%  Author: George Nelson 2020
% Set sample info
sample.user = 'George';
sample.material = 'In0.53Ga0.47As';
sample.name = 'GAP500-Stage1';
sample.area = '0.196';  % mm^2
sample.comment = 'Post1180KAnneal';
sample.save_folder = strcat('.\data\',sample.name,'_',datestr(now,'mm-dd-yyyy-HH-MM-SS'));  % folder data will be saved to, uses timecode so no overwriting happens

% Set YSpec experiment parameters
mfia.sample_time = 5;    % sec, length to sample each temp point, determines speed of scan and SNR
bias_start = 0.1;      % Hz, start lock in AC frequency, GN suggests ~100Hz
bias_final = 2.5;      % Hz, final frequency, GN suggests 5MHz (MFIA limit)
bias_step = 0.01;      % Frequency step size on the log-scale

% Set temperature parameters
temp_init = 150;        % K, Initial temperature
temp_step = 10;         % K, Temperature step size
temp_final = 150;        % K, Ending temperature
temp_idle = 180;        % K, Temp to set after experiment is over
temp_stability = 0.05;   % K, Sets how stable the temperature point must be (set point +- stability)
time_stability = 20;    % s, How long must temperature be stable before collecting data, useful if sample lags temperature or if PID settings are overshooting beyond the stability criteria above

% Set MFIA Parameters
mfia.time_constant = 2.4e-3;  % us, lock in time constant, GN suggests 2.4e-3
mfia.pulse_height = 0.0;      % V, has to be zero for YSpec, don't change this
mfia.ac_ampl = 0.080;           % V, lock in AC amplitude, GN suggests ~100 mV for good SNR
mfia.sample_rate = 107143;     % Hz, sampling rate Hz, for Y_Spec use 53571 or 107143
mfia.ac_freq = 1e6;           % Hz, not used for YSpec
mfia.ss_bias = bias_start;           % Hz, not used for YSpec
mfia.full_period = 0.150;     % s, not used for YSpec
mfia.trns_length = 0.150;     % s, not used for YSpec
mfia.pulse_width = 0.000;     % s, not used for YSpec
mfia.irange = 0.0001;         % A, current range for MFIA  


% Setup PATH
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
        %if freqs(i) < 9900000
        %    mfia.irange = 0.0001;
        %elseif freqs(i) > 9900000
        %    mfia.irange = 0.001;
        %end
        [timeStamp, sampleCap, sampleRes] = MFIA_CAPACITANCE_POLL(device,mfia);
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
