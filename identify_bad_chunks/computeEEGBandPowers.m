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
%       bp - Struct with the following fields, each of size
%            [nOneMinSeg x nChannels]:
%                .broadband  - Broadband power (1-80 Hz)
%                .delta      - Delta band (1-4 Hz)
%                .theta      - Theta band (4-8 Hz)
%                .alpha      - Alpha band (8-13 Hz)
%                .beta       - Beta band (13-30 Hz)
%                .gamma      - Gamma band (30-80 Hz)
%                .sixtyHz    - 60 Hz noise power (59-61 Hz)
%
%            Additionally, bp.bands is a struct that records the frequency ranges:
%                .broadband, .delta, .theta, .alpha, .beta, .gamma, .sixtyHz

    % Window durations in seconds
    winDuration = 10;          % Each short window is 10 seconds
    oneMinDuration = 60;       % Group into one minute segments
    nWinsPerMin = oneMinDuration / winDuration;  % 6 windows per minute
    
    % Number of samples per 10-second window
    winSamples = winDuration * fs;
    
    % Define frequency bands
    bands.broadband = [1 50];
    bands.delta     = [1 4];
    bands.theta     = [4 8];
    bands.alpha     = [8 13];
    bands.beta      = [13 30];
    bands.gamma     = [30 50];
    bands.sixtyHz   = [59 61];
    
    % Get the size of the data matrix
    [nSamples, nChannels] = size(data);
    
    % Determine the number of complete 10-second windows available
    n10secWins = floor(nSamples / winSamples);
    
    % Determine the number of complete one-minute segments
    nOneMinSeg = floor(n10secWins / nWinsPerMin);
    
    % Preallocate arrays for bandpower values in each 10-second window
    bp_broadband_10sec = nan(n10secWins, nChannels);
    bp_delta_10sec     = nan(n10secWins, nChannels);
    bp_theta_10sec     = nan(n10secWins, nChannels);
    bp_alpha_10sec     = nan(n10secWins, nChannels);
    bp_beta_10sec      = nan(n10secWins, nChannels);
    bp_gamma_10sec     = nan(n10secWins, nChannels);
    bp_60hz_10sec      = nan(n10secWins, nChannels);
    
    % Loop over each 10-second window for each channel
    for ch = 1:nChannels
        for win = 1:n10secWins
            % Get indices for the current 10-second segment
            idxStart = (win-1)*winSamples + 1;
            idxEnd = win * winSamples;
            segment = data(idxStart:idxEnd, ch);
            
            % Compute bandpower for each frequency band in the segment
            bp_broadband_10sec(win, ch) = bandpower(segment, fs, bands.broadband);
            bp_delta_10sec(win, ch)     = bandpower(segment, fs, bands.delta);
            bp_theta_10sec(win, ch)     = bandpower(segment, fs, bands.theta);
            bp_alpha_10sec(win, ch)     = bandpower(segment, fs, bands.alpha);
            bp_beta_10sec(win, ch)      = bandpower(segment, fs, bands.beta);
            bp_gamma_10sec(win, ch)     = bandpower(segment, fs, bands.gamma);
            bp_60hz_10sec(win, ch)      = bandpower(segment, fs, bands.sixtyHz);
        end
    end
    
    % Preallocate arrays for one-minute segments (median of 6 windows)
    broadband_min = nan(nOneMinSeg, nChannels);
    delta_min     = nan(nOneMinSeg, nChannels);
    theta_min     = nan(nOneMinSeg, nChannels);
    alpha_min     = nan(nOneMinSeg, nChannels);
    beta_min      = nan(nOneMinSeg, nChannels);
    gamma_min     = nan(nOneMinSeg, nChannels);
    sixtyHz_min   = nan(nOneMinSeg, nChannels);
    
    % Group the 10-second windows into one-minute segments and take the median
    for ch = 1:nChannels
        for seg = 1:nOneMinSeg
            % Determine window indices for this one-minute segment
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
    
    % Bundle all the computed bandpower values into a structure
    bp = struct(...
        'broadband', broadband_min, ...
        'delta',     delta_min, ...
        'theta',     theta_min, ...
        'alpha',     alpha_min, ...
        'beta',      beta_min, ...
        'gamma',     gamma_min, ...
        'sixtyHz',   sixtyHz_min, ...
        'bands',     bands ...
    );
end
