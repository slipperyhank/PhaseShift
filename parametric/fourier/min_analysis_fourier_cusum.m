% Search for the minimum value of n_samples such that the desired 
% false positive rate can be achieved. at which the power to identify shifts
% plateaus. 

% Frequency band is (7, 9)
frequency = 8;
bandwidth = 1;

% Sampling rate is 250 samples per second
sampling_rate = 250;

% Default SNR is 0.5, but test other values 
SNR = 0.5;

% Number of simulations for each blocksize
n_simulations = 1000;

% Number of bootstrap samples for estimating critical values
n_bootstrap = 5000;

% Desired power
power = 0.9;
alpha = 0.05;

% Optimial burn value from burn_analysis_fourier.m
n_burn = 70;

% For the default parameters - SNR = 0.5, width = 1

sample_list = (1:50)*50;
n_sample_parameters = length(sample_list);

false_positives = zeros(1, n_sample_parameters);

for i = 1:n_sample_parameters
    disp(i)
    n_samples = sample_list(i);
    signal_length = n_samples + 2 * n_burn;
    [critical_value] = parametric_cusum_fourier(signal_length, sampling_rate, SNR, frequency, bandwidth, alpha, n_bootstrap, n_burn);    
    for j=1:n_simulations
        % Random phase values
        phi = rand() * 2 * pi;
        % Simulate signal with no shifts and estimate instantaneous phase
        signal = sim_one_shift(signal_length, sampling_rate, SNR, frequency, phi);
        phase = fourier_phase(signal, sampling_rate, frequency, bandwidth);
        % Burn away start and end of signal
        phase = unwrap(phase((n_burn + 1):(end - n_burn)));
        % Test for change point and estimate tau
        if max(abs(weighted_cusum(phase))) > critical_value
            false_positives(i) = false_positives(i) + 1;
        end
    end
end


save fourier_minSize false_positives n_simulations sample_list alpha n_burn SNR frequency bandwidth 

%{

figure()
L0 = mean(mean(tau)) * 2;

plot(blocksize_list, false_positives / n_simulations, 'b', 'linewidth', 2)
hold on
plot([0, max(blocksize_list)], [alpha, alpha], 'k--')
plot([L0, L0], [0, 1], 'r', 'linewidth', 2)


%}




% Tried a number of different scenarios, all result in 
% FP rates averaging 10% rather than 5%

% Have increased nSim and blocksize_list
% Increased T to 20+ seconds
% Tried permutation and resampling 
%     - reampling does better but not sufficient
% Tried 500 and 1000 point burn
% Tried making L = 2*tau for every signals estimated tau
% Decreasing noise
% Decreasing alpha to 0.025 got the desired 0.05 error rate
%   - Many different values of alpha all give 2(alpha)
% Making width smaller made things worse: possibly need to extend boundary?
%   - extending boundary didn't work. Maybe need to have larger L values
%   - Larger L values didn't converge down, does eventually show cyclic behaviour 
%     with a period near the block size
% Tried with random initial phi, didn't change anything
% Different frequency didn't change anything
% Added a 'back burn' to remove the end of signal boundary effect, reduced
% the FPs slightly. Now results of alpha 0.05 close 7.5%

% Conclusions:
% Frequency and initial phase do not change anything. 
% The burn can be too small, and the block_size can be too big if there are not enough points in the signal
% Need to consider the boundary at the end

    
