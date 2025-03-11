%% pull eeg data from pioneer
% Requires you are samba mounted!

%% Parameters
which_sz = 18;
which_chunk = 1;
sp_time = 323.79;
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
%plot_scalp_eeg(bipolar_values(samples,:),Fs,bipolar_labels)
plot_scalp_eeg(bipolar_values,Fs,bipolar_labels)

%% Spectrogram
%{
channelIndex = 2;  % Replace with the desired channel number

% Define spectrogram parameters
fs = 1000;         % Sampling frequency in Hz (adjust as needed)
window = 256;      % Length of each segment
noverlap = 128;    % Number of overlapping samples
nfft = 256;        % Number of FFT points

% Plot the spectrogram for the specified channel
figure;
spectrogram(bipolar_values(:, channelIndex), window, noverlap, nfft, fs, 'yaxis');
title(['Spectrogram of Channel ' num2str(channelIndex)]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');

%}