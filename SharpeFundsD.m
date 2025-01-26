% Carica i dati dal file Excel DBEXAM.xlsx, worksheet NASselectedM
filePath = 'C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx';
sheetNameAssets = 'FUNDSselectedD';
sheetNameIndex = 'SP500indexD';
dataAssets = readtable(filePath, 'Sheet', sheetNameAssets, 'VariableNamingRule', 'preserve');
dataIndex = readtable(filePath, 'Sheet', sheetNameIndex, 'VariableNamingRule', 'preserve');

% Estrai i nomi dei titoli
assetNames = dataAssets.Properties.VariableNames(2:end);

% Calcola i rendimenti giornalieri dei titoli
pricesAssets = dataAssets{:, 2:end}; % Supponendo che la prima colonna sia la data
returnsAssets = diff(pricesAssets) ./ pricesAssets(1:end-1, :);

% Calcola i rendimenti giornalieri dell'indice S&P 500
pricesIndex = dataIndex{:, 2}; % Supponendo che la prima colonna sia la data
returnsIndex = diff(pricesIndex) ./ pricesIndex(1:end-1);

% Allinea le date tra i rendimenti dei titoli e dell'indice
datesAssets = dataAssets{2:end, 1};
datesIndex = dataIndex{2:end, 1};
[commonDates, idxAssets, idxIndex] = intersect(datesAssets, datesIndex);
returnsAssets = returnsAssets(idxAssets, :);
returnsIndex = returnsIndex(idxIndex);

% Calcola le statistiche
meanReturns = mean(returnsAssets);
stdReturns = std(returnsAssets);

% Calcola i beta dei titoli tramite regressione
beta_assets = zeros(1, size(returnsAssets, 2));
for i = 1:size(returnsAssets, 2)
    mdl = fitlm(returnsIndex, returnsAssets(:, i));
    beta_assets(i) = mdl.Coefficients.Estimate(2);
end

% Calcola il tasso risk-free giornaliero
riskFreeRate = 0.02 / 252; % 2% annuo convertito in giornaliero

% Calcola la SML per ogni titolo
marketReturn = mean(returnsIndex);
marketRiskPremium = marketReturn - riskFreeRate;
smlValues = riskFreeRate + marketRiskPremium * beta_assets;

% Stampa i risultati e confronta i rendimenti attesi con i rendimenti effettivi
fprintf('Rendimento atteso dei titoli:\n');
for i = 1:length(assetNames)
    fprintf('%s: %f\n', assetNames{i}, meanReturns(i));
end
fprintf('Beta dei titoli:\n');
for i = 1:length(assetNames)
    fprintf('%s: %f\n', assetNames{i}, beta_assets(i));
end
fprintf('Valore della SML per i titoli:\n');
for i = 1:length(assetNames)
    fprintf('%s: %f\n', assetNames{i}, smlValues(i));
end
fprintf('Confronto tra rendimenti attesi e rendimenti effettivi:\n');
for i = 1:length(assetNames)
    fprintf('%s: Rendimento atteso = %f, Rendimento effettivo = %f\n', assetNames{i}, smlValues(i), meanReturns(i));
end

% Traccia il piano media-varianza con tutti i titoli e la SML
figure;
scatter(beta_assets, meanReturns, 'b', 'filled');
hold on;
for i = 1:length(assetNames)
    text(beta_assets(i), meanReturns(i), assetNames{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
plot([0, max(beta_assets)], [riskFreeRate, max(smlValues)], '-r', 'LineWidth', 2);

% Calcola il portafoglio che massimizza il rapporto di Sharpe
p = Portfolio('AssetMean', meanReturns, 'AssetCovar', cov(returnsAssets));
p = setDefaultConstraints(p);
wts = estimateMaxSharpeRatio(p);

% Stampa i pesi del portafoglio
fprintf('Pesi del portafoglio che massimizza il rapporto di Sharpe:\n');
for i = 1:length(assetNames)
    fprintf('%s: %f\n', assetNames{i}, wts(i));
end

% Calcola le statistiche del portafoglio
portfolio_return = mean(returnsAssets * wts);
portfolio_std = sqrt(wts' * cov(returnsAssets) * wts);
sharpe_ratio = (portfolio_return - riskFreeRate) / portfolio_std;

% Calcola il beta del portafoglio
beta_portfolio = sum(wts' .* beta_assets);

% Calcola skewness e curtosi del portafoglio
portfolio_skewness = skewness(returnsAssets * wts);
portfolio_kurtosis = kurtosis(returnsAssets * wts);

% Stampa le statistiche del portafoglio
fprintf('Statistiche del portafoglio ottimo:\n');
fprintf('Media: %f\n', portfolio_return);
fprintf('Varianza: %f\n', portfolio_std^2);
fprintf('Beta: %f\n', beta_portfolio);
fprintf('Skewness: %f\n', portfolio_skewness);
fprintf('Curtosi: %f\n', portfolio_kurtosis);
fprintf('Sharpe Ratio: %f\n', sharpe_ratio);

% Aggiungi il portafoglio di Sharpe al grafico SML
scatter(beta_portfolio, portfolio_return, 'r', 'filled');
text(beta_portfolio, portfolio_return, 'Portafoglio di Sharpe', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

% Aggiungi il portafoglio di mercato al grafico SML
market_beta = 1; % Il beta del portafoglio di mercato è 1
market_return = marketReturn; % Il rendimento del portafoglio di mercato è il rendimento medio del mercato
scatter(market_beta, market_return, 100, 'g', '*'); % Evidenzia il portafoglio di mercato con una stella verde
text(market_beta, market_return, 'Portafoglio di Mercato', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

xlabel('Beta');
ylabel('Rendimento Atteso');
title('Piano Media-Varianza con SML, Portafoglio di Sharpe e Portafoglio di Mercato');
legend('Titoli', 'SML', 'Portafoglio di Sharpe', 'Portafoglio di Mercato');

% Calcola la frontiera efficiente
p = Portfolio('AssetList', assetNames, 'RiskFreeRate', riskFreeRate);
p = setAssetMoments(p, meanReturns, cov(returnsAssets));
p = setDefaultConstraints(p);
pwgt = estimateFrontier(p, 20);
[prsk, pret] = estimatePortMoments(p, pwgt);

% Calcola la linea tangente
q = setBudget(p, 0, 1);
qwgt = estimateFrontier(q, 20);
[qrsk, qret] = estimatePortMoments(q, qwgt);

% Grafico della frontiera efficiente (valori giornalieri)
figure;
plot(prsk, pret, 'b-', 'LineWidth', 2);
hold on;
plot(qrsk, qret, 'g--', 'LineWidth', 2); % Linea tangente
scatter(portfolio_std, portfolio_return, 'r', 'filled');
text(portfolio_std, portfolio_return, 'Portafoglio Ottimo', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
for i = 1:length(meanReturns)
    scatter(stdReturns(i), meanReturns(i), 'k', 'filled');
    text(stdReturns(i), meanReturns(i), assetNames{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
scatter(beta_portfolio, portfolio_return, 100, 'r', '*'); % Evidenzia il portafoglio di Sharpe con una stella

% Imposta i limiti degli assi per migliorare la visualizzazione
xlim([0, max(stdReturns) * 1.1]);
ylim([min(meanReturns) * 0.9, max(meanReturns) * 1.1]);

xlabel('Rischio (Deviazione Standard)');
ylabel('Rendimento Atteso');
title('Frontiera Efficiente sul Piano Media-Varianza (Valori Giornalieri)');
legend('Frontiera Efficiente', 'Linea Tangente', 'Portafoglio Ottimo', 'Portafoglio di Sharpe', 'Portafoglio di Mercato', 'Location', 'Best');
grid on;
hold off;
