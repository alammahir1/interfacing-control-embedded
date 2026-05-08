%% Setup Serial Connection
clear; clc; close all;

% --- CONFIGURATION ---
serialPort = 'COM5'; % <--- CHANGE THIS to your ESP32 Port
baudRate = 115200;
% ---------------------

% Create UI for stopping the loop safely
f = figure('Name', 'Arduino Live Data', 'NumberTitle', 'off');
stopButton = uicontrol('Style', 'togglebutton', 'String', 'Stop',...
                       'Position', [20 20 100 40], 'Callback', 'uiresume(gcbf)');

% Initialize Serial Port
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

try
    s = serialport(serialPort, baudRate);
    configureTerminator(s, "CR/LF");
    flush(s);
    disp(['Connected to ' serialPort]);
catch ME
    errordlg(['Failed to connect: ' ME.message]);
    return;
end

% Initialize Animated Lines for efficient plotting
ax = axes('Position', [0.13 0.2 0.77 0.7]); % Make room for button
hLineDiff = animatedline('Color', 'b', 'LineWidth', 1.5, 'DisplayName', 'Voltage Difference');
hLineCap  = animatedline('Color', 'r', 'LineWidth', 1.5, 'DisplayName', 'Capacitor Voltage');

% Setup Plot Aesthetics
title('Live Voltage Data');
xlabel('Time (samples)');
ylabel('Voltage (V)');
legend('show', 'Location', 'best');
grid on;
ylim([-1 3.5]); % Fixed Y-axis helps reduce jitter (adjust as needed)

%% Data Collection Loop
disp('Reading data... Press "Stop" button on figure to end.');

sampleCount = 0;

% Loop until the Stop button is pressed
while ~stopButton.Value
    if s.NumBytesAvailable > 0
        try
            % Read a line of data
            dataLine = readline(s);
            dataLine = char(dataLine); % Convert string to char array
            
            % Parse "Voltage_Difference"
            if contains(dataLine, 'Voltage_Difference:')
                valStr = extractAfter(dataLine, 'Voltage_Difference:');
                val = str2double(valStr);
                
                if ~isnan(val)
                    sampleCount = sampleCount + 1;
                    addpoints(hLineDiff, sampleCount, val);
                end
                
            % Parse "Capacitor_Voltage"
            elseif contains(dataLine, 'Capacitor_Voltage:')
                valStr = extractAfter(dataLine, 'Capacitor_Voltage:');
                val = str2double(valStr);
                
                if ~isnan(val)
                    % Note: We use the same sampleCount assuming they come in pairs
                    addpoints(hLineCap, sampleCount, val);
                end
            end
            
            % Update plot every 10 samples to improve performance
            if mod(sampleCount, 10) == 0
                drawnow limitrate;
            end
            
        catch e
            disp('Error reading data line. Skipping...');
        end
    end
end

%% Cleanup
disp('Stopping...');
clear s; % Closes the serial port
disp('Serial port closed.');
