clc;
close all;
clearvars;

%% ========================================================================
%  USER DATA
% ========================================================================
X1 = csvread("fandata_10V_6.csv");
X = csvread("fandata_nofan_6.csv");
t = 0:59;
y = -X1(1:60,2) +X(1:60,2);


%% ========================================================================
%  MONTE CARLO SEARCH SETTINGS
% ========================================================================
N_iter = 50000;     % number of random trials

% Parameter search ranges
K_min    = 0.1;
K_max    = 20;

tau1_min = 5;
tau1_max = 20;

tau2_min = 0.1;
tau2_max = 4.0;

%% ========================================================================
%  STORAGE FOR BEST RESULT
% ========================================================================
best_J = inf;
best_K = NaN;
best_tau1 = NaN;
best_tau2 = NaN;
best_y_model = [];

J_all = zeros(N_iter,1);   % optional: store all costs

%% ========================================================================
%  MONTE CARLO SEARCH
% ========================================================================
for k = 1:N_iter
    
    % ---------------------------------------------------------------------
    % Randomly generate candidate parameters
    % ---------------------------------------------------------------------
    K_candidate = K_min + (K_max - K_min)*rand;
    
    tau1_candidate = tau1_min + (tau1_max - tau1_min)*rand;
    tau2_candidate = tau2_min + (tau2_max - tau2_min)*rand;    
        
    % ---------------------------------------------------------------------
    % Build transfer function
    % G(s) = K / [(1 + tau1*s)(1 + tau2*s)]
    % ---------------------------------------------------------------------
    num = K_candidate;
    den = conv([tau1_candidate 1], [tau2_candidate 1]);
    sys = tf(num, den);
    
    % ---------------------------------------------------------------------
    % Compute step response at the same time samples as data
    % ---------------------------------------------------------------------
    y_model = step(sys, t);
    
    % ---------------------------------------------------------------------
    % Compute sum of squared errors
    % ---------------------------------------------------------------------
    e = y - y_model;
    J = sum(e.^2);
    
    J_all(k) = J;
    
    % ---------------------------------------------------------------------
    % Update best result if current candidate is better
    % ---------------------------------------------------------------------
    if J < best_J
        best_J = J;
        best_K = K_candidate;
        best_tau1 = tau1_candidate;
        best_tau2 = tau2_candidate;
        best_y_model = y_model;
    end
end

%% ========================================================================
%  DISPLAY BEST PARAMETERS
% ========================================================================
fprintf('Best fit found:\n');
fprintf('K     = %.6f\n', best_K);
fprintf('tau1  = %.6f\n', best_tau1);
fprintf('tau2  = %.6f\n', best_tau2);
fprintf('Cost J = %.6f\n', best_J);

%% ========================================================================
%  BUILD BEST-FIT TRANSFER FUNCTION
% ========================================================================
num_best = best_K;
den_best = conv([best_tau1 1], [best_tau2 1]);
sys_best = tf(num_best, den_best);

disp('Best-fit transfer function:')
sys_best

%% ========================================================================
%  PLOT MEASURED DATA VS BEST MODEL
% ========================================================================
figure;
plot(t, y, 'r*', 'DisplayName', 'Measured data');
hold on;
plot(t, best_y_model, 'LineWidth', 1.5, 'DisplayName', 'Best model fit');
grid on;
xlabel('Time (s)');
ylabel('Output');
title('Monte Carlo Fit of Second-Order Model');
legend('Location', 'best');

%% ========================================================================
%  OPTIONAL: PLOT ERROR
% ========================================================================
figure;
plot(t, y - best_y_model, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Error');
title('Model Error: y_{data} - y_{model}');
