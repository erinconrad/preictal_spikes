%% pull eeg data from pioneer
% Requires you are samba mounted!

%% Parameters
which_sz = 15;
which_chunk = 55;
sp_time = 267.45;
times = [sp_time-7.5,sp_time+7.5];

addpath(genpath('../'))

%% Paths
base_path = '/Volumes/erinconr/projects/preictal_spikes/eeg_data/';
curr_path = [base_path,sprintf('sz_%d/chunk_%d.mat',which_sz,which_chunk)];

%% Load it
load(curr_path);

samples = round(times(1)*Fs):round(times(2)*Fs);

%% Process
[bipolar_values,bipolar_labels] = scalp_bipolar(channels,data');

%% Plot it
plot_scalp_eeg(bipolar_values(samples,:),Fs,bipolar_labels)
%plot_scalp_eeg(bipolar_values,Fs,bipolar_labels)