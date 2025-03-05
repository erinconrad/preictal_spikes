%% Get spike counts
%{
- Loop over szs
- Divide into 10 minute chunks 6 hours pre to 6 hours post
- Loop over chunks
- Pull data from ieeg.org 
- Process as needed for SN2 - downsample to 128 - save to a local folder

-------------------------------------------------

- Run SN2
- Save SN2 probs

--------------------------

- Determine counts in each chunk based on prob threshold

--------------------------------------------------

- plot counts pre to post sz

- actually, I think I can save the raw data because I think it is only 73Gb
- 83 seizures x 12 hours x 3600 s/hours x 128 samples/s x 20 chs x 8 bytes
= 73 Gb
%}

%% Paths
