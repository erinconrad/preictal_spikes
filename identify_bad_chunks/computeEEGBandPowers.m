function bp = computeEEGBandPowers(data, fs)
% computeEEGBandPowers calculates the median bandpower over one-minute segments.
%
%   bp = computeEEGBandPowers(data, fs)
%
%   Inputs:
%       data - [nsamples x nChannels] matrix of EEG data.
%       fs   - Sampling frequency in Hz.
%
%   Output:
%       bp - Struct with the following fields:
%                .broadband  - Median broadband power (1-80 Hz) per one-minute segment
%                .delta      - Median delta power (1-4 Hz) per one-minute segment
%                .theta      - Median theta power (4-8 Hz) per one-minute segment
%                .alpha      - Median alpha power (8-13 Hz) per one-minute segment
%                .beta       - Median beta power (13-30 Hz) per one-minute segment
%                .gamma      - Median gamma power (30-80 Hz) per one-minute segment
%                .sixtyHz    - Median 60 Hz noise power (59-61 Hz) per one-minute segment
%                .bands      - Structure with the frequency band definitions
%                .time10sec  - Structure with time markers for each 10-second window:
%                              .samples: [n10secWins x 2] array with start and end sample indices
%                              .seconds: [n10secWins x 2] array with start and end times (sec)
%
%   The function first divides the data into 10‑second windows, computes the bandpower
%   for each window, and then groups every six windows into one‑minute segments by taking
%   the median across those windows.

    %% Set up parameters
    % Duration settings
    winDuration = 10;          % Duration of each 10-second window (seconds)
    oneMinDuration = 60;       % One minute segment duration (seconds)
    nWinsPerMin = oneMinDuration / winDuration;  % 6 windows per minute

    % Number of samples per 10-second window
    winSamples = winDuration * fs;
    
    % Define frequency bands (and store them in a struct)
    bands.broadband = [1 50];
    bands.delta     = [1 4];
    bands.theta     = [4 8];
    bands.alpha     = [8 13];
    bands.beta      = [13 30];
    bands.gamma     = [30 50];
    bands.sixtyHz   = [59 61];
    
    %% Determine windowing and time markers
    [nSamples, nChannels] = size(data);
    n10secWins = floor(nSamples / winSamples);  % Total complete 10-second windows
    nOneMinSeg = floor(n10secWins / nWinsPerMin); % Total complete one-minute segments
    
    % Create time markers for each 10-second window:
    % Each row will be: [start_sample, end_sample]
    timeSamples = zeros(n10secWins, 2);
    for win = 1:n10secWins
        startSample = (win-1)*winSamples + 1;
        endSample = win * winSamples;
        timeSamples(win, :) = [startSample, endSample];
    end
    % Convert sample indices to time in seconds
    timeSeconds = timeSamples / fs;
    
    %% Preallocate arrays for bandpower values in each 10-second window
    bp_broadband_10sec = nan(n10secWins, nChannels);
    bp_delta_10sec     = nan(n10secWins, nChannels);
    bp_theta_10sec     = nan(n10secWins, nChannels);
    bp_alpha_10sec     = nan(n10secWins, nChannels);
    bp_beta_10sec      = nan(n10secWins, nChannels);
    bp_gamma_10sec     = nan(n10secWins, nChannels);
    bp_60hz_10sec      = nan(n10secWins, nChannels);
    
    %% Compute bandpower for each 10-second window and each channel
    for ch = 1:nChannels
        for win = 1:n10secWins
            idxStart = (win-1)*winSamples + 1;
            idxEnd = win * winSamples;
            segment = data(idxStart:idxEnd, ch);
            
            bp_broadband_10sec(win, ch) = bandpower(segment, fs, bands.broadband);
            bp_delta_10sec(win, ch)     = bandpower(segment, fs, bands.delta);
            bp_theta_10sec(win, ch)     = bandpower(segment, fs, bands.theta);
            bp_alpha_10sec(win, ch)     = bandpower(segment, fs, bands.alpha);
            bp_beta_10sec(win, ch)      = bandpower(segment, fs, bands.beta);
            bp_gamma_10sec(win, ch)     = bandpower(segment, fs, bands.gamma);
            bp_60hz_10sec(win, ch)      = bandpower(segment, fs, bands.sixtyHz);
        end
    end
    
    %% Group the 10-second windows into one-minute segments by taking the median
    broadband_min = nan(nOneMinSeg, nChannels);
    delta_min     = nan(nOneMinSeg, nChannels);
    theta_min     = nan(nOneMinSeg, nChannels);
    alpha_min     = nan(nOneMinSeg, nChannels);
    beta_min      = nan(nOneMinSeg, nChannels);
    gamma_min     = nan(nOneMinSeg, nChannels);
    sixtyHz_min   = nan(nOneMinSeg, nChannels);
    
    for ch = 1:nChannels
        for seg = 1:nOneMinSeg
            winIndices = (seg-1)*nWinsPerMin + (1:nWinsPerMin);
            broadband_min(seg, ch) = median(bp_broadband_10sec(winIndices, ch), 'omitnan');
            delta_min(seg, ch)     = median(bp_delta_10sec(winIndices, ch), 'omitnan');
            theta_min(seg, ch)     = median(bp_theta_10sec(winIndices, ch), 'omitnan');
            alpha_min(seg, ch)     = median(bp_alpha_10sec(winIndices, ch), 'omitnan');
            beta_min(seg, ch)      = median(bp_beta_10sec(winIndices, ch), 'omitnan');
            gamma_min(seg, ch)     = median(bp_gamma_10sec(winIndices, ch), 'omitnan');
            sixtyHz_min(seg, ch)   = median(bp_60hz_10sec(winIndices, ch), 'omitnan');
        end
    end
    
    %% Bundle all results into the output structure
    bp = struct(...
        'broadband', broadband_min, ...
        'delta',     delta_min, ...
        'theta',     theta_min, ...
        'alpha',     alpha_min, ...
        'beta',      beta_min, ...
        'gamma',     gamma_min, ...
        'sixtyHz',   sixtyHz_min, ...
        'bands',     bands, ...
        'time10sec', struct('samples', timeSamples, 'seconds', timeSeconds) ...
    );
end
