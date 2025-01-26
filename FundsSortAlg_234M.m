% Carica i dati dal file Excel con la regola di denominazione delle variabili impostata su 'preserve'
opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'funds monthly');
opts.VariableNamingRule = 'preserve';
funds_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'SP500indexM');
opts.VariableNamingRule = 'preserve';
benchmark_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

% Converti le date in formato datetime
funds_data.DATE = datetime(funds_data.DATE, 'InputFormat', 'MM/yyyy');
benchmark_data.DATE = datetime(benchmark_data.DATE, 'InputFormat', 'MM/yyyy');

% Allinea i dati delle date
start_date = datetime('01/2020', 'InputFormat', 'MM/yyyy');
end_date = datetime('01/2025', 'InputFormat', 'MM/yyyy');
funds_data = funds_data(funds_data.DATE >= start_date & funds_data.DATE <= end_date, :);
benchmark_data = benchmark_data(benchmark_data.DATE >= start_date & benchmark_data.DATE <= end_date, :);

% Trova le date comuni
common_dates = intersect(funds_data.DATE, benchmark_data.DATE);

% Filtra i dati per le date comuni
funds_data = funds_data(ismember(funds_data.DATE, common_dates), :);
benchmark_data = benchmark_data(ismember(benchmark_data.DATE, common_dates), :);

% Calcola i rendimenti mensili
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

% Tasso privo di rischio mensile
risk_free_rate_monthly = 0.02 / 12;

for i = 1:num_stocks
    X = [ones(size(benchmark_returns)), benchmark_returns];
    y = funds_returns(:, i);
    b = X \ y;
    beta(i) = b(2);
    mean_returns(i) = mean(funds_returns(:, i));
    std_returns(i) = std(funds_returns(:, i));
    sharpe_ratio(i) = (mean_returns(i) - risk_free_rate_monthly) / std_returns(i);
    information_ratio(i) = (mean_returns(i) - mean(benchmark_returns)) / std_returns(i);

    % Calcola l'Average Drawdown
    cumulative_returns = cumprod(1 + funds_returns(:, i)) - 1;
    drawdowns = cumulative_returns - cummax(cumulative_returns);
    average_drawdown(i) = mean(drawdowns(drawdowns < 0));

    % Calcola il Pain Index
    pain_index(i) = mean(abs(drawdowns(drawdowns < 0)));

    % Calcola lo Sterling Ratio
    sterling_ratio(i) = (mean_returns(i) - risk_free_rate_monthly) / abs(average_drawdown(i));

    % Calcola il Burke Ratio
    burke_ratio(i) = (mean_returns(i) - risk_free_rate_monthly) / sqrt(mean(drawdowns(drawdowns < 0).^2));

    % Calcola il Jensen Alpha
    jensen_alpha(i) = mean_returns(i) - (risk_free_rate_monthly + beta(i) * (mean(benchmark_returns) - risk_free_rate_monthly));

    % Calcola il Treynor Index
    treynor_index(i) = (mean_returns(i) - risk_free_rate_monthly) / beta(i);

    % Calcola il Treynor-Black Ratio
    treynor_black_ratio(i) = jensen_alpha(i) / beta(i);
end

% Aggiungi i punteggi alla tabella dei risultati
results_table = table(stock_names', beta, mean_returns, std_returns, sharpe_ratio, information_ratio, ...
    average_drawdown, pain_index, sterling_ratio, burke_ratio, jensen_alpha, treynor_index, treynor_black_ratio, ...
    'VariableNames', {'Stock', 'Beta', 'Mean_Return', 'Std_Dev', 'Sharpe_Ratio', 'Information_Ratio', ...
    'Average_Drawdown', 'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Jensen_Alpha', 'Treynor_Index', 'Treynor_Black_Ratio'});

% Definisci i pesi per ciascuna categoria, inclusa la correlazione
weights = struct('mean_returns', 0.05, ...
                 'std_returns', 0.05, ...
                 'sharpe_ratio', 0.025, ...
                 'information_ratio', 0.2, ...
                 'pain_index', 0.05, ...
                 'sterling_ratio', 0.05, ...
                 'burke_ratio', 0.05, ...
                 'jensen_alpha', 0.275, ...
                 'treynor_index', 0.05, ...
                 'correlation', 0.1);

% Calcola il punteggio ponderato per ciascun titolo
scores = zeros(num_stocks, 1);
for i = 1:num_stocks
    score = 0;
    if mean_returns(i) > mean(mean_returns)
        score = score + 5 * weights.mean_returns; 
    else
        score = score + 1 * weights.mean_returns; 
    end
    
    if std_returns(i) < mean(std_returns)
        score = score + 5 * weights.std_returns; 
    else
        score = score + 1 * weights.std_returns; 
    end
    
    if sharpe_ratio(i) > mean(sharpe_ratio)
        score = score + 5 * weights.sharpe_ratio; 
    else
        score = score + 1 * weights.sharpe_ratio; 
    end
    
    if information_ratio(i) > mean(information_ratio)
        score = score + 5 * weights.information_ratio; 
    else
        score = score + 1 * weights.information_ratio; 
    end
    
    if pain_index(i) < mean(pain_index)
        score = score + 5 * weights.pain_index; 
    else
        score = score + 1 * weights.pain_index; 
    end
    
    if sterling_ratio(i) > mean(sterling_ratio)
        score = score + 5 * weights.sterling_ratio; 
    else
        score = score + 1 * weights.sterling_ratio; 
    end

    scores(i) = score; % Assegna il punteggio per il titolo corrente
end

% Aggiungi i punteggi alla tabella dei risultati
results_table.Score = scores;

% Ordina i titoli in base ai punteggi e seleziona i migliori 7
sorted_stocks = sortrows(results_table, 'Score', 'descend');
top_7_stocks = sorted_stocks(1:min(7, height(sorted_stocks)), :);

disp('I migliori 7 titoli selezionati sono:');
disp(top_7_stocks);

% Calcola i rendimenti annualizzati e le deviazioni standard annualizzate
annualized_mean_returns = mean_returns * 252;
annualized_std_returns = std_returns * sqrt(252);
annualized_sharpe_ratio = sharpe_ratio * sqrt(252);
annualized_information_ratio = information_ratio * sqrt(252);
annualized_jensen_alpha = jensen_alpha * 252;
annualized_treynor_index = treynor_index * 252;
annualized_treynor_black_ratio = treynor_black_ratio * 252;

% Visualizza i risultati mensili in una tabella
monthly_results_table = table(stock_names', beta, mean_returns, std_returns, sharpe_ratio, information_ratio, ...
    pain_index, sterling_ratio, burke_ratio, jensen_alpha, treynor_index, treynor_black_ratio, scores, ...
    'VariableNames', {'Stock', 'Beta', 'Mean_Return', 'Std_Dev', 'Sharpe_Ratio', 'Information_Ratio', ...
    'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Jensen_Alpha', 'Treynor_Index', 'Treynor_Black_Ratio', 'Score'});

disp('Beta, rendimenti mensili, deviazione standard mensile, Sharpe Ratio mensile, Information Ratio mensile, Pain Index, Sterling Ratio, Burke Ratio, Jensen Alpha, Treynor Index e Treynor-Black Ratio dei titoli:');
disp(monthly_results_table);

% Visualizza i risultati annualizzati in una tabella
annualized_results_table = table(stock_names', beta, annualized_mean_returns, annualized_std_returns, annualized_sharpe_ratio, annualized_information_ratio, ...
    pain_index, sterling_ratio, burke_ratio, annualized_jensen_alpha, annualized_treynor_index, annualized_treynor_black_ratio, scores, ...
    'VariableNames', {'Stock', 'Beta', 'Annualized_Mean_Return', 'Annualized_Std_Dev', 'Annualized_Sharpe_Ratio', 'Annualized_Information_Ratio', ...
    'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Annualized_Jensen_Alpha', 'Annualized_Treynor_Index', 'Annualized_Treynor_Black_Ratio', 'Score'});

disp('Beta, rendimenti annualizzati, deviazione standard annualizzata, Sharpe Ratio annualizzato, Information Ratio annualizzato, Pain Index, Sterling Ratio, Burke Ratio, Jensen Alpha annualizzato, Treynor Index annualizzato e Treynor-Black Ratio annualizzato dei titoli:');
disp(annualized_results_table);


% Visualizza i risultati annualizzati in una tabella
annualized_results_table = table(stock_names', beta, annualized_mean_returns, annualized_std_returns, annualized_sharpe_ratio, annualized_information_ratio, ...
    pain_index, sterling_ratio, burke_ratio, annualized_jensen_alpha, annualized_treynor_index, annualized_treynor_black_ratio, scores, ...
    'VariableNames', {'Stock', 'Beta', 'Annualized_Mean_Return', 'Annualized_Std_Dev', 'Annualized_Sharpe_Ratio', 'Annualized_Information_Ratio', ...
    'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Annualized_Jensen_Alpha', 'Annualized_Treynor_Index', 'Annualized_Treynor_Black_Ratio', 'Score'});

disp('Beta, rendimenti annualizzati, deviazione standard annualizzata, Sharpe Ratio annualizzato, Information Ratio annualizzato, Pain Index, Sterling Ratio, Burke Ratio, Jensen Alpha annualizzato, Treynor Index annualizzato e Treynor-Black Ratio annualizzato dei titoli:');
disp(annualized_results_table);
