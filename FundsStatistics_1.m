% Definisci il percorso del file
filename = 'C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx';
sheet = 'funds monthly';

% Carica il file Excel
opts = detectImportOptions(filename, 'Sheet', sheet);
opts.VariableNamingRule = 'preserve';
data = readtable(filename, opts);

% Visualizza i dati
disp(data);

% Estrai le date e i ticker
dates = data{:, 1};
tickers = data.Properties.VariableNames(2:end);

% Converti i dati delle celle in valori numerici se necessario
for i = 2:width(data)
    if iscell(data{:, i})
        data{:, i} = str2double(data{:, i});
    end
end

% Calcola i rendimenti giornalieri
returns = diff(log(data{:, 2:end}));

% Inizializza le variabili per i risultati
mean_values = mean(returns);
variance_values = var(returns);
std_dev_values = std(returns);
skewness_values = skewness(returns);
kurtosis_values = kurtosis(returns);

% Crea una tabella con i risultati
results = table(tickers', mean_values', variance_values', std_dev_values', skewness_values', kurtosis_values', ...
    'VariableNames', {'Ticker', 'Mean', 'Variance', 'StandardDeviation', 'Skewness', 'Kurtosis'});

% Visualizza i risultati
disp(results);

% Trova il massimo e minimo per ciascuna categoria
[max_mean, max_mean_idx] = max(mean_values);
[min_mean, min_mean_idx] = min(mean_values);

[max_variance, max_variance_idx] = max(variance_values);
[min_variance, min_variance_idx] = min(variance_values);

[max_std_dev, max_std_dev_idx] = max(std_dev_values);
[min_std_dev, min_std_dev_idx] = min(std_dev_values);

[max_skewness, max_skewness_idx] = max(skewness_values);
[min_skewness, min_skewness_idx] = min(skewness_values);

[max_kurtosis, max_kurtosis_idx] = max(kurtosis_values);
[min_kurtosis, min_kurtosis_idx] = min(kurtosis_values);

% Stampa i risultati
disp('higher and lowest performers for each category:');
fprintf('Mean: higher = %s (%.4f), lowest = %s (%.4f)\n', ...
    tickers{max_mean_idx}, max_mean, tickers{min_mean_idx}, min_mean);

fprintf('Variance: higher = %s (%.4f), lowest = %s (%.4f)\n', ...
    tickers{max_variance_idx}, max_variance, tickers{min_variance_idx}, min_variance);

fprintf('Standard Deviation: higher = %s (%.4f), lowest = %s (%.4f)\n', ...
    tickers{max_std_dev_idx}, max_std_dev, tickers{min_std_dev_idx}, min_std_dev);

fprintf('Skewness: higher = %s (%.4f), lowest = %s (%.4f)\n', ...
    tickers{max_skewness_idx}, max_skewness, tickers{min_skewness_idx}, min_skewness);

fprintf('Kurtosis: higher = %s (%.4f), lowest = %s (%.4f)\n', ...
    tickers{max_kurtosis_idx}, max_kurtosis, tickers{min_kurtosis_idx}, min_kurtosis);


%% GRAFICI --------------------------------------------------------------------------------------------------------------------------------------------------------

% Crea i grafici per ogni categoria
figure;
bar(mean_values);
title('Mean');
set(gca, 'XTick', 1:length(tickers), 'XTickLabel', tickers);
xtickangle(45);
ylabel('Value');
xlabel('Tickers');
set(gca, 'FontSize', 6); % Dimezza la grandezza del font

figure;
bar(variance_values);
title('Variance');
set(gca, 'XTick', 1:length(tickers), 'XTickLabel', tickers);
xtickangle(45);
ylabel('Value');
xlabel('Tickers');
set(gca, 'FontSize', 6); % Dimezza la grandezza del font

figure;
bar(std_dev_values);
title('Standard Deviation');
set(gca, 'XTick', 1:length(tickers), 'XTickLabel', tickers);
xtickangle(45);
ylabel('Value');
xlabel('Tickers');
set(gca, 'FontSize', 6); % Dimezza la grandezza del font

figure;
bar(skewness_values);
title('Skewness');
set(gca, 'XTick', 1:length(tickers), 'XTickLabel', tickers);
xtickangle(45);
ylabel('Value');
xlabel('Tickers');
set(gca, 'FontSize', 6); % Dimezza la grandezza del font

figure;
bar(kurtosis_values);
title('Kurtosis');
set(gca, 'XTick', 1:length(tickers), 'XTickLabel', tickers);
xtickangle(45);
ylabel('Value');
xlabel('Tickers');
set(gca, 'FontSize', 6); % Dimezza la grandezza del font

% Aggiusta la dimensione della figura
set(gcf, 'Position', [100, 100, 1200, 800]);
