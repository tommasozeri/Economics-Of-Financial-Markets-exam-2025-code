% Carica i dati dal file Excel
filename = 'C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\PortfolioCombinations_24.xlsx';
opts = detectImportOptions(filename, 'Sheet', 'nyse statisticsD');
opts.VariableNamingRule = 'preserve';
nasdaqStatistics = readtable(filename, opts);

% Estrai i pesi dei portafogli
weights = [0.2, 0.2, 0.2, 0.2, 0.2]; % Esempio di pesi per ciascun portafoglio

% Calcola la media del portafoglio di combinazione
meanReturns = nasdaqStatistics.Mean;
portfolioMean = sum(weights .* meanReturns);

% Calcola la deviazione standard del portafoglio di combinazione considerando le covarianze
covMatrix = [
    0.0004    0.0001    0.0000    0.0001    0.0001    0.0001    0.0001    0.0001    0.0001    0.0001;
    0.0001    0.0026    0.0001    0.0000    0.0002    0.0000    0.0000    0.0001    0.0001    0.0002;
    0.0000    0.0001    0.0021    0.0000    0.0007   -0.0000    0.0001    0.0002    0.0003    0.0008;
    0.0001    0.0000    0.0000    0.0002    0.0000    0.0001    0.0001    0.0001    0.0001    0.0000;
    0.0001    0.0002    0.0007    0.0000    0.0012    0.0000    0.0000    0.0002    0.0003    0.0011;
    0.0001    0.0000   -0.0000    0.0001    0.0000    0.0003    0.0000    0.0000    0.0001    0.0001;
    0.0001    0.0000    0.0001    0.0001    0.0000    0.0000    0.0004    0.0000    0.0001    0.0000;
    0.0001    0.0001    0.0002    0.0001    0.0002    0.0000    0.0000    0.0004    0.0002    0.0002;
    0.0001    0.0001    0.0003    0.0001    0.0003    0.0001    0.0001    0.0002    0.0014    0.0004;
    0.0001    0.0002    0.0008    0.0000    0.0011    0.0001    0.0000    0.0002    0.0004    0.0016
];

% Trasponi il vettore dei pesi per la moltiplicazione
weights = weights';

portfolioVariance = weights' * covMatrix * weights;
portfolioStdDev = sqrt(portfolioVariance);

% Calcola la curtosi del portafoglio di combinazione
kurtosisValues = nasdaqStatistics.Kurtosis;
portfolioKurtosis = sum(weights .* kurtosisValues);

% Calcola la skewness del portafoglio di combinazione
skewnessValues = nasdaqStatistics.Skeweness;
portfolioSkewness = sum(weights .* skewnessValues);

% Converti il tasso privo di rischio annuale in tasso giornaliero
annualRiskFreeRate = 0.02; % Esempio di tasso privo di rischio annuale
dailyRiskFreeRate = (1 + annualRiskFreeRate)^(1/252) - 1;

% Calcola lo Sharpe ratio del portafoglio di combinazione
portfolioSharpeRatio = (portfolioMean - dailyRiskFreeRate) / portfolioStdDev;

% Annualizza i valori
annualizedMean = portfolioMean * 252;
annualizedStdDev = portfolioStdDev * sqrt(252);
annualizedSharpeRatio = (annualizedMean - annualRiskFreeRate) / annualizedStdDev;

% Visualizza i risultati giornalieri
disp(['La media giornaliera del portafoglio di combinazione è: ', num2str(portfolioMean)]);
disp(['La deviazione standard giornaliera del portafoglio di combinazione è: ', num2str(portfolioStdDev)]);
disp(['La curtosi giornaliera del portafoglio di combinazione è: ', num2str(portfolioKurtosis)]);
disp(['La skewness giornaliera del portafoglio di combinazione è: ', num2str(portfolioSkewness)]);
disp(['Lo Sharpe ratio giornaliero del portafoglio di combinazione è: ', num2str(portfolioSharpeRatio)]);

% Visualizza i risultati annualizzati
disp(['La media annualizzata del portafoglio di combinazione è: ', num2str(annualizedMean)]);
disp(['La deviazione standard annualizzata del portafoglio di combinazione è: ', num2str(annualizedStdDev)]);
disp(['La curtosi annualizzata del portafoglio di combinazione è: ', num2str(portfolioKurtosis)]);
disp(['La skewness annualizzata del portafoglio di combinazione è: ', num2str(portfolioSkewness)]);
disp(['Lo Sharpe ratio annualizzato del portafoglio di combinazione è: ', num2str(annualizedSharpeRatio)]);

% Plotta tutti i portafogli e quello risultante della combinazione sul piano media-varianza
figure;
hold on;
scatter(stdDevs, meanReturns, 'b', 'filled'); % Tutti i portafogli
scatter(portfolioStdDev, portfolioMean, 'r', 'filled'); % Portafoglio di combinazione
text(stdDevs, meanReturns, nasdaqStatistics{:, 1}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Nomi dei portafogli
text(portfolioStdDev, portfolioMean, 'Portafoglio di Combinazione', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Nome del portafoglio di combinazione
xlabel('Deviazione Standard (Rischio)');
ylabel('Rendimento Atteso');
title('Portafogli sul Piano Media-Varianza');
legend('Portafogli', 'Portafoglio di Combinazione', 'Location', 'Best');
grid on;
hold off;
