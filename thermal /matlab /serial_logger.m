% 1. Setup Serial
port = "COM7";
baud = 115200;
device = serialport(port, baud);
flush(device);
% 2. Initialize Table - Column 1 is now a simple double (Numeric Seconds)
dataLog = table(double.empty(0,1), double.empty(0,1), double.empty(0,1), string.empty(0,1), ...
'VariableNames', {'Relative_Seconds', 'Temperature_C', 'Fan_Voltage', 'Status'});
% 3. Setup Plotting
figure('Color', 'w', 'Name', 'Fan Step Response Analysis');
t1 = subplot(2,1,1); grid on; hold on;
ylabel('Temperature (°C)'); title('Temperature vs Relative Time');
t2 = subplot(2,1,2); grid on; hold on;
ylabel('Fan Voltage (V)'); xlabel('Time (seconds)'); title('Fan Voltage Command Line');
% Start the stopwatch
tic;
disp('Recording... Close the plot window to stop.');
% 4. Main Loop
while ishandle(t1)
try
        rawData = readline(device);
        parts = str2double(strsplit(rawData, ','));
if length(parts) == 2
% Get numeric time elapsed since tic
            elapsedTime = toc;
            temp = parts(1);
            fanVoltage = parts(2);
            status = "Pre-Start";
if fanVoltage > 0, status = "Fan Active"; end
% Append to Table (Relative_Seconds is a simple number)
            newRow = {elapsedTime, temp, fanVoltage, status};
            dataLog = [dataLog; newRow];
% 5. Plotting (Line graph)
            plot(t1, dataLog.Relative_Seconds, dataLog.Temperature_C, 'r-', 'LineWidth', 1.5);
            plot(t2, dataLog.Relative_Seconds, dataLog.Fan_Voltage, 'b-', 'LineWidth', 1.5);
            drawnow limitrate;
end
catch
break;
end
end
% Show the final table
disp('--- Data Recording Complete (Relative Time Only) ---');
disp(head(dataLog, 15));
