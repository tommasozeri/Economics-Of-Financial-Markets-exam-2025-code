% Carica i dati dal file DBEXAM.xlsx con la regola di denominazione delle variabili impostata su 'preserve'
opts = detectImportOptions('DBEXAM.xlsx', 'Sheet', 'NASselectedD');
opts.VariableNamingRule = 'preserve';
data = readtable('DBEXAM.xlsx', opts);

% Calcola i rendimenti giornalieri
prices = data{:, 2:end}; % Supponendo che la prima colonna sia la data
returns = diff(prices) ./ prices(1:end-1, :);

% Definisci il problema del portafoglio
p = Portfolio('AssetList', data.Properties.VariableNames(2:end));
p = estimateAssetMoments(p, returns, 'missingdata', true);
p = setDefaultConstraints(p);

% Trova il portafoglio di varianza minima
w = estimateFrontierLimits(p, 'min');

% Calcola il rendimento atteso e la deviazione standard del portafoglio
portfolio_return = mean(returns * w);
portfolio_std = sqrt(w' * cov(returns) * w);

% Calcola skewness e kurtosis del portafoglio
portfolio_skewness = skewness(returns * w);
portfolio_kurtosis = kurtosis(returns * w);

% Calcola il rapporto di Sharpe
risk_free_rate = 0.02 / 252; % Tasso privo di rischio giornaliero
sharpe_ratio = (portfolio_return - risk_free_rate) / portfolio_std;

% Calcola il beta del portafoglio
benchmark_returns = mean(returns, 2); % Supponendo che il benchmark sia la media dei rendimenti degli asset
cov_matrix = cov(returns);
beta_portfolio = (cov_matrix * w) / var(benchmark_returns);
beta_portfolio = sum(beta_portfolio); % Somma dei beta ponderati per ottenere un valore unico

% Mostra i risultati
fprintf('Rendimento atteso del portafoglio: %.4f\n', portfolio_return);
fprintf('Deviazione standard del portafoglio: %.4f\n', portfolio_std);
fprintf('Skewness del portafoglio: %.4f\n', portfolio_skewness);
fprintf('Kurtosis del portafoglio: %.4f\n', portfolio_kurtosis);
fprintf('Rapporto di Sharpe: %.4f\n', sharpe_ratio);
fprintf('Beta del portafoglio: %.4f\n', beta_portfolio);

% Mostra i pesi dei titoli nel portafoglio
fprintf('Pesi dei titoli nel portafoglio:\n');
for i = 1:length(w)
    fprintf('%s: %.4f\n', data.Properties.VariableNames{i+1}, w(i));
end

% Plot della frontiera efficiente
figure;
plotFrontier(p);
hold on;
plot(portfolio_std, portfolio_return, 'r*', 'MarkerSize', 10);

% Aggiungi la retta tangente
slope = (portfolio_return - risk_free_rate) / portfolio_std;
x = linspace(0, max(portfolio_std), 100);
y = risk_free_rate + slope * x;
plot(x, y, 'g--');

title('Frontiera Efficiente con Portafoglio di Varianza Minima e Retta Tangente');
xlabel('Deviazione Standard');
ylabel('Rendimento Atteso');
legend('Frontiera Efficiente', 'Portafoglio di Varianza Minima', 'Retta Tangente', 'Location', 'best');
grid on;
