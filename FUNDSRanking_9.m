% Carica i dati dal file Excel con la regola di denominazione delle variabili impostata su 'preserve'
opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'funds daily');
opts.VariableNamingRule = 'preserve';
funds_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'SP500indexD');
opts.VariableNamingRule = 'preserve';
benchmark_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

% Converti le date in formato datetime
funds_data.DATE = datetime(funds_data.DATE, 'InputFormat', 'dd/MM/yyyy');
benchmark_data.DATE = datetime(benchmark_data.DATE, 'InputFormat', 'dd/MM/yyyy');

% Allinea i dati delle date
start_date = datetime('10/01/2020', 'InputFormat', 'dd/MM/yyyy');
end_date = datetime('10/01/2025', 'InputFormat', 'dd/MM/yyyy');
funds_data = funds_data(funds_data.DATE >= start_date & funds_data.DATE <= end_date, :);
benchmark_data = benchmark_data(benchmark_data.DATE >= start_date & benchmark_data.DATE <= end_date, :);

% Trova le date comuni
common_dates = intersect(funds_data.DATE, benchmark_data.DATE);

% Filtra i dati per le date comuni
funds_data = funds_data(ismember(funds_data.DATE, common_dates), :);
benchmark_data = benchmark_data(ismember(benchmark_data.DATE, common_dates), :);

% Calcola i rendimenti giornalieri normali
funds_returns = diff(funds_data{:, 2:end}) ./ funds_data{1:end-1, 2:end};
benchmark_returns = diff(benchmark_data{:, 2}) ./ benchmark_data{1:end-1, 2};

% Assicurati che le dimensioni delle matrici siano compatibili
if size(funds_returns, 1) ~= size(benchmark_returns, 1)
    error('Le dimensioni delle matrici dei rendimenti non corrispondono.');
end

% Calcola i beta dei titoli
num_stocks = size(funds_returns, 2);
beta = zeros(num_stocks, 1);
mean_returns = zeros(num_stocks, 1);
std_returns = zeros(num_stocks, 1);
sharpe_ratio = zeros(num_stocks, 1);
information_ratio = zeros(num_stocks, 1);
average_drawdown = zeros(num_stocks, 1);
pain_index = zeros(num_stocks, 1);
sterling_ratio = zeros(num_stocks, 1);
burke_ratio = zeros(num_stocks, 1);
jensen_alpha = zeros(num_stocks, 1);
treynor_index = zeros(num_stocks, 1);
treynor_black_ratio = zeros(num_stocks, 1);
stock_names = funds_data.Properties.VariableNames(2:end);

% Tasso privo di rischio giornaliero
risk_free_rate_daily = 0.02 / 252;

for i = 1:num_stocks
    X = [ones(size(benchmark_returns)), benchmark_returns];
    y = funds_returns(:, i);
    b = X \ y;
    beta(i) = b(2);
    mean_returns(i) = mean(funds_returns(:, i));
    std_returns(i) = std(funds_returns(:, i));
    sharpe_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / std_returns(i);
    information_ratio(i) = (mean_returns(i) - mean(benchmark_returns)) / std_returns(i);

    % Calcola l'Average Drawdown
    cumulative_returns = cumprod(1 + funds_returns(:, i)) - 1;
    drawdowns = cumulative_returns - cummax(cumulative_returns);
    average_drawdown(i) = mean(drawdowns(drawdowns < 0));

    % Calcola il Pain Index
    pain_index(i) = mean(abs(drawdowns(drawdowns < 0)));

    % Calcola lo Sterling Ratio
    sterling_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / abs(average_drawdown(i));

    % Calcola il Burke Ratio
    burke_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / sqrt(mean(drawdowns(drawdowns < 0).^2));

    % Calcola il Jensen Alpha
    jensen_alpha(i) = mean_returns(i) - (risk_free_rate_daily + beta(i) * (mean(benchmark_returns) - risk_free_rate_daily));

    % Calcola il Treynor Index
    treynor_index(i) = (mean_returns(i) - risk_free_rate_daily) / beta(i);

    % Calcola il Treynor-Black Ratio
    treynor_black_ratio(i) = jensen_alpha(i) / beta(i);
end

% Calcola i rendimenti annualizzati e le deviazioni standard annualizzate
annualized_mean_returns = mean_returns * 252;
annualized_std_returns = std_returns * sqrt(252);
annualized_sharpe_ratio = sharpe_ratio * sqrt(252);
annualized_information_ratio = information_ratio * sqrt(252);
annualized_jensen_alpha = jensen_alpha * 252;
annualized_treynor_index = treynor_index * 252;
annualized_treynor_black_ratio = treynor_black_ratio * 252;

% Seleziona i 5 indicatori di performance per il ranking
performance_indicators = [annualized_information_ratio, annualized_sharpe_ratio, annualized_jensen_alpha, pain_index, annualized_treynor_index];

% Assegna pesi a ciascun indicatore (puoi modificare questi pesi in base alle tue preferenze)
weights = [0.3, 0.25, 0.2, 0.15, 0.1]; % La somma dei pesi deve essere 1

% Inizializza una matrice per memorizzare i ranking
rankings = zeros(num_stocks, 5);

% Calcola i ranking per ciascun indicatore
for i = 1:5
    [~, sorted_indices] = sort(performance_indicators(:, i), 'descend');
    [~, rankings(:, i)] = sort(sorted_indices);
end

% Calcola il punteggio complessivo per ciascun fondo
overall_scores = zeros(num_stocks, 1);
for i = 1:num_stocks
    overall_scores(i) = sum(rankings(i, :) .* weights);
end

% Aggiungi i punteggi complessivi alla tabella dei risultati
results_table = table(stock_names', beta, annualized_mean_returns, annualized_std_returns, annualized_sharpe_ratio, annualized_information_ratio, ...
    pain_index, sterling_ratio, burke_ratio, annualized_jensen_alpha, annualized_treynor_index, annualized_treynor_black_ratio, overall_scores, ...
    'VariableNames', {'Stock', 'Beta', 'Annualized_Mean_Return', 'Annualized_Std_Dev', 'Annualized_Sharpe_Ratio', 'Annualized_Information_Ratio', ...
    'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Annualized_Jensen_Alpha', 'Annualized_Treynor_Index', 'Annualized_Treynor_Black_Ratio', 'Overall_Score'});

% Ordina i fondi in base al punteggio complessivo (dal migliore al peggiore)
sorted_funds = sortrows(results_table, 'Overall_Score', 'ascend'); % 'ascend' perché un punteggio più basso è migliore

% Visualizza i fondi in ordine di punteggio
disp('Ranking dei fondi in ordine di punteggio (dal migliore al peggiore):');
disp(sorted_funds(:, {'Stock', 'Overall_Score', 'Annualized_Information_Ratio', 'Annualized_Sharpe_Ratio', 'Annualized_Jensen_Alpha', 'Pain_Index', 'Annualized_Treynor_Index'}));

% Seleziona il miglior fondo
top_fund = sorted_funds(1, :);
disp('Il miglior fondo selezionato è:');
disp(top_fund);