%% plot_sz_onsets

i = 5;
surround = 7;

%% paths
addpath('../../tools/');
paths = preictal_paths;

%% patient list
sz_path = '../../data/isolated_szs.csv';

T = readtable(sz_path);

isolated_rows = find(T.isolated == 1);

row = T(isolated_rows(i),:);
ieeg_name = row.IEEGname;
sz_time = row.annotation_time;
run_times = [sz_time-surround,sz_time+surround];

%% Get EEG data
addpath(genpath(paths.ieeg_folder));
session = IEEGSession(ieeg_name,paths.ieeg_login,paths.ieeg_pw_file);
chLabels = session.data.channelLabels; chLabels = chLabels(:,1);
nchs = size(chLabels,1);
fs = session.data.sampleRate;
run_idx = round(run_times(1)*fs):round(run_times(2)*fs);
if ~isempty(run_idx)
    % Break the number of channels in half to avoid wacky server errors
    values1 = session.data.getvalues(run_idx,1:floor(nchs/4));
    values2 = session.data.getvalues(run_idx,floor(nchs/4)+1:floor(2*nchs/4));
    values3 = session.data.getvalues(run_idx,floor(2*nchs/4)+1:floor(3*nchs/4)); 
    values4 = session.data.getvalues(run_idx,floor(3*nchs/4)+1:nchs); 

    values = [values1,values2,values3,values4];
else
    values = [];
end
session.delete;

%% bipolar
[bipolar_values,bipolar_labels] = scalp_bipolar(chLabels,values);

%% Plot
plot_scalp_eeg(bipolar_values,fs,bipolar_labels)

row