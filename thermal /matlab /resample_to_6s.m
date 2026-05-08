%% ========================================================================
%  INTERPOLATION OF NON-UNIFORM DATA TO UNIFORM TIME GRID
% ========================================================================

% clc;
% clearvars;
% close all;

%% ------------------------------------------------------------------------
%  USER INPUT: ORIGINAL DATA
% -------------------------------------------------------------------------
X=csvread('fandata_3V.csv');
t_original = X(:,1);        % time vector (must be column)
y_original = X(:,2);        % measurement vector (same length as t)

%% ------------------------------------------------------------------------
%  STEP 1: CHECK DATA VALIDITY
% -------------------------------------------------------------------------
% Ensure time is strictly increasing (important for interpolation)

% Sort data just in case it is not ordered
[t_original, idx] = sort(t_original);
y_original = y_original(idx);

% Remove duplicate time points (interp1 requires unique values)
[t_unique, idx_unique] = unique(t_original);
y_unique = y_original(idx_unique);

%% ------------------------------------------------------------------------
%  STEP 2: DEFINE NEW UNIFORM TIME VECTOR
% -------------------------------------------------------------------------
% Option 1: specify sampling time
Ts = 6;   % <-- sampling interval in seconds (you can change this)

t_start = t_unique(1);
t_end   = t_unique(end);

t_uniform = (t_start:Ts:t_end)';   % column vector

% Option 2 (alternative): define number of points instead
% N = 1000;
% t_uniform = linspace(t_start, t_end, N)';

%% ------------------------------------------------------------------------
%  STEP 3: INTERPOLATE DATA
% -------------------------------------------------------------------------
% Common interpolation methods:
% 'linear'  - simple, robust
% 'pchip'   - shape-preserving (recommended for physical signals)
% 'spline'  - smoother but may overshoot

method = 'pchip';

y_uniform = interp1(t_unique, y_unique, t_uniform, method);

%% ------------------------------------------------------------------------
%  OPTIONAL: HANDLE EXTRAPOLATION (if needed)
% -------------------------------------------------------------------------
% If your new time vector goes outside original range, use:
% y_uniform = interp1(t_unique, y_unique, t_uniform, method, 'extrap');

%% ------------------------------------------------------------------------
%  STEP 4: VISUALISE RESULT
% -------------------------------------------------------------------------
figure;
plot(t_original, y_original, 'o', 'DisplayName', 'Original Data');
hold on;
plot(t_uniform, y_uniform, '-', 'LineWidth', 1.5, ...
    'DisplayName', 'Interpolated Data');
grid on;

xlabel('Time (s)');
ylabel('Measurement');
legend('Location', 'best');
title('Interpolation to Uniform Time Grid');

%% ------------------------------------------------------------------------
%  OUTPUT
% -------------------------------------------------------------------------
% t_uniform  -> new time vector (uniformly sampled)
% y_uniform  -> interpolated measurements
X_new=[t_uniform y_uniform];
writematrix(X_new,'fandata_10V_6.csv')
