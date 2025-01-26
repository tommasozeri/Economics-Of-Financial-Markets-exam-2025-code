% Carica i dati dal worksheet NYSEselectedD
dataD = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'funds daily', 'VariableNamingRule', 'preserve');

% Normalizza i prezzi
normalized_dataD = dataD;
for i = 2:width(dataD)
    normalized_dataD{:, i} = dataD{:, i} / dataD{1, i};
end

% Plot dei prezzi normalizzati
figure;
hold on;
for i = 2:width(normalized_dataD)
    plot(normalized_dataD.DATE, normalized_dataD{:, i}, 'DisplayName', normalized_dataD.Properties.VariableNames{i});
end
hold off;
xlabel('Date');
ylabel('Normalized Price');
title('Normalized Stock Prices - Funds Daily');
legend;

% Calcolo dei rendimenti giornalieri
returnsD = diff(log(dataD{:, 2:end})); % Rendimenti logaritmici dei fondi giornalieri

% Calcolo della matrice di correlazione giornaliera
corr_matrixD = corr(returnsD); % Matrice di correlazione giornaliera

% Plot della heatmap della matrice di correlazione giornaliera con la mappa di colori 'parula'
figure;
heatmap(dataD.Properties.VariableNames(2:end), dataD.Properties.VariableNames(2:end), corr_matrixD, 'ColorMap', parula, 'Title', 'Correlation Heatmap - Funds Daily');

% Carica i dati dal worksheet FUNDSselectedM
dataM = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'FUNDSselectedM', 'VariableNamingRule', 'preserve');

% Normalizza i prezzi
normalized_dataM = dataM;
for i = 2:width(dataM)
    normalized_dataM{:, i} = dataM{:, i} / dataM{1, i};
end

% Plot dei prezzi normalizzati
figure;
hold on;
for i = 2:width(normalized_dataM)
    plot(normalized_dataM.DATE, normalized_dataM{:, i}, 'DisplayName', normalized_dataM.Properties.VariableNames{i});
end
hold off;
xlabel('Date');
ylabel('Normalized Price');
title('Normalized Stock Prices - Funds Monthly');
legend;

% Calcolo dei rendimenti mensili
returnsM = diff(log(dataM{:, 2:end})); % Rendimenti logaritmici dei fondi mensili

% Calcolo della matrice di correlazione mensile
corr_matrixM = corr(returnsM); % Matrice di correlazione mensile

% Plot della heatmap della matrice di correlazione mensile con la mappa di colori 'parula'
figure;
heatmap(dataM.Properties.VariableNames(2:end), dataM.Properties.VariableNames(2:end), corr_matrixM, 'ColorMap', parula, 'Title', 'Correlation Heatmap - Funds Monthly');
